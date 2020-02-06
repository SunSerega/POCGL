unit XMLUtils;

{$reference System.XML.dll}
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

var log := new System.IO.StreamWriter(
  GetFullPath('..\xml.log', GetEXEFileName),
  false, enc
);
var xmls: HashSet<string>;

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
  
end.