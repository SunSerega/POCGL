uses OpenCLABC;

type
  MyQueueContainer = sealed class
    private Q: CommandQueue<integer>;
    private par1 := new ParameterQueue<integer>('par1');
    private par2 := new ParameterQueue<string>('par2');
    
    // Эта очередь ничего полезного не делает, но это только пример
    public constructor := self.Q :=
    CLMemory.Create(sizeof(integer)).MakeCCQ
    .ThenWriteValue( self.par1 )
    .ThenQueue( self.par2.ThenUse(x->Println(x), false) )
    .ThenGetValue&<integer>;
    
    public function Invoke(par1: integer; par2: string) :=
    CLContext.Default.SyncInvoke(self.Q,
      self.par1.NewSetter(par1),
      self.par2.NewSetter(par2)
    );
    
  end;
  
begin
  var cont := new MyQueueContainer;
  
  cont.Invoke(1, 'abc').Println;
  cont.Invoke(2, 'def').Println;
  
end.