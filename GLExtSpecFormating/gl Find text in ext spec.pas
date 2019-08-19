
{$apptype windows}
{$reference System.Windows.Forms.dll}

const
  Notepad = 'C:\Program Files\Notepad++\notepad++.exe';

begin
  var search_for := System.Windows.Forms.Clipboard.GetText;
  
  foreach var fname in System.IO.Directory.EnumerateFiles('gl ext spec', '*.txt', System.IO.SearchOption.AllDirectories) do
    if ReadAllText(fname).Contains(search_for) then
    begin
      writeln(fname);
      System.Diagnostics.Process.Start(Notepad, $'"{System.IO.Path.GetFullPath(fname)}"');
      System.Console.Beep;
    end;
  
end.