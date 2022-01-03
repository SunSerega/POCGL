///Модуль, который должен быть подключён ко всему, что ожидает вызов себя из другой программы
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
      bw.Write(l.s);
      bw.Write(l.t);
      bw.Write(l.general);
      bw.Flush;
    end;
    
    public procedure CloseImpl; override;
    begin
      bw.Close;
    end;
    
  end;
  
  BinarizingExeTimer = sealed class(ExeTimer)
    
    public procedure GlobalLog; override;
    begin
      var bw := ParentStreamLogger(Logger.main).bw;
      bw.Write(2);
      self.Save( bw );
    end;
    
  end;
  
begin
  try
    if GetArgs(ParentStreamLogger.OutputPipeIdStr).Any then
    begin
      Logger.main := new ParentStreamLogger;
      Timer.main := new BinarizingExeTimer;
    end;
  except
    on e: Exception do ErrOtp(e);
  end;
end.