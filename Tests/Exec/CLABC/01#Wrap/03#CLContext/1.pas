﻿## uses OpenCLABC;

var c := CLContext.Default;
Println(c.GetType);
Println(c.Properties.GetType);
var c2 := new CLContext(c.Native);
(c=c2).Println;
c.AllDevices.SequenceEqual(c2.AllDevices).Println;
Arr(c).Contains(c2).Println;
Println(c2.GetType);
Println(c2.Properties.GetType);