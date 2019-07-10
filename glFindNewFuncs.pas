program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

function SkipCharsFromTo(self: sequence of char; f,t: string): sequence of char; extensionmethod;
begin
  var enm := self.GetEnumerator;
  enm.MoveNext;
  var q := new Queue<char>;
  
  while true do
  begin
    while q.Count<f.Length do
    begin
      q += enm.Current;
      if not enm.MoveNext then
      begin
        yield sequence q;
        exit;
      end;
    end;
    
    if q.SequenceEqual(f) then
    begin
      q.Clear;
      
      while true do
      begin
        while q.Count<t.Length do
        begin
          q += enm.Current;
          if not enm.MoveNext then exit;
        end;
        
        if q.SequenceEqual(t) then
          break else
          q.Dequeue;
        
      end;
      
      q.Clear;
    end else
      yield q.Dequeue;
    
  end;
  
  yield sequence q;
end;

function TakeCharsFromTo(self: sequence of char; fa,ta: array of string): sequence of array of char; extensionmethod;
begin
  var enm := self.GetEnumerator;
  enm.MoveNext;
  var q := new Queue<char>;
  var res := new List<char>;
  
  while true do
  begin
    while q.Count<fa.Max(f->f.Length) do
    begin
      q += enm.Current;
      if not enm.MoveNext then exit;
    end;
    
    if fa.Any(f->q.Take(f.Length).SequenceEqual(f)) then
    begin
      q.Clear;
      
      while true do
      begin
        while q.Count<ta.Max(t->t.Length) do
        begin
          q += enm.Current;
          if not enm.MoveNext then
          begin
            res.AddRange(q);
            yield res.ToArray;
            exit;
          end;
        end;
        
        if ta.Any(t->q.SequenceEqual(t)) then
          break else
          res += q.Dequeue;
        
      end;
      
      yield res.ToArray;
      res.Clear;
      q.Clear;
    end else
      q.Dequeue;
    
  end;
  
end;

const
  GLpas = 'OpenGL.pas';
  HeadersFolder = 'C:\Users\Master in EngLiSH\Desktop\GL .h';
  
begin
  try
    var used_funcs := new HashSet<string>;
    
    var org_glpas_text := ReadAllText(GLpas);
    foreach var chs in
      org_glpas_text
      .SkipCharsFromTo('//',#13)
      .TakeCharsFromTo(
        Arr('procedure', ' function'),
        Arr&<string>('(', #13, #10)
      )
    do
    begin
      var res := string.Create(chs).TrimEnd;
      if not res.EndsWith(';') then res += '(';
      used_funcs += res;
    end;
    
    var res := new StringBuilder;
    foreach var fname in System.IO.Directory.EnumerateFiles(HeadersFolder, '*.h', System.IO.SearchOption.AllDirectories) do
    begin
      System.Windows.Forms.Clipboard.SetText(ReadAllText(fname));
      System.Diagnostics.Process.Start('gl format func.exe').WaitForExit;
      
      var funcs := System.Windows.Forms.Clipboard.GetText.Remove(#13).Split(Arr(#10'    '#10), System.StringSplitOptions.None).ToList;
      funcs.RemoveAll(f->not used_funcs.Any(uf->f.Contains(uf)));
      if funcs.Count=0 then continue;
      
      res += #10;
      res += $'  {System.IO.Path.GetFileNameWithoutExtension(fname)} = static class' + #10;
      res += $'    ';
      res += funcs.JoinIntoString(#10'    '#10);
      res += $'    ' + #10;
      res += $'  end;' + #10;
      res += $'  ';
      
    end;
    
    System.Windows.Forms.Clipboard.SetText(res.ToString.Replace(#10,#13#10));
    System.Console.Beep(5000,1000);
    
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
    end;
  end;
end.