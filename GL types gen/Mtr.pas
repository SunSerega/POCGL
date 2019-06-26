program prog;
{$apptype windows}
{$reference System.Windows.Forms.dll}

//ToDo issue компилятора:
// - #2021

function gl_to_pas_t(self: string): string; extensionmethod;
begin
  case self of
    ''+'f':     Result := 'single';
    ''+'d':     Result := 'real';
  end;
end;

type t_descr = (
  (integer,integer), // sz
  string,            // gl_t
  string             // pas_t
);

function GetName(self: t_descr); extensionmethod :=
$'Mtr{self[0][0]}x{self[0][1]}{self[1]}';

function GetRowTName(self: t_descr); extensionmethod :=
$'Vec{self[0][1]}{self[1]}';

function GetColTName(self: t_descr); extensionmethod :=
$'Vec{self[0][0]}{self[1]}';

function GetMltResT(self: (t_descr,t_descr)): t_descr; extensionmethod :=
((self[0][0][0], self[1][0][1]), self[0][1], self[0][2]);

procedure AddMtrType(res: StringBuilder; t: t_descr; prev_tps: sequence of t_descr);
begin
  res += $'  '+#10;
  res += $'  {t.GetName} = record'+#10;
  
  
  
  for var y := 0 to t[0][0]-1 do
  begin
    res += $'    public ';
    res += Range(0, t[0][1]-1).Select(x->$'val{y}{x}').JoinIntoString(', ');
    res += $': {t[2]};' + #10;
  end;
  
  
  
  res += $'    '+#10;
  res += $'    public constructor(';
  res +=
    Range(0,t[0][0]-1)
    .Cartesian(Range(0,t[0][1]-1))
    .Select(pos->$'val{pos[0]}{pos[1]}')
    .JoinIntoString(', ');
  res += $': {t[2]});'+#10;
  
  res += $'    begin'+#10;
  
  for var y := 0 to t[0][0]-1 do
    for var x := 0 to t[0][1]-1 do
      res += $'      self.val{y}{x} := val{y}{x};'+#10;
  
  res += $'    end;'+#10;
  
  
  
  res += $'    '+#10;
  
  res +=      $'    private function GetValAt(y,x: integer): {t[2]};'+#10;
  res +=      $'    begin'+#10;
  res +=      $'      case y of'+#10;
  for var y := 0 to t[0][0]-1 do
  begin
    res +=    $'        {y}:'+#10;
    res +=    $'        case x of'+#10;
    for var x := 0 to t[0][1]-1 do
      res +=  $'          {x}: Result := self.val{y}{x};'+#10;
    res +=    $'          else raise new IndexOutOfRangeException(''Индекс "X" должен иметь значение 0..{t[0][1]-1}'');'+#10;
    res +=    $'        end;'+#10;
  end;
  res +=      $'        else raise new IndexOutOfRangeException(''Индекс "Y" должен иметь значение 0..{t[0][0]-1}'');'+#10;
  res +=      $'      end;'+#10;
  res +=      $'    end;'+#10;
  
  res +=      $'    private procedure SetValAt(y,x: integer; val: {t[2]});'+#10;
  res +=      $'    begin'+#10;
  res +=      $'      case y of'+#10;
  for var y := 0 to t[0][0]-1 do
  begin
    res +=    $'        {y}:'+#10;
    res +=    $'        case x of'+#10;
    for var x := 0 to t[0][1]-1 do
      res +=  $'          {x}: self.val{y}{x} := val;'+#10;
    res +=    $'          else raise new IndexOutOfRangeException(''Индекс "X" должен иметь значение 0..{t[0][1]-1}'');'+#10;
    res +=    $'        end;'+#10;
  end;
  res +=      $'        else raise new IndexOutOfRangeException(''Индекс "Y" должен иметь значение 0..{t[0][0]-1}'');'+#10;
  res +=      $'      end;'+#10;
  res +=      $'    end;'+#10;
  
  res += $'    public property val[y,x: integer]: {t[2]} read GetValAt write SetValAt; default;'+#10;
  
  
  
  res += $'    '+#10;
  
  res += $'    public static property Identity: {t.GetName} read new {t.GetName}(';
  res +=
    Range(0,t[0][0]-1)
    .Cartesian(Range(0,t[0][1]-1))
    .Select(pos-> pos[0]=pos[1] ? '1.0' : '0.0' )
    .JoinIntoString(', ');
  res += $');'+#10;
  
  
  
  res += $'    '+#10;
  
  for var y := 0 to t[0][0]-1 do
  begin
    res += $'    public property Row{y}: {t.GetRowTName} read new {t.GetRowTName}(';
    res +=
      Range(0,t[0][1]-1)
      .Select(x-> $'self.val{y}{x}' )
      .JoinIntoString(', ');
    res += $') write begin';
    for var x := 0 to t[0][1]-1 do
      res += $' self.val{y}{x} := value.val{x};';
    res += $' end;'+#10;
  end;
  
  res += $'    public property Row[y: integer]: {t.GetRowTName} read ';
  for var y := 0 to t[0][0]-1 do
    res += $'y={y}?Row{y}:';
  res += $'Arr&<{t.GetRowTName}>[y]';
  res += $' write'+#10;
  res += $'    case y of'+#10;
  for var y := 0 to t[0][0]-1 do
    res += $'      {y}: Row{y} := value;'+#10;
  res += $'      else raise new IndexOutOfRangeException(''Номер строчки должен иметь значение 0..{t[0][0]-1}'');'+#10;
  res += $'    end;'+#10;
  
  
  
  res += $'    '+#10;
  
  for var x := 0 to t[0][1]-1 do
  begin
    res += $'    public property Col{x}: {t.GetColTName} read new {t.GetColTName}(';
    res +=
      Range(0,t[0][0]-1)
      .Select(y-> $'self.val{y}{x}' )
      .JoinIntoString(', ');
    res += $') write begin';
    for var y := 0 to t[0][0]-1 do
      res += $' self.val{y}{x} := value.val{y};';
    res += $' end;'+#10;
  end;
  
  res += $'    public property Col[x: integer]: {t.GetColTName} read ';
  for var x := 0 to t[0][1]-1 do
    res += $'x={x}?Col{x}:';
  res += $'Arr&<{t.GetColTName}>[x]';
  res += $' write'+#10;
  res += $'    case x of'+#10;
  for var x := 0 to t[0][1]-1 do
    res += $'      {x}: Col{x} := value;'+#10;
  res += $'      else raise new IndexOutOfRangeException(''Номер столбца должен иметь значение 0..{t[0][1]-1}'');'+#10;
  res += $'    end;'+#10;
  
  
  
  res += $'    '+#10;
  
  for var x := 0 to t[0][1]-1 do
    res += $'    public property RowPtr{x}: ^{t.GetRowTName} read pointer(IntPtr(pointer(@self)) + {x*t[0][1]*(t[1].Contains(''d'')?8:4)});'+#10;
  res += $'    public property RowPtr[x: integer]: ^{t.GetRowTName} read pointer(IntPtr(pointer(@self)) + x*{t[0][1]*(t[1].Contains(''d'')?8:4)});'+#10;
  
  
  
  var mtr_mlt_tps := new List<(t_descr,t_descr)>;
  
  if t[0][0]=t[0][1] then mtr_mlt_tps += (t,t);
  
  for var i := 2 to 4 do
  begin
    var t2 := ((t[0][1],i), t[1], t[2]);
    if prev_tps.Contains(t2) and prev_tps.Contains((t,t2).GetMltResT) then mtr_mlt_tps += (t,t2);
  end;
  
  for var i := 2 to 4 do
  begin
    var t2 := ((i,t[0][0]), t[1], t[2]);
    if prev_tps.Contains(t2) and prev_tps.Contains((t2,t).GetMltResT) then mtr_mlt_tps += (t2,t);
  end;
  
  //ToDo #2021
//  for var i := 2 to 4 do
//  begin
//    var t1 := ((t[0][0], i), t[1], t[2]);
//    var t2 := ((i, t[0][1]), t[1], t[2]);
//    if prev_tps.Contains(t1) and prev_tps.Contains(t2) then mtr_mlt_tps += (t1,t2);
//  end;
  
  foreach var tt in mtr_mlt_tps do
  begin
    var rt := tt.GetMltResT;
    res += $'    '+#10;
    
    res +=      $'    public static function operator*(m1: {tt[0].GetName}; m2: {tt[1].GetName}): {rt.GetName};'+#10;
    res +=      $'    begin'+#10;
    for var y := 0 to rt[0][0]-1 do
      for var x := 0 to rt[0][1]-1 do
      begin
        res +=  $'      Result.val{y}{x} := ';
        res +=
          Range(0, tt[0][0][1]-1)
          .Select(i-> $'m1.val{y}{i}*m2.val{i}{x}' )
          .JoinIntoString(' + ');
        res += ';'#10;
      end;
    res +=      $'    end;'+#10;
    
  end;
  
  
  
  res += $'    '+#10;
  
  res += $'    public static function operator*(m: {t.GetName}; v: {t.GetRowTName}): {t.GetColTName} := new {t.GetColTName}(';
  res +=
    Range(0,t[0][0]-1)
    .Select(y->
      Range(0,t[0][1]-1)
      .Select(x->
        $'m.val{y}{x}*v.val{x}'
      ).JoinIntoString('+')
    ).JoinIntoString(', ');
  res += $');'+#10;
  
  res += $'    public static function operator*(v: {t.GetColTName}; m: {t.GetName}): {t.GetRowTName} := new {t.GetRowTName}(';
  res +=
    Range(0,t[0][1]-1)
    .Select(x->
      Range(0,t[0][0]-1)
      .Select(y->
        $'m.val{y}{x}*v.val{y}'
      ).JoinIntoString('+')
    ).JoinIntoString(', ');
  res += $');'+#10;
  
  
  
  foreach var t2 in prev_tps do
  begin
    res += $'    '+#10;
    
    res += $'    public static function operator implicit(m: {t2.GetName}): {t.GetName} := new {t.GetName}(';
    res +=
      Range(0,t[0][0]-1)
      .Cartesian(Range(0,t[0][1]-1))
      .Select(pos-> (pos[0]<t2[0][0]) and (pos[1]<t2[0][1]) ? $'m.val{pos[0]}{pos[1]}' : '0.0' )
      .JoinIntoString(', ');
    res += $');'+#10;
    
    res += $'    public static function operator implicit(m: {t.GetName}): {t2.GetName} := new {t2.GetName}(';
    res +=
      Range(0,t2[0][0]-1)
      .Cartesian(Range(0,t2[0][1]-1))
      .Select(pos-> (pos[0]<t[0][0]) and (pos[1]<t[0][1]) ? $'m.val{pos[0]}{pos[1]}' : '0.0' )
      .JoinIntoString(', ');
    res += $');'+#10;
    
  end;
  
  
  
  res += $'    '+#10;
  
  res += $'  end;'+#10;
  if t[0][0]=t[0][1] then
    res += $'  Mtr{t[0][0]}{t[1]} = {t.GetName};'+#10;
  
end;

procedure AddTranspose(res: StringBuilder; sz1,sz2: integer; gl_t: string);
begin
  var t1 := ((sz1,sz2), gl_t, gl_t.gl_to_pas_t);
  var t2 := ((sz2,sz1), gl_t, gl_t.gl_to_pas_t);
  
  res += '  '#10;
  res += $'  function Transpose(self: {t1.GetName}); extensionmethod :='+#10;
  res += $'  new {t2.GetName}(';
  res +=
    Range(0,sz2-1)
    .Cartesian(Range(0,sz1-1))
    .Select(pos-> $'self.val{pos[1]}{pos[0]}' )
    .JoinIntoString(', ');
  res += ');'#10;
  res += $'  function Transpose(self: {t2.GetName}); extensionmethod :='+#10;
  res += $'  new {t1.GetName}(';
  res +=
    Range(0,sz1-1)
    .Cartesian(Range(0,sz2-1))
    .Select(pos-> $'self.val{pos[1]}{pos[0]}' )
    .JoinIntoString(', ');
  res += ');'#10;
  
end;

begin
  try
    var res := new StringBuilder;
    
    res += #10;
    res += '  {$region Mtr}'#10;
    
    var t_table: sequence of t_descr :=
      Range(2,4)
      .Cartesian(Range(2,4))
      .SelectMany(sz->
        Arr&<string>('f','d')
        .Select(t->(sz,t,t.gl_to_pas_t))
      ).OrderBy(t->t[0][0]=t[0][1]?integer.MinValue:t[0][0]+t[0][1])
      .OrderByDescending(t->t[1])
      .ToArray
    ;
    
    foreach var t in t_table.Numerate(0) do
      AddMtrType(res, t[1], t_table.Take(t[0]));
    
    res += '  '#10;
    res += '  {$endregion Mtr}'#10;
    res += '  '#10;
    res += '  {$region MtrTranspose}'#10;
    
    foreach var t in Arr('f','d') do
    begin
      AddTranspose(res, 2,3, t);
      AddTranspose(res, 2,4, t);
      AddTranspose(res, 3,4, t);
    end;
    
    res += '  '#10;
    res += '  {$endregion MtrTranspose}'#10;
    
    res += '  ';
    System.Windows.Forms.Clipboard.SetText(res.ToString.Replace(#10,#13#10));
    System.Console.Beep;
  except
    on e: Exception do
    begin
      writeln(e);
      readln;
    end;
  end;
end.