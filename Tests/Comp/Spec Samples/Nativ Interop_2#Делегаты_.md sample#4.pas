uses System.Runtime.InteropServices;
uses OpenCL;

begin
  
  var gc_hnd: GCHandle;
  var cb: Event_Callback := (ev,st,data)->
  begin
    
    Writeln($'{ev} перешёл в состояние {st}');
    
    // в данном случае освобождать GCHandle станет можно тогда, когда делегат 1 раз выполнится,
    // а значит очень удобно поставить освобождение в конец самого делегата
    gc_hnd.Free;
  end;
  gc_hnd := GCHandle.Alloc(cb);
  
  var ev: cl_event; //ToDo := ...
  
  cl.SetEventCallback(ev, CommandExecutionStatus.COMPLETE, cb, nil).RaiseIfError;
end.