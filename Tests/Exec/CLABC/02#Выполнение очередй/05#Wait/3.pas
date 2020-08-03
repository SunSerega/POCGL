uses OpenCLABC;

procedure Test(Q1_exec_count: integer; err_text1, err_text2: string) :=
try
  var Q1 := HFQ(()->0);
  
  var t1 := Context.Default.BeginInvoke(
    WaitFor(Q1) +
    WaitFor(Q1) +
    HPQ(()->
    begin
      Writeln('raise1');
      raise new Exception(err_text1);
    end)
  );
  var t2 := Context.Default.BeginInvoke(
    CombineSyncQueue(ArrFill(Q1_exec_count,Q1)) +
    HPQ(()->
    begin
      Sleep(10);
      Writeln('raise2');
      raise new Exception(err_text2);
    end)
  );
  
  var ev := new System.Threading.ManualResetEvent(false);
  var first_err := true;
  var on_err: Action2<CLTaskBase, array of Exception> := (tsk,err)->
  if not first_err then
    ev.Set else
  begin
    err.PrintLines;
    first_err := false;
    Context.Default.SyncInvoke(Q1);
  end;
  
  t1.WhenError(on_err);
  t2.WhenError(on_err);
  
  ev.WaitOne;
except
  on e: Exception do Writeln(e);
end;

begin
  Test(1, 'TestERROR', 'TestOK');
  Writeln('='*40);
  Test(2, 'TestOK', 'TestERROR');
end.