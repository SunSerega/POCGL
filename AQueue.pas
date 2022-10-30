unit AQueue;

uses System;
uses System.Threading;

type
  
  AsyncQueue<T> = class(IEnumerable<T>, IEnumerator<T>)
    protected q: Queue<T>;
    protected done := false;
    private ev := new ManualResetEvent(false);
    
    {$ifdef DEBUG}
    private done_trace := default(string);
    {$endif DEBUG}
    
    public constructor :=
    q := new Queue<T>;
    public constructor(capacity: integer) :=
    q := new Queue<T>(capacity);
    
    public procedure Enq(o: T) :=
    lock q do
    begin
      if done then raise new System.InvalidOperationException($'ERROR: Попытка писать {TypeName(o)}[{_ObjectToString(o)}] в завершенную {TypeName(self)}');
      q.Enqueue(o);
      ev.Set;
    end;
    public procedure EnqRange(sq: sequence of T) :=
    foreach var o in sq do Enq(o);
    
    public procedure Finish;
    begin
      lock q do
      begin
        if done then raise new InvalidOperationException($'ERROR: Двойная попытка завершить {self.GetType}'
          {$ifdef DEBUG}
            +':'#10#10+
            done_trace + #10#10 +
            System.Environment.StackTrace
          {$endif DEBUG}
        );
        done := true;
        {$ifdef DEBUG}
        done_trace := System.Environment.StackTrace;
        {$endif DEBUG}
        ev.Set;
      end;
    end;
    
    public function GetEnumerator: IEnumerator<T> := self;
    function System.Collections.IEnumerable.GetEnumerator: System.Collections.IEnumerator := self;
    
    private last_item: T;
    public property Current: T read last_item;
    property System.Collections.IEnumerator.Current: object read last_item as object;
    
    public function MoveNext: boolean;
    begin
      last_item := default(T);
      Result := false;
      
      lock q do
        if q.Count=0 then
        begin
          if done then
            exit else
            ev.Reset;
        end else
        begin
          last_item := q.Dequeue;
          Result := true;
          exit;
        end;
      
      ev.WaitOne;
      
      if (q.Count=0) and done then exit;
      
      lock q do last_item := q.Dequeue;
      Result := true;
    end;
    
    public procedure Reset := raise new System.NotSupportedException;
    public procedure Dispose := exit;
    
  end;
  
end.