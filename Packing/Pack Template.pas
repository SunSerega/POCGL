uses System.Threading;
uses Pack_Utils;

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
    done := false;
    
    constructor(f: ()->string);
    begin
      Thread.Create(()->
      try
        self.str := f();
        self.done := true;
      except
        on e: Exception do ErrOtp(e);
      end).Start;
    end;
    
    function Finish: string; override;
    begin
      while not done do Sleep(10);
      Result := str;
    end;
    
  end;
  
function ProcessCommand(comm: string): string;
begin
  if comm='' then exit;
  
  var sind := comm.IndexOf('!');
  if sind<>-1 then
  begin
    ExecuteFile(comm.Substring(sind+1));
    comm := comm.Remove(sind);
  end;
  
  comm := GetFullPath(comm+'.template');
  RunFile(GetEXEFileName, $'"fname={comm}"');
  
  comm += 'res';
  Result := ReadAllText(comm, System.Text.Encoding.UTF7);
  System.IO.File.Delete(comm);
  
end;

begin
  try
    
    var arg := CommandLineArgs.Where(arg->arg.StartsWith('fname=')).SingleOrDefault;
    if arg=nil then raise new PackException('Invalid args: ' + CommandLineArgs.Select(arg->$'"{arg}"').JoinIntoString );
    arg := GetFullPath(arg.SubString('fname='.Length));
    
    var blocks := new Queue<TextBlock>;
    var read_done := false;
    
    Thread.Create(()->
    try
      var res := new StringBuilder;
      
      foreach var l in ReadAllText(arg, System.Text.Encoding.UTF7).Remove(#13).Trim(#10' '.ToArray).Split(#10) do
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
//          writeln(comm);
          lock blocks do blocks.Enqueue(new FuncBlock( ()->ProcessCommand(comm) ));
          
          res += l.Remove(0,ind2+1);
        end else
          res += l;
        
        res += #10;
      end;
      
      res.Length -= 1;
      lock blocks do blocks.Enqueue(new StrBlock(res.ToString));
      read_done := true;
    except
      on e: Exception do ErrOtp(e);
    end).Start;
    
    Thread.Create(()->
    try
      var fname := arg.Remove(arg.LastIndexOf('.'));
      if CommandLineArgs.Contains('GenPas') then
        fname += '.pas' else
        fname += '.templateres';
      var sw := new System.IO.StreamWriter(System.IO.File.Create(fname), System.Text.Encoding.Unicode);
      
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
    end).Start;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.