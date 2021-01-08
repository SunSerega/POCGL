unit AQueue;

uses System;
uses System.Threading;

type
  
  //ToDo #2397
  ///--
  __AsyncQueueBase = abstract class(System.Collections.IEnumerable, System.Collections.IEnumerator)
    
    public function GetEnumerator: System.Collections.IEnumerator := self;
    
    protected function GetCurrentBase: object; abstract;
    public property IEnumerator.Current: object read GetCurrentBase;
    
    public function MoveNext: boolean; abstract;
    
    public procedure Reset := raise new System.NotSupportedException;
    
  end;
  
  AsyncQueue<T> = class(__AsyncQueueBase, IEnumerable<T>, IEnumerator<T>)
    protected q: Queue<T>;
    protected done := false;
    private ev := new ManualResetEvent(false);
    
    public constructor :=
    q := new Queue<T>;
    public constructor(capacity: integer) :=
    q := new Queue<T>(capacity);
    
    public procedure Enq(o: T) :=
    lock q do
    begin
      if done then raise new System.InvalidOperationException($'ERROR: Попытка писать в завершенную {self.GetType}');
      q.Enqueue(o);
      ev.Set;
    end;
    public procedure EnqRange(sq: sequence of T) :=
    foreach var o in sq do Enq(o);
    
    public procedure Finish;
    begin
      lock q do
      begin
        if done then raise new InvalidOperationException($'ERROR: Двойная попытка завершить {self.GetType}');
        done := true;
        ev.Set;
      end;
    end;
    
    public function GetEnumerator: IEnumerator<T> := self;
    
    private last_item: T;
    public property Current: T read last_item;
    protected function GetCurrentBase: object; override := last_item;
    
    public function MoveNext: boolean; override;
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
    
    public procedure Dispose := exit;
    
  end;
  
end.