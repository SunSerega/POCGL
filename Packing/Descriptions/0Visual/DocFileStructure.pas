unit DocFileStructure;

interface

uses Parsing in '..\..\..\Utils\Parsing';
uses TreePatterns in '..\..\..\Utils\Patterns\TreePatterns';

uses Logic;
uses Visual;

type
  DocFilePart = abstract class(IPatternTreeNode<DocFilePart>)
    
    
    
    public function GetFirstChild: TNode;
    public function GetChildAfter(n: TNode): TNode;
    public function GetParent: TNode;
    begin
//      var tb: System.Windows.Controls.RichTextBox;
//      tb.Document.Blocks.FirstBlock.fi
//      System.Windows.LogicalTreeHelper.GetChildren
    end;
    
    public function GetParentCount: integer;
    public function CompareChildInds(n1, n2: TNode): integer;
    
  end;
  
implementation

uses Patterns in '..\..\..\Utils\Patterns';

end.