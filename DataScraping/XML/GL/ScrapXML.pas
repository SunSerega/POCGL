{$reference System.XML.dll}
uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

var log := new System.IO.StreamWriter(
  GetFullPath('..\log.dat', GetEXEFileName),
  false, enc
);

type
  LogCache = static class
    
    static invalid_type_for_group := new HashSet<string>;
    static missing_group := new HashSet<string>;
    
  end;

var xmls := System.IO.Directory.EnumerateFiles(GetFullPath($'..\..\..\Reps\OpenGL-Registry\xml', GetEXEFileName), '*.xml').ToHashSet;

type
  XmlNode = sealed class
    private t: string;
    private atrbs := new Dictionary<string,string>;
    private txt: string;
    private nds: array of XmlNode;
    
    private procedure InitFrom(el: System.Xml.XmlNode);
    begin
      self.t := el.Name;
      
      if el.Attributes<>nil then
        foreach var atrb: System.Xml.XmlAttribute in el.Attributes do
          atrbs.Add(atrb.Name, atrb.Value);
      
      txt := el.InnerText;
      
      nds := new XmlNode[el.ChildNodes.Count];
      for var i := 0 to nds.Length-1 do
      begin
        var n := new XmlNode;
        n.InitFrom(el.ChildNodes[i]);
        nds[i] := n;
      end;
      
    end;
    
    public constructor(fname: string);
    begin
      if not xmls.Remove(fname) then Otp($'WARNING: file [{fname}] isn''t expected as input');
      var d := new System.Xml.XmlDocument;
      d.Load(fname);
      InitFrom(d.DocumentElement);
    end;
    
    public constructor;
    begin
      nds := new XmlNode[0];
    end;
    
    public property Text: string read txt;
    
    public property Attribute[name: string]: string read atrbs.ContainsKey(name) ? atrbs[name] : nil; default;
    
    public property Nodes[t: string]: sequence of XmlNode read nds.Where(n->n.t=t);
    
  end;
  
  Group = sealed class
    private name: string;
    private bitmask: boolean;
    private enums := new Dictionary<string, int64>;
    
    public static All := new List<Group>;
    public static Used := new HashSet<string>;
    
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
    
    public static function SealAll(api_name: string): Dictionary<string, Group>;
    begin
      Result := new Dictionary<string, Group>;
      
      foreach var gname in all.Keys do
      begin
        var res := new Group;
        res.name := gname;
        
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
            Group.All += res;
            Result.Add(gname, res);
          end;
        end;
        
      end;
      
      all.Clear;
    end;
    
  end;
  
  ParData = sealed class
    name, t: string;
    ptr: integer;
    gr: Group := nil;
    
    constructor(n: XmlNode; groups: Dictionary<string, Group>);
    begin
      
      self.name := n.Nodes['name'].Single.Text;
      
      self.t := n.Nodes['ptype'].SingleOrDefault?.Text;
      if self.t=nil then
      begin
        var s := n.Text;
        s := s.Remove(s.LastIndexOf(' '));
        self.t := s.Remove('const').Trim;
      end;
      
      self.ptr := n.Text.Count(ch->ch='*');
      
      var gname := n['group'];
      if gname<>nil then
      begin
        Group.Used += gname;
        
        if not (self.t in ['GLenum', 'GLbitfield']) then
        begin
          if LogCache.invalid_type_for_group.Add(t) then
            log.WriteLine($'Skipped group attrib for type [{t}]');
        end else
        if not groups.TryGetValue(gname, self.gr) then
        begin
          if LogCache.missing_group.Add(gname) then
            log.WriteLine($'Group [{gname}] not defined');
        end;
        
      end;
      
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter; grs: List<Group>);
    begin
      bw.Write(name);
      bw.Write(t);
      bw.Write(ptr);
      
      var ind := gr=nil ? -1 : grs.IndexOf(gr);
      if (gr<>nil) and (ind=-1) then raise new MessageException($'Group [{gr.name}] not found in saved list');
      bw.Write(ind);
      
    end;
    
  end;
  
  FuncData = sealed class
    // первая пара - имя функции и возвращаемое значение
    private pars := new List<ParData>;
    
    public constructor(n: XmlNode; groups: Dictionary<string, Group>);
    begin
      pars += new ParData(n.Nodes['proto'].Single, groups);
      foreach var pn in n.Nodes['param'] do
        pars += new ParData(pn, groups);
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter; grs: List<Group>);
    begin
      bw.Write(pars.Count);
      foreach var par in pars do
        par.Save(bw, grs);
    end;
    
  end;
  
var funcs := new List<FuncData>;

procedure ScrapFile(api_name: string);
begin
  Otp($'Parsing "{api_name}"');
  var root := new XmlNode(GetFullPath($'..\..\..\Reps\OpenGL-Registry\xml\{api_name}.xml', GetEXEFileName));
  
  foreach var enums in root.Nodes['enums'] do
  begin
    var bitmask := enums['type'] = 'bitmask';
    
    foreach var enum in enums.Nodes['enum'] do
      if (enum['api']<>nil) and (enum['api']<>'gl') then
        log.WriteLine($'enum "{enum[''name'']}" had api "{enum[''api'']}"') else
      if enum['group']<>nil then
      begin
        var val_str := enum['value'];
        var val: int64;
        
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
  
  var groups := GroupBuilder.SealAll(api_name);
  
  foreach var command in root.Nodes['commands'].Single.Nodes['command'] do
    funcs += new FuncData(command, groups);
  
end;

procedure SaveFuncs;
begin
  Otp($'Saving as binary');
  var bw := new System.IO.BinaryWriter(System.IO.File.Create(GetFullPath($'..\funcs.bin', GetEXEFileName)));
  
  var grs := funcs
    .SelectMany(f->f.pars)
    .Select(par->par.gr)
    .Where(gr->gr<>nil)
    .ToHashSet.ToList;
  bw.Write(grs.Count);
  foreach var gr in grs do
    gr.Save(bw);
  
  bw.Write(funcs.Count);
  foreach var func in funcs do
    func.Save(bw, grs);
  
end;

begin
  try
    ScrapFile('gl');
    ScrapFile('wgl');
    ScrapFile('glx');
    
    foreach var fname in xmls do
      log.WriteLine($'file "fname" wasn''t used');
    
    foreach var gr in Group.All do
      if not Group.Used.Contains(gr.name) then
        log.WriteLine($'group [{gr.name}] wasn''t used in any function');
    
    SaveFuncs;
    
    if not CommandLineArgs.Contains('SecondaryProc') then Otp($'done');
    log.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.