uses '../../../../POCGL_Utils';

uses '../Essentials';

begin
  try
    
    SetMaxUnfixedOverloads(12);
    
    ApiManager.MarkKeep('gl', true);
    ApiManager.MarkKeep('wgl', true);
    ApiManager.MarkKeep('gdi', true);
    ApiManager.MarkKeep('glx', true);
    ApiManager.MarkKeep('gles1', false);
    ApiManager.MarkKeep('gles2', false);
    ApiManager.MarkKeep('glsc2', false);
    
    ApiManager.MarkDynamic('gl',  true,   true);
    ApiManager.MarkDynamic('wgl', false,  true);
    ApiManager.MarkDynamic('gdi', false,  nil);
    ApiManager.MarkDynamic('glx', false,  true);
    
    ApiManager.AddApiLib('wgl', 'opengl32.dll');
    ApiManager.AddApiLib('gdi', 'gdi32.dll');
    ApiManager.AddApiLib('glx', 'libGL.so.1');
    
    AddFuncAutoFixersForAllOutParams;
    ApplyFixers;
    PackAllItems;
    
  except
    on e: Exception do
      ErrOtp(e);
  end;
end.