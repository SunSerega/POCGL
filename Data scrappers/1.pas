begin
  System.IO.Directory.EnumerateFiles('gl ext spec','*.txt',System.IO.SearchOption.AllDirectories)
  .SelectMany(f->ReadLines(f))
  .Where(l->l.ToLower.Contains('procedure'))
  .Distinct
  .Sorted
  .PrintLines;
end.