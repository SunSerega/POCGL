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
    
    var ARB := new HashSet<string>;
    var EXT := new HashSet<string>;
    var KHR := new HashSet<string>;
    var AMD := new HashSet<string>;
    var INTEL := new HashSet<string>;
    var NVIDIA := new HashSet<string>;
    
    foreach var f in fncs.ToArray do
      if f.Contains('ARB') then
      begin
        ARB += f;
        fncs -= f;
      end else
      if f.Contains('EXT') then
      begin
        EXT += f;
        fncs -= f;
      end else
      if f.Contains('KHR') then
      begin
        KHR += f;
        fncs -= f;
      end else
      if f.Contains('AMD') then
      begin
        AMD += f;
        fncs -= f;
      end else
      if f.Contains('INTEL') then
      begin
        INTEL += f;
        fncs -= f;
      end else
      if f.Contains('NV') then
      begin
        NVIDIA += f;
        fncs -= f;
      end;
    
    var res := new StringBuilder;
    
    res += #10;
    res += '    {$region ARB}'#10;
    res += '    '#10;
    
    res += ARB.JoinIntoString(#10'    '#10);
    
    res += #10;
    res += '    '#10;
    res += '    {$endregion ARB}'#10;
    res += '    '#10;
    res += '    {$region EXT}'#10;
    res += '    '#10;
    
    res += EXT.JoinIntoString(#10'    '#10);
    
    res += #10;
    res += '    '#10;
    res += '    {$endregion EXT}'#10;
    res += '    '#10;
    res += '    {$region KHR}'#10;
    res += '    '#10;
    
    res += KHR.JoinIntoString(#10'    '#10);
    
    res += #10;
    res += '    '#10;
    res += '    {$endregion KHR}'#10;
    res += '    '#10;
    res += '    {$region AMD}'#10;
    res += '    '#10;
    
    res += AMD.JoinIntoString(#10'    '#10);
    
    res += #10;
    res += '    '#10;
    res += '    {$endregion AMD}'#10;
    res += '    '#10;
    res += '    {$region INTEL}'#10;
    res += '    '#10;
    
    res += INTEL.JoinIntoString(#10'    '#10);
    
    res += #10;
    res += '    '#10;
    res += '    {$endregion INTEL}'#10;
    res += '    '#10;
    res += '    {$region NVIDIA}'#10;
    res += '    '#10;
    
    res += NVIDIA.JoinIntoString(#10'    '#10);
    
    res += #10;
    res += '    '#10;
    res += '    {$endregion NVIDIA}'#10;
    res += '    ';
    
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