## uses OpenCLABC, Blocks, CameraDef, Settings;

var max_iterations := 256;

// Только степени двойки
// Если нет - округлит наверх до следующей степени двойки
// Потому что из GetRenderInfo берёт только .block_area,
// выбрасывая всю информацию о границах экрана
var view_w := 1024;
var view_h := 1024;

var more_output := true;
{$ifdef ForceMaxDebug}
more_output := false;
{$endif ForceMaxDebug}

CLMemoryObserver.Current := new TrackingMemoryObserver;

var camera := new CameraPos(view_w,view_h);
var layer := BlockLayer.GetLayer(camera);
var block_area: BlockLayerSubArea := layer.GetRenderInfo(camera, nil).block_area;
block_area.InitAllBlocks;
var blocks := block_area.MakeInitedBlocksMatr;
var b_cy := blocks.GetLength(0);
var b_cx := blocks.GetLength(1);

var render_block_size := Settings.block_w;
var render_sheet_w := b_cx * render_block_size;
var render_sheet_h := b_cy * render_block_size;

var A_Sheet := new CLArray<cardinal>(render_sheet_w*render_sheet_h);
var V_UpdateCount := new CLValue<cardinal>(0);
var V_ExtractedCount := new CLValue<cardinal>(0);
var A_Err := new CLArray<cardinal>(3);

var Q_Init := CQNil
  + A_Sheet.MakeCCQ.ThenFillValue(0).DiscardResult
  + A_Err.MakeCCQ.ThenFillValue(0).DiscardResult
;

var Q_Steps := CQNil;
var Q_Extract := CQNil;
for var b_y := 0 to b_cy-1 do
  for var b_x := 0 to b_cx-1 do
  begin
    var b := blocks[b_y, b_x];
//    if (b_x, b_y) <> (1,1) then continue;
    
    Q_Init += b.CQ_UpGradeToVRAM;
    
    // Можно распараллелить, заменив += на *= (и в случае Q_Extract)
    // Но из тестирования - затраты на синхронизацию тут того не стоят
    //TODO Раз всё последовательно считает - можно по 1 блоку выделять и освобождать сразу...
    Q_Steps += b.CQ_MandelbrotBlockStep(max_iterations, V_UpdateCount, A_Err);
    
    var sheet_shift := render_block_size * (b_x + b_y*render_sheet_w);
    Q_Extract += b.CQ_GetData(new ShiftedCLArray<cardinal>(A_Sheet, sheet_shift, render_sheet_w), V_ExtractedCount);
    
  end;

var sw := Stopwatch.StartNew;
var err_data := new cardinal[3];
var sheet_data := CLContext.Default.SyncInvoke(
  Q_Init +
  Q_Steps +
  Q_Extract +
  A_Err.MakeCCQ.ThenReadArray(err_data) +
  V_UpdateCount.MakeCCQ.ThenGetValue.ThenUse(v->Println($'Updates: {v}')) +
  V_ExtractedCount.MakeCCQ.ThenGetValue.ThenUse(v->Println($'Extracted: {v}')) +
  A_Sheet.MakeCCQ.ThenGetArray2(render_sheet_h, render_sheet_w)
);

if more_output then
  Println(sw.Elapsed);
if err_data[0]<>0 then
  $'Err at [{err_data[1]},{err_data[2]}]: {CLCodeExecutionError(err_data[0])}'.Println;

var sps := -Settings.scale_pow_shift;
{$reference System.Drawing.dll}
var bmp := new System.Drawing.Bitmap(render_sheet_w shr sps, render_sheet_h shr sps);
for var y := 0 to bmp.Height-1 do
  for var x := 0 to bmp.Width-1 do
  begin
    var v_r := 0.0;
    for var dy := 0 to 1 shl sps - 1 do
      for var dx := 0 to 1 shl sps - 1 do
      begin
        var sy := y shl sps + dy;
        var sx := x shl sps + dx;
        v_r += ((sheet_data[sy,sx] and integer.MaxValue)/max_iterations) ** 0.5;
      end;
    v_r /= 1 shl (sps*2);
    var v := Round(v_r * 255);
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

$'Used a total of {CLMemoryObserver.Current.CurrentlyUsedAmount} VRAM bytes'.Println;
foreach var bl in blocks do
  bl.Dispose;
A_Sheet.Dispose;
V_UpdateCount.Dispose;
V_ExtractedCount.Dispose;
A_Err.Dispose;

if more_output and ('[REDIRECTIOMODE]' not in System.Environment.CommandLine) then
begin
  $'Press enter to exit'.Println;
  Readln;
end;