unit CLArgs;

function GetArgs(key: string) := CommandLineArgs
  .Where(arg->arg.StartsWith(key+'='))
  .Select(arg->arg.SubString(key.Length+1));

end.