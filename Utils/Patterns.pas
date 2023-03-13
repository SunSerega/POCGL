unit Patterns;
{$zerobasedstrings}

interface

uses System;
uses System.Runtime.CompilerServices;

//TODO IPatternEdgePointer<TData, TSelf>
// - Позволит передавать на много меньше данных, но взамен код станет значительно сложнее...

type
  
  {$region Generic Pattern}
  
  {$region Point}
  
  IPatternPoint<TSelf> = interface(IEquatable<TSelf>)
  where TSelf: IPatternPoint<TSelf>;
    
    function AnyEdgesDone: boolean;
    function AllEdgesDone: boolean;
    
    function IncLessThan(p: TSelf): boolean;
    
  end;
  
  {$endregion Point}
  
  {$region Cost}
  
  IJumpCost<TSelf> = interface(IEquatable<TSelf>, IComparable<TSelf>)
  where TSelf: IJumpCost<TSelf>;
    
    function Plus(other: TSelf): TSelf;
    
  end;
  
  {$endregion Cost}
  
  {$region Algorithm}
  
  Pattern = static class
    
//    private constructor := raise new System.InvalidOperationException;
    
    ///p0: The Point looking at the first symbol of all edges
    /// - Must implement IPatternPoint<TSelf>
    ///
    ///get_zero_jumps: Zero cost jump generator
    ///get_cost_jumps: Non-zero cost jump generator
    /// - Cheapest jump sequence will be returned
    ///on_no_path what to do when no path was found
    /// - If no set and no path found, throws InvalidOperationException
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static function MinPaths<TPoint, TJumpNode,TJumpCost>(
      p0: TPoint; zero_jump: TJumpNode; zero_cost: TJumpCost
      ; get_zero_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode>
      ; get_cost_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode,TJumpCost>
    ): ValueTuple<sequence of TJumpNode, TJumpCost>;
    where TPoint: IPatternPoint<TPoint>;
    where TJumpCost: IJumpCost<TJumpCost>;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static function AllPaths<TPoint, TJumpNode>(
      p0: TPoint; zero_jump: TJumpNode
      ; get_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode>
    ): sequence of TJumpNode;
    where TPoint: IPatternPoint<TPoint>;
    
  end;
  
  {$endregion Algorithm}
  
  {$endregion Generic Pattern}
  
  {$region Basic Pattern}
  
  {$region Edge}
  
  IPatternEdgePointer<TSelf> = interface(IComparable<TSelf>, IEquatable<TSelf>)
  where TSelf: IPatternEdgePointer<TSelf>;
    
    function IsOut: boolean;
    
  end;
  
  IPatternEdgeJumpGeneratable<TSelf, TOther, TCost> = interface(IPatternEdgePointer<TSelf>)
  where TSelf:  IPatternEdgePointer<TSelf>, IPatternEdgeJumpGeneratable<TSelf, TOther, TCost>;
  where TOther: IPatternEdgePointer<TOther>;
    
    function MakeZeroJumps(other: TOther): sequence of ValueTuple<TSelf, TOther>;
    function MakeCostJumps(other: TOther): sequence of ValueTuple<TSelf, TOther, TCost>;
    
  end;
  
  {$endregion Edge}
  
  {$region Point}
  
  BasicPatternPoint1<TPointer> = record(IPatternPoint<BasicPatternPoint1<TPointer>>)
  where TPointer: IPatternEdgePointer<TPointer>;
    private ep: TPointer;
    
    public constructor(ep: TPointer) := self.ep := ep;
    public constructor := Create(default(TPointer));
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AnyEdgesDone := ep.IsOut;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AllEdgesDone := ep.IsOut;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function IncLessThan(p: BasicPatternPoint1<TPointer>) := self.ep.CompareTo(p.ep)<=0;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Equals(p: BasicPatternPoint1<TPointer>) := self.ep.Equals(p.ep);
    
    public static function operator implicit(ep: TPointer): BasicPatternPoint1<TPointer> :=
    new BasicPatternPoint1<TPointer>(ep);
    
    public property Edge: TPointer read ep;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}(Edge={Edge})';
    
  end;
  
  BasicPatternPointRec<TPointer, TOther> = record(IPatternPoint<BasicPatternPointRec<TPointer, TOther>>)
  where TPointer: IPatternEdgePointer<TPointer>;
  where TOther: IPatternPoint<TOther>;
    private first: BasicPatternPoint1<TPointer>;
    private other: TOther;
    
    public constructor(first: BasicPatternPoint1<TPointer>; other: TOther);
    begin
      self.first := first;
      self.other := other;
    end;
    public constructor := Create(default(TPointer), default(TOther));
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AnyEdgesDone := first.AnyEdgesDone  or other.AnyEdgesDone;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AllEdgesDone := first.AllEdgesDone and other.AllEdgesDone;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function IncLessThan(p: BasicPatternPointRec<TPointer, TOther>) := first.IncLessThan(p.first) and other.IncLessThan(p.other);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Equals(p: BasicPatternPointRec<TPointer, TOther>) := self.first.Equals(p.first) and self.other.Equals(p.other);
    
    public property FirstEdge: TPointer read first.Edge;
    public property OtherEdges: TOther read other;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}(FirstEdge={FirstEdge}; OtherEdges={OtherEdges})';
    
  end;
  
  BasicPatternPoint2<TPointer1, TPointer2> = record(IPatternPoint<BasicPatternPoint2<TPointer1, TPointer2>>)
  where TPointer1: IPatternEdgePointer<TPointer1>;
  where TPointer2: IPatternEdgePointer<TPointer2>;
    private impl: BasicPatternPointRec<TPointer1, BasicPatternPoint1<TPointer2>>;
    
    public constructor(ep1: TPointer1; ep2: TPointer2) := impl :=
    new BasicPatternPointRec<TPointer1, BasicPatternPoint1<TPointer2>>(ep1, ep2);
    public static function operator implicit(p: ValueTuple<TPointer1, TPointer2>): BasicPatternPoint2<TPointer1, TPointer2> :=
    new BasicPatternPoint2<TPointer1, TPointer2>(p.Item1, p.Item2);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AnyEdgesDone := impl.AnyEdgesDone;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AllEdgesDone := impl.AllEdgesDone;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function IncLessThan(p: BasicPatternPoint2<TPointer1, TPointer2>) := impl.IncLessThan(p.impl);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Equals(p: BasicPatternPoint2<TPointer1, TPointer2>) := impl.Equals(p.impl);
    
    public property Edge1: TPointer1 read impl.FirstEdge;
    public property Edge2: TPointer2 read impl.OtherEdges.Edge;
    
    public function ToString: string; override :=
    $'({Edge1}; {Edge2})';
//    $'{self.GetType.Name}(Edge1={Edge1}; Edge2={Edge2})';
    
  end;
  
  {$endregion Point}
  
  {$region Jump}
  
  PatternJumpNode<TJumpNode> = abstract class
  where TJumpNode: PatternJumpNode<TJumpNode>;
    private _prev: TJumpNode;
    
    protected constructor(prev: TJumpNode) := self._prev := prev;
    private constructor := raise new System.InvalidOperationException;
    
    public property Prev: TJumpNode read _prev;
    
  end;
  PatternPath<TJumpNode> = record
  where TJumpNode: PatternJumpNode<TJumpNode>;
    public n: TJumpNode;
    public constructor(n: TJumpNode) := self.n := n;
    public static function operator implicit(n: TJumpNode): PatternPath<TJumpNode> :=
    new PatternPath<TJumpNode>(n);
    
    public function Count: integer;
    begin
      Result := 0;
      var n := self.n;
      while n<>nil do
      begin
        Result += 1;
        n := n.Prev;
      end;
    end;
    
    public function ToArray<TRes>(f: TJumpNode->TRes): array of TRes;
    begin
      Result := new TRes[self.Count];
      var n := self.n;
      for var i := Result.Length-1 downto 0 do
      begin
        Result[i] := f(n);
        n := n.Prev;
      end;
    end;
    
    public function ToString: string; override :=
    self.ToArray(n->n).JoinToString(', ');
    
  end;
  
  {$endregion Jump}
  
  {$region Cost}
  
  BasicJumpCost = record(IJumpCost<BasicJumpCost>)
    private val: integer;
    
    public constructor(val: integer) := self.val := val;
    public constructor := Create(0);
    
    public property Value: integer read val;
    
    public static function operator implicit(cost: integer): BasicJumpCost := new BasicJumpCost(cost);
    public static function operator implicit(cost: BasicJumpCost): integer := cost.Value;
    
    public function Equals(cost: BasicJumpCost) := self.val = cost.val;
    public function CompareTo(cost: BasicJumpCost) := self.val.CompareTo(cost.val);
    
    public function Plus(cost: BasicJumpCost): BasicJumpCost := self.val+cost.val;
    
    public function ToString: string; override :=
    $'{TypeName(self)}({val})';
    
  end;
  
  {$endregion Cost}
  
  {$region Algorithm}
  
  BasicPatternDiffBase = abstract class
    private ind: integer;
    
    private constructor(ind: integer) := self.ind := ind;
    private constructor := raise new System.InvalidOperationException;
    
    public property Index: integer read ind;
    
  end;
  BasicPatternDiff<TPointer> = sealed class(BasicPatternDiffBase)
    private p1,p2: TPointer;
    
    private constructor(ind: integer; p1,p2: TPointer);
    begin
      inherited Create(ind);
      self.p1 := p1;
      self.p2 := p2;
    end;
    private constructor := inherited Create;
    
    public property JumpF: TPointer read p1;
    public property JumpT: TPointer read p2;
    
  end;
  
  BasicPattern = static class
    
    public static function MinPaths<TPointer1,TPointer2>(ep1: TPointer1; ep2: TPointer2): sequence of array of BasicPatternDiffBase;
    where TPointer1: record, IPatternEdgePointer<TPointer1>;
    where TPointer2: record, IPatternEdgePointer<TPointer2>;
    
    public static function MinPaths<TPointer>(ep1, ep2: TPointer): sequence of array of BasicPatternDiff<TPointer>;
    where TPointer: record, IPatternEdgePointer<TPointer>;
    
  end;
  
  {$endregion Algorithm}
  
  {$endregion Basic Pattern}
  
implementation

function ToPath<TJumpNode>(self: TJumpNode): PatternPath<TJumpNode>; extensionmethod;
  where TJumpNode: PatternJumpNode<TJumpNode>;
begin
  Result := self;
end;

{$region Pattern}

type
  PatternCostStep<TPoint, TJumpNode,TJumpCost> = sealed class
  where TPoint: IPatternPoint<TPoint>;
  where TJumpCost: IJumpCost<TJumpCost>;
    cost: TJumpCost;
    pts: List<ValueTuple<TPoint, TJumpNode>>;
    next := default(PatternCostStep<TPoint, TJumpNode,TJumpCost>);
    
    constructor(cost: TJumpCost; pts: List<ValueTuple<TPoint, TJumpNode>>);
    begin
      self.cost := cost;
      self.pts := pts ?? new List<ValueTuple<TPoint, TJumpNode>>;
      {$ifdef DEBUG}
      if self.pts.Any then raise new System.InvalidOperationException($'Old buffer was not empty');
      {$endif DEBUG}
    end;
    constructor := raise new System.InvalidOperationException;
    
    function HasBetterThan(p: TPoint): boolean;
    begin
      Result := false;
      
      foreach var j_res in self.pts do
      begin
        Result := p.IncLessThan(j_res.Item1);
        if Result then exit;
      end;
      
    end;
    
    procedure RemoveWorseThan(p: TPoint) :=
    pts.RemoveAll(j_res->j_res.Item1.IncLessThan(p));
    
  end;
  
  PatternMinCombinationState<TPoint, TJumpNode,TJumpCost> = record
  where TPoint: IPatternPoint<TPoint>;
  where TJumpCost: IJumpCost<TJumpCost>;
    min_step: PatternCostStep<TPoint, TJumpNode,TJumpCost>;
    old_step_buff: List<ValueTuple<TPoint, TJumpNode>> := nil;
    
    function CheckInsertable(p: TPoint; cost: TJumpCost): PatternCostStep<TPoint, TJumpNode,TJumpCost>;
    begin
      Result := nil;
      var curr := Result;
      var next := min_step;
      
      while (next<>nil) and (next.cost.CompareTo(cost)<0) do
      begin
        curr := next;
        if curr.HasBetterThan(p) then exit;
        next := curr.next;
      end;
      
      if (next=nil) or (next.cost.CompareTo(cost)<>0) then
      begin
        Result := new PatternCostStep<TPoint, TJumpNode,TJumpCost>(cost, old_step_buff);
        if curr=nil then
          min_step := Result else
          curr.next := Result;
        Result.next := next;
        old_step_buff := nil;
      end else
      begin
        if next.HasBetterThan(p) then exit;
        next.RemoveWorseThan(p);
        Result := next;
      end;
      
      curr := Result.next;
      while curr<>nil do
      begin
        curr.RemoveWorseThan(p);
        curr := curr.next;
      end;
      
    end;
    
  end;
  
static function Pattern.MinPaths<TPoint, TJumpNode,TJumpCost>(
  p0: TPoint; zero_jump: TJumpNode; zero_cost: TJumpCost
  ; get_zero_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode>
  ; get_cost_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode,TJumpCost>
): ValueTuple<sequence of TJumpNode, TJumpCost>;
where TPoint: IPatternPoint<TPoint>;
where TJumpCost: IJumpCost<TJumpCost>;
begin
  var state := new PatternMinCombinationState<TPoint, TJumpNode,TJumpCost>;
  state.min_step := new PatternCostStep<TPoint, TJumpNode,TJumpCost>(zero_cost, nil);
  
  begin
    var pjs := get_zero_jumps(p0, zero_jump);
    foreach var pj in pjs index i do
    begin
      var (p,j) := pj;
      if p.AllEdgesDone then
      begin
        Result := ValueTuple.Create(
          j + pjs.Skip(i+1).Where(\(p,j)->p.AllEdgesDone).Select(\(p,j)->j),
          zero_cost
        );
        exit;
      end;
      state.min_step.pts += pj;
    end;
  end;
  
  while true do
  begin
    var consumed_step := state.min_step;
    if consumed_step=nil then break;
    
    var old_cost := consumed_step.cost;
    var old_buff := consumed_step.pts;
    state.min_step := consumed_step.next;
    
//    old_buff.PrintLines(\(old_p, old_l)->old_l);
//    Writeln('='*30);
    
    foreach var old_pj in old_buff index i do
    begin
      var (old_p, old_j) := old_pj;
      
      if old_p.AllEdgesDone then
      begin
        Result := ValueTuple.Create(
          old_j + old_buff.Skip(i+1).Where(\(p,j)->p.AllEdgesDone).Select(\(p,j)->j),
          old_cost
        );
        exit;
      end;
      
      foreach var (mid_p, mid_j, cost) in get_cost_jumps(old_p, old_j) do
      begin
        cost := old_cost.Plus(cost);
        
        foreach var (p,j) in get_zero_jumps(mid_p, mid_j) do
        begin
          var step := state.CheckInsertable(p, cost);
          if step=nil then continue;
          step.pts += ValueTuple.Create(p, j);
        end;
        
      end;
      
    end;
    
    old_buff.Clear;
    state.old_step_buff := old_buff;
  end;
  
end;

static function Pattern.AllPaths<TPoint, TJumpNode>(
  p0: TPoint; zero_jump: TJumpNode
  ; get_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode>
): sequence of TJumpNode;
where TPoint: IPatternPoint<TPoint>;
begin
  var st := new Stack<ValueTuple<TPoint,TJumpNode>>;
  st += ValueTuple.Create(p0, zero_jump);
  
  while st.Count<>0 do
  begin
    var (old_p, old_j) := st.Pop;
    
    foreach var pj in get_jumps(old_p, old_j) do
    begin
      var (p,j) := pj;
      {$ifdef DEBUG}
      if st.Any and not st.Peek.Item1.IncLessThan(p) then
        raise new System.InvalidOperationException($'Points should be ordered');
      {$endif DEBUG}
      if p.AllEdgesDone then
        yield j else
        st.Push(pj);
    end;
    
  end;
  
end;

{$endregion Pattern}

{$region Pattern2EdgeJumpGenerator}

type
  Pattern2EdgeMakeZeroJumpsFunc<T1,T2> = function(var ep1: T1; ep2: T2): sequence of ValueTuple<T1,T2>;
  Pattern2EdgeMakeCostJumpsFunc<T1,T2> = function(var ep1: T1; ep2: T2): sequence of ValueTuple<T1,T2, BasicJumpCost>;
  Pattern2EdgeJumpGenerator<TPointer1, TPointer2> = sealed class
  where TPointer1: record, IPatternEdgePointer<TPointer1>;
  where TPointer2: record, IPatternEdgePointer<TPointer2>;
    public static make_zero: Pattern2EdgeMakeZeroJumpsFunc<TPointer1,TPointer2> := nil;
    public static make_cost: Pattern2EdgeMakeCostJumpsFunc<TPointer1,TPointer2> := nil;
    
    private constructor := raise new System.InvalidOperationException;
    
    static constructor;
    begin
      var gen_intr := typeof(IPatternEdgeJumpGeneratable<,,>);
      try
        gen_intr := gen_intr.MakeGenericType(
          typeof(TPointer1), typeof(TPointer2),
          typeof(BasicJumpCost)
        );
      except
        on ArgumentException do exit;
      end;
//      $'{TypeToTypeName(gen_intr)}.IsAssignableFrom({TypeToTypeName(typeof(TPointer1))}) ='.Print;
      if not gen_intr.IsAssignableFrom(typeof(TPointer1)){.Println} then exit;
      
      var map := typeof(TPointer1).GetInterfaceMap(gen_intr);
//      Writeln(map.TargetMethods[map.InterfaceMethods.IndexOf(gen_intr.GetMethod('MakeZeroJumps'))]);
//      Writeln(typeof(Pattern2EdgeMakeZeroJumpsFunc&<TPointer1, TPointer2>));
      make_zero := Pattern2EdgeMakeZeroJumpsFunc&<TPointer1, TPointer2>( map.TargetMethods[map.InterfaceMethods.IndexOf(gen_intr.GetMethod('MakeZeroJumps'))].CreateDelegate(typeof(Pattern2EdgeMakeZeroJumpsFunc<TPointer1, TPointer2>)) );
      make_cost := Pattern2EdgeMakeCostJumpsFunc&<TPointer1, TPointer2>( map.TargetMethods[map.InterfaceMethods.IndexOf(gen_intr.GetMethod('MakeCostJumps'))].CreateDelegate(typeof(Pattern2EdgeMakeCostJumpsFunc<TPointer1, TPointer2>)) );
      
    end;
    
    static function WrapZero: BasicPatternPoint2<TPointer1, TPointer2> -> sequence of BasicPatternPoint2<TPointer1, TPointer2>;
    begin
      if Pattern2EdgeJumpGenerator&<TPointer1, TPointer2>.make_zero<>nil then
        Result := p ->
          Pattern2EdgeJumpGenerator&<TPointer1, TPointer2>.make_zero(p.impl.first.ep, p.Edge2)
          .Select(\(ep1,ep2) -> new BasicPatternPoint2<TPointer1, TPointer2>(ep1, ep2)) else
      if Pattern2EdgeJumpGenerator&<TPointer2, TPointer1>.make_zero<>nil then
        Result := p ->
          Pattern2EdgeJumpGenerator&<TPointer2, TPointer1>.make_zero(p.impl.other.ep, p.Edge1)
          .Select(\(ep2,ep1) -> new BasicPatternPoint2<TPointer1, TPointer2>(ep1, ep2)) else
        raise new System.InvalidOperationException;
    end;
    
    static function WrapCost: BasicPatternPoint2<TPointer1, TPointer2> -> sequence of ValueTuple<BasicPatternPoint2<TPointer1, TPointer2>, BasicJumpCost>;
    begin
      if Pattern2EdgeJumpGenerator&<TPointer1, TPointer2>.make_cost<>nil then
        Result := p ->
          Pattern2EdgeJumpGenerator&<TPointer1, TPointer2>.make_cost(p.impl.first.ep, p.Edge2)
          .Select(\(ep1,ep2, cost) -> ValueTuple.Create(new BasicPatternPoint2<TPointer1, TPointer2>(ep1, ep2), cost)) else
      if Pattern2EdgeJumpGenerator&<TPointer2, TPointer1>.make_cost<>nil then
        Result := p->
          Pattern2EdgeJumpGenerator&<TPointer2, TPointer1>.make_cost(p.impl.other.ep, p.Edge1)
          .Select(\(ep2,ep1, cost) -> ValueTuple.Create(new BasicPatternPoint2<TPointer1, TPointer2>(ep1, ep2), cost)) else
        raise new System.InvalidOperationException;
    end;
    
  end;
  
{$endregion Pattern2EdgeJumpGenerator}

{$region BasicPattern.MinCombination}

type
  BasicPatternJumpNode = sealed class(PatternJumpNode<BasicPatternJumpNode>)
    public diff: BasicPatternDiffBase;
    public constructor(prev: BasicPatternJumpNode; diff: BasicPatternDiffBase);
    begin
      inherited Create(prev);
      self.diff := diff;
    end;
  end;
  
function BasicMinCombination<TPointer1,TPointer2>(ep1: TPointer1; ep2: TPointer2): sequence of PatternPath<BasicPatternJumpNode>;
  where TPointer1: record, IPatternEdgePointer<TPointer1>;
  where TPointer2: record, IPatternEdgePointer<TPointer2>;
begin
  
  foreach var n in Pattern.MinPaths(
    new BasicPatternPoint2<TPointer1, TPointer2>(ep1, ep2),
    default(BasicPatternJumpNode),
    new BasicJumpCost,
    
    (p, j) -> Pattern2EdgeJumpGenerator&<TPointer1,TPointer2>.WrapZero()(p)
      .Select(np->ValueTuple.Create(np, j)),
    
    (p, j) -> Pattern2EdgeJumpGenerator&<TPointer1,TPointer2>.WrapCost()(p)
      .Select(\(np,cost)->
      begin
        var nj := j;
        if p.Edge1 <> np.Edge1 then
          nj := new BasicPatternJumpNode(nj, new BasicPatternDiff<TPointer1>(1, p.Edge1, np.Edge1));
        if p.Edge2 <> np.Edge2 then
          nj := new BasicPatternJumpNode(nj, new BasicPatternDiff<TPointer2>(2, p.Edge2, np.Edge2));
        Result := ValueTuple.Create(np, nj, cost);
      end)
    
  ).Item1 do yield n;
  
end;

static function BasicPattern.MinPaths<TPointer1,TPointer2>(ep1: TPointer1; ep2: TPointer2): sequence of array of BasicPatternDiffBase;
  where TPointer1: record, IPatternEdgePointer<TPointer1>;
  where TPointer2: record, IPatternEdgePointer<TPointer2>;
begin
  Result := BasicMinCombination(ep1, ep2).Select(p->p.ToArray(n->n.diff));
end;

static function BasicPattern.MinPaths<TPointer>(ep1, ep2: TPointer): sequence of array of BasicPatternDiff<TPointer>;
  where TPointer: record, IPatternEdgePointer<TPointer>;
begin
  Result := BasicMinCombination(ep1, ep2).Select(p->p.ToArray(n->BasicPatternDiff&<TPointer>(n.diff)));
end;

{$endregion BasicPattern.MinCombination}

end.