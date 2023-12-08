uses '../../../../POCGL_Utils';

uses '../Essentials';

begin
  try
    
    SetMaxUnfixedOverloads(12);
    
    ApiManager.EnableLoadableExtensions(new DynamicLoadInfo(
      'pl', 'cl_platform_id',
      'cl_extension_base',
      'PlatformLess', true
    ));
    
    ApiManager.MarkKeep('cl', true);
    
    ApiManager.MarkDynamic('cl', false, true);
    
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