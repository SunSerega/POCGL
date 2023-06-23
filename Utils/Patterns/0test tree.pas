uses Trees;

type
  DummyTreeNode<TData> = sealed class(BasicPatternTreeNode<DummyTreeNode<TData>>)
    private children := new List<DummyTreeNode<TData>>;
    private data: TData;
    
    public constructor(data: TData; parent: DummyTreeNode<TData>);
    begin
      inherited Create(parent.GetParentCount+1, parent.children.Count, parent);
      self.data := data;
    end;
    public constructor(data: TData);
    begin
      inherited Create(0,0,nil);
      self.data := data;
    end;
    private constructor;
    begin
      inherited Create(0,0,nil);
      raise new System.InvalidOperationException;
    end;
    
    protected function GetSubNodeAt(ind: integer): DummyTreeNode<TData>; override :=
    if ind=children.Count then nil else children[ind];
    
    public function Add(data: TData): DummyTreeNode<TData>;
    begin
      Result := new DummyTreeNode<TData>(data, self);
      self.children += Result;
    end;
    
    public function ToString: string; override :=
    $'{TypeName(self)}[{_ObjectToString(data)}]';
    
  end;
  DummyTreePointer = BasicPatternTreePointer<DummyTreeNode<string>>;
  
function StringTree(parent: DummyTreeNode<string>; data: string; add_children: DummyTreeNode<string>->() := nil): DummyTreeNode<string>;
begin
  Result := if parent=nil then
    new DummyTreeNode<string>(data) else
    parent.Add(data);
  if add_children<>nil then
    add_children(Result);
end;

begin
  var n1, n2: DummyTreeNode<string>;
  
  var t := StringTree(nil, 'root', n->
  begin
    n1 := StringTree(n, 'r.1', n->
    begin
      StringTree(n, 'r.1.1');
      StringTree(n, 'r.1.2');
    end);
    n2 := StringTree(n, 'r.2');
  end);
  
  DummyTreePointer.Compare(n1, n2).Println;
  Println(n1);
  Println(n2);
end.