uses OpenCL;

begin
  
  var cb: Event_Callback := (ev,st,data)->
  begin
    Writeln($'{ev} перешёл в состояние {st}');
  end;
  
  var ev: cl_event; //ToDo := ...
  
  cl.SetEventCallback(ev, CommandExecutionStatus.COMPLETE, cb, nil).RaiseIfError;
end.