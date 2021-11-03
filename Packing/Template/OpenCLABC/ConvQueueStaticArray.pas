uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses Fixers       in '..\..\..\Utils\Fixers';

uses ATask        in '..\..\..\Utils\ATask';

const MaxQueueStaticArraySize = 7;

begin
  try
    
    (
      Range(2, MaxQueueStaticArraySize).TaskForEach(c->
      begin
        var res := new System.IO.StreamWriter(GetFullPathRTA($'ConvQueue\StaticArray[{c}].template'), false, enc);
        loop 3 do res.WriteLine;
        
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
        
        res.WriteLine('type');
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
        res.WriteLine('    private constructor := raise new InvalidOperationException($''%Err:NoParamCtor%'');');
        
        res.WriteLine('    ');
        
        res.WriteLine('    protected procedure RegisterWaitables(g: CLTaskGlobalData; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;');
        res.WriteLine('    begin');
        for var i := 1 to c do
          res.WriteLine($'      self.q{i}.RegisterWaitables(g, prev_hubs);');
        res.WriteLine('    end;');
        
        res.WriteLine('    ');
        
        res.WriteLine('    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<CommandQueueBase,integer>; delayed: HashSet<CommandQueueBase>); override;');
        res.WriteLine('    begin');
        res.WriteLine('      sb += #10;');
        for var i := 1 to c do
          res.WriteLine($'      self.q{i}.ToString(sb, tabs, index, delayed);');
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
        
        res.Write($'    protected function InvokeSubQs(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<');
        WriteVTDef;
        res.WriteLine('>; override;');
        res.WriteLine($'    begin');
        res.WriteLine($'      l := l.WithPtrNeed(false);');
        
        for var i := 1 to c do
          res.WriteLine($'      var qr{i} := q{i}.Invoke(g, l); l.prev_ev := qr{i}.ev;');
        
        res.Write($'      Result := new QueueResFunc<');
        WriteVTDef;
        res.Write('>(()->ValueTuple.Create(qr1.GetRes()');
        for var i := 2 to c do
          res.Write($', qr{i}.GetRes()');
        res.WriteLine('), l.prev_ev);');
        
        res.WriteLine($'    end;');
        
        res.WriteLine($'    ');
        res.WriteLine($'  end;');
        
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
        
        res.Write($'    protected function InvokeSubQs(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<');
        WriteVTDef;
        res.WriteLine('>; override;');
        res.WriteLine($'    begin');
        res.WriteLine($'      l := l.WithPtrNeed(false);');
        res.WriteLine($'      if (l.prev_ev<>nil) and (l.prev_ev.count<>0) then loop {c-1} do l.prev_ev.Retain({{$ifdef EventDebug}}$''for all async branches''{{$endif}});');
        
        for var i := 1 to c do
          res.WriteLine($'      var qr{i}: QueueRes<TInp{i}>;');
        
        res.WriteLine($'      g.ParallelInvoke(l.err_handler, invoker->');
        res.WriteLine($'      begin');
        for var i := 1 to c do
          res.WriteLine($'        qr{i} := q{i}.Invoke(g, l); invoker.FinishInvokeBranch(qr{i}.ev);');
        res.WriteLine($'      end);');
        
        res.Write($'      Result := new QueueResFunc<');
        WriteVTDef;
        res.Write('>(()->ValueTuple.Create(qr1.GetRes()');
        for var i := 2 to c do
          res.Write($', qr{i}.GetRes()');
        res.Write('), ');
        
        res.Write('EventList.Combine(|qr1.ev');
        for var i := 2 to c do
          res.Write($', qr{i}.ev');
        res.WriteLine('|));');
        
        res.WriteLine($'    end;');
        
        res.WriteLine($'    ');
        res.WriteLine($'  end;');
        
        {$endregion ConvAsyncQueueArray}
        
        loop 2 do res.WriteLine('  ');
        res.Write('  ');
        res.Close;
      end)
    *
      ProcTask(()->
      begin
        var res := new System.IO.StreamWriter(GetFullPathRTA('ConvQueue\AllStaticArrays.template'), false, enc);
        
        loop 3 do res.WriteLine('  ');
        for var c := 2 to MaxQueueStaticArraySize do
        begin
          res.WriteLine($'{{$region [{c}]}}');
          res.WriteLine;
          res.WriteLine($'{{%StaticArray[{c}]%}}');
          res.WriteLine($'  ');
          res.WriteLine($'{{$endregion [{c}]}}');
          res.WriteLine;
        end;
        loop 1 do res.WriteLine('  ');
        res.Write('  ');
        
        res.Close;
      end)
    ).SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.