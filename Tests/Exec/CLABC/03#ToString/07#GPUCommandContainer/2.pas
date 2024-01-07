## uses OpenCLABC;

var a := new CLArray<byte>(1);

Println(a.MakeCCQ.ThenWriteValue(1,2)+CQ(3));
Println(a.MakeCCQ.ThenWriteValue(CQ&<byte>(1),2)+CQ(3));

a.Dispose;