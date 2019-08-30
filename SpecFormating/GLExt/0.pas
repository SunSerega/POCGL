uses BinSpecData;
uses MiscUtils in '..\..\Utils\MiscUtils.pas';

begin
  var a := ExtSpec.InitFromFile('SpecFormating\GLExt\ext spec texts\NV\NV_vertex_array_range.txt');
  a.NewFuncs.funcs.PrintLines;
end.