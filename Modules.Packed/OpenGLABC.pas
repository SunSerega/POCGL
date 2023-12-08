
//*****************************************************************************************************\\
// Copyright (©) Sergey Latchenko ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// This code is distributed under the Unlicense
// For details see LICENSE file or this:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\
// Copyright (©) Сергей Латченко ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// Данный код распространяется с лицензией Unlicense
// Подробнее в файле LICENSE или тут:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\

///
///Модуль, зарезервированный для высокоуровневой оболочки модуля OpenGL
///Все текущие элементы модуля являются временными
///
unit OpenGLABC;

uses System;
uses OpenGL;

type
  
  ///Методы для интеграции с gdi
  gl_gdi = static class
    {$reference System.Windows.Forms.dll}
    
    ///Создаёт новый контекст устройства GDI для дескриптора элемента управления
    public static function GetControlDC(hwnd: IntPtr): gdi_device_context;
    external 'user32.dll' name 'GetDC';
    
    ///Создаёт и настраивает контекст устройства GDI элемента управления WF
    ///hwnd - дескриптор элемента управления
    public static function InitControl(hwnd: IntPtr): gdi_device_context;
    begin
      Result := gl_gdi.GetControlDC(hwnd);
      
      var pfd: gdi_pixel_format_descriptor;
      pfd.nVersion := 1;
      
      pfd.dwFlags :=
        gdiPixelFormatFlags.DRAW_TO_WINDOW or
        gdiPixelFormatFlags.SUPPORT_OPENGL or
        gdiPixelFormatFlags.DOUBLEBUFFER
      ;
      pfd.cColorBits := 24;
      pfd.cDepthBits := 16;
      
      if not gdi.SetPixelFormat(
        Result,
        gdi.ChoosePixelFormat(Result, pfd),
        pfd
      ) then raise new InvalidOperationException;
      
    end;
    
    ///Создаёт и настраивает контекст устройства GDI элемента управления WF
    public static function InitControl(c: System.Windows.Forms.Control) := InitControl(c.Handle);
    
  end;
  
  RedrawThreadProc = procedure(pl: IGLPlatformLoader; EndFrame: ()->());
  RedrawHelper = static class
    
    private [ThreadStatic] static curr_context: gdi_rendering_context;
    public static property CurrentThreadContext: gdi_rendering_context read curr_context;
    
    ///Создаёт новый поток выполнения, который:
    ///1. Создаёт контекст OpenGL из контекста устройства GDI (hdc)
    ///2. Запускает перерисовку (RedrawThreadProc)
    public static procedure SetupRedrawThread(hdc: gdi_device_context; RedrawThreadProc: OpenGLABC.RedrawThreadProc; vsync_fps: integer := 65);
    begin
      
      var thr := new System.Threading.Thread(()->
      begin
        //TODO Поддержка glPlX
        var pl := new glPlWin;
        
        var context := wgl.CreateContext(hdc);
        if not wgl.MakeCurrent(hdc, context) then raise new InvalidOperationException('Не удалось применить контекст');
        RedrawHelper.curr_context := context;
        
        var EndFrame: ()->();
        if vsync_fps<=0 then
          EndFrame := ()->gdi.SwapBuffers(hdc) else
        begin
          var LastRedr := DateTime.UtcNow;
          var FrameDuration := new TimeSpan(Trunc(TimeSpan.TicksPerSecond/vsync_fps));
          var MaxSlowDown := FrameDuration.Ticks*3;
          
          EndFrame := ()->
          begin
            gdi.SwapBuffers(hdc);
            
            LastRedr := LastRedr+FrameDuration;
            var time_left := LastRedr-DateTime.UtcNow;
            
            if time_left.Ticks>0 then
              System.Threading.Thread.Sleep(time_left) else
            if -time_left.Ticks > MaxSlowDown then
              LastRedr := LastRedr.AddTicks(-time_left.Ticks - MaxSlowDown);
            
          end;
          
        end;
        
        RedrawThreadProc(pl, EndFrame);
      end);
      thr.SetApartmentState(System.Threading.ApartmentState.STA);
      thr.Start;
      
    end;
    
  end;
  
end.