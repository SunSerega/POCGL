uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';
uses XMLUtils in '..\XMLUtils.pas';

type
  LogCache = static class
    static missing_type_def  := new HashSet<string>;
  end;
  
  TypeDef = sealed class
    private def := default(string);
    private ptr := 0;
    //
    private name := default(string);
    
    private static All := new Dictionary<string, TypeDef>;
    
    public constructor(n: XmlNode);
    
    public procedure UnRollDef;
    begin
      var prev: TypeDef;
      if (def<>nil) then
        if All.TryGetValue(def, prev) then
        begin
          prev.UnRollDef;
          self.ptr          += prev.ptr;
          self.name         := prev.name;
          self.def          := nil;
        end else
        if LogCache.missing_type_def.Add(def) then
          log.WriteLine($'Type [{def}] is referenced but not defined');
      
    end;
    public static procedure UnRollAll;
    begin
      foreach var t in All.Values do
        t.UnRollDef;
    end;
    
  end;
  
  StructDef = sealed class
    private name: string;
    // (name, ptr, type)
    private flds := new List<(string,integer,string)>;
    //
    private static All := new Dictionary<string, StructDef>;
    
    public constructor(n: XmlNode);
    
    public procedure Save(bw: System.IO.BinaryWriter);
    begin
      bw.Write(name);
      bw.Write(flds.Count);
      foreach var t in flds do
      begin
        bw.Write(t[0]);
        bw.Write(t[1]);
        bw.Write(t[2]);
      end;
    end;
    
  end;
  
{$region constructor's}

constructor TypeDef.Create(n: XmlNode);
begin
  var category := n['category'];
  
  case category of
    
    'include':
    begin
      if n.Text.Contains('#include') then exit;
      self.name := n['name'];
    end;
    
    'basetype':
    begin
      self.name := n['name'];
    end;
    
    'define':
    begin
      self.name := n.Nodes['name'].Single.Text;
      self.ptr  := n.Text.Count(ch->ch='*');
      
      var enmr := n.Nodes['type'].GetEnumerator;
      if enmr.MoveNext then
      begin
        
        self.def := enmr.Current.Text;
        if enmr.MoveNext then
          Otp($'ERROR: Wrong definition of type [{name}]');
        
      end else
      begin
        if n.Text.Contains('struct _') and (ptr=1) then
        begin
          self.ptr := 0;
        end else
          Otp($'ERROR: Wrong definition of type [{name}]');
      end;
      
    end;
    
    'struct':
    begin
      self.name := n['name'];
      new StructDef(n);
    end;
    
    else Otp($'ERROR: Invalid TypeDef category: [{category}]');
  end;
  
  All.Add(self.name, self);
end;

constructor StructDef.Create(n: XmlNode);
begin
  self.name := n['name'];
  
  foreach var m in n.Nodes['member'] do
  begin
    var nn := m.Nodes['name'].SingleOrDefault;
    
    if nn=nil then
    begin
      
      // костыль, но этот юнион безсмыслен, ибо буфер это подвид mem_object-а
      if m.Text.Contains('union') and m.Text.Contains('cl_mem buffer') and m.Text.Contains('cl_mem mem_object') then
      begin
        self.flds += ('mem_object', 0, 'cl_mem');
      end else
        raise new MessageException($'ERROR parsing struct member: [{m.Text}]');
      
      continue;
    end;
    
    self.flds += (nn.Text, m.Text.Count(ch->ch='*'), m.Nodes['type'].Single.Text);
  end;
  
  All.Add(self.name, self);
end;

{$endregion constructor's}

type
  Group = sealed class
    private name, t: string;
    private bitmask: boolean;
    private enums := new Dictionary<string, int64>;
    //
    public static All := new Dictionary<string, Group>;
    
    static constructor;
    begin
      var ec := new Group;
      ec.name := 'ErrorCode';
      ec.t := TypeDef.All['cl_int'].name;
      ec.bitmask := false;
      All.Add(ec.name, ec);
    end;
    
    public constructor(n: XmlNode);
    begin
      self.name := n['name'];
      if self.name.Contains('.') then exit;
      
      begin
        var t := n['type'];
        if t=nil then t := 'enum';
        
        case t of
          'enum': self.bitmask := false;
          'bitmask': self.bitmask := true;
          else raise new MessageException($'Wrong enum type: [{t}]');
        end;
        
      end;
      
      if not self.name.StartsWith('ErrorCode') then
      begin
        var td: TypeDef;
        if not TypeDef.All.TryGetValue(self.name, td) then
        begin
          log.WriteLine($'Type-less group [{self.name}]');
          exit;
        end;
        if td.ptr<>0 then raise new MessageException($'Enum [{self.name}] has type with ptr');
        self.t := td.name;
      end;
      
      foreach var e in n.Nodes['enum'] do
      begin
        var ename := e['name'];
        
        var val_str := e['value'];
        var val: int64;
        if val_str<>nil then
        try
          if val_str.StartsWith('0x') then
            val := System.Convert.ToInt64(val_str, 16) else
            val := System.Convert.ToInt64(val_str);
        except
          if not enums.TryGetValue(val_str, val) then
            Otp($'ERROR parsing enum val [{val_str}] of group [{self.name}]');
        end else
          val := 1 shl e['bitpos'].ToInteger;
        
        enums.Add(ename, val);
      end;
      
      if self.name.StartsWith('ErrorCode') then
      begin
        var ec := All['ErrorCode'];
        foreach var ename in enums.Keys do
          ec.enums.Add(ename, self.enums[ename]);
      end else
        All.Add(self.name, self);
    end;
    
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
  
  ParData = sealed class
    private name, t: string;
    private readonly: boolean;
    private ptr: integer;
    private gr: Group := nil;
    
    public constructor(n: XmlNode);
    begin
      var text := n.Text;
      
      self.name := n.Nodes['name'].SingleOrDefault?.Text;
      if self.name=nil then
        raise new MessageException($'ERROR: no name of func par [{text}]');
      
      self.t := n.Nodes['type'].SingleOrDefault?.Text;
      if self.t=nil then
        if text.Contains('CL_CALLBACK') then
          self.t := 'CL_CALLBACK' else
          raise new MessageException($'ERROR: unable to parse func par [{text}]');
      
      self.readonly := text.Contains('const');
      
      self.ptr := n.Text.Count(ch->ch='*');
      
      if (self.t<>'CL_CALLBACK') and not Group.All.TryGetValue(self.t, self.gr) then
      begin
        var td: TypeDef;
        if not TypeDef.All.TryGetValue(self.t, td) then
          raise new MessageException($'ERROR: Type [{self.t}] is not defined');
        self.ptr += td.ptr;
        self.t := td.name;
      end;
      
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
    
    public static All := new Dictionary<string, FuncData>;
    
    private constructor(n: XmlNode);
    begin
      pars += new ParData(n.Nodes['proto'].Single);
      
      var pns := n.Nodes['param'].ToList;
      if (pns.Count<>1) or (pns[0].Text<>'void') then
        foreach var pn in pns do
          pars += new ParData(pn);
      
      var last_par := pars[pars.Count-1];
      if last_par.name = 'errcode_ret' then
        last_par.gr := Group.All['ErrorCode'] else
      if (pars[0].t='cl_int') and (pars[0].ptr=0) then
        pars[0].gr := Group.All['ErrorCode'] else
        log.WriteLine($'Func [{pars[0].name}] had no err code return');
      
      All.Add(pars[0].name, self);
    end;
    
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
    
    public static All := new List<Feature>;
    
    public constructor(n: XmlNode);
    begin
      
      api := n['api'];
      if api='opencl' then
        api := 'cl' else
        raise new MessageException($'ERROR: Unexpected api [{api}] of feature [{n[''name'']}]');
      
      num := n['number'].ToWords('.').ConvertAll(s->s.ToInteger);
      
      add := n.Nodes['require'].SelectMany(rn->rn.Nodes['command']).Select(c->FuncData.All[c['name']]).ToList;
      rem := n.Nodes['remove' ].SelectMany(rn->rn.Nodes['command']).Select(c->FuncData.All[c['name']]).ToList;
      
      All.add(self);
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
    
    public static All := new List<Extension>;
    
    public constructor(n: XmlNode);
    begin
      name := n['name'];
      
      api := n['supported'];
      if api='opencl' then
        api := 'cl' else
        raise new MessageException($'ERROR: Unexpected api [{api}] of ext [{name}]');
      
      add := new HashSet<FuncData>;
      foreach var rn in n.Nodes['require'] do
        foreach var c in rn.Nodes['command'] do
          if not add.Add(FuncData.All[c['name']]) then
            Otp($'WARNING: Func [{c[''name'']}] found 2 times in ext [{name}]');
      if add.Count=0 then exit;
      
      if n.Nodes['remove'].Any then Otp('WARNING: ext [{name}] had <remove> tag');
      
      All.Add(self);
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
  
procedure ScrapFile(api_name: string);
begin
  Otp($'Parsing "{api_name}"');
  var root := new XmlNode(GetFullPath($'..\..\..\Reps\OpenCL-Docs\xml\{api_name}.xml', GetEXEFileName));
  
  foreach var n in root.Nodes['types'].Single.Nodes['type'] do
    new TypeDef(n);
  TypeDef.UnRollAll;
  
  foreach var n in root.Nodes['enums'] do
    new Group(n);
  
  foreach var n in root.Nodes['commands'].Single.Nodes['command'] do
    new FuncData(n);
  
  foreach var n in root.Nodes['feature'] do
    new Feature(n);
  
  foreach var n in root.Nodes['extensions'].Single.Nodes['extension'] do
    new Extension(n);
  
end;

procedure SaveBin;
begin
  Otp($'Saving as binary');
  var bw := new System.IO.BinaryWriter(System.IO.File.Create(GetFullPath($'..\funcs.bin', GetEXEFileName)));
  
  var funcs := (
    Feature.All.SelectMany(f->f.add.Concat(f.rem)) +
    Extension.All.SelectMany(ext->ext.add)
  ).ToHashSet.ToArray;
  
  var grs := funcs
    .SelectMany(f->f.pars)
    .Select(par->par.gr)
    .Where(gr->gr<>nil)
    .ToHashSet.ToArray
  ;
  
  var structs := funcs
    .SelectMany(f->f.pars)
    .Select(par->
    begin
      var res: StructDef;
      StructDef.All.TryGetValue(par.t, res);
      Result := res;
    end)
    .Where(s->s<>nil)
    .ToHashSet.ToArray
  ;
  
  bw.Write(structs.Length);
  foreach var struct in structs do
    struct.Save(bw);
  
  bw.Write(grs.Length);
  foreach var gr in grs do
    gr.Save(bw);
  
  bw.Write(funcs.Length);
  foreach var func in funcs do
    func.Save(bw, grs);
  
  bw.Write(Feature.All.Count);
  foreach var f in Feature.All do
    f.Save(bw, funcs);
  
  bw.Write(Extension.All.Count);
  foreach var ext in Extension.All do
    ext.Save(bw, funcs);
  
end;

begin
  try
    xmls := System.IO.Directory.EnumerateFiles(GetFullPath($'..\..\..\Reps\OpenCL-Docs\xml', GetEXEFileName), '*.xml').ToHashSet;
    
    ScrapFile('cl');
    
    foreach var fname in xmls do
      log.WriteLine($'File [{fname}] wasn''t used');
    
    SaveBin;
    
    log.Close;
    if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString($'done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.