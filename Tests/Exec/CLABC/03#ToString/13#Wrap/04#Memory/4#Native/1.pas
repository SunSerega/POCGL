## uses OpenCLABC;

procedure Test(o: System.IDisposable);
begin
  
  var area := o.GetType.GetProperty('Area')?.GetValue(o) ?? o;
  area := area.GetType.GetProperty('UntypedArea')?.GetValue(area) ?? area;
  NativeMemoryArea(area).FillZero;
  
  Println(o);
  
end;

Test(new NativeMemory(new System.UIntPtr(100)));
Test(new NativeMemory(new System.UIntPtr(101)));

Test(new NativeValue<byte>(123));

Test(new NativeArray<integer>(30));
Test(new NativeArray<integer>(31));