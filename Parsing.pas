unit Parsing;
{$zerobasedstrings}

type
  
  StringIndex = record(IComparable<StringIndex>)
    private val: integer;
    
    private static function MakeInvalid: StringIndex;
    begin
      Result.val := -1; // Note UnsafeInc
    end;
    public static property Invalid: StringIndex read MakeInvalid;
    public property IsInvalid: boolean read val=-1;
    public property IsValid: boolean read not IsInvalid;
    
    public static function operator implicit(ind: integer): StringIndex;
    begin
      if ind<0 then raise new System.IndexOutOfRangeException($'Index was {ind}');
      Result.val := ind;
    end;
    public static function operator implicit(ind: StringIndex): integer;
    begin
      if ind.IsInvalid then raise new System.ArgumentOutOfRangeException('ind');
      Result := ind.val;
    end;
    
    public static function operator=(ind1, ind2: StringIndex) := ind1.val=ind2.val;
    public static function operator=(ind1: StringIndex; ind2: integer) :=
    (ind1.val=ind2) and not ind1.IsInvalid;
    public static function operator=(ind1: integer; ind2: StringIndex) :=
    (ind1=ind2.val) and not ind2.IsInvalid;
    
    public static function operator<(ind1: StringIndex; ind2: integer) := integer(ind1)<ind2;
    public static function operator>(ind1: StringIndex; ind2: integer) := integer(ind1)>ind2;
    
    public static function operator<(ind1: integer; ind2: StringIndex) := ind1<integer(ind2);
    public static function operator>(ind1: integer; ind2: StringIndex) := ind1>integer(ind2);
    
    public static function operator<(ind1, ind2: StringIndex): boolean;
    begin
      if ind1.IsInvalid then raise new System.ArgumentOutOfRangeException('ind1');
      if ind2.IsInvalid then raise new System.ArgumentOutOfRangeException('ind2');
      Result := ind1.val < ind2.val;
    end;
    public static function operator>(ind1, ind2: StringIndex): boolean;
    begin
      if ind1.IsInvalid then raise new System.ArgumentOutOfRangeException('ind1');
      if ind2.IsInvalid then raise new System.ArgumentOutOfRangeException('ind2');
      Result := ind1.val > ind2.val;
    end;
    public static function operator<=(ind1, ind2: StringIndex) := not (ind1>ind2);
    public static function operator>=(ind1, ind2: StringIndex) := not (ind1<ind2);
    
    public static function MinOrInvalid(ind1, ind2: StringIndex) :=
    if ind1.IsInvalid or ind2.IsInvalid then Invalid else
      Min(ind1.val, ind2.val);
    public static function MaxOrInvalid(ind1, ind2: StringIndex) :=
    if ind1.IsInvalid or ind2.IsInvalid then Invalid else
      Max(ind1.val, ind2.val);
    
    public static function MinValid(ind1, ind2: StringIndex) :=
    if ind2.IsInvalid then ind1 else
    if ind1.IsInvalid then ind2 else
      Min(ind1.val, ind2.val);
    public static function MaxValid(ind1, ind2: StringIndex) :=
    if ind2.IsInvalid then ind1 else
    if ind1.IsInvalid then ind2 else
      Max(ind1.val, ind2.val);
    
    public static function Compare(ind1, ind2: StringIndex; invalid_ord: integer := 0): integer;
    begin
      Result := Ord(ind1.IsValid) - Ord(ind2.IsValid);
      if Result<>0 then
      begin
        Result *= invalid_ord;
        if Result=0 then
          raise new System.ArgumentOutOfRangeException(if ind1.IsInvalid then 'ind1' else 'ind2');
        exit;
      end;
      Result := Sign(ind1.val - ind2.val);
    end;
    public function CompareTo(ind: StringIndex) := Compare(self, ind);
    
    public static function operator+(ind: StringIndex; shift: integer): StringIndex;
    begin
      if ind.IsInvalid then raise new System.ArgumentOutOfRangeException;
      Result := ind.val + shift;
    end;
    public static function operator-(ind: StringIndex; shift: integer): StringIndex;
    begin
      if ind.IsInvalid then raise new System.ArgumentOutOfRangeException;
      Result := ind.val - shift;
    end;
    public function UnsafeInc: StringIndex;
    begin
      // No .IsInvalid check: Invalid+1=0
      Result.val := self.val+1;
    end;
    
    public static procedure operator+=(var ind: StringIndex; shift: integer) := ind := ind + shift;
    public static procedure operator-=(var ind: StringIndex; shift: integer) := ind := ind - shift;
    
    public static function operator-(ind1, ind2: StringIndex): integer;
    begin
      if ind1.IsInvalid then raise new System.ArgumentOutOfRangeException('ind1');
      if ind2.IsInvalid then raise new System.ArgumentOutOfRangeException('ind2');
      Result := ind1.val - ind2.val;
    end;
    
    public function ToString: string; override :=
    if self.IsInvalid then 'StringIndex.Invalid' else self.val.ToString;
    public function Print: StringIndex;
    begin
      self.ToString.Print;
      Result := self;
    end;
    public function Println: StringIndex;
    begin
      self.ToString.Println;
      Result := self;
    end;
    
  end;
  
  SIndexRange = record
    public i1, i2: StringIndex; // [i1,i2)
    
    public property Length: integer read i2 - i1;
    
    public constructor(i1, i2: StringIndex);
    begin
      self.i1 := i1;
      self.i2 := i2;
      if i1>i2 then raise new System.InvalidOperationException($'Invalid range {self}');
    end;
    public constructor := raise new System.InvalidOperationException;
    
    private static function MakeInvalid: SIndexRange;
    begin
      Result.i1 := StringIndex.Invalid;
      Result.i2 := StringIndex.Invalid;
    end;
    public static property Invalid: SIndexRange read MakeInvalid;
    
    public static function operator in(ind: StringIndex; range: SIndexRange) := (ind>=range.i1) and (ind<=range.i2);
    
    public function ToString: string; override := $'[{i1}..{i2})';
    public function ToString(whole_text: string) := whole_text.SubString(i1, self.Length);
    
  end;
  
  StringSection = record
    public text := default(string);
    public range := SIndexRange.Invalid;
    
    public property I1: StringIndex read range.i1;
    public property I2: StringIndex read range.i2;
    public property Length: integer read range.Length;
    
    public static property Invalid: StringSection read new StringSection;
    public property IsInvalid: boolean read text=nil;
    
    public constructor(text: string; range: SIndexRange);
    begin
      self.text := text;
      self.range := range;
    end;
    public constructor(text: string; i1, i2: StringIndex) := Create(text, new SIndexRange(i1, i2));
    public constructor(text: string) := Create(text, 0, text.Length);
    public constructor := exit;
    
    public procedure ValidateInd(ind: StringIndex) :=
    if (ind >= StringIndex(Length)) then raise new System.IndexOutOfRangeException($'Index {ind} was >= {Length}');
    public procedure ValidateLen(len: StringIndex) :=
    if (len >  StringIndex(Length)) then raise new System.IndexOutOfRangeException($'Length {len} was > {Length}');
    
    public static function operator in(ind: StringIndex; s: StringSection) := ind in s.range;
    
    private function GetItemAt(ind: StringIndex): char;
    begin
      ValidateInd(ind);
      Result := text[self.i1+ind];
    end;
    public property Item[ind: StringIndex]: char read GetItemAt write
    begin
      ValidateInd(ind);
      text[self.i1+ind] := value;
    end; default;
    
    public function Prev := text[I1-1];
    public function Prev(low_bound_incl: StringIndex): char? := self.I1>low_bound_incl ? Prev : nil;
    public function Prev(bounds: StringSection) := Prev(bounds.I1);
    
    public function Next := text[I2];
    public function Next(upr_bound_n_in: StringIndex): char? := self.I2<upr_bound_n_in ? Next : nil;
    public function Next(bounds: StringSection) := Next(bounds.I2);
    
    public function PrevWhile(low_bound_incl: StringIndex; ch_validator: char->boolean; min_expand: StringIndex): StringSection;
    begin
      Result := self;
      var max_i1 := if min_expand.IsInvalid then Result.I1 else Result.I1-min_expand;
      while true do
      begin
        var ch := Result.Prev(low_bound_incl);
        if ch=nil then break;
        if not ch_validator(ch.Value) then break;
        Result.range.i1 -= 1;
      end;
      if Result.I1>max_i1 then Result := StringSection.Invalid;
    end;
    public function PrevWhile(low_bound_incl: StringIndex; ch_validator: char->boolean) := PrevWhile(low_bound_incl, ch_validator, StringIndex.Invalid);
    
    public function NextWhile(upr_bound_n_in: StringIndex; ch_validator: char->boolean; min_expand: StringIndex): StringSection;
    begin
      Result := self;
      var min_i2 := if min_expand.IsInvalid then Result.I2 else Result.I2+min_expand;
      while true do
      begin
        var ch := Result.Next(upr_bound_n_in);
        if ch=nil then break;
        if not ch_validator(ch.Value) then break;
        Result.range.i2 += 1;
      end;
      if Result.I2<min_i2 then Result := StringSection.Invalid;
    end;
    public function NextWhile(upr_bound_n_in: StringIndex; ch_validator: char->boolean) := NextWhile(upr_bound_n_in, ch_validator, StringIndex.Invalid);
    
    public function WithI1(i1: StringIndex) := new StringSection(text, i1, i2);
    public function WithI2(i2: StringIndex) := new StringSection(text, i1, i2);
    
    public function TrimFirst(i1_shift: StringIndex) := new StringSection(self.text, self.i1+i1_shift, self.i2);
    public function TrimLast (i2_shift: StringIndex) := new StringSection(self.text, self.i1, self.i2-i2_shift);
    
    public function TakeFirst(len: StringIndex): StringSection;
    begin
      ValidateLen(len);
      Result := new StringSection(self.text, self.i1, self.i1+len);
    end;
    public function TakeLast(len: StringIndex): StringSection;
    begin
      ValidateLen(len);
      Result := new StringSection(self.text, self.i2-len, self.i2);
    end;
    
    public function First := self[0];
    public function Last := self.TakeLast(1).First;
    
    public function TrimFirstWhile(ch_validator: char->boolean): StringSection;
    begin
      Result := self;
      while true do
      begin
        if Result.Length=0 then break;
        if not ch_validator(Result[0]) then break;
        Result.range.i1 += 1;
      end;
    end;
    public function TrimLastWhile(ch_validator: char->boolean): StringSection;
    begin
      Result := self;
      while true do
      begin
        if Result.Length=0 then break;
        if not ch_validator(Result.Last) then break;
        Result.range.i2 -= 1;
      end;
    end;
    public function TrimWhile(ch_validator: char->boolean) := self
    .TrimFirstWhile(ch_validator)
    .TrimLastWhile(ch_validator);
    
    public function TakeFirstWhile(ch_validator: char->boolean) :=
    self.TakeFirst(0).NextWhile(self.I2, ch_validator);
    public function TakeLastWhile(ch_validator: char->boolean) :=
    self.TakeLast(0).PrevWhile(self.I1, ch_validator);
    
    public function TrimAfterFirst(ch: char): StringSection;
    begin
      var ind := self.IndexOf(ch);
      Result := if ind.IsInvalid then
        StringSection.Invalid else
        new StringSection(self.text, self.i1, self.i1+ind+1);
    end;
    public function TrimAfterFirst(str: string): StringSection;
    begin
      var ind := self.IndexOf(str);
      Result := if ind.IsInvalid then
        StringSection.Invalid else
        new StringSection(self.text, self.i1, self.i1+ind+str.Length);
    end;
    
    public function SubSection(ind1, ind2: StringIndex): StringSection;
    begin
      ValidateLen(ind2);
      Result := new StringSection(self.text, self.i1+ind1, self.i1+ind2);
    end;
    
    public function All(ch_validator: char->boolean): boolean;
    begin
      Result := true;
      for var i: integer := i1 to integer(i2)-1 do
      begin
        Result := ch_validator( text[i] );
        if not Result then break;
      end;
    end;
    public function CountOf(ch: char): integer;
    begin
      for var i: integer := i1 to i2-1 do
        Result += integer( text[i] = ch );
    end;
    
    public static function operator=(text1, text2: StringSection): boolean;
    begin
      begin
        var inv_c := Ord(text1.IsInvalid) + Ord(text2.IsInvalid);
        if inv_c<>0 then
        begin
          Result := inv_c = 2;
          exit;
        end;
      end;
      Result := object.ReferenceEquals(text1.text, text2.text) and (text1.range=text2.range);
      if Result then exit;
      if text1.Length <> text2.Length then exit;
      for var i := 0 to text1.Length-1 do
        if text1[i]<>text2[i] then exit;
      Result := true;
    end;
    public static function operator=(text: StringSection; str: string): boolean;
    begin
      Result := false;
      if str=nil then raise new System.ArgumentNullException;
      if text.IsInvalid then exit;
      if text.Length<>str.Length then exit;
      for var i := 0 to str.Length-1 do
        if text[i]<>str[i] then exit;
      Result := true;
    end;
    public static function operator=(str: string; text: StringSection): boolean := text=str;
    
    public static function operator<>(text1, text2: StringSection) := not (text1=text2);
    public static function operator<>(text: StringSection; str: string) := not (text=str);
    public static function operator<>(str: string; text: StringSection) := not (text=str);
    
    public function StartsWith(str: string): boolean;
    begin
      Result := false;
      if self.Length<str.Length then exit;
      for var i := 0 to str.Length-1 do
        if str[i] <> self[i] then
          exit;
      Result := true;
    end;
    public function EndsWith(str: string): boolean;
    begin
      Result := false;
      if self.Length<str.Length then exit;
      var shift := self.Length-str.Length;
      for var i := 0 to str.Length-1 do
        if str[i] <> self[i+shift] then
          exit;
      Result := true;
    end;
    
    public function IndexOf(ch: char): StringIndex;
    begin
      for var i: integer := self.i1 to self.i2-1 do
        if text[i] = ch then
        begin
          Result := i - integer(self.i1);
          exit;
        end;
      Result := StringIndex.Invalid;
    end;
    public function IndexOf(from: StringIndex; ch: char): StringIndex;
    begin
      Result := self.TrimFirst(from).IndexOf(ch);
      if Result.IsInvalid then exit;
      Result += from;
    end;
    public function IndexOf(ch_validator: char->boolean): StringIndex;
    begin
      for var i: integer := self.i1 to self.i2-1 do
        if ch_validator(text[i]) then
        begin
          Result := i - integer(self.i1);
          exit;
        end;
      Result := StringIndex.Invalid;
    end;
    
    public function LastIndexOf(ch: char): StringIndex;
    begin
      for var i: integer := self.i2-1 downto self.i1 do
        if text[i] = ch then
        begin
          Result := i - integer(self.i1);
          exit;
        end;
      Result := StringIndex.Invalid;
    end;
    
    private static KMP_Cache := new System.Collections.Concurrent.ConcurrentDictionary<string, array of StringIndex>;
    public static function KMP_GetHeader(str: string): array of StringIndex;
    begin
      if KMP_Cache.TryGetValue(str, Result) then exit;
      
      Result := new StringIndex[str.Length];
      var curr_ind := StringIndex.Invalid;
      Result[0] := curr_ind;
      for var i := 1 to str.Length-1 do
      begin
        while true do
        begin
          var next_ind := curr_ind.UnsafeInc;
          if str[i] = str[next_ind] then
            curr_ind := next_ind else
          if not curr_ind.IsInvalid then
          begin
            curr_ind := Result[curr_ind];
            continue;
          end;
          break;
        end;
        Result[i] := curr_ind;
      end;
      
      KMP_Cache[str] := Result;
    end;
    
    public function IndexOf(str: string): StringIndex;
    begin
      if str.Length=0 then raise new System.ArgumentException;
      var header := KMP_GetHeader(str);
      var curr_ind := StringIndex.Invalid;
      
      for var i: integer := self.i1 to self.i2-str.Length do
        while true do
        begin
          var next_ind := curr_ind.UnsafeInc;
          if text[i] = str[next_ind] then
          begin
            curr_ind := next_ind;
            if curr_ind = str.Length-1 then
            begin
              Result := i-integer(self.i1)-str.Length+1;
              exit;
            end;
          end else
          if not curr_ind.IsInvalid then
          begin
            curr_ind := header[curr_ind];
            continue;
          end;
          break;
        end;
      
      Result := StringIndex.Invalid;
    end;
    public function IndexOf(from: StringIndex; str: string): StringIndex;
    begin
      Result := self.TrimFirst(from).IndexOf(str);
      if Result.IsInvalid then exit;
      Result += from;
    end;
    
    public function SubSectionOfFirst(params strs: array of string): StringSection;
    begin
      Result := StringSection.Invalid;
      
      var min_str_len := strs.Min(str->str.Length);
      if self.Length<min_str_len then exit;
      if min_str_len=0 then raise new System.ArgumentException(strs.JoinToString(#10));
      
      var headers := strs.ConvertAll(KMP_GetHeader);
      var curr_inds := ArrFill(strs.Length, StringIndex.Invalid);
      
      for var text_i: integer := self.i1 to self.i2-1 do
      begin
        var text_ch := text[text_i];
        for var str_i := 0 to strs.Length-1 do
        begin
          var str := strs[str_i];
          var header := headers[str_i];
          var curr_ind := curr_inds[str_i];
          
          while true do
          begin
            var next_ind := curr_ind.UnsafeInc;
            if text_ch = str[next_ind] then
            begin
              curr_ind := next_ind;
              if curr_ind = str.Length-1 then
              begin
                var ind_end := text_i+1;
                Result := new StringSection(self.text, ind_end-str.Length, ind_end);
                exit;
              end;
            end else
            if not curr_ind.IsInvalid then
            begin
              curr_ind := header[curr_ind];
              continue;
            end;
            break;
          end;
          
          curr_inds[str_i] := curr_ind;
        end;
      end;
      
    end;
    
    public function IsEscaped(min_ind: StringIndex; escape_sym: char) :=
    self.TakeFirst(0).PrevWhile(min_ind, ch->ch=escape_sym).Length.IsOdd;
    
    public procedure UnescapeTo(res: StringBuilder; escape_sym: char);
    begin
      var escaped := false;
      for i: integer := I1 to I2-1 do
      begin
        var ch := text[i];
        escaped := (ch=escape_sym) and not escaped;
        if not escaped then
          res += ch;
      end;
    end;
    public function Unescape(escape_sym: char): string;
    begin
      var res := new StringBuilder(self.Length);
      UnescapeTo(res, escape_sym);
      Result := res.ToString;
    end;
    
    public function IndexOfUnescaped(str: string; escape_sym: char): StringIndex;
    begin
      var ind := 0;
      while true do
      begin
        Result := self.IndexOf(ind, str);
        if Result.IsInvalid then break;
        if not self.TrimFirst(Result).IsEscaped(self.I1, escape_sym) then break;
        ind := Result+1;
      end;
    end;
    public function IndexOfUnescaped(from: StringIndex; str: string; escape_sym: char): StringIndex;
    begin
      Result := self.TrimFirst(from).IndexOfUnescaped(str, escape_sym);
      if Result.IsInvalid then exit;
      Result += from;
    end;
    
    public function SubSectionOfFirstUnescaped(escape_sym: char; params strs: array of string): StringSection;
    begin
      Result := self;
      while true do
      begin
        Result := Result.SubSectionOfFirst(strs);
        if Result.IsInvalid then break;
        if not Result.IsEscaped(self.I1, escape_sym) then break;
        Result := Result.TakeLast(0).WithI2(self.I2);
      end;
    end;
    
    public function SplitByUnescaped(by: string; escape_sym: char): List<StringSection>;
    begin
      Result := new List<StringSection>;
      while true do
      begin
        var sep := self.SubSectionOfFirstUnescaped(escape_sym, by);
        if sep.IsInvalid then break;
        Result += self.WithI2(sep.I1);
        self.range.i1 := sep.I2;
      end;
      Result += self;
    end;
    
    public function ToString: string; override :=
    if self.IsInvalid then 'StringSection.Invalid' else range.ToString(text);
    public property AsString: string read ToString;
    
  end;
  
//TODO #2692
procedure operator*=(sb: StringBuilder; s: StringSection); extensionmethod := sb.Append(s.text, s.I1, s.Length);

end.