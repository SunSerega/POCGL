uses System.Threading;
uses System.IO;
{$string_nullbased+}

uses POCGL_Utils  in '..\..\POCGL_Utils';
uses AOtp         in '..\..\Utils\AOtp';
uses ATask        in '..\..\Utils\ATask';
uses AQueue       in '..\..\Utils\AQueue';
uses CLArgs       in '..\..\Utils\CLArgs';

type
  FileBlock = abstract class
    
    procedure Finish(into: AsyncQueue<string>); abstract;
    
  end;
  
  StrBlock = sealed class(FileBlock)
    str: string;
    
    constructor(str: string) :=
    self.str := str;
    
    procedure Finish(into: AsyncQueue<string>); override :=
    into.Enq(str);
    
  end;
  
  WaitBlock = sealed class(FileBlock)
    p_otp: AsyncProcOtp;
    f: AsyncQueue<string>->();
    
    constructor(p: AsyncTask; f: AsyncQueue<string>->());
    begin
      p.StartExec;
      self.p_otp := p.own_otp;
      self.f := f;
    end;
    
    procedure Finish(into: AsyncQueue<string>); override;
    begin
      foreach var l in p_otp do Otp(l);
      f(into);
    end;
    
  end;
  
  TemplateUtils = static class
    
    static prev_commands := new Dictionary<string, ManualResetEvent>;
    static function RegisterCommand(name: string; work: ()->AsyncTask): AsyncTask;
    begin
      var ev: ManualResetEvent;
      
//      Writeln(name);
      
      lock prev_commands do
        if prev_commands.TryGetValue(name, ev) then
        begin
//          Writeln('wait');
          Result := EventTask(ev);
        end else
        begin
//          Writeln('work');
          ev := new ManualResetEvent(false);
          prev_commands.Add(name, ev);
          Result := work + SetEvTask(ev);
        end;
      
//      Writeln('='*50);
      
    end;
    
    static function ProcessCommand(template_fname, generator_fname: string; generator_par: array of string): sequence of FileBlock;
    begin
      var tsk := EmptyTask;
      
      if generator_fname<>nil then
      begin
        
        if Path.GetExtension(generator_fname) = '.pas' then
        begin
          tsk := RegisterCommand(generator_fname, ()->tsk+CompTask(generator_fname));
          generator_fname := Path.ChangeExtension(generator_fname, '.exe');
        end;
        
        tsk := RegisterCommand(Concat(generator_fname,'!',generator_par.JoinToString('!')), ()->tsk+ExecTask(generator_fname, $'TemplateCommand[{GetRelativePathRTA(generator_fname)}]', generator_par));
      end;
      
      //ToDo #
      var template_nick := $'Template[{GetRelativePathRTA(Path.ChangeExtension(template_fname, nil))}]';
      yield new WaitBlock(tsk, otp->
      begin
        
        var p := ProcessFile(Path.GetDirectoryName(template_fname), template_fname, otp);
        p.StartExec;
        
        foreach var l in p.own_otp do
          AOtp.Otp(l.ConvStr(s->$'{template_nick}: {s}'));
        
      end);
      
    end;
    
    static function ParseCommand(comm: string; curr_path: string): sequence of FileBlock;
    begin
      var wds := comm.Split('!');
      if wds.Length=0 then exit;
      if string.IsNullOrWhiteSpace(wds[0]) then exit;
      
      Result := ProcessCommand(
        GetFullPath(wds[0]+'.template', curr_path),
        (wds.Length<2) or string.IsNullOrWhiteSpace(wds[1]) ? nil : GetFullPath(wds[1], curr_path),
        wds?[2:]
      );
      
    end;
    
    static function ProcessLine(l: string; curr_path: string): sequence of FileBlock;
    begin
      var ind := 0;
      
      while true do
      begin
        
        var ind1 := l.IndexOf('{%', ind);
        if ind1=-1 then break;
        
        var ind2 := l.IndexOf('%}', ind1);
        if ind2=-1 then break;
        
        yield new StrBlock(l.Substring(ind, ind1-ind));
        ind1 += '{%'.Length;
        
        var sq := ParseCommand(l.Substring(ind1,ind2-ind1), curr_path);
        if sq<>nil then yield sequence sq;
        
        ind := ind2 + '%}'.Length;
      end;
      
      yield new StrBlock(l.Remove(0,ind));
      
    end;
    
    static function ProcessFile(curr_path: string; inp_fname: string; otp: AsyncQueue<string>): AsyncTask;
    begin
      var bls := new AsyncQueue<FileBlock>;
      var inp := new AsyncQueue<string>;
      
      Result := (
        ProcTask(()->
        begin
//          MiscUtils.Otp($'Reading');
//          Writeln(inp_fname);
          if not FileExists(inp_fname) then raise new MessageException($'ERROR: File [{GetRelativePathRTA(inp_fname)}] not found');
          var text := ReadAllText(inp_fname, enc).Trim.Remove(#13);
          
          var ind1 := 0;
          while true do
          begin
            var ind2 := text.IndexOf(#10, ind1);
            if ind2=-1 then break;
            inp.Enq(text.SubString(ind1, ind2-ind1)+#13#10);
            ind1 := ind2+1;
          end;
          inp.Enq(text.Remove(0, ind1));
          
          inp.Finish;
//          MiscUtils.Otp($'Done reading');
        end)
      *
        ProcTask(()->
        begin
          foreach var l in inp do
            bls.EnqRange(ProcessLine(l, curr_path));
          bls.Finish;
//          MiscUtils.Otp($'Done parsing');
        end)
      *
        ProcTask(()->
        begin
          foreach var bl in bls do
            bl.Finish(otp);
//          MiscUtils.Otp($'Done processing');
        end)
      );
      
    end;
    static function ProcessingFile(curr_path: string; inp_fname, otp_fname: string): AsyncTask;
    begin
      var otp := new AsyncQueue<string>;
      
      Result := (
        (
          ProcessFile(curr_path, inp_fname, otp) +
          ProcTask(otp.Finish)
        )
      *
        ProcTask(()->
        begin
          var sw := new StreamWriter(otp_fname, false, enc);
          foreach var s in otp do
            sw.Write(s);
          sw.Close;
        end)
      );
      
    end;
    
  end;
  
begin
  try
    var inp_fname := GetArgs('inp_fname').SingleOrDefault;
    var otp_fname := GetArgs('otp_fname').SingleOrDefault;
    var nick := GetArgs('nick').SingleOrDefault;
    
    if is_separate_execution and string.IsNullOrWhiteSpace(inp_fname) and string.IsNullOrWhiteSpace(otp_fname) and string.IsNullOrWhiteSpace(nick) then
    begin
      
//      inp_fname := 'Modules\Template\OpenGL.pas';
//      otp_fname := 'Modules\OpenGL.pas';
//      nick := 'OpenGL';
      
//      inp_fname := 'Modules\Template\OpenCL.pas';
//      otp_fname := 'Modules\OpenCL.pas';
//      nick := 'OpenCL';
      
      inp_fname := 'Modules\Internal\OpenCLABCBase.pas';
      otp_fname := 'Modules.Packed\Internal\OpenCLABCBase.pas';
      nick := 'OpenCLABC';
      
//      inp_fname := 'Modules\OpenCLABC.pas';
//      otp_fname := 'Modules.Packed\OpenCLABC.pas';
//      nick := 'OpenCLABC';
      
    end;
    
    TemplateUtils.ProcessingFile(
      GetFullPath(nick, Path.GetDirectoryName(GetEXEFileName)),
      inp_fname, otp_fname
    ).SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.