## uses OpenCLABC;

var wh := new System.Threading.ManualResetEventSlim(false);
var Q := (HPQ(wh.Wait)+HFQ(()->123)).Multiusable;
var t := CLContext.Default.BeginInvoke(
  Q *
  Q.ThenUse(x->Println(x))
);
wh.Set;
t.Wait;