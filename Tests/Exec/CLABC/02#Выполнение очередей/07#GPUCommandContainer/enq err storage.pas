## uses OpenCLABC;

var a := new CLArray<integer>(1);
var wh := new System.Threading.ManualResetEventSlim(false);
var t := CLContext.Default.BeginInvoke(
  (HPQ(wh.Wait) + CQ(a)).MakeCCQ.ThenWriteArray(HFQ(()->nil as array of integer, false))
  .HandleWithoutRes(e->TypeName(e).Println <> nil)
);
wh.Set;
t.Wait;
a.Dispose;