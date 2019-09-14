uses BinSpecData;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

begin
  try
    
    Otp('Loading');
    var db := BinSpecDB.InitFromFolder('SpecFormating\GLExt\ext spec texts');
    Otp('Saving');
    db.Save('SpecFormating\GLExt\ext spec.bin');
    
    if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString('done');
  except
    on e: System.Threading.ThreadAbortException do System.Threading.Thread.ResetAbort;
    on e: Exception do ErrOtp(e);
  end;
end.