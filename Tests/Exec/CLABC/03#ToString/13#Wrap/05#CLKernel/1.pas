## uses OpenCLABC;

Println(
  CLProgramCode.Create('kernel void k(int x) {}')['k']
);