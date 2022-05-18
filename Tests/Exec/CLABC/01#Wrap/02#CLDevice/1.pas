## uses OpenCLABC;

var dvc := CLContext.Default.MainDevice;
Println(dvc.GetType);
Println(dvc.Properties.GetType);
var dvc2 := CLDevice.FromNative(dvc.Native);
(dvc=dvc2).Println;
Arr(dvc).Contains(dvc2).Println;
Println(dvc2.GetType);
Println(dvc2.Properties.GetType);