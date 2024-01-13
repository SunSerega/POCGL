unit ThoroughXML;

{$reference System.XML.dll}

interface

type
  
  {$region Basic def}
  
  XmlItem = abstract class
    
    {$region MarkUsed}
    
    private was_used := false;
    public property WasUsed: boolean read was_used;
    public function TryMarkUsed: boolean;
    begin
      Result := not WasUsed;
      was_used := true;
    end;
    public procedure MarkUsed := if not TryMarkUsed then
      raise new System.InvalidOperationException;
    
    protected function GetContent<T>(f: ()->T): T;
    begin
      self.TryMarkUsed;
      Result := f;
    end;
    
    {$endregion MarkUsed}
    
    {$region Discard}
    
    private is_discarded := false;
    public property IsDiscarded: boolean read is_discarded;
    public function TryDiscard: boolean;
    begin
      Result := not IsDiscarded;
      is_discarded := true;
    end;
    public procedure Discard := if not TryDiscard then
      raise new System.InvalidOperationException;
    
    {$endregion Discard}
    
  end;
  
  XmlNode = sealed partial class(XmlItem)
    private _parent: XmlNode;
    private _raw: System.Xml.XmlNode;
    
    {$region Constructors}
    
    private constructor(_parent: XmlNode; _raw: System.Xml.XmlNode);
    begin
      self._parent := _parent;
      self._raw := _raw;
    end;
    public constructor(xml_text: string);
    begin
      var d := new System.Xml.XmlDocument;
      d.LoadXml(xml_text);
      self._parent := nil;
      self._raw := d.DocumentElement;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    {$endregion Constructors}
    
    public property Parent: XmlNode read _parent;
    
    public property Tag: string read _raw.Name;
    public property Text: string read GetContent(()->_raw.InnerText);
    
    public function IterateParents: sequence of XmlNode;
    begin
      var curr := self;
      repeat
        yield curr;
        curr := curr.Parent;
      until curr=nil;
    end;
    public property FullPath: string read IterateParents.Reverse.Select(n->n.Tag).JoinToString('=>');
    public function ToString: string; override := FullPath;
    
  end;
  
  XmlAttrib = sealed partial class(XmlItem)
    private _node: XmlNode;
    private _raw: System.Xml.XmlAttribute;
    
    {$region Constructors}
    
    private constructor(_node: XmlNode; _raw: System.Xml.XmlAttribute);
    begin
      self._node := _node;
      self._raw := _raw;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    {$endregion Constructors}
    
    public property Node: XmlNode read _node;
    
    public property Name: string read _raw.Name;
    public property Data: string read GetContent(()->_raw.Value);
    
    public function ToString: string; override := $'{Node.FullPath}: {Name}="{Data}"';
    
  end;
  
  {$endregion Basic def}
  
  {$region Node Children}
  
  XmlNode = sealed partial class
    
    {$region Attribs}
    
    private attribs_cache: Dictionary<string, XmlAttrib>;
    public function GetAllAttribs: Dictionary<string, XmlAttrib>;
    begin
      Result := attribs_cache;
      if Result<>nil then exit;
      
      if _raw.Attributes=nil then
        Result := new Dictionary<string, XmlAttrib> else
      begin
        Result := new Dictionary<string, XmlAttrib>(_raw.Attributes.Count);
        for var i := 0 to _raw.Attributes.Count-1 do
        begin
          var a := new XmlAttrib(self, _raw.Attributes[i]);
          Result.Add(a.Name, a);
        end;
      end;
      
      attribs_cache := Result;
    end;
    //TODO #????: self.
    public property Attrib[name: string]: XmlAttrib read GetContent(()->self.GetAllAttribs.Get(name));
    //TODO #2461: string(...)
    public property AttribData[name: string]: string read string(Attrib[name]?.Data); default;
    
    public function TryDiscardAttrib(name: string): boolean :=
      (Attrib[name] is XmlAttrib(var a)) and a.TryDiscard;
    public procedure DiscardAttrib(name: string) := if not TryDiscardAttrib(name) then
      raise new System.InvalidOperationException(name);
    
    {$endregion Attribs}
    
    {$region SubNodes}
    
    private sub_nodes_cache: array of XmlNode;
    public function GetAllSubNodes: IList<XmlNode>;
    begin
      Result := sub_nodes_cache;
      if Result<>nil then exit;
      
      Result := new List<XmlNode>(_raw.ChildNodes.Count);
      for var i := 0 to _raw.ChildNodes.Count-1 do
      begin
        var n := new XmlNode(self, _raw.ChildNodes[i]);
        if n.Tag.StartsWith('#') then
        begin
          if n.Tag not in |'#comment', '#text', '#cdata-section'| then
            raise new System.NotImplementedException(n.Tag);
          continue;
        end;
        Result.Add(n);
      end;
      
      sub_nodes_cache := Result.ToArray;
    end;
    //TODO #????: self.
    public property SubNodes[tag: string]: sequence of XmlNode read GetContent(()->self.GetAllSubNodes.Where(n->n.Tag=tag));
    
    public function TryDiscardSubNodes(tag: string) := SubNodes[tag].Count(n->n.TryDiscard);
    
    {$endregion SubNodes}
    
  end;
  
  {$endregion Node Children}
  
  {$region Visitor}
  
  XmlVisitor = abstract class
    
    public procedure VisitAttrib(a: XmlAttrib); abstract;
    
    public function VisitNode(n: XmlNode): boolean; abstract;
    
    public static function MakeBasic(visit_attrib: XmlAttrib->(); visit_node: XmlNode->boolean): XmlVisitor;
    
  end;
  
  XmlNode = sealed partial class
    
    public procedure Visit(v: XmlVisitor);
    begin
      if not v.VisitNode(self) then exit;
      
      foreach var a in GetAllAttribs.Values do
        v.VisitAttrib(a);
      
      foreach var n in GetAllSubNodes do
        n.Visit(v);
      
    end;
    
    public procedure ThoroughCheck(header: ()->()
      ; attrib_lost, attrib_used_and_discarded: XmlAttrib->()
      ; node_lost,   node_used_and_discarded:   XmlNode->()
    ) := Visit(XmlVisitor.MakeBasic(
      a->
      begin
        if a.WasUsed xor a.IsDiscarded then exit;
        
        if header<>nil then header();
        header := nil;
        
        if not a.WasUsed then
          attrib_lost(a) else
          attrib_used_and_discarded(a);
        
      end,
      n->
      begin
        Result := not n.IsDiscarded;
        if n.WasUsed xor n.IsDiscarded then exit;
        
        if header<>nil then header();
        header := nil;
        
        if not n.WasUsed then
          node_lost(n) else
          node_used_and_discarded(n);
        
      end
    ));
    
  end;
  
  {$endregion Visitor}
  
implementation

{$region BasicVisitor}

type
  BasicXmlVisitor = sealed class(XmlVisitor)
    private visit_attrib: XmlAttrib->();
    private visit_node: XmlNode->boolean;
    
    public constructor(visit_attrib: XmlAttrib->(); visit_node: XmlNode->boolean);
    begin
      self.visit_attrib := visit_attrib;
      self.visit_node := visit_node;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public procedure VisitAttrib(a: XmlAttrib); override := visit_attrib(a);
    
    public function VisitNode(n: XmlNode): boolean; override := visit_node(n);
    
  end;
  
static function XmlVisitor.MakeBasic(visit_attrib: XmlAttrib->(); visit_node: XmlNode->boolean) :=
  new BasicXmlVisitor(visit_attrib, visit_node);

{$endregion BasicVisitor}

end.