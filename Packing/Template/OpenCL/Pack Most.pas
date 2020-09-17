uses FuncData in '..\FuncData';
uses POCGL_Utils in '..\..\..\POCGL_Utils';

begin
  try
    InitAll;
    dll_name := 'opencl.dll';
    
    Otp($'Reading .bin');
    LoadBin('DataScraping\XML\CL\funcs.bin');
    
    Otp($'Fixing all');
    Group.FixCL_Names;
    Feature.FixCL_ErrCodeRet;
    Extension.FixCL_ErrCodeRet;
    ApplyFixers;
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
  except
    on e: Exception do ErrOtp(e);
  end;
end.