uses PackingUtils in '..\PackingUtils';
uses POCGL_Utils  in '..\..\..\POCGL_Utils';

{$reference System.Windows.Forms.dll}

{$region Misc helpers}

function gl_to_pas_t(self: string): string; extensionmethod;
begin
  case self of
    'b':     Result := 'SByte';
    'ub':    Result :=  'Byte';
    's':     Result :=  'Int16';
    'us':    Result := 'UInt16';
    'i':     Result :=  'Int32';
    'ui':    Result := 'UInt32';
    'i64':   Result :=  'Int64';
    'ui64':  Result := 'UInt64';
    'f':     Result := 'single';
    'd':     Result := 'double';
  end;
end;

type t_descr = (
  integer,  // sz
  string,   // gl_t
  string    // pas_t
);

function GetName(self: t_descr); extensionmethod :=
$'Vec{self[0]}{self[1]}';

function GetElSize(self: t_descr): integer; extensionmethod;
begin
  case self[1] of
    'b':     Result := 1;
    'ub':    Result := 1;
    's':     Result := 2;
    'us':    Result := 2;
    'i':     Result := 4;
    'ui':    Result := 4;
    'i64':   Result := 8;
    'ui64':  Result := 8;
    'f':     Result := 4;
    'd':     Result := 8;
  end;
end;

function IsFloat(self: t_descr); extensionmethod :=
  self[1].Contains('f') or
  self[1].Contains('d')
;

{$endregion Misc helpers}

procedure AddVecType(res: StringBuilder; t: t_descr; prev_tps: sequence of t_descr);
begin
  res += $'  '+#10;
  res += $'  {t.GetName} = record'+#10;
  
  {$region field's}
  
  for var i := 0 to t[0]-1 do
    res += $'    public val{i}: {t[2]};'+#10;
  res += $'    '+#10;
  
  {$endregion field's}
  
  {$region constructor's}
  
  res += $'    public constructor(';
  res += Range(0,t[0]-1).Select(i->$'val{i}').JoinIntoString(', ');
  res += $': {t[2]});'+#10;
  
  res += $'    begin'+#10;
  
  for var i := 0 to t[0]-1 do
    res += $'      self.val{i} := val{i};'+#10;
  
  res += $'    end;'+#10;
  res += $'    '+#10;
  
  {$endregion constructor's}
  
  {$region property's}
  
  {$region property val[i]}
  
//  res +=      $'    private function GetValAt(i: integer): {t[2]};'+#10;
//  res +=      $'    begin'+#10;
//  res +=      $'      if cardinal(i) > {t[0]-1} then raise new IndexOutOfRangeException(''Индекс должен иметь значение 0..{t[0]-1}'');'+#10;
//  res +=      $'      var ptr: ^{t[2]} := pointer(new IntPtr(@self) + i*{t.GetElSize} );'+#10;
//  res +=      $'      Result := ptr^;'+#10;
//  res +=      $'    end;'+#10;
//  
//  res +=      $'    private procedure SetValAt(i: integer; val: {t[2]});'+#10;
//  res +=      $'    begin'+#10;
//  res +=      $'      if cardinal(i) > {t[0]-1} then raise new IndexOutOfRangeException(''Индекс должен иметь значение 0..{t[0]-1}'');'+#10;
//  res +=      $'      var ptr: ^{t[2]} := pointer(new IntPtr(@self) + i*{t.GetElSize} );'+#10;
//  res +=      $'      ptr^ := val;'+#10;
//  res +=      $'    end;'+#10;
//  
//  res += $'    public property val[i: integer]: {t[2]} read GetValAt write SetValAt; default;'+#10;
//  res += $'    '+#10;
  
  {$endregion property val[i]}
  
  {$endregion property's}
  
  {$region operator's}
  
  {$region arithmetics}
  
  if not t[1].Contains('u') then
  begin
    res += $'    public static function operator-(v: {t.GetName}): {t.GetName} := new {t.GetName}(';
    res += Range(0,t[0]-1).Select(i->$'-v.val{i}').JoinIntoString(', ');
    res += $');'+#10;
  end;
  
  res += $'    public static function operator+(v: {t.GetName}): {t.GetName} := v;'+#10;
  
  res += $'    public static function operator*(v: {t.GetName}; k: {t[2]}): {t.GetName} := new {t.GetName}(';
  res += Range(0,t[0]-1).Select(i->$'v.val{i}*k').JoinIntoString(', ');
  res += $');'+#10;
  
  if t.IsFloat then
  begin
    
    res += $'    public static function operator/(v: {t.GetName}; k: {t[2]}): {t.GetName} := new {t.GetName}(';
    res += Range(0,t[0]-1).Select(i->$'v.val{i}/k').JoinIntoString(', ');
    res += $');'+#10;
    
  end else
  begin
    
    res += $'    public static function operator div(v: {t.GetName}; k: {t[2]}): {t.GetName} := new {t.GetName}(';
    res += Range(0,t[0]-1).Select(i->$'v.val{i} div k').JoinIntoString(', ');
    res += $');'+#10;
    
  end;
  
  res += $'    '+#10;
  
  
  
  res += $'    public static function operator*(v1, v2: {t.GetName}): {t[2]} := (';
  res += Range(0,t[0]-1).Select(i->$' v1.val{i}*v2.val{i} ').JoinIntoString('+');
  res += $');'+#10;
  
  res += $'    public static function operator+(v1, v2: {t.GetName}): {t.GetName} := new {t.GetName}(';
  res += Range(0,t[0]-1).Select(i->$'v1.val{i}+v2.val{i}').JoinIntoString(', ');
  res += $');'+#10;
  
  res += $'    public static function operator-(v1, v2: {t.GetName}): {t.GetName} := new {t.GetName}(';
  res += Range(0,t[0]-1).Select(i->$'v1.val{i}-v2.val{i}').JoinIntoString(', ');
  res += $');'+#10;
  
  res += $'    '+#10;
  
  {$endregion arithmetics}
  
  {$region operator implicit}
  
  var get_val_str: integer->string := i->$'v.val{i}';
  var get_conv_val_str_templ: (integer,t_descr)->string := (i,t2)->$'Convert.To{t2[2]}(v.val{i})';
  
  foreach var t2 in prev_tps do
  begin
    var get_conv_val_str:   integer->string := i->get_conv_val_str_templ(i,t);
    var get_conv2_val_str:  integer->string := i->get_conv_val_str_templ(i,t2);
    
    res += $'    public static function operator implicit(v: {t2.GetName}): {t.GetName} := new {t.GetName}(';
    res += Range(0,t[0]-1).Select(
      t2.IsFloat and not t.IsFloat?
        get_conv_val_str:
        get_val_str
    ).Select((s,i)->
      i<t2[0]?
      s:'0'
    ).JoinIntoString(', ');
    res += $');'+#10;
    
    res += $'    public static function operator implicit(v: {t.GetName}): {t2.GetName} := new {t2.GetName}(';
    res += Range(0,t2[0]-1).Select(
      t.IsFloat and not t2.IsFloat?
        get_conv2_val_str:
        get_val_str
    ).Select((s,i)->
      i<t[0]?
      s:'0'
    ).JoinIntoString(', ');
    res += $');'+#10;
    
    res += $'    '+#10;
  end;
  
  {$endregion operator implicit}
  
  {$endregion operator's}
  
  {$region method's}
  
  {$region function SqrLength}
  
  res += '    public function SqrLength := ';
  res +=
    Range(0,t[0]-1)
    .Select(i->$'val{i}*val{i}')
    .JoinIntoString(' + ');
  res += ';'#10;
  res += '    '#10;
  
  {$endregion function SqrLength}
  
  {$region function Normalized}
  
  if t.IsFloat then
  begin
    
    res +=    $'    public function Normalized := ';
    if t[1] = 'f' then
      res +=  $'self / single(Sqrt(self.SqrLength));'+#10 else
      res +=  $'self / self.SqrLength.Sqrt;'+#10;
    res +=    $'    '+#10;
    
  end;
  
  {$endregion function Normalized}
  
  {$region static function Cross}
  
  if (t[0] = 3) and not t[1].Contains('u') then
  begin
    res += $'    public static function CrossCW(v1,v2: {t.GetName}) :='+#10;
    res += $'    new {t.GetName}(';
    
    res +=
      Range(0,2)
      .Select(i->$'v1.val{(i+1) mod 3}*v2.val{(i+2) mod 3} - v2.val{(i+1) mod 3}*v1.val{(i+2) mod 3}')
      .JoinIntoString(', ')
    ;
    
    res += ');'#10;
    res += $'    public static function CrossCCW(v1,v2: {t.GetName}) := CrossCW(v2,v1);'+#10;
    
    res += '    '#10;
  end;
  
  {$endregion static function Cross}
  
  {$region static function Random}
  
  res += '    public static function Random(min, max: ';
  res += t[2];
  res += '): ';
  res += t.GetName;
  res += ';'#10;
  res += '    begin'#10;
  res += '      if min>max then Swap(min,max);'#10;
  res += '      var r := max-min;'#10;
  for var i := 0 to t[0]-1 do
  begin
    res += '      Result.val';
    res += i.ToString;
    res += ' := ';
    res += 'min + PABCSystem.Random(r);';
    res += #10;
  end;
  res += '    end;'#10;
  res += '    '#10;
  
  {$endregion static function Random}
  
  {$region static function Read}
  
  foreach var ln in |'', 'ln'| do
  begin
    res +=  $'    public static function Read{ln}(prompt: string := nil): {t.GetName};'+#10;
    res +=  $'    begin'+#10;
    res +=  $'      if prompt <> nil then prompt.Print;'+#10;
    res +=  $'      PABCSystem.Read{ln}(';
    res += Range(0, t[0]-1).Select(i->$'Result.val{i}').JoinToString(', ');
    res += ');'#10;
    res +=  $'    end;'+#10;
  end;
  res +=    $'    '+#10;
  
  {$endregion static function Read}
  
  {$region function ToString}
  
  res += $'    public function ToString: string; override;'+#10;
  res += $'    begin'+#10;
  res += $'      var res := new StringBuilder;'+#10;
  res += $'      res += ''[ '';'+#10;
  
  res +=
    Range(0,t[0]-1)
    .Select(i->$'      res += val{i}.ToString(''f2'');'+#10)
    .JoinIntoString($'      res += '', '';'+#10);
  
  res += $'      res += '' ]'';'+#10;
  res += $'      Result := res.ToString;'+#10;
  res += $'    end;'+#10;
  res += $'    '+#10;
  
  {$endregion function ToString}
  
  {$region function Println}
  
  res += $'    public function Println: {t.GetName};'+#10;
  res += $'    begin'+#10;
  res += $'      Writeln(self.ToString);'+#10;
  res += $'      Result := self;'+#10;
  res += $'    end;'+#10;
  res += $'    '+#10;
  
  {$endregion function Println}
  
  {$endregion method's}
  
  res += $'  end;'+#10;
  
  if t.IsFloat then
  begin
    res += $'  Use{t.GetName}PtrCallbackP = procedure(var ptr: {t.GetName});'+#10;
    res += $'  Use{t.GetName}PtrCallbackF<T> = function(var ptr: {t.GetName}): T;'+#10;
  end;
  
end;

begin
  try
    var res := new StringBuilder;
    
    res += #10;
    res += '  {$region Vec}'#10;
    res += '  '#10;
    res += '  {$region Vec1}'#10;
    
    var t_table :=
      Range(1,4)
      .SelectMany(sz->Arr&<string>(
        'b',    'ub',
        's',    'us',
        'i',    'ui',
        'i64',  'ui64',
        'f',    'd'
      ).Select(t->(sz,t,t.gl_to_pas_t)))
      .ToArray;
    
    var last_t: t_descr;
    foreach var t in t_table.Numerate(0) do
    begin
      if last_t<>nil then
        if last_t[0]<t[1][0] then
        begin
          res += '  '#10;
          res += '  {$endregion Vec' + last_t[0] + '}'#10;
          res += '  '#10;
          res += '  {$region Vec' + t[1][0] + '}'#10;
        end;
      
      AddVecType(res, t[1], t_table.Take(t[0]));
      
      last_t := t[1];
    end;
    
    res += '  '#10;
    res += '  {$endregion Vec4}'#10;
    res += '  '#10;
    res += '  {$endregion Vec}'#10;
    res += '  ';
    
    WriteAllText(GetFullPathRTA('VecTypes.template'), res.ToString);
  except
    on e: Exception do ErrOtp(e);
  end;
end.