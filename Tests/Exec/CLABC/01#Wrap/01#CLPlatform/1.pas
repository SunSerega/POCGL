## uses OpenCLABC;

var pl := CLPlatform.All[0];
Println(pl.GetType);
Println(pl.Properties.GetType);
var pl2 := new CLPlatform(pl.Native);
(pl=pl2).Println;
Arr(pl).Contains(pl2).Println;
Println(pl2.GetType);
Println(pl2.Properties.GetType);