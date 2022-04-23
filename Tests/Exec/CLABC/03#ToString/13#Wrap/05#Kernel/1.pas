## uses OpenCLABC;

Println(
  ProgramCode.Create(Context.Default, 'kernel void k() {}')['k']
);