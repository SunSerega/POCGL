﻿uses Pack_Utils;

begin
  try
    ExecuteFile('..\Text generators\MtrExt.pas', 'MtrExtCodeGenerator', '"fname=Packing\MtrExt.template"');
  except
    on e: Exception do ErrOtp(e);
  end;
end.