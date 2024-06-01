unit ATask;

uses System.Threading;

uses AOtp;
uses SubExecuters;

type
  AsyncTask = abstract class
    public own_otp: AsyncProcOtp;
    
    private procedure SyncExecImpl; abstract;
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); abstract;
    
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
    private ps: array of AsyncTask;
    
    protected constructor(ps: array of AsyncTask);
    begin
      self.ps := ps;
      foreach var p in ps do
        if p=nil then raise nil;
    end;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override :=
      foreach var p in ps do
        p.Prepare(evs);
    
    private procedure SyncExecImpl; override :=
      foreach var p in ps do
        p.SyncExecImpl;
    
  end;
  
  AsyncTaskMltExecuter = sealed class(AsyncTask)
    private ps: array of AsyncTask;
    private otps: array of AsyncProcOtp;
    private next_ind: ()->integer;
    
    protected constructor(ps: array of AsyncTask; otps: array of AsyncProcOtp; next_ind: ()->integer);
    begin
      self.ps := ps;
      self.otps := otps;
      self.next_ind := next_ind;
    end;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override :=
      raise new System.InvalidOperationException;
    
    private procedure SyncExecImpl; override :=
      while true do
      begin
        var i := next_ind();
        if i>=ps.Length then break;
        AsyncProcOtp.curr := otps[i];
        ps[i].SyncExecImpl();
        otps[i].Finish;
      end;
    
  end;
  AsyncTaskMlt = sealed class(AsyncTask)
    private ps: array of AsyncTask;
    private max_cores: integer;
    
    protected constructor(ps: array of AsyncTask; max_cores: integer?);
    begin
      self.ps := ps;
      self.max_cores := (max_cores ?? System.Environment.ProcessorCount+1).Value.ClampTop(ps.Length);
      foreach var p in ps do
        if p=nil then raise nil;
    end;
    
    private procedure Prepare(evs: Dictionary<string, ManualResetEvent>); override :=
      foreach var p in ps do
        p.Prepare(evs);
    
    private procedure SyncExecImpl; override :=
      if ps.Length = max_cores then
      begin
        foreach var p in ps do
          p.StartExecImpl;
        
        foreach var p in ps do
          foreach var l in p.own_otp do
            Otp(l);
      end else
      begin
        var otps := ArrGen(ps.Length, i->new AsyncProcOtp(AsyncProcOtp.curr));
        
        var next_p_ind := 0;
        var next_ind := function: integer ->
          Interlocked.Increment(next_p_ind) - 1;
        
        loop max_cores do
          AsyncTaskMltExecuter.Create(ps, otps, next_ind).StartExecImpl;
        
        foreach var p_otp in otps do
          foreach var l in p_otp do
            AOtp.Otp(l);
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

function operator+(p1,p2: AsyncTask): AsyncTask; extensionmethod;
begin
  var p1_arr := (p1 as AsyncTaskSum)?.ps;
  var p2_arr := (p2 as AsyncTaskSum)?.ps;
  var res := new List<AsyncTask>(
    (p1_arr?.Length??1).Value +
    (p2_arr?.Length??1).Value
  );
  if p1_arr<>nil then res.AddRange(p1_arr) else if p1<>nil then res += p1;
  if p2_arr<>nil then res.AddRange(p2_arr) else if p2<>nil then res += p2;
  Result := new AsyncTaskSum(res.ToArray);
end;
procedure operator+=(var p1: AsyncTask; p2: AsyncTask); extensionmethod := p1 := p1+p2;

function operator*(p1,p2: AsyncTask): AsyncTask; extensionmethod;
begin
  var p1_arr := (p1 as AsyncTaskMlt)?.ps;
  var p2_arr := (p2 as AsyncTaskMlt)?.ps;
  var res := new List<AsyncTask>(
    (p1_arr?.Length??1).Value +
    (p2_arr?.Length??1).Value
  );
  if p1_arr<>nil then res.AddRange(p1_arr) else if p1<>nil then res += p1;
  if p2_arr<>nil then res.AddRange(p2_arr) else if p2<>nil then res += p2;
  Result := new AsyncTaskMlt(res.ToArray, nil);
end;
procedure operator*=(var p1: AsyncTask; p2: AsyncTask); extensionmethod := p1 := p1*p2;

function CompTask(fname: string; kind: OtpKind? := nil; args: string := nil) :=
  ProcTask(()->CompilePasFile(fname, if kind=nil then OtpKind.Empty else kind.Value, args));

function ExecTask(fname, nick: string; params pars: array of string): AsyncTask :=
  new AsyncTaskProcessExec(fname, nick, pars);

function SetEvTask(ev: ManualResetEvent) := ProcTask(()->ev.Set());
function EventTask(ev: ManualResetEvent) := ProcTask(()->ev.WaitOne());

function CombineAsyncTask(self: sequence of AsyncTask; max_cores: integer? := nil): AsyncTask; extensionmethod :=
  new AsyncTaskMlt(self.Where(t->t<>nil).ToArray, max_cores);

function TaskForEach<T>(self: sequence of T; p: T->(); max_cores: integer := System.Environment.ProcessorCount+1); extensionmethod :=
  self.Select(o->ProcTask(()->p(o))).CombineAsyncTask(max_cores);

end.