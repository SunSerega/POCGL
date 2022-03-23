uses OpenCLABC;

type
  MyQueueContainer = sealed class
    private Q: CommandQueue<integer>;
    private par1 := new ConstQueue<integer>(-1);
    private par2 := new ConstQueue<string>(nil);
    
    // Эта очередь ничего полезного не делает, но это только пример
    public constructor := self.Q :=
    MemorySegment.Create(sizeof(integer)).NewQueue
    .ThenWriteValue( self.par1 )
    .ThenQueue( self.par2.ThenQuickUse(x->Writeln(x)) )
    .ThenGetValue&<integer>;
    
    public function Invoke(par1: integer; par2: string): integer;
    begin
      var tsk: CLTask<integer>;
      // Нужна блокировка, чтобы если метод Invoke будет выполнен
      // в нескольких потоках одновременно, .Value параметров
      // не могло поменяться пока Context.BeginInvoke создаёт CLTask
      lock self do
      begin
        self.par1.Value := par1;
        self.par2.Value := par2;
        tsk := Context.Default.BeginInvoke(Q);
      end;
      
      Result := tsk.WaitRes;
    end;
    
  end;
  
begin
  var cont := new MyQueueContainer;
  
  cont.Invoke(1, 'abc').Println;
  cont.Invoke(2, 'def').Println;
  
end.