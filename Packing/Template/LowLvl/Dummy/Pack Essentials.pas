﻿uses '../../../../POCGL_Utils';

uses '../Essentials';

begin
  try
    
    SetMaxUnfixedOverloads(integer.MaxValue);
    
    ApiManager.EnableDynamicApis(new DynamicLoadInfo(
      'loader', 'DummyLoader',
      'api_with_loader',
      nil, false
    ));
    
    ApiManager.MarkKeep('dum', true);
    ApiManager.MarkKeep('dyn', true);
    
    ApiManager.MarkDynamic('dum', false,  nil);
    ApiManager.MarkDynamic('dyn', true,   nil);
    
    ApiManager.AddApiLib('dum', 'dummy.dll');
    
    AddFuncAutoFixersForAllOutParams;
    ApplyFixers;
    PackAllItems;
    
  except
    on e: Exception do
      ErrOtp(e);
  end;
end.