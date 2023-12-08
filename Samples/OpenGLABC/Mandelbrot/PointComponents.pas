unit PointComponents;

{$savepcu false} //TODO

uses Settings;

type
  
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
        raise new System.InvalidOperationException;
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
      // GetHashCode должно считать быстро
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
    
    public static function RoundToLowestBits(size, bit_ind: integer; x: real): int64;
    begin
      var d_shift := size*32-1-bit_ind;
      {$ifdef DEBUG}
      if d_shift>=63 then
        raise new System.OverflowException;
      {$endif DEBUG}
      x *= int64(1) shl d_shift;
      Result := Convert.ToInt64(x);
    end;
    public function AddLowestBits(d: int64): PointComponent;
    begin
      var size := self.Words.Length;
      var self_sign := self.Words[0] and sign_bit_mask;
      var same_sign := (self_sign<>0) = (d<0);
      if self_sign<>0 then
        d := -d;
      
      Result := new PointComponent(size);
      var carry := d;
      for var i := size-1 downto 1 do
      begin
        carry += self.Words[i];
        {$ifdef DEBUG}
        if (d<0) <> (carry<0) then
          raise new System.OverflowException;
        {$endif DEBUG}
        Result.Words[i] := carry;
        carry := carry shr 32;
      end;
      
      begin
        carry += self.Words[0] and sign_bit_anti_mask;
        {$ifdef DEBUG}
        if (d<0) <> (carry<0) then
          raise new System.OverflowException;
        {$endif DEBUG}
        Result.Words[0] := carry xor self_sign;
      end;
      
      if self_sign <> (Result.Words[0] and sign_bit_mask) then
      begin
        if same_sign or (Abs(carry) shr 32 <> 0) then
          raise new System.OverflowException;
        var compliment := true;
        for var i := size-1 downto 1 do
        begin
          Result.Words[i] := not Result.Words[i] + Ord(compliment);
          compliment := compliment and (Result.Words[i]=0);
        end;
        Result.Words[0] := sign_bit_mask xor not Result.Words[0] + Ord(compliment);
      end;
      
    end;
    
    // Round to the block bound
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
    end;
    
    public procedure SelfFlipIfMinusZero;
    begin
      if Words[0] <> sign_bit_mask then exit;
      for var i := 1 to Words.Length-1 do
        if Words[i]<>0 then exit;
      Words[0] += sign_bit_mask;
    end;
    
    private function BodyWordAs64At(ind: integer): int64 :=
      if ind=0 then Words[0] and sign_bit_anti_mask else Words[ind];
    // c1 is lower bound of first block
    // c2 is upper bound of last block
    public static function BlocksCount(c1, c2: PointComponent; block_sz_bit_ind: integer): integer;
    begin
      
      {$ifdef DEBUG}
      if c1.Words.Length <> c2.Words.Length then
        raise new System.InvalidOperationException;
      {$endif DEBUG}
      
      var word_inner_pos: integer; // 0..31
      var word_ind := System.Math.DivRem(block_sz_bit_ind, 32, word_inner_pos);
      
      var c1_sign := c1.Words[0] and sign_bit_mask;
      var c2_sign := c2.Words[0] and sign_bit_mask;
      {$ifdef DEBUG}
      if (c1_sign=0) and (c2_sign<>0) then
        raise new System.InvalidOperationException;
      {$endif DEBUG}
      var same_sign := c1_sign=c2_sign;
      
      var lower_bits_mask: cardinal := (1 shl (31-word_inner_pos))-1;
      
      var diff := int64(0);
      if word_ind<>0 then
      begin
        var prev_word1 := c1.BodyWordAs64At(word_ind-1);
        var prev_word2 := c2.BodyWordAs64At(word_ind-1);
        diff := lower_bits_mask and if same_sign then prev_word2-prev_word1 else prev_word2+prev_word1;
        diff := diff shl (1+word_inner_pos);
        {$ifdef DEBUG}
        if (prev_word1 and not lower_bits_mask) <> (prev_word2 and not lower_bits_mask) then
          raise new System.InvalidOperationException;
        {$endif DEBUG}
      end;
      var curr_word1 := c1.BodyWordAs64At(word_ind);
      var curr_word2 := c2.BodyWordAs64At(word_ind);
      {$ifdef DEBUG}
      if curr_word1 and lower_bits_mask <> 0 then raise new System.InvalidOperationException;
      if curr_word2 and lower_bits_mask <> 0 then raise new System.InvalidOperationException;
      {$endif DEBUG}
      diff += (if same_sign then curr_word2-curr_word1 else curr_word2+curr_word1) shr (31-word_inner_pos);
      
      Result := diff;
      
      {$ifdef DEBUG}
      if int64(Result) <> diff then
        raise new System.OverflowException;
      for var i := 0 to word_ind-2 do
        if c1.BodyWordAs64At(i) <> c2.BodyWordAs64At(i) then
          raise new System.OverflowException;
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
      if self_sign=0 then
      begin
        var i := word_ind;
        Result.Words[i] := self.Words[i] + curr_block_sz_bit;
        while (Result.Words[i]=0) and (i<>0) do
        begin
          i -= 1;
          Result.Words[word_ind] := self.Words[word_ind] + 1;
        end;
      end else
      // Substract instead of adding
      begin
        var i := word_ind;
        Result.Words[i] := self.Words[i] - curr_block_sz_bit;
        while (Result.Words[i]>self.Words[i]) and (i<>0) do
        begin
          i -= 1;
          Result.Words[i] := self.Words[i] - 1;
        end;
      end;
      
      if Result.Words[0] and sign_bit_mask <> self_sign then
        raise new System.OverflowException;
      Result.SelfFlipIfMinusZero;
    end;
    
  end;
  
  PointPos = record
    public r,i: PointComponent;
    
    public constructor(r,i: PointComponent) :=
      (self.r,self.i) := (r,i);
    
    public property Size: integer read r.Words.Length;
    public function WithSize(size: integer) := new PointPos(
      r.WithSize(size),
      i.WithSize(size)
    );
    
    public function AddLowestBits(dr,di: int64) := new PointPos(
      r.AddLowestBits(dr),
      i.AddLowestBits(di)
    );
    
    public procedure SelfBlockRound(block_sz_bit_ind: integer; round_up: boolean; var skip_r: single; var skip_i: single);
    begin
      self.r.SelfBlockRound(block_sz_bit_ind, round_up, skip_r);
      self.i.SelfBlockRound(block_sz_bit_ind, round_up, skip_i);
    end;
    
    public procedure SelfFlipIfMinusZero;
    begin
      self.r.SelfFlipIfMinusZero;
      self.i.SelfFlipIfMinusZero;
    end;
    
  end;
  
end.