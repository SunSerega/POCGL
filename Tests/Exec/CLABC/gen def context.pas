## uses OpenCLABC;

CLContext.GenerateAndCheckDefault;
var c := CLContext.Default;

var bw := new System.IO.BinaryWriter(System.IO.File.Create('..\..\..\TestContext.dat'));

bw.Write(c.MainDevice.BaseCLPlatform.Properties.Name);
bw.Write(c.AllDevices.Count);
foreach var dvc in c.AllDevices do
  bw.Write(dvc.Properties.Name);

bw.Close;