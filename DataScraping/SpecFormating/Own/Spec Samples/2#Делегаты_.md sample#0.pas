procedure p1(i: integer);
begin
  Writeln(i);
end;

begin
  
  var d: System.Delegate := p1; // это не вызов, а получение адреса p1
  d.DynamicInvoke(5); // вообще .DynamicInvoke это очень медленно
  
  var p: integer->();
//  var p: Action<integer>; // такое же объявление как на предыдущей строчке, но в другом стиле
  
  p(5); // типизированные делегаты можно вызывать быстрее и проще, так же как обычные подпрограммы
  
end.