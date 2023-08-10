unit Timers;

interface

uses System;

uses AOtp;

type
  
  Timer = abstract class
    protected static main: Timer;
    
    protected function OuterTime: TimeSpan; abstract;
    
    public function MakeLogLines(lvl: integer; header: string): sequence of (integer,string,string); abstract;
    
    protected static function TimeToText(time: TimeSpan) :=
      time.TotalSeconds.ToString('N7').PadLeft(15);
    
    private static lk_console_only := new OtpKind('console only');
    
    private static TextLogLvlColors := |ConsoleColor.Black, ConsoleColor.DarkGray|;
    private static procedure ConsoleGlobalLog(lines: array of (integer,string,string));
    begin
//      Write(
//        'ConsoleGlobalLog:'#10+
//        System.Environment.StackTrace
//      );
      var max_head_len := lines.Max(\(lvl, head, body)->lvl*4+head.Length);
      Otp('', lk_console_only);
      foreach var (lvl, head, body) in lines do
      begin
        var sb := new StringBuilder;
        
        sb.Append(' ', 4*lvl);
        sb += head;
        sb.Append(' ', max_head_len-head.Length-lvl*4);
        sb += ' : ';
        sb += body;
        
        //TODO #2898: &<ConsoleColor>
        Otp(new OtpLineColored(sb.ToString, lk_console_only, SeqGen(lvl, i->i=0?3:4).ZipTuple(TextLogLvlColors.Cycle&<ConsoleColor>)));
      end;
    end;
    public static GlobalLog := ConsoleGlobalLog;
    
    protected static procedure ConditionalActWrap(cond: boolean; wrap: Action->(); act: Action) :=
      if cond then wrap(act) else act;
    
  end;
  
  SimpleTimer = sealed class(Timer)
    private time: TimeSpan;
    
    public constructor(act: ()->());
    begin
      var sw := Stopwatch.StartNew;
      act();
      self.time := sw.Elapsed;
    end;
    
    protected function OuterTime: TimeSpan; override := self.time;
    
    public function MakeLogLines(lvl: integer; header: string): sequence of (integer,string,string); override :=
      |(lvl, header, TimeToText(self.time))|;
    
  end;
  
  LoadedTimer = sealed class(Timer)
    private measured_time, loaded_time: TimeSpan;
    private loaded_info: array of (integer,string,string);
    
    public constructor(exec_body: ()->System.IO.BinaryReader);
    begin
      if exec_body=nil then
        raise new ArgumentNullException('exec_body');
      
      var sw := Stopwatch.StartNew;
      var br := exec_body();
      self.measured_time := sw.Elapsed;
      
      if br=nil then
        raise new ArgumentNullException('br');
      self.loaded_time := new TimeSpan(br.ReadInt64);
      self.loaded_info := ArrGen(br.ReadInt32, i->
        (br.ReadInt32, br.ReadString, br.ReadString)
      );
      br.Close;
      
    end;
    private constructor := raise new InvalidOperationException;
    
    protected function OuterTime: TimeSpan; override := self.measured_time;
    
    public function MakeLogLines(lvl: integer; header: string): sequence of (integer,string,string); override;
    begin
      yield (lvl, header, $'{TimeToText(measured_time)} ({loaded_time.TotalSeconds:N4})');
      foreach var (d_lvl, head, body) in loaded_info do
        yield (lvl+d_lvl, head, body);
    end;
    
  end;
  
  TimerContainer<TTimer> = sealed class(Timer)
  where TTimer: Timer;
    // Dictionary<nick, List<(full_name, timer)>>
    private sub_timers := new Dictionary<string, List<(string, TTimer)>>;
    
    public procedure Add(nick, full_name: string; t: TTimer);
    begin
      if nick=nil then
        raise new ArgumentNullException('nick');
      if outer_time_cache<>nil then
        raise new InvalidOperationException;
      
      var l: List<(string, TTimer)>;
      lock sub_timers do
        if not sub_timers.TryGetValue(nick, l) then
        begin
          l := new List<(string, TTimer)>;
          sub_timers[nick] := l;
        end;
      
      lock l do
        l += (full_name, t);
      
    end;
    
    private outer_time_cache: TimeSpan?;
    private time_per_nick: Dictionary<string, TimeSpan>;
    protected function OuterTime: TimeSpan; override;
    begin
      if outer_time_cache<>nil then
      begin
        Result := outer_time_cache.Value;
        exit;
      end;
      Result := TimeSpan.Zero;
      
      time_per_nick := new Dictionary<string, TimeSpan>(sub_timers.Count);
      foreach var nick in sub_timers.Keys do
      begin
        var time := sub_timers[nick].Aggregate(TimeSpan.Zero, (accum,\(n,t))->accum + t.OuterTime);
        time_per_nick.Add(nick, time);
        Result := Result + time;
      end;
      
      outer_time_cache := Result;
    end;
    
    public function Any := sub_timers.Count<>0;
    
    public function MakeLogLines(lvl: integer; header: string): sequence of (integer,string,string); override;
    begin
      //TODO #2896
      yield (lvl, header, Timer.TimeToText(self.OuterTime));
      
      foreach var nick in sub_timers.Keys.Order do
      begin
        var l := sub_timers[nick];
        
        if l.Count=1 then
        begin
          yield sequence l.Single[1].MakeLogLines(lvl+1, $'♦ {nick}');
          continue;
        end;
        
        //TODO #2896
        yield (lvl+1, $'♦ {nick} x{l.Count}', Timer.TimeToText(time_per_nick[nick]));
        
        var common_name_parts := l.First[0].Split('/');
        foreach var (full_name, t) in l.Skip(1) do
        begin
          var c := common_name_parts.ZipTuple(full_name.Split('/')).TakeWhile(\(p1,p2)->p1=p2).Count;
          if c<common_name_parts.Length then
            common_name_parts := common_name_parts[:c];
        end;
        var common_skip_len := common_name_parts.Sum(p->p.Length+1);
        
        foreach var (full_name, t) in l.OrderBy(t->t[0]) do
          yield sequence t.MakeLogLines(lvl+2, full_name.SubString(common_skip_len));
        
      end;
      
    end;
    
  end;
  
  ExeTimer = sealed class(Timer)
    private comp := new TimerContainer<SimpleTimer>;
    private exec := new TimerContainer<LoadedTimer>;
    
    private constructor;
    begin
      if Timer.main<>nil then
        raise new InvalidOperationException;
      Timer.main := self;
    end;
    
    public static function Compilations := ExeTimer(Timer.main).comp;
    public static function Executions   := ExeTimer(Timer.main).exec;
    
    protected function OuterTime: TimeSpan; override;
    begin
      raise new InvalidOperationException;
    end;
    
    public function MakeLogLines(lvl: integer; header: string): sequence of (integer,string,string); override;
    begin
      if lvl<>0 then
        raise new InvalidOperationException;
      yield (lvl, header, TimeToText(OtpLine.TotalTime));
      if comp.Any then yield sequence comp.MakeLogLines(lvl+1, 'Compilations');
      if exec.Any then yield sequence exec.MakeLogLines(lvl+1, 'Executions');
    end;
    
  end;
  
implementation

initialization
  try
    new ExeTimer;
  except
    on e: Exception do ErrOtp(e);
  end;
finalization
  try
    Timer.GlobalLog(Timer.main.MakeLogLines(0, 'Total').ToArray);
  except
    on e: Exception do ErrOtp(e);
  end;
end.