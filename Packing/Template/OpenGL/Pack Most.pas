uses FuncData     in '..\FuncData';
uses POCGL_Utils  in '..\..\..\POCGL_Utils';

begin
  try
    InitAll;
    api_name := 'gl';
    
    Otp($'Reading .bin');
    LoadBin('DataScraping\XML\GL\funcs.bin');
    
    Otp($'Fixing all');
    ApplyFixers;
    Feature.FixGL_GDI;
    MarkUsed;
    
    Otp($'Constructing structs code');
    var structs_sb := new StringBuilder;
    loop 3 do structs_sb += '  '#10;
    Struct.WriteAll(structs_sb);
    structs_sb += '  '#10'  ';
    WriteAllText(GetFullPathRTA('Structs.template'), structs_sb.ToString);
    
    Otp($'Constructing enums code');
    var groups_sb := new StringBuilder;
    loop 3 do groups_sb += '  '#10;
    Group.WriteAll(groups_sb);
    groups_sb += '  '#10'  ';
    WriteAllText(GetFullPathRTA('Groups.template'), groups_sb.ToString);
    
    Otp($'Constructing funcs code');
    var funcs_sb := new StringBuilder;
    var funcs_ntv_sb := new StringBuilder;
    loop 3 do funcs_sb += '  '#10;
    loop 3 do funcs_ntv_sb += '  '#10;
    Feature.WriteAll(funcs_sb, funcs_ntv_sb);
    Extension.WriteAll(funcs_sb, funcs_ntv_sb);
    funcs_sb += '  '#10'  ';
    funcs_ntv_sb += '  '#10'  ';
    WriteAllText(GetFullPathRTA('Funcs.template'), funcs_sb.ToString);
    WriteAllText(GetFullPathRTA('FuncsNtv.template'), funcs_ntv_sb.ToString);
    
    FinishAll;
  except
    on e: Exception do ErrOtp(e);
  end;
end.