uses OpenCLABC;

type
  Color = record
    a, r, g, b: byte;
  end;
  
begin
  var code := new ProgramCode(ReadAllText('Поиск.cl'));
  
  var (W,H) := (3, 5);
  var bitmap := new CLArray<Color>(W*H);
  
  code['FillWrite'].Exec2(W, H, bitmap, W, H);
//  bitmap.GetArray.Length.Println;
  Matr(W,H, bitmap.GetArray()).Println(10);
  
  
end.