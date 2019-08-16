uses Pack_Utils;

begin
  try
    ExecuteFile('..\Text converters\glFindNewFuncs.pas', 'glFindNewFuncs', '"fname=Packing\gl_ext.template"');
  except
    on e: Exception do ErrOtp(e);
  end;
end.