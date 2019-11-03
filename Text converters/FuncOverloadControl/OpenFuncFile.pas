{$apptype windows}
{$reference System.Windows.Forms.dll}

uses System.Windows.Forms;

begin
  if not Clipboard.ContainsText then
  begin
    Writeln('no text copied');
    readln;
  end;
  var fn := 'F%'+Clipboard.GetText.Trim+#10;
  
  var done := 0;
  foreach var fname in System.IO.Directory.EnumerateFiles(GetCurrentDir, '*.cfg', System.IO.SearchOption.AllDirectories) do
    if ReadAllText(fname).Remove(#13).Contains(fn) then
    begin
      Exec(fname);
      done += 1;
    end;
  
  if done<>1 then
  begin
    Write(fn);
    Writeln($'Found {done}');
    readln;
  end;
end.