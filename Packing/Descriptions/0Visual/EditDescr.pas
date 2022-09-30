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
uses SubExecuters in '..\..\..\Utils\SubExecuters';

uses Markings;

uses PABCSystem;

const
  inp_file_ext = '.dat';
  
var enc := new System.Text.UTF8Encoding(true);

[Cache]
function ColorFromKey(key: object): Color;
begin
  var rng := new System.Random(key.ToString.GetHashCode);
  Result := Color.FromRgb(rng.Next(100,150), rng.Next(150,250), rng.Next(150,250));
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
  FileState = (FS_OK, FS_Unused, FS_Error);
    
    public static function MakeName(path: string): string;
    begin
      Result := System.IO.Path.GetFileName(path);
      var s := Result.Split(|' '|,2);
      if (s.Length=2) and s[0].All(char.IsDigit) then
        Result := s[1];
    end;
    
    private parent_item: FileListItem;
    private state := FS_OK;
    private all_names := new HashSet<string>;
    private own_names := new HashSet<string>;
    private procedure ResetState;
    begin
      var sub_items := Items.Cast&<FileListItem>;
      var new_state := sub_items.Max(i->i.state);
      
      if new_state < FS_Error then
      begin
        all_names.Clear;
        all_names.UnionWith(own_names);
        foreach var i in sub_items do
        begin
          var c := all_names.Count + i.all_names.Count;
          all_names.UnionWith(i.all_names);
          if all_names.Count <> c then new_state := FS_Error;
        end;
      end;
      
      if self.state = new_state then exit;
      self.state := new_state;
      var TODO_main := 0; //TODO А что если одно имя 2 раза в совсем разных папках
      // Нужен Dict<header, HashSet<FileListItem>>
      if parent_item<>nil then parent_item.ResetState;
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
      self.parent_item := cont as FileListItem;
      
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
    private headers := new List<(array of string, Run)>;
    
    private static function MakeHeaderColor(names: array of string; unused, used: HashSet<string>): SolidColorBrush;
    begin
      var c := names.Count(unused.Contains);
      Result :=
        if c+names.Count(used.Contains) < names.Length then
          Brushes.Transparent else
        if c=0 then
          Brushes.LightGreen else
        if c=names.Length then
          Brushes.Red else
          Brushes.Orange;
    end;
    
    public constructor(fname: string; readonly: boolean; file_lock: Object; update: ()->(); unused_headers, used_headers: HashSet<string>);
    begin
      
      var TODO_long := 0;
      //TODO Proper spans/cuts system, with recursion, abstract classes and etc.
      // - Openable templates (any in the name), creating own new textbox ('s?)
      // - %key% with a Ctrl+Click to tp to definition
      
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
          var named_spans := new Dictionary<integer, array of string>;
          var text := new StringSection(last_text.Remove(#13));
          if text.EndsWith(#10) then text := text.TrimLast(1);
          //TODO Better send to update thread
          if not readonly then lock file_lock do
          begin
            var temp_fname := fname+'.backup';
            System.IO.File.Move(fname, temp_fname);
            WriteAllText(fname, text.ToString, enc);
            System.IO.File.Delete(temp_fname);
            update;
          end;
          
          {$region Find markables}
          begin
            var known_template_names: HashSet<string>;
            
            //TODO #????
            var body := body;
            var unused_headers := unused_headers;
            var used_headers := used_headers;
            
            DescrFileMarksInfo.Instance.MarkAll(text, (s,eot,info)->
            begin
              match info with
                DescrBlockMarks(var m):
                if not eot and (s.Next(text.I2)='#') then
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
                        
                        var text := s.TrimFirst(1).TrimWhile(char.IsWhiteSpace);
                        var names := FixerUtils.DeTemplateName(text).ConvertAll(\(name,conv)->name);
                        named_spans.Add(spans.Count, names);
                        spans += (s.TakeFirst(1).range, body.Dispatcher.Invoke(()->
                          MakeHeaderColor(names, unused_headers, used_headers)
                        ));
                        
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
                              
                              var b := body.Dispatcher.Invoke(()->new SolidColorBrush(ColorFromKey(name)));
                              spans += (s.range, b);
                              
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
                  
                  var name := name_s.ToString;
                  spans += (s.range,
                    if name in known_template_names then
                      body.Dispatcher.Invoke(()->new SolidColorBrush(ColorFromKey(name))) else
                      Brushes.Salmon
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
          var named_cuts := new Dictionary<integer, array of string>;
          begin
            var head := text;
            
            foreach var (r,b) in spans index i do
            begin
              if head.I1<>r.i1 then
              begin
                cuts += (head.WithI2(r.i1).ToString, Brushes.Transparent);
                head.range.i1 := r.i1;
              end;
              
              var names := named_spans.Get(i);
              if names<>nil then
                named_cuts.Add(cuts.Count, names);
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
            
//            'Chars before prev caret'.Print; TextRange.Create(body.tb.Document.ContentStart, body.tb.CaretPosition).Text.Select(c->c.Code).Println;
            // Before merging blocks, because it messes up newly added line breaks
            var cur_pos := TextRange.Create(body.tb.Document.ContentStart, body.tb.CaretPosition).Text.Remove(#13).Length;
            
            //TODO Dispatcher not needed
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
            
            var write_acts := false;
            
            var new_run := function(s: string; b: Brush; before: Run): Run->
            begin
              Result := new Run(s);
              Result.Background := b;
              if before=nil then
                bl.Inlines.Add(Result) else
                bl.Inlines.InsertBefore(before, Result);
            end;
            
            var new_headers := new List<(array of string, Run)>;
            
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
                var names := named_cuts.Get(next_cut_ind);
                if names<>nil then new_headers += (names, r);
                next_cut_ind += 1;
                old_r_c[new_key] -= 1;
                new_r_c[new_key] -= 1;
                continue;
              end;
              
              if new_r_c.Get(new_key)<old_r_c.Get(new_key) then
              begin
                var (s,b) := new_key;
                if write_acts then Writeln('create missing');
                var nr := new_run(s, b, r);
                var names := named_cuts.Get(next_cut_ind);
                if names<>nil then new_headers += (names, nr);
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
              if write_acts then Writeln('create leftover');
              var nr := new_run(s, b, nil);
              var names := named_cuts.Get(i);
              if names<>nil then new_headers += (names, nr);
            end;
            
            self.headers := new_headers;
            
            var ptrs_len := body.tb.Document.ContentStart.GetOffsetToPosition(body.tb.Document.ContentEnd);
            var ptr := body.tb.Document.ContentStart;
            if cur_pos<>0 then
            begin
              ptr := ptr.GetPositionAtOffset(Round((cur_pos/text.Length).ClampTop(1) * (ptrs_len-1)));
  //            $'[{TextRange.Create(body.tb.Document.ContentStart, ptr).Text}]'.Println;
              while true do
              begin
//                'Chars before next caret'.Print; TextRange.Create(body.tb.Document.ContentStart, ptr).Text.Select(c->c.Code).Println;
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
              
            end;
            
            // ptr.LogicalDirection := LogicalDirection.Forward
            ptr := TextRange.Create(body.tb.Document.ContentStart, ptr).End;
            
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
        if e.Changes.Count=0 then exit;
        if system_text_change then exit;
        last_text := TextRange.Create(body.tb.Document.ContentStart, body.tb.Document.ContentEnd).Text;
        
        remark_wh.Set;
      end;
      
      Paragraph(body.tb.Document.Blocks.FirstBlock).Inlines.Add(ReadAllText(fname,enc));
      body.tb.IsReadOnly := readonly;
      body.tb.AutoWordSelection := false;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public function Visual := body;
    
    public procedure UpdateHeaders(unused, used: HashSet<string>) :=
    foreach var (names, r) in headers do
      r.Background := MakeHeaderColor(names, unused, used);
    
  end;
  
  DescriptionsPackCanceled = sealed class(Exception) end;
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
      
      var module_dir := GetFullPathRTA('..\'+name);
      var curr_file_view := default(InpFileView);
      var file_lock := new Object;
      
      var unused_headers := new HashSet<string>;
      var used_headers := new HashSet<string>;
      
      var file_display := new ContentControl;
      
      {$region Apply changes}
      var apply_changes_wh := new System.Threading.ManualResetEventSlim(false);
      System.Threading.Thread.Create(()->
      begin
        var descr_packer_fname := GetFullPathRTA('..\PackDescriptions.pas');
        CompilePasFile(descr_packer_fname, ZeroOtp, err->MessageBox.Show(err), false, '/Debug:1');
        descr_packer_fname := System.IO.Path.ChangeExtension(descr_packer_fname, '.exe');
        
        while true do
        try
          apply_changes_wh.Wait;
          apply_changes_wh.Reset;
          
          try
            lock file_lock do RunFile(descr_packer_fname, nil, SimpleOtp(l->
            begin
              var TODO0 := 0;
              var text := new StringSection(l);
              var ind := text.IndexOf('template is not defined. All templates:');
              if not ind.IsInvalid then
              begin
                text := text.TakeFirst(ind).TrimLastWhile(ch->ch<>':').TrimLast(2);
                text := text.TrimFirst(text.IndexOf('[')+1);
                var names := FixerUtils.DeTemplateName(text).ConvertAll(t->t[0]);
                'broken template in:'.Println;
                names.PrintLines;
                Writeln('='*30);
                raise new DescriptionsPackCanceled;
              end else
              begin
//                Writeln(l+NewLine*1);
                MessageBox.Show(l);
              end;
            end), e->exit(), 'UseLastPreDoc', $'nick={name}', $'fname=Modules.Packed\{name}.pas');
          except
            on DescriptionsPackCanceled do ;
          end;
          
          self.Dispatcher.Invoke(()->
          begin
          
          unused_headers.Clear;
          unused_headers.UnionWith(ReadLines(module_dir+'.unused.log', enc));
          
          used_headers.Clear;
          used_headers.UnionWith(ReadLines(module_dir+'.used.log', enc).Where(l->l.StartsWith('#')).Select(l->l.SubString(1).Trim));
          
          if curr_file_view<>nil then
            curr_file_view.UpdateHeaders(unused_headers, used_headers);
        end);
          
        except
          on e: Exception do MessageBox.Show(e.ToString);
        end;
      end).Start;
      {$endregion Apply changes}
      
      var file_view_cache := new Dictionary<string, InpFileView>;
      
      var open_file := procedure(fname: string)->
      begin
        if file_view_cache.TryGetValue(fname, curr_file_view) then
          curr_file_view.UpdateHeaders(used_headers, unused_headers) else
        begin
          curr_file_view := new InpFileView(
            fname, false, file_lock,
            apply_changes_wh.Set,
            unused_headers, used_headers
          );
          file_view_cache[fname] := curr_file_view;
        end;
        file_display.Content := curr_file_view.Visual;
      end;
      
      var g := new Grid;
      self.Content := g;
      loop 3 do g.ColumnDefinitions.Add(new ColumnDefinition);
      
      begin
        var tw := new TreeView;
        var cont_by_dir := new Dictionary<string, ItemsControl>;
        
        cont_by_dir.Add(module_dir, tw);
        
        foreach var path in EnumerateAllDirectories(module_dir)+EnumerateAllFiles(module_dir, '*'+inp_file_ext) do
          new FileListItem(cont_by_dir, path, apply_changes_wh.Set, open_file);
        
        begin
          var missing_item := new TreeViewItem;
          missing_item.Header := 'Missing';
          tw.Items.Add(missing_item);
          
          missing_item.Selected += (o,e)->
          begin
            file_display.Content := ReadAllText(module_dir+'.missing.log');
            var TODO := 0;
            //TODO Open missing (this is a virtual file)
            // - Wait, why virtual?
//            file_display.Content := InpFileView.Create(module_dir+'.missing.log', true).Visual;
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
      
      apply_changes_wh.Set;
    end;
    private constructor := raise new System.InvalidOperationException;
    
  end;
  
begin
  var w := new Window;
  w.WindowState := WindowState.Maximized;
  Environment.CurrentDirectory := System.IO.Path.GetDirectoryName(GetCurrentDir);
  
  begin
    var last_esc_t := DateTime.MinValue;
    w.KeyDown += (o,e)->
    case e.Key of
      System.Windows.Input.Key.Escape:
      begin
        var t := DateTime.Now;
        if (t-last_esc_t).TotalSeconds<0.3 then
          w.Close;
        last_esc_t := t;
      end;
    end;
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