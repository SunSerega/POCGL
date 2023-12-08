## uses OpenCLABC;

{$ifdef ForceMaxDebug}
OpenCLABC.gen_debug_otp := new System.IO.StreamWriter('CLContextGen.log', false, new System.Text.UTF8Encoding(true));
OpenCLABC.eh_debug_otp := new System.IO.StreamWriter('CLContextGen.EH.log', false, new System.Text.UTF8Encoding(true));
{$endif ForceMaxDebug}

var dir := 'CLContext';
if System.IO.Directory.Exists(dir) then
  System.IO.Directory.Delete(dir, true);
System.IO.Directory.CreateDirectory(dir);

foreach var c in CLContext.GenerateAndCheckAllPossible.OrderBy(\(c,time)->time).Select(\(c,time)->c) index i do
begin
  var bw := new System.IO.BinaryWriter(System.IO.File.Create($'{dir}/{i}.dat'));
  
  $'Platform:'.Print;
  bw.Write(c.MainDevice.BaseCLPlatform.Properties.Name.Println);
  bw.Write(c.AllDevices.Count);
  foreach var dvc in c.AllDevices do
  begin
    $'Device:'.Print;
    bw.Write(dvc.Properties.Name.Println);
  end;
  
  bw.Close;
end;