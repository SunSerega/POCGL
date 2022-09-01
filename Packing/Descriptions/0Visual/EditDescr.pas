{$apptype windows}

{$reference PresentationFramework.dll}
{$reference PresentationCore.dll}
{$reference WindowsBase.dll}

uses System;
uses System.Windows;
uses System.Windows.Media;
uses System.Windows.Controls;
uses System.Windows.Documents;

uses Fixers       in '..\..\..\Utils\Fixers';
uses Parsing      in '..\..\..\Utils\Parsing';
uses PathUtils    in '..\..\..\Utils\PathUtils';

uses Markings;

uses PABCSystem;

const
  inp_file_ext = '.dat';
  
var enc := new System.Text.UTF8Encoding(true);

[Cache]
function ColorFromKey(key: object): Color;
begin
  var rng := new System.Random(key.ToString.GetHashCode);
  Result := Color.FromRgb(rng.Next(200,250), rng.Next(50,200), rng.Next(50,200));
end;

//TODO Наверное придётся засунуть весь текст файла в один FixedTextBox
// - И тогда все особые вещи оборачивать в Span'ы и менять во время редактирования текста
// - Вообще, лучше сделать специальную систему подсветки
// --- (Файл TextMarking.pas)
// --- [%key%] и все связанные {%key%}
// --- %key% со ссылкой на источник
// - Как тогда поступать с раскрытием [+]
// --- Попробовать вставлять TextBlock в инлайны - будет ли он выделяться/редактироваться?

type
  FixedTextBox = sealed class(ContentControl)
    public tb := new RichTextBox;
    
    public constructor;
    begin
      self.Content := tb;
      self.IsTabStop := false;
      
      // Otherwise 1 letter per line
//      self.SizeChanged += (o,e)->(
//        tb.Document.PageWidth := e.NewSize.Width
//      );
      
      tb.Document.LineHeight := 1;
      
      tb.VerticalScrollBarVisibility := ScrollBarVisibility.Auto;
      tb.HorizontalScrollBarVisibility := ScrollBarVisibility.Auto;
      
      tb.PreviewMouseWheel += (o,e)->
      if System.Windows.Input.Keyboard.Modifiers.HasFlag(System.Windows.Input.ModifierKeys.Shift) then
      begin
        var scr := if e.Delta<0 then tb.LineRight else tb.LineLeft;
        loop Abs(Round(e.Delta/60)) do scr;
        e.Handled := true;
      end;
      
    end;
    
  end;
  
  InputDialog = sealed class(Window)
    private tb := new {Rich}TextBox;
    
    public constructor(title, descr, default_inp: string; validate: string->string);
    begin
      self.Title := title;
      self.SizeToContent := System.Windows.SizeToContent.WidthAndHeight;
      self.MinWidth := 300;
      
      var sp := new StackPanel;
      self.Content := sp;
      
      var descr_l := new &Label;
      sp.Children.Add(descr_l);
      descr_l.Content := descr;
      
      sp.Children.Add(tb);
      tb.Margin := new Thickness(5);
      var last_err := default(string);
      tb.TextChanged += (o,e)->
      begin
        last_err := validate(tb.Text);
        tb.Background := if last_err=nil then
          Brushes.White else
          Brushes.LightPink;
      end;
      tb.Text := default_inp;
      tb.Focus;
      tb.SelectionStart := default_inp.Length;
      
      self.KeyDown += (o,e)->
      case e.Key of
        System.Windows.Input.Key.Enter:
        if last_err<>nil then
          MessageBox.Show(last_err, 'Invalid input') else
        begin
          self.DialogResult := true;
          self.Close;
        end;
        System.Windows.Input.Key.Escape:
        begin
          self.DialogResult := false;
          self.Close;
        end;
      end;
      
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public static function Ask(title, descr, default_inp: string; validate: string->string): string;
    begin
      var d := new InputDialog(title, descr, default_inp, validate);
      Result := if d.ShowDialog = true then
        d.tb.Text else nil;
//      Result := if d.ShowDialog = true then
//        TextRange.Create(
//          d.tb.Document.ContentStart, d.tb.Document.ContentEnd
//        ).Text else nil;
    end;
    
  end;
  
  FileListItem = sealed class(TreeViewItem)
    
    public static function MakeName(path: string): string;
    begin
      Result := System.IO.Path.GetFileName(path);
      var s := Result.Split(|' '|,2);
      if (s.Length=2) and s[0].All(char.IsDigit) then
        Result := s[1];
    end;
    
    public constructor(cont_by_dir: Dictionary<string, ItemsControl>; path: string; update: ()->(); on_selected: string->());
    begin
      self.ContextMenu := new System.Windows.Controls.ContextMenu;
      
      var h := new ContentControl;
      self.Header := h;
      h.IsTabStop := false;
      h.Content := MakeName(path);
      h.Margin := new Thickness(0,0,5,0);
      
      var cont := cont_by_dir[System.IO.Path.GetDirectoryName(path)];
      cont.Items.Add(self);
      
      var is_file := FileExists(path);
      if is_file then
        self.Selected += (o,e)->on_selected(path) else
      begin
        cont_by_dir.Add(path, self);
        
        foreach var item_type in |'File','Dir'| do
        begin
          var item_is_file := item_type='File';
          
          var cm_item := new MenuItem;
          self.ContextMenu.Items.Add(cm_item);
          cm_item.Header := $'Add {item_type.ToLower}';
          cm_item.Click += (o,e)->
          try
            var item_path := InputDialog.Ask($'Add {item_type.ToLower}', $'{item_type} name:', '', item_path->
            begin
              
              try
                System.IO.Path.GetFullPath(item_path);
              except
                Result := 'Invalid symbols in path';
                exit;
              end;
              
              if '\/'.Any(ch->ch in item_path) then
                Result := $'Expected file in current ({GetRelativePath(item_path, ''..'')}) directory' else
                Result := nil;
              
            end);
            if item_path=nil then exit;
            
            if item_is_file and (System.IO.Path.GetExtension(item_path)<>inp_file_ext) then
              item_path += inp_file_ext;
            item_path := GetFullPath(item_path, path);
            
            if item_is_file then
              System.IO.File.Create(item_path).Close else
              System.IO.Directory.CreateDirectory(item_path);
            new FileListItem(cont_by_dir, item_path, update, on_selected);
            
          except
            on ex: Exception do MessageBox.Show(ex.ToString);
          end;
        end;
        
      end;
      
      begin
        var cm_item := new MenuItem;
        self.ContextMenu.Items.Add(cm_item);
        cm_item.Header := 'Rename';
        cm_item.Click += (o,e)->
        try
          var new_path := InputDialog.Ask($'Rename {path}', $'New name:', System.IO.Path.GetFileName(path), new_path->
          begin
            
            try
              System.IO.Path.GetFullPath(new_path);
            except
              Result := 'Invalid symbols in path';
              exit;
            end;
            
            Result := nil;
          end);
          if new_path=nil then exit;
          
          if is_file and (System.IO.Path.GetExtension(new_path)<>inp_file_ext) then
            new_path += inp_file_ext;
          new_path := GetFullPath('..\'+new_path, path);
          
          if is_file then
            System.IO.File.Move(path, new_path) else
            System.IO.Directory.Move(path, new_path);
          
          h.Content := MakeName(new_path);
          path := new_path;
        except
          on ex: Exception do MessageBox.Show(ex.ToString);
        end;
      end;
      
      begin
        var cm_item := new MenuItem;
        self.ContextMenu.Items.Add(cm_item);
        cm_item.Header := 'Delete';
        cm_item.Click += (o,e)->
        try
          case MessageBox.Show($'Delete [{path}]?', 'Confirm', MessageBoxButton.YesNo) of
            MessageBoxResult.Yes: ;
            MessageBoxResult.No: exit;
            else raise new System.InvalidOperationException;
          end;
          
          if is_file then
            System.IO.File.Delete(path) else
            System.IO.Directory.Delete(path, true);
          
          cont.Items.Remove(self);
          
          update();
        except
          on ex: Exception do MessageBox.Show(ex.ToString);
        end;
      end;
      
    end;
    private constructor := raise new System.InvalidOperationException;
    
  end;
  
  InpFileView = sealed class
    private body := new FixedTextBox;
    
    public constructor(fname: string);
    begin
      
      {$region Remarking thread}
      
      var system_text_change := false;
      var remark_wh := new System.Threading.ManualResetEventSlim(false);
      var last_text := default(string);
      
        //TODO #????
        var write_timings := false;
        var sw := new Stopwatch;
        
      System.Threading.Thread.Create(()->
      begin
        
        while true do
        try
          remark_wh.Wait;
          remark_wh.Reset;
          if write_timings then
            sw.Restart;
          
          var spans := new List<(SIndexRange, SolidColorBrush)>;
          var text := new StringSection(last_text.Remove(#13));
          if text.EndsWith(#10) then text := text.TrimLast(1);
          WriteAllText(fname, text.ToString, enc);
          
          {$region Find markables}
          begin
            var known_template_names: HashSet<string>;
            
            DescrFileMarksInfo.Instance.MarkAll(text, (s,eot,info)->
            begin
              match info with
                DescrBlockMarks(var m):
                if s.Next(text.Length)='#' then // "not eot" baked in
                  Result := StringIndex.Invalid else // Continue search for the end of heads
                begin
                  begin
                    var c := s.Prev(0);
                    if (c<>nil) and (c<>#10) then
                    begin
                      Result := s.I1+1;
                      exit;
                    end;
                  end;
                  known_template_names := nil;
                  
                  var text := s;
                  m.MarkAll(text, (s,eot,info)->
                  begin
                    match info with
                      DescrHeadMarks(var m):
                      begin
                        begin
                          var c := s.Prev(0);
                          if (c<>nil) and (c<>#10) then
                          begin
                            Result := s.I1+1;
                            exit;
                          end;
                        end;
                        var curr_head_template_names := new HashSet<string>;
                        
                        var text := s;
                        var i := 0;
                        m.MarkAll(text, (s,eot,info)->
                        begin
                          match info with
                            DescrHeadTemplateMarks(var m):
                            begin
                              Result := s.I2;
                              if eot then exit;
                              var ind := s.IndexOf(':');
                              var name := if ind.IsInvalid then
                                i.ToString else
                                s.TakeFirst(ind).TrimFirst(2).ToString;
                              if not curr_head_template_names.Add(name) then exit;
                              i += 1;
                              
                              spans += (s.range, Brushes.LightBlue);
                              
                            end;
                            else raise new NotImplementedException;
                          end;
                        end);
                        
                        if known_template_names=nil then
                          known_template_names := curr_head_template_names else
                          known_template_names.IntersectWith(curr_head_template_names);
                        Result := s.I2-1;
                      end;
                      else raise new NotImplementedException;
                    end;
                  end);
                  
                  Result := s.I2;
                end;
                DescrBodyTemplateMarks(var m):
                begin
                  Result := s.I2;
                  if eot then exit;
                  if known_template_names=nil then exit;
                  
                  var inner := s.TrimFirst(2).TrimLast(2);
                  var ind := inner.IndexOf('?');
                  var name_s := if ind.IsInvalid then
                    inner else
                    inner.TakeFirst(ind)
                  ;
                  
                  spans += (s.range,
                    if name_s.ToString in known_template_names then
                      Brushes.LightGreen else
                      Brushes.Pink
                  );
                  
                end;
                else raise new NotImplementedException;
              end;
            end);
            
          end;
          {$endregion Find markables}
          
          if write_timings then
          begin
            $'Recalc in {sw.Elapsed}'.Println;
            sw.Restart;
          end;
          if remark_wh.IsSet then continue;
          
          var cuts := new List<(string, SolidColorBrush)>;
          begin
            var head := text;
            
            foreach var (r,b) in spans do
            begin
              if head.I1<>r.i1 then
              begin
                cuts += (head.WithI2(r.i1).ToString, Brushes.Transparent);
                head.range.i1 := r.i1;
              end;
              
              cuts += (head.WithI2(r.i2).ToString, b);
              head.range.i1 := r.i2;
            end;
            if (head.Length<>0) or (cuts.Count=0) then
              cuts += (head.ToString, Brushes.Transparent);
            
          end;
          
          if write_timings then
          begin
            $'Cut in {sw.Elapsed}'.Println;
            sw.Restart;
          end;
          
          if body.tb.Dispatcher.Invoke(()->
          try
            Result := remark_wh.IsSet;
            if Result then exit;
            system_text_change := true;
            
            begin
              var ft := new FormattedText(text.text, System.Globalization.CultureInfo.InvariantCulture, FlowDirection.LeftToRight, new Typeface(
                body.FontFamily,
                body.FontStyle,
                body.FontWeight,
                body.FontStretch
              ), body.FontSize, Brushes.Black);
              body.tb.Document.PageWidth := FormattedText(ft).Width*1.1+12;
            end;
            
            var bl := body.Dispatcher.Invoke(()->
            begin
              var bls := body.tb.Document.Blocks.Cast&<Paragraph>.ToArray;
//              $'bls.Length={bls.Length}'.Println;
              Result := bls.FirstOrDefault;
              if Result=nil then
              begin
                Result := new Paragraph;
                body.tb.Document.Blocks.Add(Result);
              end else
              foreach var ebl in bls.Skip(1) do
              begin
                if not body.tb.Document.Blocks.Remove(ebl) then
                  raise new System.InvalidOperationException;
                Result.Inlines.Add(#10);
                Result.Inlines.AddRange(ebl.Inlines.ToArray);
              end;
            end);
            
            var old_key_map := body.tb.Document.Blocks
              .SelectMany(bl->Paragraph(bl).Inlines)
              .OfType&<Run>
              .ToDictionary(r->r, r->(
                Run(r).Text,
                SolidColorBrush(r.Background)
              ));
            var old_r_c := old_key_map.Values.EachCount;
            var new_r_c := cuts.EachCount;
            
            var last_new_line := false;
            begin
              var prev_ins := body.tb.CaretPosition.GetNextInsertionPosition(LogicalDirection.Backward);
              last_new_line := (prev_ins<>nil) and (prev_ins.GetOffsetToPosition(body.tb.CaretPosition)>1);
            end;
//            TextRange.Create(body.tb.Document.ContentStart, body.tb.CaretPosition).Text.Select(c->c.Code).Println;
            var cur_pos := TextRange.Create(body.tb.Document.ContentStart, body.tb.CaretPosition).Text.Length;
            
            var write_acts := false;
            
            var new_run := function(s: string; b: Brush; before: Run): Run->
            begin
              Result := new Run(s);
              Result.Background := b;
              if before=nil then
                bl.Inlines.Add(Result) else
                bl.Inlines.InsertBefore(before, Result);
            end;
            
            var next_cut_ind := 0;
//            bl.Inlines.Count.Println;
            foreach var inl in bl.Inlines.ToArray do
            begin
              var r := inl as Run;
              var old_key := if r=nil then nil else old_key_map[r];
              if (next_cut_ind=cuts.Count) or (r=nil) or (new_r_c.Get(old_key)=0) then
              begin
                if write_acts then Writeln('remove leftover');
                if not bl.Inlines.Remove(inl) then
                  raise new System.InvalidOperationException;
                continue;
              end;
//              r.Text.Length.Println;
              
              var new_key := cuts[next_cut_ind];
              if old_key=new_key then
              begin
                if write_acts then Writeln('pass already right');
                next_cut_ind += 1;
                old_r_c[new_key] -= 1;
                new_r_c[new_key] -= 1;
                continue;
              end;
              
              if new_r_c.Get(new_key)<old_r_c.Get(new_key) then
              begin
                var (s,b) := new_key;
                new_run(s, b, r);
                next_cut_ind += 1;
                new_r_c[new_key] -= 1;
              end else
              begin
                if write_acts then Writeln('remove in the way');
                old_r_c[old_key] -= 1;
                if not bl.Inlines.Remove(inl) then
                  raise new System.InvalidOperationException;
              end;
              
            end;
            for var i := next_cut_ind to cuts.Count-1 do
            begin
              var (s,b) := cuts[i];
              new_run(s, b, nil);
            end;
            
            var ptrs_len := body.tb.Document.ContentStart.GetOffsetToPosition(body.tb.Document.ContentEnd);
            var ptr := body.tb.Document.ContentStart;
            if cur_pos<>0 then
            begin
              ptr := ptr.GetPositionAtOffset(Round((cur_pos/text.Length).ClampTop(1) * (ptrs_len-1)));
  //            $'[{TextRange.Create(body.tb.Document.ContentStart, ptr).Text}]'.Println;
              while true do
              begin
//                TextRange.Create(body.tb.Document.ContentStart, ptr).Text.Select(c->c.Code).Println;
                var rel_cur_pos := cur_pos - TextRange.Create(body.tb.Document.ContentStart, ptr).Text.Length;
//                $'cur_pos={cur_pos}; rel_cur_pos={rel_cur_pos}'.Println;
                if rel_cur_pos=0 then break;
                var dir := if rel_cur_pos>0 then LogicalDirection.Forward else LogicalDirection.Backward;
                loop Abs(rel_cur_pos) do
                begin
                  ptr := ptr.GetNextInsertionPosition(dir);
//                  $'Moved {dir}'.Println;
                end;
              end;
//              Writeln('='*30);
              
              if last_new_line then
                ptr := ptr.GetNextInsertionPosition(LogicalDirection.Forward).GetLineStartPosition(1) ?? ptr;
            end;
            body.tb.CaretPosition := ptr;
//            $'[{TextRange.Create(body.tb.Document.ContentStart, ptr).Text}]'.Println;
            
          finally
            system_text_change := false;
          end{, System.Windows.Threading.DispatcherPriority.Background}) then continue;
          
          if write_timings then
          begin
            $'Remarked in {sw.Elapsed}'.Println;
//            sw.Restart;
          end;
          
//          if write_timings then
//            $'Cleanup in {sw.Elapsed}'.Println;
        except
          on e: Exception do
            MessageBox.Show(e.ToString);
        end;
      end).Start;
      
      {$endregion Remarking thread}
      
      DataObject.AddPastingHandler(body.tb, (o,e)->
      begin
        e.DataObject := new DataObject(DataFormats.UnicodeText,
          e.DataObject.GetData(DataFormats.UnicodeText) as string ?? ''
        );
      end);
      
      body.tb.TextChanged += (o,e)->
      begin
        if system_text_change then exit;
        last_text := TextRange.Create(body.tb.Document.ContentStart, body.tb.Document.ContentEnd).Text;
        remark_wh.Set;
      end;
      
      body.tb.Dispatcher.Invoke(()->
      begin
        var text := ReadAllText(fname, enc);
        Paragraph(body.tb.Document.Blocks.FirstBlock).Inlines.Add(text);
      end);
      
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public function Visual := body;
    
  end;
  
  ModuleView = sealed class(ContentControl)
    
    public constructor(name: string);
    begin
      Application.Current.MainWindow.Title := $'Editing descriptions for {name}';
      
      self.KeyDown += (o,e)->
      case e.Key of
        System.Windows.Input.Key.F5,
        System.Windows.Input.Key.BrowserRefresh:
        begin
          Application.Current.MainWindow.Content := new ModuleView(name);
          e.Handled := true;
        end;
      end;
      
      var file_display := new ContentControl;
      
      var update := procedure->
      begin
        
        var TODO := 0; // Run "..\PackDescriptions"
        
      end;
      
      var open_file := procedure(fname: string)->
      begin
        var fview := new InpFileView(fname);
        file_display.Content := fview.Visual;
//        file_display.Content := ReadAllText(path);
        var TODO := 0;
        //TODO
        // - File caching (delete when updated outside)
        // - Ctrl+S
      end;
      
      var g := new Grid;
      self.Content := g;
      loop 3 do g.ColumnDefinitions.Add(new ColumnDefinition);
      
      begin
        var tw := new TreeView;
        var cont_by_dir := new Dictionary<string, ItemsControl>;
        
        var module_dir := GetFullPathRTA('..\'+name);
        cont_by_dir.Add(module_dir, tw);
        
        foreach var path in EnumerateAllDirectories(module_dir)+EnumerateAllFiles(module_dir, '*'+inp_file_ext) do
          new FileListItem(cont_by_dir, path, update, open_file);
        
        begin
          var missing_item := new TreeViewItem;
          missing_item.Header := 'Missing';
          tw.Items.Add(missing_item);
          
          missing_item.Selected += (o,e)->
          begin
            file_display.Content := ReadAllText(module_dir+'.missing.log');
            var TODO := 0; //TODO Open missing (this is virtual file)
          end;
          
        end;
        
        var sw := new ScrollViewer;
        sw.VerticalScrollBarVisibility := ScrollBarVisibility.Auto;
        sw.HorizontalScrollBarVisibility := ScrollBarVisibility.Hidden;
        sw.FlowDirection := System.Windows.FlowDirection.RightToLeft;
        tw.FlowDirection := System.Windows.FlowDirection.LeftToRight;
        sw.Content := tw;
        
        var cd := g.ColumnDefinitions[0];
        cd.Width := new GridLength(1, GridUnitType.Star);
        sw.SizeChanged += (o,e)->(
          cd.MinWidth := sw.DesiredSize.Width
        );
        
        g.Children.Add(sw);
        Grid.SetColumn(sw, 0);
      end;
      
      begin
        var spl := new GridSplitter;
        spl.HorizontalAlignment := System.Windows.HorizontalAlignment.Stretch;
        spl.IsTabStop := false;
        
        var cd := g.ColumnDefinitions[1];
        cd.Width := new GridLength(5);
        
        g.Children.Add(spl);
        Grid.SetColumn(spl, 1);
      end;
      
      begin
        file_display.FontFamily := new System.Windows.Media.FontFamily('Cascadia Code');
        
        var cd := g.ColumnDefinitions[2];
        cd.Width := new GridLength(4, GridUnitType.Star);
        
        g.Children.Add(file_display);
        Grid.SetColumn(file_display, 2);
      end;
      
    end;
    private constructor := raise new System.InvalidOperationException;
    
  end;
  
begin
  var w := new Window;
  w.WindowState := WindowState.Maximized;
      
  w.KeyDown += (o,e)->
  case e.Key of
    System.Windows.Input.Key.Escape: w.Close;
  end;
  
  w.Loaded += (o,e)->
  begin
    
    var sw := new ScrollViewer;
    w.Content := sw;
    
    var sp := new StackPanel;
    sw.Content := sp;
    
    foreach var name in EnumerateFiles('..\', '*.predoc').Select(System.IO.Path.GetFileNameWithoutExtension) do
    begin
      
      var b := new Button;
      sp.Children.Add(b);
      b.Content := name;
      
      b.Click += (o,e)->
      begin
        w.Content := new ModuleView(name);
      end;
      
    end;
    
    var TODO := 0; //TODO Comment out
    w.Content := new ModuleView('OpenCLABC');
  end;
  
  Halt(Application.Create.Run(w));
end.