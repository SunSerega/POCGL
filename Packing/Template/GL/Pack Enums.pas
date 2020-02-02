uses FuncData;
uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

begin
  try
    InitLog(log, '..\Log\Enums.log');
    var res := new StringBuilder;
    
    Otp($'Reading groups');
    var br := new System.IO.BinaryReader(System.IO.File.OpenRead('DataScraping\XML\GL\funcs.bin'));
    var grs := ArrGen(br.ReadInt32, i->new Group(br)).ToList;
    
    Otp($'Fixing groups');
    GroupFixer.ApplyAll(grs);
    
    Otp($'Constructing new code');
    res += '  '#10;
    res += '  '#10;
    res += '  '#10;
    foreach var g in grs.GroupBy(gr->gr.ext_name).OrderBy(g->
    begin
      case g.Key of
        '':     Result := 0;
        'ARB':  Result := 1;
        'EXT':  Result := 2;
        else    Result := 3;
      end;
    end).ThenBy(g->g.Key) do
    begin
      var gn := g.Key;
      if gn='' then gn := 'Core';
      
      res += $'  {{$region {gn}}}'+#10;
      res += $'  '+#10;
      
      foreach var gr in g.OrderBy(gr->gr.name) do
        gr.Write(res);
      
      res += $'  {{$endregion {gn}}}'+#10;
      res += $'  '+#10;
    end;
    res += '  '#10;
    res += '  ';
    
    GroupFixer.WarnAllUnused;
    log.Close;
    WriteAllText(GetFullPath('..\Enums.template', GetEXEFileName), res.ToString);
    if not CommandLineArgs.Contains('SecondaryProc') then ReadString('done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.