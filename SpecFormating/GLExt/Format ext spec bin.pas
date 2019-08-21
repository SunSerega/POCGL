uses BinSpecData;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

begin
  try
    
    var db := BinSpecDB.InitFromFolder('SpecFormating\GLExt\ext spec texts');
    db.Save('SpecFormating\GLExt\ext spec.bin');
    
  //  ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\Data scrappers\gl ext spec\3DFX\3DFX_multisample.txt');
    
    if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString('done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.