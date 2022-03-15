uses OpenCLABC;

type
  MyQueueContainer = sealed class
    private Q: CommandQueue<integer>;
    private par1 := new ParameterQueue<integer>('par1');
    private par2 := new ParameterQueue<string>('par2');
    
    // Эта очередь ничего полезного не делает, но это только пример
    public constructor := self.Q :=
    MemorySegment.Create(sizeof(integer)).NewQueue
    .AddWriteValue( self.par1 )
    .AddQueue( self.par2.ThenQuickUse(x->Writeln(x)) )
    .AddGetValue&<integer>;
    
    public function Invoke(par1: integer; par2: string) :=
    Context.Default.SyncInvoke(self.Q,
      self.par1.NewSetter(par1),
      self.par2.NewSetter(par2)
    );
    
  end;
  
begin
  var cont := new MyQueueContainer;
  
  cont.Invoke(1, 'abc').Println;
  cont.Invoke(2, 'def').Println;
  
end.