uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses Fixers       in '..\..\..\Utils\Fixers';

uses PackingUtils in '..\PackingUtils';
uses CodeGenUtils in '..\CodeGenUtils';

begin
  try
    var res := new FileWriter(GetFullPathRTA('Wrappers\Common.template'));
    loop 3 do res += '  '#10;
    
    var prev := new HashSet<string>;
    foreach var l in ReadLines(GetFullPathRTA('Wrappers\Def.dat')) do
    begin
      var sl := l.Split(':');
      if sl.Length<2 then continue;
      
      var t := sl[0].Trim;
      var base_t := sl[1].Trim;
      
      prev.Add(t);
      var is_wrap := not prev.Contains(base_t);
      
      
      
      res += '  ';
      res += t;
      res += ' = partial class';
      if not is_wrap then
      begin
        res += '(';
        res += base_t;
        res += ')';
      end;
      res += #10;
      
      res += '    '#10;
      
      
      
      if is_wrap then
      begin
        
        res += '    public property Native: ';
        res += base_t;
        res += ' read ntv;'#10;
        
        res += '    '#10;
      end;
      
      
      
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
      
      
      
      if is_wrap then
      begin
        
        res += '    public static function operator=(wr1, wr2: ';
        res += t;
        res += '): boolean := wr1.ntv = wr2.ntv;'#10;
        
        res += '    public static function operator<>(wr1, wr2: ';
        res += t;
        res += '): boolean := wr1.ntv <> wr2.ntv;'#10;
        
        res += '    '#10;
      end;
      
      
      
      if is_wrap then
      begin
        
        res += '    public function Equals(obj: object): boolean; override :='#10;
        
        res += '    (obj is ';
        res += t;
        res += '(var wr)) and (self = wr);'#10;
        
        res += '    '#10;
      end;
      
      
      
      res += '  end;'#10;
      
      res += '  '#10;
      
      
      
    end;
    
    res += '  '#10'  ';
    res.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.