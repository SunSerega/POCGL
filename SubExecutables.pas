///Модуль, который позволяющий программе более красиво вызвать себя из SubExecuters
unit SubExecutables;

interface

implementation

uses AOtp;
uses Timers;
uses CLArgs;

type
  ParentStreamLogger = sealed class(Logger)
    private bw: System.IO.BinaryWriter;
    
    // Если менять - то в SubExecuters тоже
    public const OutputPipeIdStr = 'OutputPipeId';
    
    private constructor;
    begin
      
      if not (Logger.main is ConsoleLogger) then
        raise new System.InvalidOperationException;
      Logger.main := self;
      
      var hnd_strs := GetArgs(OutputPipeIdStr).Single.ToWords;
      
      var str := new System.IO.Pipes.AnonymousPipeClientStream(
        System.IO.Pipes.PipeDirection.Out,
        hnd_strs[0]
      );
      self.bw := new System.IO.BinaryWriter(str);
      bw.Write(byte(0)); // подтверждение соединения для другой стороны (так проще ошибки ловить)
      
      var halt_str := new System.IO.Pipes.AnonymousPipeClientStream(
        System.IO.Pipes.PipeDirection.In,
        hnd_strs[1]
      );
      StartBgThread(()->
      begin
        var command := halt_str.ReadByte;
        case command of
          1, -1: ErrOtp(new ParentHaltException);
          else ErrOtp(new MessageException($'Received invalid halt command: {command}'));
        end;
      end);
      
    end;
    
    protected procedure OtpImpl(l: OtpLine); override;
    begin
      bw.Write(1);
      l.Save(bw);
      bw.Flush;
    end;
    
    public static procedure BinarizeGlobalTimerLog(lines: array of (integer,string,string));
    begin
      var psl := ParentStreamLogger(Logger.main);
      var bw := psl.bw;
      bw.Write(2);
      bw.Write(OtpLine.TotalTime.Ticks);
      bw.Write(lines.Count-1);
      foreach var (lvl, head, body) in lines.Skip(1) do
      begin
        bw.Write(lvl);
        bw.Write(head);
        bw.Write(body);
      end;
    end;
    
    public procedure CloseImpl; override;
    begin
      bw.Close;
    end;
    
  end;
  
begin
  try
    if GetArgs(ParentStreamLogger.OutputPipeIdStr).Any then
    begin
      new ParentStreamLogger;
      Timer.GlobalLog := ParentStreamLogger.BinarizeGlobalTimerLog;
    end;
  except
    on e: Exception do ErrOtp(e);
  end;
end.