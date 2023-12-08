## uses OpenCLABC, Settings, Blocks, CameraDef;

var max_iterations := 256;

//TODO Сейчас только степени двойки
// - Пожалуй частичный рендеринг тут тестить уже после того как напишу основной рендеринг
var view_w := 1024;
var view_h := 1024;

var more_output := true;
{$ifdef ForceMaxDebug}
more_output := false;
{$endif ForceMaxDebug}

var render_info := BlockLayer.BlocksForCurrentScale(new CameraPos(view_w,view_h));
var b_cy := render_info.blocks.GetLength(0);
var b_cx := render_info.blocks.GetLength(1);

var render_block_size := Settings.block_w shr render_info.mipmap_lvl;
var render_sheet_w := b_cx * render_block_size;
var render_sheet_h := b_cy * render_block_size;

var A_State := new CLArray<byte>(render_sheet_w*render_sheet_h);
var A_Steps := new CLArray<cardinal>(A_State.Length);
var V_UpdateCount := new CLValue<cardinal>(0);
var A_Err := new CLArray<cardinal>(3);

var Q_Init := CQNil
  + A_State.MakeCCQ.ThenFillValue(0)
  + A_Steps.MakeCCQ.ThenFillValue(0)
  + A_Err.MakeCCQ.ThenFillValue(0)
;

var Q_Steps := CQNil;
var Q_Extract := CQNil;
for var b_y := 0 to b_cy-1 do
  for var b_x := 0 to b_cx-1 do
  begin
    var b := render_info.blocks[b_y, b_x];
//    if (b_x, b_y) <> (1,1) then continue;
    
    // Можно распараллелить, заменив += на *= (и в случае Q_Extract)
    // Но из тестирования - затраты на синхронизацию тут того не стоят
    //TODO Раз всё последовательно считает - можно по 1 блоку выделять и освобождать сразу...
    Q_Steps += b.CQ_MandelbrotBlockStep(max_iterations, V_UpdateCount, A_Err);
    
    var sheet_shift := render_block_size * (b_x + b_y*render_sheet_w);
    Q_Extract += b.CQ_GetData(render_info.mipmap_lvl
      , new ShiftedCLArray<byte>(A_State, sheet_shift, render_sheet_w)
      , new ShiftedCLArray<cardinal>(A_Steps, sheet_shift, render_sheet_w)
    );
    
  end;

var sw := Stopwatch.StartNew;
var err_data := new cardinal[3];
var sheet_data := CLContext.Default.SyncInvoke(
  Q_Init +
  Q_Steps +
  Q_Extract +
  A_Err.MakeCCQ.ThenReadArray(err_data) +
  A_Steps.MakeCCQ.ThenGetArray2(render_sheet_h, render_sheet_w)
);

if more_output then
  Println(sw.Elapsed);
if err_data[0]<>0 then
  $'Err at [{err_data[1]},{err_data[2]}]: {CLCodeExecutionError(err_data[0])}'.Println;
$'Updates: {V_UpdateCount.GetValue}'.Println;

{$reference System.Drawing.dll}
var bmp := new System.Drawing.Bitmap(render_sheet_w, render_sheet_h);
for var y := 0 to render_sheet_h-1 do
  for var x := 0 to render_sheet_w-1 do
  begin
    var v := Round( (sheet_data[y,x]/max_iterations)**0.5 * 255);
    bmp.SetPixel(x, y, System.Drawing.Color.FromArgb(v,v,v));
  end;

var res_fname := 'FieldTest.bmp';
var tmp_fname := 'FieldTest.temp.bmp';
bmp.Save(tmp_fname);

var res_changed := function: boolean ->
begin
  Result := true;
  var br1 := new System.IO.BinaryReader(System.IO.File.OpenRead(res_fname));
  var br2 := new System.IO.BinaryReader(System.IO.File.OpenRead(tmp_fname));
  try
    
    if br1.BaseStream.Length <> br2.BaseStream.Length then
      exit;
    
    loop br1.BaseStream.Length do
      if br1.ReadByte <> br2.ReadByte then
        exit;
    
  finally
    br1.Close;
    br2.Close;
  end;
  Result := false;
end;

if res_changed then
  $'Result image changed'.Println;
System.IO.File.Delete(res_fname);
System.IO.File.Move(tmp_fname, res_fname);

if more_output and ('[REDIRECTIOMODE]' not in System.Environment.CommandLine) then
begin
  $'Press enter to exit'.Println;
  Readln;
end;