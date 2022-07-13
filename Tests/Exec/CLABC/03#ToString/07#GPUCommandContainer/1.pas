## uses OpenCLABC;

var code := new CLProgramCode('kernel void k(global int* mem, int x) { }');
var k := code['k'];

k.MakeCCQ
.ThenExec2(1,1,
  
  CLMemoryCCQ.Create(HFQ(()->new CLMemory(1)))
  .ThenQueue(HFQ(()->5))
  .ThenProc(m->begin end, false,true)
  .ThenProc(m->begin end, false)
  .ThenProc(m->begin end),
  
  5
).Println;