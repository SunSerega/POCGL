program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

begin
  try
    
    var fncs :=
      System.Windows.Forms.Clipboard.GetText
      .Remove(#13)
      .Split(new string[](#10'    '#10), System.StringSplitOptions.RemoveEmptyEntries)
      .ToHashSet
    ;
    
    var table := Dict(
      ('ARB',     'ARB'),
      ('EXT',     'EXT'),
      ('KHR',     'KHR'),
      ('AMD',     'AMD'),
      ('INTEL',   'INTEL'),
      ('NV',      'NVIDIA'),
      ('SUN',     'SUN'),
      ('OES',     'OES'),
      ('APPLE',   'APPLE'),
      ('ATI',     'ATI'),
      ('GREMEDY', 'GREMEDY'),
      ('HP',      'HP'),
      ('IBM',     'IBM'),
      ('INGR',    'INGR'),
      ('MESA',    'MESA'),
      ('PGI',     'PGI'),
      ('SGIS',    'SGIS'),
      ('SGIX',    'SGIX'),
      ('SGI',     'SGI')
    );
    var groups := new Dictionary<string, HashSet<string>>;
    foreach var t in table do groups[t.Value] := new HashSet<string>;
    
    foreach var f in fncs.ToArray do
      foreach var t in table do
        if f.Contains(t.Key) then
        begin
          groups[t.Value] += f;
          fncs -= f;
          //break;
        end;
    
    var res := new StringBuilder;
    
    foreach var kvp in groups do
      if kvp.Value.Count<>0 then
      begin
        
        res += #10;
        res += $'    {{$region {kvp.Key}}}'+#10;
        res +=  '    '#10;
        
        res += kvp.Value.JoinIntoString(#10'    '#10);
        
        res += #10;
        res +=  '    '#10;
        res += $'    {{$endregion {kvp.Key}}}'+#10;
        res +=  '    ';
        
      end;
    
    res += fncs.JoinIntoString(#10'    '#10);
    
    System.Windows.Forms.Clipboard.SetText(res.ToString);
    System.Console.Beep;
    
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
    end;
  end;
end.