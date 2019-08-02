uses BinSpecData;

begin
  
  var f := ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\Data scrappers\gl ext spec\EXT\EXT_vertex_shader.txt');
  f.NewFuncs.funcs.Select(f->f[0]).PrintLines;
  
end.