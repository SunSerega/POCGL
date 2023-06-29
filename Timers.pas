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
    
    private static TextLogLvlColors := |ConsoleColor.Black, ConsoleColor.DarkGray|;
    private static procedure ConsoleGlobalLog(lines: array of (integer,string,string));
    begin
      var otp_kind := new OtpKind('console only');
      var max_head_len := lines.Max(\(lvl, head, body)->lvl*4+head.Length);
      Otp('', otp_kind);
      foreach var (lvl, head, body) in lines do
      begin
        var sb := new StringBuilder;
        
        sb.Append(' ', 4*lvl);
        sb += head;
        sb.Append(' ', max_head_len-head.Length-lvl*4);
        sb += ' : ';
        sb += body;
        
        //TODO #2898: &<ConsoleColor>
        Otp(new OtpLineColored(sb.ToString, otp_kind, SeqGen(lvl, i->i=0?3:4).ZipTuple(TextLogLvlColors.Cycle&<ConsoleColor>)));
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
      var sw := Stopwatch.StartNew;
      
      if exec_body=nil then
        raise new ArgumentNullException('exec_body');
      var br := exec_body();
      if br=nil then
        raise new ArgumentNullException('br');
      self.loaded_time := new TimeSpan(br.ReadInt64);
      self.loaded_info := ArrGen(br.ReadInt32, i->
        (br.ReadInt32, br.ReadString, br.ReadString)
      );
      br.Close;
      
      self.measured_time := sw.Elapsed;
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
  
  {$region old}
  (**
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
    protected procedure TextLogBody(lvl: integer; otp: (integer, string, string)->()); abstract;
    protected static function TimeToText(time: int64) := (time/System.TimeSpan.TicksPerSecond).ToString('N7').PadLeft(15);
    protected procedure TextLog(lvl: integer; header: string; otp: (integer, string, string)->());
    begin
      otp(lvl, header, TimeToText(self.total_time));
      TextLogBody(lvl+1, otp);
    end;
    
    private static TextLogLvlColors := |System.ConsoleColor.Black, System.ConsoleColor.DarkGray|;
    public procedure GlobalLog; virtual; // overriden to save to bin
    begin
//      if not IsSeparateExecution then exit;
      ReCalcTotalTime;
      
      var lines := new List<(integer,string,string)>;
      TextLog(0, 'Total', (lvl, head, body)->
        lines.Add((lvl, head, body))
      );
      if not lines.Any then raise new System.InvalidOperationException;
      
      var otp_kind := new OtpKind('console only');
      var max_head_len := lines.Max(\(lvl, head, body)->lvl*4+head.Length);
      Otp('', otp_kind);
      foreach var (lvl, head, body) in lines do
      begin
        var sb := new StringBuilder;
        
        sb.Append(' ', 4*lvl);
        sb += head;
        sb.Append(' ', max_head_len-head.Length-lvl*4);
        sb += ' : ';
        sb += body;
        
        Otp(new OtpLineColored(sb.ToString, otp_kind, SeqGen(lvl, i->i=0?3:4).ZipTuple(TextLogLvlColors.Cycle)));
      end;
      
    end;
    
    private const BinId_Simple: byte = 1;
    private const BinId_Container: byte = 2;
    public procedure Save(bw: System.IO.BinaryWriter); abstract;
    
    private static loaders := new Dictionary<byte, System.IO.BinaryReader->Timer>;
    protected static procedure AddLoader<TTimer>(bin_id: byte; loader: System.IO.BinaryReader->TTimer) :=
      loaders.Add(bin_id, br->Timer(loader(br) as object)); //TODO delegate conversion
    public static function Load(br: System.IO.BinaryReader): Timer;
    begin
      var bin_id := br.ReadByte;
      Result := loaders[bin_id](br);
    end;
    
  end;
  
  ContainerBaseTimer = abstract class(Timer)
    protected secondary_time: int64?;
    private sub_timers := new Dictionary<string, List<Timer>>;
    
    protected constructor(time_is_children_sum: boolean) :=
      self.time_is_children_sum := time_is_children_sum;
    private constructor := raise new System.InvalidOperationException;
    
    protected function AddTimer<TTimer>(name: string; t: TTimer): TTimer; where TTimer: Timer;
    begin
      var l: List<Timer>;
      if not sub_timers.TryGetValue(name, l) then
      begin
        l := new List<Timer>;
        sub_timers[name] := l;
      end;
      l.Add(t);
      Result := t;
    end;
    
    protected procedure ReCalcTotalTime; override;
    begin
      if time_is_children_sum then
        self.total_time := 0;
      foreach var sub_t in sub_timers.Values.SelectMany(l->l) do
      begin
        sub_t.ReCalcTotalTime;
        if time_is_children_sum then
          self.total_time += sub_t.total_time;
      end;
    end;
    
    protected procedure TextLogBody(lvl: integer; otp: (integer, string, string)->()); override;
    begin
      if (sub_timers.Count=0) and time_is_children_sum then exit;
      
      foreach var name in sub_timers.Keys do
      begin
        var l := sub_timers[name];
        
        if l.Count=1 then
        begin
          l.Single.TextLog(lvl, $'♦ {name}', otp);
          continue;
        end;
        
        begin
          var sb := new StringBuilder;
          var list_total_time := int64(0);
          foreach var sub_t in l index i do
          begin
            sb += if i=0 then ' = ' else ' + ';
            sb += (sub_t.total_time/System.TimeSpan.TicksPerSecond).Round(3).ToString;
            list_total_time += sub_t.total_time;
          end;
          sb.Insert(0, TimeToText(list_total_time));
          otp(lvl, $'♦ {name} (x{l.Count})', sb.ToString);
        end;
        
        foreach var sub_t in l index i do
          sub_t.TextLog(lvl+1, i+':', otp);
        
      end;
      
    end;
    
    public procedure Save(bw: System.IO.BinaryWriter); override;
    begin
      bw.Write(BinId_Container);
      
      bw.Write(time_is_children_sum);
      
      if not time_is_children_sum then
        bw.Write(total_time);
      
      bw.Write(sub_timers.Count);
      foreach var name in sub_timers.Keys do
      begin
        bw.Write(name);
        var l := sub_timers[name];
        bw.Write(l.Count);
        foreach var sub_t in l do
          sub_t.Save(bw);
      end;
      
    end;
  end;
  
  LoadedContainerTimer = sealed class(ContainerBaseTimer)
    
    public static function Load(br: System.IO.BinaryReader): LoadedContainerTimer;
    begin
      Result := new LoadedContainerTimer(br.ReadBoolean);
      
      if Result.time_is_children_sum then
        Result.total_time := br.ReadInt64;
      
      loop br.ReadInt32 do
      begin
        var name := br.ReadString;
        var l := new List<Timer>(br.ReadInt32);
        loop l.Capacity do
          l += Timer.Load(br);
        Result.sub_timers.Add(name, l);
      end;
      
    end;
    
  end;
  
  ContainerTimer<TTimer> = sealed class(ContainerBaseTimer)
  where TTimer: Timer;
    private timer_creator: ()->TTimer;
    
    public constructor(timer_creator: ()->TTimer);
    begin
      inherited Create(true);
      self.timer_creator := timer_creator;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public property SubTimer[name: string]: TTimer read AddTimer(name, timer_creator()); default;
    
    public procedure LoadSubTimer(name: string; br: System.IO.BinaryReader) := AddTimer(name, Timer.Load(br));
    
  end;
  
  {$endregion Generic}
  
  {$region Default}
  
  SimpleTimer = sealed class(Timer)
    
    public static function MakeNew: SimpleTimer :=
      new SimpleTimer;
    
    protected procedure ReCalcTotalTime; override := exit;
    protected procedure TextLogBody(lvl: integer; otp: (integer, string, string)->()); override := exit;
    
    public procedure Save(bw: System.IO.BinaryWriter); override;
    begin
      bw.Write(BinId_Simple);
      bw.Write(self.total_time);
    end;
    public static function Load(br: System.IO.BinaryReader): SimpleTimer;
    begin
      Result := new SimpleTimer;
      Result.total_time := br.ReadInt64;
    end;
    
  end;
  
  ExeTimer = class(ContainerBaseTimer)
    public pas_comp := AddTimer('.pas compilation', new ContainerTimer<SimpleTimer>(SimpleTimer.MakeNew));
    public exe_exec := AddTimer('.exe execution',   new ContainerTimer<WrapTimer<ExeTimer>>(nil));
    
    public constructor := inherited Create(false);
    
    protected procedure ReCalcTotalTime; override;
    begin
      self.total_time := OtpLine.pack_timer.ElapsedTicks;
      Otp($'Total time is set to {self.total_time}');
      inherited;
      foreach var name in self.sub_timers.Keys.ToArray do
        if not ContainerBaseTimer(sub_timers[name].Single).sub_timers.Any then
          self.sub_timers.Remove(name);
    end;
    
  end;
  
  {$endregion Default}
  
  (**)
  {$endregion old}
  
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