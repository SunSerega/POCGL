unit Visual;
{$apptype windows}

{$reference PresentationFramework.dll}
{$reference PresentationCore.dll}
{$reference WindowsBase.dll}

uses System.Windows;
uses System.Windows.Input;
uses System.Windows.Media;
uses System.Windows.Controls;

type
  
  {$region InputDialog}
  
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
        Key.Enter:
        if last_err<>nil then
          MessageBox.Show(last_err, 'Invalid input') else
        begin
          self.DialogResult := true;
          self.Close;
        end;
        Key.Escape:
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
  
  {$endregion InputDialog}
  
end.