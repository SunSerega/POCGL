uses BinSpecData;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

begin
  var a := ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\SpecFormating\GLExt\ext spec texts\NV\NV_copy_image.txt');
  a.NewFuncs.funcs.PrintLines(t->t[1]);
end.