uses MtrBase;

procedure AddMtrMlt(res: StringBuilder; t1,t2: t_descr);
begin
  
  var rt := (t1,t2).GetMltResT;
  res += #10;
  
  res +=      $'function operator*(m1: {t1.GetName}; m2: {t2.GetName}): {rt.GetName}; extensionmethod;'+#10;
  res +=      $'begin'+#10;
  for var y := 0 to rt[0][0]-1 do
    for var x := 0 to rt[0][1]-1 do
    begin
      res +=  $'  Result.val{y}{x} := ';
      res +=
        Range(0, t1[0][1]-1)
        .Select(i-> $'m1.val{y}{i}*m2.val{i}{x}' )
        .JoinIntoString(' + ');
      res += ';'#10;
    end;
  res +=      $'end;'+#10;
  
end;

procedure AddTranspose(res: StringBuilder; t: t_descr);
begin
  
  if t[0][0]<=t[0][1] then
    res += #10;
  res += $'function Transpose(self: {t.GetName}); extensionmethod :='+#10;
  res += $'new {t.GetTransposedT.GetName}(';
  res +=
    Range(0,t[0][1]-1)
    .Cartesian(Range(0,t[0][0]-1))
    .Select(pos-> $'self.val{pos[1]}{pos[0]}' )
    .JoinIntoString(', ');
  res += ');'#10;
  
end;

begin
  try
    var res := new StringBuilder;
    
    var t_table: sequence of t_descr :=
      Range(2,4)
      .Cartesian(Range(2,4))
      .SelectMany(sz->
        Arr&<string>('f','d')
        .Select(t->(sz,t,t.gl_to_pas_t))
      ).OrderBy(t->t[0][0]=t[0][1]?integer.MinValue:t[0][0]+t[0][1])
      .OrderByDescending(t->t[1])
      .ToArray
    ;
    
    res += ''#10;
    res += '{$region MtrMlt}'#10;
    
    foreach var t1 in t_table do
      foreach var t2 in t_table do
        if t1[0][1]=t2[0][0] then
          AddMtrMlt(res, t1,t2);
    
    res += ''#10;
    res += '{$endregion MtrMlt}'#10;
    res += ''#10;
    res += '{$region MtrTranspose}'#10;
    
    foreach var t in t_table do
      AddTranspose(res, t);
    
    res += ''#10;
    res += '{$endregion MtrTranspose}'#10;
    res += '';
    
    var farg := CommandLineArgs.Where(arg->arg.StartsWith('fname=')).SingleOrDefault;
    
    if farg<>nil then
      WriteAllText(farg.SubString('fname='.Length), res.ToString, new System.Text.UTF8Encoding(true)) else
    begin
      System.Windows.Forms.Clipboard.SetText(res.ToString.Replace(#10,#13#10));
      System.Console.Beep;
    end;
  except
    on e: Exception do
    begin
      writeln(e);
      if not CommandLineArgs.Contains('SecondaryProc') then Readln;
    end;
  end;
end.