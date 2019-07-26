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
//  GLpas = 'Temp.pas';
  GLpas = 'OpenGL.pas';
//  HeadersFolder = 'D:\0\Temp';
//  HeadersFolder = 'C:\Users\Master in EngLiSH\Desktop\GL .h';
  HeadersFolder = 'C:\Users\Master in EngLiSH\Desktop\OpenGL-Registry';
  
begin
  try
    var used_funcs := new HashSet<string>;
    
    var org_glpas_text := ReadAllText(GLpas);
    foreach var chs in
      org_glpas_text
      .Remove(#13)
      .SkipCharsFromTo('//',#10)
      .TakeCharsFromTo(
        Arr('procedure', ' function'),
        Arr&<string>('(', ':', ';')
      )
    do
    begin
      if chs.Length<5 then continue;
      var res := string.Create(chs).TrimEnd;
      if not res.EndsWith(';') then res += '(';
      used_funcs += res;
    end;
    
    var all_funcs := new HashSet<string>;
    
    foreach var fname in System.IO.Directory.EnumerateFiles(HeadersFolder, '*.h', System.IO.SearchOption.AllDirectories) do
    begin
      writeln(fname);
      System.Windows.Forms.Clipboard.SetText(ReadAllText(fname));
      System.Diagnostics.Process.Start('gl format func.exe').WaitForExit;
      
      var text := System.Windows.Forms.Clipboard.GetText.Remove(#13).Trim(#10' '.ToArray);
      if text='' then continue;
      
      all_funcs +=
        ('    ' + text)
        .Split(Arr(#10'    '#10), System.StringSplitOptions.RemoveEmptyEntries)
        .Where(f->not used_funcs.Any(uf->f.Contains(uf)))
      ;
      
//      if funcs.Count=0 then continue;
//      
//      res += #10;
//      res += $'  {System.IO.Path.GetFileNameWithoutExtension(fname)} = static class' + #10;
//      res += $'    ' + #10;
//      res += funcs.JoinIntoString(#10'    '#10);
//      res += #10;
//      res += $'    ' + #10;
//      res += $'  end;' + #10;
//      res += $'  ';
      
    end;
    
    var funcs_data :=
      all_funcs.Tabulate(f->
      begin
        
        var ind := f.IndexOf('procedure');
        if ind=-1 then ind := f.IndexOf('function');
        ind := f.IndexOf(' ', ind)+1;
        
        var ind2 := f.IndexOf('(');
        if ind2=-1 then ind2 := f.IndexOf(':');
        if ind2=-1 then ind2 := f.IndexOf(';');
        
        Result := f.Substring(ind, ind2-ind);
      end)
      .OrderBy(t->t[1])
      .ToList;
    
    var ext_types :=
      funcs_data
      .Select(t->t[1])
      .Select(s->s.Reverse.TakeWhile(ch->ch.IsUpper).Reverse.JoinIntoString(''))
      .Where(s->not (s in ['', 'D', 'A', 'W', 'CMAAINTEL', 'DEXT', 'DARB', 'DOES', 'GPUIDAMD', 'DC', 'DCARB', 'DCEXT', 'DCNV', 'DFX', 'DINTEL', 'DL', 'DSGIS']))
      .Distinct
      .ToList;
    ext_types += '';
    
    var funcs_by_ext_type := new Dictionary<string, List<(string,string)>>;
    foreach var t in funcs_data do
    begin
      var ext_t := ext_types.Single(ext_t->t[1].EndsWith(ext_t));
      if not funcs_by_ext_type.ContainsKey(ext_t) then funcs_by_ext_type[ext_t] := new List<(string,string)>;
      funcs_by_ext_type[ext_t] += t;
    end;
    
    var funcs_sorted := new Dictionary<string, Dictionary<string, (string,string)>>;
    foreach var ext_t in funcs_by_ext_type.Keys do
    begin
      var funcs_by_ext := new Dictionary<string, (string,string)>;
      
      foreach var t in funcs_by_ext_type[ext_t] do
      begin
        
      end;
      
      funcs_sorted[ext_t] := funcs_by_ext;
    end;
    
//    foreach var f in all_funcs do
//    begin
//      for var n := f.Length downto 2 do
//        if all_funcs.Any(f2-> (f2<>f) and f2.
//      begin
//        
//      end;
//    end;
    
    
    
    
    
    
    
    
    
    
    
    var res := new StringBuilder;
    
    res += #10 + funcs_data.Select(t->t[0]).JoinIntoString(#10'    '#10) + #10'    ';
//    res += funcs_data.Select(t->t[1]).JoinIntoString(#10);
//    res += ext_types.Sorted.JoinIntoString(#10);
//    res += funcs_data.Select(t->t[1]).Where(s->s.EndsWith('A')).JoinIntoString(#10);
    
    writeln('done');
    if res.Length<>0 then
    begin
      System.Windows.Forms.Clipboard.SetText(res.ToString.Replace(#10,#13#10));
      System.Console.Beep(5000,1000);
    end else
    begin
      System.Windows.Forms.Clipboard.Clear;
      System.Console.Beep(3000,1000);
    end;
    
    readln;
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
    end;
  end;
end.