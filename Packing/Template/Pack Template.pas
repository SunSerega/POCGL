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
    own_otp := new ThrProcOtp;
    
    constructor(f: ()->string);
    begin
      Thread.Create(()->
      try
        RegisterThr;
        ThrProcOtp.curr := self.own_otp;
        self.str := f();
        self.own_otp.Finish;
      except
        on e: Exception do ErrOtp(e);
      end).Start;
    end;
    
    function Finish: string; override;
    begin
      foreach var l in own_otp.Enmr do Otp(l);
      Result := str;
    end;
    
  end;
  
var prev_commands := new Dictionary<string, ManualResetEvent>;
procedure WaitCommandExec(name: string; work: ()->());
begin
  var ev: ManualResetEvent;
  var comm_otp: ThrProcOtp;
  
  lock prev_commands do
    if not prev_commands.TryGetValue(name, ev) then
    begin
      ev := new ManualResetEvent(false);
      prev_commands.Add(name, ev);
      var T_Command := (
        ProcTask(work) +
        SetEvTask(ev)
      );
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
    WaitCommandExec(fname, ()-> ExecuteFile(GetFullPath(fname, path), $'TemplateCommand[{fname}]') );
    comm := comm.Remove(sind);
  end;
  
  comm := GetFullPath(comm+'.template', path);
  WaitCommandExec(comm, ()-> RunFile(GetEXEFileName, $'Template[{comm}]', $'"fname={comm}"') );
  
  comm += 'res';
  Result := ReadAllText(comm);
  System.IO.File.Delete(comm);
  
end;

begin
  try
    if not CommandLineArgs.Contains('SecondaryProc') then CommandLineArgs := Arr('fname=Packing\Template\GL\0OpenGL.template');
    
    var arg := CommandLineArgs.Where(arg->arg.StartsWith('fname=')).SingleOrDefault;
    if arg=nil then raise new MessageException('Invalid args: [' + CommandLineArgs.Select(arg->$'"{arg}"').JoinIntoString + ']' );
    arg := GetFullPath(arg.SubString('fname='.Length));
    var curr_dir := System.IO.Path.GetDirectoryName(arg);
    
    var blocks := new Queue<TextBlock>;
    var read_done := false;
    
    Thread.Create(()->
    try
      var res := new StringBuilder;
      
      foreach var l in ReadAllText(arg, new System.Text.UTF8Encoding(true)).Remove(#13).Trim(#10' '.ToArray).Split(#10) do
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
          lock blocks do blocks.Enqueue(new FuncBlock( ()->ProcessCommand(comm, curr_dir) ));
          
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
    
    var fname := arg.Remove(arg.LastIndexOf('.'));
    if CommandLineArgs.Contains('GenPas') then
      fname += '.pas' else
      fname += '.templateres';
    var sw := new System.IO.StreamWriter(System.IO.File.Create(fname), new System.Text.UTF8Encoding(true));
    
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