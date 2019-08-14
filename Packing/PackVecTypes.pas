uses Pack_Utils;

begin
  try
    ExecuteFile('..\Text generators\Vec.pas', 'VecCodeGenerator', '"fname=Packing\VecTypes.template"');
  except
    on e: Exception do ErrOtp(e);
  end;
end.