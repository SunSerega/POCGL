uses CodeGen      in '..\..\..\Utils\CodeGen';
uses POCGL_Utils  in '..\..\..\POCGL_Utils';

uses FuncData     in '..\FuncData';

begin
  try
    LoadMiscInput;
    api_name := 'cl';
    
    Otp($'Reading .bin');
    LoadBin('DataScraping\XML\CL\funcs.bin');
    
    Otp($'Fixing all');
    Group.FixAllEndExt;
    Group.FixCL_Names;
    Func.FixAllGet;
    Func.FixCL;
    LoadFixers;
    ApplyFixers;
    MarkReferenced;
    
    begin
      Otp($'Constructing funcs code');
      var funcs_wr := new FileWriter(GetFullPathRTA('Funcs.template'));
      loop 3 do funcs_wr += '  '#10;
      Feature.WriteAll(funcs_wr, nil);
      Extension.WriteAll(funcs_wr, nil);
      funcs_wr += '  '#10'  ';
      funcs_wr.Close;
    end;
    
    begin
      Otp($'Constructing structs code');
      var structs_wr := new FileWriter(GetFullPathRTA('Structs.template'));
      loop 3 do structs_wr += '  '#10;
      Struct.WriteAll(structs_wr);
      structs_wr += '  '#10'  ';
      structs_wr.Close;
    end;
    
    begin
      Otp($'Constructing enums code');
      var group_wr := new FileWriter(GetFullPathRTA('Groups.template'));
      loop 3 do group_wr += '  '#10;
      Group.WriteAll(group_wr);
      group_wr += '  '#10'  ';
      group_wr.Close;
    end;
    
    FinishAll;
  except
    on e: Exception do ErrOtp(e);
  end;
end.