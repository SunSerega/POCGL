## uses OpenCLABC;

Println(
  ProgramCode.Create('kernel void k(int x) {}')['k']
);