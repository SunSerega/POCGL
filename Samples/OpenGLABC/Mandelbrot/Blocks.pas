unit Blocks;

{$savepcu false} //TODO

uses OpenCLABC;

uses Settings;
uses PointComponents;
uses CameraDef;
uses MandelbrotSampling;

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
  
  // Блок из block_w*block_w точек 
  PointBlock = sealed class
    
    // Принимает значения -∞..1
    // Длина стороны блока в логическом пространстве = 2**block_scale
    private block_scale: integer;
    private component_word_count: integer;
    private pos00: CLArray<cardinal>;
    
    private gpu_data: CLArray<cardinal>;
    private gpu_mipmaps_state: CLArray<byte>;
    private gpu_mipmaps_steps: CLArray<cardinal>;
    private gpu_mipmaps_need_update: CLArray<byte>;
    
    private ram_data: array of byte;
    
    public constructor(block_scale: integer; pos00: PointPos);
    begin
      self.block_scale := block_scale;
      if block_scale>=2 then
        raise new System.ArgumentOutOfRangeException;
      
      self.component_word_count := pos00.Size;
      //TODO Track GPU memory used amount
      self.pos00 := new CLArray<cardinal>(pos00.r.Words+pos00.i.Words, CLMemoryUsage.ReadOnly, CLMemoryUsage.None);
      
      self.gpu_data := new CLArray<cardinal>( block_w*block_w * (2 + component_word_count*2) );
      self.gpu_mipmaps_state := new CLArray<byte>(mipmap_total_size);
      self.gpu_mipmaps_steps := new CLArray<cardinal>(mipmap_total_size);
      self.gpu_mipmaps_need_update := new CLArray<byte>(mipmap_total_size);
      
      //TODO Снять с этого потока выполнения...
      CLContext.Default.SyncInvoke(
        self.gpu_data.MakeCCQ.ThenFillValue(0) +
        self.gpu_mipmaps_state.MakeCCQ.ThenFillValue(0) +
        self.gpu_mipmaps_steps.MakeCCQ.ThenFillValue(0) +
        self.gpu_mipmaps_need_update.MakeCCQ.ThenFillValue(0)
      );
      
    end;
    private constructor := raise new System.InvalidOperationException;
    
    private static CLCodeCache := new System.Collections.Concurrent.ConcurrentDictionary<cardinal, CLProgramCode>;
    private static function CLCodeFor(word_c: cardinal) :=
      CLCodeCache.GetOrAdd(word_c, word_c->MandelbrotSampling.CompiledCode(word_c));
    public function CQ_MandelbrotBlockStep(step_repeat_count: CommandQueue<integer>; V_UpdateCount: CLValue<cardinal>; A_Err: CLArray<cardinal>): CommandQueueNil :=
      CLCodeFor(self.component_word_count)['MandelbrotBlockSteps']
      .MakeCCQ.ThenExec2(block_w,block_w
        , self.gpu_data
        , self.pos00
        , Settings.z_int_bits-1 + -(self.block_scale-Settings.block_w_pow)
        , self.gpu_mipmaps_need_update
        , step_repeat_count
        , V_UpdateCount
        , A_Err
      ).DiscardResult;
    
    public function CQ_GetData(target_mipmap_lvl: integer; A_State: ShiftedCLArray<byte>; A_Steps: ShiftedCLArray<cardinal>): CommandQueueNil;
    begin
      
      {$ifdef DEBUG}
      if target_mipmap_lvl < -scale_shift then
        raise new System.InvalidOperationException;
      if target_mipmap_lvl > block_w_pow then
        raise new System.InvalidOperationException;
      {$endif DEBUG}
      
      var code := CLCodeFor(self.component_word_count);
      var w := block_w;
      
      if target_mipmap_lvl=0 then
      begin
        Result := code['ExtractRawSteps'].MakeCCQ.ThenExec2(w,w
          , self.gpu_data
          , A_State.a, A_State.shift, A_State.row_len
          , A_Steps.a, A_Steps.shift, A_Steps.row_len
        ).DiscardResult;
        exit;
      end;
      
      w := w shr 1;
      Result := code['FixFirstMipMap'].MakeCCQ.ThenExec2(w,w
        , self.gpu_data
        , self.gpu_mipmaps_state
        , self.gpu_mipmaps_steps
        , self.gpu_mipmaps_need_update
      ).DiscardResult;
      var mipmap_shift := w*w;
      
      for var mipmap_lvl := 2 to target_mipmap_lvl do
      begin
        w := w shr 1;
        Result += code['FixMipMap'].MakeCCQ.ThenExec2(w,w
          , self.gpu_mipmaps_state
          , self.gpu_mipmaps_steps
          , self.gpu_mipmaps_need_update
          , cardinal(mipmap_shift)
          , cardinal(mipmap_lvl)
        ).DiscardResult;
        mipmap_shift += w*w;
      end;
      
      Result += code['ExtractMipMapSteps'].MakeCCQ.ThenExec2(w,w
        , self.gpu_mipmaps_state, self.gpu_mipmaps_steps, cardinal(mipmap_shift - w*w)
        , A_State.a, A_State.shift, A_State.row_len
        , A_Steps.a, A_Steps.shift, A_Steps.row_len
        , cardinal(target_mipmap_lvl)
      ).DiscardResult;
      
    end;
    
  end;
  
  BoundDefs = record
    public xf, yf: single;
    public xl, yl: single;
    
    public static procedure operator*=(var b: BoundDefs; k: System.ValueTuple<single,single>);
    begin
      var (kx,ky) := k;
      b.xf *= kx; b.yf *= ky;
      b.xl *= kx; b.yl *= ky;
    end;
    public static procedure operator/=(var b: BoundDefs; k: System.ValueTuple<single,single>) :=
      b *= System.ValueTuple.Create(1/k.Item1, 1/k.Item2);
    
  end;
  BlockLayerRenderInfo = record
    public blocks: array[,] of PointBlock; // [y,x]
    public mipmap_lvl: integer;
    
    // How much of viewport is empty
    // [0;2) and first+last<=2
    public view_bound: BoundDefs;
    
    // How much of edge blocks is hidden
    // [0;1) and first+last<=1
    public sheet_bound: BoundDefs;
    
  end;
  
  // Слой, содержащий кэш уже просчитанных блоков
  BlockLayer = sealed class
    private scale: integer;
    
    private blocks := new Dictionary<PointPos, PointBlock>;
    
    public constructor(scale: integer);
    begin
      self.scale := scale;
      
    end;
    private constructor := raise new System.InvalidOperationException;
    
//    private static all_layers := new BlockLayer[1+max_z_scale_bits_rounded];
//    private static function scale_to_layer_ind(scale: integer) := 1-scale;
//    
//    public static function TakeBlocks(scale: integer; dx, dy: cardinal): List<PointBlock>;
//    begin
//      var layer_ind := scale_to_layer_ind(scale).Clamp(0, all_layers.Length-1);
//      scale := 1-layer_ind;
//      
//      
//    end;
//    
//    public static procedure Cleanup;
//    begin
//      var TODO := 0; // Вообще вместо этого надо чистить когда заканчивается место
//    end;
    
    //TODO Сейчас блоки создаёт с 0 при каждом вызове. Использовать экземпляр типа BlockLayer
    public static function BlocksForCurrentScale(camera_pos: CameraPos): BlockLayerRenderInfo;
    begin
      Result := default(BlockLayerRenderInfo);
      
      var word_count := camera_pos.pos.Size;
      var c_ctr := camera_pos.pos;
      
      //TODO Таким макаром view_size_bit_ind может быть <0, не говоря уже о переполнении сложения .AddLowestBits
      // Если сильно отдалить камеру - значения границ не поместятся в c_min/c_max
      // - Можно сразу складывать, округлять и ограничивать, всё в 1 операцию
      // --- Но это будет 1 очень большая и сложная подпрограмма
      // - Можно ограничивать отдельно вывод RoundToLowestBits и т.п.
      // --- Но тогда границы блоков неправильно поставит относительно границ экрана
      // - Можно ограничивать камеру
      // --- Но обработать PointComponent границы вместе с fine+pow масштабом будет сложно...
      // --- И очень широкое окно всё равно переполнит PointComponent
      // - Можно использовать отдельный алгоритм для границ, в зависимости от того - нужна ли точность PointComponent
      // --- Но это дубли кода, сложная проверка какой алгоритм выбрать и возможность дёрганья камеры при переходе от 1 алгоритма к другому
      // - Можно менять область рендеринга если камера слишком отдалена, а внутри неё всё равно использовать обычный алгоритм с PointComponent
      // --- Но тогда на каждый пиксель придётся очень много точек
      //TODO В итоге решил ограничить .pos, чтобы оно за [-2;+2] не выходило
      // - Тогда достаточно таки view_skip при большом отдалении делать, и больше ничего
      if camera_pos.scale_pow>=1 then
      begin
        if c_ctr.Size<>1 then raise new System.NotImplementedException;
        var cx := c_ctr.r.FirstWordToReal;
        var cy := c_ctr.i.FirstWordToReal;
        
        //TODO Масштабировать cx и cy, привести их к диапазону -1..+1
        
      end;
      
      var view_size_bit_ind := Settings.z_int_bits-1 - camera_pos.scale_pow;
      var di := PointComponent.RoundToLowestBits(word_count, view_size_bit_ind, camera_pos.scale_fine);
      var dr := PointComponent.RoundToLowestBits(word_count, view_size_bit_ind, camera_pos.scale_fine * camera_pos.AspectRatio);
      var c_min := c_ctr.AddLowestBits(-dr,-di);
      var c_max := c_ctr.AddLowestBits(+dr,+di);
      c_max.SelfFlipIfMinusZero;
      
      var (block_scale, main_mipmap_lvl) := camera_pos.GetPointScaleAndMainMipMapLvl;
      block_scale += Settings.block_w_pow;
      Result.mipmap_lvl := main_mipmap_lvl;
      var block_sz_bit_ind := Settings.z_int_bits-1 + -block_scale;
      c_min.SelfBlockRound(block_sz_bit_ind, false, Result.sheet_bound.xf, Result.sheet_bound.yf);
      c_max.SelfBlockRound(block_sz_bit_ind, true,  Result.sheet_bound.xl, Result.sheet_bound.yl);
      //TODO Debug error for when bounds are >2
      
      var r_blocks_count := PointComponent.BlocksCount(c_min.r, c_max.r, block_sz_bit_ind);
      var i_blocks_count := PointComponent.BlocksCount(c_min.i, c_max.i, block_sz_bit_ind);
      
      Result.sheet_bound /= new System.ValueTuple<single,single>(r_blocks_count, i_blocks_count);
      
      var pc_rs := new PointComponent[r_blocks_count];
      begin
        var pc_r := c_min.r;
        for var ri := 0 to r_blocks_count-1 do
        begin
          pc_rs[ri] := pc_r;
          pc_r := pc_r.MakeNextBlockBound(block_sz_bit_ind);
        end;
        {$ifdef DEBUG}
        if pc_r<>c_max.r then
          raise new System.InvalidOperationException;
        {$endif DEBUG}
      end;
      
      Result.blocks := new PointBlock[i_blocks_count, r_blocks_count];
//      $'Need {i_blocks_count} x {r_blocks_count} = {Result.blocks.Length} blocks'.Println; Halt;
      begin
        var pc_i := c_min.i;
        for var ii := 0 to i_blocks_count-1 do
        begin
          for var ri := 0 to r_blocks_count-1 do
            Result.blocks[ii, ri] := new PointBlock(block_scale, new PointPos(pc_rs[ri], pc_i));
          pc_i := pc_i.MakeNextBlockBound(block_sz_bit_ind);
        end;
        {$ifdef DEBUG}
        if pc_i<>c_max.i then
          raise new System.InvalidOperationException;
        {$endif DEBUG}
      end;
      
    end;
    
  end;
  
  BlockUpdater = static class
    private static output_update_info := false;
    
    private static procedure ExceptionToConsole(e: Exception) := Println(e);
    private static current_ex_handler := ExceptionToConsole;
    public static procedure SetExHandler(h: Exception->()) := current_ex_handler := h;
    
    private static current_blocks: array[,] of PointBlock;
    public static procedure SetCurrent(a: array[,] of PointBlock) := current_blocks := a;
    
    static constructor := System.Threading.Thread.Create(()->
    begin
      
      var P_StepCount := new ParameterQueue<integer>('step_count');
      var V_UpdateCount := new CLValue<cardinal>(0);
      var A_Err := new CLArray<cardinal>(3);
      var err := new cardinal[3];
      
      var last_blocks: array[,] of PointBlock := nil;
      var Q_StepAll: CommandQueue<cardinal>;
      
      var sw := new Stopwatch;
      var step_count := 1;
      
      while true do
      try
        
        var blocks := current_blocks;
        if blocks=nil then
        begin
          Sleep(1);
          continue;
        end;
        
        if blocks<>last_blocks then
        begin
          var branches := ArrFill(Settings.max_parallel_blocks, CQNil);
          foreach var b: PointBlock in blocks index b_i do
            branches[b_i mod branches.Length] += b.CQ_MandelbrotBlockStep(P_StepCount, V_UpdateCount, A_Err);
          last_blocks := blocks;
          Q_StepAll :=
            V_UpdateCount.MakeCCQ.ThenWriteValue(0) +
            A_Err.MakeCCQ.ThenFillValue(0) +
            CombineAsyncQueue(branches) +
            A_Err.MakeCCQ.ThenReadArray(err) +
            V_UpdateCount.MakeCCQ.ThenGetValue
        end;
        
        sw.Restart;
        var update_count := CLContext.Default.SyncInvoke(Q_StepAll
          , P_StepCount.NewSetter(step_count)
        );
        sw.Stop;
        
        if output_update_info then
        begin
          $'Updated {update_count} points'.Println;
          $'Updated current {blocks.Length} blocks {step_count} times in {sw.Elapsed}'.Println;
          Println('='*30);
        end;
        
        // Тут бы PID контроллер реализовать вообще, потому что
        // зависимость времени от кол-ва шагов не линейная
        // Но пока и так работает...
        step_count := (step_count * Settings.target_step_time_seconds/sw.Elapsed.TotalSeconds).Clamp(1,max_steps_at_once).Round;
        
        if err[0]<>0 then
          //TODO Надо бы выводить какой-то id блока тоже...
          // - Достаточно [x,y] индекс. Тут из него можно получить все данные блока
          raise new Exception($'Step err {CLCodeExecutionError(err[0])} at [{err[1]},{err[2]}]');
        
      except
        on e: Exception do
          current_ex_handler(e);
      end;
      
    end).Start;
    
  end;
  
end.