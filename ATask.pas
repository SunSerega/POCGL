unit ATask;

uses System.Threading;

uses AOtp;
uses SubExecuters;

uses AQueue; //TODO #2543

type
  AsyncTask = abstract class
    public own_otp: AsyncProcOtp;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); abstract;
    private procedure SyncExecImpl; abstract;
    
    private function CreateThread := new Thread(()->
    try
      RegisterThr;
      AsyncProcOtp.curr := self.own_otp;
      SyncExecImpl;
      self.own_otp.Finish;
    except
      on e: Exception do ErrOtp(e);
    end);
    
    private function StartExecImpl: Thread;
    begin
      self.own_otp := new AsyncProcOtp(AsyncProcOtp.curr);
      Result := CreateThread;
      Result.Start;
    end;
    
    public procedure SyncExec;
    begin
      Prepare(new Dictionary<string, ManualResetEvent>);
      SyncExecImpl;
    end;
    
    public function StartExec: Thread;
    begin
      Prepare(new Dictionary<string, ManualResetEvent>);
      Result := StartExecImpl;
    end;
    
  end;
  
  AsyncProc = sealed class(AsyncTask)
    private p: Action0;
    protected constructor(p: Action0) := self.p := p;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override := exit;
    private procedure SyncExecImpl; override := p;
    
  end;
  
  AsyncTaskSum = sealed class(AsyncTask)
    private p1, p2: AsyncTask;
    
    protected constructor(p1, p2: AsyncTask);
    begin
      self.p1 := p1;
      self.p2 := p2;
    end;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override;
    begin
      p1.Prepare(evs);
      p2.Prepare(evs);
    end;
    
    private procedure SyncExecImpl; override;
    begin
      p1.SyncExecImpl;
      p2.SyncExecImpl;
    end;
    
  end;
  
  AsyncTaskMlt = sealed class(AsyncTask)
    private p1,p2: AsyncTask;
    
    protected constructor(p1,p2: AsyncTask);
    begin
      self.p1 := p1;
      self.p2 := p2;
    end;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override;
    begin
      p1.Prepare(evs);
      p2.Prepare(evs);
    end;
    
    private procedure SyncExecImpl; override;
    begin
      p1.StartExecImpl;
      p2.StartExecImpl;
      
      foreach var l in p1.own_otp do Otp(l);
      foreach var l in p2.own_otp do Otp(l);
    end;
    
  end;
  
  AsyncTaskProcessExec = sealed class(AsyncTask)
    private fname, nick: string;
    private pars: array of string;
    
    protected constructor(fname, nick: string; params pars: array of string);
    begin
      self.fname := fname;
      self.nick := nick;
      self.pars := pars;
    end;
    
    private ev: ManualResetEvent;
    private prep_otp: AsyncProcOtp;
    
    public const lk_exec_task_pre_compile = 'exec task pre-compile';
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override :=
      case System.IO.Path.GetExtension(fname) of
        
        '.pas':
        begin
          var pas_fname := fname;
          fname := System.IO.Path.ChangeExtension(pas_fname, '.exe');
          if evs.TryGetValue(pas_fname, self.ev) then exit;
          self.ev := new ManualResetEvent(false);
          evs[pas_fname] := self.ev;
          
          var p := new AsyncProc(()->
          begin
            CompilePasFile(pas_fname, new OtpKind(AsyncTaskProcessExec.lk_exec_task_pre_compile));
            self.ev.Set;
          end);
          
          p.StartExecImpl;
          prep_otp := p.own_otp;
        end;
        
      end;
    
    private procedure SyncExecImpl; override;
    begin
      if prep_otp<>nil then
        foreach var l in prep_otp do
          Otp(l);
      if ev<>nil then ev.WaitOne;
      ExecuteFile(fname, nick, pars);
    end;
    
  end;
  
  AsyncTaskOtpHandler = sealed class(AsyncTask)
    private t: AsyncTask;
    public event p: OtpLine->();
    
    public constructor(t: AsyncTask; p: OtpLine->());
    begin
      self.t := t;
      self.p += p;
    end;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override := t.Prepare(evs);
    
    private procedure SyncExecImpl; override;
    begin
      t.StartExecImpl;
      var lp := p;
      foreach var l in t.own_otp do
      begin
        if lp<>nil then lp(l);
        Otp(l);
      end;
    end;
    
  end;
  
function ProcTask(p: Action0): AsyncTask :=
  new AsyncProc(p);
function EmptyTask := ProcTask(()->exit());

function operator+(p1,p2: AsyncTask): AsyncTask; extensionmethod :=
  new AsyncTaskSum(p1??EmptyTask, p2??EmptyTask);
procedure operator+=(var p1: AsyncTask; p2: AsyncTask); extensionmethod := p1 := p1+p2;

function operator*(p1,p2: AsyncTask): AsyncTask; extensionmethod :=
  new AsyncTaskMlt(p1??EmptyTask, p2??EmptyTask);
procedure operator*=(var p1: AsyncTask; p2: AsyncTask); extensionmethod := p1 := p1*p2;

function CompTask(fname: string; kind: OtpKind? := nil; args: string := nil) :=
  ProcTask(()->CompilePasFile(fname, if kind=nil then OtpKind.Empty else kind.Value, args));

function ExecTask(fname, nick: string; params pars: array of string): AsyncTask :=
  new AsyncTaskProcessExec(fname, nick, pars);

function SetEvTask(ev: ManualResetEvent) := ProcTask(()->ev.Set());
function EventTask(ev: ManualResetEvent) := ProcTask(()->ev.WaitOne());

function CombineAsyncTask(self: sequence of AsyncTask; max_cores: integer := System.Environment.ProcessorCount+1): AsyncTask; extensionmethod;
begin
  Result := EmptyTask;
  
  var evs := new List<ManualResetEvent>;
  foreach var t in self do
  begin
    var ev := new ManualResetEvent(false);
    evs += ev;
    
    var T_Wait := EmptyTask;
    foreach var pev in evs.SkipLast(max_cores).TakeLast(max_cores) do T_Wait += EventTask(pev);
    
    var T_ver :=
      T_Wait + t +
      SetEvTask(ev)
    ;
    
    Result := Result * T_ver;
  end;
  
end;

function TaskForEach<T>(self: sequence of T; p: T->(); max_cores: integer := System.Environment.ProcessorCount+1); extensionmethod :=
  self.Select(o->ProcTask(()->p(o))).CombineAsyncTask(max_cores);

end.