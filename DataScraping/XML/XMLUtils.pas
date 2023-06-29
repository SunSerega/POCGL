unit XMLUtils;
{$reference System.XML.dll}

uses '../../POCGL_Utils';

uses ScrapUtils;

var unprocessed_xml_files: HashSet<string>;
procedure Init(repo_name: string);
begin
  var path := System.IO.Path.GetFullPath(GetFullPathRTA($'../../Reps/{repo_name}/xml'));
  unprocessed_xml_files := EnumerateFiles(path, '*.xml').Select(fname->fname.Replace('\','/')).ToHashSet;
end;

type
  {$region XmlNode}
  
  XmlNode = sealed class
    private t: string;
    private atrbs := new Dictionary<string,string>;
    private txt: string;
    private nds: array of XmlNode;
    
    private used := false;
    private atrbs_used := new HashSet<string>;
    private atrbs_discarded := new HashSet<string>;
    
    private procedure InitFrom(el: System.Xml.XmlNode);
    begin
      self.t := el.Name;
      if t='#comment' then
        self.Discard;
      
      if el.Attributes<>nil then
        foreach var atrb: System.Xml.XmlAttribute in el.Attributes do
          atrbs.Add(atrb.Name, atrb.Value);
      
      txt := el.InnerText;
      
      nds := (0..el.ChildNodes.Count-1).Select(el.ChildNodes.Item)
        .Where(sub_el->sub_el.Name not in |'#comment', '#text'|)
        .Select(sub_el->
        begin
          Result := new XmlNode;
          Result.InitFrom(sub_el);
        end).ToArray;
      
    end;
    
    private static AllRoots := new Dictionary<string, XmlNode>;
    public constructor(fname: string);
    begin
      fname := GetFullPath(fname).Replace('\','/');
      if not unprocessed_xml_files.Remove(fname) then Otp($'WARNING: File [{fname}] isn''t expected as input');
      var d := new System.Xml.XmlDocument;
      d.LoadXml(ReadAllText(fname).Replace(#13#10,#10));
      InitFrom(d.DocumentElement);
      AllRoots.Add(fname, self);
      self.used := true;
    end;
    
    public constructor;
    begin
      nds := new XmlNode[0];
    end;
    
    public property Text: string read txt;
    
    private function GetAttribute(name: string): string;
    begin
      if name in atrbs_discarded then
        raise new System.InvalidOperationException;
      if not atrbs.TryGetValue(name, Result) then exit;
      atrbs_used += name;
    end;
    public property Attribute[name: string]: string read GetAttribute; default;
    
    public procedure DiscardAttribute(name: string);
    begin
      if not atrbs_discarded.Add(name) then
        raise new System.InvalidOperationException($'Double discard of [{name}]');
      atrbs.Remove(name);
    end;
    
    private function GetNodes(t: string): sequence of XmlNode;
    begin
      foreach var n in nds do
      begin
        if n.t<>t then continue;
        n.used := true;
        yield n;
      end;
    end;
    public property Nodes[t: string]: sequence of XmlNode read GetNodes;
    
    public property NodeTypes: sequence of string
      read nds.Select(n->n.t).Distinct;
    
    public procedure Discard;
    begin
      self.used := true;
      self.atrbs.Clear;
      SetLength(self.nds, 0);
    end;
    public procedure DiscardNodes(t: string) :=
      foreach var n in Nodes[t] do n.Discard;
    
    private procedure ReportUnused(write_header: Action0; prev: Stack<XmlNode>);
    begin
      prev.Push(self);
      
      if not used then
      begin
        write_header;
        log.Otp($'Unused node '+prev.Reverse.Select(n->n.t).JoinToString('=>')+'< '+atrbs.Select(kvp->$'{kvp.Key}="{kvp.Value}"').JoinToString+' >: '+self.Text.Replace(#10,'\n')?[:250+1]);
      end else
      begin
        
        foreach var atrb in atrbs.Keys do
        begin
          if atrb in atrbs_used then continue;
          write_header;
          log.Otp($'Unused attribute in '+prev.Reverse.Select(n->n.t).JoinToString('=>')+$': {atrb}="{atrbs[atrb]}"');
        end;
        
        foreach var n in nds do
          n.ReportUnused(write_header, prev);
        
      end;
      
      if prev.Pop <> self then raise new System.InvalidOperationException;
    end;
    private procedure ReportUnused(fname: string);
    begin
      ReportUnused(()->
      begin
        if fname=nil then exit;
        log.Otp($'=== {System.IO.Path.GetFileName(fname)} ===');
        fname := nil;
      end, new Stack<XmlNode>);
    end;
    
  end;
  
  {$endregion XmlNode}
  
initialization
finalization
  try
    
    foreach var fname in unprocessed_xml_files do
      log.Otp($'File [{fname}] wasn''t used');
    
    foreach var fname in XmlNode.AllRoots.Keys do
      XmlNode.AllRoots[fname].ReportUnused(fname);
    
    log.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.