uses PackingUtils in '..\PackingUtils.pas';
uses CoreFuncData in '..\..\SpecFormating\GL\CoreFuncData.pas';
uses BinSpecData in '..\..\SpecFormating\GLExt\BinSpecData.pas';
uses FuncFormatData in '..\..\Text converters\FuncFormatData.pas';

var unused_core_funcs := new HashSet<CoreFuncDef>;
var core_funcs := new List<(string,List<CoreFuncDef>)>;

procedure LoadCoreFuncs;
begin
  
end;

begin
  try
    
    
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.
//Packing\GL\ExtFuncs.template