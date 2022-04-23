## uses OpenCLABC;

var pl := Platform.All[0];
Println(pl.GetType);
Println(pl.Properties.GetType);
var pl2 := new Platform(pl.Native);
(pl=pl2).Println;
Arr(pl).Contains(pl2).Println;
Println(pl2.GetType);
Println(pl2.Properties.GetType);