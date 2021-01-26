unit Timers;

interface

uses AOtp;

type
  ExeTimer = class;
  
  {$region Generic}
  
  Timer = abstract class
    protected total_time: int64;
    public static main: ExeTimer;
    
    public function MeasureTime<T>(f: ()->T): T;
    begin
      var sw := Stopwatch.StartNew;
      try
        Result := f();
      finally
        sw.Stop;
        total_time += sw.ElapsedTicks;
      end;
    end;
    public procedure MeasureTime(p: ()->());
    begin
      var sw := Stopwatch.StartNew;
      try
        p();
      finally
        sw.Stop;
        total_time += sw.ElapsedTicks;
      end;
    end;
    
    protected procedure ReCalcTotalTime; abstract;
    protected procedure TextLog(lvl: integer; header: string; otp: (integer, string)->()); virtual :=
    otp(lvl, $'{header} : {total_time/System.TimeSpan.TicksPerSecond,15:N7}');
    
    private static TextLogLvlColors := |System.ConsoleColor.Black, System.ConsoleColor.DarkGray|;
    public procedure GlobalLog; virtual;
    begin
      ReCalcTotalTime;
      Otp('');
      TextLog(0, 'Total', (lvl, l)->
      begin
        Otp(new OtpLineColored(' '*(4*lvl) + l, SeqGen(lvl, i->(i=0?3:4, TextLogLvlColors[i mod TextLogLvlColors.Length]))));
      end);
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter); abstract;
    public procedure Load(br: System.IO.BinaryReader); abstract;
    
  end;
  
  SimpleTimer = sealed class(Timer)
    
    protected procedure ReCalcTotalTime; override := exit;
    
    public procedure Save(bw: System.IO.BinaryWriter); override :=
    bw.Write(self.total_time);
    public procedure Load(br: System.IO.BinaryReader); override :=
    lock self do total_time += br.ReadInt64;
    
  end;
  
  ContainerBaseTimer = class(Timer)
    private own_time_record := false;
    protected is_empty := true;
    protected sub_timers := new Dictionary<string, Timer>;
    
    protected function AddTimer<TTimer>(name: string; t: TTimer): TTimer; where TTimer: Timer;
    begin
      sub_timers.Add(name, t);
      is_empty := false;
      Result := t;
    end;
    
    protected property SubTimerNames: sequence of string read sub_timers.Keys;
    
    protected procedure ReCalcTotalTime; override;
    begin
      if not own_time_record then
        self.total_time := 0;
      foreach var sub_t in sub_timers.Values do
      begin
        sub_t.ReCalcTotalTime;
        if not own_time_record then
          self.total_time += sub_t.total_time;
      end;
    end;
    protected procedure TextLog(lvl: integer; header: string; otp: (integer, string)->()); override;
    begin
      if (sub_timers.Count=0) and not own_time_record then exit;
      
      inherited;
      
      var max_name_len := sub_timers.Keys.Max(name->name.Length);
      foreach var kvp in sub_timers do
        kvp.Value.TextLog(lvl+1, $'♦ {kvp.Key.PadRight(max_name_len)}', otp);
      
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter); override;
    begin
      
      bw.Write(own_time_record);
      if own_time_record then
        bw.Write(self.total_time);
      
      bw.Write(sub_timers.Count);
      foreach var kvp in sub_timers do
      begin
        bw.Write(kvp.Key);
        bw.Write(kvp.Value is SimpleTimer);
        kvp.Value.Save(bw);
      end;
      
    end;
    public procedure Load(br: System.IO.BinaryReader); override :=
    lock self do
    begin
      
      if self.is_empty then
        self.own_time_record := br.ReadBoolean else
      begin
        if self.own_time_record <> br.ReadBoolean then
          raise new System.InvalidOperationException;
      end;
      if self.own_time_record then
        self.total_time += br.ReadInt64;
      
      loop br.ReadInt32 do
      begin
        var key := br.ReadString;
        var is_simple := br.ReadBoolean;
        var t: Timer;
        if sub_timers.TryGetValue(key, t) then
        begin
          if t is SimpleTimer <> is_simple then
            raise new System.InvalidOperationException;
        end else
        begin
          if is_simple then
            t := new SimpleTimer else
            t := new ContainerBaseTimer;
          sub_timers[key] := t;
        end;
        t.Load(br);
      end;
      
      is_empty := false;
    end;
    
  end;
  
  {$endregion Generic}
  
  {$region Default}
  
  ContainerTimer<TTimer> = sealed class(ContainerBaseTimer)
  where TTimer: Timer, constructor;
    
    private function GetSubTimer(name: string): TTimer;
    begin
      var res: Timer;
      lock sub_timers do
        if not sub_timers.TryGetValue(name, res) then
        begin
          res := new TTimer;
          sub_timers[name] := res;
        end;
      Result := TTimer(res);
    end;
    public property SubTimer[name: string]: TTimer read GetSubTimer; default;
    
  end;
  
  ExeTimer = class(ContainerBaseTimer)
    public pas_comp := AddTimer('.pas compilation', new ContainerTimer<SimpleTimer>);
    public exe_exec := AddTimer('.exe execution',   new ContainerTimer<ContainerBaseTimer>);
    
    public constructor :=
    self.own_time_record := true;
    
    protected procedure ReCalcTotalTime; override;
    begin
      self.total_time := pack_timer.ElapsedTicks;
      inherited;
    end;
    
  end;
  
  {$endregion Default}
  
implementation

function CloseIfNonTimed(log: Logger): boolean;
begin
  Result := (log is FileLogger(var f_log)) and not f_log.IsTimed;
  if Result then
    log.Close else
    log.sub_loggers.RemoveAll(CloseIfNonTimed);
end;

procedure MainLoggerPreClose;
begin
  CloseIfNonTimed(Logger.main);
  Timer.main.GlobalLog;
end;

begin
  try
    Timer.main := new ExeTimer;
    Logger.PreClose += MainLoggerPreClose;
  except
    on e: Exception do ErrOtp(e);
  end;
end.