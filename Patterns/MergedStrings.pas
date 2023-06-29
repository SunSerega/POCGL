unit MergedStrings;
{$zerobasedstrings}

interface

uses System;

uses '../Parsing';
uses '../Patterns';
uses '../ColoredStrings';

//TODO Снова использовать MergedStringLength
// - По сути это имеет смысл только в get_*_jumps
// - И только в "operator in", потому что "operator*" всегда может по-стрейфить до конца

type
  {$region MergedString}
  
  MergedString = sealed partial class(IComparable<MergedString>)
    
    private constructor := raise new System.InvalidOperationException;
    
    public static function Literal(s: string): MergedString;
    public static function operator implicit(s: string): MergedString := Literal(s);
    
    public static function Parse(s: StringSection; escape_sym: char := '\'): MergedString;
    public static function Parse(s: string; escape_sym: char := '\') := Parse(new StringSection(s), escape_sym);
    
    public static function operator=(s1, s2: MergedString): boolean;
    public static function operator<>(s1, s2: MergedString) := not(s1=s2);
    
    public static function AllMerges(s1, s2: MergedString): sequence of MergedString;
    public static function operator*(s1, s2: MergedString) := AllMerges(s1, s2).First;
    
    public static function operator in(s1, s2: MergedString): boolean;
    
    public static function Compare(s1, s2: MergedString): integer;
    public function CompareTo(other: MergedString) := Compare(self, other);
    
    private procedure WriteTo(b: ColoredStringBuilderBase<string>; escape_sym: char);
    public function ToColoredString(escape_sym: char := '\'): ColoredString<string>;
    begin
      var b := new ColoredStringBuilder<string>('root');
      WriteTo(b, escape_sym);
      Result := b.Finish;
    end;
    public function ToString(escape_sym: char): string;
    begin
      var b := new UnColoredStringBuilder<string>;
      WriteTo(b, escape_sym);
      Result := b.Finish;
    end;
    public function ToString: string; override := ToString('\');
    
    public function Print: MergedString;
    begin
      self.ToString.Print;
      Result := self;
    end;
    public function Println: MergedString;
    begin
      self.ToString.Println;
      Result := self;
    end;
    
  end;
  
  {$endregion MergedString}
  
  {$region MergedStringLength}
  
  MergedStringLengthMinT = cardinal;
  MergedStringLengthMaxT = StringIndex;
  
  MergedStringLength = record
    public min: MergedStringLengthMinT;
    public max: MergedStringLengthMaxT;
    
    public property IsSimple: boolean read min=max;
    
    public constructor(min: MergedStringLengthMinT; max: MergedStringLengthMaxT);
    begin
      self.min := min;
      self.max := max;
    end;
    public constructor(c: integer) := Create(c, c);
    public constructor := exit;
    
    public static function operator implicit(c: integer): MergedStringLength := new MergedStringLength(c);
    
    public function Contains(c: integer): boolean;
    begin
      Result := false;
      if c<min then exit;
      if max.IsValid and (c>integer(max)) then exit;
      Result := true;
    end;
    public static function operator in(c: integer; l: MergedStringLength) := c in l;
    
    public static function operator+(c1, c2: MergedStringLength): MergedStringLength;
    begin
      Result.min := c1.min+c2.min;
      Result.max := if c1.max.IsInvalid or c2.max.IsInvalid then
        MergedStringLengthMaxT.Invalid else c1.max + c2.max;
    end;
    
    public static function operator*(c1, c2: MergedStringLength): MergedStringLength;
    begin
      Result.min := PABCSystem.Min(c1.min,c2.min);
      Result.max := MergedStringLengthMaxT.MaxOrInvalid(c1.max, c2.max);
    end;
    
    public function ToString: string; override :=
    $'{min}..{max}';
    
  end;
  
  {$endregion MergedStringLength}
  
  {$region MergedStringCost}
  
  MergedStringCost = record(IJumpCost<MergedStringCost>)
    private strafe := 0;
    
    private merge_infs := 0;
    private merge_chrs := 0;
    
    public constructor(strafe, merge_infs,merge_chrs: integer);
    begin
      self.strafe := strafe;
      self.merge_infs := merge_infs;
      self.merge_chrs := merge_chrs;
    end;
    public constructor := exit;
    
    public static function Strafed := new MergedStringCost(1, 0,0);
    public static function Merged(len1,len2: MergedStringLength): MergedStringCost;
    begin
      var char_c := MergedStringLengthMaxT.MaxOrInvalid(len1.max, len2.max);
      Result := new MergedStringCost(0,
        Ord(char_c.IsInvalid),
        if char_c.IsValid then integer(char_c) else 0
      );
    end;
    
    public function Plus(other: MergedStringCost) := new MergedStringCost(
      self.strafe     + other.strafe,
      self.merge_infs + other.merge_infs,
      self.merge_chrs + other.merge_chrs
    );
    
    public function Equals(other: MergedStringCost) := (self.strafe=other.strafe) and (self.merge_infs=other.merge_infs) and (self.merge_chrs=other.merge_chrs);
    public function CompareTo(other: MergedStringCost): integer;
    begin
      
      Result := self.strafe.CompareTo(other.strafe);
      if Result<>0 then exit;
      
      Result := self.merge_infs.CompareTo(other.merge_infs);
      if Result<>0 then exit;
      
      Result := self.merge_chrs.CompareTo(other.merge_chrs);
      if Result<>0 then exit;
      
    end;
    
    public function ToString: string; override :=
    $'{TypeName(self)}[{strafe}, {merge_infs}, {merge_chrs}]';
    
  end;
  
  {$endregion MergedStringCost}
  
  {$region MergedStringPointer}
  
  MergedStringPointerData = record(IComparable<MergedStringPointerData>)
    public part_i := 0;
    public solid_sym_used := 0;
    
    public function SolidMoveAndBreak(solid_len: integer): boolean;
    begin
      solid_sym_used += 1;
      Result := solid_sym_used=solid_len;
      if not Result then exit;
      part_i += 1;
      solid_sym_used := 0;
    end;
    
    public static function operator=(p1,p2: MergedStringPointerData) := (p1.part_i=p2.part_i) and (p1.solid_sym_used=p2.solid_sym_used);
    public static function operator<>(p1,p2: MergedStringPointerData) := not(p1=p2);
    
    public static function Compare(p1, p2: MergedStringPointerData): integer;
    begin
      
      Result := p1.part_i.CompareTo(p2.part_i);
      if Result<>0 then exit;
      
      Result := p1.solid_sym_used.CompareTo(p2.solid_sym_used);
      if Result<>0 then exit;
      
    end;
    public function CompareTo(p: MergedStringPointerData) := Compare(self, p);
    
  end;
  MergedStringPointer = record(IPatternEdgePointer<MergedStringPointer>)
    private s: MergedString := nil;
    private data := new MergedStringPointerData;
    
    public constructor(s: MergedString) := self.s := s;
    public constructor := exit;
    
    public static function operator implicit(s: MergedString): MergedStringPointer := new MergedStringPointer(s);
    
    public function IsOut: boolean;
    
    private function SolidMoveAndBreak(solid_len: integer) := data.SolidMoveAndBreak(solid_len);
    
    {$ifdef DEBUG}
    private static procedure EnsureRelated(p1, p2: MergedStringPointer);
    begin
      if p1.s <> p2.s then raise new System.InvalidOperationException;
    end;
    {$endif DEBUG}
    
    public static function operator=(p1, p2: MergedStringPointer): boolean;
    begin
      {$ifdef DEBUG}
      EnsureRelated(p1, p2);
      {$endif DEBUG}
      Result := p1.data = p2.data;
    end;
    public static function operator<>(p1, p2: MergedStringPointer) := not(p1=p2);
    
    public static function Compare(p1, p2: MergedStringPointer): integer;
    begin
      {$ifdef DEBUG}
      EnsureRelated(p1, p2);
      {$endif DEBUG}
      Result := MergedStringPointerData.Compare(p1.data, p2.data);
    end;
    public function CompareTo(p: MergedStringPointer) := Compare(self, p);
    
    public function ToString: string; override :=
    $'>>> {s} <<< [{data.part_i}, {data.solid_sym_used}]';
    
  end;
  
  {$endregion MergedStringPointer}
  
implementation

{$region MergedStringPart} type
  
  MergedStringPart = abstract class
    
    public property Length: MergedStringLength read; abstract;
    
    //TODO Remove, use Pattern's instead
    // - Only thing left is use c_min/c_max in "operator in"
    public function TryApply(text: StringSection; c_min, c_max: integer): sequence of StringSection; abstract;
    
    public procedure WriteTo(b: ColoredStringBuilderBase<string>; escape_sym: char); abstract;
    
  end;
  MergedStringPartSolid = sealed class(MergedStringPart)
    private val: string;
    
    public constructor(val: string) := self.val := val;
    private constructor := raise new System.InvalidOperationException;
    
    public property Length: MergedStringLength read new MergedStringLength(val.Length); override;
    
    public function TryApply(text: StringSection; c_min, c_max: integer): sequence of StringSection; override :=
    if val.Length.InRange(c_min, c_max) and text.StartsWith(val) then
      |text.TakeFirst(val.Length)| else
      System.Array.Empty&<StringSection>;
    
    public static function Compare(p1, p2: MergedStringPartSolid) := string.Compare(p1.val, p2.val);
    
    public procedure WriteTo(b: ColoredStringBuilderBase<string>; escape_sym: char); override :=
    b.AddSubRange('solid', b->
      foreach var ch in self.val do
      begin
        if (ch=escape_sym) or (ch='@') then
          b += escape_sym;
        b += ch;
      end
    );
    
  end;
  MergedStringPartWild = sealed class(MergedStringPart)
    private count: MergedStringLength;
    private allowed: HashSet<char>;
    private static allowed_anything := (char.MinValue..char.MaxValue).ToHashSet;
    
    {$region constructor's}
    
    public constructor(count: MergedStringLength; allowed: HashSet<char>);
    begin
      self.count := count;
      self.allowed := if allowed.Count=allowed_anything.Count then
        allowed_anything else allowed;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    private static function TryParseCountFrom(s: StringSection; var c: StringIndex): boolean;
    begin
      Result := false;
      if s.Length=0 then
        c := StringIndex.Invalid else
      if s.All(char.IsDigit) then
        c := s.ToString.ToInteger else
        exit;
      Result := true;
    end;
    private static function TryParseCountFrom(s: StringSection; var c: MergedStringLengthMinT): boolean;
    begin
      var nc: StringIndex;
      Result := TryParseCountFrom(s, nc);
      if not Result then exit;
      c := if nc.IsInvalid then 0 else nc;
    end;
    
    public static function TryParse(read_head: StringSection; escape_sym: char): System.ValueTuple<StringSection,MergedStringPartWild>;
    begin
      
      while true do
      begin
        var wild_beg_s := read_head.SubSectionOfFirstUnescaped(escape_sym, wild_beg);
        if wild_beg_s.IsInvalid then break;
        read_head := read_head.WithI1(wild_beg_s.I2);
        
        var wild_end_s := read_head.SubSectionOfFirstUnescaped(escape_sym, wild_end);
        if wild_end_s.IsInvalid then continue;
        var body := read_head.WithI2(wild_end_s.I1);
        
        var count_chs_sep_s := body.SubSectionOfFirstUnescaped(escape_sym, count_chs_sep);
        if count_chs_sep_s.IsInvalid then continue;
        var count_s := body.WithI2(count_chs_sep_s.I1);
        
        var count := new MergedStringLength(0, MergedStringLengthMaxT.Invalid);
        if count_s.Length<>0 then
        begin
          var count_sep_s := count_s.SubSectionOfFirst(range_sep);
          
          if count_sep_s.IsInvalid then
          begin
            if not TryParseCountFrom(count_s, count.max) then continue;
            count.min := if count.max.IsInvalid then 0 else count.max;
          end else
          begin
            if not TryParseCountFrom(count_s.WithI2(count_sep_s.I1), count.min) then continue;
            if not TryParseCountFrom(count_s.WithI1(count_sep_s.I2), count.max) then continue;
            if count.max.IsValid and (count.min>count.max) then continue;
          end;
          
        end;
        
        var allowed := new HashSet<char>;
        var chars := body.WithI1(count_chs_sep_s.I2);
        
        var escaped := false;
        while chars.Length<>0 do
        begin
          var ch1 := chars[0];
          chars := chars.TrimFirst(1);
          escaped := not escaped and (ch1=escape_sym);
          if escaped then continue;
          if (chars.Length>=range_sep.Length+1) and chars.StartsWith(range_sep) then
          begin
            var ch2 := chars[range_sep.Length];
            chars := chars.TrimFirst(range_sep.Length+1);
            for var ch := ch1 to ch2 do
              allowed += ch;
          end else
            allowed += ch1;
        end;
        if allowed.Count=0 then
          allowed := allowed_anything;
        
        Result.Item1 := wild_beg_s.WithI2(wild_end_s.I2);
        Result.Item2 := new MergedStringPartWild(count, allowed);
        
        exit;
      end;
      
    end;
    
    {$endregion constructor's}
    
    public property Length: MergedStringLength read count; override;
    
    private const wild_beg = '@[';
    private const wild_end = ']';
    private const count_chs_sep = '*';
    private const range_sep = '..';
    
    public function TryApply(text: StringSection; c_min, c_max: integer): sequence of StringSection; override;
    begin
      
      if text.Length>c_max then
        text := text.TakeFirst(c_max);
      if not self.count.max.IsInvalid and (text.Length>count.max) then
        text := text.TakeFirst(count.max);
      text := text.TakeFirstWhile(allowed.Contains);
      
      if c_min<self.count.min then
        c_min := count.min;
      
      var res := text.TakeFirst(c_min);
      while true do
      begin
        yield res;
        if res.I2=text.I2 then break;
        res.range.i2 += 1;
      end;
      
    end;
    
    public static function Compare(p1, p2: MergedStringPartWild): integer;
    begin
      
      Result += Ord(p1.allowed.IsSupersetOf(p2.allowed));
      Result -= Ord(p2.allowed.IsSupersetOf(p1.allowed));
      if Result<>0 then exit;
      
      Result := StringIndex.Compare(
        p1.count.max,
        p2.count.max
      );
      if Result<>0 then exit;
      
      Result := Sign(
        p1.count.min -
        p2.count.min
      );
      if Result<>0 then exit;
      
    end;
    
    private static function AreCharsCombineable(ch1, ch2: char): boolean;
    begin
      Result := false;
      if ch2.Code-ch1.Code <> 1 then exit;
      if ch1.IsDigit then
        Result := ch2.IsDigit else
      if ch1.IsLetter then
      begin
        if not ch2.IsLetter then exit;
        Result := ch1.IsUpper=ch2.IsUpper;
      end;
    end;
    
    public procedure WriteTo(b: ColoredStringBuilderBase<string>; escape_sym: char); override :=
    b.AddSubRange('wild', b->
    begin
      //TODO #????
      b += MergedStringPartWild.wild_beg;
      
      b.AddSubRange('count', b->
      begin
        var c_min_s := if count.min=0 then '' else count.min.ToString;
        var c_max_s := if count.max.IsInvalid then '' else count.max.ToString;
        
        b += c_min_s;
        if c_max_s<>c_min_s then
        begin
          //TODO #????
          b += MergedStringPartWild.range_sep;
          b += c_max_s;
        end;
        
      end);
      
      //TODO #????
      b += MergedStringPartWild.count_chs_sep;
      
      if not ReferenceEquals(allowed, allowed_anything) then
        b.AddSubRange('chars', b->
        begin
          var enmr := allowed.Order.GetEnumerator;
          if not enmr.MoveNext then raise new System.InvalidOperationException;
          
          var ch1 := enmr.Current;
          var ch2 := ch1;
          
          var FlushPrev := procedure->b.AddSubRange('sym', b->
          begin
            var AddEscaped := procedure(ch: char)->
            begin
              if (ch=escape_sym) or (ch=']') then
                b += escape_sym;
              b += ch;
            end;
            
            AddEscaped(ch1);
            if ch1<>ch2 then
            begin
              if ch2.Code-ch1.Code <> 1 then
                //TODO #????: Need "MergedStringPart."
                b += MergedStringPartWild.range_sep;
              AddEscaped(ch2);
            end;
            
          end);
          
          while enmr.MoveNext do
          begin
            var ch := enmr.Current;
            if AreCharsCombineable(ch2, ch) then
              ch2 := ch else
            begin
              FlushPrev;
              ch1 := ch;
              ch2 := ch;
            end;
          end;
          
          FlushPrev;
        end);
      
      //TODO #????
      b += MergedStringPartWild.wild_end;
    end);
    
  end;
  
{$endregion MergedStringPart}

{$region MergedString.Create}

type
  MergedString = sealed partial class
    private parts: array of MergedStringPart;
    private len_caps: array of MergedStringLength;
    
    private constructor(parts: array of MergedStringPart);
    begin
      self.parts := parts;
      SetLength(len_caps, parts.Count);
      
      var cap := new MergedStringLength(0);
      for var i := parts.Count-1 to 0 step -1 do
      begin
        len_caps[i] := cap;
        cap := cap + parts[i].Length;
      end;
      
    end;
    
    private static function MakeParts(pattern: StringSection; escape_sym: char): sequence of MergedStringPart;
    begin
      //TODO Replace used_head with leftover
      
      var used_head := pattern.TakeFirst(0);
      //TODO #2715
      var make_solid_until: function(ind: StringIndex): MergedStringPart := function(ind: StringIndex): MergedStringPart->
      begin
        var leftover := used_head.TakeLast(0).WithI2(ind);
        if leftover.Length=0 then exit;
        Result := new MergedStringPartSolid(leftover.Unescape(escape_sym));
        used_head.range.i2 := ind;
      end;
      
      while true do
      begin
        var (wild_s, wild) := MergedStringPartWild.TryParse(pattern.WithI1(used_head.I2), escape_sym);
        if wild=nil then break;
        
        if make_solid_until(wild_s.I1) is MergedStringPart(var solid) then yield solid;
        
        if wild.count.max<>0 then
        begin
          if wild.count.IsSimple and (wild.allowed.Count=1) then
            yield new MergedStringPartSolid(wild.allowed.Single * wild.count.min) else
            yield wild;
        end;
        
        used_head := used_head.WithI2(wild_s.I2);
      end;
      
      if make_solid_until(pattern.I2) is MergedStringPart(var p) then yield p;
    end;
    
    /// Returns whether to delete each
    private static function TryMergeParts(part1, part2: MergedStringPart): ValueTuple<boolean, boolean>;
    begin
      match part1 with
        
        MergedStringPartSolid(var sp1):
          match part2 with
            
            MergedStringPartSolid(var sp2):
            begin
              sp1.val += sp2.val;
              Result := ValueTuple.Create(false, true);
            end;
            
            MergedStringPartWild(var wp2):
            begin
              //TODO Code dup
              if wp2.allowed.Count<>1 then exit;
              
              var prev_len := sp1.val.Length;
              sp1.val := sp1.val.TrimEnd(wp2.allowed.Single);
              var absorb_c := prev_len-sp1.val.Length;
              if absorb_c=0 then exit;
              
              wp2.count := wp2.count + absorb_c;
              Result := ValueTuple.Create(sp1.val.Length=0, false);
            end;
            
            {$ifdef DEBUG}
            else raise new System.NotImplementedException;
            {$endif DEBUG}
          end;
        
        MergedStringPartWild(var wp1):
          match part2 with
            
            MergedStringPartSolid(var sp2):
            begin
              if wp1.allowed.Count<>1 then exit;
              
              var prev_len := sp2.val.Length;
              sp2.val := sp2.val.TrimStart(wp1.allowed.Single);
              var absorb_c := prev_len-sp2.val.Length;
              if absorb_c=0 then exit;
              
              wp1.count := wp1.count + absorb_c;
              Result := ValueTuple.Create(false, sp2.val.Length=0);
            end;
            
            MergedStringPartWild(var wp2):
            begin
              Result := ValueTuple.Create(false, wp1.allowed.SetEquals(wp2.allowed));
              if not Result.Item2 then exit;
              wp1.count := wp1.count + wp2.count;
            end;
            
            {$ifdef DEBUG}
            else raise new System.NotImplementedException;
            {$endif DEBUG}
          end;
        
        {$ifdef DEBUG}
        else raise new System.NotImplementedException;
        {$endif DEBUG}
      end;
    end;
    
    private static function OptimizeParts(parts_seq: sequence of MergedStringPart): List<MergedStringPart>;
    begin
      Result := new List<MergedStringPart>;
      
      foreach var curr in parts_seq do
        while true do
        begin
          if Result.Count=0 then
          begin
            Result += curr;
            break;
          end;
          var last := Result[Result.Count-1];
          var (rm_last, rm_curr) := TryMergeParts(last, curr);
          if rm_curr then
            break else
          if rm_last then
            Result.RemoveLast else
          begin
            Result += curr;
            break;
          end;
        end;
      
    end;
    
  end;
  
function MergedStringPointer.IsOut := data.part_i = s.parts.Length;

static function MergedString.Literal(s: string) :=
//TODO #????: adding params breaks case where array is passed to "new MergedString"
new MergedString(new MergedStringPart[](new MergedStringPartSolid(s)));

static function MergedString.Parse(s: StringSection; escape_sym: char) :=
new MergedString(OptimizeParts(MakeParts(s, escape_sym)).ToArray);

procedure MergedString.WriteTo(b: ColoredStringBuilderBase<string>; escape_sym: char) :=
foreach var part in parts do part.WriteTo(b, escape_sym);

static function MergedString.Compare(s1, s2: MergedString): integer;
begin
  var i := 0;
  while true do
  begin
    var have_p1 := i<s1.parts.Length;
    var have_p2 := i<s2.parts.Length;
    Result := Ord(have_p1) - Ord(have_p2);
    if Result<>0 then exit;
    if not have_p1 then break;
    
    var p1_wild := s1.parts[i] is MergedStringPartWild;
    var p2_wild := s2.parts[i] is MergedStringPartWild;
    Result := Ord(p1_wild) - Ord(p2_wild);
    if Result<>0 then exit;
    
    Result := if not p1_wild then
      MergedStringPartSolid.Compare(MergedStringPartSolid(s1.parts[i]), MergedStringPartSolid(s2.parts[i])) else
      MergedStringPartWild .Compare(MergedStringPartWild (s1.parts[i]), MergedStringPartWild (s2.parts[i]));
    if Result<>0 then exit;
    
    i += 1;
  end;
end;

{$endregion MergedString.Create}

{$region MergedString.operator's}

{$region operator=}

static function MergedString.operator=(s1, s2: MergedString): boolean;
begin
  Result := object.ReferenceEquals(s1, s2);
  if Result then exit;
  if object.ReferenceEquals(s1, nil) then exit;
  if object.ReferenceEquals(s2, nil) then exit;
  if s1.parts.Length<>s2.parts.Length then exit;
  for var i := 0 to s1.parts.Length-1 do
  begin
    match s1.parts[i] with
      MergedStringPartSolid(var sp1):
        Result := (s2.parts[i] is MergedStringPartSolid(var sp2)) and (sp1.val=sp2.val);
      MergedStringPartWild(var wp1):
        Result := (s2.parts[i] is MergedStringPartWild(var wp2)) and (wp1.count=wp2.count) and (wp1.allowed=wp2.allowed);
      {$ifdef DEBUG}
      else raise new System.NotImplementedException;
      {$endif DEBUG}
    end;
    if not Result then exit;
  end;
end;

{$endregion operator=}

{$region MergedStringJumpNode}

type
  MergedStringJumpNode = abstract class(PatternJumpNode<MergedStringJumpNode>)
    
    public function ToParts(edge1: MergedString): sequence of MergedStringPart; abstract;
    
    public static function ToMergedString(edge1: MergedString; n: MergedStringJumpNode) :=
    new MergedString(MergedString.OptimizeParts(
      PatternPath&<MergedStringJumpNode>(n)
      .ToArray(n->n.ToParts(edge1)).SelectMany(ps->ps)
    ).ToArray);
    
  end;
  
  MergedStringJumpNodeCopy = sealed class(MergedStringJumpNode)
    public e1p1, e1p2: MergedStringPointerData;
    
    public constructor(prev: MergedStringJumpNode; e1p1, e1p2: MergedStringPointerData);
    begin
      inherited Create(prev);
      self.e1p1 := e1p1;
      self.e1p2 := e1p2;
    end;
    
    public function ToParts(edge1: MergedString): sequence of MergedStringPart; override;
    begin
      
      if e1p1.part_i <> e1p2.part_i then
      begin
        var p := edge1.parts[e1p1.part_i];
        yield if e1p1.solid_sym_used=0 then
          p else
          new MergedStringPartSolid(
            StringSection.Create(MergedStringPartSolid(p).val)
            .TrimFirst(e1p1.solid_sym_used)
            .ToString
          );
      end;
      
      for var part_i := e1p1.part_i+1 to e1p2.part_i-1 do
        yield edge1.parts[part_i];
      
      if e1p2.solid_sym_used<>0 then
      begin
        var p := edge1.parts[e1p2.part_i];
        yield if p is MergedStringPartSolid then
          new MergedStringPartSolid(
            StringSection.Create(MergedStringPartSolid(p).val)
            .TakeFirst(e1p2.solid_sym_used)
            .TrimFirst(if e1p1.part_i=e1p2.part_i then e1p1.solid_sym_used else 0)
            .ToString
          ) else p;
      end;
      
    end;
    
  end;
  MergedStringJumpNodeWild = sealed class(MergedStringJumpNode)
    // Can have many nested .Append
    // As such it is also a form of linked list
    public chars: sequence of char;
    // Along each of edges
    public len1, len2: MergedStringLength;
    
    public constructor(prev: MergedStringJumpNode; chars: sequence of char; len1,len2: MergedStringLength);
    begin
      inherited Create(prev);
      self.chars := chars;
      self.len1 := len1;
      self.len2 := len2;
    end;
    
    public function ToParts(edge1: MergedString): sequence of MergedStringPart; override :=
    new MergedStringPart[](new MergedStringPartWild(
      len1 * len2,
      chars.ToHashSet
    ));
    
  end;
  
  MergedStringPoint2 = BasicPatternPoint2<MergedStringPointer, MergedStringPointer>;
  
  MergedStringMergeCostJumpRes = ValueTuple<
    MergedStringPoint2,
    MergedStringJumpNode,
    MergedStringCost
  >;
  MergedStringInJumpRes = ValueTuple<
    MergedStringPoint2,
    boolean
  >;
  
{$endregion MergedStringJumpNode}

{$region Misc}

function EdgePart(p: MergedStringPointer) := p.s.parts[p.data.part_i];
function TakeChar(p: MergedStringPointer; var chars: sequence of char; var len: MergedStringLength): MergedStringPointer;
begin
  match EdgePart(p) with
    
    MergedStringPartSolid(var part):
    begin
      chars := chars.Append(part.val[p.data.solid_sym_used]);
      len := len + 1;
      p.SolidMoveAndBreak(part.val.Length);
    end;
    
    MergedStringPartWild(var part):
    begin
      chars := chars + part.allowed;
      len := len + part.count;
      p.data.part_i += 1;
    end;
    
    {$ifdef DEBUG}
    else raise new System.NotImplementedException;
    {$endif DEBUG}
  end;
  Result := p;
end;

function NextZeroJumpPoint(p: MergedStringPoint2): MergedStringPoint2;
begin
  var ep1 := p.Edge1;
  var ep2 := p.Edge2;
  var s := ep1.s;
  
  while true do
  begin
    if ep1.IsOut or ep2.IsOut then break;
    
    match EdgePart(ep1) with
      
      MergedStringPartSolid(var part1):
      begin
        var part2 := EdgePart(ep2) as MergedStringPartSolid;
        if part2=nil then break;
        var part_esc_c := 0;
        
        while part1.val[ep1.data.solid_sym_used]=part2.val[ep2.data.solid_sym_used] do
        begin
          part_esc_c :=
            +Ord(ep1.SolidMoveAndBreak(part1.val.Length))
            +Ord(ep2.SolidMoveAndBreak(part2.val.Length))
          ;
          if part_esc_c<>0 then break;
        end;
        
        if part_esc_c<>2 then break;
      end;
      
      MergedStringPartWild(var part1):
      begin
        var part2 := EdgePart(ep2) as MergedStringPartWild;
        if part2=nil then break;
        
        {$ifdef DEBUG}
        if ep1.data.solid_sym_used<>0 then raise new System.InvalidOperationException;
        if ep2.data.solid_sym_used<>0 then raise new System.InvalidOperationException;
        {$endif DEBUG}
        
        // Only accept non-equal as a merge-jump
        if not part1.allowed.SetEquals(part2.allowed) then break;
        if part1.count<>part2.count then break;
        // Also don't mess with inf matches:
        // "in" and "*" for "@[*]a" and "@[*]"
        if part1.count.max.IsInvalid then break;
        
        ep1.data.part_i += 1;
        ep2.data.part_i += 1;
      end;
      
      {$ifdef DEBUG}
      else raise new System.NotImplementedException;
      {$endif DEBUG}
    end;
    
  end;
  
  Result := new MergedStringPoint2(ep1, ep2);
end;

{$endregion Misc}

{$region operator*}

type
  MergedStringMltCostJumpData = record
    chars: sequence of char;
    len1 := MergedStringLength(0);
    len2 := MergedStringLength(0);
    prev_j: MergedStringJumpNode;
    ep1, ep2: MergedStringPointer;
    s: MergedString;
    
    constructor(p: MergedStringPoint2; j: MergedStringJumpNode);
    begin
      
      if j is MergedStringJumpNodeWild(var w) then
      begin
        self.chars := w.chars;
        self.len1 := w.len1;
        self.len2 := w.len2;
        j := w.Prev;
      end else
        self.chars := System.Linq.Enumerable.Empty&<char>;
      self.prev_j := j;
      
      self.ep1 := p.Edge1;
      self.ep2 := p.Edge2;
      self.s := ep1.s;
      
    end;
    
    function MergeJump: MergedStringMergeCostJumpRes;
    begin
      Result := default(MergedStringMergeCostJumpRes);
      var ep1 := self.ep1; if ep1.IsOut then exit;
      var ep2 := self.ep2; if ep2.IsOut then exit;
      match EdgePart(ep1) with
        
        MergedStringPartSolid(var part1):
          match EdgePart(ep2) with
            // Zero-jump if equal
            // Strafe-jump if different
            MergedStringPartSolid(var part2): ;
            
            MergedStringPartWild(var part2):
            begin
              //TODO Code dup
              // - Combine with case where types are flipped
              var c := 0;
              while part1.val[ep1.data.solid_sym_used] in part2.allowed do
              begin
                c += 1;
                if ep1.SolidMoveAndBreak(part1.val.Length) then
                  break;
              end;
              if c=0 then exit;
              ep2.data.part_i += 1;
              
              Result := new MergedStringMergeCostJumpRes(
                new MergedStringPoint2(ep1, ep2),
                new MergedStringJumpNodeWild(
                  prev_j, chars+part2.allowed,
                  len1 + c,
                  len2 + part2.count
                ),
                MergedStringCost.Merged(c, part2.count)
              );
            end;
            
            {$ifdef DEBUG}
            else raise new System.NotImplementedException;
            {$endif DEBUG}
          end;
        
        MergedStringPartWild(var part1):
          match EdgePart(ep2) with
            
            MergedStringPartSolid(var part2):
            begin
              
              var c := 0;
              while part2.val[ep2.data.solid_sym_used] in part1.allowed do
              begin
                c += 1;
                if ep2.SolidMoveAndBreak(part2.val.Length) then
                  break;
              end;
              if c=0 then exit;
              ep1.data.part_i += 1;
              
              Result := new MergedStringMergeCostJumpRes(
                new MergedStringPoint2(ep1, ep2),
                new MergedStringJumpNodeWild(
                  prev_j, chars+part1.allowed,
                  len1 + part1.count,
                  len2 + c
                ),
                MergedStringCost.Merged(part1.count, c)
              );
            end;
            
            MergedStringPartWild(var part2):
            begin
              {$ifdef DEBUG}
              // Should have been checked by zero-jump
              if part1.allowed.SetEquals(part2.allowed) and (part1.count=part2.count) then
                raise new System.NotImplementedException;
              {$endif DEBUG}
              
              var n_chars: sequence of char;
              if part1.allowed.IsSupersetOf(part2.allowed) then n_chars := chars+part1.allowed else
              if part2.allowed.IsSupersetOf(part1.allowed) then n_chars := chars+part2.allowed else
                exit;
              
              ep1.data.part_i += 1;
              ep2.data.part_i += 1;
              Result := new MergedStringMergeCostJumpRes(
                new MergedStringPoint2(ep1, ep2),
                new MergedStringJumpNodeWild(
                  prev_j, n_chars,
                  len1 + part1.count,
                  len2 + part2.count
                ),
                MergedStringCost.Merged(part1.count, part2.count)
              );
            end;
            
            {$ifdef DEBUG}
            else raise new System.NotImplementedException;
            {$endif DEBUG}
          end;
        
        {$ifdef DEBUG}
        else raise new System.NotImplementedException;
        {$endif DEBUG}
      end;
    end;
    
    function StrafeJumps: sequence of MergedStringMergeCostJumpRes;
    begin
      
      if not ep1.IsOut then
      begin
        var n_chars := chars;
        var n_len1 := len1;
        yield new MergedStringMergeCostJumpRes(
          new MergedStringPoint2(TakeChar(ep1, n_chars, n_len1), ep2),
          new MergedStringJumpNodeWild(prev_j, n_chars, n_len1,len2),
          MergedStringCost.Strafed
        );
      end;
      
      if not ep2.IsOut then
      begin
        var n_chars := chars;
        var n_len2 := len2;
        yield new MergedStringMergeCostJumpRes(
          new MergedStringPoint2(ep1, TakeChar(ep2, n_chars, n_len2)),
          new MergedStringJumpNodeWild(prev_j, n_chars, len1,n_len2),
          MergedStringCost.Strafed
        );
      end;
      
    end;
    
    function AllCostJumps: sequence of MergedStringMergeCostJumpRes;
    begin
    
      begin
        var r := MergeJump;
        if r.Item2<>nil then
          yield r;
      end;
      
      yield sequence StrafeJumps;
      
    end;
    
  end;
  
static function MergedString.AllMerges(s1, s2: MergedString) :=
Pattern.MinPaths(
  new MergedStringPoint2(s1, s2),
  default(MergedStringJumpNode),
  new MergedStringCost,
  
  (p, j)->
  begin
    var p2 := NextZeroJumpPoint(p);
    
    Result := |ValueTuple.Create(p2,
      if p.Edge1=p2.Edge1 then j else
        new MergedStringJumpNodeCopy(j, p.Edge1.data, p2.Edge1.data)
    )|;
    
  end,
  
  (p, j)->
  MergedStringMltCostJumpData.Create(p, j).AllCostJumps
  
).Select(n->
begin
  Result := MergedStringJumpNode.ToMergedString(s1, n);
  {$ifdef DEBUG}
  
  if s1 not in Result then raise new System.InvalidOperationException($'s1{#10}{s1}{#10}{s2}{#10}{Result}{#10}');
  if s2 not in Result then raise new System.InvalidOperationException($'s2{#10}{s1}{#10}{s2}{#10}{Result}{#10}');
  
  foreach var esc_ch in '@\' do
  begin
    var r2 := MergedString.Parse(Result.ToString(esc_ch), esc_ch);
    if Result <> r2 then
      raise new System.InvalidOperationException($'{#10}{Result}{#10}{r2}{#10}');
  end;
  
  {$endif DEBUG}
end);

{$endregion operator*}

{$region operator in}

function MergedStringInMakeJumps(p: MergedStringPoint2): sequence of MergedStringInJumpRes;
begin
  { $define MergedStringInMakeCostJumps_Flat}
  {$ifdef MergedStringInMakeCostJumps_Flat}
  var res := new List<MergedStringInJumpRes>;
  Result := res;
  {$endif MergedStringInMakeCostJumps_Flat}
  
  p := NextZeroJumpPoint(p);
  var ep1 := p.Edge1;
  var ep2 := p.Edge2;
  //TODO Compare MergedStringLength instead
  if ep2.IsOut then
  begin
    if ep1.IsOut then
    begin
      var r := new MergedStringInJumpRes(
        p, true
      );
      {$ifdef MergedStringInMakeCostJumps_Flat}
      res += r;
      {$else MergedStringInMakeCostJumps_Flat}
      yield r;
      {$endif MergedStringInMakeCostJumps_Flat}
    end;
    exit;
  end;
  var s := ep1.s;
  
  var part2 := EdgePart(ep2);
  if part2 is MergedStringPartSolid then
  begin
    {$ifdef DEBUG}
    var sp2 := MergedStringPartSolid(part2);
    if not ep1.IsOut then match EdgePart(ep1) with
      
      MergedStringPartSolid(var sp1):
        // Should have been zero-jump
        if sp1.val[ep1.data.solid_sym_used]=sp2.val[ep2.data.solid_sym_used] then
          raise new System.InvalidOperationException;
      
      MergedStringPartWild(var wp1):
        // Should've been optimized out
        if (wp1.allowed.Count=1) and wp1.count.IsSimple then
          raise new System.InvalidOperationException;
        // Otherwise, it's not possible for solid to cover all cases of wild
      
      else raise new System.NotImplementedException;
    end;
    {$endif DEBUG}
    exit;
  end;
  
//  Writeln(ep1);
//  Writeln(ep2);
  
  var wp2 := MergedStringPartWild(part2);
  ep2.data.part_i += 1;
  
  var left_len := wp2.count;
  var no_res := true;
  while not ep1.IsOut do
  begin
    {$ifdef DEBUG}
    if left_len.max=0 then raise new System.NotImplementedException;
    {$endif DEBUG}
    
    match EdgePart(ep1) with
      
      MergedStringPartSolid(var sp1):
      {$region Solid/Wild}
      begin
        var ep1r := ep1;
        
        var c := 0;
        while sp1.val[ep1.data.solid_sym_used] in wp2.allowed do
        begin
          c += 1;
          if ep1.SolidMoveAndBreak(sp1.val.Length) then
            break;
          if left_len.max.IsValid and (c=integer(left_len.max)) then
            break;
        end;
        
        // if c >= left_len.min
        ep1r.data.solid_sym_used += left_len.min;
        for var sym_c := left_len.min to c do
        begin
          var r := new MergedStringInJumpRes(
            new MergedStringPoint2(
              if ep1r.data.solid_sym_used=sp1.val.Length then
                ep1 else ep1r, ep2
            ), true
          );
          ep1r.data.solid_sym_used += 1;
          {$ifdef MergedStringInMakeCostJumps_Flat}
          res += r;
          {$else MergedStringInMakeCostJumps_Flat}
          yield r;
          {$endif MergedStringInMakeCostJumps_Flat}
          no_res := false;
        end;
        if c=0 then break;
        
        left_len.min := if left_len.min < c then
          0 else
          integer(left_len.min) - c;
        left_len.max := if left_len.max.IsInvalid then
          left_len.max else
          integer(left_len.max) - c;
        
      end;
      {$endregion Solid/Wild}
      
      MergedStringPartWild(var wp1):
      {$region Wild/Wild}
      begin
        if wp1.count.max.IsInvalid > left_len.max.IsInvalid then break;
        if left_len.max.IsValid and (wp1.count.max > left_len.max) then break;
        if not wp2.allowed.IsSupersetOf(wp1.allowed) then break;
        
        ep1.data.part_i += 1;
        
        if left_len.min <= wp1.count.min then
        begin
          var r := new MergedStringInJumpRes(
            new MergedStringPoint2(ep1, ep2), true
          );
          {$ifdef MergedStringInMakeCostJumps_Flat}
          res += r;
          {$else MergedStringInMakeCostJumps_Flat}
          yield r;
          {$endif MergedStringInMakeCostJumps_Flat}
          no_res := false;
          left_len.min := 0;
        end else
          left_len.min -= wp1.count.min;
        
//        if wp1.count.max.IsInvalid then
//          break;
        
        if left_len.max.IsValid and wp1.count.max.IsValid then
        begin
          var n_max := integer(left_len.max) - integer(wp1.count.max);
          left_len.max := n_max;
          if left_len.min > n_max then
            left_len.min := n_max;
        end;
        
      end;
      {$endregion Wild/Wild}
      
      {$ifdef DEBUG}
      else raise new System.NotImplementedException;
      {$endif DEBUG}
    end;
    
    if left_len.max=0 then break;
  end;
  
  // Possibly fully skip wp2
  if no_res and (left_len.min=0) then
  begin
    var r := new MergedStringInJumpRes(
      new MergedStringPoint2(ep1, ep2), true
    );
    {$ifdef MergedStringInMakeCostJumps_Flat}
    res += r;
    {$else MergedStringInMakeCostJumps_Flat}
    yield r;
    {$endif MergedStringInMakeCostJumps_Flat}
  end;
  
//  Writeln(res.Count);
//  Writeln('='*30);
end;

static function MergedString.operator in(s1, s2: MergedString) :=
Pattern.AllPaths(
  new MergedStringPoint2(s1, s2), true,
  (p, j) -> MergedStringInMakeJumps(p)
).Any;

{$endregion operator in}

{$endregion MergedString.operator's}

end.