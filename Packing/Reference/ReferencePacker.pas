{$reference '!MarkDig/Markdig.dll'}
uses System.IO;

uses '../../POCGL_Utils';
uses '../../Utils/AOtp';

type
  HTML = static class
    // Справка расширений:
    // https://github.com/lunet-io/markdig/blob/master/src/Markdig.Tests/Specs/readme.md
    private static md_pipeline := Markdig.MarkdownPipelineBuilder.Create
      .UseEmphasisExtras    // перечёркивание с ~~text~~ и т.п.
      .UseCustomContainers  // блоки-спойлеры
      .UseGenericAttributes // прямое указание атрибутов html элемента, надо для спойлеров
    .Build;
    
    private static last_page_id: integer;
    
    public static procedure AddPage(sw: StreamWriter; path: string);
    begin
      last_page_id += 1;
      
      var page_name := System.IO.Path.GetFileName(path);
      if '#' in page_name then page_name := page_name.Substring(page_name.IndexOf('#')+1);
      
      sw.WriteLine($'<div id="page-{last_page_id}" page_name="{page_name}" hidden=true>');
      
      if &File.Exists(path+'.css') then
      begin
        sw.WriteLine('<style>');
        sw.WriteLine(ReadAllText(path+'.css').Trim);
        sw.WriteLine('</style>');
      end;
      
      sw.WriteLine(Markdig.Markdown.ToHtml(
        ReadAllText(path+'.md'),
        md_pipeline
      ).Trim);
      
      if &File.Exists(path+'.js') then
      begin
        sw.WriteLine('<script>');
        sw.WriteLine(ReadAllText(path+'.js').Trim);
        sw.WriteLine('</script>');
      end;
      
      sw.WriteLine($'</div>');
    end;
    
    public static procedure AddFolder(sw: StreamWriter; dir: string);
    begin
      var dir_name := Path.GetFileName(dir);
      if '#' in dir_name then dir_name := dir_name.Substring(dir_name.IndexOf('#')+1);
      
      if &File.Exists(dir+'/.md') then
      begin
        AddPage(sw, dir+'/');
        sw.WriteLine($'<script>on_start_folder("{dir_name}", document.getElementById("page-{last_page_id}"))</script>');
      end else
        sw.WriteLine($'<script>on_start_folder("{dir_name}", null)</script>');
        
      foreach var sub_dir in Directory.EnumerateDirectories(dir) do
        AddFolder(sw, sub_dir);
      
      foreach var fname in Directory.EnumerateFiles(dir, '*.md') do
        if Path.GetFileNameWithoutExtension(fname) <> '' then
        begin
          AddPage(sw, Path.ChangeExtension(fname, nil));
          sw.WriteLine($'<script>on_page_added(document.getElementById("page-{last_page_id}"))</script>');
        end;
      
      sw.WriteLine($'<script>on_end_folder()</script>');
    end;
    
    public static procedure Pack(path, otp: string);
    begin
      var nick := otp.Remove(otp.LastIndexOf('.'));
      POCGL_Utils.Otp($'Packing reference "{nick}"');
      last_page_id := 0;
      
      var ReleaseDir := GetFullPathRTA('0Release');
      System.IO.Directory.CreateDirectory(ReleaseDir);
      
      path := GetFullPathRTA(path);
      otp  := GetFullPath(otp, ReleaseDir);
      
      var sw := new StreamWriter(otp, false, enc);
      sw.WriteLine('<!DOCTYPE html>');
      sw.WriteLine('<html>');
      sw.WriteLine('<head>');
      sw.WriteLine('<meta charset="utf-8">');
      
      sw.WriteLine('<link rel="stylesheet" href="Common/0.css" />');
      
      sw.WriteLine('</head>');
      sw.WriteLine('<body>');
      
      sw.WriteLine(Markdig.Markdown.ToHtml(
        ReadAllText(GetFullPathRTA('Common.md')),
        md_pipeline
      ).Trim);
      
      sw.WriteLine('<script src="Common/0.js" ></script>');
      
      if System.IO.Directory.Exists(path) then AddFolder(sw, path);
      
      sw.WriteLine('</body>');
      sw.WriteLine('</html>');
      sw.Close;
      
      POCGL_Utils.Otp($'Done packing feference "{nick}"');
    end;
    
  end;
  
begin
  try
    
    HTML.Pack('Index',          'index.html');
    HTML.Pack('Native Interop', 'Гайд по использованию OpenGL и OpenCL.html');
    HTML.Pack('GL ABC',         'Справка OpenGLABC.html');
    HTML.Pack('CL ABC',         'Справка OpenCLABC.html');
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.