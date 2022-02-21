unit RNNData;

uses OpenCLABC;

type
  AI = class
    
    {$region field's}
    
    private sz_hl: integer;
    private sz_ol: integer;
    
    public property hlSZ: integer read sz_hl;
    public property olSZ: integer read sz_ol;
    
    private matr_hth: KernelArg; // hidden to hidden
    private matr_hto: KernelArg; // hidden to output
    
    private const FirstFill: (FFT_Zeroes, FFT_Ones, FFT_Rng) = FFT_Zeroes;
    
    private static prog := new ProgramCode(Context.Default,ReadAllText('RNN progs.cl'));
    
    {$endregion field's}
    
    {$region init}
    
    private constructor := exit;
    
    public constructor(ol_sz: integer; hl_sz: integer);
    begin
      self.sz_ol := ol_sz;
      self.sz_hl := hl_sz;
      
      matr_hth := new KernelArg( hl_sz*hl_sz * 4 );
      matr_hto := new KernelArg( hl_sz*ol_sz * 4 );
      
      case FirstFill of
        
        FFT_Zeroes, FFT_Ones:
        begin
          var pattern: single := integer(FirstFill=FFT_Ones);
          
          Context.Default.SyncInvoke((
            (matr_hth.NewQueue.PatternFill(pattern) as CommandQueue<KernelArg>) *
            (matr_hto.NewQueue.PatternFill(pattern) as CommandQueue<KernelArg>)
          ) as CommandQueue<KernelArg>);
          
        end;
        
        FFT_Rng:
        begin
          
          // HFQ - чтоб массивы созавались асинхронно, то есть одновременно
          Context.Default.SyncInvoke(
            (matr_hth.NewQueue.WriteData(HFQ&<System.Array>( ()-> ArrGen&<single>(hl_sz*hl_sz, i->Random) )) as CommandQueue<KernelArg>) *
            (matr_hto.NewQueue.WriteData(HFQ&<System.Array>( ()-> ArrGen&<single>(hl_sz*ol_sz, i->Random) )) as CommandQueue<KernelArg>)
          );
          
        end;
        
      end;
      
    end;
    
    {$endregion init}
    
    {$region work}
    
    public procedure TrainOn(training_data: array of array of byte; after_work: AI->()) :=
    try
      
      var vec_hl := new KernelArg( sz_hl );
      var vec_ol := new KernelArg( sz_ol );
      
      var bb_matr_hth := new KernelArg( matr_hth.Size );
      var bb_matr_hto := new KernelArg( matr_hto.Size );
      var bb_vec_hl := new KernelArg( sz_hl );
      
      var training_args := new KernelArg[training_data.Length];
      var next_arg_indexes: array of integer;
      
      var Q_CopyToBack :=
        (matr_hth.NewQueue.CopyTo(bb_matr_hth) as CommandQueue<KernelArg>) *
        (matr_hto.NewQueue.CopyTo(bb_matr_hto) as CommandQueue<KernelArg>);
      
      var Q_InitTrainArgs :=
        HPQ(
          ()->
          begin
            next_arg_indexes := SeqGen(100,i->Random(training_args.Length)).Distinct.ToArray;
            
            Context.Default.SyncInvoke(
              next_arg_indexes
              
              .Where(i->training_args[i]=nil)
              .Select(
                i->
                HPQ(()->
                begin
                  training_args[i] :=
                    KernelArg.Create(training_data[i].Length)
                    .WriteData(training_data[i]);
                end) as CommandQueue<object>
              )
              
              .Aggregate(
                (q1,q2) ->
                q1*q2
              )
              
            );
            
          end
        ) as CommandQueue<object>;
      
      var Q_AfterWork :=
        HPQ(()->after_work(self)) as CommandQueue<object>;
      
      var Q_Learn :=
        prog['MatrMltVec'].NewQueue.Exec(1 // TODO
          
        ) as CommandQueue<Kernel>;
      
      
      
      Context.Default.SyncInvoke(
        //Q_CopyToBack +
        Q_Learn
      );
      
      while true do
      begin
        Swap(matr_hth, bb_matr_hth);
        Swap(matr_hto, bb_matr_hto);
        Swap(vec_hl, bb_vec_hl);
        
        Context.Default.SyncInvoke(
          Q_AfterWork *
          (
            Q_CopyToBack +
            Q_Learn 
          )
        );
        
      end;
      
    except
      on e: Exception do
      begin
        System.Windows.MessageBox.Show(
          e.ToString,
          'Ошибка во время тренировки ИИ'
        );
        Halt;
      end;
    end;
    
    public function OutputData: sequence of word;
    begin
      
      
      
    end;
    
    {$endregion work}
    
    {$region serialization}
    
    public procedure Save(bw: System.IO.BinaryWriter);
    begin
      
      bw.Write(self.sz_hl);
      bw.Write(self.sz_ol);
      
      bw.Write(matr_hth.GetArray&<array of byte>( integer(matr_hth.Size32) ));
      bw.Write(matr_hto.GetArray&<array of byte>( integer(matr_hto.Size32) ));
      
    end;
    
    public static function Load(br: System.IO.BinaryReader): AI;
    begin
      Result := new AI;
      
      Result.sz_hl := br.ReadInt32;
      Result.sz_ol := br.ReadInt32;
      
      var hth_buff := br.ReadBytes( Result.sz_hl*Result.sz_hl * 4 );
      var hto_buff := br.ReadBytes( Result.sz_hl*Result.sz_ol * 4 );
      if hto_buff.Length <> Result.sz_hl*Result.sz_ol * 4 then raise new System.IO.EndOfStreamException;
      
      Context.Default.SyncInvoke(
        (Result.matr_hth.NewQueue.WriteData( hth_buff ) as CommandQueue<KernelArg>) *
        (Result.matr_hto.NewQueue.WriteData( hto_buff ) as CommandQueue<KernelArg>)
      );
      
    end;
    
    {$endregion serialization}
    
  end;
  
end.