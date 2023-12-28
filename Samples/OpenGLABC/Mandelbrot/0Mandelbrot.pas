{$reference System.Windows.Forms.dll}
{$reference System.Drawing.dll}

{$apptype windows}

// Управление:
// - Escape:      Завершение программы (дважды или +Ctrl чтобы отменить сохранение)
// - Mouse Drag:  Быстрое движение камеры
// - Arrows:      Гладкое движение камеры
// - Scroll:      Быстрое изменение масштаба
// - "+" и "-":   Гладкое изменение масштаба
// - Space:       Сбросить положение камеры
// - Ctrl+C:      Скопировать положение камеры (+Shift чтобы добавить комментарий)
// - Ctrl+V:      Вставить положение камеры
// - Win+V:       Вставить положение камеры из истории буфера обмена
// - Q:           Сбросить визуальную информацию предыдущих кадров
//TODO:
// - B:           Телепортировать камеру к курсору (Blink)
// --- Пока держат - выводить точку в начале заголовка, а телепортировать когда отпускают

// В модуле Settings находятся все основных константы
// + объяснение логики программы, чтобы понимать зачем эти константы
// Ctrl+тыкните на название модуля тут, в uses, чтобы открыть его
uses Settings;

//TODO Вывод шагов под курсором чтобы норм дебажить
// - in[123]
// - out[456]
//TODO Выводить отдельно для sheet и для блоков
// - Для этого надо находить номер блока и точки в нём и кидать (x;y) точки в CQ_GetData

//TODO При очень большом приближении край рисунка ведёт себя криво
// - Потому что FirstWordToReal
// - Надо в виде PointComponent считать разницу сначала

//TODO mouse_grab_move ведёт себя не стабильно: точка которую держат может потихоньку сдвигаться
// - Надо запоминать camera.pos в начале движения мышкой
// - И затем пересчитывать на каждом кадре относительно него

//TODO Отдельное окно по нажатию какой-то клавиши с кучей инфы
// - Загруженность памяти (VRAM,RAM,Drive)
// - Скорость обработки блоков (ну и текущее кол-во слов там же)
// - Для начала выводить сколько памяти тратится на sheet-ы

//TODO Всё ещё наблюдаются редкие глюки CQ_CopySheet, особенно при больших прыжках масштаба
//TODO Так же заметил с горизонтальным движением, когда не хватает оперативки
// - Может это скорее потому что что-то не обнуляется?
// - Сложно тестировать потому что начинаются ещё и всякие INVALID_KERNEL_ARGS вдруг...

//TODO Отдельная программа для полной прорисовки кардров с движением камеры от 1 точки (и масштаба) к другой

uses System;
uses System.Windows.Forms;

uses OpenGL;
uses OpenGLABC;

uses OpenCLABC;

uses GL_CL_Context;

uses Common;// in '../Common'; //TODO Merge

uses PointComponents;
uses CameraDef;
uses Blocks;

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
    
    procedure Write(b: BoundDefs<single>);
    begin
      gl.Uniform1f(xf, b.xf);
      gl.Uniform1f(yf, b.yf);
      gl.Uniform1f(xl, b.xl);
      gl.Uniform1f(yl, b.yl);
    end;
    
  end;
  
  CLGLArray<T> = sealed class
  where T: record;
    
    public b_gl: gl_buffer;
    public b_cl: CLArray<T>;
    
    public constructor(gl: OpenGL.gl);
    begin
      gl.CreateBuffers(1, self.b_gl);
      b_cl := nil;
    end;
    
    public function EnsureLen(len: integer): boolean;
    begin
      Result := false;
      if (b_cl<>nil) and (b_cl.Length>=len) then exit;
      
      if b_cl<>nil then
        CLMemoryObserver.Current.RemoveMemoryUse(b_cl.ByteSize, b_gl);
      gl.NamedBufferData(b_gl, new UIntPtr(len*System.Runtime.InteropServices.Marshal.SizeOf&<T>), IntPtr.Zero, glVertexBufferObjectUsage.STREAM_DRAW);
      GL_CL_Context.WrapBuffer(b_gl, b_cl);
      if b_cl.Length <> len then
        raise new InvalidOperationException;
      CLMemoryObserver.Current.AddMemoryUse(b_cl.ByteSize, b_gl);
      
      Result := true;
    end;
    
  end;
  
begin
  var f := new Form;
  CLMemoryObserver.Current := new TrackingMemoryObserver;
//  f.ControlBox := false;
//  OpenCLABC.eh_debug_otp := nil;
  
  // Может понадобится увеличить max_VRAM в "Settings.pas",
  // для раскрытия на полный экран с 1920х1080 (1080p) и больше пикселей
//  f.WindowState := FormWindowState.Maximized;
//  f.ClientSize := new System.Drawing.Size(1920,1080); // 1080p, 16:9
//  f.ClientSize := new System.Drawing.Size(1280,720); // 720p, 16:9
  f.ClientSize := new System.Drawing.Size(1440,720); // 720p, 2:1
//  f.ClientSize := new System.Drawing.Size(1072,603); // 603p, 16:9
//  f.ClientSize := new System.Drawing.Size(1206,603); // 603p, 2:1
  f.StartPosition := FormStartPosition.CenterScreen;
  
  var camera_saved_pos_fname := 'camera.dat';
  var camera_saved_pos_enc := new System.Text.UTF8Encoding(true);
  
  {$region Закрытие}
  
  f.KeyUp += (o,e)->
  case e.KeyCode of
    Keys.Escape: f.Close;
  end;
  var wait_for_last_frame := true;
  f.Closing += (o,e)->
  begin
    if Control.ModifierKeys.HasFlag(Keys.Control) then Halt;
    
    var shutdown_progress_form := new Form;
    shutdown_progress_form.StartPosition := FormStartPosition.CenterScreen;
    shutdown_progress_form.FormBorderStyle := FormBorderStyle.None;
    shutdown_progress_form.Closing += (o,e)->
    begin
      while wait_for_last_frame do ;
      Halt;
    end;
    shutdown_progress_form.KeyUp += (o,e)->
    case e.KeyCode of
      Keys.Escape: shutdown_progress_form.Close;
    end;
    
    var progress_bar := new ProgressBar;
    shutdown_progress_form.Controls.Add(progress_bar);
    shutdown_progress_form.ClientSize := new System.Drawing.Size(
      (Screen.PrimaryScreen.WorkingArea.Width * 0.7).Round,
      progress_bar.Height
    );
    progress_bar.Dock := DockStyle.Fill;
    
    var progress_t := new Timer;
    progress_t.Interval := 10;
    progress_t.Tick += (o,e)->
    begin
      var (done,total) := BlockUpdater.ShutdownProgress;
      progress_bar.Minimum := 0;
      progress_bar.Maximum := total;
      progress_bar.Value := done;
      f.Text := $'Saving to drive: {done/total:P} ({done}/{total})';
    end;
    
    BlockUpdater.BeginShutdown(shutdown_progress_form.Close);
    progress_t.Start;
    
    shutdown_progress_form.ShowDialog;
  end;
  
  {$endregion Закрытие}
  
  {$region speak}
  
  var speak: string->();
  try
    {$reference System.Speech.dll}
    
    var all_voices := System.Speech.Synthesis.SpeechSynthesizer.Create.GetInstalledVoices;
    if all_voices.Count=0 then raise new System.Exception('No installed voices');
    
    var speaker_per_voice := all_voices.ToDictionary(v->v, v->
    begin
      Result := new System.Speech.Synthesis.SpeechSynthesizer;
      Result.SetOutputToDefaultAudioDevice;
      Result.SelectVoice(v.VoiceInfo.Name);
      if Result.Voice<>v.VoiceInfo then
        raise new System.InvalidOperationException;
    end);
    
    var speaker_per_letter := new Dictionary<char, System.Speech.Synthesis.SpeechSynthesizer>;
    var add_letter_voice := procedure(ch: char; v: System.Speech.Synthesis.InstalledVoice)->
    begin
      var ll := ch.ToLower;
      var lu := ch.ToUpper;
      if ll=lu then raise new System.InvalidOperationException;
      var speaker := speaker_per_voice[v];
      speaker_per_letter.Add(ll, speaker);
      speaker_per_letter.Add(lu, speaker);
    end;
    
    var en_voice := all_voices.FirstOrDefault(v->'en' in v.VoiceInfo.Culture.Name);
    if en_voice=nil then
      $'No en voice!'.Println else
      for var ch := 'a' to 'z' do
        add_letter_voice(ch, en_voice);
    
    var ru_voice := all_voices.FirstOrDefault(v->'ru' in v.VoiceInfo.Culture.Name);
    if ru_voice=nil then
      $'No ru voice!'.Println else
    begin
      for var ch := 'а' to 'я' do
        add_letter_voice(ch, ru_voice);
      add_letter_voice('ё', ru_voice);
    end;
    
    var def_voice := en_voice ?? ru_voice ?? all_voices.First;
    var def_speaker := speaker_per_voice[def_voice];
    
    speak := s->System.Threading.Tasks.Task.Run(()->
    try
      foreach var sp in speaker_per_voice.Values do
        sp.SpeakAsyncCancelAll;
      
      var sb := new StringBuilder(s.Length);
      var speaker := default(System.Speech.Synthesis.SpeechSynthesizer);
      var dump := ()->
      begin
        if sb.Length=0 then exit;
//        $'{speaker.Voice.Culture.Name} says [{sb}]'.Println;
        speaker.Speak(sb.ToString);
        sb.Clear;
      end;
      var add_char := procedure(ch: char; new_speaker: System.Speech.Synthesis.SpeechSynthesizer)->
      begin
        if speaker<>new_speaker then dump;
        speaker := new_speaker;
        sb += ch;
      end;
      
      var sb_neutral := new StringBuilder(s.Length);
      foreach var ch in s do
      begin
        var new_speaker := speaker_per_letter.Get(ch);
//        $'[{ch}: {new_speaker?.Voice.Culture.Name??''nil''}]'.Println;
        if new_speaker=nil then
        begin
          sb_neutral.Append(ch);
          continue;
        end;
        
        if speaker in |nil,new_speaker| then
        begin
          speaker := new_speaker;
          sb.Append(sb_neutral);
          sb_neutral.Clear;
        end else
        begin
          for var i := 0 to sb_neutral.Length-1 do
            add_char(sb_neutral[i], def_speaker);
          sb_neutral.Clear;
        end;
        
        add_char(ch, new_speaker);
      end;
      if speaker=nil then
        speaker := def_speaker;
      sb.Append(sb_neutral);
      
      dump;
    except
      on System.OperationCanceledException do
        ;
      on e: Exception do
        MessageBox.Show(e.ToString, 'Error speaking');
    end);
    
  except
    on e: Exception do
      Println('Failed to init TTS:', e);
  end;
  
  {$endregion speak}
  
  var need_resize := false;
  var copy_camera_pos := default(Tuple<string>);
  var paste_camera_pos := default(Tuple<CameraPos>);
  var mouse_captured := true;
  var sheet_less_mode := false;
  var mouse_pos := default(Vec2i);
  var mouse_grab_move := default(Vec2i);
  var scale_speed_add := 0;
  var camera_reset := false;
  var slow_move_dir := default(Vec2i);
  var slow_scale_dir1 := 0;
  var slow_scale_dir2 := 0;
  {$region Управление}
  begin
    
    {$region resize}
    
    f.Shown += (o,e)->
    begin
      need_resize := true;
      f.Resize += (o,e)->
      begin
        need_resize := true;
        // Чтобы не мигало - ждём завершения одной перерисовки
        // в потоке формы, то есть блокируя отсыл информации системе
        while need_resize do ;
      end;
    end;
    
    {$endregion resize}
    
    {$region copy/paste}
    
    if FileExists(camera_saved_pos_fname) then
    try
      paste_camera_pos := Tuple.Create(CameraPos.Parse(ReadAllText(camera_saved_pos_fname), speak));
    except
      on e: Exception do
        MessageBox.Show(e.ToString, $'Failed to load camera position');
    end;
    
    f.KeyUp += (o,e)->if e.Modifiers.HasFlag(Keys.Control) then
    case e.KeyCode of
      
      Keys.C:
      begin
        var copy_comment := default(string);
        if e.Modifiers.HasFlag(Keys.Shift) then
        begin
          var comment_inp_form := new Form;
          comment_inp_form.Text := 'Comment';
          comment_inp_form.FormBorderStyle := FormBorderStyle.FixedSingle;
          comment_inp_form.StartPosition := FormStartPosition.CenterParent;
          
          var comment_inp_tb := new RichTextBox;
          comment_inp_form.Controls.Add(comment_inp_tb);
          comment_inp_tb.Dock := DockStyle.Fill;
          
          var reset_form_size := ()->
          begin
            var text_size := comment_inp_form.CreateGraphics.MeasureString(comment_inp_tb.Text+'a', comment_inp_tb.Font);
            comment_inp_form.ClientSize := new System.Drawing.Size(
              Ceil(text_size.Width+10).ClampBottom(250),
              Ceil(text_size.Height+10).ClampBottom(30)
            );
            var screen_size := Screen.FromControl(comment_inp_form).WorkingArea.Size;
            comment_inp_form.Location := new System.Drawing.Point(
              (screen_size.Width-comment_inp_form.Width) div 2,
              (screen_size.Height-comment_inp_form.Height) div 2
            );
          end;
          reset_form_size;
          comment_inp_tb.TextChanged += (o,e)->reset_form_size();
          
          comment_inp_tb.KeyUp += (o,e)->
          case e.KeyCode of
            
            Keys.Escape:
              comment_inp_form.Close;
            
            Keys.Enter:
            if not e.Modifiers.HasFlag(Keys.Shift) then
            begin
              copy_comment := comment_inp_tb.Text.Replace(#13#10,#10);
              copy_comment := copy_comment.Remove(copy_comment.Length-1);
              comment_inp_form.Close;
            end;
            
          end;
          
          comment_inp_form.ShowDialog;
          if copy_comment=nil then exit;
        end;
        copy_camera_pos := Tuple.Create(copy_comment);
      end;
      
      Keys.V:
      try
        paste_camera_pos := Tuple.Create(
          CameraPos.Parse(Clipboard.GetText, speak)
        );
      except
        on ex: Exception do
          MessageBox.Show(ex.ToString, 'Failed to parse camera position');
      end;
      
    end;
    
    {$endregion copy/paste}
    
    {$region mouse_captured}
    
    f.MouseEnter += (o,e)->(mouse_captured := true);
    f.MouseLeave += (o,e)->(mouse_captured := false);
    
    {$endregion mouse_captured}
    
    {$region sheet_less_mode}
    
    f.KeyDown += (o,e)->if e.KeyCode=Keys.Q then sheet_less_mode := true;
    f.KeyUp   += (o,e)->if e.KeyCode=Keys.Q then sheet_less_mode := false;
    
    {$endregion sheet_less_mode}
    
    {$region camera reset}
    
    f.KeyDown += (o,e)->
    case e.KeyCode of
      Keys.Space:
      begin
        camera_reset := true;
        scale_speed_add := 0;
      end;
    end;
    
    {$endregion camera reset}
    
    {$region camera drag}
    
    var mouse_grabbed := false;
    f.MouseDown += (o,e)->
    case e.Button of
      MouseButtons.Left: mouse_grabbed := true;
    end;
    f.MouseUp += (o,e)->
    case e.Button of
      MouseButtons.Left: mouse_grabbed := false;
    end;
    
    f.MouseMove += (o,e)->
    begin
      var n_mouse_pos := new Vec2i(e.X,e.Y);
      if mouse_grabbed then
      begin
        var change := mouse_pos-n_mouse_pos;
        System.Threading.Interlocked.Add(mouse_grab_move.val0, change.val0);
        System.Threading.Interlocked.Add(mouse_grab_move.val1, change.val1);
      end;
      mouse_pos := n_mouse_pos;
    end;
    
    {$endregion camera drag}
    
    {$region camera scroll}
    
    f.MouseWheel += (o,e)->System.Threading.Interlocked.Add(scale_speed_add, e.Delta);
    
    {$endregion camera scroll}
    
    {$region camera slow control}
    
    var define_slow_control := procedure(key_low, key_high, modifiers: Keys; on_change: integer->())->
    begin
      var low_pressed := false;
      var high_pressed := false;
      var update := procedure->on_change(Ord(high_pressed)-Ord(low_pressed));
      f.KeyDown += (o,e)->
      begin
        if e.Modifiers and modifiers <> modifiers then exit;
        if e.KeyCode=key_low then low_pressed := true else
        if e.KeyCode=key_high then high_pressed := true else
          exit;
        update;
      end;
      f.KeyUp += (o,e)->
      begin
        if e.Modifiers and modifiers <> modifiers then exit;
        if e.KeyCode=key_low then low_pressed := false else
        if e.KeyCode=key_high then high_pressed := false else
          exit;
        update;
      end;
    end;
    
    define_slow_control(Keys.Subtract, Keys.Add, Keys.None, x->(slow_scale_dir1:=x));
    define_slow_control(Keys.OemMinus, Keys.Oemplus, Keys.Shift, x->(slow_scale_dir2:=x));
    
    define_slow_control(Keys.Left, Keys.Right, Keys.None, x->(slow_move_dir.val0:=x));
    define_slow_control(Keys.Down, Keys.Up, Keys.None, x->(slow_move_dir.val1:=x));
    
    {$endregion camera slow control}
    
  end;
  {$endregion Управление}
  
  var hdc := OpenGLABC.gl_gdi.InitControl(f);
  OpenGLABC.RedrawHelper.SetupRedrawThread(hdc, (pl, EndFrame)->
  try
    GL_CL_Context.Init(hdc);
    gl := new OpenGL.gl(pl);
    
    // Реализация от NVidia тратит 16мс на вызов clGLSharingKHR.EnqueueAcquireGLObjects (при чём синхронно), если не выключить vsync
    // Точнее vsync применяется и к EndFrame, и затем ещё раз к .EnqueueAcquireGLObjects
    // Ну, в этой программе vsync не сдался...
    if not wglSwapControlEXT.Instance.SwapIntervalEXT(0) then
      raise new System.InvalidOperationException;
    
    {$region Общие данные для всех кадров}
    
    var s_vert_empty := InitShaderResource('Empty.vert', glShaderType.VERTEX_SHADER); {$resource Shaders/Empty.vert}
    
    var s_geom_box := InitShaderResource('Box.geom', glShaderType.GEOMETRY_SHADER); {$resource Shaders/Box.geom}
    
    var s_frag_rainbow := InitShaderResource('Rainbow.frag', glShaderType.FRAGMENT_SHADER); {$resource Shaders/Rainbow.frag}
    
    var shader_prog: gl_program;
    var uniform_view_bound, uniform_sheet_bound: BoundUniforms;
    var uniform_sheet_size: integer;
    var ssb_sheet: integer;
    var choose_frag_shader := procedure(s_frag: gl_shader)->
    begin
      shader_prog := InitProgram(s_vert_empty, s_geom_box, s_frag);
      gl.UseProgram(shader_prog);
      uniform_view_bound := new BoundUniforms(shader_prog, 'view');
      uniform_sheet_bound := new BoundUniforms(shader_prog, 'sheet');
      uniform_sheet_size := gl.GetUniformLocation(shader_prog, 'sheet_size');
      ssb_sheet := gl.GetProgramResourceIndex(shader_prog, glProgramInterface.SHADER_STORAGE_BLOCK, 'sheet_block');
    end;
    //TODO Собственно использовать чтобы менять шейдеры
    choose_frag_shader(s_frag_rainbow);
    
    var sheet_draw := new CLGLArray<cardinal>(gl);
    var sheet_back := new CLGLArray<cardinal>(gl);
    var V_ExtractedCount := new CLValue<cardinal>;
    
    var last_render_info := default(BlockLayerRenderInfo?);
    var last_render_sheet_w := 0;
    
    // Для дебага
//    var buffer_temp: gl_buffer;
//    gl.CreateBuffers(1, buffer_temp);
//    gl.NamedBufferData(buffer_temp, new IntPtr(3*sizeof(real)), IntPtr.Zero, VertexBufferObjectUsage.DYNAMIC_READ);
//    gl.BindBufferBase(BufferTarget.SHADER_STORAGE_BUFFER, 1, buffer_temp);
    
    var t_full := new UpdateTimingQueue(30);
    var t_body := new UpdateTimingQueue(30);
    
    var camera := new CameraPos(f.ClientSize.Width, f.ClientSize.Height);
    var scale_speed := 0.0;
    
    var frame_time_sw := Stopwatch.StartNew;
    var last_frame_time := frame_time_sw.Elapsed;
    
    {$endregion Общие данные для всех кадров}
    
    while BlockUpdater.ShutdownProgress=nil do
    try
      var curr_frame_resized := false;
      begin
        var w_size := f.ClientSize;
        if need_resize then
        begin
          gl.Viewport(0,0, w_size.Width,w_size.Height);
          curr_frame_resized := true;
          camera.Resize(w_size.Width, w_size.Height);
        end;
        if camera_reset then
        begin
          camera_reset := false;
          camera := new CameraPos(w_size.Width, w_size.Height);
          scale_speed := 0;
        end;
      end;
      t_body.Start;
      
      begin
        var l_copy_camera_pos := System.Threading.Interlocked.Exchange(copy_camera_pos, nil);
        var n_camera := camera;
        if l_copy_camera_pos<>nil then f.BeginInvoke(()->
        begin
          Clipboard.SetText(n_camera.ToString(l_copy_camera_pos.Item1));
          Console.Beep;
        end);
      end;
      
      begin
        var l_paste_camera_pos := System.Threading.Interlocked.Exchange(paste_camera_pos, nil);
        if l_paste_camera_pos<>nil then
        begin
          var n_camera := l_paste_camera_pos.Item1;
          n_camera.dw := camera.dw;
          n_camera.dh := camera.dh;
          camera := n_camera;
          scale_speed := 0;
        end;
      end;
      
      begin
        var next_frame_time := frame_time_sw.Elapsed;
        var frame_len := (next_frame_time-last_frame_time).TotalSeconds;
        last_frame_time := next_frame_time;
        
        scale_speed += System.Threading.Interlocked.Exchange(scale_speed_add,0) * 0.005;
        
        camera.Move(
          slow_move_dir.val0*10 * frame_len + System.Threading.Interlocked.Exchange(mouse_grab_move.val0, 0),
          slow_move_dir.val1*10 * frame_len - System.Threading.Interlocked.Exchange(mouse_grab_move.val1, 0),
          mouse_pos.val0, mouse_pos.val1,
          scale_speed + frame_len * (slow_scale_dir1+slow_scale_dir2),
          mouse_captured
        );
        
        scale_speed *= 0.5;
      end;
      
      camera.FixWordCount;
      var render_info := BlockLayer.GetLayer(camera).GetRenderInfo(camera, last_render_info);
      BlockUpdater.SetCurrent(render_info.block_area);
      last_render_info := render_info;
      
      {$region Кадр}
      gl.Clear(glClearBufferMask.COLOR_BUFFER_BIT);
      
      var blocks := render_info.block_area.MakeInitedBlocksMatr;
      var b_cy := blocks.GetLength(0);
      var b_cx := blocks.GetLength(1);
      
      var render_sheet_w := b_cx * block_w;
      var render_sheet_h := b_cy * block_w;
      
      var l_sheet_less_mode := sheet_less_mode;
      var need_back_sheet := not l_sheet_less_mode
        and (render_info.last_sheet_diff<>nil)
        and not render_info.last_sheet_diff.Value.IsNoChange;
      
      var Q_Acquire := CQNil;
      var Q_Release := CQNil;
      var Q_Init := CQNil;
      if need_back_sheet and not l_sheet_less_mode then
      begin
        Q_Acquire += CQAcquireGL(sheet_draw.b_cl);
        Q_Release += CQReleaseGL(sheet_draw.b_cl);
        Swap(sheet_back, sheet_draw);
      end;
      var need_zero_out := l_sheet_less_mode or sheet_draw.EnsureLen(render_sheet_w * render_sheet_h);
      Q_Acquire += CQAcquireGL(sheet_draw.b_cl);
      Q_Release += CQReleaseGL(sheet_draw.b_cl);
      if need_back_sheet or need_zero_out then
        Q_Init += sheet_draw.b_cl.MakeCCQ.ThenFillValue(0).DiscardResult;
      if need_back_sheet then
        Q_Init += render_info.last_sheet_diff.Value.CQ_CopySheet(sheet_back.b_cl, sheet_draw.b_cl, last_render_sheet_w, render_sheet_w, render_sheet_h);
      last_render_sheet_w := render_sheet_w;
      
      //TODO С текущими очередями OpenCLABC не получится тут использовать имеющуюся очередь
      // - Проблема в том что CQ_GetData может выдавать CQNil, если блок создан, но его vram_data не инициализировано
      // - Чтобы это решить надо сначала доделать ветвление в OpenCLABC
      var Q_Extract := V_ExtractedCount.MakeCCQ.ThenWriteValue(0).DiscardResult;
      for var b_y := 0 to b_cy-1 do
        for var b_x := 0 to b_cx-1 do
        begin
          var b := blocks[b_y, b_x];
          if b=nil then continue;
          var sheet_shift := block_w * (b_x + b_y*render_sheet_w);
          Q_Extract += b.CQ_GetData(
            new ShiftedCLArray<cardinal>(sheet_draw.b_cl, sheet_shift, render_sheet_w),
            V_ExtractedCount
          );
        end;
      
//      var sw := Stopwatch.StartNew;
      var extracted_count := CLContext.Default.SyncInvoke(
        Q_Acquire +
        Q_Init +
        Q_Extract +
        Q_Release +
        V_ExtractedCount.MakeCCQ.ThenGetValue
      );
//      Println(sw.Elapsed);
      
      uniform_view_bound.Write(render_info.view_bound);
      uniform_sheet_bound.Write(render_info.sheet_bound);
      gl.Uniform2i(uniform_sheet_size, render_sheet_w, render_sheet_h);
      gl.BindBufferBase(glBufferTarget.SHADER_STORAGE_BUFFER, ssb_sheet, sheet_draw.b_gl);
      
      // Для дебага
//      gl.NamedBufferSubData(buffer_temp, new IntPtr(0*sizeof(real)), new IntPtr(2*sizeof(real)), mouse_pos);
      
      gl.DrawArrays(glPrimitiveType.POINTS, 0,1);
      
      // Для дебага
//      var temp_data := new real[1];
//      gl.GetNamedBufferSubData(buffer_temp, new IntPtr(2*sizeof(real)), new IntPtr(1*sizeof(real)), temp_data);
      
//      gl.BindBufferBase(glBufferTarget.SHADER_STORAGE_BUFFER, ssb_sheet, gl_buffer.Zero);
      
      gl.Finish; //TODO Использовать обмент ивентами OpenCL/OpenGL
      {$endregion Кадр}
      
      var err := gl.GetError;
      if err.IS_ERROR then MessageBox.Show(err.ToString);
      
      t_body.Stop;
      if curr_frame_resized then
        need_resize := false;
      
      var title_parts := new List<string>;
      
      // Для дебага
//      title_parts += $'temp_data={_ObjectToString(temp_data)}';
      
//      title_parts += $'mem={CLMemoryObserver.Current.CurrentlyUsedAmount}';
//      title_parts += $'rendering {b_cx} x {b_cy} blocks';
//      title_parts += $'sheet byte size={curr_sheet_size} (${curr_sheet_size:X})';
      
      t_full.Update;
      t_body.Update;
      title_parts += $'{t_full.UPS:N2} fps';
      title_parts += $'{t_full.MSPU:N2} full mspf';
//      title_parts += $'{t_body.UPS:N2} body fps';
      title_parts += $'{t_body.MSPU:N2} body mspf';
      
      title_parts += $'scale={camera.scale_fine:N3}*2^{camera.scale_pow}';
//      title_parts += $'pos=({camera.pos.r}; {camera.pos.i})';
      
      title_parts += $'{1-extracted_count/render_sheet_w/render_sheet_h:00.00%} old';
      
      if BlockUpdater.StepInfoStr<>nil then
        title_parts += BlockUpdater.StepInfoStr;
      
//      title_parts += $'RAM: {GC.GetTotalMemory(true)/1024/1024/1024:N5} GC vs {System.Diagnostics.Process.GetCurrentProcess.WorkingSet64/1024/1024/1024:N5} Process';
      
      if BlockUpdater.LackingVRAM then
        title_parts += $'LACKING VRAM!!!';
      
      System.Threading.Tasks.Task.Run(()->
        f.Invoke(()->
        try
          f.Text := title_parts.JoinToString(', ');
        except
          on e: Exception do
            MessageBox.Show(e.ToString);
        end)
      );
      
      EndFrame;
    except
      on e: Exception do
        Println(e);
    end;
    
    WriteAllText(camera_saved_pos_fname, camera.ToString, camera_saved_pos_enc);
    wait_for_last_frame := false;
  except
    on e: Exception do
    begin
      MessageBox.Show(e.ToString);
      Halt;
    end;
  end);
  
  System.Windows.Forms.Application.Run(f);
end.