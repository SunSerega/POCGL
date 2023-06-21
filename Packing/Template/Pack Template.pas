uses POCGL_Utils  in '..\..\POCGL_Utils';

uses Templates    in '..\..\Utils\Templates';
uses CLArgs       in '..\..\Utils\CLArgs';

begin
  try
    var inp_fname := GetArgs('inp_fname').SingleOrDefault;
    var otp_fname := GetArgs('otp_fname').SingleOrDefault;
    var nick := GetArgs('nick').SingleOrDefault;
    var dir := GetArgs('dir').SingleOrDefault;
    
    if is_separate_execution and string.IsNullOrWhiteSpace(inp_fname) and string.IsNullOrWhiteSpace(otp_fname) and string.IsNullOrWhiteSpace(nick) then
    begin
      
//      inp_fname := 'Modules\Template\OpenGL.pas';
//      otp_fname := 'Modules\OpenGL.pas';
//      nick := 'OpenGL';
//      dir := 'LowLvl';
      
//      inp_fname := 'Modules\Template\OpenCL.pas';
//      otp_fname := 'Modules\OpenCL.pas';
//      nick := 'OpenCL';
//      dir := 'LowLvl';
      
      inp_fname := 'Modules\OpenCLABC.pas';
      otp_fname := 'Modules.Packed\OpenCLABC.pas';
      nick := 'OpenCLABC';
      dir := 'HighLvl';
      
    end;
    
    ProcessTemplateTask(
      GetFullPath(nick, GetFullPathRTA(dir)),
      inp_fname, otp_fname
    ).SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.