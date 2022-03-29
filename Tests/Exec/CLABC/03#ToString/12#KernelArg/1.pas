## uses OpenCLABC;

var test_layer := 0;
var PrintIdents := procedure->
loop test_layer do Write('|'#9);
var Test := procedure(arg: KernelArg)->
foreach var l in arg.ToString.Trim.Split(#10) do
begin
  PrintIdents;
  Writeln(l);
end;
var TestRange := procedure(name: string; tests: ()->())->
begin
  PrintIdents;
  Writeln(name);
  test_layer += 1;
  tests();
  test_layer -= 1;
end;



var val := 1;
var a := |2.0|;
var a3 := new int64[2,3,4];
var seg := new System.ArraySegment<integer>(|2,3,4|, 1,1);

var area := new NativeMemoryArea(new System.IntPtr(4), new System.UIntPtr(5));
var ptr := PReal(pointer(6));
var n_val := new NativeValue<byte>(7);
var n_a := new NativeArray<integer>(|8,9|);

var cl_mem := new CLMemorySegment(11);
var cl_sub_mem := new CLMemorySubSegment(cl_mem, 0,10);
var cl_val := new CLValue<word>;
var cl_a := new CLArray<single>(12);



TestRange('Const', ()->
begin
  
  TestRange('Managed', ()->
  begin
    TestRange('Value', ()->
    begin
      Test(KernelArg.FromValue(val));
      Test(val);
    end);
    TestRange('Array', ()->
    begin
      Test(KernelArg.FromArray(a));
      Test(a);
    end);
    TestRange('Array3', ()->
    begin
      Test(KernelArg.FromArray3(a3));
      Test(a3);
    end);
    TestRange('ArraySegment', ()->
    begin
      Test(KernelArg.FromArraySegment(seg));
//      Test(seg); //TODO #2650
      TestRange('TODO#2650: implicit from segment', ()->exit());
    end);
  end);
  
  TestRange('Native', ()->
  begin
    TestRange('Area', ()->
    begin
      Test(KernelArg.FromData(area));
      Test(area);
    end);
    TestRange('Pointer', ()->
    begin
      Test(ptr);
    end);
    TestRange('NativeValue', ()->
    begin
      Test(KernelArg.FromNativeValue(n_val));
      Test(n_val);
    end);
    TestRange('NativeArray', ()->
    begin
      Test(KernelArg.FromNativeArray(n_a));
      Test(n_a);
    end);
  end);
  
  TestRange('OpenCL', ()->
  begin
    TestRange('CLMemorySegment', ()->
    begin
      Test(KernelArg.FromCLMemorySegment(cl_mem));
      Test(cl_mem);
    end);
    TestRange('CLMemorySubSegment', ()->
    begin
      Test(KernelArg.FromCLMemorySegment(cl_sub_mem));
      Test(cl_sub_mem);
    end);
    TestRange('CLValue', ()->
    begin
      Test(KernelArg.FromCLValue(cl_val));
      Test(cl_val);
    end);
    TestRange('CLArray', ()->
    begin
      Test(KernelArg.FromCLArray(cl_a));
      Test(cl_a);
    end);
  end);
  
end);

TestRange('Queue', ()->
begin
  
  TestRange('Managed', ()->
  begin
    TestRange('Value', ()->
    begin
      Test(KernelArg.FromValueCQ(CQ(val)));
      Test(CQ(val));
    end);
    TestRange('Array', ()->
    begin
      Test(KernelArg.FromArrayCQ(CQ(a)));
      Test(CQ(a));
    end);
    TestRange('Array3', ()->
    begin
      Test(KernelArg.FromArray3CQ(CQ(a3)));
      Test(CQ(a3));
    end);
    TestRange('ArraySegment', ()->
    begin
      Test(KernelArg.FromArraySegmentCQ(CQ(seg)));
//      Test(CQ(seg)); //TODO #2650
      TestRange('TODO#2650: implicit from segment', ()->exit());
    end);
  end);
  
  TestRange('Native', ()->
  begin
    TestRange('Area', ()->
    begin
      Test(KernelArg.FromDataCQ(area));
      Test(CQ(area));
    end);
    TestRange('NativeValue', ()->
    begin
      Test(KernelArg.FromNativeValueCQ(CQ(n_val)));
      Test(CQ(n_val));
    end);
    TestRange('NativeArray', ()->
    begin
      Test(KernelArg.FromNativeArrayCQ(CQ(n_a)));
      Test(CQ(n_a));
    end);
  end);
  
  TestRange('OpenCL', ()->
  begin
    TestRange('CLMemorySegment', ()->
    begin
      Test(KernelArg.FromCLMemorySegmentCQ(cl_mem));
      Test(CQ(cl_mem));
    end);
    TestRange('CLMemorySubSegment', ()->
    begin
      Test(KernelArg.FromCLMemorySegmentCQ(CQ&<CLMemorySegment>(cl_sub_mem)));
      Test(CQ&<CLMemorySegment>(cl_sub_mem));
    end);
    TestRange('CLValue', ()->
    begin
      Test(KernelArg.FromCLValueCQ(CQ(cl_val)));
      Test(CQ(cl_val));
    end);
    TestRange('CLArray', ()->
    begin
      Test(KernelArg.FromCLArrayCQ(CQ(cl_a)));
      Test(CQ(cl_a));
    end);
  end);
  
end);