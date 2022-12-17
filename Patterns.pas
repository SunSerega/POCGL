unit Patterns;
{$zerobasedstrings}

//TODO #2739
{$savepcu false}

interface

uses System;
uses System.Runtime. InteropServices;
uses System.Runtime.CompilerServices;

uses Parsing;

//TODO IPatternEdgePointer<TData, TSelf>
// - Позволит передавать на много меньше данных, но взамен код станет значительно сложнее...

type
  {$region Pattern}
  
  IPatternPoint<TSelf> = interface(IEquatable<TSelf>)
  where TSelf: IPatternPoint<TSelf>;
    
    function AnyEdgesDone: boolean;
    function AllEdgesDone: boolean;
    
    function IncLessThan(p: TSelf): boolean;
    
  end;
  
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
  
  IJumpCost<TSelf> = interface(IEquatable<TSelf>, IComparable<TSelf>)
  where TSelf: IJumpCost<TSelf>;
    
    function Plus(other: TSelf): TSelf;
    
  end;
  
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
    ): sequence of TJumpNode;
    where TPoint: IPatternPoint<TPoint>;
    where TJumpCost: IJumpCost<TJumpCost>;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static function AllPaths<TPoint, TJumpNode>(
      p0: TPoint; zero_jump: TJumpNode
      ; get_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode>
    ): sequence of TJumpNode;
    where TPoint: IPatternPoint<TPoint>;
    
  end;
  
  {$endregion Pattern}
  
  {$region Basic PatternPoint's}
  
  IPatternEdgePointer<TSelf> = interface(IComparable<TSelf>)
  where TSelf: IPatternEdgePointer<TSelf>;
    
    function IsOut: boolean;
    
  end;
  
  BasicPatternPointDummy<TPointer> = record(IPatternPoint<BasicPatternPointDummy<TPointer>>)
  where TPointer: IPatternEdgePointer<TPointer>;
    private ep: TPointer;
    
    public constructor(ep: TPointer) := self.ep := ep;
    public constructor := Create(default(TPointer));
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AnyEdgesDone := ep.IsOut;
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AllEdgesDone := ep.IsOut;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function IncLessThan(p: BasicPatternPointDummy<TPointer>) := self.ep.CompareTo(p.ep)<=0;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Equals(p: BasicPatternPointDummy<TPointer>) := self.ep = p.ep;
    
    public static function operator implicit(ep: TPointer): BasicPatternPointDummy<TPointer> :=
    new BasicPatternPointDummy<TPointer>(ep);
    
    public property Edge: TPointer read ep;
    
    public function ToString: string; override :=
    $'{self.GetType.Name}(Edge={Edge})';
    
  end;
  
  BasicPatternPointRec<TPointer, TOther> = record(IPatternPoint<BasicPatternPointRec<TPointer, TOther>>)
  where TPointer: IPatternEdgePointer<TPointer>;
  where TOther: IPatternPoint<TOther>;
    private first: BasicPatternPointDummy<TPointer>;
    private other: TOther;
    
    public constructor(first: BasicPatternPointDummy<TPointer>; other: TOther);
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
    private impl: BasicPatternPointRec<TPointer1, BasicPatternPointDummy<TPointer2>>;
    
    public constructor(ep1: TPointer1; ep2: TPointer2) := impl :=
    new BasicPatternPointRec<TPointer1, BasicPatternPointDummy<TPointer2>>(ep1, ep2);
    
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
  
  {$endregion Basic PatternPoint's}
  
  {$region BasicCharIterator}
  
  //TODO Move
  IPatternEdgeJumpGeneratable<TOther, TSelf, TCost> = interface
    
    function MakeZeroJumps(other: TOther): sequence of ValueTuple<TSelf, TOther>;
    function MakeCostJumps(other: TOther): sequence of ValueTuple<TSelf, TOther, TCost>;
    
  end;
  
  //TODO Move
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
  
  BasicCharIterator = record(IPatternEdgePointer<BasicCharIterator>, IPatternEdgeJumpGeneratable<BasicCharIterator, BasicCharIterator, BasicJumpCost>)
    private s: StringSection;
    
    public constructor(s: StringSection) := self.s := s;
    public constructor(s: string) := Create(new StringSection(s));
    public constructor := Create('');
    
    public static function operator implicit(s: StringSection): BasicCharIterator := new BasicCharIterator(s);
    public static function operator implicit(s: string): BasicCharIterator := new BasicCharIterator(s);
    
    public function IsOut := s.Length=0;
    
    {$ifdef DEBUG}
    private static procedure EnsureRelated(i1,i2: BasicCharIterator);
    begin
      if (i1.s.text <> i2.s.text) or (i1.s.I2   <> i2.s.I2) then
        raise new System.InvalidOperationException($'{i1.s.text}[{i1.s.range}] ~ {i2.s.text}[{i2.s.range}]');
    end;
    {$endif DEBUG}
    public function CompareTo(i: BasicCharIterator): integer;
    begin
      {$ifdef DEBUG}
      EnsureRelated(self, i);
      {$endif DEBUG}
      Result := self.s.I1.CompareTo(i.s.I1);
    end;
    
    public static function operator=(i1, i2: BasicCharIterator): boolean;
    begin
      {$ifdef DEBUG}
      EnsureRelated(i1, i2);
      {$endif DEBUG}
      Result := i1.s.I1 = i2.s.I1;
    end;
    public static function operator<>(i1, i2: BasicCharIterator) := not (i1=i2);
    public function Equals(i: BasicCharIterator) := self=i;
    public function Equals(o: object): boolean; override :=
    (o is BasicCharIterator(var i)) and self.Equals(i);
    
    public property Current: char read s.First;
    
    public static function Between(i1, i2: BasicCharIterator): StringSection;
    begin
      {$ifdef DEBUG}
      EnsureRelated(i1, i2);
      {$endif DEBUG}
      Result := i1.s.WithI2(i2.s.I1);
    end;
    
    public static function MakeZeroJumps(i1, i2: BasicCharIterator): sequence of ValueTuple<BasicCharIterator, BasicCharIterator>;
    begin
      
      loop Min(i1.s.Length, i2.s.Length) do
      begin
        if i1.Current <> i2.Current then break;
        i1.s.range.i1 += 1;
        i2.s.range.i1 += 1;
      end;
      
      Result := |ValueTuple.Create(i1,i2)|;
    end;
    public function MakeZeroJumps(i: BasicCharIterator) := BasicCharIterator.MakeZeroJumps(self, i);
    
    public static function MakeCostJumps(i1, i2: BasicCharIterator): sequence of ValueTuple<BasicCharIterator, BasicCharIterator, BasicJumpCost>;
    begin
      var need1 := not i1.IsOut;
      var need2 := not i2.IsOut;
      
      var res := new ValueTuple<BasicCharIterator, BasicCharIterator, BasicJumpCost>[Ord(need1)+Ord(need2)];
      if need1 then
      begin
        res[Ord(false)].Item1 := i1.s.TrimFirst(1);
        res[Ord(false)].Item2 := i2;
        res[Ord(false)].Item3 := 1;
      end;
      if need2 then
      begin
        res[Ord(need1)].Item1 := i1;
        res[Ord(need1)].Item2 := i2.s.TrimFirst(1);
        res[Ord(need1)].Item3 := 1;
      end;
      
      Result := res;
    end;
    public function MakeCostJumps(i: BasicCharIterator) := BasicCharIterator.MakeCostJumps(self, i);
    
    public function ToString: string; override :=
    s.I1.ToString;
//    $'{TypeName(self)}(ind={s.I1}; left={s})';
    
  end;
  
  {$endregion BasicCharIterator}
  
  {$region BasicPattern}
  
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
  
  {$endregion BasicPattern}
  
implementation

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
): sequence of TJumpNode;
where TPoint: IPatternPoint<TPoint>;
where TJumpCost: IJumpCost<TJumpCost>;
begin
  var state := new PatternMinCombinationState<TPoint, TJumpNode,TJumpCost>;
  state.min_step := new PatternCostStep<TPoint, TJumpNode,TJumpCost>(zero_cost, nil);
  
  var found_res := false;
  foreach var pj in get_zero_jumps(p0, zero_jump) do
  begin
    var (p,j) := pj;
    if p.AllEdgesDone then
    begin
      found_res := true;
      yield j;
    end;
    if found_res then continue;
    state.min_step.pts += pj;
  end;
  
  while true do
  begin
    if found_res then break;
    var consumed_step := state.min_step;
    if consumed_step=nil then break;
    
    var old_cost := consumed_step.cost;
    var old_buff := consumed_step.pts;
    state.min_step := consumed_step.next;
    
//    old_buff.PrintLines(\(old_p, old_l)->old_l);
//    Writeln('='*30);
    
    foreach var old_pj in old_buff do
    begin
      var (old_p, old_j) := old_pj;
      
      if old_p.AllEdgesDone then
      begin
        found_res := true;
        yield old_j;
      end;
      if found_res then continue;
      
      foreach var (mid_p, mid_j, cost) in get_cost_jumps(old_p, old_j) do
      begin
        cost := cost.Plus(old_cost);
        
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
      var gen_intr := typeof(IPatternEdgeJumpGeneratable<TPointer2, TPointer1, BasicJumpCost>);
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
    
  ) do yield n;
  
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