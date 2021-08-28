uses OpenCLABC;

begin
  var code := new ProgramCode(Context.Default, '__kernel void p1() { }');
  var k := code['p1'];
  
  k.NewQueue
  //ToDo #2511 - убрать все KernelArg.From
  .AddExec2(1,1,
    KernelArg.FromMemorySegmentCQ(
      MemorySegmentCCQ.Create(HFQ(()->new MemorySegment(1)))
      .AddQueue(HFQ(()->5))
      .AddProc(ms->begin exit() end)
    ),
    KernelArg.FromRecord(5)
  ).Println;
  
end.