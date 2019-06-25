program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

begin
  var text := ReadAllText('temp.txt');
  
//  for var i := 1 to 4 do
//    text := text.Replace(i+'f', i+'d');
//  text := text.Replace('single', 'real');
  
  text := text.Replace('Uniform', 'ProgramUniform');
  text := text.Replace('[MarshalAs(UnmanagedType.LPArray)]', '%MarshalAs');
  text := text.Replace('(', '(&program: ProgramName; ');
  text := text.Replace('%MarshalAs', '[MarshalAs(UnmanagedType.LPArray)]');
  
//  text :=
//    text.Replace('2x3', '2x4') +
//    text.Replace('2x3', '4x2') +
//    text.Replace('2x3', '3x4') +
//    text.Replace('2x3', '4x3')
//  ;
  
  System.Windows.Forms.Clipboard.SetText(text);
  System.Console.Beep;
end.