uses OpenCLABC;

procedure OtpObject(o: object) :=
Writeln( $'{o?.GetType}[{_ObjectToString(o)}]' );

begin
  var b0 := new Buffer(1);
  
  OtpObject(Context.Default.SyncInvoke( b0.NewQueue as CommandQueue<Buffer>   ));
  OtpObject(Context.Default.SyncInvoke( HFQ( ()->5                          ) ));
  OtpObject(Context.Default.SyncInvoke( HFQ( ()->'abc'                      ) ));
  OtpObject(Context.Default.SyncInvoke( HPQ( ()->Writeln('Выполнилась HPQ') ) ));
  
end.