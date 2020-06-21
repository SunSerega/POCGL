uses MiscUtils  in '..\..\..\Utils\MiscUtils';
uses Fixers     in '..\..\..\Utils\Fixers';

const MaxQueueStaticArraySize = 7;

begin
  try
    
    Range(2, MaxQueueStaticArraySize).Select(c->ProcTask(()->
    begin
      var res := new System.IO.StreamWriter(GetFullPathRTE($'ConvQueueStaticArray[{c}].template'), false, enc);
      loop 3 do res.WriteLine('  ');
      
      var WriteVTDef: Action0 := ()->
      begin
        res.Write('ValueTuple<TInp1');
        for var i := 2 to c do
          res.Write($', TInp{i}');
        res.Write('>');
      end;
      
      var WriteFuncDef: Action0 := ()->
      begin
        res.Write('(');
        for var i := 1 to c do
          res.Write($'TInp{i}, ');
        res.Write('Context)->TRes');
      end;
      
      {$region ConvQueueArrayBase}
      
      res.Write($'  ConvQueueArrayBase{c}<');
      for var i := 1 to c do
        res.Write($'TInp{i}, ');
      res.Write('TRes> = abstract class(HostQueue<');
      WriteVTDef;
      res.Write(', TRes>)');
      res.WriteLine;
      
      for var i := 1 to c do
        res.WriteLine($'    protected q{i}: CommandQueue<TInp{i}>;');
      
      res.Write('    protected f: ');
      WriteFuncDef;
      res.WriteLine(';');
      
      res.WriteLine('    ');
      
      res.Write('    public constructor(');
      for var i := 1 to c do
        res.Write($'q{i}: CommandQueue<TInp{i}>; ');
      res.Write('f: ');
      WriteFuncDef;
      res.WriteLine(');');
      
      res.WriteLine('    begin');
      for var i := 1 to c do
        res.WriteLine($'      self.q{i} := q{i};');
      res.WriteLine('      self.f := f;');
      res.WriteLine('    end;');
      res.WriteLine('    private constructor := raise new NotSupportedException;');
      
      res.WriteLine('    ');
      
      res.WriteLine('    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;');
      res.WriteLine('    begin');
      for var i := 1 to c do
        res.WriteLine($'      self.q{i}.RegisterWaitables(tsk, prev_hubs);');
      res.WriteLine('    end;');
      
      res.WriteLine('    ');
      
      res.Write('    protected function ExecFunc(t: ');
      WriteVTDef;
      res.Write('; c: Context): TRes; override := f(');
      for var i := 1 to c do
        res.Write($'t.Item{i}, ');
      res.WriteLine('c);');
      
      res.WriteLine('    ');
      
      res.WriteLine('  end;');
      
      {$endregion ConvQueueArrayBase}
      
      res.WriteLine('  ');
      
      {$region ConvSyncQueueArray}
      
      res.Write($'  ConvSyncQueueArray{c}<');
      for var i := 1 to c do
        res.Write($'TInp{i}, ');
      res.Write($'TRes> = sealed class(ConvQueueArrayBase{c}<');
      for var i := 1 to c do
        res.Write($'TInp{i}, ');
      res.Write('TRes>)');
      res.WriteLine;
      res.WriteLine('    ');
      
      res.Write('    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<');
      WriteVTDef;
      res.WriteLine('>; override;');
      res.WriteLine('    begin');
      
      for var i := 1 to c do
        res.WriteLine($'      var qr{i} := q{i}.Invoke(tsk, c, main_dvc, false, cq, prev_ev); prev_ev := qr{i}.ev;');
      
      res.Write('      Result := new QueueResFunc<');
      WriteVTDef;
      res.Write('>(()->ValueTuple.Create(qr1.GetRes()');
      for var i := 2 to c do
        res.Write($', qr{i}.GetRes()');
      res.WriteLine('));');
      
      res.WriteLine('      Result.ev := prev_ev;');
      
      res.WriteLine('    end;');
      
      res.WriteLine('    ');
      res.WriteLine('  end;');
      
      {$endregion ConvSyncQueueArray}
      
      {$region ConvAsyncQueueArray}
      
      res.Write($'  ConvAsyncQueueArray{c}<');
      for var i := 1 to c do
        res.Write($'TInp{i}, ');
      res.Write($'TRes> = sealed class(ConvQueueArrayBase{c}<');
      for var i := 1 to c do
        res.Write($'TInp{i}, ');
      res.Write('TRes>)');
      res.WriteLine;
      res.WriteLine('    ');
      
      res.Write('    protected function InvokeSubQs(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; prev_ev: EventList): QueueRes<');
      WriteVTDef;
      res.WriteLine('>; override;');
      res.WriteLine('    begin');
      
      res.WriteLine(  $'      var qr{1} := q{1}.Invoke(tsk, c, main_dvc, false, cq, prev_ev);');
      for var i := 2 to c do
        res.WriteLine($'      var qr{i} := q{i}.InvokeNewQ(tsk, c, main_dvc, false, prev_ev);');
      
      res.Write('      Result := new QueueResFunc<');
      WriteVTDef;
      res.Write('>(()->ValueTuple.Create(qr1.GetRes()');
      for var i := 2 to c do
        res.Write($', qr{i}.GetRes()');
      res.WriteLine('));');
      
      res.Write('      Result.ev := EventList.Combine(new EventList[](qr1.ev');
      for var i := 2 to c do
        res.Write($', qr{i}.ev');
      res.WriteLine('), tsk, c.Native, main_dvc, cq);');
      
      res.WriteLine('    end;');
      
      res.WriteLine('    ');
      res.WriteLine('  end;');
      
      {$endregion ConvAsyncQueueArray}
      
      loop 2 do res.WriteLine('  ');
      res.Write('  ');
      res.Close;
    end)).Append(ProcTask(()->
    begin
      var res := new System.IO.StreamWriter(GetFullPathRTE('ConvQueueStaticArray.template'), false, enc);
      
      loop 3 do res.WriteLine('  ');
      for var c := 2 to MaxQueueStaticArraySize do
      begin
        res.WriteLine($'  {{$region [{c}]}}');
        res.WriteLine($'  ');
        res.WriteLine($'  {{%ConvQueueStaticArray[{c}]%}}');
        res.WriteLine($'  ');
        res.WriteLine($'  {{$endregion [{c}]}}');
        res.WriteLine($'  ');
      end;
      loop 1 do res.WriteLine('  ');
      res.Write('  ');
      
      res.Close;
    end)).CombineAsyncTask.SyncExec;
    
    if not is_secondary_proc then Otp('Done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.