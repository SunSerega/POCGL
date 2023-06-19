uses '..\..\..\..\POCGL_Utils';

uses '..\Essentials';

begin
  try
    
    SetMaxUnfixedOverloads(12);
    
    ApiManager.MarkKeep('cl', true);
    
    ApiManager.MarkDynamic('cl', false, false);
    
    ApiManager.AddApiLib('cl', 'OpenCL');
    
    AddFuncAutoFixersForAllOutParams;
    AddFuncAutoFixersForCL;
    ApplyFixers;
    PackAllItems;
    
  except
    on e: Exception do
      ErrOtp(e);
  end;
end.