uses FuncFormatData;

procedure STAProc :=
try
  var farg := CommandLineArgs.Where(arg->arg.StartsWith('fname=')).SingleOrDefault;
  if farg<>nil then farg := farg.SubString('fname='.Length);
  
  var text := farg=nil ? System.Windows.Forms.Clipboard.GetText : ReadAllText(farg, new System.Text.UTF8Encoding(true));
  
  text := ReadGLFuncs(text).JoinIntoString('');
  
  if farg<>nil then
    WriteAllText(farg, text, new System.Text.UTF8Encoding(true)) else
  begin
    System.Windows.Forms.Clipboard.SetText(text);
    System.Console.Beep;
  end;
  
except
  on e: Exception do
  begin
    writeln(e);
    if not CommandLineArgs.Contains('SecondaryProc') then Readln;
  end;
end;

begin
  var thr := new System.Threading.Thread(STAProc);
  thr.ApartmentState := System.Threading.ApartmentState.STA;
  thr.Start;
end.