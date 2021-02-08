uses OpenCLABC;
uses OpenCL;

begin
  var code := new ProgramCode(Context.Default, '__kernel void p1() { }');
  var k := code['p1'];
  
  //ToDo Обрабатывать в .td файле, а не коде
  code.GetType.GetField('ntv', System.Reflection.BindingFlags.Instance or System.Reflection.BindingFlags.NonPublic).SetValue(code, new cl_program(new System.IntPtr(1)));
     k.GetType.GetField('ntv', System.Reflection.BindingFlags.Instance or System.Reflection.BindingFlags.NonPublic).SetValue(   k, new cl_kernel (new System.IntPtr(2)));
  
  k.NewQueue
  .AddExec2(1,1,
    BufferCommandQueue.Create(HFQ(()->new Buffer(1)))
    .AddQueue(nil as object)
    .AddQueue(HFQ(()->5))
    .AddProc(b->exit()),
    5
  )
  .Println;
  
  code.GetType.GetField('ntv', System.Reflection.BindingFlags.Instance or System.Reflection.BindingFlags.NonPublic).SetValue(code, new cl_program(new System.IntPtr(0)));
     k.GetType.GetField('ntv', System.Reflection.BindingFlags.Instance or System.Reflection.BindingFlags.NonPublic).SetValue(   k, new cl_kernel (new System.IntPtr(0)));
  
end.