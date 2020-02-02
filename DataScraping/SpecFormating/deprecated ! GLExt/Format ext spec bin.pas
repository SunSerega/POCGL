uses BinSpecData;
uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

begin
  try
    
    Otp('Loading');
    var db := BinSpecDB.InitFromFolder(GetFullPath('..\ext spec texts', GetEXEFileName));
    
    Otp('Saving');
    db.Save(GetFullPath('..\ext spec.bin', GetEXEFileName));
    
    Otp('Loging');
    db.Log(GetFullPath('..\ext spec.log', GetEXEFileName));
    
    if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString('done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.