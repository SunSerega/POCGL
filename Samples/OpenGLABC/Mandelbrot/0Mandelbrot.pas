{$reference System.Windows.Forms.dll}
{$reference System.Drawing.dll}

{$apptype windows}

// Управление:
// - Space:       Сбросить положение камеры
// - Ctrl+C:      Скопировать положение камеры
// - Ctrl+V:      Вставить положение камеры
// - Mouse Drag:  Быстрое движение камеры
// - Arrows:      Гладкое движение камеры
// - Scroll:      Быстрое изменение масштаба
// - "+" и "-":   Гладкое изменение масштаба
// - Alt+Enter:   Полноэкранный режим

//TODO Доделать ограничение view_bound
// - Сейчас его не возвращает из функции, создающей блоки

// Константы, которые можно быстро менять
uses Settings;

uses GL_CL_Context;

uses System;
uses System.Windows.Forms;

uses OpenGL;
uses OpenGLABC;

//uses OpenCL; //TODO Remove
uses OpenCLABC;

uses Common in '../Common';

uses PointComponents;
uses CameraDef;
uses Blocks;

//var extra_debug_output := false;

//TODO Система отдельных блоков, как на гугл картах
// - Запоминать номер кадра последнего использования каждого блока
//TODO Что насчёт рисования кадра?
// - В идеале надо смотреть только на блок нужного масштаба
// - Но если он не полностью нарисован:
// --- Сначала пытаться нарисовать более мелкие блоки
// --- Затем наоборот, более большие (а знач неточные)
// - А что с точками, которые ещё считает?
// --- По сути можно иметь 3 глубины:
// --- 0=не нарисовано
// --- 1=нарисовано недосчитанным
// --- 2=нарисовано конечным
// - Конечный статус наверн будет у очень маленького кол-ва точек...
// - То есть, наверное, нет смысла давать блоку конечный статус

//TODO + и - для стабильного зума
//TODO * и / для максимального кол-ва шагов (для цвета и расчётов)

//TODO Множество разных фрагметных шейдеров, для разной раскраски в зависимости от глубины
// - По глубине:
// --- от depth/макс_глубину
// --- от depth/n%1
// - По цвету (0 и MaxLongWord считать особенными)
// --- hsv2rgb
// --- чёрно-белое
//TODO Максимальную глубину передавать в уже сглаженном виде, чтобы цвета не менялись резко
//TODO Или может собирать фрагментные шейдеры на ходу, из комбинаций кусков кода?

//TODO Значения z надо хранить с изменяемой точность, исходя из текущего масштаба

//TODO Отдельное окно по нажатию какой-то клавиши с кучей инфы
// - Загруженность памяти (VRAM,RAM)
// - Скорость обработки блоков (ну и текущее кол-во слов там же)

//TODO Попробовать вставить цикл в корень MandelbrotBlockStep, чтобы не запускать kernel кучу раз

type
  UpdateTimingQueue = sealed class
    private sw := Stopwatch.StartNew;
    private cap: integer;
    private q: Queue<TimeSpan>;
    private _mspu: real;
    
    public constructor(cap: integer);
    begin
      self.cap := cap;
      self.q := new Queue<TimeSpan>(cap);
    end;
    private constructor := raise new InvalidOperationException;
    
    public procedure Start := sw.Start;
    public procedure Stop := sw.Stop;
    public procedure Update;
    begin
      var t := sw.Elapsed;
      var last_deq := TimeSpan.Zero;
      if q.Count=cap then
        last_deq := q.Dequeue;
      q += t;
      _mspu := (t-last_deq).TotalMilliseconds / q.Count;
    end;
    
    public property MSPU: real read _mspu;
    public property UPS: real read 1000/_mspu;
    
  end;
  
  BoundUniforms = record
    xf, yf: integer;
    xl, yl: integer;
    
    constructor(shader_prog: gl_program; prefix: string);
    begin
      (xf, yf) := (gl.GetUniformLocation(shader_prog, $'{prefix}_skip_x_frst'), gl.GetUniformLocation(shader_prog, $'{prefix}_skip_y_frst'));
      (xl, yl) := (gl.GetUniformLocation(shader_prog, $'{prefix}_skip_x_last'), gl.GetUniformLocation(shader_prog, $'{prefix}_skip_y_last'));
    end;
    
    procedure Write(b: BoundDefs);
    begin
      gl.Uniform1f(xf, b.xf);
      gl.Uniform1f(yf, b.yf);
      gl.Uniform1f(xl, b.xl);
      gl.Uniform1f(yl, b.yl);
    end;
    
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
  
  var camera: CameraPos;
  
  var need_resize := false;
  f.Shown += (o,e)->
  begin
    camera := new CameraPos(f.ClientSize.Width, f.ClientSize.Height);
    need_resize := true;
    f.Resize += (o,e)->
    begin
      need_resize := true;
      // Чтобы не мигало - ждём завершения одной перерисовки
      // в потоке формы, то есть блокируя отсыл информации системе
      while need_resize do ;
    end;
  end;
  
  //TODO Использовать чтобы выдавать кол-во итераций под курсором
  var mouse_pos: Vec2i;
  {$region Управление}
  begin
    
//    var CoordsFromScreen := function(X,Y: integer): Vec2d ->
//    begin
//      var logic_pos := new Vec2d(X/f.ClientSize.Width-0.5, 0.5-Y/f.ClientSize.Height)*2;
//      var pos := new Vec2d(logic_pos.val0*camera.aspect, logic_pos.val1);
//      Result := pos*camera.scale + camera.pos;
//    end;
    
    f.MouseWheel += (o,e)->
    begin
      //TODO
//      var pos := CoordsFromScreen(e.X, e.Y);
//      
//      var pow := 1 - Sign(e.Delta)*0.1;
//      camera.scale := camera.scale * pow;
//      
//      camera.pos := camera.pos + (pos-CoordsFromScreen(e.X, e.Y));
    end;
    
    f.KeyDown += (o,e)->
    case e.KeyCode of
      Keys.Space: camera := new CameraPos(f.Width, f.Height);
    end;
    
    f.MouseMove += (o,e)->(mouse_pos := new Vec2i(e.X,e.Y));
    
  end;
  {$endregion Управление}
  
  var hdc := OpenGLABC.gl_gdi.InitControl(f);
  OpenGLABC.RedrawHelper.SetupRedrawThread(hdc, (pl, EndFrame)->
  try
    GL_CL_Context.Init(hdc);
    gl := new OpenGL.gl(pl);
    
    begin
      var org_swap_interval := wglSwapControlEXT.Instance.GetSwapIntervalEXT;
      var new_swap_interval := Settings.frame_interval;
      if extra_debug_output then
        $'Swap interval: {org_swap_interval}=>{new_swap_interval}'.Println;
      if not wglSwapControlEXT.Instance.SwapIntervalEXT(new_swap_interval) then
        raise new System.InvalidOperationException;
    end;
    
    var sw := Stopwatch.StartNew;
    var timings_max_count := 30;
    // sw.Elapsed для каждого из последних timings_max_count кадров
    var timings := new Queue<TimeSpan>(timings_max_count);
    
    var s_vert_empty := InitShaderResource('Empty.vert', glShaderType.VERTEX_SHADER); {$resource Shaders/Empty.vert}
    
    var s_geom_box := InitShaderResource('Box.geom', glShaderType.GEOMETRY_SHADER); {$resource Shaders/Box.geom}
    
    var s_frag_rainbow := InitShaderResource('Rainbow.frag', glShaderType.FRAGMENT_SHADER); {$resource Shaders/Rainbow.frag}
    
    var shader_prog: gl_program;
    var uniform_view_bound, uniform_sheet_bound: BoundUniforms;
    var uniform_sheet_size: integer;
    var ssb_sheet: integer;
    var uniform_max_steps: integer;
    var choose_frag_shader := procedure(s_frag: gl_shader)->
    begin
      shader_prog := InitProgram(s_vert_empty, s_geom_box, s_frag);
      gl.UseProgram(shader_prog);
      uniform_view_bound := new BoundUniforms(shader_prog, 'view');
      uniform_sheet_bound := new BoundUniforms(shader_prog, 'sheet');
      uniform_sheet_size := gl.GetUniformLocation(shader_prog, 'sheet_size');
      ssb_sheet := gl.GetProgramResourceIndex(shader_prog, glProgramInterface.SHADER_STORAGE_BLOCK, 'sheet_block');
      uniform_max_steps := gl.GetUniformLocation(shader_prog, 'max_steps');
    end;
    choose_frag_shader(s_frag_rainbow);
    
    var cl_err_buffer := new CLArray<cardinal>(3);
    var cl_uc_buffer := new CLValue<cardinal>;
    
    var gl_sheet_buffer: gl_buffer;
    gl.CreateBuffers(1, gl_sheet_buffer);
    var cl_sheet_buffer: CLArray<cardinal>;
    var cl_sheet_states: CLArray<byte>;
    var curr_sheet_size := -1;
    var Q_Init := CQNil;
    var ensure_sheet_buffer_size := procedure(w, h: integer)->
    begin
      var req_size := w*h;
      if req_size<=0 then
        raise new InvalidOperationException;
      if curr_sheet_size>=req_size then exit;
      curr_sheet_size := req_size;
      gl.NamedBufferData(gl_sheet_buffer, new UIntPtr(req_size*sizeof(cardinal)), IntPtr.Zero, glVertexBufferObjectUsage.STREAM_DRAW);
      GL_CL_Context.WrapBuffer(gl_sheet_buffer, cl_sheet_buffer);
      if cl_sheet_buffer.Length <> req_size then
        raise new InvalidOperationException;
      cl_sheet_states := new CLArray<byte>(req_size);
      Q_Init := CQNil
        + cl_sheet_buffer.MakeCCQ.ThenFillValue(0)
        + cl_sheet_states.MakeCCQ.ThenFillValue(0)
        + cl_err_buffer.MakeCCQ.ThenFillValue(0)
        + cl_uc_buffer.MakeCCQ.ThenWriteValue(0)
        + CQNil
      ;
    end;
    
    // Для дебага
//    var buffer_temp: gl_buffer;
//    gl.CreateBuffers(1, buffer_temp);
//    gl.NamedBufferData(buffer_temp, new IntPtr(3*sizeof(real)), IntPtr.Zero, VertexBufferObjectUsage.DYNAMIC_READ);
//    gl.BindBufferBase(BufferTarget.SHADER_STORAGE_BUFFER, 1, buffer_temp);
    
    //TODO Calculate on-fly
    var max_steps := 256;
    
    while true do
    begin
      var curr_frame_resized := false;
      if need_resize then
      begin
        var w_size := f.ClientSize;
        
        gl.Viewport(0,0, w_size.Width,w_size.Height);
        curr_frame_resized := true;
        
        camera.Resize(w_size.Width, w_size.Height);
      end;
      var render_info := BlockLayer.BlocksForCurrentScale(camera);
      var b_cy := render_info.blocks.GetLength(0);
      var b_cx := render_info.blocks.GetLength(1);
      
      var render_block_size := Settings.block_w shr render_info.mipmap_lvl;
      var render_sheet_w := b_cx * render_block_size;
      var render_sheet_h := b_cy * render_block_size;
      ensure_sheet_buffer_size(render_sheet_w, render_sheet_h);
      
      var Q_Steps := CQNil; //TODO Calculate in separate thread
      var Q_Extract := CQNil;
      for var b_y := 0 to b_cy-1 do
        for var b_x := 0 to b_cx-1 do
        begin
          var b := render_info.blocks[b_y, b_x];
          
          Q_Steps += b.CQ_MandelbrotBlockStep(max_steps, cl_uc_buffer, cl_err_buffer);
          
          var sheet_shift := render_block_size * (b_x + b_y*render_sheet_w);
          Q_Extract += b.CQ_GetData(render_info.mipmap_lvl
            , new ShiftedCLArray<byte>(cl_sheet_states, sheet_shift, render_sheet_w)
            , new ShiftedCLArray<cardinal>(cl_sheet_buffer, sheet_shift, render_sheet_w)
          );
          
        end;
      
      begin
        var cl_err := CLContext.Default.SyncInvoke(
          Q_Init +
          Q_Steps +
          Q_Extract +
          cl_err_buffer.MakeCCQ.ThenGetArray
        );
        if cl_err[0]<>0 then
          $'OpenCL err at [{cl_err[1]},{cl_err[2]}]: {CLCodeExecutionError(cl_err[0])}'.Println;
      end;
      
      uniform_view_bound.Write(render_info.view_bound);
      uniform_sheet_bound.Write(render_info.sheet_bound);
      gl.Uniform2i(uniform_sheet_size, render_sheet_w, render_sheet_h);
      gl.BindBufferBase(glBufferTarget.SHADER_STORAGE_BUFFER, ssb_sheet, gl_sheet_buffer);
      gl.Uniform1f(uniform_max_steps, max_steps);
      
      // Для дебага
//      gl.NamedBufferSubData(buffer_temp, new IntPtr(0*sizeof(real)), new IntPtr(2*sizeof(real)), mouse_pos);
      
      gl.DrawArrays(glPrimitiveType.POINTS, 0,1);
      
      // Для дебага
//      var temp_data := new real[1];
//      gl.GetNamedBufferSubData(buffer_temp, new IntPtr(2*sizeof(real)), new IntPtr(1*sizeof(real)), temp_data);
      
      var err := gl.GetError;
      if err.IS_ERROR then MessageBox.Show(err.ToString);
      
      gl.Finish;
      if curr_frame_resized then
        need_resize := false;
      var curr_time := sw.Elapsed;
      
      var title_parts := new List<string>;
      
      // Для дебага
//      title_parts += $'temp_data={_ObjectToString(temp_data)}';
      
      //TODO Оттестировать и убрать
      title_parts += $'sheet byte size={curr_sheet_size} (${curr_sheet_size:X})';
      
      if timings.Count=timings_max_count then
      begin
        var time_diff := curr_time - timings.Dequeue;
        var mspf := time_diff.TotalMilliseconds / timings_max_count;
        var fps := 1000/mspf;
        title_parts += $'{fps:N2} fps';
        title_parts += $'{mspf:N2} mspf';
      end;
      timings += curr_time;
      
      title_parts += $'pos=({camera.pos.r}; {camera.pos.i})';
      title_parts += $'scale={camera.scale_fine:N3}*2^{camera.scale_pow}';
      
      f.Text := title_parts.JoinToString(', ');
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