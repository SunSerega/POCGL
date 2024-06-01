﻿uses OpenCLABC;

/// Вывод типа и значения объекта
procedure OtpObject(o: object) :=
  Writeln( $'{o?.GetType}[{ObjectToString(o)}]' );
// "o?.GetType" это короткая форма "o=nil ? nil : o.GetType",
// то есть, берём или тип объекта, или nil если сам объект nil
// ObjectToString это функция, которую использует Writeln для форматирования значений

begin
  var b0 := new Buffer(1);
  
  // Тип - буфер, потому что очередь создали из буфера
  OtpObject(  Context.Default.SyncInvoke( b0.NewQueue as CommandQueue<Buffer>   )  );
  
  // Тип - Int32 (то есть integer), потому что это тип по умолчанию для выражения (5)
  OtpObject(  Context.Default.SyncInvoke( HFQ( ()->5                          ) )  );
  
  // Тип - string, по той же причине
  OtpObject(  Context.Default.SyncInvoke( HFQ( ()->'abc'                      ) )  );
  
  // Тип отсутствует, потому что HPQ возвращает nil
  OtpObject(  Context.Default.SyncInvoke( HPQ( ()->Writeln('Выполнилась HPQ') ) )  );
  
end.