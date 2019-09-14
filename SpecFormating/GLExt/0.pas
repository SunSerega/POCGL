uses BinSpecData;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

begin
  var a := ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\Reps\OpenGL-Registry\extensions\EXT\EXT_direct_state_access.txt');
//  exit;
  a.NewFuncs.funcs.PrintLines;
end.