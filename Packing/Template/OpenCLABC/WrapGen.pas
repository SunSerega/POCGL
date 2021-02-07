uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses Fixers       in '..\..\..\Utils\Fixers';

uses PackingUtils in '..\PackingUtils';
uses CodeGenUtils in '..\CodeGenUtils';

begin
  try
    var res := new FileWriter(GetFullPathRTA('Wrappers\Common.template'));
    loop 3 do res += '  '#10;
    
    foreach var l in ReadLines(GetFullPathRTA('Wrappers\Def.dat')) do
    begin
      var sl := l.Split(':');
      if sl.Length<2 then continue;
      
      var t := sl[0].Trim;
      var ntv_t := sl[1].Trim;
      
      
      
      res += '  ';
      res += t;
      res += ' = partial class'#10;
      
      res += '    '#10;
      
      
      
      res += '    public property Native: ';
      res += ntv_t;
      res += ' read ntv;'#10;
      
      res += '    '#10;
      
      
      
      res += '    private prop: ';
      res += t;
      res += 'Properties;'#10;
      
      res += '    private function GetProperties: ';
      res += t;
      res += 'Properties;'#10;
      
      res += '    begin'#10;
      
      res += '      if prop=nil then prop := new ';
      res += t;
      res += 'Properties(ntv);'#10;
      
      res += '      Result := prop;'#10;
      
      res += '    end;'#10;
      
      res += '    public property Properties: ';
      res += t;
      res += 'Properties read GetProperties;'#10;
      
      res += '    '#10;
      
      
      
      res += '    public static function operator=(wr1, wr2: ';
      res += t;
      res += '): boolean := wr1.ntv = wr2.ntv;'#10;
      
      res += '    public static function operator<>(wr1, wr2: ';
      res += t;
      res += '): boolean := wr1.ntv <> wr2.ntv;'#10;
      
      res += '    '#10;
      
      
      
      res += '    public function Equals(obj: object): boolean; override :='#10;
      
      res += '    (obj is ';
      res += t;
      res += '(var wr)) and (self = wr);'#10;
      
      res += '    '#10;
      
      
      
      res += '  end;'#10;
      
      res += '  '#10;
      
      
      
    end;
    
    res += '  '#10'  ';
    res.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.