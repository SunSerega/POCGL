{$reference System.Windows.Forms.dll}
{$reference System.Drawing.dll}

// Данный пример демонстрирует запуск простейшей программы с модулем OpenGL
// Примите во внимание, что методы из gl_gdi. - могут служить только временной заменой в серьёзной программе
// (По крайней мере в данной версии. В будущем, возможно, gl_gdi будет улучшено)
// Они использованы тут, чтоб пример был проще

uses System.Windows.Forms;
uses System.Drawing;
uses OpenGL;

{$apptype windows} // убирает консоль

begin
  
  // Создаёт и настраиваем окно
  var f := new Form;
  f.StartPosition := FormStartPosition.CenterScreen;
  f.ClientSize := new Size(500, 500);
  f.FormBorderStyle := FormBorderStyle.Fixed3D;
  // Если окно закрылось - надо сразу завершить программу
  f.Closed += (o,e)->Halt();
  
  // Настраиваем поверхность рисования
  var hdc := gl_gdi.InitControl(f);
  
  // Настраиваем перерисовку
  gl_gdi.SetupControlRedrawing(f, hdc, EndFrame ->
  begin
    
    {$region Настройка глобальных параметров OpenGL}
    
    // Выключаем встроенный vsync (ибо у SetupControlRedrawing свой есть)
    // Если на этой строчке "не удаётся найти точку входа" - значит у вас нету встроенного vsync-а
    // В таком случае можно просто убрать эту строчку
    wgl.SwapIntervalEXT(0);
    
    {$endregion Настройка глобальных параметров OpenGL}
    
    {$region Инициализация переменных}
    
    var dy := -Sin(Pi / 6) / 2;
//    var pts := real(0.0).Step(Pi*2/3).Take(3).Select(rot->(Sin(rot), Cos(rot)+dy)).ToArray; //ToDo #2042
    var pts := Range(0, 2).Select(i -> i * Pi * 2 / 3).Select(rot -> (Sin(rot), Cos(rot) + dy)).ToArray;
    var frame_rot := 0.0;
    
    {$endregion Инициализация переменных}
    
    while true do
    begin
      
      gl.Clear(BufferTypeFlags.COLOR_BUFFER_BIT);
      var rot_k := Cos(frame_rot);
      
      // Методы из gl_Deprecated это всё что устарело
      gl_Deprecated.Begin(PrimitiveType.TRIANGLES);
      gl_Deprecated.Color4f( 1,0,0, 1); gl_Deprecated.Vertex2f( pts[0][0] * rot_k, pts[0][1] );
      gl_Deprecated.Color4f( 0,1,0, 1); gl_Deprecated.Vertex2f( pts[1][0] * rot_k, pts[1][1] );
      gl_Deprecated.Color4f( 0,0,1, 1); gl_Deprecated.Vertex2f( pts[2][0] * rot_k, pts[2][1] );
      gl_Deprecated.&End;
      
      frame_rot += 0.03;
      
      gl.Finish;
      // EndFrame меняет местами буферы и ждёт vsync
      EndFrame;
    end;
    
  end);
  
  Application.Run(f);
end.