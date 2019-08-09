{$reference System.Windows.Forms.dll}
{$reference System.Drawing.dll}
uses System.Windows.Forms;
uses OpenGL;
uses System;

{$apptype windows} // убирает консоль

type
  MF = class(Form)
    
    procedure p1;
    begin
      var m: Message;
      self.DefWndProc(m);
      self.WndProc(m);
      
    end;
    
  end;

function GetDC(hwnd: IntPtr): IntPtr;
external 'user32.dll';

function InitOpenGL(hwnd: IntPtr): IntPtr;
begin
  Result := GetDC(hwnd);
  
  
  
  var pfd: GDI_PixelFormatDescriptor;
  pfd.nSize := sizeof( GDI_PixelFormatDescriptor );
  pfd.nVersion := 1;
  
  pfd.dwFlags :=
    GDI_PixelFormatFlags.DRAW_TO_WINDOW or
    GDI_PixelFormatFlags.SUPPORT_OPENGL or
    GDI_PixelFormatFlags.DOUBLEBUFFER
  ;
  pfd.cColorBits := 24;
  pfd.cDepthBits := 16;
  
  if 0=gl_gdi.SetPixelFormat(
    Result,
    gl_gdi.ChoosePixelFormat(Result, pfd),
    pfd
  ) then raise new InvalidOperationException;
  
  var context := wgl.CreateContext(Result);
  if 0=wgl.MakeCurrent(Result, context) then raise new InvalidOperationException;
  
end;

begin
  var f := new MF;
  
  f.StartPosition := FormStartPosition.CenterScreen;
  f.ClientSize := new System.Drawing.Size(500,500);
  f.FormBorderStyle := FormBorderStyle.Fixed3D;
  
  f.Closing += (o,e)->Halt();
  
  f.Load += (o,e)->
  begin
    var hdc := InitOpenGL(f.Handle);
    
    var dy := -Sin(Pi/6) / 2;
//    var pts := real(0.0).Step(Pi*2/3).Take(3).Select(rot->(Sin(rot), Cos(rot)+dy)).ToArray; //ToDo #2042
    var pts := Range(0,2).Select(i->i* Pi*2/3 ).Select(rot->(Sin(rot), Cos(rot)+dy)).ToArray;
    var frame_rot := 0.0;
    
    System.Threading.Thread.Create(()->
    while true do
    begin
      
      f.Invoke(()->
      begin
        gl.Clear(BufferTypeFlags.COLOR_BUFFER_BIT);
        var rot_k := Cos(frame_rot);
        
        gl_Deprecated.Begin(PrimitiveType.TRIANGLES);
        gl_Deprecated.Color4f(1,0,0,1); gl_Deprecated.Vertex2f( pts[0][0]*rot_k, pts[0][1] );
        gl_Deprecated.Color4f(0,1,0,1); gl_Deprecated.Vertex2f( pts[1][0]*rot_k, pts[1][1] );
        gl_Deprecated.Color4f(0,0,1,1); gl_Deprecated.Vertex2f( pts[2][0]*rot_k, pts[2][1] );
        gl_Deprecated.&End;
        
        frame_rot += 0.03;
        gl.Finish;
        gl_gdi.SwapBuffers(hdc);
      end);
      
      Sleep(16);
    end).Start;
    
  end;
  
  Application.Run(f);
end.