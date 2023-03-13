unit CharPatterns;

interface

uses System;

uses Parsing  in '..\Parsing';
uses Patterns in '..\Patterns';

type
  
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
      if ReferenceEquals(i1.s.text, i2.s.text) and (i1.s.I2 = i2.s.I2) then exit;
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
  
implementation



end.