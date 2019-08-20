uses RepUtils;

const RepKey = 'git@github.com:KhronosGroup/OpenGL-Registry.git';

begin
  
  try
    
    if System.IO.Directory.Exists('Reps\OpenGL-Registry') then
      PullRep (         'OpenGL-Registry',  'GLRep') else
      CloneRep(RepKey,  'OpenGL-Registry',  'GLRep');
    
  except
    on e: Exception do ErrOtp(e);
  end;
  
  if not CommandLineArgs.Contains('SecondaryProc') then ReadlnString('Press Enter to exit');
end.