## uses
  AOtp            in '..\AOtp',
  PathUtils       in '..\PathUtils',
  SubExecutables  in '..\SubExecutables',
  
  SubExecuters    in '..\SubExecuters',
  Templates       in '..\Templates';
  
try
  ExecuteFile('GenCode.pas', 'CodeGen[KEP]');
  ProcessTemplateTask('Templates', 'KEP.pas', 'temp\KEP.pas').SyncExec;
except
  on e: Exception do ErrOtp(e);
end;