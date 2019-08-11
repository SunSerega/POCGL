uses BinSpecData;

begin
  BinSpecDB.LoadFromFile('gl ext spec.bin').exts
  .Where(ext->ext.NewFuncs<>nil)
  .SelectMany(ext->ext.NewFuncs.funcs)
  .Select(f->f[0])
  .PrintLines;
end.