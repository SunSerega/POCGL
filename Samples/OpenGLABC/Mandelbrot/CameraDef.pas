unit CameraDef;

{$savepcu false} //TODO

uses Settings;

uses PointComponents;

type
  CameraPos = record
    
    public pos: PointPos;
    public dw,dh: single; // Window distance from center
    
    // Actual camera scale = scale_fine * 2**scale_pow
    // OpenGL space Y is -1..+1
    // Visible logical space Y is -scale..+scale
    // Visible logical space X is Y*dw/dh
    // Always 1 <= scale_fine < 2
    public scale_fine: single;
    public scale_pow: integer;
    
    public constructor(w,h: integer);
    begin
      self.pos := new PointPos(
        new PointComponent,
        new PointComponent
      );
      Resize(w,h);
      
      // By default fit 4x4 of logical space around (0;0) inside the window
      // Logical space Y is -2..+2, scale=2
      self.scale_fine := 2;
      // But if dw<dh then scale=2/(dw/dh)
      if dw<dh then scale_fine /= AspectRatio;
      self.scale_pow := 0;
      
      FixScalePow;
    end;
    public procedure Resize(w,h: integer);
    begin
      if w<1 then w := 1;
      if h<1 then h := 1;
      self.dw := single(w)/2;
      self.dh := single(h)/2;
    end;
    
    public function AspectRatio := real(dw)/real(dh);
    
    public function GetPointScalePow :=
      (self.scale_pow + Settings.scale_pow_shift + Floor(Log2(self.scale_fine/dh)))
      .ClampTop(Settings.max_block_scale_pow - Settings.block_w_pow);
    private function GetBitCount := Settings.z_int_bits + -GetPointScalePow + Settings.z_extra_precision_bits;
    private function GetWordCount := Ceil(GetBitCount/32).ClampBottom(1);
//    public function GetPosBitCount := Settings.z_int_bits - (self.scale_pow + Floor(Log2(self.scale_fine/dh)));
//    public function GetBlockBitCount := Settings.z_int_bits - (self.scale_pow + Settings.scale_shift - Settings.block_w_pow) + Settings.z_extra_precision_bits;
    
    private procedure FixScalePow;
    begin
      if (scale_fine>=1) and (scale_fine<2) then exit;
      
      begin
        var scale_fine_pow_r := Log2(scale_fine);
        var scale_fine_pow_i := Floor(scale_fine_pow_r);
        self.scale_pow += scale_fine_pow_i;
        self.scale_fine := 2 ** (scale_fine_pow_r-scale_fine_pow_i);
        if (scale_fine<1) or (scale_fine>=2) then
          raise new System.InvalidOperationException;
      end;
      
    end;
    
    public procedure FixWordCount;
    begin
      var pos_word_count := GetWordCount;
      if pos.Size = pos_word_count then exit;
      pos := pos.WithSize(pos_word_count);
    end;
    
    public procedure Move(move_x,move_y, mouse_x,mouse_y, scale_speed: real; mouse_captured: boolean);
    begin
      var scale_mlt := 0.9 ** scale_speed;
      
      begin
        var shift_mlt := scale_fine * (1 - scale_mlt) * Ord(mouse_captured);
        var dx := mouse_x-dw;
        var dy := mouse_y-dh;
        dx *= +shift_mlt/dw * AspectRatio;
        dy *= -shift_mlt/dh;
        var word_count := self.pos.Size;
        var dr := new PointComponentShift(word_count, self.scale_pow, dx + move_x*scale_fine/dh);
        var di := new PointComponentShift(word_count, self.scale_pow, dy + move_y*scale_fine/dh);
        self.pos := self.pos.WithShiftClamp2(dr,di, true);
      end;
      
      self.scale_fine *= scale_mlt;
      FixScalePow;
    end;
    
    public function ToString(comment: string): string;
    begin
      var sb := new StringBuilder;
      
      if comment<>nil then
      begin
        sb += 'c=';
        sb += comment.Replace('\','\\').Replace(#13#10,#10).Replace(#10,'\'#10);
        sb += #10;
      end;
      
      sb += 'pos.r=';
      sb += self.pos.r.ToString;
      sb += #10;
      
      sb += 'pos.i=';
      sb += self.pos.i.ToString;
      sb += #10;
      
      sb += 'scale=';
      sb += self.scale_fine.ToString;
      sb += '*2^';
      sb += self.scale_pow.ToString;
      
      Result := sb.ToString;
    end;
    public function ToString: string; override := ToString(nil);
    
    public static function Parse(text: string; on_comment: string->()): CameraPos;
    begin
      Result := default(CameraPos);
      var scale_is_set := false;
      
      var l_enmr := text.Replace(#13#10,#10).Split(#10).AsEnumerable.GetEnumerator;
      while l_enmr.MoveNext do
      begin
        var l := l_enmr.Current;
        if string.IsNullOrWhiteSpace(l) then continue;
        var spl := l.Split(|'='|,2);
        if spl.Length<>2 then
          raise new System.FormatException(l);
        case spl[0] of
          
          'pos.r':
            if Result.pos.r.Words=nil then
              Result.pos.r := PointComponent.Parse(spl[1]) else
              raise new System.FormatException($'pos.r is already set: [{#10}{text}{#10}]');
          'pos.i':
            if Result.pos.i.Words=nil then
              Result.pos.i := PointComponent.Parse(spl[1]) else
              raise new System.FormatException($'pos.i is already set: [{#10}{text}{#10}]');
          
          'scale':
          begin
            if scale_is_set then
              raise new System.FormatException($'scale is already set: [{#10}{text}{#10}]');
            spl := spl[1].Split(|'*2^'|,2,System.StringSplitOptions.None);
            Result.scale_fine := single.Parse(spl[0]);
            Result.scale_pow := integer.Parse(spl[1]);
            scale_is_set := true;
          end;
          
          'c':
          begin
            var sb := new StringBuilder(spl[1]);
            while true do
            begin
              
              begin
                var last_bs_c := 0;
                while last_bs_c < sb.Length do
                begin
                  if sb[sb.Length-1-last_bs_c] <> '\' then break;
                  last_bs_c += 1;
                end;
                if last_bs_c.IsEven then break;
              end;
              
              sb.Length -= 1;
              if not l_enmr.MoveNext then
                raise new System.FormatException('Unfinished comment');
              sb += #10;
              sb += l_enmr.Current;
              
            end;
            
            if on_comment<>nil then on_comment(sb.ToString.Replace('\\','\'));
          end;
          
        end;
      end;
      
      if Result.pos.r.Words=nil then
        raise new System.FormatException($'pos.r not set: [{#10}{text}{#10}]');
      if Result.pos.i.Words=nil then
        raise new System.FormatException($'pos.i not set: [{#10}{text}{#10}]');
      if not scale_is_set then
        raise new System.FormatException($'scale not set: [{#10}{text}{#10}]');
      
    end;
    
  end;

end.