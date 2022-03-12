uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses Fixers       in '..\..\..\Utils\Fixers';
uses CodeGen      in '..\..\..\Utils\CodeGen';

uses PackingUtils in '..\PackingUtils';

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
      
      // (name, where)
      var generics := new List<(string,string)>;
      
      foreach var g_str in sl.Skip(2) do
      begin
        var ind := g_str.IndexOf('=');
        generics += (
          (if ind=-1 then g_str else g_str.Remove(ind)).Trim,
          if ind=-1 then nil else g_str.Substring(ind+1).Trim
        );
      end;
      
      prev.Add(t);
      var is_wrap := not prev.Contains(base_t);
      
      
      
      var WriteGenerics := procedure->
      if generics.Count<>0 then
      begin
        res += '<';
        res += generics.Select(g->g[0]).JoinToString(', ');
        res += '>';
      end;
      
      
      
      res += '  ';
      res += t;
      WriteGenerics;
      res += ' = partial class';
      if not is_wrap then
      begin
        res += '(';
        res += base_t;
        res += ')';
      end;
      res += #10;
      
//      foreach var g in generics do
//      begin
//        if g[1]=nil then continue;
//        res += '  where ';
//        res += g[0];
//        res += ': ';
//        res += g[1];
//        res += ';'#10
//      end;
      
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
        WriteGenerics;
        res += '): boolean :='#10;
        res += '    if ReferenceEquals(wr1,nil) then ReferenceEquals(wr2,nil) else not ReferenceEquals(wr2,nil) and (wr1.ntv = wr2.ntv);'#10;
        
        res += '    public static function operator<>(wr1, wr2: ';
        res += t;
        WriteGenerics;
        //TODO #????: not (wr1=wr2)
        res += '): boolean := false='#10;
        res += '    if ReferenceEquals(wr1,nil) then ReferenceEquals(wr2,nil) else not ReferenceEquals(wr2,nil) and (wr1.ntv = wr2.ntv);'#10;
        
        res += '    '#10;
      end;
      
      
      
      if is_wrap then
      begin
        
        res += '    public function Equals(obj: object): boolean; override :='#10;
        
        res += '    (obj is ';
        res += t;
        WriteGenerics;
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