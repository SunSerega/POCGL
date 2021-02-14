uses OpenCLABC;

procedure p1(q: CommandQueue<integer>);
begin
  for var base := false to true do
  begin
    var t := if base then
      Context.Default.BeginInvoke(q as CommandQueueBase) else
      Context.Default.BeginInvoke(q);
    try
      t.Wait;
    except
    end;
    t.WhenDoneBase    ( tsk     ->Writeln(1));
    t.WhenCompleteBase((tsk,res)->Writeln(2));
    t.WhenErrorBase   ((tsk,err)->Writeln(3));
    Writeln('-'*30);
  end;
end;

begin
  p1(5);
  p1(HPQ(()->raise new Exception) + HFQ(()->5));
end.