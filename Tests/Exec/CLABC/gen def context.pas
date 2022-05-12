## uses OpenCLABC;

CLContext.GenerateAndCheckDefault;
var c := CLContext.Default;

var bw := new System.IO.BinaryWriter(System.IO.File.Create('..\..\..\TestContext.dat'));

bw.Write(
  CLPlatform.All.Single(pl->c.MainDevice in CLDevice.GetAllFor(pl, CLDeviceType.DEVICE_TYPE_ALL))
  .Properties.Name
);

bw.Write(c.AllDevices.Count);
foreach var dvc in c.AllDevices do
  bw.Write(dvc.Properties.Name);

bw.Close;