  
  
  
  {%!!}unit DebugTypes;{$define ForceMaxDebug}{$include DebugHeader.pas} uses System; var gen_debug_otp: System.IO.TextWriter; type//{%}{$region CallDebug}{$ifdef CallDebug}
  
  ///
  CallRecord = sealed class
    private time: TimeSpan;
    private call: string;
    
    private constructor(sw: Stopwatch; call: string);
    begin
      self.time := sw.Elapsed;
      self.call := call;
    end;
    
    private procedure Add(tail: string) :=
      self.call += tail;
    
  end;
  
  ///
  CallDebug = static class
    private static sw := Stopwatch.StartNew;
    
    private static all_thread_lists := new System.Collections.Concurrent.ConcurrentDictionary<System.Threading.Thread, List<CallRecord>>;
    private static active_call_count := 0;
    
    private static function GetCurrThreadList :=
      all_thread_lists.GetOrAdd(System.Threading.Thread.CurrentThread, t->new List<CallRecord>);
    
    private static procedure RegisterCallDataHeader(name: string; par: array of string) :=
      GetCurrThreadList.Add(new CallRecord(sw, $'{name}({par.JoinToString('', '')})'));
    private static procedure RegisterCallDataResult(res: string) :=
      GetCurrThreadList[^1].Add($' -> {res}');
    
    private static function Wrap(o: object) := ObjectToString(o);
    private static function Wrap(o: pointer) := if o=nil then 'nil' else IntPtr(o).ToString('X'+IntPtr.Size*2);
    private static function WrapVarArg<T>(var arg: T) := if @arg=nil then 'nil' else Wrap(arg);
    
    private static temp_lock := new object;
    
    private [ThreadStatic] static in_call: integer; // One public method may call another
    // Not saving call name, because EnumToType call can have a suffix
    private static procedure RegisterCallBegin(name: string; params par: array of string);
    begin
      System.Threading.Interlocked.Increment(active_call_count);
//      System.IO.File.AppendAllLines('temp.log', [name, Environment.StackTrace] + par);
      in_call += 1;
      if in_call = 1 then
        RegisterCallDataHeader(name, par);
      System.Threading.Monitor.Enter(temp_lock);
    end;
    private static procedure RegisterCallResult(res: string) :=
      if in_call = 1 then RegisterCallDataResult(res);
    private static procedure RegisterCallEnd;
    begin
      System.Threading.Monitor.Exit(temp_lock);
      System.Threading.Interlocked.Decrement(active_call_count);
      in_call -= 1;
//      System.IO.File.AppendAllLines('temp.log', ['---']);
    end;
    
    public static procedure ReportCalls(otp: System.IO.TextWriter := Console.Out) := lock otp do
    begin
      otp.WriteLine(System.Environment.StackTrace);
      
      var newest_report := TimeSpan.Zero;
      foreach var thread in all_thread_lists.Keys.OrderBy(thread->all_thread_lists[thread][0].time) do
      begin
        var l := all_thread_lists[thread];
        if l[0].time>newest_report then
          otp.WriteLine;
        otp.WriteLine($'Logging calls on thread {thread.ManagedThreadId} [{thread.Name}]');
        foreach var r in l do
          otp.WriteLine($'{r.time}: {r.call}');
        newest_report := |newest_report, l[^1].time|.Max;
        otp.WriteLine('-'*30);
      end;
      
      otp.WriteLine('='*40);
      otp.Flush;
    end;
    
    public static procedure FinallyReport;
    begin
      if all_thread_lists.Count=0 then exit;
      
      if active_call_count<>0 then
        lock output do
        begin
          ReportCalls(Console.Error);
          Sleep(1000);
          raise new InvalidOperationException($'Some call is still executing');
        end;
      
      var total_call_count := all_thread_lists.Values.Sum(l->l.Count);
      gen_debug_otp.WriteLine($'[CallDebug]: {total_call_count} total calls made');
      
      //TODO Prob remove, this is too verbose for succesfull test
      foreach var thread in all_thread_lists.Keys.OrderBy(thread->all_thread_lists[thread][0].time) do
      begin
        gen_debug_otp.WriteLine($'- Thread [{thread.Name}]');
        foreach var r in all_thread_lists[thread] do
          gen_debug_otp.WriteLine($'--- {r.call}');
      end;
      
    end;
    
  end;
  
  {%!!}end.//{%}{$endif CallDebug}{$region CallDebug}
  
  
  