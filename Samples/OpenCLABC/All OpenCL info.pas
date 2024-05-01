## uses OpenCLABC;

foreach var pl in CLPlatform.All do
begin
  Println(pl);
  Println(pl.Properties);
  foreach var dvc in CLDevice.GetAllFor(pl, clDeviceType.DEVICE_TYPE_ALL) do
  begin
    Println('~'*70);
    Println(dvc);
    Println(dvc.Properties);
  end;
  Println('='*90);
end;

