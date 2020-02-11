uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';
uses XMLUtils in '..\XMLUtils.pas';

var allowed_api := HSet(
  'gl','glcore', // gl есть всюду где glcore, glcore только чтоб не выводить лишнее сообщение в лог
  'wgl',
  'glx'
);

type
  LogCache = static class
    
    static invalid_type_for_group := new HashSet<string>;
    static missing_group := new HashSet<string>;
    static func_with_enum_without_group := new HashSet<string>;
    static invalid_api := new HashSet<string>;
    
  end;
  
  Group = sealed class
    private name, t: string;
    private bitmask: boolean;
    private enums := new Dictionary<string, int64>;
    
    public static All: Dictionary<string, Group>;
    public static Used: HashSet<string>;
    
    public procedure Save(bw: System.IO.BinaryWriter);
    begin
      bw.Write(name);
      bw.Write(t);
      bw.Write(bitmask);
      bw.Write(enums.Count);
      foreach var key in enums.Keys do
      begin
        bw.Write(key);
        bw.Write(enums[key]);
      end;
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
      Group.All := new Dictionary<string, Group>;
      Group.Used := new HashSet<string>;
      
      foreach var gname in all.Keys do
      begin
        var res := new Group;
        res.name := gname;
        res.t := 'GLuint';
        
        var group_t: (gt_any, gt_enum, gt_bitmask, gt_error) := gt_any;
        foreach var enum in all[gname].enums do
        begin
          if res.enums.ContainsKey(enum[0]) then
          begin
            log.WriteLine($'enum [{enum[0]}] used multiple times in group [{gname}] of api [{api_name}]');
            continue;
          end;
          
          res.enums.Add(enum[0], enum[1]);
          
          if enum[1]<>0 then
            case group_t of
              gt_any:     group_t := enum[2] ? gt_bitmask : gt_enum;
              gt_enum:    if     enum[2] then group_t := gt_error;
              gt_bitmask: if not enum[2] then group_t := gt_error;
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
    private name, t: string;
    private readonly: boolean;
    private ptr: integer;
    private gr: Group := nil;
    
    public on_used: ()->();
    
    public constructor(func_name: string; n: XmlNode);
    begin
      
      self.name := n.Nodes['name'].Single.Text;
      if func_name=nil then func_name := self.name;
      
      var text := n.Text;
      self.t := n.Nodes['ptype'].SingleOrDefault?.Text;
      if self.t=nil then
        self.t := text.Remove(text.LastIndexOf(' ')).Remove('const').Trim;
      
      self.readonly := text.Contains('const');
      
      self.ptr := n.Text.Count(ch->ch='*');
      
      var is_enum := self.t in ['GLenum', 'GLbitfield'];
      
      var gname := n['group'];
      if gname<>nil then
      begin
        Group.Used += gname;
        
        if not is_enum then
        begin
          if gname='String' then
          begin
            if self.t <> 'GLubyte' then raise new MessageException($'Group [{gname}] was applied to type [{self.t}]');
            self.t := 'GLchar';
          end else
            on_used += ()->
            if LogCache.invalid_type_for_group.Add(t) then
              log.WriteLine($'Skipped group attrib for type [{t}]');
        end else
        if not Group.All.TryGetValue(gname, self.gr) then
        begin
          on_used += ()->
          if LogCache.missing_group.Add(gname) then
            log.WriteLine($'Group [{gname}] isn''t defined');
        end;
        
      end;// else
//      if is_enum then
//        on_used += ()->
//          if LogCache.func_with_enum_without_group.Add(func_name) then
//            Otp(func_name);
//            log.WriteLine($'Command [{func_name}] has enum parameter without group');
      
      var ToDo := 0; //ToDo расскоментировать когда группы приведут в кое-какой порядк
      
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter; grs: array of Group);
    begin
      bw.Write(name);
      bw.Write(t);
      bw.Write(readonly);
      bw.Write(ptr);
      
      var ind := gr=nil ? -1 : grs.IndexOf(gr);
      if (gr<>nil) and (ind=-1) then raise new MessageException($'ERROR: Group [{gr.name}] not found in saved list');
      bw.Write(ind);
      
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
    private name: string;
    private api: string;
    private add := new HashSet<FuncData>;
    
    public constructor(n: XmlNode);
    begin
      name := n['name'];
      
      var apis := n['supported'].ToWords('|').Where(api->
      begin
        Result := api in allowed_api;
        if not Result and LogCache.invalid_api.Add(api) then
          log.WriteLine($'Invalid api: [{api}]');
      end).ToList;
      apis.Remove('glcore');
      self.api := apis.DefaultIfEmpty('').SingleOrDefault;
      if self.api=nil then raise new System.NotSupportedException($'Extension can''t have multiple API''s');
      
      add := new HashSet<FuncData>;
      foreach var rn in n.Nodes['require'] do
        if (rn['api']=nil) or (rn['api'] in allowed_api) then
          foreach var c in rn.Nodes['command'] do
            if not add.Add(FuncData[c['name']]) then
              Otp($'WARNING: Func [{c[''name'']}] found 2 times in ext [{name}]');
      if n.Nodes['remove'].Any then Otp('WARNING: ext [{name}] had "remove" tag');
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
  var root := new XmlNode(GetFullPath($'..\..\..\Reps\OpenGL-Registry\xml\{api_name}.xml', GetEXEFileName));
  
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
      if (enum['api']<>nil) and not allowed_api.Contains(enum['api']) then
        log.WriteLine($'Enum "{enum[''name'']}" had api "{enum[''api'']}"') else
      if enum['group']<>nil then
      begin
        var val_str := enum['value'];
        var val: int64;
        
        // у всех энумов из групп пока что тип UInt32, так что этот функционал не нужен
        if enum['type']<>nil then raise new System.NotImplementedException;
        
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
        
        foreach var gname in enum['group'].ToWords(',') do
        begin
          var gb := GroupBuilder[gname];
          gb += (enum['name'], val, bitmask);
        end;
        
      end;
    
  end;
  
  GroupBuilder.SealAll(api_name);
  
  FuncData.InitNodes(root.Nodes['commands'].Single.Nodes['command']);
  
  foreach var n in root.Nodes['feature'] do
  begin
    var f := new Feature(n);
    if f.api in allowed_api then
      features += f else
    if LogCache.invalid_api.Add(f.api) then
      log.WriteLine($'Invalid api: [{f.api}]');
  end;
  
  foreach var n in root.Nodes['extensions'].Single.Nodes['extension'] do
  begin
    var ext := new Extension(n);
    if ext.api='' then continue;
    extensions += ext;
  end;
  
  foreach var gr in Group.All.Values do
    if not Group.Used.Contains(gr.name) then
      log.WriteLine($'Group [{gr.name}] wasn''t used in any function');
  
end;

procedure SaveBin;
begin
  Otp($'Saving as binary');
  var bw := new System.IO.BinaryWriter(System.IO.File.Create(GetFullPath($'..\funcs.bin', GetEXEFileName)));
  
  var funcs := (
    features.SelectMany(f->f.add.Concat(f.rem)) +
    extensions.SelectMany(ext->ext.add)
  ).ToHashSet.ToArray;
  
  var grs := funcs
    .SelectMany(f->f.pars)
    .Select(par->par.gr)
    .Where(gr->gr<>nil)
    .ToHashSet.ToArray
  ;
  
  bw.Write(0); // structs
  
  bw.Write(grs.Length);
  foreach var gr in grs do
    gr.Save(bw);
  
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
    
    foreach var fname in xmls do
      log.WriteLine($'File [{fname}] wasn''t used');
    
    SaveBin;
    
    log.Close;
    if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString($'done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.