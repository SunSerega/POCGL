unit PointComponents;

{$zerobasedstrings}

{$savepcu false} //TODO

uses Settings;

type
  
  PointComponentShift = record
    private bits: int64;
    private word_ind := 0;
    private overflow := false;
    
    public constructor(word_c, pow: integer; shift: real);
    // 64 bits of int64
    // -= 1 bit for sign
    // -= 1 bit because shift is normalized to [1;2), the "1.xxx" form, with 1 leading int bit
    const max_local_pow = 62;
    begin
      var sign := Sign(shift);
      shift *= sign;
      self.bits := sign;
      if sign=0 then exit;
      
      if (shift<1) or (shift>=2) then
      begin
        var extra_pow_r := Log2(shift);
        var extra_pow_i := Floor(extra_pow_r);
        pow += extra_pow_i;
        shift := 2 ** (extra_pow_r-extra_pow_i);
        {$ifdef DEBUG}
        if (shift<1) or (shift>=2) then
          raise new System.InvalidOperationException;
        {$endif DEBUG}
      end;
      
      // With pow=0,shift=1 this is the only bit to set
      var head_bit_ind := Settings.z_int_bits-1 - pow;
      // In ideal case this is on the word bound or within 12 more bits,
      // allowing to save all 52 bits of mantissa of "real"
      // But if not, we round word_ind down (div) to prev word
      // And then rounding to int64, loosing some precision (max 19/52 bits)
      var after_tail_bit_ind := head_bit_ind + max_local_pow;
      
      var word_ind_raw := after_tail_bit_ind div 32;
      var word_ind := word_ind_raw.Clamp(0, word_c-1);
      self.word_ind := word_ind;
      
      // Bit shift by max_local_pow if there was no rounding (div)
      // If there was, bit shift a bit less
      shift *= 2 ** (max_local_pow-1 - (after_tail_bit_ind - (word_ind+1)*32));
      
      {$ifdef DEBUG}
      //TODO Слишном сонный чтобы доразобраться
      // - Вылетает если pow>32 (очень далеко отдалить)
//      if (after_tail_bit_ind>=0) and (shift>int64.MaxValue) then
//        raise new System.InvalidOperationException;
      if (after_tail_bit_ind<word_c*32) and (shift<1) then
        raise new System.InvalidOperationException;
      if shift<0 then
        raise new System.NotImplementedException;
      {$endif DEBUG}
      
      try
        self.bits *= System.Convert.ToInt64(shift);
      except
        on System.OverflowException do
          self.overflow := true;
      end;
      
    end;
    
    public static function operator+(shift: PointComponentShift) := shift;
    public static function operator-(shift: PointComponentShift): PointComponentShift;
    begin
      Result.bits := -shift.bits;
      Result.word_ind := shift.word_ind;
      Result.overflow := shift.overflow;
    end;
    
    public function ToString: string; override;
    begin
      var sb := new StringBuilder;
      if not overflow then
      begin
        sb.Append('[');
        sb.Append(word_ind);
        sb.Append('] += ');
      end;
      sb.Append( if bits<0 then '-' else '+' );
      if overflow then
        sb.Append('∞') else
      begin
        var carry := Abs(bits);
        for var bit_i := 30+32*Ord(carry>integer.MaxValue) downto 0 do
        begin
          sb.Append(carry shr bit_i and 1);
          if bit_i=32 then
            sb += '|';
        end;
      end;
      Result := sb.ToString;
    end;
    
  end;
  
  PointComponent = record(System.IEquatable<PointComponent>)
    private _words: array of cardinal;
    private const sign_bit_mask: cardinal = 1 shl 31;
    private const sign_bit_anti_mask: cardinal = not sign_bit_mask;
    
    public constructor(size: integer := 1);
    begin
      {$ifdef DEBUG}
      if size<1 then raise new System.InvalidOperationException;
      {$endif DEBUG}
      _words := new cardinal[size];
    end;
    
    public property Words: array of cardinal read _words;
    
    public static function Equals(c1, c2: PointComponent): boolean;
    begin
      var size := c1.Words.Length;
      {$ifdef DEBUG}
      if size <> c2.Words.Length then
        raise new System.InvalidOperationException($'{c1} vs {c2}');
      {$endif DEBUG}
      Result := false;
      for var i := size-1 downto 0 do
        if c1.Words[i] <> c2.Words[i] then exit;
      Result := true;
    end;
    public static function operator=(c1, c2: PointComponent) := Equals(c1, c2);
    public static function operator<>(c1, c2: PointComponent) := not (c1 = c2);
    
    public function Equals(other: PointComponent) := Equals(self, other);
    public function Equals(o: object): boolean; override :=
      (o is PointComponent(var other)) and Equals(self, other);
    
    public function GetHashCode: integer; override;
    begin
      var l := Words.Length;
      Result := Words[l-1];
      if l<>1 then
        Result := Result xor Words[l-2];
      // GetHashCode должно считаться быстро
      // 64 нижних бита уже достаточно
    end;
    
    public function ToString: string; override;
    begin
      var res_size := Words.Length*33;
      var sb := new StringBuilder(res_size);
      
      sb += if Words[0] and sign_bit_mask = 0 then '+' else '-';
      for var bit_i := 1 to 31 do
      begin
        if bit_i=Settings.z_int_bits then
          sb += '.';
        sb.Append(Words[0] shr (31-bit_i) and 1);
      end;
      
      for var word_i := 1 to Words.Length-1 do
      begin
        sb += '|';
        for var bit_i := 0 to 31 do
          sb.Append(Words[word_i] shr (31-bit_i) and 1);
      end;
      
      {$ifdef DEBUG}
      if sb.Length<>res_size then
        raise new System.InvalidOperationException;
      {$endif DEBUG}
      Result := sb.ToString;
    end;
    public static function Parse(s: string): PointComponent;
    begin
      Result._words := s.Split('|').ConvertAll((w,i)->
      begin
        var raise_format := procedure(m: string)->
          raise new System.FormatException($'{m} in word#{i} [{w}] of [{s}]');
        
        if i=0 then
        begin
          
          case w[0] of
            '+': w[0] := '0';
            '-': w[0] := '1';
            else raise_format($'First char of first word must be a sign');
          end;
          
          if w[Settings.z_int_bits]<>'.' then
            raise_format($'Char#{Settings.z_int_bits} of first word must be a decimal point');
          w := w.Remove(Settings.z_int_bits,1);
          
        end;
        
        if w.Length<>32 then
          raise_format($'Word must be 32 chars long, got {w.Length}');
        
        Result := cardinal(0);
        foreach var ch in w index ch_ind do
        begin
          Result *= 2;
          case ch of
            '0': ;
            '1': Result += 1;
            else raise_format($'Char#{ch_ind} was [{ch}]');
          end;
        end;
        
      end);
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter) :=
      foreach var x in Words do bw.Write(x);
    public static function Load(br: System.IO.BinaryReader; word_count: integer): PointComponent;
    begin
      Result := new PointComponent(word_count);
      for var i := 0 to word_count-1 do
        Result.WOrds[i] := br.ReadUInt32;
    end;
    
    public function FirstWordToReal: real;
    const body_d = 1 shl (32-z_int_bits);
    const body_m = 1/body_d;
    begin
      Result := Words[0] and sign_bit_anti_mask;
      Result *= body_m;
      if Words[0] and sign_bit_mask <> 0 then
        Result := -Result;
    end;
    
    public function WithSize(size: integer): PointComponent;
    begin
      {$ifdef DEBUG}
      if size=self.Words.Length then
        raise new System.InvalidOperationException;
      {$endif DEBUG}
      Result := new PointComponent(size);
      for var i := 0 to Min(self.Words.Length, size)-1 do
        Result.Words[i] := self.Words[i];
    end;
    
    private procedure HandleMinusZero(expect_minus_zero: boolean);
    begin
      if Words[0] <> sign_bit_mask then exit;
      for var i := 1 to Words.Length-1 do
        if Words[i]<>0 then exit;
      if not expect_minus_zero then
        raise new System.InvalidOperationException;
      Words[0] += sign_bit_mask;
    end;
    
    public function WithShiftClamp2(shift: PointComponentShift; expect_minus_zero: boolean): PointComponent;
    const v2: cardinal = 1 shl (33-Settings.z_int_bits);
    begin
      Result := self;
      if shift.bits=0 then exit;
      var size := self.Words.Length;
      Result := new PointComponent(size);
      
      if shift.overflow then
      begin
        Result.Words[0] := v2;
        if shift.bits<0 then
          Result.Words[0] += sign_bit_mask;
        // All other words are already 0 on init
        exit;
      end;
      
      var d := shift.bits;
      var self_sign := self.Words[0] and sign_bit_mask;
      var same_sign := (self_sign<>0) = (d<0);
      if self_sign<>0 then
        d := -d;
      
      for var i := size-1 downto shift.word_ind+1 do
        Result.Words[i] := self.Words[i];
      
      var carry := d;
      for var i := shift.word_ind downto 1 do
      begin
        carry += self.Words[i];
        Result.Words[i] := carry;
        carry := carry shr 32;
      end;
      
      begin
        carry += self.Words[0] and sign_bit_anti_mask;
        Result.Words[0] := carry xor self_sign;
      end;
      
      if Abs(carry) shr (33-Settings.z_int_bits) <> 0 then
      begin
        var res_sign := self_sign;
        if not same_sign then
          res_sign := sign_bit_mask - res_sign;
        Result.Words[0] := v2 xor res_sign;
        for var i := 1 to size-1 do
          Result.Words[i] := 0;
        exit;
      end;
      
      if self_sign <> (Result.Words[0] and sign_bit_mask) then
      begin
        if same_sign then
          raise new System.InvalidOperationException;
        var compliment := true;
        for var i := size-1 downto 1 do
        begin
          Result.Words[i] := not Result.Words[i] + Ord(compliment);
          compliment := compliment and (Result.Words[i]=0);
        end;
        Result.Words[0] := sign_bit_mask xor not Result.Words[0] + Ord(compliment);
      end;
      
      self.HandleMinusZero(expect_minus_zero);
    end;
    
    // Round self to the block boundry
    // PointComponent with only bit at block_sz_bit_ind set is the block side length
    // - Self is set to the bound between blocks
    // - block_len_outside is set to value in [0;1), indicating how much of the block was outside of initial bounds
    public procedure SelfBlockRound(block_sz_bit_ind: integer; round_up: boolean; var block_len_outside: single);
    begin
      
      {$region Init}
      
      var size := Words.Length;
      
      var word_inner_pos: integer; // 0..31
      var word_ind := System.Math.DivRem(block_sz_bit_ind, 32, word_inner_pos);
      
      var curr_block_sz_bit: cardinal := 1 shl (31-word_inner_pos);
      var curr_word_mask: cardinal := curr_block_sz_bit-1; // 0 if word_inner_pos=31 (last bit in current word)
      
      var self_sign := Words[0] and sign_bit_mask;
      var body_round_up := round_up = (self_sign=0);
      
      {$endregion Init}
      
      {$region Calculate block_len_outside}
      
      begin
        var skip_c := uint64(Words[word_ind] and curr_word_mask) shl 32;
        // "single" has 23 bits of mantissa, so need at least 1 word to use up all precision
        if word_ind+1<>size then skip_c += Words[word_ind+1];
        
        var skip_l := single(skip_c);
        if skip_c<>0 then
        begin
          skip_l /= uint64(1) shl (63-word_inner_pos);
          if body_round_up then
            skip_l := 1-skip_l;
        end;
        
        block_len_outside := skip_l;
      end;
      
      {$endregion Calculate block_len_outside}
      
      {$region Trim rounded bits}
      // First round body down (trim bits after block_sz_bit_ind)
      
      var any_rounding := Words[word_ind] and curr_word_mask <> 0;
      Words[word_ind] := Words[word_ind] and not curr_word_mask;
      
      for var i := word_ind+1 to size-1 do
      begin
        any_rounding := (Words[i]<>0) or any_rounding;
        Words[i] := 0;
      end;
      
      {$endregion Trim rounded bits}
      
      {$region Fix rounding}
      
      // Then add 1 block side length to fix rounding, if needed
      if body_round_up and any_rounding then
      begin
        Words[word_ind] += curr_block_sz_bit;
        var i := word_ind;
        while (Words[i]=0) and (i<>0) do
        begin
          i -= 1;
          Words[i] += 1;
        end;
      end;
      
      {$endregion Fix rounding}
      
      if Words[0] and sign_bit_mask <> self_sign then
        raise new System.OverflowException;
      HandleMinusZero(round_up);
      
    end;
    public function WithBlockRound(block_sz_bit_ind: integer; round_up: boolean): PointComponent;
    begin
      Result._words := self.Words.ToArray;
      var block_len_outside: single;
      Result.SelfBlockRound(block_sz_bit_ind, round_up, block_len_outside);
    end;
    
    private function BodyWordAs64AtOr0(ind: integer): int64 :=
      if ind=0 then Words[0] and sign_bit_anti_mask else
      if ind<Words.Length then Words[ind] else 0;
    // c1 is lower bound of first block
    // c2 is upper bound of last block
    public static function BlocksCount(c1, c2: PointComponent; block_sz_bit_ind: integer): integer;
    begin
      
      var word_inner_pos: integer; // 0..31
      var word_ind := System.Math.DivRem(block_sz_bit_ind, 32, word_inner_pos);
      var lower_bits_mask: int64 := (1 shl (31-word_inner_pos))-1;
      
      var c1_sign := c1.Words[0] and sign_bit_mask;
      var c2_sign := c2.Words[0] and sign_bit_mask;
      var same_sign := c1_sign=c2_sign;
      
      for var i := 0 to word_ind-2 do
      begin
        var word1 := c1.BodyWordAs64AtOr0(i);
        var word2 := c2.BodyWordAs64AtOr0(i);
        if word1<>word2 then
          raise new System.OverflowException;
        if not same_sign and (word1<>0) then
          raise new System.OverflowException;
      end;
      
      {$ifdef DEBUG}
      for var i := word_ind+1 to c1.Words.Length-1 do
        if c1.Words[i] <> 0 then raise new System.InvalidOperationException;
      for var i := word_ind+1 to c2.Words.Length-1 do
        if c2.Words[i] <> 0 then raise new System.InvalidOperationException;
      {$endif DEBUG}
      
      var total_diff := int64(0);
      if word_ind<>0 then
      begin
        var word1 := c1.BodyWordAs64AtOr0(word_ind-1);
        var word2 := c2.BodyWordAs64AtOr0(word_ind-1);
        
        var diff := if same_sign then word2-word1 else word2+word1;
        var diff_sign := Sign(diff);
        diff *= diff_sign;
        diff := diff and lower_bits_mask;
        diff := diff shl (1+word_inner_pos);
        diff *= diff_sign;
        total_diff += diff;
        
        word1 := word1 and not lower_bits_mask;
        word2 := word2 and not lower_bits_mask;
        if word1<>word2 then
          raise new System.OverflowException;
        if not same_sign and (word1<>0) then
          raise new System.OverflowException;
        
      end;
      begin
        var word1 := c1.BodyWordAs64AtOr0(word_ind);
        var word2 := c2.BodyWordAs64AtOr0(word_ind);
        
        var diff := if same_sign then word2-word1 else word2+word1;
        var diff_sign := Sign(diff);
        diff *= diff_sign;
        diff := diff shr (31-word_inner_pos);
        diff *= diff_sign;
        total_diff += diff;
        
        {$ifdef DEBUG}
        if word1 and lower_bits_mask <> 0 then raise new System.InvalidOperationException;
        if word2 and lower_bits_mask <> 0 then raise new System.InvalidOperationException;
        {$endif DEBUG}
        
      end;
      
      total_diff := if c2_sign=0 then +total_diff else -total_diff;
      Result := total_diff;
      
      {$ifdef DEBUG}
      if Result <> total_diff then
      begin
//        BlocksCount(c1, c2, block_sz_bit_ind);
        //TODO "diff := lower_bits_mask and ..." даёт неправильное значение для отрицательных diff
        // - shr/shl тоже не расчитаны на этот случай
        // - Сейчас падает если приблизить на scale_pow=-30
        // - Тестил на мини-мандельбротах в левой, легко-просчитываемой части
        raise new System.OverflowException;
      end;
      {$endif DEBUG}
    end;
    
    public function MakeNextBlockBound(block_sz_bit_ind: integer): PointComponent;
    begin
      var size := Words.Length;
      Result := new PointComponent(size);
      
      var word_inner_pos: integer; // 0..31
      var word_ind := System.Math.DivRem(block_sz_bit_ind, 32, word_inner_pos);
      var curr_block_sz_bit: cardinal := 1 shl (31-word_inner_pos);
      
      {$ifdef DEBUG}
      if Words[word_ind] and (curr_block_sz_bit-1) <> 0 then
        raise new System.InvalidOperationException;
      for var i := word_ind+1 to size-1 do
        if Words[i]<>0 then
          raise new System.InvalidOperationException;
      {$endif DEBUG}
      
      var self_sign := Words[0] and sign_bit_mask;
      var i := word_ind;
      
      if self_sign=0 then
      begin
        Result.Words[i] := self.Words[i] + curr_block_sz_bit;
        while (Result.Words[i]=0) and (i<>0) do
        begin
          i -= 1;
          Result.Words[i] := self.Words[i] + 1;
        end;
      end else
      // Substract instead of adding
      begin
        Result.Words[i] := self.Words[i] - curr_block_sz_bit;
        while (Result.Words[i]>self.Words[i]) and (i<>0) do
        begin
          i -= 1;
          Result.Words[i] := self.Words[i] - 1;
        end;
      end;
      
      while i<>0 do
      begin
        i -= 1;
        Result.Words[i] := self.Words[i];
      end;
      
      if Result.Words[0] and sign_bit_mask <> self_sign then
        raise new System.OverflowException;
      Result.HandleMinusZero(true);
    end;
    
    // [c1,c2) range of points
    public static function Range(c1, c2: PointComponent; block_sz_bit_ind: integer): array of PointComponent;
    begin
      Result := new PointComponent[BlocksCount(c1,c2,block_sz_bit_ind)];
      var x := c1;
      Result[0] := x;
      for var i := 1 to Result.Length-1 do
      begin
        x := x.MakeNextBlockBound(block_sz_bit_ind);
        Result[i] := x;
      end;
      {$ifdef DEBUG}
      if x.MakeNextBlockBound(block_sz_bit_ind)<>c2 then
        raise new System.InvalidOperationException;
      {$endif DEBUG}
    end;
    
  end;
  
  PointPos = record(System.IEquatable<PointPos>)
    // Real and imaginary components of complex number
    public r,i: PointComponent;
    
    public constructor(r,i: PointComponent) :=
      (self.r,self.i) := (r,i);
    
    public static function operator=(p1, p2: PointPos) := (p1.r=p2.r) and (p1.i=p2.i);
    public static function operator<>(p1, p2: PointPos) := not(p1=p2);
    public function Equals(other: PointPos) := self=other;
    public function Equals(o: object): boolean; override :=
      (o is PointPos(var other)) and Equals(other);
    public function GetHashCode: integer; override :=
      r.GetHashCode xor i.GetHashCode*668265263;
    
    public function ToString: string; override := $'({r}; {i})';
    
    public property Size: integer read r.Words.Length;
    public function WithSize(size: integer) := new PointPos(
      r.WithSize(size),
      i.WithSize(size)
    );
    
    public procedure Save(bw: System.IO.BinaryWriter);
    begin
      r.Save(bw);
      i.Save(bw);
    end;
    public static function Load(br: System.IO.BinaryReader; word_count: integer) := new PointPos(
      PointComponent.Load(br, word_count),
      PointComponent.Load(br, word_count)
    );
    
    public function WithShiftClamp2(dr, di: PointComponentShift; expect_minus_zero: boolean) := new PointPos(
      self.r.WithShiftClamp2(dr, expect_minus_zero),
      self.i.WithShiftClamp2(di, expect_minus_zero)
    );
    
    public procedure SelfBlockRound(block_sz_bit_ind: integer; round_up: boolean; var skip_r: single; var skip_i: single);
    begin
      self.r.SelfBlockRound(block_sz_bit_ind, round_up, skip_r);
      self.i.SelfBlockRound(block_sz_bit_ind, round_up, skip_i);
    end;
    
  end;
  
end.