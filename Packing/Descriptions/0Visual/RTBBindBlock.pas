unit RTBBindBlock;

interface

uses Visual;

procedure BlockExtraBindings(tb: System.Windows.Controls.RichTextBox);

implementation

uses System.Windows;
uses System.Windows.Input;
uses System.Windows.Controls;
uses System.Windows.Documents;

type
  PastePlainTextCommand = sealed class(ICommand)
    private tb: RichTextBox;
    public constructor(tb: RichTextBox) := self.tb := tb;
    
    public procedure System.Windows.Input.ICommand.add_CanExecuteChanged(h: System.EventHandler) := exit;
    public procedure System.Windows.Input.ICommand.remove_CanExecuteChanged(h: System.EventHandler) := exit;
    
    public function CanExecute(parameter: object) := Clipboard.ContainsText;
    
    public procedure Execute(parameter: object);
    begin
      if not Clipboard.ContainsText then
        raise new System.InvalidOperationException;
      tb.Selection.Text := Clipboard.GetText;
      tb.CaretPosition := tb.Selection.End;
    end;
    
  end;
  
procedure BlockExtraBindings(tb: RichTextBox);
begin
  tb.AcceptsTab := true;
  
  begin
    var gen_bind_list := function(name: string): System.Collections.IEnumerable ->
      System.Collections.Specialized.HybridDictionary(
        typeof(CommandManager).GetField(name, System.Reflection.BindingFlags.Static or System.Reflection.BindingFlags.NonPublic).GetValue(nil)
      )[typeof(RichTextBox)] as System.Collections.IEnumerable;
    
    var all_commands :=
      gen_bind_list('_classInputBindings').Cast&<InputBinding>.Select(b->(b.Gesture,RoutedUICommand(b.Command))) +
      gen_bind_list('_classCommandBindings').Cast&<CommandBinding>.Select(b->RoutedUICommand(b.Command)).SelectMany(c->c.InputGestures.Cast&<InputGesture>.Select(g->(g,c)))
    ;
    
    foreach var (g,c) in all_commands do
    begin
      case c.Name of
        
        'Paste',
        'PasteFormat':
        begin
          tb.InputBindings.Add(new InputBinding(new PastePlainTextCommand(tb), g));
          continue;
        end;
        
        'EnterParagraphBreak',
        'EnterLineBreak':
        begin
          var nc := EditingCommands.EnterParagraphBreak;
          if c<>nc then
            tb.InputBindings.Add(new InputBinding(nc, g));
          continue;
        end;
        
        'ToggleInsert',
        'Delete',
        'DeleteNextWord',
        'DeletePreviousWord',
        'TabForward',
        'TabBackward',
        'Space',
        'ShiftSpace',
        'Backspace',
        'Copy',
        'CopyFormat',
        'Cut',
        'SelectAll',
        'MoveRightByCharacter',
        'MoveLeftByCharacter',
        'MoveRightByWord',
        'MoveLeftByWord',
        'MoveDownByLine',
        'MoveUpByLine',
        'MoveDownByParagraph',
        'MoveUpByParagraph',
        'MoveDownByPage',
        'MoveUpByPage',
        'MoveToLineStart',
        'MoveToLineEnd',
        'MoveToColumnStart',
        'MoveToColumnEnd',
        'MoveToWindowTop',
        'MoveToWindowBottom',
        'MoveToDocumentStart',
        'MoveToDocumentEnd',
        'SelectRightByCharacter',
        'SelectLeftByCharacter',
        'SelectRightByWord',
        'SelectLeftByWord',
        'SelectDownByLine',
        'SelectUpByLine',
        'SelectDownByParagraph',
        'SelectUpByParagraph',
        'SelectDownByPage',
        'SelectUpByPage',
        'SelectToLineStart',
        'SelectToLineEnd',
        'SelectToColumnStart',
        'SelectToColumnEnd',
        'SelectToWindowTop',
        'SelectToWindowBottom',
        'SelectToDocumentStart',
        'SelectToDocumentEnd',
        'Undo',
        'Redo':
          continue;
        
        'CorrectionList',
        'AlignLeft',
        'AlignCenter',
        'AlignRight',
        'AlignJustify',
        'ApplySingleSpace',
        'ApplyOneAndAHalfSpace',
        'ApplyDoubleSpace',
        'ResetFormat',
        'ToggleBold',
        'ToggleItalic',
        'ToggleUnderline',
        'ToggleSubscript',
        'ToggleSuperscript',
        'IncreaseFontSize',
        'DecreaseFontSize',
        'ApplyFontSize',
        'ApplyFontFamily',
        'ApplyForeground',
        'ApplyBackground',
        'ToggleSpellCheck',
        'RemoveListMarkers',
        'ToggleBullets',
        'ToggleNumbering',
        'IncreaseIndentation',
        'DecreaseIndentation':
          ;
        
        else
          $'Unexpected command: {c.Name} (from {c.OwnerType})'.Println;
        
      end;
      
      tb.InputBindings.Add(new InputBinding(ApplicationCommands.NotACommand, g));
    end;
    
  end;
  
end;

end.