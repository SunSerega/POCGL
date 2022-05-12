uses AOtp         in '..\AOtp';
uses SubExecuters in '..\SubExecuters';

begin
  try
    CompilePasFile('TestExecutor.pas', false);
    CompilePasFile('Testing.pas', false);
  except
    on e: Exception do
      ErrOtp(e);
  end;
end.