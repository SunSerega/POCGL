program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

begin
  try
    var text := System.Windows.Forms.Clipboard.GetText;
    
    var all_lns := text.Remove(#13).ToWords(#10);
    var lns := all_lns.Where(l->l.StartsWith('#define')).Select(l->
    begin
      
      var ind1 := l.IndexOf(' ')+1;
      var ind2 := l.IndexOf(' ', ind1);
      
      var val := l.Split(new char[](' '), 3, System.StringSplitOptions.RemoveEmptyEntries)[2].Replace('<<','shl').Replace('0x','$');
      if val.Contains('//') then val := val.Remove(val.IndexOf('//'));
      if val.Contains('/*') then val := val.Remove(val.IndexOf('/*'));
      
      Result := (
        l.Substring(ind1, ind2-ind1) + ': ',
        val.Trim(' ', '(', ')'),
        ''
      );
    end).ToArray;
    
    var TName := all_lns.SingleOrDefault(l->l.StartsWith('%'));
    TName := TName=nil?'_____':TName.Substring(1);
    
    var same_letters_sb := new StringBuilder;
    if lns.Length>1 then
      for var _i := 0 to lns.Max(l->l[0].Length)-1 do
      begin
        var i := _i;
        
        var m :=
          lns.Select(t->t[0]).Select(l->i<l.Length?l[i+1]:#0)
          .GroupBy( ch->ch, ch->ch, (ch,sq)->(ch,sq.Count) )
          .MaxBy(t->t[1]);
        
        if m[1] / lns.Length < 0.8 then break else
          same_letters_sb += m[0];
      end;
    var same_letters := same_letters_sb.ToString;
    lns := lns.ConvertAll(l->( l[0].StartsWith(same_letters)?l[0].Substring(same_letters.Length):l[0], l[1], '' ));
    
    
    var max_name_l := lns.Max(l->l[0].Length);
    if max_name_l.IsEven then max_name_l += 1;
    lns := lns.ConvertAll(l->( l[0].PadRight(max_name_l) , l[1], l[0].Remove(l[0].Length-2) ));
    
    var res := new StringBuilder;
    res += #10;
    
    
    
    var val_t_name: string;
    
    res += $'  //S'+#10;
    res += $'  {TName} = record'+#10;
    val_t_name := 'UInt32';
    
    res += $'    public val: {val_t_name};{#10}';
    res += $'    public constructor(val: {val_t_name}) := self.val := val;{#10}';
//    res += $'    public constructor(val: int64) := self.val := val;{#10}';
    
    res += '    '#10;
    
    
    
    foreach var l in lns do
      res += $'    public static property {l[0]}{TName} read new {TName}({l[1]});{#10}';
    
    res += '    '#10;
    
    foreach var l in lns do
      res += $'    public property IS_{l[0]}boolean read self = {TName}.{l[2]};{#10}';
    
    res += '    '#10;
    
    foreach var l in lns do
      res += $'    public property {l[0]}boolean read self.val = {l[1]};{#10}';
    
    res += '    '#10;
    
    foreach var l in lns do
      res += $'    public property {l[0]}boolean read self and ({l[1]}) <> 0;{#10}';
    
    res += '    '#10;
    
    
    
    res +=  '    // IS_'#10;
    res +=  '    public function ToString: string; override;'#10;
    res +=  '    begin'#10;
    res += $'      var res := typeof({TName}).GetProperties.Where(prop->prop.PropertyType=typeof(boolean)).Select(prop->(prop.Name,boolean(prop.GetValue(self)))).FirstOrDefault(t->t[1]);'+#10;
    res +=  '      Result := res=nil?'#10;
    res += $'        $''{TName}[{{self.val}}]'':'+#10;
    res +=  '        res[0].Substring(3);'#10;
    res +=  '    end;'#10;
    
    res += '    '#10;
    
    res +=  '    // Flags'#10;
    res +=  '    public function ToString: string; override;'#10;
    res +=  '    begin'#10;
    res += $'      var res := typeof({TName}).GetProperties.Select(prop->(prop.Name,boolean(prop.GetValue(self)))).Where(t->t[1]).Select(t->t[0]).ToArray;'+#10;
    res +=  '      Result := res.Length=0?'#10;
    res += $'        $''{TName}[{{self.val}}]'':'+#10;
    res +=  '        res.JoinIntoString(''+'');'#10;
    res +=  '    end;'#10;
    
    
    
    res += '    '#10;
    res += '  end;'#10;
    res += '  ';
    
    System.Windows.Forms.Clipboard.SetText(res.ToString.Replace(#10,#13#10));
    System.Console.Beep;
  except
    on e: Exception do
    begin
      writeln(e);
      if not CommandLineArgs.Contains('SecondaryProc') then Readln;
    end;
  end;
end.