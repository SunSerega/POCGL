uses BinSpecData;

begin
  
  var f := ExtSpec.InitFromFile('D:\1Cергей\Мои программы\проекты\POCGL\Data scrappers\gl ext spec\EXT\EXT_separate_shader_objects.gles.txt');
  f.NewFuncs.funcs.Select(f->f[0]).PrintLines;
  
end.