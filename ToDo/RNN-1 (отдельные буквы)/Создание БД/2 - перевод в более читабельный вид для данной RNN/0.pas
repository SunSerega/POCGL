begin
  
  writeln('читаю бд');
  
  var br := new System.IO.BinaryReader(System.IO.File.OpenRead('texts.db'));
  var texts: array of string := ArrGen(br.ReadInt32, i->br.ReadString);
  br.Close;
  
  writeln('создаю таблицу символов');
  
  var chs := texts.SelectMany(s->s.AsEnumerable).ToHashSet.ToArray;
  chs.Sort;
  
  if chs.Length>word.MaxValue+1 then raise new System.ArgumentException($'слишком много разных букв - {chs.Length}');
  writeln($'Всего {chs.Length} разных символов');
  
  var table := new Dictionary<char, word>;
  for var i := 0 to chs.Length-1 do
    table.Add(chs[i],i);
  
  writeln('создаю новую бд');
  
  var bd := System.IO.File.Create('res.db');
  var bw := new System.IO.BinaryWriter(bd);
  
  bw.Write(table.Count);
  foreach var kvp in table do
  begin
    bw.Write(word(kvp.Key));
    bw.Write(kvp.Value);
  end;
  
  bw.Write(texts.Length);
  foreach var t in texts do
  begin
    bw.Write(t.Length);
    foreach var ch in t do
      bw.Write(table[ch]);
  end;
  
  bd.Close;
end.