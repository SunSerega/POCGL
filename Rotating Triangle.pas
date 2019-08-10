{$reference System.Windows.Forms.dll}
{$reference System.Drawing.dll}

uses System.Windows.Forms;
uses System.Drawing;
uses OpenGL;

{$apptype windows} // убирает консоль

begin
  var f := new Form;
  
  f.StartPosition := FormStartPosition.CenterScreen;
  f.ClientSize := new Size(500, 500);
  f.FormBorderStyle := FormBorderStyle.Fixed3D;
  
  f.Closing += (o,e)->Halt();
  
  var hdc := gl_gdi.InitControl(f);
  gl_gdi.SetupControlRedrawing(f, hdc, EndFrame ->
  begin
    
    var dy := -Sin(Pi / 6) / 2;
//    var pts := real(0.0).Step(Pi*2/3).Take(3).Select(rot->(Sin(rot), Cos(rot)+dy)).ToArray; //ToDo #2042
    var pts := Range(0, 2).Select(i -> i * Pi * 2 / 3).Select(rot -> (Sin(rot), Cos(rot) + dy)).ToArray;
    var frame_rot := 0.0;
    
    wgl.SwapIntervalEXT(0); //ToDo эту функцию удаляет, ибо есть glXSwapIntervalEXT. Это плохо...
    
    while true do
    begin
      
      gl.Clear(BufferTypeFlags.COLOR_BUFFER_BIT);
      var rot_k := Cos(frame_rot);
      
      gl_Deprecated.Begin(PrimitiveType.TRIANGLES.val);
      gl_Deprecated.Color4f(1, 0, 0, 1); gl_Deprecated.Vertex2f( pts[0][0] * rot_k, pts[0][1]);
      gl_Deprecated.Color4f(0, 1, 0, 1); gl_Deprecated.Vertex2f( pts[1][0] * rot_k, pts[1][1]);
      gl_Deprecated.Color4f(0, 0, 1, 1); gl_Deprecated.Vertex2f( pts[2][0] * rot_k, pts[2][1]);
      gl_Deprecated.&End;
      
      frame_rot += 0.03;
      gl.Finish;
      
      EndFrame;
    end;
    
  end);
  
  Application.Run(f);
end.