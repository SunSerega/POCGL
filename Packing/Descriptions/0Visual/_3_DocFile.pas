unit _3_DocFile;

uses Visual;
uses System.Windows;
uses System.Windows.Media;
uses System.Windows.Input;
uses System.Windows.Controls;
uses System.Windows.Documents;

type
  VisualFileName = sealed class
    
  end;
  
  VisualFileTextBox = sealed class(ContentControl)
    private tb := new RichTextBox; //TODO #????: Не даёт наследовать
    
    private CallingNewText := false;
    public event NewText: string->();
    
    public constructor;
    begin
      self.IsTabStop := false;
      self.Content := tb;
      
      tb.TextChanged += (o,e)->
      begin
        if CallingNewText then exit;
        var text := TextRange.Create(tb.Document.ContentStart,tb.Document.ContentEnd).Text;
        begin
          var NewText := self.NewText;
          if NewText<>nil then
          try
            CallingNewText := true;
            NewText(text);
          finally
            CallingNewText := false;
          end;
        end;
        var ft := new FormattedText(
          text,
          System.Globalization.CultureInfo.InvariantCulture,
          System.Windows.FlowDirection.LeftToRight,
          new Typeface(
            tb.FontFamily,
            tb.FontStyle,
            tb.FontWeight,
            tb.FontStretch
          ),
          tb.FontSize,
          Brushes.Black
        );
        tb.Document.PageWidth := ft.Width*1.1+12; //TODO Magic numbers
      end;
      
      tb.Document.LineHeight := 1;
      
      tb.VerticalScrollBarVisibility := ScrollBarVisibility.Auto;
      tb.HorizontalScrollBarVisibility := ScrollBarVisibility.Auto;
      
      tb.PreviewMouseWheel += (o,e)->
        if Keyboard.Modifiers.HasFlag(ModifierKeys.Shift) then
        begin
          var scr := if e.Delta<0 then tb.LineRight else tb.LineLeft;
          loop Abs(Round(e.Delta/60)) do scr;
          e.Handled := true;
        end;
      
    end;
    
  end;
  
  VisualFileContent = sealed class
    
    private tb := new VisualFileTextBox;
    
  end;
  
  
  
end.