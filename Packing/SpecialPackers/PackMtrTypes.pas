uses Pack_Utils;

begin
  try
    ExecuteFile('..\Text generators\Mtr.pas', 'MtrCodeGenerator', '"fname=Packing\MtrTypes.template"');
  except
    on e: Exception do ErrOtp(e);
  end;
end.