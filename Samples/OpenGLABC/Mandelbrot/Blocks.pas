unit Blocks;

{$savepcu false} //TODO

uses OpenCLABC;

uses Settings;
uses PointComponents;
uses CameraDef;
uses MandelbrotSampling;
uses MemoryLayering;

type
  CLCodeExecutionError = MandelbrotSampling.CLCodeExecutionError;
  
  ShiftedCLArray<T> = record
  where T: record;
    public a: CLArray<T>;
    public shift, row_len: cardinal;
    
    public constructor(a: CLArray<T>; shift, row_len: cardinal);
    begin
      self.a := a;
      self.shift := shift;
      self.row_len := row_len;
    end;
    
  end;
  
  BlockLayer = class;
  // Блок из block_w*block_w точек 
  PointBlock = sealed class(IMemoryLayerData)
    private layer: BlockLayer;
    
    // Принимает значения -∞..1
    // Длина стороны блока в логическом пространстве = 2**block_scale_pow
    private block_scale_pow: integer;
    private pos00: PointPos;
    
    private vram_pos00: CLArray<cardinal>;
    private vram_data: CLArray<cardinal> := nil;
    
    private ram_data: array of cardinal := nil;
    
    private drive_cache_file: string := nil;
    // Current block format:
    //
    // version: int32 := cache_format_version
    // scale: int32
    // word_count: int32
    // pos00: PointPos
    // data: array of uint32
    //
    // Also used in Drive_MemoryLayer
    private const drive_cache_format_version = 1;
    private static last_drive_cache_id := 0;
    private static drive_cache_dir_name := $'Cache/block_w_pow={Settings.block_w_pow}';
    private const drive_cache_ext_name = 'point_block';
    private static function AllocDriveCacheFile: string;
    begin
      while true do
      begin
        var id := System.Threading.Interlocked.Increment(last_drive_cache_id);
        Result := $'{drive_cache_dir_name}/{id}.{drive_cache_ext_name}';
        if not FileExists(Result) then break;
      end;
    end;
    
    public constructor(layer: BlockLayer; block_scale_pow: integer; pos00: PointPos);
    begin
      self.layer := layer;
      
      self.block_scale_pow := block_scale_pow;
      if block_scale_pow>Settings.max_block_scale_pow then
        raise new System.ArgumentOutOfRangeException;
      
      self.pos00 := pos00;
      
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public static function GetMetaWordCount(component_word_count: integer) := component_word_count*2;
    public static function GetDataWordCount(component_word_count: integer) := block_w.Sqr * (2 + component_word_count*2);
    public static function GetWordCount(component_word_count: integer) := GetMetaWordCount(component_word_count) + GetDataWordCount(component_word_count);
    public static function GetByteSize(component_word_count: integer) := GetWordCount(component_word_count) * sizeof(cardinal);
    public function GetByteSize := GetByteSize(self.pos00.Size);
    
    private static CLCodeCache := new System.Collections.Concurrent.ConcurrentDictionary<cardinal, CLProgramCode>;
    private static function CLCodeFor(word_c: cardinal) :=
      CLCodeCache.GetOrAdd(word_c, word_c->MandelbrotSampling.CompiledCode(word_c));
    
    public function CQ_DownGradeToRAM: CommandQueueNil;
    begin
      Result := CQNil;
      var l_vram_data := System.Threading.Interlocked.Exchange(self.vram_data, nil);
      if l_vram_data=nil then exit;
      
      vram_pos00.Dispose;
      vram_pos00 := nil;
      
      if ram_data<>nil then raise new System.InvalidOperationException;
      var l_ram_data := new cardinal[l_vram_data.Length];
      ram_data := l_ram_data;
      
      //TODO l_vram_data may still be used by the render thread
      // - Maybe, instead of disposing, add to some list that render thread can dispose at the end of frame
      //TODO #????: &<array of cardinal>
      Result += l_vram_data.MakeCCQ.ThenReadArray(HFQ&<array of cardinal>(()->l_ram_data, need_own_thread := false)) +
        HPQ(()->
        begin
          l_vram_data.Dispose;
          //TODO Протестить как теперь тратится память. Должно убрать скачёк при сохранении
          // - Нет, проблема ж вообще не в этом
          // - На самом деле все l_ram_data выделяются вместе, перед началом выполнения очереди
          // - Это очень фиговый дизайн получился...
          l_ram_data := nil;
        end, need_own_thread := false);
      
    end;
    public function CQ_DownGradeToDrive: CommandQueueNil;
    begin
      Result := CQ_DownGradeToRAM;
      
      var l_ram_data := System.Threading.Interlocked.Exchange(self.ram_data, nil);
      if l_ram_data=nil then exit;
      
      if drive_cache_file<>nil then raise new System.InvalidOperationException;
      var l_drive_cache_file := AllocDriveCacheFile;
      drive_cache_file := l_drive_cache_file;
      
      Result += HPQ(()->
      begin
        var need_del := true;
        var temp_fname := l_drive_cache_file + '.temp';
        var str := System.IO.File.Create(temp_fname);
        try
          var bw := new System.IO.BinaryWriter(str);
          
          bw.Write(drive_cache_format_version);
          bw.Write(self.block_scale_pow);
          bw.Write(self.pos00.Size);
          self.pos00.Save(bw);
          
          // Much faster than reading/writing one word at a time
          // But could be even faster, if stream directly accessed l_ram_data
          var bytes := new byte[l_ram_data.Length * sizeof(cardinal)];
          System.Buffer.BlockCopy(l_ram_data,0, bytes,0, bytes.Length);
          l_ram_data := nil;
          str.Write(bytes, 0, bytes.Length);
          
          need_del := false;
        finally
          str.Close;
          if need_del then
            DeleteFile(temp_fname);
        end;
        System.IO.File.Move(temp_fname, l_drive_cache_file);
      end, need_own_thread := false);
      
    end;
    
    public function CQ_UpGradeToRAM: CommandQueueNil;
    begin
      Result := CQNil;
      var l_drive_cache_file := System.Threading.Interlocked.Exchange(drive_cache_file, nil);
      if l_drive_cache_file=nil then exit;
      
      if ram_data<>nil then raise new System.InvalidOperationException;
      var l_ram_data := new cardinal[GetDataWordCount(self.pos00.Size)];
      ram_data := l_ram_data;
      
      Result += HPQ(()->
      begin
        var str := System.IO.File.OpenRead(l_drive_cache_file);
        try
          str.Position := 12 + GetMetaWordCount(self.pos00.Size)*sizeof(cardinal);
          
          var bytes := new byte[l_ram_data.Length * sizeof(cardinal)];
          var read_len := str.Read(bytes, 0, bytes.Length);
          if read_len<>bytes.Length then raise new System.InvalidOperationException;
          
          System.Buffer.BlockCopy(bytes,0, l_ram_data,0, bytes.Length);
        finally
          str.Close;
          DeleteFile(l_drive_cache_file);
        end;
      end, need_own_thread := false);
      
    end;
    public function CQ_UpGradeToVRAM: CommandQueueNil;
    begin
      Result := CQ_UpGradeToRAM;
      var l_ram_data := System.Threading.Interlocked.Exchange(self.ram_data, nil);
      // Init vram buffer even if there is no existing data
//      if l_ram_data=nil then exit;
//      if vram_data<>nil then raise new System.InvalidOperationException;
      // Instead, exit if vram is already inited
      if vram_data<>nil then exit;
      
      if vram_pos00<>nil then raise new System.InvalidOperationException;
      vram_pos00 := new CLArray<cardinal>(pos00.r.Words + pos00.i.Words, CLMemoryUsage.ReadOnly, CLMemoryUsage.None);
      
      var l_vram_data := new CLArray<cardinal>(GetDataWordCount(self.pos00.Size), CLMemoryUsage.ReadWrite, CLMemoryUsage.ReadWrite);
      vram_data := l_vram_data;
      
      Result += if l_ram_data=nil then
        l_vram_data.MakeCCQ.ThenFillValue(0).DiscardResult else
        l_vram_data.MakeCCQ.ThenWriteArray(l_ram_data).DiscardResult;
      
    end;
    
    public function CQ_MandelbrotBlockStep(Q_GetStepRepeatCount: CommandQueue<integer>; V_UpdateCount: CLValue<cardinal>; A_Err: CLArray<cardinal>): CommandQueueNil;
    begin
      Result := CQNil;
      if vram_data=nil then exit;
      
      Result := CLCodeFor(self.pos00.Size)['MandelbrotBlockSteps']
        .MakeCCQ.ThenExec2(block_w,block_w
          , vram_data
          , vram_pos00
          , Settings.z_int_bits-1 + -(self.block_scale_pow-Settings.block_w_pow)
          , Q_GetStepRepeatCount
          , V_UpdateCount
          , A_Err
        ).DiscardResult;
      
    end;
    
    public function CQ_GetData(A_Result: ShiftedCLArray<cardinal>; V_ExtractedCount: CLValue<cardinal>): CommandQueueNil;
    begin
      Result := CQNil;
      
      var l_vram_data := self.vram_data;
      if l_vram_data=nil then exit;
      
      Result += CLCodeFor(self.pos00.Size)['ExtractSteps']
        .MakeCCQ.ThenExec2(block_w,block_w
          , l_vram_data
          , A_Result.a, A_Result.shift, A_Result.row_len
          , V_ExtractedCount
        ).DiscardResult;
      
    end;
    
    public function ToString: string; override :=
      $'block at scale_pow={self.block_scale_pow}, pos={self.pos00}';
    
    public procedure Dispose;
    begin
      pos00 := default(PointPos);
      
      var l_vram_pos00 := System.Threading.Interlocked.Exchange(self.vram_pos00, nil);
      if l_vram_pos00<>nil then l_vram_pos00.Dispose;
      
      var l_vram_data := System.Threading.Interlocked.Exchange(self.vram_data, nil);
      if l_vram_data<>nil then l_vram_data.Dispose;
      
      ram_data := nil;
      
      var l_drive_cache_file := System.Threading.Interlocked.Exchange(self.drive_cache_file, nil);
      if l_drive_cache_file<>nil then DeleteFile(l_drive_cache_file);
      
      GC.SuppressFinalize(self);
    end;
    protected procedure Finalize; override := Dispose;
    
  end;
  
  BoundDefs<T> = record
    public xf, yf: T;
    public xl, yl: T;
    
    public function Convert<T2>(dx, dy: T->T2): BoundDefs<T2>;
    begin
      Result.xf := dx(self.xf); Result.yf := dy(self.yf);
      Result.xl := dx(self.xl); Result.yl := dy(self.yl);
    end;
    public function Convert<T2>(d: T->T2): BoundDefs<T2> := Convert(d,d);
    
    public function ToString: string; override :=
      $'{xf}<=x=>{xl} | {yf}<=y=>{yl}';
    
  end;
  BlockLayerSubArea = record
    private c_min, c_max: PointPos;
    private r_block_poss, i_block_poss: array of PointComponent;
    private layer: BlockLayer;
    
    /// Ordered by distance from the center
    public function MakeOrderedArr<T>(sel: PointPos->T): array of T;
    begin
      var rc := r_block_poss.Length;
      var ic := i_block_poss.Length;
      Result := new T[rc*ic];
      var keys := new int64[Result.Length];
      
      var ind := 0;
      for var i_ind := 0 to ic-1 do
        for var r_ind := 0 to rc-1 do
        begin
          Result[ind] := sel(new PointPos(r_block_poss[r_ind], i_block_poss[i_ind]));
          // Doesn't account for sheet_bound
          // But in practice it would hardly matter
          keys[ind] := Sqr(r_ind*2-rc) + Sqr(i_ind*2-ic);
          ind += 1;
        end;
      {$ifdef DEBUG}
      if ind<>Result.Length then
        raise new System.InvalidOperationException;
      {$endif DEBUG}
      
      System.Array.Sort(keys, Result);
    end;
    
  end;
  SheetDiff = record
    
    // All positive (or zero) if new sheet is fully inside old sheet
    // All negative (or zero) if old sheet is fully inside new sheet
    // Counted in terms of points of new sheet
    private bounds_diff: BoundDefs<integer>;
    
    // Positive if new sheet covers smaller scale than old sheet
    private scale_diff: integer;
    
    {$resource SheetTransfer.cl}
    private static sheet_transfer_code_text := System.IO.StreamReader.Create(
      System.Reflection.Assembly.GetCallingAssembly.GetManifestResourceStream('SheetTransfer.cl')
    ).ReadToEnd;
    private static sheet_transfer_code := new CLProgramCode(sheet_transfer_code_text);
    
    public function IsNoChange := (bounds_diff = default(BoundDefs<integer>)) and (scale_diff=0);
    
    public function CQ_CopySheet(old_sheet, new_sheet: CLArray<cardinal>; old_row_len, new_row_len, new_col_len: integer): CommandQueueNil;
    begin
      
      // Both count in points of new scale
      var old_bounds := self.bounds_diff.Convert(x->(+x).ClampBottom(0));
      var new_bounds := self.bounds_diff.Convert(x->(-x).ClampBottom(0));
      
      var scale_k := 1 shl Abs(scale_diff);
      
      // To continue counting everything in points of new sheet,
      // the scale_diff<0 should cause "old_row_len/scale_k", converting it to new points
      // But that will either loose precision, or require floating point (or both)
      // Same problem is old_shift is always in points of old sheet
      // So instead, if scale_diff<0, old_bounds is coverted to points of old sheet
//      var old_shift := old_row_len*old_bounds.yf*scale_k + old_bounds.xf * if scale_diff<0 then 1 else scale_k;
      var new_shift := new_row_len*new_bounds.yf + new_bounds.xf;
      
      var w := new_row_len - (new_bounds.xf+new_bounds.xl);
      var h := new_col_len - (new_bounds.yf+new_bounds.yl);
      
      if scale_diff<0 then
      begin
        var old_shift := (old_row_len*old_bounds.yf + old_bounds.xf)*scale_k;
        
        Result := sheet_transfer_code['DownScaleSheet'].MakeCCQ
          .ThenExec2(w,h
            , old_sheet, old_shift, old_row_len
            , new_sheet, new_shift, new_row_len
            , -scale_diff
          ).DiscardResult;
        
      end else
      if scale_diff=0 then
      begin
        var old_shift := old_row_len*old_bounds.yf + old_bounds.xf;
        
        Result := sheet_transfer_code['CopySheetRect'].MakeCCQ
          .ThenExec2(w,h
            , old_sheet, old_shift, old_row_len
            , new_sheet, new_shift, new_row_len
          ).DiscardResult;
        
      end else
      if scale_diff>0 then
      begin
        
        Result := sheet_transfer_code['UpScaleSheet'].MakeCCQ
          .ThenExec2(w,h
            , old_sheet, old_bounds.xf, old_bounds.yf, old_row_len
            , new_sheet, new_shift, new_row_len
            , +scale_diff
          ).DiscardResult;
        
      end else
        raise new System.InvalidOperationException;
      
    end;
    
  end;
  BlockLayerRenderInfo = record
    
    // How much of viewport is empty
    // (between screen edge and the sheet)
    // [0;2) and first+last<=2
    public view_bound: BoundDefs<single>;
    
    // How much of edge blocks is hidden by window edge
    // [0;1) and first+last<=1
    public sheet_bound: BoundDefs<single>;
    
    // All coordinates of (partially or fully) visible blocks
    public block_area: BlockLayerSubArea;
    
    // Info needed to render
    public last_sheet_diff: SheetDiff?;
    
    private block_sz_bit_ind: integer;
  end;
  
  // Слой, содержащий кэш уже просчитанных блоков
  BlockLayer = sealed class
    private scale_pow: integer;
    
    private blocks := new Dictionary<PointPos, PointBlock>;
    
    public constructor(scale_pow: integer) := self.scale_pow := scale_pow;
    private constructor := raise new System.InvalidOperationException;
    
    private static all_layers := new List<BlockLayer>;
    public static function GetLayer(block_scale_pow: integer): BlockLayer;
    begin
      var layer_ind := Settings.max_block_scale_pow - block_scale_pow;
      while all_layers.Count<=layer_ind do
        all_layers += default(BlockLayer);
      Result := all_layers[layer_ind];
      if Result<>nil then exit;
      
      Result := new BlockLayer(block_scale_pow);
      all_layers[layer_ind] := Result;
    end;
    public static function GetLayer(camera_pos: CameraPos) :=
      GetLayer(camera_pos.GetPointScalePow + Settings.block_w_pow);
    
    private function GetBlockAt(pos00: PointPos; can_create: boolean): PointBlock;
    begin
      if self.blocks.TryGetValue(pos00, Result) then exit;
      if not can_create then exit;
      Result := new PointBlock(self, self.scale_pow, pos00);
      self.blocks.Add(pos00, Result);
    end;
    public function GetRenderInfo(camera_pos: CameraPos; last_ri: BlockLayerRenderInfo?): BlockLayerRenderInfo;
    begin
      Result := default(BlockLayerRenderInfo);
      
      {$ifdef DEBUG}
      if self.scale_pow <> camera_pos.GetPointScalePow + Settings.block_w_pow then
        raise new System.InvalidOperationException;
      {$endif DEBUG}
      
      var word_count := camera_pos.pos.Size;
      var c_ctr := camera_pos.pos;
      
      begin
        var cx := c_ctr.r.FirstWordToReal;
        var cy := c_ctr.i.FirstWordToReal;
        var ar := camera_pos.AspectRatio;
        
        var visible_space_dy := camera_pos.scale_fine * 2.0**camera_pos.scale_pow;
        var visible_space_dx := visible_space_dy * ar;
        
        // Whole logical space is -2 .. +2
        // Visible logical space is c_ctr-visible_space_d .. c_ctr+visible_space_d
        
        Result.view_bound.xf := (-2-(cx-visible_space_dx)).ClampBottom(0) / visible_space_dx;
        Result.view_bound.xl := ((cx+visible_space_dx)-2).ClampBottom(0) / visible_space_dx;
        
        Result.view_bound.yf := (-2-(cy-visible_space_dy)).ClampBottom(0) / visible_space_dy;
        Result.view_bound.yl := ((cy+visible_space_dy)-2).ClampBottom(0) / visible_space_dy;
        
      end;
      
      var dr := new PointComponentShift(word_count, camera_pos.scale_pow, camera_pos.scale_fine * camera_pos.AspectRatio);
      var di := new PointComponentShift(word_count, camera_pos.scale_pow, camera_pos.scale_fine);
      Result.block_area.c_min := c_ctr.WithShiftClamp2(-dr,-di, false);
      Result.block_area.c_max := c_ctr.WithShiftClamp2(+dr,+di, true);
      
      Result.block_sz_bit_ind := Settings.z_int_bits-1 + -self.scale_pow;
      Result.block_area.c_min.SelfBlockRound(Result.block_sz_bit_ind, false, Result.sheet_bound.xf, Result.sheet_bound.yf);
      Result.block_area.c_max.SelfBlockRound(Result.block_sz_bit_ind, true,  Result.sheet_bound.xl, Result.sheet_bound.yl);
      
      Result.block_area.r_block_poss := PointComponent.Range(Result.block_area.c_min.r, Result.block_area.c_max.r, Result.block_sz_bit_ind);
      Result.block_area.i_block_poss := PointComponent.Range(Result.block_area.c_min.i, Result.block_area.c_max.i, Result.block_sz_bit_ind);
      Result.block_area.layer := self;
      
      var kx: single := 1/Result.block_area.r_block_poss.Length;
      var ky: single := 1/Result.block_area.i_block_poss.Length;
      Result.sheet_bound := Result.sheet_bound.Convert(x->x*kx, y->y*ky);
      
      if last_ri<>nil then
      try
        var last_ri_v := last_ri.Value;
        var last_sheet_diff: SheetDiff;
        
        last_sheet_diff.scale_diff := Result.block_sz_bit_ind - last_ri_v.block_sz_bit_ind;
        if Abs(last_sheet_diff.scale_diff)>16 then
          // Handling such jump in scale would require
          // increasing precision in SheetDiff.CQ_CopySheet
          // But it's not worth it, just recalculate the sheet
          raise new System.OverflowException;
        
        var point_sz_bit_ind := Result.block_sz_bit_ind + Settings.block_w_pow;
        last_sheet_diff.bounds_diff.xf := +PointComponent.BlocksCount(last_ri_v.block_area.c_min.r.WithBlockRound(point_sz_bit_ind, false), Result.block_area.c_min.r, point_sz_bit_ind);
        last_sheet_diff.bounds_diff.yf := +PointComponent.BlocksCount(last_ri_v.block_area.c_min.i.WithBlockRound(point_sz_bit_ind, false), Result.block_area.c_min.i, point_sz_bit_ind);
        last_sheet_diff.bounds_diff.xl := -PointComponent.BlocksCount(last_ri_v.block_area.c_max.r.WithBlockRound(point_sz_bit_ind, false), Result.block_area.c_max.r, point_sz_bit_ind);
        last_sheet_diff.bounds_diff.yl := -PointComponent.BlocksCount(last_ri_v.block_area.c_max.i.WithBlockRound(point_sz_bit_ind, false), Result.block_area.c_max.i, point_sz_bit_ind);
        
        Result.last_sheet_diff := last_sheet_diff;
//        if not last_sheet_diff.IsNoChange then
//        begin
//          Println($'{c_min} .. {c_max}');
//          Println($'{Result.block_area.r_block_poss.Length} x {Result.block_area.i_block_poss.Length}');
//          Println(last_sheet_diff.bounds_diff);
//        end;
      except
        on e: System.OverflowException do ;
      end;
      
    end;
    
  end;
  
  //TODO Вытащить код для вывода KB и т.п.
//  // VRAM/RAM/Drive
//  MemoryLayer = sealed class
//    private blocks := new List<PointBlock>;
//    private new_blocks := new List<PointBlock>;
//    private layer_name: string;
//    private max_size: int64;
//    private get_curr_size: ()->int64;
//    private next := default(MemoryLayer);
//    
//    public constructor(layer_name: string; max_size: int64; get_curr_size: ()->int64);
//    begin
//      self.layer_name := layer_name;
//      self.max_size := max_size;
//      self.get_curr_size := get_curr_size;
//    end;
//    private constructor := raise new System.InvalidOperationException;
//    
////    public procedure Flush;
////    begin
////      blocks.AddRange(new_blocks);
////      new_blocks.Clear;
////    end;
////    public procedure FlushAll := Enmr.ForEach(l->l.Flush);
//    
//    public function MemoryInfoStr: string;
//    begin
//      var c1 := real(get_curr_size());
//      var c2 := real(max_size);
//      
//      var pow := 0;
//      var pow_step := 1024;
//      var pow_names := |'KB','MB','GB'|;
//      while (c1>=pow_step) or (c2>=pow_step) do
//      begin
//        if pow=pow_names.Length then break;
//        pow += 1;
//        c1 /= pow_step;
//        c2 /= pow_step;
//      end;
//      
//      var pow_name := if pow=0 then nil else ' '+pow_names[pow];
//      Result := $'{layer_name}: {c1}/{c2}{pow_name} ({c1/c2:000.00%})';
//    end;
//    public function Enmr: sequence of MemoryLayer;
//    begin
//      var curr := self;
//      repeat
//        yield curr;
//        curr := curr.next;
//      until curr=nil;
//    end;
//    
//    
//    
//  end;
  
  VRAM_MemoryLayer = sealed class(MemoryLayer<PointBlock>)
    
    public constructor := inherited Create('VRAM', Settings.max_VRAM);
    
    protected function GetRealFilledSize: int64; override := CLMemoryObserver.Current.CurrentlyUsedAmount;
    
  end;
  
  RAM_MemoryLayer = sealed class(MemoryLayer<PointBlock>)
    
    public constructor := inherited Create('RAM', Settings.max_RAM);
    
    protected function GetRealFilledSize: int64; override := GC.GetTotalMemory(true);
    
  end;
  
  Drive_MemoryLayer = sealed class(MemoryLayer<PointBlock>)
    
    public constructor;
    begin
      inherited Create('Drive', Settings.max_drive_space);
      
      var cache_dir := System.IO.Directory.CreateDirectory(PointBlock.drive_cache_dir_name);
      
      var filled_size := int64(0);
      foreach var fi in cache_dir.EnumerateFiles($'*.{PointBlock.drive_cache_ext_name}').OrderByDescending(fi->fi.LastWriteTimeUtc) do
      begin
        try
          var str := fi.OpenRead;
          try
            var br := new System.IO.BinaryReader(str);
            var version := br.ReadInt32;
            var scale := br.ReadInt32;
            var word_count := br.ReadInt32;
            var pos00 := PointPos.Load(br, word_count);
            if version<>PointBlock.drive_cache_format_version then
              raise new Exception('Unsupported cache format');
            var expected_len := str.Position + PointBlock.GetDataWordCount(word_count)*sizeof(cardinal);
            var actual_len := str.Length;
            if expected_len <> actual_len then
              raise new Exception($'Bad cache file size: {expected_len} vs {actual_len}');
            var layer := BlockLayer.GetLayer(scale);
            var bl := new PointBlock(layer, scale, pos00);
            bl.drive_cache_file := fi.FullName;
            self.TryAdd(bl, bl->raise new Exception($'Not enough allocated disk space to load all the cache'));
            layer.blocks.Add(pos00, bl);
            filled_size += actual_len;
          finally
            str.Close;
          end;
        except
          on e: Exception do
          begin
            $'Failed to load cached block: {fi.FullName}'.Println;
            Println(e);
            fi.Delete;
          end;
        end;
      end;
      
      self.EndUpdate; // Flush newly added blocks
      if filled_size + System.IO.DriveInfo.Create(GetCurrentDir).TotalFreeSpace < Settings.max_drive_space then
        raise new System.InvalidOperationException('No enough disk space');
      
    end;
    
    protected function GetRealFilledSize: int64; override :=
      System.IO.Directory.CreateDirectory(PointBlock.drive_cache_dir_name)
      .EnumerateFiles($'*.{PointBlock.drive_cache_ext_name}').Select(fi->fi.Length).Sum;
    
  end;
  
  // Цикл обработки видимых блоков
  BlockUpdater = static class
    
    private static procedure ExceptionToConsole(e: Exception) := Println(e);
    private static current_ex_handler := ExceptionToConsole;
    public static procedure SetExHandler(h: Exception->()) := current_ex_handler := h;
    
    private static current_area := default(System.Tuple<BlockLayerSubArea>);
    public static procedure SetCurrent(area: BlockLayerSubArea) := current_area := Tuple.Create(area);
    
    private static lacking_vram := true;
    public static property LackingVRAM: boolean read lacking_vram;
    
    private static step_info_str := default(string);
    public static property StepInfoStr: string read step_info_str;
    
    private static shutdown_progress: (integer,integer) := nil;
    private static on_shutdown_done: Action0 := nil;
    public static property ShutdownProgress: (integer,integer) read shutdown_progress;
    public static procedure BeginShutdown(on_shutdown_done: Action0);
    begin
      shutdown_progress := (0,1);
      BlockUpdater.on_shutdown_done += on_shutdown_done;
    end;
    
    private static function MatrItemsSortedFromCenter<T>(m: array[,] of T): array of T;
    begin
      Result := new T[m.Length];
      var keys := new integer[Result.Length];
      
      var res_i := 0;
      var (c1,c2) := m.Size;
      for var i1 := 0 to c1-1 do
        for var i2 := 0 to c2-1 do
        begin
          Result[res_i] := m[i1,i2];
          keys[res_i] := Sqr(i1*2 - c1) + Sqr(i2*2 - c2);
          res_i += 1;
        end;
      
      System.Array.Sort(keys, Result);
    end;
    
    static constructor := System.Threading.Thread.Create(()->
    begin
      
      var P_StepCount := new ParameterQueue<integer>('step_count');
      var V_UpdateCount := new CLValue<cardinal>(0);
      var A_Err := new CLArray<cardinal>(3);
      var err := new cardinal[3];
      
      var last_blocks := new HashSet<PointBlock>;
      var Q_StepAll: CommandQueue<cardinal>;
      
      var step_sw := new Stopwatch;
      var step_count := 1;
      
      var ml_vram := new VRAM_MemoryLayer;
      var ml_ram := new RAM_MemoryLayer;
      var ml_drive := new Drive_MemoryLayer;
      
      var all_mem_layers := new MemoryLayer<PointBlock>[](
        ml_vram, ml_ram, ml_drive
      );
      
      while true do
      try
        if shutdown_progress<>nil then
        begin
          
          var unloadable_blocks := new List<PointBlock>;
          var add_to_unload := procedure(ml: MemoryLayer<PointBlock>)->
          begin
            foreach var bl in ml.Enmr.Reverse do
              if ml_drive.TryAdd(bl, bl->bl.Dispose()) then
                unloadable_blocks += bl;
            ml_drive.EndUpdate;
          end;
          add_to_unload( ml_ram);
          add_to_unload(ml_vram);
          
          (ml_ram.Enmr+ml_vram.Enmr).ToArray;
          foreach var bl in unloadable_blocks do
            ml_drive.TryAdd(bl, bl->bl.Dispose());
          
          var Q_ShutDown := CQNil;
          foreach var bl in unloadable_blocks index bl_ind do
          begin
            Q_ShutDown += bl.CQ_DownGradeToDrive;
            var shutdown_ind := bl_ind+1;
            Q_ShutDown += HPQ(()->(shutdown_progress := (shutdown_ind,unloadable_blocks.Count)), need_own_thread := false);
          end;
          CLContext.Default.SyncInvoke(Q_ShutDown);
          
          var on_shutdown_done := on_shutdown_done;
          if on_shutdown_done<>nil then on_shutdown_done();
          break;
        end;
        
        var area: BlockLayerSubArea;
        begin
          var area_t := current_area;
          if area_t=nil then
          begin
            Sleep(1);
            continue;
          end;
          area := area_t.Item1;
        end;
        
        var req_blocks := area.MakeOrderedArr(pos00->area.layer.GetBlockAt(pos00, true));
        if req_blocks.Length=0 then raise new System.NotImplementedException($'0 block area');
        
        var block_new_table := new Dictionary<PointBlock, boolean>(area.r_block_poss.Length * area.i_block_poss.Length);
        foreach var bl in req_blocks do block_new_table.Add(bl, true);
        foreach var ml in all_mem_layers do
          ml.BeginUpdate(block_new_table);
        
        foreach var bl in req_blocks do
          ml_vram.TryAdd(bl, bl->
            ml_ram.TryAdd(bl, bl->
              ml_drive.TryAdd(bl, bl->
              begin
                if not bl.layer.blocks.Remove(bl.pos00) then
                begin
                  $'Could not delete {bl}'.Println;
                  $'Current blocks:'.Println;
                  foreach var curr_bl in req_blocks do
                    $'{curr_bl}'.Println;
                  Println('='*50);
                end;
                bl.Dispose;
              end)
            )
          );
        
        foreach var ml in all_mem_layers do
          ml.EndUpdate;
        
        lacking_vram := ml_vram.Enmr.Take(req_blocks.Length).Count <> req_blocks.Length;
        
        begin
          var Q_Init := CQNil;
          
          foreach var bl in ml_drive.Enmr do Q_Init += bl.CQ_DownGradeToDrive;
          foreach var bl in ml_ram.Enmr do Q_Init += bl.CQ_DownGradeToRAM;
          
          foreach var bl in ml_ram.Enmr do Q_Init += bl.CQ_UpGradeToRAM;
          foreach var bl in ml_vram.Enmr do Q_Init += bl.CQ_UpGradeToVRAM;
          
//          var init_sw := Stopwatch.StartNew;
          CLContext.Default.SyncInvoke(Q_Init);
//          $'Inited in {init_sw.Elapsed}'.Println;
        end;
        
        var update_blocks := req_blocks.Intersect(ml_vram.Enmr).ToArray;
        if not last_blocks.SetEquals(update_blocks) then
        begin
          last_blocks.Clear;
          last_blocks.UnionWith(update_blocks);
          
          // After blocks have changed, the update might take far longer
          // Reset step count to avoid sudden horrible lag
          step_count := 1;
          
          var branches := ArrFill(Settings.max_parallel_blocks, CQNil);
          foreach var bl in update_blocks index bl_i do
            branches[bl_i mod branches.Length] += bl.CQ_MandelbrotBlockStep(P_StepCount, V_UpdateCount, A_Err);
          
          Q_StepAll :=
            V_UpdateCount.MakeCCQ.ThenWriteValue(0) +
            A_Err.MakeCCQ.ThenFillValue(0) +
            CombineAsyncQueue(branches) +
            A_Err.MakeCCQ.ThenReadArray(err) +
            V_UpdateCount.MakeCCQ.ThenGetValue;
          
        end;
        
        {$ifdef DEBUG}
        //TODO BlockLayer.all_layers использует из нескольких потоков, надо его блокировать...
        var blocks_by_scale := BlockLayer.all_layers.Where(l->l<>nil).SelectMany(l->l.blocks.Values).ToArray;
        var blocks_by_memory := all_mem_layers.SelectMany(l->l.Enmr).ToArray;
        if not blocks_by_scale.ToHashSet.SetEquals(blocks_by_memory) then
          raise new System.InvalidOperationException;
        {$endif DEBUG}
        
        step_sw.Restart;
        var update_count := CLContext.Default.SyncInvoke(Q_StepAll
          , P_StepCount.NewSetter(step_count)
        );
        step_sw.Stop;
        
        step_info_str := $'u={update_count/step_count:N0}/step, {step_count} steps in {step_sw.Elapsed.TotalSeconds:N3}s';
        
        // Тут бы PID контроллер реализовать вообще, потому что
        // зависимость времени от кол-ва шагов не линейная
        // Но на практике этого достаточно...
        step_count := (step_count * Settings.target_step_time_seconds/step_sw.Elapsed.TotalSeconds).Clamp(1,max_steps_at_once).Round;
        
        if err[0]<>0 then
          // Надо бы выводить какой-то id блока тоже...
          // - Достаточно [x,y] индекс. Тут из него можно получить все данные блока
          // - Но пока что ошибок на стороне .cl кода (после FieldTest) вообще не видел. Слишком хорошо написал?
          raise new Exception($'Step err {CLCodeExecutionError(err[0])} at [{err[1]},{err[2]}]');
        
      except
        on e: Exception do
          current_ex_handler(e);
      end;
      
    end).Start;
    
  end;
  
// For FieldTest, to go around the inconsistent BlockUpdater
procedure InitAllBlocks(self: BlockLayerSubArea); extensionmethod;
begin
  var rc := self.r_block_poss.Length;
  var ic := self.i_block_poss.Length;
  for var i_ind := 0 to ic-1 do
    for var r_ind := 0 to rc-1 do
      self.layer.GetBlockAt(new PointPos(
        self.r_block_poss[r_ind], self.i_block_poss[i_ind]
      ), true);
end;

function MakeInitedBlocksMatr(self: BlockLayerSubArea): array[,] of PointBlock; extensionmethod;
begin
  var rc := self.r_block_poss.Length;
  var ic := self.i_block_poss.Length;
  Result := new PointBlock[ic, rc];
  for var i_ind := 0 to ic-1 do
    for var r_ind := 0 to rc-1 do
      // Cannot create blocks here, because they
      // would not be marked by memory layers
      // Instead BlockUpdater manages all creation and initing
      Result[i_ind, r_ind] := self.layer.GetBlockAt(new PointPos(
        self.r_block_poss[r_ind], self.i_block_poss[i_ind]
      ), false);
end;

end.