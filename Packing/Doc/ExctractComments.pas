uses CommentableData;

const fname = 'OpenCLABC';

begin
  var last_comment: StringBuilder;
  
  var cleared := System.IO.File.CreateText(fname+'.cleared.pas');
  var d := new Dictionary<string,string>;
  FindCommentable(
    ReadLines(fname+'.pas'),
    _l->
    begin
      var l := _l.Trim(' ');
      
      if l.StartsWith('///') then
      begin
        if last_comment=nil then last_comment := new StringBuilder;
        last_comment.AppendLine(l.Remove(0,3));
        exit;
      end;
      
      cleared.WriteLine(_l);
      Result := true;
    end,
    c->
    begin
      if last_comment=nil then exit;
      last_comment.Length -= 1;
      d.Add(c, last_comment.ToString);
      last_comment := nil;
    end
  );
  var lst := d.Values.Distinct.ToList;
  
  d.Keys.PrintLines;
  exit;
  
  System.IO.Directory.CreateDirectory(fname);
  
  var lnks := System.IO.File.CreateText(fname+'\lnks.dat');
  var vals := System.IO.File.CreateText(fname+'\vals.dat');
  
  lnks.WriteLine;
  vals.WriteLine;
  
  foreach var name in d.Keys do
  begin
    lnks.Write('# ');
    lnks.WriteLine(name);
    lnks.WriteLine($'%val{lst.IndexOf(d[name])}%');
    lnks.WriteLine;
  end;
  
  for var i := 0 to lst.Count-1 do
  begin
    vals.Write('# val');
    vals.WriteLine(i);
    vals.WriteLine(lst[i]);
  end;
  
  lnks.Close;
  vals.Close;
end.