## uses OpenCLABC;

procedure Test(inp: CommandQueue<CLKernel>);
begin
  var Q := CLKernelCCQ.Create(inp).ThenExec1(1, 0).DiscardResult;
  CLContext.Default.SyncInvoke(Q);
  CLContext.Default.SyncInvoke(Q);
end;

var code := CLProgramCode.Create(
  '#define K(name) kernel void name(int x) {}'#10
  'K(k1) K(k2) K(k3)'
);
Test(code['k1']);
Test(new ParameterQueue<CLKernel>('k2', code['k2']));
Test(HFQ(()->code['k3'], false));

ExecDebug.ReportExecCache;