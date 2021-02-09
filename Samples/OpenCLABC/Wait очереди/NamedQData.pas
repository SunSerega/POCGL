unit NamedQData;

uses OpenCLABC;

function NamedQ(name: string; delay: integer := 1000): (CommandQueueBase, MarkerQueue);
begin
  var M := new MarkerQueue;
  Result := (HPQ(()->
  begin
    lock output do Writeln($'Очередь {name} начала выполнятся');
    Sleep(delay);
    lock output do Writeln($'Очередь {name} выполнилась');
  end)+M, M);
end;

end.