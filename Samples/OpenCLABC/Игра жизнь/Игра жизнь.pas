﻿## uses OpenCLABC, GraphWPF;

try
  var W := 100;
  var fps := 20;
  Window.Maximize;
  
  // Очередь состояний поля, ожидающих отрисовки
  // Не путать с очередями команд OpenCLABC
  var field_states_q := new System.Collections.Concurrent.ConcurrentQueue<array[,] of byte>;
  
  BeginFrameBasedAnimation(frame->
  begin
    var field: array[,] of byte;
    while not field_states_q.TryDequeue(field) do Sleep(1);
    Window.Title := $'Шаг №{frame}';
    
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
    
  end, fps);
  
  var B := new CLArray<byte>(ArrGen(W*W, i->byte(Random(2))));
  var B_temp := new CLArray<byte>(B.Length);
  
  var code := new CLProgramCode(ReadAllText('Игра жизнь.cl'));
  
  var Q_1Step :=
    code['CalcStep']
    .MakeCCQ
    .ThenExec2(W,W,
      HFQ(()->B, false),
      HFQ(()->B_temp, false),
      W
    ) +
    HPQ(()->Swap(B,B_temp), false)
 ;
 var Q_Otp :=
    B.MakeCCQ
    .ThenGetArray2(W,W)
    .ThenUse(field->
    begin
      // Если уже слишком далеко вперёд насчитали - можно немного отдохнуть
      while field_states_q.Count=16 do Sleep(1000 div fps);
      field_states_q.Enqueue(field);
    end)
  ;
  
  while true do
  begin
    CLContext.Default.SyncInvoke(
      Q_1Step +
      Q_Otp
    );
  end;
  
except
  on ae: System.AggregateException do
    foreach var e in ae.InnerExceptions do
      Println(e);
end;