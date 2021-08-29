## uses OpenCLABC, GraphWPF;

try
  var W := 100;
  Window.Maximize;
  
  var code := new ProgramCode(Context.Default, ReadAllText('Игра жизнь.cl'));
  var k := code['CalcTick'];
  
  //ToDo Использовать CLArray2<byte> когда будет
  var B := new MemorySegment(W*W*sizeof(byte));
  B.WriteArray2&<byte>(MatrGen(W,W, (x,y)->byte(Random(2)=0)));
  
  var q := new System.Collections.Concurrent.ConcurrentQueue<array[,] of byte>;
  
  var Q_1Cycle :=
    k.NewQueue
    .AddExec2(W,W,
      B, W
    )
  +
    B.NewQueue
    .AddGetArray2&<byte>(W,W)
    .ThenConvert&<array[,] of byte>(field->
    begin
      // Если уже слишком далеко вперёд насчитали - можно немного отдохнуть
      while q.Count=16 do Sleep(10);
      q.Enqueue(field);
      Result := field;
    end)
  ;
  
  BeginFrameBasedAnimation(frame->
  begin
    var field: array[,] of byte;
    while not q.TryDequeue(field) do Sleep(1);
    Window.Title := $'Обработка №{frame}';
    
    var min_window_size := Min(Window.Width, Window.Height);
    var cell_w := min_window_size / W;
    var dx := (Window.Width -min_window_size)/2;
    var dy := (Window.Height-min_window_size)/2;
    GraphWPF.FastDraw(dc->
    begin
      for var x := 0 to W-1 do
        for var y := 0 to W-1 do
          GraphWPF.DrawRectangleDC(dc,
            dx + cell_w*x, dy + cell_w*y,
            cell_w, cell_w,
            if field[x,y]<>0 then Colors.DarkRed else Colors.Green,
            Colors.Transparent,0
          );
    end);
    
  end);
  
  while true do
  begin
    Context.Default.SyncInvoke(
      Q_1Cycle
    );
  end;
  
except
  on e: Exception do
  begin
    Writeln(e);
    Halt;
  end;
end;