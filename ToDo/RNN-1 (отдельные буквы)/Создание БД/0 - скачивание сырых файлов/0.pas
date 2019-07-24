uses System.Threading.Tasks;

// большинство сайтов заставляют покупать бумажные книги
// или сильно ограничивали кол-во подряд скачиваемых книг (сайт тупо меня блокировал на 5 мин)
// я сайтов 50 перебрал перед тем как найти это старьё
// зато, у старья - нету сильно сложной графики, так что ссылки вытягивать легко
// ну а жанр детский - чтоб небыло "сликом взрослых" книг
// чтоб ИИ плохому не научить))
const url_base = 'https://www.litlib.net';
const url_page_mask = url_base + '/genre/90/page%';
const page_num1 = 0;
const page_count = 20;

// если сайт раздаёт архивы (как в данном случае)
// надо чтоб их могло автоматически распаковать
// у 7z нет нормального интерфейса и тихого режима (чтоб окно не создавалось)
// но зато, в отличии от WinRAR - он точно распакует что угодно
// хоть образы дисков, хоть даже .exe файлы (правда, там ничего интересного)
const path_to_7z = 'C:\Program Files\7-Zip\7zG.exe';

type
  BookFileDownloader = auto class
    book_url: string;
    book_name: string;
    
    procedure Download :=
    try
      book_name := book_name.Select(ch->
        System.IO.Path.InvalidPathChars.Contains(ch) or
        '\/'.Contains(ch)?
        '_':ch
      ).JoinIntoString;
      
      // скачиваем
      System.Net.WebClient.Create.DownloadFile(book_url, $'{book_name}.zip');
      
      if ReadAllText($'{book_name}.zip').Contains('!DOCTYPE html') then
      begin
        lock output do writeln($'ссылка скачала не архив - {book_url}');
        System.IO.File.Delete($'{book_name}.zip');
        exit;
      end;
      
      // распаковываем
      System.Diagnostics.Process.Start(
        path_to_7z,
        $'x "{book_name}.zip" -o"{book_name}"'
      ).WaitForExit;
      Sleep(500); // чот его глючит немного без задержки
      System.IO.File.Delete($'{book_name}.zip');
      
      // вытаскиваем из распакованой папки
      System.IO.File.Move(
        System.IO.Directory.EnumerateFiles(book_name).Single,
        $'{book_name}.txt'
      );
      System.IO.Directory.Delete(book_name);
      
    except
      on e: Exception do
        $'{book_name}{#10}{book_url}{#10}{e.GetType} : {e.Message}'.Println;
    end;
    
  end;
  
  SubPageSearcher = auto class
    page_url: string;
    
    const search_for1 = '/txt';
    const search_for2 = 'href="';
    
    const search_for3 = 'id="hbkname">';
    const search_for4 = '</div>';
    
    procedure Search :=
    try
      var page_bytes := System.Net.WebClient.Create.DownloadData(page_url); // тут автоматически выбранная кодировка - ломала русские буквы (название книги), так что пришлось её выбирать ручками
      var page := System.Text.Encoding.UTF8.GetString(page_bytes);
      
      var ind1 := page.IndexOf(search_for1,0);
      if ind1=-1 then
      begin
        lock output do writeln($'TXT файл не найден - {page_url}');
        exit;
      end;
      ind1 := page.LastIndexOf(search_for2, ind1) + search_for2.Length;
      
      var ind2 := page.IndexOf(search_for3) + search_for3.Length;
      
      BookFileDownloader.Create(
        url_base + page.Substring(ind1, page.IndexOf('"',ind1) - ind1),
        page.Substring(ind2, page.IndexOf(search_for4,ind2) - ind2)
      ).Download;
      
    except
      on e: Exception do
        $'{page_url}{#10}{e.GetType} : {e.Message}'.Println;
    end;
    
  end;
  
  MainPageSearcher = auto class
    pagenum: integer;
    
    const search_for1 = '<a class="book" href="'; // что искать - видно если в браузере нажать Ctrl+Shift+C и тыкнуть на часть которую надо найти
    const search_for2 = '<a class="book" href="/bk/'; // костыльчик чтоб выдавало только ссылки на книги, а то class="book" есть так же у ссылок на обсуждения
    
    procedure Search :=
    try
      var page := System.Net.WebClient.Create.DownloadString(url_page_mask.Replace('%',pagenum.ToString));
//      WriteAllText('0.html', page); // если надо будет про Ctrl+F -ить руками, чтоб увидеть что там такого нетакого находит
      
      var tasks := new List<Task>;
      
      var ind := 0;
      while true do
      begin
        ind := page.IndexOf(search_for2,ind);
        if ind=-1 then break;
        ind += search_for1.Length;
        
        tasks += Task.Run(
          SubPageSearcher.Create(
            url_base + page.Substring(ind, page.IndexOf('"',ind) - ind)
          ).Search
        );
        
      end;
      
      Task.WaitAll(tasks.ToArray);
    except // обязательно нужно сделать всё обработчики, чтоб сразу узнать если что то пойдёт не так
      on e: Exception do
        $'{e.GetType} : {e.Message}'.Println;
    end;
    
  end;

begin
  
  if System.IO.Directory.Exists('files') then System.IO.Directory.Delete('files', true);
  System.IO.Directory.CreateDirectory('files');
  System.Environment.CurrentDirectory += '\files';
  
  // из за того что сайт старый - System.Windows.Forms.WebBrowser не нужен
  // достаточно скачать страницу в виде .html сайта (а в нашем случае без файла, то есть строкой)
  // что делается в 1 строчку, через System.Net.WebClient
  //
  // но вообще на большинстве сайтов в наше время страницы динамичны
  // то есть их догружает после того как основной .html файл скачался
  // если у вас будет загружатся только кусок страницы - вы знаете что юзать
  
  var done_c := 0;
  
  {$omp parallel for}
  for var i := page_num1 to page_num1+page_count-1 do
  begin
    MainPageSearcher.Create(i).Search;
    lock output do
    begin
      done_c += 1;
      writeln($'обработано {done_c} страниц');
    end;
  end;
  
end.