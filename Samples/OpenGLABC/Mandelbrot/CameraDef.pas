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
      // But if dw<dh then scale=2*(dw/dh)
      if dw<dh then scale_fine *= AspectRatio;
      self.scale_pow := 0;
      
      FixScalePow;
    end;
    public procedure Resize(w,h: integer);
    begin
      self.dw := single(w)/2;
      self.dh := single(h)/2;
    end;
    
    public function AspectRatio := real(dw)/real(dh);
    
    public function GetPointScaleAndMainMipMapLvl: System.ValueTuple<integer, integer>;
    const max_point_scale = Settings.max_block_scale-Settings.block_w_pow;
    begin
      var point_scale := self.scale_pow + Settings.scale_shift + Floor(Log2(self.scale_fine/dh));
      var main_mipmap_lvl := -scale_shift;
      if point_scale > max_point_scale then
      begin
        main_mipmap_lvl += point_scale-max_point_scale;
        point_scale := max_point_scale;
      end;
      Result := System.ValueTuple.Create(point_scale, main_mipmap_lvl.Clamp(0,block_w));
    end;
    private function GetBitCount := Settings.z_int_bits + -GetPointScaleAndMainMipMapLvl.Item1 + Settings.z_extra_precision_bits;
    private function GetWordCount := Ceil(GetBitCount/32).ClampBottom(1);
//    public function GetPosBitCount := Settings.z_int_bits - (self.scale_pow + Floor(Log2(self.scale_fine/dh)));
//    public function GetBlockBitCount := Settings.z_int_bits - (self.scale_pow + Settings.scale_shift - Settings.block_w_pow) + Settings.z_extra_precision_bits;
    
    public procedure FixScalePow;
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
      
      var pos_word_count := GetWordCount;
      if pos.Size = pos_word_count then exit;
      pos := pos.WithSize(pos_word_count);
      
    end;
    
  end;

end.