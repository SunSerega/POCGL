uses OpenCLABC;

begin
  var dvc := Context.Default.MainDevice;
  Writeln(dvc.GetType);
  Writeln(dvc.Properties.GetType);
  var dvc2 := new Device(dvc.Native);
  (dvc=dvc2).Println;
  Arr(dvc).Contains(dvc2).Println;
  Writeln(dvc2.GetType);
  Writeln(dvc2.Properties.GetType);
end.