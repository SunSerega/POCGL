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
procedure WaitCommandExec(name: string; work: SecThrProc);
begin
  var ev: ManualResetEvent;
  var comm_otp: ThrProcOtp;
  
  lock prev_commands do
    if not prev_commands.TryGetValue(name, ev) then
    begin
      ev := new ManualResetEvent(false);
      prev_commands.Add(name, ev);
      var T_Command := work + SetEvTask(ev);
      T_Command.StartExec;
      comm_otp := T_Command.own_otp;
    end;
  
  if comm_otp=nil then
    ev.WaitOne else
  foreach var l in comm_otp.Enmr do
    Otp(l);
end;

function ProcessCommand(comm: string; path: string): string;
begin
  if comm='' then exit;
  
  var sind := comm.IndexOf('!');
  if sind <> -1 then
  begin
    var fname := comm.Substring(sind+1);
    WaitCommandExec(fname, ExecTask(GetFullPath(fname, path), $'TemplateCommand[{fname}]') );
    comm := comm.Remove(sind);
  end;
  
  var templ_fname := GetFullPath(comm+'.template', path);
  WaitCommandExec(templ_fname, ExecTask(GetEXEFileName, $'Template[{comm}]', $'"fname={templ_fname}"', $'"otp_dir={path}"') );
  
  if comm.Contains('\') then
    comm := comm.Substring(comm.LastIndexOf('\')+1);
  var tr_fname := $'{path}\{comm}.templateres';
  Result := ReadAllText(tr_fname);
  System.IO.File.Delete(tr_fname);
  
end;

begin
  try
    var CommandLineArgs := PABCSystem.CommandLineArgs();
    if not CommandLineArgs.Contains('SecondaryProc') then CommandLineArgs := Arr('fname=Packing\Template\GL\0OpenGL.template');
    
    var inp_fname := CommandLineArgs.Where(arg->arg.StartsWith('fname=')).SingleOrDefault;
    if inp_fname=nil then raise new MessageException('Invalid args: [' + CommandLineArgs.Select(arg->$'"{arg}"').JoinIntoString + ']' );
    inp_fname := GetFullPath(inp_fname.SubString('fname='.Length));
    var curr_dir := System.IO.Path.GetDirectoryName(inp_fname);
    
    var otp_dir := CommandLineArgs.Where(arg->arg.StartsWith('otp_dir=')).SingleOrDefault;
    if otp_dir<>nil then
      otp_dir := GetFullPath(otp_dir.SubString('otp_dir='.Length));
    
    var blocks := new Queue<TextBlock>;
    var read_done := false;
    
    Thread.Create(()->
    try
      var res := new StringBuilder;
      
      foreach var l in ReadAllText(inp_fname).Remove(#13).Trim(#10' '.ToArray).Split(#10) do
      begin
        var ind1 := l.IndexOf('%');
        
        if ind1<>-1 then
        begin
          res += l.Remove(ind1);
          lock blocks do blocks.Enqueue(new StrBlock(res.ToString));
          res.Clear;
          
          ind1 += 1;
          var ind2 := l.IndexOf('%', ind1);
          var comm := l.Substring(ind1,ind2-ind1);
          var comm_res: string;
          lock blocks do
            blocks.Enqueue(new FuncBlock(
              ProcTask(()->
              begin
                comm_res := ProcessCommand(comm, curr_dir);
              end), ()->comm_res
            ));
          
          res += l.Remove(0,ind2+1);
        end else
          res += l;
        
        res += #10;
      end;
      
      res.Length -= 1; // -= #10
      lock blocks do blocks.Enqueue(new StrBlock(res.ToString));
      read_done := true;
    except
      on e: Exception do ErrOtp(e);
    end).Start;
    
    var fname := inp_fname.Remove(inp_fname.LastIndexOf('.'));
    if CommandLineArgs.Contains('GenPas') then
      fname += '.pas' else
      fname += '.templateres';
    
    if otp_dir<>nil then
      fname := otp_dir + fname.Substring(fname.LastIndexOf('\'));
    
    var sw := new System.IO.StreamWriter(System.IO.File.Create(fname));
    
    while true do
    begin
      while blocks.Count=0 do
      begin
        if read_done and (blocks.Count=0) then
        begin
          sw.Flush;
          sw.Close;
          Halt;
        end;
        Sleep(10);
      end;
      
      var bl: TextBlock;
      lock blocks do bl := blocks.Dequeue;
      sw.Write(bl.Finish);
      
    end;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.