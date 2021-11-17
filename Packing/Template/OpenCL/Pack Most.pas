uses FuncData in '..\FuncData';
uses POCGL_Utils in '..\..\..\POCGL_Utils';

begin
  try
    InitAll;
    api_name := 'cl';
    
    Otp($'Reading .bin');
    LoadBin('DataScraping\XML\CL\funcs.bin');
    
    Otp($'Fixing all');
    Group.FixCL_Names;
    Feature.FixCL;
    Extension.FixCL;
    ApplyFixers;
    MarkUsed;
    
    var res := new StringBuilder;
    
    Otp($'Constructing structs code');
    res += '  '#10;
    res += '  '#10;
    res += '  '#10;
    Struct.WriteAll(res);
    res += '  '#10;
    res += '  ';
    WriteAllText(GetFullPathRTA('Structs.template'), res.ToString);
    res.Clear;
    
    Otp($'Constructing enums code');
    res += '  '#10;
    res += '  '#10;
    res += '  '#10;
    Group.WriteAll(res);
    res += '  '#10;
    res += '  ';
    WriteAllText(GetFullPathRTA('Groups.template'), res.ToString);
    res.Clear;
    
    Otp($'Constructing funcs code');
    res += '  '#10;
    res += '  '#10;
    res += '  '#10;
    Feature.WriteAll(res, nil);
    Extension.WriteAll(res, nil);
    res += '  '#10;
    res += '  ';
    WriteAllText(GetFullPathRTA('Funcs.template'), res.ToString);
    res.Clear;
    
    FinishAll;
  except
    on e: Exception do ErrOtp(e);
  end;
end.