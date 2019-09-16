uses BinSpecData;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

begin
  var a := ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\SpecFormating\GLExt\ext spec texts\ARB\ARB_robustness.txt');
  a.NewFuncs.funcs.PrintLines(t->t[1]);
  a.is_complete.Println;
end.