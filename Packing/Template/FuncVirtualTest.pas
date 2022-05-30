uses CodeGen      in '..\..\Utils\CodeGen';
uses POCGL_Utils  in '..\..\POCGL_Utils';

uses FuncData;

begin
  try
    api_name := 'v';
    
    Otp($'Creating funcs');
    FuncFixer.LoadFile(GetFullPathRTA('FuncVirtualTest.dat'));
    ApplyFixers;
    MarkReferenced;
    
    begin
      Otp($'Constructing funcs code');
      var funcs_wr := new FileWriter(GetFullPathRTA('Log\FuncVirtualTest.template'));
      var funcs_impl_wr := new FileWriter(GetFullPathRTA('Log\FuncVirtualTest.Implementation.template'));
      loop 3 do funcs_wr += '  '#10;
      loop 3 do funcs_impl_wr += #10;
      Feature.WriteAll(funcs_wr, funcs_impl_wr);
      Extension.WriteAll(funcs_wr, funcs_impl_wr);
      funcs_wr += '  '#10'  ';
      funcs_impl_wr += #10;
      funcs_wr.Close;
      funcs_impl_wr.Close;
    end;
    
    FinishAll;
  except
    on e: Exception do ErrOtp(e);
  end;
end.