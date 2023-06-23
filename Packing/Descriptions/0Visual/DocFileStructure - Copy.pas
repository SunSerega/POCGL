unit DocFileStructure;

interface

uses Parsing in '..\..\..\Utils\Parsing';

uses Logic;

type
  
  {$region Nodes}
  
  {$region Base}
  
  DocFileNode = abstract class
    private text: StringSection;
    
    public constructor(text: StringSection) := self.text := text;
    private constructor := raise new System.InvalidOperationException;
    
    protected procedure SetParent(p: DocFileNode; ind: integer); abstract;
    public function GetParent: DocFileNode; abstract;
    
    public function FirstChild: DocFileNode; abstract;
    public function DirectNextAfter(n: DocFileNode): DocFileNode; abstract;
    
    public function Next: DocFileNode;
    begin
      Result := FirstChild;
      if Result<>nil then exit;
      var n := self;
      
      while true do
      begin
        var p := n.GetParent;
        if p=nil then break;
        Result := p.DirectNextAfter(n);
        if Result<>nil then break;
        n := p;
      end;
      
    end;
    
  end;
  
  {$endregion Base}
  
  {$region Child}
  
  DocFileChildNode = abstract class(DocFileNode)
    
    protected parent: DocFileNode;
    protected parent_ind: integer;
    protected procedure SetParent(p: DocFileNode; ind: integer); override;
    begin
      self.parent := p;
      self.parent_ind := ind;
    end;
    public function GetParent: DocFileNode; override := parent;
    
  end;
  
  {$endregion Child}
  
  {$region Numbered}
  
  DocFileNumberedList<TNode> = sealed class(List<TNode>)
  where TNode: DocFileChildNode;
    
    public procedure Add(parent: DocFileNode; n: TNode); reintroduce;
    begin
      if n.GetParent<>nil then
        raise new System.InvalidOperationException;
      n.SetParent(parent, self.Count);
      inherited Add(n);
    end;
    
    public function TryGet(ind: integer) :=
    if ind < self.Count then
      self[ind] else nil;
    
    public function NextDirect(n: TNode) := TryGet(n.parent_ind+1);
    public function NextDirect(n: DocFileNode) := NextDirect(TNode(n));
    
  end;
  
  {$endregion Numbered}
  
  {$region Trimmed}
  
  DocFileTrimmedNode = abstract class(DocFileChildNode)
    
    public function FirstChild: DocFileNode; override := nil;
    public function DirectNextAfter(n: DocFileNode): DocFileNode; override :=
      ValRaise&<DocFileNode>(new System.InvalidOperationException);
    
  end;
  
  {$endregion Trimmed}
  
  {$region BlockName}
  
  DocFileBlockName = sealed class(DocFileChildNode)
    private 
    
  end;
  
  {$endregion BlockName}
  
  {$region BlockHead}
  
  DocFileBlockHead = sealed class(DocFileChildNode)
    private names := new DocFileNumberedList<DocFileBlockName>;
    
    public function FirstChild: DocFileNode; override := names.TryGet(0);
    public function DirectNextAfter(n: DocFileNode): DocFileNode; override := names.NextDirect(n);
    
  end;
  
  {$endregion BlockHead}
  
  {$region BlockBody}
  
  {$endregion BlockBody}
  
  {$region Block}
  
  DocFileBlock = sealed class(DocFileChildNode)
    private head: DocFileBlockHead;
    private body: DocFileBlockBody;
    
    public constructor(text: StringSection);
    begin
      var TODO := 0;
    end;
    
    public function FirstChild: DocFileNode; override := head;
    public function DirectNextAfter(n: DocFileNode): DocFileNode; override :=
      if n=head then body else
      if n=body then nil else
        ValRaise&<DocFileNode>(new System.InvalidOperationException);
    
  end;
  
  {$endregion Block}
  
  {$region Tree}
  
  DocFileTree = sealed partial class(DocFileNode)
    private blocks := new DocFileNumberedList<DocFileBlock>;
    
    private constructor := self.text := new StringSection('');
    
    public constructor(text: StringSection);
    begin
      inherited Create(text);
      
      //TODO
      
      blocks.Add(self, new DocFileBlock);
      
    end;
    public constructor(text: string) := Create(new StringSection(text));
    public static function operator implicit(text: string): DocFileTree := new DocFileTree(text);
    
    protected procedure SetParent(p: DocFileNode; ind: integer); override := raise new System.NotImplementedException;
    public function GetParent: DocFileNode; override := nil;
    
    public function FirstChild: DocFileNode; override := blocks.TryGet(0);
    public function DirectNextAfter(n: DocFileNode): DocFileNode; override := blocks.NextDirect(n);
    
  end;
  
  {$endregion Tree}
  
  {$endregion Nodes}
  
  {$region Diff}
  
  DocFileTreeDiff = abstract class
    
  end;
  
  DocFileTree = sealed partial class(DocFileNode)
    
    private static _empty := new DocFileTree;
    public static property Empty: DocFileTree read _empty;
    
    public static function Diff(t1, t2: DocFileTree): sequence of DocFileTreeDiff;
    
  end;
  
  {$endregion Diff}
  
implementation

uses Patterns in '..\..\..\Utils\Patterns';

static function DocFileTree.Diff(t1, t2: DocFileTree): sequence of DocFileTreeDiff;
begin
  
end;

end.