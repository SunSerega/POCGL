uses POCGL_Utils in '..\..\..\POCGL_Utils';
uses XMLUtils    in '..\XMLUtils';


type
  LogCache = static class
    
    static kinds_undescribed            := new HashSet<string>;
    static kinds_unutilised             := new HashSet<string>;
    static invalid_type_for_group       := new HashSet<string>;
    static missing_group                := new HashSet<string>;
    static func_with_enum_without_group := new HashSet<string>;
    
  end;
  
  Kinds = static class
    static described  := new HashSet<string>;
    static mentioned  := new HashSet<string>
  end;
  
  Group = sealed class
    private name: string;
    private bitmask: boolean;
    private enums := new Dictionary<string, int64>;
    
    private types := new HashSet<string>;
    
    public static All := new Dictionary<string, Group>;
    public static Used := new HashSet<string>;
    
    public procedure MakeTypeCompatible(var t1, t2: string; func_name: string);
    begin
      if t1=t2 then exit;
      
      begin
        var t1s := if t1.StartsWith('GLu') then t1.Remove(2,1) else t1;
        var t2s := if t2.StartsWith('GLu') then t2.Remove(2,1) else t2;
        if t1s=t2s then
        begin
          t1 := t1s;
          t2 := t2s;
          exit;
        end;
      end;
      
      raise new MessageException($'Incompatible underlying group types: [{t1}] and [{t2}] in func [{func_name}]');
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter);
    begin
      bw.Write(name);
      bw.Write(bitmask);
      bw.Write(enums.Count);
      
      foreach var key in enums.Keys do
      begin
        bw.Write(key);
        bw.Write(enums[key]);
      end;
      
      if types.Count=0 then
        types += 'GLuint';
      bw.Write(types.Count);
      foreach var t in types do
        bw.Write(t);
      
    end;
    
  end;
  GroupBuilder = sealed class
    private static all := new Dictionary<string, GroupBuilder>;
    private enums := new List<(string,int64,boolean)>;
    
    private static function GetItem(gname: string): GroupBuilder;
    begin
      if not all.TryGetValue(gname, Result) then
      begin
        Result := new GroupBuilder;
        all[gname] := Result;
      end;
    end;
    public static property Item[gname: string]: GroupBuilder read GetItem; default;
    
    public static procedure operator+=(gb: GroupBuilder; enum: (string,int64,boolean)) :=
    gb.enums += enum;
    
    public static procedure SealAll(api_name: string);
    begin
      
      foreach var gname in all.Keys do
      begin
        var res := new Group;
        res.name := gname;
        
        var group_t: (gt_any, gt_enum, gt_bitmask, gt_error) := gt_any;
        foreach var (ename, eval, is_bitmask) in all[gname].enums do
        begin
          if res.enums.ContainsKey(ename) then
          begin
            log.WriteLine($'enum [{ename}] used multiple times in group [{gname}] of api [{api_name}]');
            continue;
          end;
          
          res.enums.Add(ename, eval);
          
          if eval=0 then
          begin
            if 'Flags' in gname then
            begin
              group_t := gt_bitmask;
              var TODO := 0;
              //TODO костыль, надо определять тип групы по тому, как она использована в функциях
              log.WriteLine($'Group {gname} was autoset to gt_bitmask, because of GL_NONE in enums, need fixing');
            end;
          end else
            case group_t of
              gt_any:     group_t := is_bitmask ? gt_bitmask : gt_enum;
              gt_enum:    if     is_bitmask then group_t := gt_error;
              gt_bitmask: if not is_bitmask then group_t := gt_error;
              gt_error:   ;
            end;
          
        end;
        
        case group_t of
          
          gt_any:     log.WriteLine($'Empty group [{gname}] in api [{api_name}]');
          gt_error:   Otp($'ERROR: Can''t determine type of group [{gname}] in api [{api_name}]');
          
          else
          begin
            res.bitmask := group_t=gt_bitmask;
            Group.All.Add(gname, res);
          end;
        end;
        
      end;
      
      all.Clear;
    end;
    
  end;
  
  ParData = sealed class
    public static ParClasses := new HashSet<string>;
    
    private name, t: string;
    private rep_c: int64 := 1;
    private ptr: integer;
    private static_arr_len := -1;
    private readonly_lvls := new List<integer>; // "const int * * const * v": Levels 1 and 3 are readonly
    private gr: Group := nil;
    
    public on_used: ()->();
    
    private enum_types := |'GLenum', 'GLbitfield'|;
    public constructor(func_name: string; n: XmlNode);
    begin
      var text := n.Text;
      
      if n['len'] is string(var static_arr_len_str) then
      begin
        if not static_arr_len_str.TryToInteger(self.static_arr_len) then
          ; // Если в будущем будет смысл обрабатывать значения кроме литералов - добавлять код сюда
      end;
      
      self.name := n.Nodes['name'].Single.Text;
      if func_name=nil then func_name := self.name;
      
      var class_name := n['class'];
      if class_name<>nil then ParClasses += class_name;
      
      self.t :=
        class_name ??
        n.Nodes['ptype'].SingleOrDefault?.Text ??
        text.Remove(text.LastIndexOf(' ')).Remove('const').Trim;
      ;
      
      foreach var s in text.Split('*').Reverse index i do
        if 'const' in s then
          self.readonly_lvls += i;
      
      self.ptr := text.Count(ch->ch='*');
      
      if n['kind'] is string(var kind_s) then foreach var kind in kind_s.Split(',') do
      begin
        if kind in Kinds.described then
          Kinds.mentioned += kind else
        if LogCache.kinds_undescribed.Add(kind) then
          log.WriteLine($'Kind [{kind}] was not described');
        
        case kind of
          
          'String':
          begin
            if self.t <> 'GLubyte' then raise new MessageException($'ERROR: Kind [{kind}] was applied to type [{self.t}]');
            self.t := 'GLchar';
          end;
          
          else if (kind in Kinds.described) and LogCache.kinds_unutilised.Add(kind) then
            log.WriteLine($'Kind [{kind}] was not utilised');
        end;
      end;
      
      if n['group'] is string(var gname) then
      begin
        
        if not Group.All.TryGetValue(gname, self.gr) then
        begin
          on_used += ()->
          if LogCache.missing_group.Add(gname) then
            log.WriteLine($'Group [{gname}] isn''t defined');
        end else
        begin
          Group.Used += gname;
          if self.t in enum_types then
            self.t := 'GLuint';
          gr.types += self.t;
        end;
        
      end else
      if self.t in enum_types then
        on_used += ()->
          if LogCache.func_with_enum_without_group.Add(func_name) then
            ;
      
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter; grs: array of Group);
    begin
      bw.Write(name);
      bw.Write(t);
      bw.Write(rep_c);
      bw.Write(ptr);
      bw.Write(static_arr_len);
      
      bw.Write(readonly_lvls.Count);
      foreach var lvl in readonly_lvls do
        bw.Write(lvl);
      
      var ind := gr=nil ? -1 : grs.IndexOf(gr);
      if (gr<>nil) and (ind=-1) then raise new MessageException($'ERROR: Group [{gr.name}] not found in saved list');
      bw.Write(ind);
      
      bw.Write(false); // base_t - onlt relevant for OpenCL, because there is no class's
      
    end;
    
  end;
  FuncData = sealed class
    // первая пара - имя функции и возвращаемое значение
    private pars := new List<ParData>;
    
    private constructor(n: XmlNode);
    begin
      pars += new ParData(nil, n.Nodes['proto'].Single);
      foreach var pn in n.Nodes['param'] do
        pars += new ParData(pars[0].name, pn);
    end;
    
    private static _all: Dictionary<string, FuncData>;
    private static Used: HashSet<string>;
    
    public static procedure InitNodes(nodes: sequence of XmlNode);
    begin
      _all := new Dictionary<string, FuncData>;
      Used := new HashSet<string>;
      foreach var n in nodes do
      begin
        var f := new FuncData(n);
        _all.Add(f.pars[0].name, f);
      end;
    end;
    
    private static function GetItem(fn: string): FuncData;
    begin
      Result := _all[fn];
      if Used.Add(fn) then
        foreach var par in Result.pars do
          if par.on_used<>nil then par.on_used;
    end;
    public static property All[fn: string]: FuncData read GetItem; default;
    
    public procedure Save(bw: System.IO.BinaryWriter; grs: array of Group);
    begin
      bw.Write(pars.Count);
      foreach var par in pars do
        par.Save(bw, grs);
    end;
    
  end;
  
  Feature = sealed class
    private api: string;
    private num: array of integer;
    private add: List<FuncData>;
    private rem: List<FuncData>;
    
    public constructor(n: XmlNode);
    begin
      api := n['api'];
      num := n['number'].ToWords('.').ConvertAll(s->s.ToInteger);
      add := n.Nodes['require'].SelectMany(rn->rn.Nodes['command']).Select(c->FuncData[c['name']]).ToList;
      rem := n.Nodes['remove' ].SelectMany(rn->rn.Nodes['command']).Select(c->FuncData[c['name']]).ToList;
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter; fncs: array of FuncData);
    begin
      bw.Write(api);
      
      bw.Write(num.Length);
      foreach var n in num do
        bw.Write(n);
      
      bw.Write(add.Count);
      foreach var f in add do
      begin
        var ind := fncs.IndexOf(f);
        if ind=-1 then raise new MessageException($'ERROR: Func [{f.pars[0].name}] not found in saved list');
        bw.Write(ind);
      end;
      
      bw.Write(rem.Count);
      foreach var f in rem do
      begin
        var ind := fncs.IndexOf(f);
        if ind=-1 then raise new MessageException($'ERROR: Func [{f.pars[0].name}] not found in saved list');
        bw.Write(ind);
      end;
      
    end;
    
  end;
  Extension = sealed class
    private name, api: string;
    private add := new HashSet<FuncData>;
    
    public constructor(name, api: string);
    begin
      self.name := name;
      self.api  := api;
    end;
    
    public procedure AddReq(req_n: XmlNode);
    begin
      foreach var c in req_n.Nodes['command'] do
        if not add.Add(FuncData[c['name']]) then
          Otp($'WARNING: Func [{c[''name'']}] found twice in ext [{name}]');
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter; fncs: array of FuncData);
    begin
      bw.Write(name);
      bw.Write(api);
      
      bw.Write(add.Count);
      foreach var f in add do
        bw.Write(fncs.IndexOf(f));
      
    end;
    
  end;
  
var features := new List<Feature>;
var extensions := new List<Extension>;

procedure ScrapFile(api_name: string);
begin
  Otp($'Parsing "{api_name}"');
  var root := new XmlNode(GetFullPathRTA($'..\..\Reps\OpenGL-Registry\xml\{api_name}.xml'));
//  var root := new XmlNode(GetFullPathRTA($'C:\0Prog\Test\OpenGL-Registry (fork)\xml\{api_name}.xml'));
  
  begin
    var ns := root.Nodes['kinds'];
    if ns.Any then foreach var k in ns.Single.Nodes['kind'] do
    begin
      var kind := k['name'];
      var desc := k['desc'];
      if not Kinds.described.Add(kind) then
        Otp($'WARNING: Kind [{kind}] defined multiple times');
      if string.IsNullOrWhiteSpace(desc) then
        Otp($'WARNING: Kind [{kind}] had empty description');
    end;
  end;
  
  foreach var enums in root.Nodes['enums'] do
  begin
    var bitmask := false;
    var enums_t := enums['type'];
    
    if enums_t<>nil then
      case enums_t of
        
        'bitmask': bitmask := true;
        
        else log.WriteLine($'Invalid <enums> type: [{enums_t}]');
      end;
    
    foreach var enum in enums.Nodes['enum'] do
    begin
      if enum['group']=nil then continue;
      if (enum['api']<>nil) then
        raise new System.InvalidOperationException($'Enum "{enum[''name'']}" had api "{enum[''api'']}"');
      
      var val_str := enum['value'];
      var val: int64;
      
      var groups := enum['group'].ToWords(',').ToList;
      if groups.Remove('SpecialNumbers') then log.WriteLine($'Enum "{enum[''name'']}" was in SpecialNumbers');
      if groups.Count=0 then continue;
      var ename := enum['name'];
      
      // у всех энумов из групп пока что тип UInt32, так что этот функционал не нужен
      if enum['type']<>nil then raise new System.NotImplementedException(enum['name']);
      
//        var enum_t := enum['type'];
//        if enum_t=nil then enum_t := 'u' else
//        Writeln(enum_t);
      
      try
        if val_str.StartsWith('0x') then
          val := System.Convert.ToInt64(val_str, 16) else
          val := System.Convert.ToInt64(val_str);
      except
        on e: Exception do log.WriteLine($'Error registering value [{val}] of token [{enum[''name'']}] in api [{api_name}]: {e}');
      end;
      
      foreach var gname in groups do
      begin
        var gb := GroupBuilder[gname];
        gb += (ename, val, bitmask);
      end;
      
    end;
    
  end;
  
  GroupBuilder.SealAll(api_name);
  
  FuncData.InitNodes(root.Nodes['commands'].Single.Nodes['command']);
  
  foreach var n in root.Nodes['feature'] do
  begin
    var f := new Feature(n);
    features += f;
  end;
  
  foreach var ext_n in root.Nodes['extensions'].Single.Nodes['extension'] do
  begin
    var name := ext_n['name'];
    
    var exts := ext_n['supported'].ToWords('|').ToDictionary(k->k,k->default(Extension));
    if exts.Remove('glcore') and not exts.ContainsKey('gl') then
      raise new System.InvalidOperationException(name);
    if exts.Count=0 then raise new System.InvalidOperationException(name);
    
    foreach var req_n in ext_n.Nodes['require'] do
    begin
      
      var def_api := req_n['api'];
      foreach var api in
        if def_api=nil then exts.Keys.ToArray else |def_api|
      do
      begin
        if exts[api]=nil then exts[api] := new Extension(name, api);
        exts[api].AddReq(req_n);
      end;
      
    end;
    
    foreach var ext in exts.Values do
    begin
      if ext=nil then continue;
      extensions += ext;
    end;
  end;
  
end;

procedure SaveBin;
begin
  Otp($'Saving as binary');
  var bw := new System.IO.BinaryWriter(System.IO.File.Create(GetFullPath($'..\funcs.bin', GetEXEFileName)));
  
  var grs := Group.All.Values.ToArray;
  var funcs := (
    features.SelectMany(f->f.add.Concat(f.rem)) +
    extensions.SelectMany(ext->ext.add)
  ).ToHashSet.ToArray;
  
  bw.Write(grs.Length);
  foreach var gr in grs do
    gr.Save(bw);
  
  bw.Write(0); // structs
  
  bw.Write(ParData.ParClasses.Count);
  foreach var cl in ParData.ParClasses do
    bw.Write(cl);
  
  bw.Write(funcs.Length);
  foreach var func in funcs do
    func.Save(bw, grs);
  
  bw.Write(features.Count);
  foreach var f in features do
    f.Save(bw, funcs);
  
  bw.Write(extensions.Count);
  foreach var ext in extensions do
    ext.Save(bw, funcs);
  
  bw.Close;
end;

begin
  try
    xmls := System.IO.Directory.EnumerateFiles(GetFullPath($'..\..\..\Reps\OpenGL-Registry\xml', GetEXEFileName), '*.xml').ToHashSet;
    
    ScrapFile('gl');
    ScrapFile('wgl');
    ScrapFile('glx');
    
    //TODO Turn into WARNING's
    LogCache.func_with_enum_without_group .WriteLines(GetFullPathRTA('enum_without_group.txt'));
    
    foreach var kind in Kinds.described.Except(Kinds.mentioned) do
      Otp($'WARNING: Kind [{kind}] has description, but was not mentioned');
    
    foreach var fname in xmls do
      log.WriteLine($'File [{fname}] wasn''t used');
    
//    foreach var f: FuncData in features.SelectMany(f->f.add+f.rem).Where(f->f.pars.Any(par->(par.t in ['GLenum', 'GLbitfield']) and (par.gr=nil))).Distinct.OrderBy(f->f.pars[0].name) do
//    begin
//      Writeln('='*30);
//      f.pars.PrintLines(par->$'{par.name}: {par.t} [{_ObjectToString(par.gr)}]');
//    end;
//    exit;
    
    SaveBin;
    
    log.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.