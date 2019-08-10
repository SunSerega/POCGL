program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

uses BinSpecData in '..\Data scrappers\BinSpecData.pas';

function RemoveFuncNameExt(self: string): string; extensionmethod;
begin
  var i := self.Length;
  while self[i].IsUpper do i -= 1;
  Result := self.Substring(0,i);
end;

function TakeFuncNameExt(self: string): string; extensionmethod;
begin
  var i := self.Length;
  while self[i].IsUpper do i -= 1;
  Result := self.Remove(0,i);
end;

type
  ListSeqEqualityComparer = class(System.Collections.Generic.EqualityComparer<List<string>>)
    
    public function Equals(x, y: List<string>): boolean; override;
    begin
      Result := x.SequenceEqual(y);
    end;
    
    public function GetHashCode(obj: List<string>): integer; override :=
    obj.Count=0?0:obj[0].GetHashCode;
    
  end;
  
  FuncNameEqualityComparer = class(System.Collections.Generic.EqualityComparer<string>)
    
    public function Equals(x, y: string): boolean; override :=
    x.RemoveFuncNameExt = y.RemoveFuncNameExt;
    
    public function GetHashCode(obj: string): integer; override :=
    obj.RemoveFuncNameExt.GetHashCode;
    
  end;
  
function DistinctBy<T1,T2>(self: sequence of T1; selector: T1->T2): sequence of T1; extensionmethod;
begin
  var prev := new HashSet<T2>;
  foreach var a in self do
    if prev.Add(selector(a)) then
      yield a;
end;

const
  
//  GLpas = 'Temp.pas';
  GLpas = 'OpenGL.pas';
  
//  HeadersFolder = 'D:\0\Temp';
//  HeadersFolder = 'C:\Users\Master in EngLiSH\Desktop\GL .h';
  HeadersFolder = 'C:\Users\Master in EngLiSH\Desktop\OpenGL-Registry';
  
  BrokenHeadersFolder = 'Data scrappers\BrokenSource';
  
begin
  try
    System.Environment.CurrentDirectory := System.IO.Path.GetDirectoryName(System.Environment.CurrentDirectory);
    
    {$region Read used funcs}
    writeln('Read used funcs');
    
    var used_funcs: HashSet<string> :=
      ReadAllText(GLpas)
      .Remove(#13)
      .Split(#10)
      .SkipWhile(l->not l.Contains('gl = static class'))
      .TakeWhile(l->not l.Contains('end;'))
      .Select(l->l.Contains('//')?l.Remove(l.IndexOf('//')):l)
      .Select(l->
      begin
        if l.Contains('procedure') then Result := l.Substring(l.IndexOf('procedure')+'procedure'.Length) else
        if l.Contains('function' ) then Result := l.Substring(l.IndexOf('function' )+'function' .Length) else
          Result := '';
      end)
      .Where(l->l<>'')
      .Select(l->
      begin
        if l.Contains('(') then Result := l.Remove(l.IndexOf('(')) else
        if l.Contains(':') then Result := l.Remove(l.IndexOf(':')) else
        if l.Contains(';') then Result := l.Remove(l.IndexOf(';')) else
          raise new System.InvalidOperationException($'"{l}"');
      end)
      .Select(l->l.Trim(' '))
      .ToHashSet
    ;
    
    {$endregion Read used funcs}
    
    {$region Read funcs from .h's}
    writeln('Read funcs from .h''s');
    
    // including used
    var all_funcs := new HashSet<string>;
    
    foreach var fname in
      System.IO.Directory.EnumerateFiles(HeadersFolder, '*.h', System.IO.SearchOption.AllDirectories) +
      System.IO.Directory.EnumerateFiles(BrokenHeadersFolder, '*.h', System.IO.SearchOption.AllDirectories)
    do
    begin
      writeln(fname);
      System.Windows.Forms.Clipboard.SetText(ReadAllText(fname));
      System.Diagnostics.Process.Start('Text converters\gl format func.exe').WaitForExit;
      
      var text := System.Windows.Forms.Clipboard.GetText.Remove(#13).Trim(#10' '.ToArray);
      if text='' then continue;
      
      all_funcs +=
        ('    ' + text)
        .Split(Arr(#10'    '#10), System.StringSplitOptions.RemoveEmptyEntries)
      ;
      
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
      .Where(f->not used_funcs.Contains(f[1]))
      .DistinctBy(f->f[1].RemoveFuncNameExt)
      .OrderBy(f->f[1])
      .ToList
    ;
    
    {$endregion Tabulate all funcs with name (and delete used)}
    
    {$region Find ext types}
    writeln('Find ext types');
    
    var ext_types: List<string> :=
      funcs_data
      .Select(t->t[1])
      .Select(s->s.TakeFuncNameExt)
      .Where(s->not (s in ['', 'D', 'A', 'W', 'CMAAINTEL', 'IDEXT', 'DEXT', 'DARB', 'DOES', 'GPUIDAMD', 'DC', 'DCARB', 'DCEXT', 'DCNV', 'DFX', 'DINTEL', 'DL', 'DSGIS']))
      .Distinct
      .ToList
    ;
    
//    ext_types.Sorted.PrintLines;
//    exit;
    
    {$endregion Find ext types}
    
    {$region construct func name tables}
    writeln('construct func name tables');
    var ext_spec_db := BinSpecDB.LoadFromFile('Data scrappers\gl ext spec.bin');
    
    var func_name_ext_name_table := new Dictionary<string, List<string>>(new FuncNameEqualityComparer);
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
    
    {$endregion construct construct func name tables}
    
    {$region Sort by ext names}
    writeln('Sort by ext name');
    
    // ext_name (or string[0]) => (func_text, func_name)
    var funcs_by_ext_name := new Dictionary<List<string>, List<(string,string)>>(new ListSeqEqualityComparer);
    funcs_by_ext_name[new List<string>] := new List<(string,string)>;
    
    var unused_exts := new HashSet<List<string>>(func_name_ext_name_table.Values, new ListSeqEqualityComparer);
    
    while funcs_data.Count<>0 do
    begin
      
      var ext_names: List<string>;
      var fn1 := funcs_data[0][1];
      if func_name_ext_name_table.TryGetValue(fn1, ext_names) then
      begin
        var fs := new List<(string,string)>;
        
        foreach var fn in ext_name_func_name_table[ext_names] do
        begin
          var ind := funcs_data.FindIndex(f->f[1].RemoveFuncNameExt=fn.RemoveFuncNameExt);
          if ind <> -1 then
          begin
            fs += funcs_data[ind];
            funcs_data.RemoveAt(ind);
          end else
          if not used_funcs.Contains(fn) then
            writeln($'"{fn1}": can''t find func "{fn}" from "{ext_names.JoinIntoString}"');
        end;
        
//        writeln(ext_names, fs.Select(f->f[1]));
        if funcs_by_ext_name.ContainsKey(ext_names) then
          raise new System.InvalidOperationException($'key = [{ext_names.JoinIntoString}], val1 = [{funcs_by_ext_name[ext_names].Select(f->f[1]).JoinIntoString}], val2 = [{fs.Select(f->f[1]).JoinIntoString}]') else
          funcs_by_ext_name.Add(ext_names, fs);
        unused_exts.Remove(ext_names);
      end else
      begin
        funcs_by_ext_name[new List<string>].Add(funcs_data[0]);
        funcs_data.RemoveAt(0);
      end;
      
    end;
    
    foreach var ext in unused_exts do
    begin
      var fs := ext_name_func_name_table[ext].ToList;
      fs.RemoveAll(f->used_funcs.Contains(f));
      if fs.Count=0 then continue;
      writeln($'[{ext.JoinIntoString}]: funcs [{fs.JoinIntoString}] wasn''t found');
    end;
    
    {$endregion Sort by ext names}
    
    {$region Then sort by ext type}
    writeln('Then sort by ext type');
    
    // class name => ext names (or string[0]) => (func_text, func_name)
    var funcs_sorted := new Dictionary<string, Dictionary<List<string>, List<(string,string)>>>;
    
    foreach var ext_names in funcs_by_ext_name.Keys do
    begin
      var ofs := funcs_by_ext_name[ext_names];
      
      foreach var fs in ext_names.Count=0 ? ofs.Select(f->Lst&<(string,string)>(f)) : Seq&<List<(string,string)>>(ofs) do
      begin
        
        var t_name: string;
        if fs.Any(f->f[0].Contains('gdi')) then
          t_name := 'gdi' else
        if fs.Any(f->f[0].Contains('wgl')) then
          t_name := 'wgl' else
        if fs.Any(f->f[0].Contains('egl')) then
          t_name := 'egl' else
        if fs.Any(f->f[0].Contains('glu')) then
          t_name := 'glu' else
        if fs.Any(f->f[0].Contains('glX')) then
          t_name := 'glX' else
        begin
          var ext_ts := fs.Select(f->
          begin
            var ext_ts := ext_types.Where(ext_t->f[1].EndsWith(ext_t)).ToList;
            if ext_ts.Count>1 then raise new System.ArgumentException($'func {f[1]} had multiple ext types: {ext_ts.JoinIntoString}');
            Result := ext_ts.Count=0?'':ext_ts[0];
          end).Where(ext_t->ext_t<>'').Distinct.ToList;
          
          if ext_ts.Count=0 then
            t_name := 'gl_Deprecated' else
          if ext_ts.Count=1 then
            t_name := 'gl_'+ext_ts[0] else
          if ext_ts.Contains('gl_EXT') then
            t_name := 'gl_EXT' else
            t_name := 'gl_ARB';
          
        end;
        
        if not funcs_sorted.ContainsKey(t_name) then funcs_sorted[t_name] := new Dictionary<List<string>, List<(string,string)>>(new ListSeqEqualityComparer);
        
        if not funcs_sorted[t_name].ContainsKey(ext_names) then
          funcs_sorted[t_name][ext_names] := fs else
        if ext_names.Count=0 then
          funcs_sorted[t_name][ext_names].AddRange(fs) else
          raise new System.ArgumentException($'funcs "{fs.JoinIntoString}" are already added to {t_name} : ({ext_names.JoinIntoString})');
      end;
      
    end;
    
    {$endregion Then sort by ext type}
    
    {$region contruct new code}
    writeln('contruct new code');
    
    var res := new StringBuilder;
    
    res += #10;
    res += '  {$region Auto translated}'#10;
    res += '  ';
    
    foreach var kvp1 in funcs_sorted.OrderBy(kvp->
    begin
      case kvp.Key of
        'gl_Deprecated':  Result := 01;
        'wgl':            Result := 02;
        'egl':            Result := 03;
        'glu':            Result := 04;
        'glX':            Result := 05;
        'gl_ARB':         Result := 06;
        'gl_EXT':         Result := 07;
        
        'gdi':            Result := 21;
        
        else              Result := 10;
      end;
    end).ThenBy(kvp->kvp.Key) do
    begin
      res += #10;
      
//      if kvp1.Key='gdi' then
//      begin
//        
//        res += 'implementation'#10;
//        res += #10;
//        res += 'type'#10;
//        
//      end;
      
      res += '  ';
      res += kvp1.Key;
      res += ' = static class'#10;
      
      res += '    ';
      
      foreach var kvp2 in kvp1.Value.OrderBy(kvp->kvp.Key.Count).ThenBy(kvp->kvp.Key.FirstOrDefault) do
      begin
        res += #10;
        
        var reg_name := kvp2.Key.Count=0 ? 'Unsorted' : kvp2.Key.JoinIntoString(', ');
        res += $'    {{$region {reg_name}}}' + #10;
        
        res += '    '#10;
        
        res += kvp2.Value.Select(f->f[0]).JoinIntoString(#10'    '#10);
        
        res += #10;
        res += '    '#10;
        
        res += $'    {{$endregion {reg_name}}}' + #10;
        
        res += '    ';
      end;
      
      res += #10;
      
      res += '  end;'#10;
      
      res += '  ';
    end;
    
    res += #10;
    res += '  {$endregion Auto translated}'#10;
    res += '  ';
    
    {$endregion contruct new code}
    
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