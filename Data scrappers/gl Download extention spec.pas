var wc := new System.Net.WebClient;

function GetAllRefs(page: string): sequence of string;
const search_for = '</a></td><td><a href="';
begin
  var text := wc.DownloadString(page);
  
  var ind := 0;
  while true do
  begin
    ind := text.IndexOf(search_for,ind);
    if ind=-1 then break;
    ind += search_for.Length;
    
    var ind2 := text.IndexOf('"', ind);
    yield page+text.Substring(ind, ind2-ind);
    
  end;
  
end;

function GetAllFileRefs(page: string): sequence of string :=
GetAllRefs(page)
.Skip(1) // Parent Directory
.SelectMany(link->
  link.EndsWith('/') ?
  GetAllFileRefs(link) :
  Seq(link)
);

begin
  System.IO.Directory.Delete('gl ext spec',true);
  
  foreach var link in GetAllFileRefs('https://www.khronos.org/registry/OpenGL/extensions/') do
  begin
    
    var text := wc.DownloadString(link);
    text := text.Remove(#13).Replace(#9,' '*4);
    while text.Contains(' '#10) do text := text.Replace(' '#10, #10);
    
    var fname := link.Replace('https://www.khronos.org/registry/OpenGL/extensions', 'gl ext spec').Println;
    System.IO.Directory.CreateDirectory(fname.Remove(fname.LastIndexOf('/')));
    text := text.Replace('New Procedures and'#10'Functions', 'New Procedures and Functions');
    WriteAllText(fname, text);
    
  end;
  
  writeln;
  writeln('done');
  if not CommandLineArgs.Contains('SecondaryProc') then Readln;
end.