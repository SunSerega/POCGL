uses FuncData;
uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

begin
  try
    InitLog(log, '..\Log\Funcs.log');
    InitLog(log_func_ovrs, '..\Log\FinalFuncOverloads.log');
    var res := new StringBuilder;
    
    loop 3 do log_func_ovrs.WriteLine;
    
    Otp($'Reading .bin');
    var br := new System.IO.BinaryReader(System.IO.File.OpenRead('DataScraping\XML\GL\funcs.bin'));
    var grs :=        ArrGen(br.ReadInt32, i->new Group(br)).ToList;
    var funcs :=      ArrGen(br.ReadInt32, i->new Func(br,grs)).ToList;
    var features :=   ArrGen(br.ReadInt32, i->new Feature(br,funcs)).ToList;
    var extensions := ArrGen(br.ReadInt32, i->new Extension(br,funcs)).ToList;
    if br.BaseStream.Position<>br.BaseStream.Length then raise new System.FormatException;
    
    Otp($'Fixing all');
    GroupFixer.ApplyAll(grs);
    FuncFixer.ApplyAll(funcs);
    
    Otp($'Constructing new code');
    res += '  '#10;
    res += '  '#10;
    res += '  '#10;
    Feature.WriteAll(res);
    res += '  '#10;
    res += '  ';
    
    var ToDo := 0; //ToDo extensions
    Otp($'WARNING: Extension funcs aren''t packed yet');
    
    GroupFixer.WarnAllUnused;
    FuncOrgParam.WarnUnusedTypeTable;
    FuncFixer.WarnAllUnused;
    
    loop 1 do log_func_ovrs.WriteLine;
    
    log.Close;
    log_func_ovrs.Close;
    WriteAllText(GetFullPath('..\Funcs.template', GetEXEFileName), res.ToString);
    if CommandLineArgs.Contains('SecondaryProc') then ReadString('done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.