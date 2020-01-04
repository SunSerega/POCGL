var cq := q as ConstQueue<integer>;
if cq=nil then
  Writeln('Очередь не константная') else
  Writeln($'Очередь была создана из значения {cq.Val}');