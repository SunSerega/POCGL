## uses OpenCLABC;

var code := new CLProgramCode('kernel void k(int x) { }');
var k := code['k'];

k.NewQueue
.ThenExec2(1,1,
  
  CLMemoryCCQ.Create(HTFQ(()->new CLMemory(1)))
  .ThenQueue(HTFQ(()->5))
  .ThenConstProc(m->begin end)
  .ThenQuickProc(m->begin end)
  .ThenThreadedProc(m->begin end),
  
  5
).Println;