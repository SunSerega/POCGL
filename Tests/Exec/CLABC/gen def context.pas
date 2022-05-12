## uses OpenCLABC;

CLContext.GenerateAndCheckDefault;
var c := CLContext.Default;

var bw := new System.IO.BinaryWriter(System.IO.File.Create('..\..\..\TestContext.dat'));

if c=nil then
  bw.Write('') else
begin
  bw.Write(c.MainDevice.BaseCLPlatform.Properties.Name);
  bw.Write(c.AllDevices.Count);
  foreach var dvc in c.AllDevices do
    bw.Write(dvc.Properties.Name);
end;

bw.Close;

// Kill all debug output
System.Environment.ExitCode := 0;
System.Diagnostics.Process.GetCurrentProcess.Kill;