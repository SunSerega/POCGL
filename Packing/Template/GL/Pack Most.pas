uses FuncData in '..\FuncData.pas';
uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

begin
  try
    InitAll;
    dll_name := 'opengl32.dll';
    
    Otp($'Reading .bin');
    LoadBin('DataScraping\XML\GL\funcs.bin');
    
    Otp($'Fixing all');
    ApplyFixers;
    Feature.FixGL_GDI;
    MarkUsed;
    
    var res := new StringBuilder;
    
    Otp($'Constructing records code');
    res += '  '#10;
    res += '  '#10;
    res += '  '#10;
    Struct.WriteAll(res);
    res += '  '#10;
    res += '  ';
    WriteAllText(GetFullPath('..\Records.template', GetEXEFileName), res.ToString);
    res.Clear;
    
    Otp($'Constructing enums code');
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