uses FuncData in '..\FuncData.pas';
uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

begin
  try
    InitAll;
    
    Otp($'Reading .bin');
    LoadBin;
    
    Otp($'Fixing all');
    ApplyFixers;
    Feature.FixGL_GDI;
    
    Otp($'Constructing enums code');
    var res := new StringBuilder;
    res += '  '#10;
    res += '  '#10;
    res += '  '#10;
    Group.WriteAll(res);
    res += '  '#10;
    res += '  ';
    WriteAllText(GetFullPath('..\Enums.template', GetEXEFileName), res.ToString);
    res.Clear;
    
    Otp($'Constructing funcs code');
    res += '  '#10;
    res += '  '#10;
    res += '  '#10;
    Feature.WriteAll(res);
    Extension.WriteAll(res);
    res += '  '#10;
    res += '  ';
    WriteAllText(GetFullPath('..\Funcs.template', GetEXEFileName), res.ToString);
    res.Clear;
    
    FinishAll;
    if not CommandLineArgs.Contains('SecondaryProc') then ReadString('done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.