uses MtrBase;
uses PackingUtils in '..\PackingUtils';
uses POCGL_Utils  in '..\..\..\POCGL_Utils';

procedure AddMtrType(res: StringBuilder; t: t_descr; prev_tps: sequence of t_descr);
begin
  res += $'  '+#10;
  res += $'  {t.GetName} = record'+#10;
  
  var ANT: Dictionary<integer,char> := Dict((0,'X'),(1,'Y'),(2,'Z'));// axiss name table
  var MinSize := Min(t[0][0],t[0][1]);
  
  {$region field's}
  
  for var y := 0 to t[0][1]-1 do
  begin
    res += $'    public ';
    res += Range(0, t[0][0]-1).Select(x->$'val{x}{y}').JoinToString(', ');
    res += $': {t[2]};' + #10;
  end;
  
  {$endregion field's}
  
  {$region constructor's}
  
  res += $'    '+#10;
  
  res += $'    public constructor(';
  res +=
    Range(0,t[0][0]-1)
    .Cartesian(Range(0,t[0][1]-1))
    .Select(pos->$'val{pos[0]}{pos[1]}')
    .JoinToString(', ');
  res += $': {t[2]});'+#10;
  
  res += $'    begin'+#10;
  
  for var y := 0 to t[0][0]-1 do
    for var x := 0 to t[0][1]-1 do
      res += $'      self.val{y}{x} := val{y}{x};'+#10;
  
  res += $'    end;'+#10;
  
  {$endregion constructor's}
  
  {$region property's}
  
  {$region property val[y,x]}
  
//  res += $'    '+#10;
//  
//  res +=      $'    private function GetValAt(y,x: integer): {t[2]};'+#10;
//  res +=      $'    begin'+#10;
//  res +=      $'      if cardinal(x) > {t[0][1]-1} then raise new IndexOutOfRangeException(''Индекс "X" должен иметь значение 0..{t[0][1]-1}'');'+#10;
//  res +=      $'      if cardinal(y) > {t[0][0]-1} then raise new IndexOutOfRangeException(''Индекс "Y" должен иметь значение 0..{t[0][0]-1}'');'+#10;
//  res +=      $'      var ptr: ^{t[2]} := pointer(new IntPtr(@self) + (x*{t[0][0]} + y) * {t.GetTSize} );'+#10;
//  res +=      $'      Result := ptr^;'+#10;
//  res +=      $'    end;'+#10;
//  
//  res +=      $'    private procedure SetValAt(y,x: integer; val: {t[2]});'+#10;
//  res +=      $'    begin'+#10;
//  res +=      $'      if cardinal(x) > {t[0][1]-1} then raise new IndexOutOfRangeException(''Индекс "X" должен иметь значение 0..{t[0][1]-1}'');'+#10;
//  res +=      $'      if cardinal(y) > {t[0][0]-1} then raise new IndexOutOfRangeException(''Индекс "Y" должен иметь значение 0..{t[0][0]-1}'');'+#10;
//  res +=      $'      var ptr: ^{t[2]} := pointer(new IntPtr(@self) + (x*{t[0][0]} + y) * {t.GetTSize} );'+#10;
//  res +=      $'      ptr^ := val;'+#10;
//  res +=      $'    end;'+#10;
//  
//  res += $'    public property val[y,x: integer]: {t[2]} read GetValAt write SetValAt; default;'+#10;
  
  {$endregion property val[y,x]}
  
  {$region static property Identity}
  
  res += $'    '+#10;
  
  res += $'    public static property Identity: {t.GetName} read new {t.GetName}(';
  res +=
    Range(0,t[0][0]-1)
    .Cartesian(Range(0,t[0][1]-1))
    .Select(pos-> pos[0]=pos[1] ? '1.0' : '0.0' )
    .JoinToString(', ');
  res += $');'+#10;
  
  {$endregion static property Identity}
  
  {$region property's Row*}
  
  res += $'    '+#10;
  
  for var y := 0 to t[0][0]-1 do
  begin
    res += $'    public property Row{y}: {t.GetRowTName} read new {t.GetRowTName}(';
    res +=
      Range(0,t[0][1]-1)
      .Select(x-> $'self.val{y}{x}' )
      .JoinToString(', ');
    res += $') write begin';
    for var x := 0 to t[0][1]-1 do
      res += $' self.val{y}{x} := value.val{x};';
    res += $' end;'+#10;
  end;
  
//  res += $'    public property Row[y: integer]: {t.GetRowTName} read ';
//  for var y := 0 to t[0][0]-1 do
//    res += $'y={y}?Row{y}:';
//  res += $'Arr&<{t.GetRowTName}>[y]';
//  res += $' write'+#10;
//  res += $'    case y of'+#10;
//  for var y := 0 to t[0][0]-1 do
//    res += $'      {y}: Row{y} := value;'+#10;
//  res += $'      else raise new IndexOutOfRangeException(''Номер строчки должен иметь значение 0..{t[0][0]-1}'');'+#10;
//  res += $'    end;'+#10;
  
  {$endregion property's Row*}
  
  {$region property's Col*}
  
  res += $'    '+#10;
  
  for var x := 0 to t[0][1]-1 do
  begin
    res += $'    public property Col{x}: {t.GetColTName} read new {t.GetColTName}(';
    res +=
      Range(0,t[0][0]-1)
      .Select(y-> $'self.val{y}{x}' )
      .JoinToString(', ');
    res += $') write begin';
    for var y := 0 to t[0][0]-1 do
      res += $' self.val{y}{x} := value.val{y};';
    res += $' end;'+#10;
  end;
  
//  res += $'    public property Col[x: integer]: {t.GetColTName} read ';
//  for var x := 0 to t[0][1]-1 do
//    res += $'x={x}?Col{x}:';
//  res += $'Arr&<{t.GetColTName}>[x]';
//  res += $' write'+#10;
//  res += $'    case x of'+#10;
//  for var x := 0 to t[0][1]-1 do
//    res += $'      {x}: Col{x} := value;'+#10;
//  res += $'      else raise new IndexOutOfRangeException(''Номер столбца должен иметь значение 0..{t[0][1]-1}'');'+#10;
//  res += $'    end;'+#10;
  
  {$endregion property's Col*}
  
  {$region property ColPtr[x]}
  
  res += $'    '+#10;
  
  for var x := 0 to t[0][1]-1 do
    res += $'    public property ColPtr{x}: ^{t.GetColTName} read pointer(@val0{x});'+#10;
  res += $'    public property ColPtr[x: integer]: ^{t.GetColTName} read pointer(IntPtr(pointer(@self)) + x*{t[0][0]*t.GetTSize});'+#10;
  
  {$endregion property ColPtr[x]}
  
  {$endregion property's}
  
  {$region method's}
  
  {$region procedure/function UseColPtr}
  
  for var is_func := false to true do
  begin
    res += $'    '+#10;
    
    var T_def :=        is_func ? '<T>'                                 : nil;
    var method_word :=  is_func ? 'function'                            : 'procedure';
    var callback_t :=   is_func ? $'Use{t.GetColTName}PtrCallbackF<T>'  : $'Use{t.GetColTName}PtrCallbackP';
    var res_def :=      is_func ? ': T'                                 : nil;
    var set_res_def :=  is_func ? 'Result := '                          : nil;
    
    for var x := 0 to t[0][1]-1 do
    begin
      res +=  $'    public {method_word} UseColPtr{x}{T_def}(callback: {callback_t}){res_def};'+#10;
      res +=  $'    type P{t.GetColTName} = ^{t.GetColTName};'+#10;
      res +=  $'    begin {set_res_def}callback(P{t.GetColTName}(pointer(@val0{x}))^); end;'+#10;
    end;
    
//    res +=    $'    public {method_word} UseColPtr{T_def}(x: integer; callback: {callback_t}){res_def};'+#10;
//    res +=    $'    type P{t.GetColTName} = ^{t.GetColTName};'+#10;
//    res +=    $'    begin {set_res_def}callback(P{t.GetColTName}(pointer(IntPtr(pointer(@self)) + x*{t[0][0]*t.GetTSize}))^); end;'+#10;
    
  end;
  
  
  {$endregion procedure/function UseColPtr}
  
  {$region static function Scale}
  
  res += $'    '+#10;
  
  res += $'    public static function Scale(k: {t[2]}): {t.GetName} := new {t.GetName}(';
  res +=
    Range(0,t[0][0]-1)
    .Cartesian(Range(0,t[0][1]-1))
    .Select(pos->pos[0]=pos[1]?'k':'0.0')
    .JoinToString(', ');
  res += ');'#10;
  
  {$endregion static function Scale}
  
  {$region static function Translate}
  
  res += $'    '+#10;
  
  res += '    public static function Traslate(';
  res +=
    Range(0, t[0][0]=Max(t[0][0],t[0][1]) ? MinSize-2 : t[0][0]-1)
    .Select(n->ANT[n])
    .JoinToString(', ');
  res += $': {t[2]}): {t.GetName} := new {t.GetName}(';
  res +=
    Range(0,t[0][0]-1)
    .Cartesian(Range(0,t[0][1]-1))
    .Select(pos->
      pos[0]=pos[1] ?
      '1.0' :
      (pos[1]=t[0][1]-1) and (pos[0]<MinSize) ?
      ANT[pos[0]] :
      '0.0'
    )
    .JoinToString(', ');
  res += ');'+#10;
  
  res += '    public static function TraslateTransposed(';
  res +=
    Range(0, t[0][1]=Max(t[0][0],t[0][1]) ? MinSize-2 : t[0][1]-1)
    .Select(n->ANT[n])
    .JoinToString(', ');
  res += $': {t[2]}): {t.GetName} := new {t.GetName}(';
  res +=
    Range(0,t[0][0]-1)
    .Cartesian(Range(0,t[0][1]-1))
    .Select(pos->
      pos[0]=pos[1] ?
      '1.0' :
      (pos[0]=t[0][0]-1) and (pos[1]<MinSize) ?
      ANT[pos[1]] :
      '0.0'
    )
    .JoinToString(', ');
  res += ');'+#10;
  
  {$endregion static function Translate}
  
  {$region static function Rotate2D}
  
  begin
    
    var planes := MinSize >= 3 ?
      Seq((0,1), (1,2), (2,0)):
      Seq((0,1));
    
    foreach var plane in planes do
    begin
      res += $'    '+#10;
      
      var plane_name := ANT[plane[0]]+ANT[plane[1]];
      var mpc := HSet(plane[0], plane[1]); // mtr plane coord
      
      for var ccw_state := false to true do
      begin
        
        var rot_dir_word := ccw_state ? 'ccw' : 'cw';
        res += $'    public static function Rotate{plane_name}{rot_dir_word}(rot: double): {t.GetName};'+#10;
        res += $'    begin'+#10;
        res += $'      var sr: {t[2]} := Sin(rot);'+#10;
        res += $'      var cr: {t[2]} := Cos(rot);'+#10;
        res += $'      Result := new {t.GetName}('+#10;
        res += $'        ';
        res +=
          Range(0,t[0][0]-1)
          .Select(y->
            Range(0,t[0][1]-1)
            .Select(x->
            begin
              if (x in mpc) and (y in mpc) then
              begin
                if x=y then
                  Result := ' cr' else
                  Result := (y=plane[0]) xor ccw_state ? '+sr' : '-sr';
              end else
                Result := x=y ? '1.0' : '0.0';
            end)
            .JoinToString(', ')
          )
          .JoinToString(','#10'        ') + #10;
        res += $'      );'+#10;
        res += $'    end;'+#10;
        
      end;
      
    end;
    
  end;
  
  {$endregion static function Rotate2D}
  
  {$region static function Rotate3D}
  
  if MinSize >= 3 then
  begin
    //     ┌                  ┐
    //     │    0, +u.z, -u.y │
    // W = │ -u.z,    0, +u.x │
    //     │ +u.y, -u.x,    0 │
    //     └                  ┘
    //
    // Result =  Identity  +  Sin(rot)*W  +  (2*Sqr(Sin(rot/2))) * (W*W)
    
    var W_val_table: Dictionary<(integer,integer), string> := Dict(
                           ( (0,1), 'u.val2' ), ( (0,2), 'u.val1' ),
      ( (1,0), 'u.val2' ),                      ( (1,2), 'u.val0' ),
      ( (2,0), 'u.val1' ), ( (2,1), 'u.val0' )
    );
    var W_sign_table: Dictionary<(integer,integer), boolean> := Dict(
                        ( (0,1), true  ), ( (0,2), false ),
      ( (1,0), false ),                   ( (1,2), true  ),
      ( (2,0), true  ), ( (2,1), false )
    );
    
    for var ccw_state := false to true do
    begin
      res += $'    '+#10;
      
      var rot_dir_word := ccw_state ? 'ccw' : 'cw';
      res += $'    public static function Rotate3D{rot_dir_word}(u: Vec3{t[1]}; rot: double): {t.GetName};'+#10;
      res += $'    begin'+#10;
      res += $'      var k1 := Sin(rot);'+#10;
      res += $'      var k2 := 2*Sqr(Sin(rot/2));'+#10;
      res += $'      '+#10;
      for var y := 0 to 3-1 do
        for var x := 0 to 3-1 do
        begin
          res += $'      Result.val{y}{x} := ';
          
          if x=y then
            res += '1' else
            res += (W_sign_table[(y,x)] xor ccw_state ? '' : '-') + $'k1*{W_val_table[(y,x)]}';
          
          res += ' + k2*( ';
          var first_val := true;
          for var i := 0 to 3-1 do
          begin
            if (i=x) or (i=y) then continue;
            var curr_sign_plus := W_sign_table[(y,i)]=W_sign_table[(i,x)];
            
            if not first_val then
              res += curr_sign_plus?' + ':' - ' else
              res += curr_sign_plus?'':'-';
            
            res += $'{W_val_table[(y,i)]}*{W_val_table[(i,x)]}';
            first_val := false;
          end;
          res += ' );'#10;
        end;
      res += $'      '+#10;
      if (t[0][0]=4) and (t[0][1]=4) then
        res += $'      Result.val33 := 1;' + #10;
      res += $'    end;'+#10;
      
    end;
    
  end;
  
  {$endregion static function Rotate3D}
  
  {$region function Det}
  
  if t[0][0]=t[0][1] then
  begin
    res +=    $'    '+#10;
    
    res +=    $'    public function Det: {t[2]} :='+#10;
    res +=    $'    ';
    
    var skip_col := new Stack<integer>;
    var ElAt: function(y,x: integer): string :=
    (y,x)->$'val{y+skip_col.Count}{Range(0,t[0][0]).Where(i->not skip_col.Contains(i)).ElementAt(x)}';
    
    var AddDet: procedure;
    AddDet := ()->
    if skip_col.Count+2=t[0][0] then
      res += $'{ElAt(0,0)}*{ElAt(1,1)} - {ElAt(1,0)}*{ElAt(0,1)}' else
    for var i := 0 to t[0][0]-skip_col.Count-1 do
    begin
      if i<>0 then res += i.IsEven ? ' + ' : ' - ';
      res += $'{ElAt(0,i)} * (';
      skip_col.Push(i);
      AddDet;
      skip_col.Pop;
      res += ')';
    end;
    
    AddDet();
    
    res += ';'#10;
  end;
  {$endregion function Det}
  
  {$region static function Read}
  
  res +=        $'    '+#10;
  
  for var rows := true downto false do
    foreach var ln in |'', 'ln'| do
    begin
      res +=    $'    public static function Read{ln}';
      res += rows ? 'Rows' : 'Cols';
      res +=    $': {t.GetName};'+#10;
      res +=    $'    begin'+#10;
      for var i1 := 0 to rows ? t[0][0]-1 : t[0][1]-1 do
      begin
        res +=  $'      PABCSystem.Read{ln}(';
        res += Range(0, rows ? t[0][1]-1 : t[0][0]-1).Select(i2->rows ? $'Result.val{i1}{i2}' : $'Result.val{i2}{i1}').JoinToString(', ');
        res += ');'#10;
      end;
      res +=    $'    end;'+#10;
    end;
  
  {$endregion static function Read}
  
  {$region function ToString}
  
  res +=      $'    '+#10;
  
  res +=      $'    public function ToString: string; override;'+#10;
  res +=      $'    begin'+#10;
  res +=      $'      var res := new StringBuilder;'+#10;
  res +=      $'      '+#10;
  res +=      $'      var ElStrs := new string[{t[0][0]},{t[0][1]}];' + #10;
  for var y := 0 to t[0][0]-1 do
    for var x := 0 to t[0][1]-1 do
      res +=  $'      ElStrs[{y},{x}] := (Sign(val{y}{x})=-1?''-'':''+'') + Abs(val{y}{x}).ToString(''f2'');' + #10;
  res +=      $'      var MtrElTextW := ElStrs.OfType&<string>.Max(s->s.Length);' + #10;
  res +=      $'      var PrintlnMtrW := MtrElTextW*{t[0][1]} + {2*t[0][1]}; // +2*(Width-1) + 2;' + #10;
  
  res +=      $'      ' + #10;
  
  res +=      $'      res += ''{ char($250C) }'';'+#10;
  res +=      $'      res.Append(#32, PrintlnMtrW);'+#10;
  res +=      $'      res += ''{ char($2510) }''#10;'+#10;
  
  for var y := 0 to t[0][0]-1 do
  begin
    res +=    $'      res += ''{ char($2502) } '';'+#10;
    res +=
      Range(0,t[0][1]-1)
      .Select(x->$'      res += ElStrs[{y},{x}].PadLeft(MtrElTextW);'+#10)
      .JoinToString($'      res += '', '';'+#10);
    res +=    $'      res += '' { char($2502) }''#10;'+#10;
  end;
  
  res +=      $'      res += ''{ char($2514) }'';'+#10;
  res +=      $'      res.Append(#32, PrintlnMtrW);'+#10;
  res +=      $'      res += ''{ char($2518) }'';'+#10;
  
  res +=      $'      ' + #10;
  
  res +=      $'      Result := res.ToString;'+#10;
  res +=      $'    end;'+#10;
  
  {$endregion function ToString}
  
  {$region function Println}
  
  res += $'    '+#10;
  
  res += $'    public function Println: {t.GetName};'+#10;
  res += $'    begin'+#10;
  res += $'      Writeln(self.ToString);'+#10;
  res += $'      Result := self;'+#10;
  res += $'    end;'+#10;
  
  {$endregion function Println}
  
  {$endregion method's}
  
  {$region operator's}
  
  {$region arithmetics}
  
  res += $'    '+#10;
  
  res += $'    public static function operator*(m: {t.GetName}; v: {t.GetRowTName}): {t.GetColTName} := new {t.GetColTName}(';
  res +=
    Range(0,t[0][0]-1)
    .Select(y->
      Range(0,t[0][1]-1)
      .Select(x->
        $'m.val{y}{x}*v.val{x}'
      ).JoinToString('+')
    ).JoinToString(', ');
  res += $');'+#10;
  
  res += $'    public static function operator*(v: {t.GetColTName}; m: {t.GetName}): {t.GetRowTName} := new {t.GetRowTName}(';
  res +=
    Range(0,t[0][1]-1)
    .Select(x->
      Range(0,t[0][0]-1)
      .Select(y->
        $'m.val{y}{x}*v.val{y}'
      ).JoinToString('+')
    ).JoinToString(', ');
  res += $');'+#10;
  
  // умножение матрицы на матрицу - в расширениях
  
  {$endregion arithmetics}
  
  {$region operator implicit}
  
  foreach var t2 in prev_tps do
  begin
    res += $'    '+#10;
    
    res += $'    public static function operator implicit(m: {t2.GetName}): {t.GetName} := new {t.GetName}(';
    res +=
      Range(0,t[0][0]-1)
      .Cartesian(Range(0,t[0][1]-1))
      .Select(pos-> (pos[0]<t2[0][0]) and (pos[1]<t2[0][1]) ? $'m.val{pos[0]}{pos[1]}' : pos[0]=pos[1] ? '1.0' : '0.0' )
      .JoinToString(', ');
    res += $');'+#10;
    
    res += $'    public static function operator implicit(m: {t.GetName}): {t2.GetName} := new {t2.GetName}(';
    res +=
      Range(0,t2[0][0]-1)
      .Cartesian(Range(0,t2[0][1]-1))
      .Select(pos-> (pos[0]<t[0][0]) and (pos[1]<t[0][1]) ? $'m.val{pos[0]}{pos[1]}' : pos[0]=pos[1] ? '1.0' : '0.0' )
      .JoinToString(', ');
    res += $');'+#10;
    
  end;
  
  {$endregion operator implicit}
  
  {$endregion operator's}
  
  res += $'    '+#10;
  
  res += $'  end;'+#10;
  
  if t[0][0]=t[0][1] then
    res += $'  Mtr{t[0][0]}{t[1]} = {t.GetName};'+#10;
  
end;

begin
  try
    var res := new StringBuilder;
    
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
    
    res += #10;
    res += '  {$region Mtr}'#10;
    
    foreach var t in t_table.Numerate(0) do
      AddMtrType(res, t[1], t_table.Take(t[0]));
    
    res += '  '#10;
    res += '  {$endregion Mtr}'#10;
    res += '  ';
    
    WriteAllText(GetFullPathRTA('MtrTypes.template'), res.ToString);
  except
    on e: Exception do ErrOtp(e);
  end;
end.