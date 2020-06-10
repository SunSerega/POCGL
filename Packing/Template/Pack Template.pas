uses System.Threading;
//uses PackingUtils;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

type
  TextBlock = abstract class
    str: string;
    
    function Finish: string; virtual := str;
    
  end;
  
  StrBlock = sealed class(TextBlock)
    
    constructor(str: string) :=
    self.str := str;
    
  end;
  
  FuncBlock = sealed class(TextBlock)
    p_otp := new ThrProcOtp;
    
    constructor(p: SecThrProc; f: ()->string);
    begin
      p := p + ProcTask(()->
      begin
        self.str := f();
      end);
      p.StartExec;
      self.p_otp := p.own_otp;
    end;
    
    function Finish: string; override;
    begin
      foreach var l in p_otp.Enmr do Otp(l);
      Result := str;
    end;
    
  end;
  
var prev_commands := new Dictionary<string, ManualResetEvent>;
function RegisterCommand(name: string; work: ()->SecThrProc): SecThrProc;
begin
  var ev: ManualResetEvent;
  
  lock prev_commands do
    if prev_commands.TryGetValue(name, ev) then
      Result := EventTask(ev) else
    begin
      ev := new ManualResetEvent(false);
      prev_commands.Add(name, ev);
      Result := work + SetEvTask(ev);
    end;
  
end;

function ProcessCommand(comm: string; path: string): FuncBlock;
begin
  if comm='' then exit;
  
  var tsk := EmptyTask;
  
  var sind := comm.IndexOf('!');
  if sind <> -1 then
  begin
    var fname := comm.Substring(sind+1);
    tsk += RegisterCommand(fname, ()->ExecTask(GetFullPath(fname, path), $'TemplateCommand[{fname}]') );
    comm := comm.Remove(sind);
  end;
  
  var templ_fname := GetFullPath(comm+'.template', path);
  tsk += RegisterCommand(templ_fname, ()->ExecTask(GetEXEFileName, $'Template[{comm}]', $'"fname={templ_fname}"', $'"otp_dir={path}"') );
  
  if comm.Contains('\') then
    comm := comm.Substring(comm.LastIndexOf('\')+1);
  var tr_fname := $'{path}\{comm}.templateres';
  
  Result := new FuncBlock(tsk, ()->
  begin
    Result := ReadAllText(tr_fname);
    System.IO.File.Delete(tr_fname);
  end);
  
end;

begin
  try
    var inp_fname := GetFullPath(
      is_secondary_proc ?
      CommandLineArgs.Where(arg->arg.StartsWith('fname=')).SingleOrDefault.SubString('fname='.Length) :
      'Packing\Template\OpenCL\0.template'
    );
    var curr_dir := System.IO.Path.GetDirectoryName(inp_fname);
    
    var otp_dir := CommandLineArgs.Where(arg->arg.StartsWith('otp_dir=')).SingleOrDefault;
    if otp_dir<>nil then
      otp_dir := GetFullPath(otp_dir.SubString('otp_dir='.Length));
    
    var blocks := new List<TextBlock>;
    
    {$region Read}
    begin
      var res := new StringBuilder;
      
      foreach var l in ReadAllText(inp_fname).Remove(#13).Trim(#10' '.ToArray).Split(#10) do
      begin
        var ind1 := l.IndexOf('%');
        
        if ind1<>-1 then
        begin
          res += l.Remove(ind1);
          blocks.Add( new StrBlock(res.ToString) );
          res.Clear;
          
          ind1 += 1;
          var ind2 := l.IndexOf('%', ind1);
          var comm := l.Substring(ind1,ind2-ind1);
          blocks.Add( ProcessCommand(comm, curr_dir) );
          
          res += l.Remove(0,ind2+1);
        end else
          res += l;
        
        res += #10;
      end;
      
      res.Length -= 1; // -= #10
      blocks.Add( new StrBlock(res.ToString) );
    end;
    {$endregion Read}
    
    var otp_fname := inp_fname.Remove(inp_fname.LastIndexOf('.')) + (CommandLineArgs.Contains('GenPas') ? '.pas' : '.templateres');
    if otp_dir<>nil then
      otp_fname := otp_dir + otp_fname.Substring(otp_fname.LastIndexOf('\'));
    
    {$region Write}
    begin
      var sw := new System.IO.StreamWriter(System.IO.File.Create(otp_fname));
      
      foreach var bl in blocks do
        if bl<>nil then
          sw.Write(bl.Finish);
      
      sw.Close;
    end;
    {$endregion Write}
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.