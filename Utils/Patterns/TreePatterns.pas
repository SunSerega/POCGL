unit TreePatterns;

interface

uses System;
uses System.Runtime.CompilerServices;

uses Patterns in '..\Patterns';

type
  
  {$region ITreeNode}
  
  IPatternTreeNode<TNode> = interface
  where TNode: class, IPatternTreeNode<TNode>;
    
    function GetFirstChild: TNode;
    function GetChildAfter(n: TNode): TNode;
    function GetParent: TNode;
    
    function GetParentCount: integer;
    function CompareChildInds(n1, n2: TNode): integer;
    
  end;
  
  {$endregion ITreeNode}
  
  {$region NestedCost}
  
  NestedJumpCost<TCost> = record(IJumpCost<NestedJumpCost<TCost>>)
  where TCost: IJumpCost<TCost>;
    private first: TCost;
    private other: Tuple<NestedJumpCost<TCost>> := nil;
    
    public constructor(first: TCost) := self.first := first;
    public constructor := Create(default(TCost));
    
    public static function operator=(c1,c2: NestedJumpCost<TCost>): boolean;
    begin
      Result := false;
      while true do
      begin
        if not c1.first.Equals(c2.first) then exit;
        if (c1.other=nil) <> (c2.other=nil) then exit;
        if c1.other=nil then break;
        c1 := c1.other[0];
        c2 := c2.other[0];
      end;
      Result := true;
    end;
    public static function operator<>(c1,c2: NestedJumpCost<TCost>) := not(c1=c2);
    public function Equals(cost: NestedJumpCost<TCost>) := self=cost;
    
    public static function Compare(c1,c2: NestedJumpCost<TCost>): integer;
    begin
      Result := 0;
      while true do
      begin
        
        Result := c1.first.CompareTo(c2.first);
        if Result<>0 then exit;
        
        var nil1 := c1.other=nil;
        var nil2 := c2.other=nil;
        if nil1 and nil2 then exit;
        
        c1 := if nil1 then default(NestedJumpCost<TCost>) else c1.other[0];
        c2 := if nil2 then default(NestedJumpCost<TCost>) else c2.other[0];
      end;
    end;
    public function CompareTo(cost: NestedJumpCost<TCost>) := Compare(self, cost);
    
    public function Plus(cost: NestedJumpCost<TCost>): NestedJumpCost<TCost>;
    begin
      Result.first := self.first.Plus(cost.first);
      if self.other=nil then
        Result.other := cost.other else
      if cost.other=nil then
        Result.other := self.other else
        Result.other := Tuple.Create( self.other[0].Plus(cost.other[0]) );
    end;
    public function NestedPlus(cost: NestedJumpCost<TCost>): NestedJumpCost<TCost>;
    begin
      Result := self;
      Result.other := Tuple.Create(
        if Result.other=nil then
          cost else Result.other[0].Plus(cost)
      )
    end;
    
    public function ToString: string; override;
    const nest_sep = ' : ';
    begin
      var res := new StringBuilder;
      res += TypeName(self);
      res += '(';
      begin
        var cost := self;
        while true do
        begin
          res += cost.first.ToString;
          res += nest_sep;
          if cost.other=nil then break;
          cost := cost.other[0];
        end;
        res.Length -= nest_sep.Length;
      end;
      res += ')';
      Result := res.ToString;
    end;
    
  end;
  
  {$endregion NestedCost}
  
  NestedPatternDiff<TEdge1,TEdge2> = class
  where TEdge1: class, IPatternTreeNode<TEdge1>;
  where TEdge2: class, IPatternTreeNode<TEdge2>;
    
    
    
  end;
  
  {$region NestedPattern}
  
  NestedPattern = static class
    
//    public static function NextTreeNode<TNode>(n: TNode): TNode;
//      where TNode: class, IPatternTreeNode<TNode>;
//    begin
//      
//      Result := n.GetFirstChild;
//      if Result<>nil then exit;
//      
//      while true do
//      begin
//        var p := n.GetParent;
//        if p=nil then break;
//        Result := p.GetChildAfter(n);
//        if Result<>nil then break;
//        n := p;
//      end;
//      
//    end;
    
//    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
//    static function MinPaths<TEdge1,TEdge2, TCompKey, TCompCost>(
//      root1: TEdge1; root2: TEdge2; zero_cost: TCompCost
//      
//      ; pre_compare_key1: TEdge1 -> TCompKey
//      ; pre_compare_key2: TEdge2 -> TCompKey
//      
//      ; is_same: (TEdge1, TEdge2) -> boolean
//      ; get_compare_cost: (TEdge1, TEdge2) -> TCompCost
//      
//    ): sequence of sequence of NestedPatternDiff<TEdge1,TEdge2>;
//    where TEdge1: class, IPatternTreeNode<TEdge1>;
//    where TEdge2: class, IPatternTreeNode<TEdge2>;
//    where TCompKey: IEquatable<TCompKey>;
//    where TCompCost: IJumpCost<TCompCost>;
    
    //TODO
//    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
//    static function MinPaths<TEdge, TCompKey, TCompCost>(
//      root1,root2: TEdge; zero_cost: TCompCost
//      ; pre_compare_key: TEdge -> TCompKey
//      ; get_compare_cost: (TEdge, TEdge) -> TCompCost
//    ): sequence of sequence of NestedPatternDiff<TEdge,TEdge>;
//      where TEdge: class, IPatternTreeNode<TEdge>;
//      where TCompKey: IEquatable<TCompKey>;
//      where TCompCost: IJumpCost<TCompCost>;
//    begin
//      Result := MinPaths(
//        root1,root2, zero_cost
//        , pre_compare_key,pre_compare_key
//        , get_compare_cost
//      );
//    end;
    
  end;
  
  {$endregion NestedPattern}
  
  {$region Basic Tree Pointer's}
  
  BasicFlatPatternPointer<TNode> = record(IPatternEdgePointer<BasicFlatPatternPointer<TNode>>)
  where TNode: class, IPatternTreeNode<TNode>;
    private n: TNode;
    
    public constructor(n: TNode) := self.n := n;
    public constructor := Create(nil);
    public static function operator implicit(n: TNode): BasicFlatPatternPointer<TNode> :=
    new BasicFlatPatternPointer<TNode>(n);
    
    public function Next: BasicFlatPatternPointer<TNode>;
    begin
      Result := n.GetParent.GetChildAfter(n);
    end;
    
    public function IsOut := n=nil;
    
    public static function operator= (p1, p2: BasicFlatPatternPointer<TNode>) := p1.n =  p2.n;
    public static function operator<>(p1, p2: BasicFlatPatternPointer<TNode>) := p1.n <> p2.n;
    public function Equals(p: BasicFlatPatternPointer<TNode>) := self=p;
    
    public static function Compare(p1, p2: BasicFlatPatternPointer<TNode>): integer;
    begin
      var n1 := p1.n;
      var n2 := p2.n;
      
      var parent := n1.GetParent;
      {$ifdef DEBUG}
      if parent<>n2.GetParent then
        raise new InvalidOperationException($'Compare for nodes of different trees: [{n1}] vs [{n2}]');
      {$endif DEBUG}
      
      Result := parent.CompareChildInds(n1,n2);
    end;
    public function CompareTo(other: BasicFlatPatternPointer<TNode>) := Compare(self, other);
    
  end;
  
  BasicNestedPatternPointer<TNode> = record(IPatternEdgePointer<BasicNestedPatternPointer<TNode>>)
  where TNode: class, IPatternTreeNode<TNode>;
    private n: TNode;
    
    public constructor(n: TNode) := self.n := n;
    public constructor := Create(nil);
    public static function operator implicit(n: TNode): BasicNestedPatternPointer<TNode> :=
    new BasicNestedPatternPointer<TNode>(n);
    
//    public function Next: BasicPatternTreePointer<TNode> := NestedPattern.NextTreeNode(self.n);
    
    public function IsOut := n=nil;
    
    public static function operator= (p1, p2: BasicNestedPatternPointer<TNode>) := p1.n =  p2.n;
    public static function operator<>(p1, p2: BasicNestedPatternPointer<TNode>) := p1.n <> p2.n;
    public function Equals(p: BasicNestedPatternPointer<TNode>) := self=p;
    
    public static function Compare(p1, p2: BasicNestedPatternPointer<TNode>): integer;
    begin
      Result := 0;
      
      var n1 := p1.n;
      var n2 := p2.n;
      if n1=n2 then exit;
      
      var d1 := n1.GetParentCount;
      var d2 := n2.GetParentCount;
      
      var min_d: integer;
      if d2>d1 then
      begin
        Result := -1;
        loop d2-d1 do n2 := n2.GetParent;
        if n1=n2 then exit;
        min_d := d1;
      end else
      if d1>d2 then
      begin
        Result := +1;
        loop d1-d2 do n1 := n1.GetParent;
        if n1=n2 then exit;
        min_d := d2;
      end else
        min_d := d1;
      
      loop min_d do
      begin
        var pn1 := n1.GetParent; {$ifdef DEBUG}if pn1=nil then raise new InvalidOperationException($'Broken ".GetParentCount" of [{p1.n}]');{$endif}
        var pn2 := n2.GetParent; {$ifdef DEBUG}if pn2=nil then raise new InvalidOperationException($'Broken ".GetParentCount" of [{p2.n}]');{$endif}
        if pn1=pn2 then
        begin
          Result := pn1.CompareChildInds(n1,n2);
          {$ifdef DEBUG}
          if Result=0 then
            raise new InvalidOperationException($'Sibling ind dup');
          {$endif DEBUG}
          exit;
        end else
        begin
          n1 := pn1;
          n2 := pn2;
        end;
      end;
      
      raise new InvalidOperationException($'Compare for nodes of different trees: [{n1}] vs [{n2}]');
    end;
    public function CompareTo(other: BasicNestedPatternPointer<TNode>) := Compare(self, other);
    
  end;
  
  {$endregion Basic Tree Pointer's}
  
  {$region BasicTreeNode}
  
  BasicPatternTreeNode<TSelf> = abstract class(IPatternTreeNode<TSelf>)
  where TSelf: BasicPatternTreeNode<TSelf>;
    private depth, ind: integer;
    private parent: TSelf;
    
    public constructor(depth, ind: integer; parent: TSelf);
    begin
      self.depth := depth;
      self.ind := ind;
      self.parent := parent;
    end;
    private constructor := raise new InvalidOperationException;
    
    protected function GetSubNodeAt(ind: integer): TSelf; abstract;
    
    public function GetFirstChild := GetSubNodeAt(0);
    public function GetChildAfter(n: TSelf) := GetSubNodeAt(n.ind+1);
    public function GetParent := self.parent;
    
    public function GetParentCount := self.depth;
    public function CompareChildInds(n1, n2: TSelf) := n1.ind.CompareTo(n2.ind);
    
  end;
  
  {$endregion BasicTreeNode}
  
implementation

type
  NestedPatternPoint<TEdge1,TEdge2> = BasicPatternPoint2<BasicFlatPatternPointer<TEdge1>, BasicFlatPatternPointer<TEdge2>>;
  
  NestedJumpInfo<TEdge1,TEdge2> = sealed class(PatternJumpNode<NestedJumpInfo<TEdge1,TEdge2>>)
  where TEdge1: class, IPatternTreeNode<TEdge1>;
  where TEdge2: class, IPatternTreeNode<TEdge2>;
    private p1, p2: NestedPatternPoint<TEdge1,TEdge2>;
    
    public constructor(prev: NestedJumpInfo<TEdge1,TEdge2>; p1, p2: NestedPatternPoint<TEdge1,TEdge2>);
    begin
      inherited Create(prev);
      self.p1 := p1;
      self.p2 := p2;
    end;
    private constructor;
    begin
      inherited Create(nil);
      raise new System.InvalidOperationException;
    end;
    
  end;
  
  NestedPatternBasicCost = NestedJumpCost<BasicJumpCost>;
  
  NestedPatternZeroJumpResNestedPattern<TEdge1,TEdge2> = ValueTuple<
    NestedPatternPoint<TEdge1,TEdge2>,
    NestedJumpInfo<TEdge1,TEdge2>
  >;
  NestedPatternCostJumpResNestedPattern<TEdge1,TEdge2> = ValueTuple<
    NestedPatternPoint<TEdge1,TEdge2>,
    NestedJumpInfo<TEdge1,TEdge2>,
    NestedPatternBasicCost
  >;
  
//static function NestedPattern.MinPaths<TEdge1, TEdge2, TCompKey, TCompCost>(
function MinPaths<TEdge1, TEdge2, TCompKey, TCompCost>(
  root1: TEdge1; root2: TEdge2; zero_cost: TCompCost
  
  ; pre_compare_key1: TEdge1 -> TCompKey
  ; pre_compare_key2: TEdge2 -> TCompKey
  
  ; is_same: (TEdge1, TEdge2) -> boolean
  ; get_compare_cost: (TEdge1, TEdge2) -> TCompCost
  
): sequence of sequence of NestedPatternDiff<TEdge1,TEdge2>;
  where TEdge1: class, IPatternTreeNode<TEdge1>;
  where TEdge2: class, IPatternTreeNode<TEdge2>;
  where TCompKey: IEquatable<TCompKey>;
  where TCompCost: IJumpCost<TCompCost>;
begin
  
  // По сути надо 2 внешних Pattern.MinPaths:
  // 1. Найти равные под-ключи, с минимумом strafe'ов
  // 2. Найти набор комбинаций, с максимальным кол-вом сочетаний-исправлений, но минимальной суммой get_compare_cost
  
  // А стоит ли 2. усилий? В итоге это оптимизация чтобы по-меньше пересоздавать, но для неё придётся столько всего перебрать...
  
  // Можно использовать метод дарвина, как подсказала CharGPT
  // Но, наверное, это будет выглядеть уродливо
  
  // Можно сортировать по размеру под-дерева и сравнивать только самые большие
  // Но этому подходу тоже нужны магические числа
  
  // А можно ещё сравнивать только под-деревья, пропущенные у обоих деревьев в одном месте
  // {a {b c} e} vs {a {b d} e} => {b c} vs {b d}
  // То есть сравнение должно происходить при strafe'ах
  // Для этого надо будет сделать частичный Pattern.MinPaths
  // То есть возможность расширять edge после окончания поиска пути
  // И это должно работать рекурсивно с под-деревьями,
  // то есть частичным должен быть и NestedPattern.MinPaths тоже
  
  Result := Pattern.MinPaths(
    new NestedPatternPoint<TEdge1,TEdge2>(root1.GetFirstChild, root2.GetFirstChild),
    default(NestedJumpInfo<TEdge1,TEdge2>),
    new NestedPatternBasicCost,
    
    (p,j)->
    begin
      var ep1 := p.Edge1;
      var ep2 := p.Edge2;
      
      while true do
      begin
        if ep1.IsOut then break;
        if ep2.IsOut then break;
        if not is_same(ep1.n, ep2.n) then break;
        ep1 := root1.GetChildAfter(ep1.n);
        ep2 := root2.GetChildAfter(ep2.n);
      end;
      
      Result := |new NestedPatternZeroJumpResNestedPattern<TEdge1,TEdge2>(
        ValueTuple.Create(ep1, ep2), j
      )|;
    end,
    
    (p,j)->
    begin
      var strafe_start := p;
      if j.p2=p then
      begin
        strafe_start := j.p1;
        j := j.Prev;
      end;
      var cost := new NestedPatternBasicCost(1);
      
      var MakeRes: (TEdge1,TEdge2)->NestedPatternCostJumpResNestedPattern<TEdge1,TEdge2> := (ep1, ep2)->
      begin
        
        //TODO Посчитать nested_cost и кэш частичного NestedPattern.MinPaths, чтобы сохранить в NestedJumpInfo
        // - При этом ещё надо использовать этот кэш в рекурсивном NestedPattern.MinPaths
        
        var end_p := new NestedPatternPoint<TEdge1,TEdge2>(ep1,ep2);
        Result := new NestedPatternCostJumpResNestedPattern<TEdge1,TEdge2>(
          end_p,
          new NestedJumpInfo<TEdge1,TEdge2>(j, strafe_start, end_p),
          cost.NestedPlus(nested_cost)
        );
      end;
      
      var ep1 := p.Edge1;
      var ep2 := p.Edge2;
      Result := new List<NestedPatternCostJumpResNestedPattern<TEdge1,TEdge2>>(2);
      
      if not ep1.IsOut then
        Result += MakeRes(ep1.Next, ep2);
      if not ep2.IsOut then
        Result += MakeRes(ep1, ep2.Next);
      
      {$ifdef DEBUG}
      if Result.Count=0 then
        raise new InvalidOperationException;
      {$endif DEBUG}
    end
    
  ).Select(j->j.ToPath)
  .Select(path->
  begin
    //TODO
    Result := |new NestedPatternDiff<TEdge1,TEdge2>|.AsEnumerable;
  end);
  
end;

end.