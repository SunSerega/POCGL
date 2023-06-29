## uses System.IO, '../CLArgs';

procedure OnException(e: Exception; et: string := 'General') :=
lock Console.Error do
begin
  Console.Error.WriteLine($'%{et}Exception%');
  Console.Error.WriteLine(e);
  Halt;
end;

try
  System.Globalization.CultureInfo.DefaultThreadCurrentUICulture := System.Globalization.CultureInfo.CurrentUICulture;
  
  System.AppDomain.CurrentDomain.UnhandledException += (o,e)->
  OnException(Exception(e.ExceptionObject));
  
  var original_input := Console.In;
  Console.SetIn(new System.IO.StringReader(''));
  
  var ep: System.Reflection.MethodInfo;
  try
    var executable := Path.ChangeExtension(Path.ChangeExtension(GetEXEFileName, nil), '.exe');
    if not FileExists(executable) then
      raise new System.IO.FileNotFoundException($'File [{executable}] doesn''t exist');
    ep := System.Reflection.Assembly.LoadFile(executable).EntryPoint;
    if ep=nil then raise new System.NullReferenceException;
  except
    on e: Exception do OnException(e, 'Load');
  end;
  
  if 'PauseWhenLoaded' in CommandLineArgs then
    original_input.ReadLine;
  
  begin
    var halt_thr := new System.Threading.Thread(()->
    try
      var max_exec_time := GetArgs('MaxExecTime').Single.ToInteger;
//      max_exec_time -= max_exec_time div 10;
      Sleep(max_exec_time);
      OnException(new System.TimeoutException($'More then {max_exec_time} milliseconds passed'), 'ExecutionTimeOut');
    except
      on e: Exception do OnException(e);
    end);
    halt_thr.IsBackground := true;
    halt_thr.Start;
  end;
  
  try
    ep.Invoke(nil, new object[0]);
  except
    on e: System.Reflection.TargetInvocationException do OnException(e.InnerException, 'Execution');
//    on e: Exception do OnException(e, 'Execution');
  end;
  
except
  on e: Exception do OnException(e);
end;