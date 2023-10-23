## uses OpenCLABC;

var dir := 'CLContext';
if System.IO.Directory.Exists(dir) then
  System.IO.Directory.Delete(dir, true);
System.IO.Directory.CreateDirectory(dir);

foreach var c in CLContext.GenerateAndCheckAllPossible.OrderBy(\(c,time)->time).Select(\(c,time)->c) index i do
begin
  var bw := new System.IO.BinaryWriter(System.IO.File.Create($'{dir}/{i}.dat'));
  
  bw.Write(c.MainDevice.BaseCLPlatform.Properties.Name);
  bw.Write(c.AllDevices.Count);
  foreach var dvc in c.AllDevices do
    bw.Write(dvc.Properties.Name);
  
  bw.Close;
end;