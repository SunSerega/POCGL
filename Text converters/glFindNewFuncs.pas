program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

uses BinSpecData in 'Data scrappers\BinSpecData.pas';

type
  ListSeqEqualityComparer = class(System.Collections.Generic.EqualityComparer<List<string>>)
    
    public function Equals(x, y: List<string>): boolean; override;
    begin
      Result := x.SequenceEqual(y);
    end;
    
    public function GetHashCode(obj: List<string>): integer; override :=
    obj.Count=0?0:obj[0].GetHashCode;
    
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
    
    {$region Read used funcs}
    writeln('Read used funcs');
    
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
    
    {$endregion Read used funcs}
    
    {$region construct func name tables}
    writeln('construct func name tables');
    
    var func_name_ext_name_table := new Dictionary<string, List<string>>;
    
    var ext_spec_db := BinSpecDB.LoadFromFile('Data scrappers\gl ext spec.bin');
    foreach var ext in ext_spec_db.exts do
      if ext.NewFuncs<>nil then
        foreach var func in ext.NewFuncs.funcs do
        begin
          if not func_name_ext_name_table.ContainsKey(func[0]) then
            func_name_ext_name_table[func[0]] := new List<string> else
//            writeln($'func {func[0]} was defined in multiple exts')
          ;
          func_name_ext_name_table[func[0]].AddRange(ext.ExtNames.names);
        end;
    
    var ext_name_func_name_table := new Dictionary<List<string>, HashSet<string>>(new ListSeqEqualityComparer);
    
    foreach var key in func_name_ext_name_table.Keys do
    begin
      var val := func_name_ext_name_table[key];
      if not ext_name_func_name_table.ContainsKey(val) then
        ext_name_func_name_table[val] := new HashSet<string>;
      ext_name_func_name_table[val].Add(key);
    end;
    ext_name_func_name_table.Add(new List<string>, new HashSet<string>);
    
    {$endregion construct [ name => ext_str ] table}
    
    {$region Read funcs from .h's}
    writeln('Read funcs from .h''s');
    
    // including used
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
    
    {$endregion Read funcs from .h's}
    
    {$region Tabulate all funcs with name (and delete used)}
    writeln('Tabulate all funcs with name (and delete used)');
    
    // (text, name)
    var funcs_data: List<(string,string)> :=
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
      .Where(t->not used_funcs.Contains(t[1]))
      .OrderBy(t->t[1])
      .ToList;
    
    {$endregion Tabulate all funcs with name (and delete used)}
    
    {$region Find ext types}
    writeln('Find ext types');
    
    var ext_types: List<string> :=
      funcs_data
      .Select(t->t[1])
      .Select(s->s.Reverse.TakeWhile(ch->ch.IsUpper).Reverse.JoinIntoString(''))
      .Where(s->not (s in ['', 'D', 'A', 'W', 'CMAAINTEL', 'DEXT', 'DARB', 'DOES', 'GPUIDAMD', 'DC', 'DCARB', 'DCEXT', 'DCNV', 'DFX', 'DINTEL', 'DL', 'DSGIS']))
      .Distinct
      .ToList;
    
    {$endregion Find ext types}
    
    {$region Sort by ext type}
    writeln('Sort by ext type');
    
    // ext_type (or nil) => (func_text, func_name)
    var funcs_by_ext_type := new Dictionary<string, List<(string,string)>>;
    
    foreach var t in funcs_data do
    begin
      var ext_ts := ext_types.Where(ext_t->t[1].EndsWith(ext_t)).ToList;
      if ext_ts.Count>1 then raise new System.ArgumentException($'func {t[1]} had multiple ext types: {ext_ts.JoinIntoString}');
      var ext_t := ext_ts.SingleOrDefault;
      if ext_t=nil then ext_t := '';
      if not funcs_by_ext_type.ContainsKey(ext_t) then funcs_by_ext_type[ext_t] := new List<(string,string)>;
      funcs_by_ext_type[ext_t].Add(t);
    end;
    
    {$endregion Sort by ext type}
    
    {$region Then sort by ext string}
    writeln('Then sort by ext string');
    
    // ext_type (or nil) => ext names => (func_text, func_name)
    var funcs_sorted := new Dictionary<string, Dictionary<List<string>, List<(string,string)>>>;
    
    foreach var ext_t in funcs_by_ext_type.Keys do
    begin
      var funcs_by_ext := new Dictionary<List<string>, List<(string,string)>>;
      
      var l := funcs_by_ext_type[ext_t].ToList;
      while l.Count>0 do
      begin
        var funcs := Lst(l[l.Count-1]);
        l.RemoveLast;
        
        var ext_names: List<string>;
        if not func_name_ext_name_table.TryGetValue(funcs[0][1], ext_names) then
          ext_names := new List<string>;
        var ext_funcs := ext_name_func_name_table[ext_names];
        
        foreach var fn in ext_funcs do
          if fn<>funcs[0][1] then
          begin
            var ind := l.FindIndex(f->f[1]=fn);
            if ind=-1 then writeln($'"{funcs[0][1]}": can''t find func "{fn}" from "{ext_names.JoinIntoString}"') else
            begin
              funcs += l[ind];
              l.RemoveAt(ind);
            end;
          end;
        
        funcs_by_ext.Add(ext_names, funcs);
      end;
      
      funcs_sorted[ext_t] := funcs_by_ext;
    end;
    
    {$endregion Then sort by ext string}
    
    
    
    
    
    
    
    
    
    var res := new StringBuilder;
    
    foreach var kvp1 in funcs_sorted.OrderBy(kvp->kvp.Key) do
    begin
      res += #10;
      
      res += '  gl_';
      if kvp1.Key='' then
        res += 'Deprecated' else
        res += kvp1.Key;
      res += ' = static class'#10;
      
      res += '    ';
      
      foreach var kvp2 in kvp1.Value.OrderBy(kvp->kvp.Key.Count).ThenBy(kvp->kvp.Key.FirstOrDefault) do
      begin
        res += #10;
        
        var reg_name := kvp2.Key.Count=0 ? 'Unsorted' : kvp2.Key.JoinIntoString(', ');
        res += $'    {{$region {reg_name}}}' + #10;
        
        res += '    ';
        
        foreach var f in kvp2.Value do
          res += f[0];
        
        res += #10;
        
        res += $'    {{$endregion {reg_name}}}' + #10;
        
        res += '    ';
      end;
      
      res += #10;
      
      res += '  end;'#10;
      
      res += '  ';
    end;
    
    
    
    
//    res += #10 + funcs_data.Select(t->t[0]).JoinIntoString(#10'    '#10) + #10'    ';
//    res += funcs_data.Select(t->t[1]).JoinIntoString(#10);
//    res += ext_types.Sorted.JoinIntoString(#10);
//    res += ext_name_func_name_table.OrderBy(kvp->kvp.Key.Count).ThenBy(kvp->kvp.Key[0]).Select(kvp->$'{kvp.Key.JoinIntoString} : {kvp.Value.JoinIntoString}').JoinIntoString(#10);
    
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