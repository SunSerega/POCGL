﻿{$reference System.Windows.Forms.dll}
{$reference System.Drawing.dll}

// Примеры фрагментных шейдеров
//
// ========== Управление ==========
// ЛКМ: Поставить точку
// СКМ: Удалить ближайшую точку
// ПКМ: Схватить и тащить ближайшую точку
// Колёсико мыши: Маштаб
// Пробел: Вернуть камеру
// Цифры от 1 до 9: Переключение шейдеров (выбирает из all_shaders)

{$apptype windows}

uses System.Windows.Forms;
uses System;
uses OpenGL;
uses OpenGLABC;

uses Common in '../Common';

var all_shaders := |
  'Минимум расстояний.frag',
  'Сумма расстояний.frag',
  'Волны.frag',
  'Спирали.frag',
  'Закраска по функции.frag',
  'Mandelbrot.frag'
|;

type
  CameraData = record
    aspect := real.NaN;
    scale := 500.0;
    pos := default(Vec2d);
  end;
  
begin
  var f := new Form;
  f.WindowState := FormWindowState.Maximized;
//  f.ControlBox := false;
  
  // Моментальное закрытие при Alt+F4 и Esc
  f.Closed += (o,e)->Halt();
  f.KeyUp += (o,e)->
  case e.KeyCode of
    Keys.Escape: Halt;
  end;
  
  var camera := new CameraData;
  
  var need_resize := false;
  var ev_resized_render_complete := new System.Threading.AutoResetEvent(false);
  f.Shown += (o,e)->
  begin
    need_resize := true;
    f.Resize += (o,e)->
    begin
      need_resize := true;
      // Чтобы не мигало - ждём завершения одной перерисовки
      // в потоке формы, то есть блокируя отсыл информации системе
      ev_resized_render_complete.WaitOne;
    end;
  end;
  
  var curr_fragment_shader := 0;
  var point_count := 0;
  var points := new Vec2d[4];
  var mouse_pos := default(Vec2i);
  {$region Управление}
  var points_updated := 0;
  begin
    
    var CoordsFromScreen := function(X,Y: integer): Vec2d ->
    begin
      var logic_pos := new Vec2d(X/f.ClientSize.Width-0.5, 0.5-Y/f.ClientSize.Height)*2;
      var pos := new Vec2d(logic_pos.val0*camera.aspect, logic_pos.val1);
      Result := pos*camera.scale + camera.pos;
    end;
    
    var ClosestPointInd := function(pos: Vec2d): integer ->
    begin
      Assert(point_count<>0);
      var min_r_sqr := (pos-points[0]).SqrLength;
      Result := 0;
      for var i := 1 to point_count-1 do
      begin
        var r_sqr := (pos-points[i]).SqrLength;
        if r_sqr < min_r_sqr then
        begin
          min_r_sqr := r_sqr;
          Result := i;
        end;
      end;
    end;
    
    f.MouseWheel += (o,e)->
    begin
      var pos := CoordsFromScreen(e.X, e.Y);
      
      var pow := 1 - Sign(e.Delta)*0.1;
      camera.scale := camera.scale * pow;
      
      camera.pos := camera.pos + (pos-CoordsFromScreen(e.X, e.Y));
    end;
    
    f.KeyDown += (o,e)->
    case e.KeyCode of
      Keys.Space:
      begin
        var n_camera := new CameraData;
        camera.scale := n_camera.scale;
        camera.pos := n_camera.pos;
      end;
      Keys.D1..Keys.D9:
      begin
        var k := integer(e.KeyCode)-integer(Keys.D1);
        if k<all_shaders.Length then
          curr_fragment_shader := k;
      end;
    end;
    
    var grabbed_point_ind := default(integer?);
    f.MouseDown += (o,e)->
    case e.Button of
      MouseButtons.Left:
      begin
        if point_count=points.Length then
          // По хорошему буфер OpenGL тоже надо увеличивать/уменьшать только по необходимости
          // Сейчас он полностью пересоздаётся
          SetLength(points, points.Length*2);
        points[point_count] := CoordsFromScreen(e.X,e.Y);
        point_count += 1;
        System.Threading.Interlocked.Exchange(points_updated, 1);
      end;
      MouseButtons.Middle:
      if point_count<>0 then
      begin
        var pos := CoordsFromScreen(e.X,e.Y);
        var ind := ClosestPointInd(pos);
        point_count -= 1;
        if ind<>point_count then points[ind] := points[point_count];
        System.Threading.Interlocked.Exchange(points_updated, 1);
      end;
      MouseButtons.Right:
      if point_count<>0 then
      begin
        var pos := CoordsFromScreen(e.X,e.Y);
        var ind := ClosestPointInd(pos);
        grabbed_point_ind := ind;
        points[ind] := pos;
        System.Threading.Interlocked.Exchange(points_updated, 1);
      end;
    end;
    
    f.MouseMove += (o,e)->
    begin
      mouse_pos := new Vec2i(e.X, f.ClientSize.Height-e.Y);
      var pos := CoordsFromScreen(e.X,e.Y);
      if grabbed_point_ind<>nil then
      begin
        points[grabbed_point_ind.Value] := pos;
        System.Threading.Interlocked.Exchange(points_updated, 1);
      end;
    end;
    
    f.MouseUp += (o,e)->
    case e.Button of
      MouseButtons.Right:
      if grabbed_point_ind<>nil then
      begin
        points[grabbed_point_ind.Value] := CoordsFromScreen(e.X,e.Y);
        grabbed_point_ind := nil;
        System.Threading.Interlocked.Exchange(points_updated, 1);
      end;
    end;
    
  end;
  {$endregion Управление}
  
  OpenGLABC.RedrawHelper.SetupRedrawThread(OpenGLABC.gl_gdi.InitControl(f), (pl, EndFrame)->
  try
    gl := new OpenGL.gl(pl);
    
    var sprog: gl_program;
    var last_fragment_shader := -1;
    
    var uniform_point_count := 0;
    var buffer_points: gl_buffer;
    gl.CreateBuffers(1, buffer_points);
    gl.BindBufferBase(glBufferTarget.SHADER_STORAGE_BUFFER, 0, buffer_points);
    
    var uniform_aspect    := 1;
    var uniform_scale     := 2;
    var uniform_pos       := 3;
    var uniform_mouse_pos := 4;
    
    var buffer_point_data: gl_buffer;
    gl.CreateBuffers(1, buffer_point_data);
    gl.NamedBufferData(buffer_point_data, new UIntPtr(1*sizeof(real)), IntPtr.Zero, glVertexBufferObjectUsage.DYNAMIC_READ);
    gl.BindBufferBase(glBufferTarget.SHADER_STORAGE_BUFFER, 1, buffer_point_data);
    
    var timings_max_count := 30;
    var timings := new Queue<TimeSpan>(timings_max_count);
    var total_time := TimeSpan.Zero;
    var sw := new Stopwatch;
    
    while true do
    begin
      var need_set_resize_ev := false;
      if need_resize then
      begin
        var w_size := f.ClientSize;
        
        gl.Viewport(0,0, w_size.Width,w_size.Height);
        need_set_resize_ev := true;
        
        camera.aspect := w_size.Width/w_size.Height;
      end;
      
      if last_fragment_shader<>curr_fragment_shader then
      begin
        last_fragment_shader := curr_fragment_shader;
        
        gl.DeleteProgram(sprog);
        sprog := InitProgram(
          InitShaderFile('Empty.vert',                      glShaderType.VERTEX_SHADER),
          InitShaderFile('SinglePointToScreen.geom',        glShaderType.GEOMETRY_SHADER),
          InitShaderFile(all_shaders[last_fragment_shader], glShaderType.FRAGMENT_SHADER)
        );
        gl.UseProgram(sprog);
        points_updated := 1;
      end;
      
      if System.Threading.Interlocked.Exchange(points_updated, 0)<>0 then
      begin
        gl.Uniform1i(uniform_point_count, point_count);
        // Плохо - пересоздаём всё тело буфера при каждом изменении точек
        // Но по сравнению с фрагментным шейдером - это капля в море
        gl.NamedBufferData(buffer_points, new UIntPtr(point_count*sizeof(vec2d)), points, glVertexBufferObjectUsage.DYNAMIC_READ);
        // Записать point_count точек из массива можно так:
//        gl.NamedBufferSubData(buffer_points, IntPtr.Zero, new IntPtr(point_count * sizeof(Vec2d)), points);
        // Но это сломается когда размера буфера не хватит
      end;
      
      sw.Restart;
      
      // Копируем все данные сразу в локальную переменную
      var camera := camera;
      // И затем в юниформы
      gl.Uniform1d(uniform_aspect,        camera.aspect);
      gl.Uniform1d(uniform_scale,         camera.scale);
      gl.Uniform2dv(uniform_pos, 1,       camera.pos);
      gl.Uniform2iv(uniform_mouse_pos, 1, mouse_pos);
      
      gl.NamedBufferSubData(buffer_point_data, new IntPtr(0*sizeof(real)), new UIntPtr(1*sizeof(real)), |real.NaN|);
      
      // Вызываем шейдерную программу один раз, не передавая локальные данные
      // Вместо этого будем использовать только юниформы (общие для всех точек данные)
      // Геометричейский шейдер сделает из этой точки прямоугольник, покрывающий все пиксели экрана
      // А фрагментный шейдер уже будет использовать юниформы чтобы покрасить каждую точку отдельно
      // Обычно это неэффективно, но тут только простая демонстация
      gl.DrawArrays(glPrimitiveType.POINTS, 0,1);
      
      var point_data: real;
      gl.GetNamedBufferSubData(buffer_point_data, new IntPtr(0*sizeof(real)), new UIntPtr(1*sizeof(real)), point_data);
      
      var err := gl.GetError;
      if err.IS_ERROR then MessageBox.Show(err.ToString);
      
      gl.Finish;
      if need_set_resize_ev then
        ev_resized_render_complete.Set;
      
      var curr_time := sw.Elapsed;
      if timings.Count=timings_max_count then
        total_time := total_time-timings.Dequeue;
      total_time := total_time+curr_time;
      timings += curr_time;
      
      var fps := timings.Count/total_time.TotalSeconds;
      var form_text := $'{all_shaders[curr_fragment_shader]}: {fps:N2} fps, {1000/fps:N2} mspf, {point_count} points, scale={camera.scale}, pos={camera.pos} data={point_data}';
//      form_text := $'temp_data={ObjectToString(temp_data)}, '+form_text;
      f.Text := form_text;
      EndFrame;
    end;
    
  except
    on e: Exception do
    begin
      MessageBox.Show(e.ToString);
      Halt;
    end;
  end);
  
  System.Windows.Forms.Application.Run(f);
end.