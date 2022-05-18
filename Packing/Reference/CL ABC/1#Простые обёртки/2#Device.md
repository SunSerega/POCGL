


Обычно устройства получают статическим методом `Device.GetAllFor`:
```
## uses OpenCLABC;

foreach var pl in Platform.All do
begin
  Writeln(pl);
  var dvcs := Device.GetAllFor(pl, DeviceType.DEVICE_TYPE_ALL);
  if dvcs<>nil then dvcs.PrintLines;
  Writeln('='*30);
end;
```
И в большинстве случаев - это всё что вам понадобится.

---

Но если где то нужен более тонкий контроль - можно создать несколько виртуальных
под-устройств, каждому из которых даётся часть ядер изначального устройства.\
Для этого используются методы `.Split*`:
```
## uses OpenCLABC;

var dvc := Context.Default.MainDevice;

Writeln('Поддерживаемые типы .Spilt-ов:');
var partition_properties := dvc.Properties.PartitionProperties;
if (partition_properties.Length=0) or (partition_properties[0].val = System.IntPtr.Zero) then
begin
  Writeln('Ничего не поддерживается...');
  exit;
end else
  partition_properties.PrintLines;
Writeln('='*30);

Writeln('Виртуальные устройства, по 1 ядру каждое:');
if dvc.CanSplitEqually then
  // Если упадёт потому что слишком много
  // устройств - пожалуйста, напишите в issue
  dvc.SplitEqually(1).PrintLines else
  Writeln('Не поддерживается...');
Writeln('='*30);

Writeln('Два устройства, 1 и 2 ядра соответственно:');
if dvc.CanSplitByCounts then
  dvc.SplitByCounts(1,2).PrintLines else
  Writeln('Не поддерживается...');
Writeln('='*30);

```


