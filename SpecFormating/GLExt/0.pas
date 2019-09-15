uses BinSpecData;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

begin
  var a := ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\SpecFormating\GLExt\ext spec texts\EXT\GLX_EXT_import_context.txt');
  a.NewFuncs.funcs.PrintLines(t->t[1]);
end.