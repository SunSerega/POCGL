program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

begin
  try
    
    var fncs :=
      System.Windows.Forms.Clipboard.GetText
      .Remove(#13)
      .Split(new string[](#10'    '#10), System.StringSplitOptions.RemoveEmptyEntries)
    ;
    System.Windows.Forms.Clipboard.Clear;
    System.Console.Beep;
    while not System.Windows.Forms.Clipboard.ContainsText do Sleep(1000);
    System.Console.Beep(5000,100);
    
    var wrds :=
      System.Windows.Forms.Clipboard.GetText
      .Select(ch-> ch.IsLetter or ch.IsDigit ? ch : ' ' )
      .JoinIntoString
      .ToWords
      .ToHashSet
    ;
    
    System.Console.Beep(5000,100);
    
    var ufncs := new HashSet<string>;
    
    foreach var f in wrds.SelectMany(w->
      fncs.Where(f->
        f.Contains($'procedure {w}(') or
        f.Contains($'function {w}(') or
        f.Contains($'procedure {w};') or
        f.Contains($'function {w};')
      )
    ) do
      ufncs += f;
    
    System.Console.Beep(5000,100);
    
    var res := new StringBuilder;
    
    res += #10;
    res += '    {$region }'#10;
    res += '    '#10;
    res += '    {$region }'#10;
    res += '    '#10;
    res += '    '#10;
    res += '    '#10;
    res += '    {$endregion }'#10;
    res += '    '#10;
    res += '    {$region }'#10;
    res += '    '#10;
    res += '    {$endregion }'#10;
    res += '    '#10;
    res += '    '#10;
    res += '    '#10;
    
    res += ufncs.JoinIntoString(#10'    '#10);
    
    res += #10'    '#10;
    res += '    {$endregion }'#10'    ';
    
    res +=
      fncs
      .Where(f->not ufncs.Contains(f))
      .JoinIntoString(#10'    '#10)
    ;
    
    System.Windows.Forms.Clipboard.SetText(res.ToString);
    System.Console.Beep;
    
  except
    on e: Exception do
    begin
      writeln(e);
      if not CommandLineArgs.Contains('SecondaryProc') then Readln;
    end;
  end;
end.