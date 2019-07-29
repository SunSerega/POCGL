uses BinSpecData;

begin
  
  var db := BinSpecDB.InitFromFolder('gl ext spec');
  db.Save('gl ext spec.bin');
  
//  ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\Data scrappers\gl ext spec\APPLE\APPLE_clip_distance.txt');
  
end.