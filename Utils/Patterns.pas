unit Patterns;
{$zerobasedstrings}

interface

uses System;
uses System.Runtime.CompilerServices;

//TODO IPatternEdgePointer<TData, TSelf>
// - Позволит передавать на много меньше данных, но взамен код станет значительно сложнее...

{$ifdef DEBUG}
  {$define PatternPointSorterDebug}
{$endif DEBUG}

type
  
  {$region Generic Pattern}
  
  {$region Point}
  
  IPatternPoint<TSelf> = interface(IEquatable<TSelf>)
  where TSelf: IPatternPoint<TSelf>;
    
    function AllEdgesDone: boolean;
    
  end;
  
  {$endregion Point}
  
  {$region PointSorter}
  
  IPatternPointSorter<TPoint> = interface
  where TPoint: IPatternPoint<TPoint>;
    
    /// Result: (blocked, stop_checking)
    function IsAddBlocked<T>(p: TPoint; lst: List<T>; mapping: T->TPoint; i1,i2: integer{$ifdef PatternPointSorterDebug}; org_p: object{$endif}): ValueTuple<boolean,boolean>;
    /// Result: added, now go cleanup
    function TryAdd<T>(org_p: T; p: TPoint; lst: List<T>; mapping: T->TPoint; i1,i2: integer): boolean;
    /// Result: all corresponding edges in lst[i1:i2] are >=p, stop checking
    function TryFinishAdd<T>(p: TPoint; lst: List<T>; mapping: T->TPoint; i1,i2: integer{$ifdef PatternPointSorterDebug}; org_p: object{$endif}): boolean;
    
  end;
  
  {$endregion PointSorter}
  
  {$region Cost}
  
  IJumpCost<TSelf> = interface(IEquatable<TSelf>, IComparable<TSelf>)
  where TSelf: IJumpCost<TSelf>;
    
    function Plus(other: TSelf): TSelf;
    
  end;
  
  {$endregion Cost}
  
  {$region Algorithm}
  
  Pattern = static class
    
//    private constructor := raise new InvalidOperationException;
    
    ///p0: The Point looking at the first symbol of all edges
    /// - Must implement IPatternPoint<TSelf>
    ///
    ///get_zero_jumps: Zero cost jump generator
    ///get_cost_jumps: Non-zero cost jump generator
    /// - Cheapest jump sequence will be returned
    ///on_no_path what to do when no path was found
    /// - If no set and no path found, throws InvalidOperationException
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static function MinPaths<TPoint,TSorter, TJumpNode,TJumpCost>(
      p0: TPoint; sorter: TSorter; zero_jump: TJumpNode; zero_cost: TJumpCost
      ; get_zero_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode>
      ; get_cost_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode,TJumpCost>
    ): ValueTuple<sequence of TJumpNode, TJumpCost>;
    where TPoint: IPatternPoint<TPoint>;
    where TSorter: IPatternPointSorter<TPoint>;
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
    function AllEdgesDone := ep.IsOut;
    
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
    function AllEdgesDone := first.AllEdgesDone and other.AllEdgesDone;
    
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
    function AllEdgesDone := impl.AllEdgesDone;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function Equals(p: BasicPatternPoint2<TPointer1, TPointer2>) := impl.Equals(p.impl);
    
    public property Edge1: TPointer1 read impl.FirstEdge;
    public property Edge2: TPointer2 read impl.OtherEdges.Edge;
    
    public function ToString: string; override :=
    $'({Edge1}; {Edge2})';
//    $'{self.GetType.Name}(Edge1={Edge1}; Edge2={Edge2})';
    
  end;
  
  {$endregion Point}
  
  {$region PointSorter}
  
  BasicPatternPoint1Sorter<TPointer> = record(IPatternPointSorter<BasicPatternPoint1<TPointer>>)
  where TPointer: IPatternEdgePointer<TPointer>;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    /// Result: (blocked, stop_checking)
    function IsAddBlocked<T>(p: BasicPatternPoint1<TPointer>; lst: List<T>; mapping: T->BasicPatternPoint1<TPointer>; i1,i2: integer{$ifdef PatternPointSorterDebug}; org_p: object{$endif}): ValueTuple<boolean,boolean>;
    begin
      {$ifdef DEBUG}
      if i2-i1 <> 1 then
        raise new InvalidOperationException;
      {$endif DEBUG}
      var blocked := mapping(lst[i1]).Edge.CompareTo(p.Edge) >= 0;
      Result := ValueTuple.Create(
        blocked, true
      );
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    /// Result: added, now go cleanup
    function TryAdd<T>(org_p: T; p: BasicPatternPoint1<TPointer>; lst: List<T>; mapping: T->BasicPatternPoint1<TPointer>; i1,i2: integer): boolean;
    begin
      {$ifdef DEBUG}
      if i2-i1 not in 0..1 then
        raise new InvalidOperationException;
      {$endif DEBUG}
      Result := false;
      if i1=i2 then
        lst.Insert(i1, org_p) else
      if mapping(lst[i1]).Edge.CompareTo(p.Edge) < 0 then
        lst[i1] := org_p else
        exit;
      Result := true;
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    /// Result: all corresponding edges in lst[i1:i2] are >=p, stop checking
    function TryFinishAdd<T>(p: BasicPatternPoint1<TPointer>; lst: List<T>; mapping: T->BasicPatternPoint1<TPointer>; i1,i2: integer{$ifdef PatternPointSorterDebug}; org_p: object{$endif}): boolean;
    begin
      {$ifdef DEBUG}
      if i2-i1 <> 1 then
        raise new InvalidOperationException;
      {$endif DEBUG}
      Result := mapping(lst[i1]).Edge.CompareTo(p.Edge) >= 0;
      if Result then exit;
      lst.RemoveAt(i1);
    end;
    
  end;
  
  BasicPatternPointRecSorter<TPointer, TOther, TOtherSorter> = record(IPatternPointSorter<BasicPatternPointRec<TPointer, TOther>>)
  where TPointer: IPatternEdgePointer<TPointer>;
  where TOther: IPatternPoint<TOther>;
  where TOtherSorter: record, IPatternPointSorter<TOther>, constructor;
    
    static constructor;
    begin
      {$ifdef DEBUG}
      var t := typeof(TOther);
      if not t.IsGenericType then exit;
      t := t.GetGenericTypeDefinition;
      //TODO Протестить ошибку
      if t = typeof(BasicPatternPoint1<>) then
        // Inefficient, instead use BasicPatternPoint2Sorter
        raise new InvalidOperationException;
      {$endif DEBUG}
    end;
    
    private static function FindFEBounds<T>(p: BasicPatternPointRec<TPointer, TOther>; lst: List<T>; mapping: T->BasicPatternPointRec<TPointer, TOther>; i1,i2: integer): ValueTuple<integer, integer>;
    begin
      {$ifdef DEBUG}
      // Empty not allowed
      if i1>=i2 then raise new InvalidOperationException;
      {$endif DEBUG}
//      if i1=i2 then
//      begin
//        Result := ValueTuple.Create(i1,i2);
//        exit;
//      end;
      
      var lb1 := i1;
      var lb2 := i2;
      
      var ub1 := lb1;
      var ub2 := lb2;
      
      while lb2>lb1 do
      begin
        var m := (lb1+lb2) div 2;
        
        var cmp := mapping(lst[m]).FirstEdge.CompareTo(p.FirstEdge);
        if cmp > 0 then
        begin
          lb2 := m;
          ub2 := m;
        end else
        if cmp < 0 then
        begin
          lb1 := m+1;
          ub1 := m+1;
        end else
        begin
          lb2 := m;
          ub1 := m+1;
          break;
        end;
        
      end;
      
      while lb2 > lb1 do
      begin
        var m := (lb1+lb2) div 2;
        
        var cmp := mapping(lst[m]).FirstEdge.CompareTo(p.FirstEdge);
        if cmp >= 0 then
          lb2 := m else
          lb1 := m+1;
        
      end;
      
      while ub2>ub1 do
      begin
        var m := (ub1+ub2) div 2;
        
        var cmp := mapping(lst[m]).FirstEdge.CompareTo(p.FirstEdge);
        if cmp > 0 then
          ub2 := m else
          ub1 := m+1;
        
      end;
      
      Result := ValueTuple.Create(lb1, ub1);
    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static function BinaryFESearchOuter(p: BasicPatternPointRec<TPointer, TOther>; lst: List<T>; mapping: T->BasicPatternPointRec<TPointer, TOther>; i1,i2: integer; strict_cmp: boolean): integer;
    begin
      {$ifdef DEBUG}
      if -1 >= i1 then raise new IndexOutOfRangeException;
      if i1 >= i2 then raise new InvalidOperationException;
      {$endif DEBUG}
      
      var len := i2-i1;
      repeat
        var ld2 := len div 2;
        
        var cmp := mapping(lst[i1+ld2]).FirstEdge.CompareTo(p.FirstEdge);
        if cmp >= Ord(strict_cmp) then
          len := ld2 else
        begin
          i1 += ld2 + 1;
          len -= ld2 + 1;
        end;
        
      until len=0;
      
      Result := i1;
    end;
    
//    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
//    static function BinaryFESearchStep(p: BasicPatternPointRec<TPointer, TOther>; lst: List<T>; mapping: T->BasicPatternPointRec<TPointer, TOther>; from,bound, direction,step: integer): integer;
//    begin
//      {$ifdef DEBUG}
//      if direction=0 then raise new InvalidOperationException('direction=0');
//      if step=0 then raise new InvalidOperationException('step=0');
//      if direction not in -1..+1 then raise new InvalidOperationException($'direction={direction} is not normalized');
//      if Sign(step) <> direction then raise new InvalidOperationException($'step={step} is in wrong direction={direction}');
//      {$endif DEBUG}
//      
//      raise new NotImplementedException;
//      
//    end;
    
    private [MethodImpl(MethodImplOptions.AggressiveInlining)]
    static function BinaryFESearchStepDown(p: BasicPatternPointRec<TPointer, TOther>; lst: List<T>; mapping: T->BasicPatternPointRec<TPointer, TOther>; i1,i2, step: integer): integer;
    begin
      {$ifdef DEBUG}
      if step <= 0 then raise new InvalidOperationException($'step={step}');
      {$endif DEBUG}
      
      
      
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    /// Result: (found <=p, found >=p)
    function FindRelTo<T>(p: BasicPatternPointRec<TPointer, TOther>; lst: List<T>; mapping: T->BasicPatternPointRec<TPointer, TOther>; i1,i2: integer; care_le, care_me: boolean{$ifdef PatternPointSorterDebug}; org_p: object{$endif}): ValueTuple<boolean,boolean>;
    begin
      {$ifdef DEBUG}
      if i1>=i2 then raise new InvalidOperationException;
      {$endif DEBUG}
      
      var fe_more_ind := BinaryFESearchOuter(p, lst, mapping, i1,i2, false);
      
      var oe_mapping: T->TOther :=
        o->mapping(o).OtherEdges;
      
      if fe_more_ind<>i2 then
      begin
        //TODO Дорогостоющая проверка... Проверяющая по сути всё то же самое что нужно, но в обратную сторону
        // - Идея с care_le,care_me интересна, но так же мож всё же придётся делать 2 отдельных метода
        var (fle, fme) := TOtherSorter.Create.FindRelTo(p.OtherEdges, lst, oe_mapping, fe_more_ind,i2{$ifdef PatternPointSorterDebug}, org_p{$endif});
        if fme then
        begin
          Result.Item1 := false; // no <=p, because fe>p.fe, oe>=p.oe
          Result.Item2 := true;
          exit;
        end;
      end;
      
      
      
//      if (fe_more_ind<>i2) and TOtherSorter.Create.FindMore(p.OtherEdges, lst, oe_mapping, fe_more_ind,i2{$ifdef PatternPointSorterDebug}, org_p{$endif}).Item1 then
//      begin
//        Result := ValueTuple.Create(false, true);
//        exit;
//      end;
      
      //TODO Воспрос теперь:
      // - Границы диапазона можно представлять как [i1,i2] вместо [i1,i2) - таким образом смена direction только меняет их местами, без доп. танцев с бубном
      // - Но что насчёт результата функций BinarySearch-, ведь он представляет границу между 2 индексами
      // - Может вообще вывернуть индексы, то есть i := (lst.Count-1)-i
      // - Нет, это лишнее, по сути вопрос только в том как получить следующий элемент, имея индекс границы
      // - Можно индекс границы хранить как i*2-1, тогда (i+direction) div 2 будет следующим индексом
      // - Но если вызов с константным direction инлайнится - if должен быть быстрее...
      
      i2 := fe_more_ind;
      if i1<>i2 then
      begin
        var fe_equ := p.FirstEdge.Equals(lst[fe_more_ind-1]);
        var step := 1;
        repeat
          var i_spl := BinaryFESearchStepDown(p, lst, mapping, i1,i2, step);
          {$ifdef DEBUG}
          if i2>=i_spl then raise new IndexOutOfRangeException;
          if fe_equ <> p.FirstEdge.Equals(lst[i_spl]) then
            raise new System.InvalidOperationException;
          {$endif DEBUG}
          
          // ?????
          var (found_less_equ, found_more_equ) := TOtherSorter.Create.FindLess(p.OtherEdges, lst, oe_mapping, i_spl,i2{$ifdef PatternPointSorterDebug}, org_p{$endif});
          if found_less_equ then
          begin
            Result.Item1 := found_less_equ;
            Result.Item2 := found_more_equ and fe_equ;
            exit;
          end;
          if found_more_equ then
            break;
          
          fe_equ := false;
          step := i2-i_spl;
          i2 := i_spl;
        until i1=i2;
      end;
      
      Result := ValueTuple.Create(false, false);
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    /// Result: found
    function FindMore<T>(p: BasicPatternPointRec<TPointer, TOther>; lst: List<T>; mapping: T->BasicPatternPointRec<TPointer, TOther>; i1,i2: integer{$ifdef PatternPointSorterDebug}; org_p: object{$endif}): ValueTuple<boolean,boolean>;
    begin
      
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    /// Result: added, now go cleanup
    function TryAdd<T>(org_p: T; p: BasicPatternPointRec<TPointer, TOther>; lst: List<T>; mapping: T->BasicPatternPointRec<TPointer, TOther>; i1,i2: integer): boolean;
    begin
      if i1=i2 then
      begin
        //TODO
        exit;
      end;
      
      var (b1,b2) := FindFEBounds(p, lst, mapping, i1,i2);
      
      if b1<>b2 then
      begin
        
      end;
      
      
    end;
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    //TODO Copy description
    /// Result: all corresponding edges in lst[i1:i2] are >=p or deleted, stop checking
    function TryFinishAdd<T>(p: BasicPatternPointRec<TPointer, TOther>; lst: List<T>; mapping: T->BasicPatternPointRec<TPointer, TOther>; i1,i2: integer{$ifdef PatternPointSorterDebug}; org_p: object{$endif}): boolean;
    begin
      
      {$ifdef DEBUG}
      if i1=i2 then raise new InvalidOperationException;
      {$endif DEBUG}
      //TODO Этот случай поидее можно обрабатывать вместе с более общей проверкой
      if mapping[i2-1].FirstEdge.Equals(p) then
      begin
        lst.RemoveAt(i2-1);
        Result := true;
        exit;
      end;
      
      var b1 := i1;
      var b2 := i2;
      while b2>b1 do
      begin
        var m := (b1+b2) div 2;
        
        var cmp := mapping(lst[m]).FirstEdge.CompareTo(p.FirstEdge);
        if cmp > 0 then
          b2 := m else
          b1 := m+1;
        
      end;
      // .FirstEdge in lst[i1:i2] are all >=p.FirstEdge
      //TODO Не единственное условие остановки
      // - Тут проверяется что нет .FirstEdge, которое меньше p
      // - Надо ещё проверить, что нет ничего меньше p в .OtherEdges
      Result := b1=i1;
      
      var oe_mapping := function(o: T): TOther ->
        o->mapping(o).OtherEdges;
      
      i2 := b1;
      while i2>i1 do
      begin
        var m := i2-1;
        var curr_fe := mapping(lst[m]).FirstEdge;
        
        while m>i1 do
        begin
          // Maybe step can be dynamically scaled
          // But it's unlikely to be much better
          var nm := m-1;
          
          if mapping(lst[nm]).FirstEdge.Equals(curr_fe) then
            m := nm else
            break;
          
        end;
        
//        var newly_removed := TOtherSorter.Create.TryFinishAdd(p, lst, oe_mapping, m,i2);
        // Added [5 11 8]
        // Now looking at what to remove:
        //
        // [1 12 8]
        // [2 11 8]
        // [3 7 11]
        // [4 7 10]
        // [4 10 8]
        // [5 7 9]
        // [5 9 7]
        //
        // Need to remove:
        // [2 11 8]
        // [4 10 8]
        // [5 9 7]
        //
        // Only a problem because [7 11] and [10 8] are incomparible
        // (bigger in different directions)
        // Need to break this loop only if all results of oe_mapping were >= 
//        if newly_removed=0 then break;
//        Result += newly_removed;
        
        if TOtherSorter.Create.TryFinishAdd(p.OtherEdges, lst, oe_mapping, m,i2{$ifdef PatternPointSorterDebug}, org_p{$endif}) then break;
        i2 := m;
      end;
      
    end;
    
  end;
  
  BasicPatternPoint2Sorter<TPointer1, TPointer2> = record(IPatternPointSorter<BasicPatternPoint2<TPointer1, TPointer2>>)
  where TPointer1: IPatternEdgePointer<TPointer1>;
  where TPointer2: IPatternEdgePointer<TPointer2>;
    
    //TODO Вызывает методы для PointRec неправильно, надо более оптимизированные версии реализовать
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function AnyMoreEqual   <T>(p: T; lst: List<T>; mapping: T->BasicPatternPoint2<TPointer1, TPointer2>; i1,i2: integer) :=
      BasicPatternPointRecSorter&<TPointer1, BasicPatternPoint1<TPointer2>, BasicPatternPoint1Sorter<TPointer2>>.Create
      .AnyMoreEqual(p, lst, o->mapping(o).impl, i1,i2);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function TryInsert      <T>(p: T; lst: List<T>; mapping: T->BasicPatternPoint2<TPointer1, TPointer2>; i1,i2: integer) :=
      BasicPatternPointRecSorter&<TPointer1, BasicPatternPoint1<TPointer2>, BasicPatternPoint1Sorter<TPointer2>>.Create
      .TryInsert(p, lst, o->mapping(o).impl, i1,i2);
    
    public [MethodImpl(MethodImplOptions.AggressiveInlining)]
    function RemoveLessEqual<T>(p: T; lst: List<T>; mapping: T->BasicPatternPoint2<TPointer1, TPointer2>; i1,i2: integer) :=
      BasicPatternPointRecSorter&<TPointer1, BasicPatternPoint1<TPointer2>, BasicPatternPoint1Sorter<TPointer2>>.Create
      .RemoveLessEqual(p, lst, o->mapping(o).impl, i1,i2);
    
//    public function RemoveLessEqual<T>(p: T; lst: List<T>; mapping: T->BasicPatternPoint1<TPointer>; i1,i2: integer): integer;
//    begin
//      var b1 := i1;
//      var b2 := i2;
//      
//      while b2>b1 do
//      begin
//        var m := (b1+b2) div 2;
//        
//        if mapping(lst[m]).Edge.CompareTo(mapping(p).Edge) <= 0 then
//          b1 := m+1 else
//          b2 := m;
//        
//      end;
//      
//      Result := b1-i1;
//      lst.RemoveRange(i1, Result);
//    end;
    
  end;
  
  {$endregion PointSorter}
  
  {$region Jump}
  
  PatternJumpNode<TJumpNode> = abstract class
  where TJumpNode: PatternJumpNode<TJumpNode>;
    private _prev: TJumpNode;
    
    protected constructor(prev: TJumpNode) := self._prev := prev;
    private constructor := raise new InvalidOperationException;
    
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
    private constructor := raise new InvalidOperationException;
    
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
  PatternCostStep<TPoint,TSorter, TJumpNode,TJumpCost> = sealed class
  where TPoint: IPatternPoint<TPoint>;
  where TSorter: IPatternPointSorter<TPoint>;
  where TJumpCost: IJumpCost<TJumpCost>;
    cost: TJumpCost;
    pts: List<ValueTuple<TPoint, TJumpNode>>;
    next := default(PatternCostStep<TPoint,TSorter, TJumpNode,TJumpCost>);
    
    constructor(cost: TJumpCost; pts: List<ValueTuple<TPoint, TJumpNode>>);
    begin
      self.cost := cost;
      self.pts := pts ?? new List<ValueTuple<TPoint, TJumpNode>>;
      {$ifdef DEBUG}
      if self.pts.Any then raise new InvalidOperationException($'Old buffer was not empty');
      {$endif DEBUG}
    end;
    constructor := raise new InvalidOperationException;
    
//    function HasBetterThan(p: TPoint; sorter: TSorter) :=
//    sorter.AnyMoreEqual(ValueTuple.Create(p, default(TJumpNode)), pts, t->t.Item1, 0,pts.Count);
//    
//    procedure RemoveWorseThan(p: TPoint) :=
//    pts.RemoveAll(j_res->j_res.Item1.IncLessThan(p));
    
  end;
  
  PatternMinCombinationState<TPoint,TSorter, TJumpNode,TJumpCost> = record
  where TPoint: IPatternPoint<TPoint>;
  where TSorter: IPatternPointSorter<TPoint>;
  where TJumpCost: IJumpCost<TJumpCost>;
    min_step: PatternCostStep<TPoint,TSorter, TJumpNode,TJumpCost>;
    old_step_buff: List<ValueTuple<TPoint, TJumpNode>> := nil;
    
    procedure TryInsert(cost: TJumpCost; p: TPoint; sorter: TSorter; n: TJumpNode);
    begin
      var TODO := 0;
//      Result := nil;
//      var curr := Result;
//      var next := min_step;
//      
//      while (next<>nil) and (next.cost.CompareTo(cost)<0) do
//      begin
//        curr := next;
//        if curr.HasBetterThan(p) then exit;
//        next := curr.next;
//      end;
//      
//      if (next=nil) or (next.cost.CompareTo(cost)<>0) then
//      begin
//        Result := new PatternCostStep<TPoint, TJumpNode,TJumpCost>(cost, old_step_buff);
//        if curr=nil then
//          min_step := Result else
//          curr.next := Result;
//        Result.next := next;
//        old_step_buff := nil;
//      end else
//      begin
//        if next.HasBetterThan(p) then exit;
//        next.RemoveWorseThan(p);
//        Result := next;
//      end;
//      
//      curr := Result.next;
//      while curr<>nil do
//      begin
//        curr.RemoveWorseThan(p);
//        curr := curr.next;
//      end;
//      
    end;
    
  end;
  
static function Pattern.MinPaths<TPoint,TSorter, TJumpNode,TJumpCost>(
  p0: TPoint; sorter: TSorter; zero_jump: TJumpNode; zero_cost: TJumpCost
  ; get_zero_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode>
  ; get_cost_jumps: (TPoint, TJumpNode) -> sequence of ValueTuple<TPoint, TJumpNode,TJumpCost>
): ValueTuple<sequence of TJumpNode, TJumpCost>;
where TPoint: IPatternPoint<TPoint>;
where TSorter: IPatternPointSorter<TPoint>;
where TJumpCost: IJumpCost<TJumpCost>;
begin
  var state := new PatternMinCombinationState<TPoint,TSorter, TJumpNode,TJumpCost>;
  state.min_step := new PatternCostStep<TPoint,TSorter, TJumpNode,TJumpCost>(zero_cost, nil);
  
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
      //TODO
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
          state.TryInsert(cost, p, sorter, j);
        
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
        raise new InvalidOperationException($'Points should be ordered');
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
    
    private constructor := raise new InvalidOperationException;
    
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
        raise new InvalidOperationException;
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
        raise new InvalidOperationException;
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
    new BasicPatternPoint2Sorter<TPointer1, TPointer2>,
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