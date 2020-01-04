uses OpenCLABC;

begin
  {$resource '0.bin'} // добавляет 0.bin внутрь готового .exe файла
  
  var code := ProgramCode.DeserializeFrom(Context.Default, GetResourceStream('0.bin'));
  
  var A := new Buffer( 10 * sizeof(integer) );
  
  code['TEST'].Exec1(10,
    
    A.NewQueue.AddFillValue(1)
    as CommandQueue<Buffer>
    
  );
  
  A.GetArray1&<integer>(10).Println;
  
end.