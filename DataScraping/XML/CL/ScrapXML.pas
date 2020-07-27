uses MiscUtils in '..\..\..\Utils\MiscUtils';
uses XMLUtils in '..\XMLUtils';

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
    public static struct_nodes := new List<XmlNode>;
    
    public constructor(n: XmlNode);
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
          struct_nodes += n;
        end;
        
        else Otp($'ERROR: Invalid TypeDef category: [{category}]');
      end;
      
      All.Add(self.name, self);
    end;
    
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
  
  Group = sealed class
    private name, t: string;
    private bitmask: boolean;
    private enums := new Dictionary<string, int64>;
    //
    public static All := new Dictionary<string, Group>;
    private static AllEnums := new Dictionary<string, int64>;
    private static GroupByEname := new Dictionary<string, Group>;
    
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
      if self.name in ['Constants'] then exit;
      var valid := true;
      
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
          valid := false;
        end else
        begin
          if td.ptr<>0 then raise new MessageException($'Group [{self.name}] has type with ptr');
          self.t := td.name;
        end;
      end;
      
      foreach var e in n.Nodes['enum'] do
      begin
        var ename := e['name'];
        
        var val_str := e['value'];
        var val: int64;
        if val_str<>nil then
        try
          var val_shl := 0;
          if val_str.Contains('<<') then
          begin
            var s := val_str.Trim('(',')').ToWords('<');
            val_str := s[0].Trim;
            val_shl := s[1].ToInteger;
          end;
          
          if val_str.StartsWith('0x') then
            val := System.Convert.ToInt64(val_str, 16) else
            val := System.Convert.ToInt64(val_str);
          
          val := val shl val_shl;
        except
          if val_str='((cl_device_partition_property_ext)0)' then
            val := 0 else
          if val_str='((cl_device_partition_property_ext)0 - 1)' then
            val := -1 else
          if not enums.TryGetValue(val_str, val) then
          begin
            Otp($'ERROR parsing enum [{ename}] val [{val_str}] of group [{self.name}]');
            continue;
          end;
        end else
          val := 1 shl e['bitpos'].ToInteger;
        
        enums.Add(ename, val);
        AllEnums.Add(ename, val);
        GroupByEname.Add(ename, self);
      end;
      
      if self.name.StartsWith('ErrorCode') then
      begin
        var ec := All['ErrorCode'];
        foreach var ename in enums.Keys do
          ec.enums.Add(ename, self.enums[ename]);
      end else
      if valid then
        All.Add(self.name, self);
    end;
    
    public static procedure FixBy(n: XmlNode);
    begin
      if not n.Nodes['enum'].Any then exit;
      var comment := n['comment'];
      if comment=nil then exit;
      
      foreach var gname in comment.ToWords do
      begin
        
        var gr: Group;
        if not All.TryGetValue(gname, gr) then
        begin
          var t: TypeDef;
          if TypeDef.All.TryGetValue(gname, t) then
          begin
            if t.ptr<>0 then raise new MessageException($'Group [{gname}] has type with ptr');
            gr := new Group;
            gr.name := gname;
            gr.t := t.name;
            t.name := gname;
            gr.bitmask := false;
            All.Add(gname, gr);
          end else
            continue;
        end;
        
        foreach var en in n.Nodes['enum'] do
        begin
          var ename := en['name'];
          if gr.enums.ContainsKey(ename) then continue;
          var pgr: Group;
          if GroupByEname.TryGetValue(ename, pgr) then
            pgr.enums.Remove(ename);
          
          var val: int64;
          if AllEnums.TryGetValue(ename, val) then
            gr.enums.Add(ename, val) else
            Otp($'ERROR: Enum [{ename}] of group [{gname}] wasn''t defined');
        end;
        
      end;
      
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
    private rep_c: int64 := 1;
    private readonly: boolean;
    private ptr: integer;
    private gr: Group := nil;
    
    public constructor(n: XmlNode);
    begin
      var text := n.Text;
      
      self.name := n.Nodes['name'].SingleOrDefault?.Text;
      if self.name=nil then
        raise new MessageException($'ERROR: no name of func par [{text}]');
      
      self.ptr := n.Text.Count(ch->ch='*');
      
      self.t := n.Nodes['type'].SingleOrDefault?.Text;
      if self.t=nil then
        if text.Contains('CL_CALLBACK') then
        begin
          self.ptr := 0;
          self.t := 'CL_CALLBACK';
        end else
          raise new MessageException($'ERROR: unable to parse func par [{text}]');
      
      if self.t.Contains('[') and self.t.EndsWith(']') then
      begin
        var ind := self.t.IndexOf('[');
        var c := self.t.Substring(ind+1, self.t.Length-ind-2);
        if TryStrToInt64(c, self.rep_c) or Group.AllEnums.TryGetValue(c, self.rep_c) then
          self.t := self.t.Remove(ind);
      end;
      
      self.readonly := text.Contains('const');
      
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
      bw.Write(rep_c);
      bw.Write(readonly);
      bw.Write(ptr);
      
      var ind := gr=nil ? -1 : grs.IndexOf(gr);
      if (gr<>nil) and (ind=-1) then raise new MessageException($'ERROR: Group [{gr.name}] not found in saved list');
      bw.Write(ind);
      
    end;
    
  end;
  StructDef = sealed class
    private name: string;
    // (name, ptr, type)
    private flds := new List<ParData>;
    //
    private static All := new Dictionary<string, StructDef>;
    
    public constructor(n: XmlNode);
    begin
      self.name := n['name'];
      
      foreach var m in n.Nodes['member'] do
      begin
        
        if not m.Nodes['name'].Any then
        begin
          
          // костыль, но этот юнион безсмыслен, ибо буфер это подвид mem_object-а
          if m.Text.Contains('union') and m.Text.Contains('cl_mem buffer') and m.Text.Contains('cl_mem mem_object') then
          begin
            var fld := new ParData;
            fld.name := 'mem_object';
            fld.t := 'cl_mem';
            self.flds += fld;
          end else
            raise new MessageException($'ERROR parsing struct member: [{m.Text}]');
          
          continue;
        end;
        
        var fld := new ParData(m);
        self.flds += fld;
      end;
      
      All.Add(self.name, self);
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter; grs: array of Group);
    begin
      bw.Write(name);
      bw.Write(flds.Count);
      foreach var fld in flds do
        fld.Save(bw, grs);
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
      if (pars[0].t='int32_t') and (pars[0].ptr=0) then
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
  var root := new XmlNode(GetFullPathRTE($'..\..\Reps\OpenCL-Docs\xml\{api_name}.xml'));
  
  foreach var n in root.Nodes['types'].Single.Nodes['type'] do
    new TypeDef(n);
  TypeDef.UnRollAll;
  
  foreach var n in root.Nodes['enums'] do
    new Group(n);
  foreach var fn in root.Nodes['feature'] + root.Nodes['extensions'].Single.Nodes['extension'] do
    foreach var rn in fn.Nodes['require'] do
      Group.FixBy(rn);
  
  foreach var n in TypeDef.struct_nodes do
    new StructDef(n);
  TypeDef.struct_nodes := nil;
  
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
  
  var grs := Group.All.Values.ToArray;
  var structs := StructDef.All.Values.ToArray;
  var funcs := (
    Feature.All.SelectMany(f->f.add.Concat(f.rem)) +
    Extension.All.SelectMany(ext->ext.add)
  ).ToHashSet.ToArray;
  
  bw.Write(grs.Length);
  foreach var gr in grs do
    gr.Save(bw);
  
  bw.Write(structs.Length);
  foreach var struct in structs do
    struct.Save(bw, grs);
  
  bw.Write(funcs.Length);
  foreach var func in funcs do
    func.Save(bw, grs);
  
  bw.Write(Feature.All.Count);
  foreach var f in Feature.All do
    f.Save(bw, funcs);
  
  bw.Write(Extension.All.Count);
  foreach var ext in Extension.All do
    ext.Save(bw, funcs);
  
  bw.Close;
end;

begin
  try
    xmls := System.IO.Directory.EnumerateFiles(GetFullPath($'..\..\..\Reps\OpenCL-Docs\xml', GetEXEFileName), '*.xml').ToHashSet;
    
    ScrapFile('cl');
    
    foreach var fname in xmls do
      log.WriteLine($'File [{fname}] wasn''t used');
    
    SaveBin;
    
    log.Close;
    if not is_secondary_proc then Otp('done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.