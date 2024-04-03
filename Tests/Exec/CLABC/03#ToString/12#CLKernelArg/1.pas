uses OpenCLABC;
uses System;

var test_layer := 0;
procedure PrintIdents :=
  loop test_layer do Write('|'#9);
procedure Test(arg: CLKernelArg) :=
  foreach var l in arg.ToString.Trim.Split(#10) do
  begin
    PrintIdents;
    l.Println;
  end;
procedure TestT<T>(arg: T); where T: CLKernelArg;
begin
  Test(arg);
end;
procedure TestRange(name: string; tests: ()->()) :=
begin
  PrintIdents;
  name.Println;
  test_layer += 1;
  tests();
  test_layer -= 1;
end;

type T=byte;

var val := 1;
var a  := new T[](1,2,3,4);
var a2 := new T[2,3]((1,2,3),(4,5,6));
var a3 := new T[2,3,4](((1,2,3,4),(5,6,7,8),(9,0,1,2)),((3,4,5,6),(7,8,9,0),(1,2,3,4)));
var seg := new ArraySegment<T>(a, 1,2);

var ntv_mem_area := new NativeMemoryArea(new IntPtr(1), new UIntPtr(2));
var ntv_val_area := new NativeValueArea<T>(new IntPtr(3));
var ntv_arr_area := new NativeArrayArea<T>(new IntPtr(4), 5);

var ntv_mem := new NativeMemory(new UIntPtr(2));
var ntv_val := new NativeValue<T>(123);
var ntv_arr := new NativeArray<T>(a);

var cl_mem := new CLMemory(new UIntPtr(1));
var cl_val := new CLValue<T>(123);
var cl_arr := new CLArray<T>(4);

begin
  
  {$include All}
  
  cl_mem.Dispose;
  cl_val.Dispose;
  cl_arr.Dispose;
end.