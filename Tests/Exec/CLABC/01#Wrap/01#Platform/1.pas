uses OpenCLABC;

begin
  var pl := Platform.All[0];
  Writeln(pl.GetType);
  Writeln(pl.Properties.GetType);
  var pl2 := new Platform(pl.Native);
  (pl=pl2).Println;
  Arr(pl).Contains(pl2).Println;
  Writeln(pl2.GetType);
  Writeln(pl2.Properties.GetType);
end.