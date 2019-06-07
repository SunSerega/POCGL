function SplitNulls(self: sequence of string): sequence of string; extensionmethod;
begin
  var res := new StringBuilder;
  
  foreach var l in self do
    if l=nil then
    begin
      if res.Length<>0 then yield res.ToString;
      res.Clear;
    end else
      if res.Length<>0 then
      begin
        res += ' ';
        res += l;
      end else
        res += l;
  
end;

begin
  var texts :=
    System.IO.Directory.EnumerateFiles('files')
    .SelectMany(f->ReadLines(f.Println, System.Text.Encoding.UTF8) + Arr(string(nil)))
    .Select(l->
      (l<>nil) and
      '.?!—:'.Any(ch->l.Contains(ch))
      ?l:nil
    )
    .SplitNulls
    .ToList;
  
  var db := System.IO.File.Create('res.db');
  var bw := new System.IO.BinaryWriter(db);
  
  bw.Write(texts.Count);
  foreach var l in texts do
    bw.Write(l.Trim);
  
  db.Close;
end.