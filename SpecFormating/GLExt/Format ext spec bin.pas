uses BinSpecData;
uses MiscUtils in '..\Utils\MiscUtils.pas';

begin
  try
    
    var db := BinSpecDB.InitFromFolder('GLExtSpecFormating\ext spec texts');
    db.Save('GLExtSpecFormating\ext spec.bin');
    
  //  ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\Data scrappers\gl ext spec\3DFX\3DFX_multisample.txt');
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.