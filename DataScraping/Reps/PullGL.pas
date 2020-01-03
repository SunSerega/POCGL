uses RepUtils;

const RepKey = 'git@github.com:KhronosGroup/OpenGL-Registry.git';
const folder = 'OpenGL-Registry';

begin
  
  try
    
    UpdateRep(RepKey, folder, 'GLRep');
    
  except
    on e: Exception do ErrOtp(e);
  end;
  
  if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString('Press Enter to exit');
end.