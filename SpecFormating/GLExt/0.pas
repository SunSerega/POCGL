uses BinSpecData;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

begin
  var a := ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\Reps\OpenGL-Registry\extensions\SGIX\GLX_SGIX_fbconfig.txt');
//  exit;
  a.NewFuncs.funcs.PrintLines(t->t[0]);
end.