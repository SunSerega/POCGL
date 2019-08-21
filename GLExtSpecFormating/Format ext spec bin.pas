uses BinSpecData;

begin
  
  var db := BinSpecDB.InitFromFolder('gl ext spec');
  db.Save('gl ext spec.bin');
  
//  ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\Data scrappers\gl ext spec\3DFX\3DFX_multisample.txt');
  
end.