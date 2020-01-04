var cq := q as IConstQueue;
if cq=nil then
  Writeln('Очередь не константная') else
  Writeln($'Очередь была создана из значения ({cq.GetConstVal})');