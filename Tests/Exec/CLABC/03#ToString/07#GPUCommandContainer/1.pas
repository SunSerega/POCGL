## uses OpenCLABC;

var code := new ProgramCode(Context.Default, '__kernel void p1() { }');
var k := code['p1'];

k.NewQueue
.ThenExec2(1,1,
  
  CLMemoryCCQ.Create(HTFQ(()->new CLMemory(1)))
  .ThenQueue(HTFQ(()->5))
  .ThenConstProc(m->begin end)
  .ThenQuickProc(m->begin end)
  .ThenThreadedProc(m->begin end),
  
  5
).Println;