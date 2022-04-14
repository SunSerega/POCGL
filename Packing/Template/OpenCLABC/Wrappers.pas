uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses Fixers       in '..\..\..\Utils\Fixers';
uses CodeGen      in '..\..\..\Utils\CodeGen';

uses PackingUtils in '..\PackingUtils';

type
  TypeDescr = sealed class
    private name: string;
    private base := default(string);
    private generics := new List<string>;
    private operator_equ := default(string);
    private to_string_def: array of string := nil;
    
    public constructor(name: string) := self.name := name;
    private constructor := raise new System.InvalidOperationException;
    
    private static All := new Dictionary<string, TypeDescr>;
    public static function ByName(name: string): TypeDescr;
    begin
      if All.TryGetValue(name, Result) then exit;
      Result := new TypeDescr(name);
      All[name] := Result;
    end;
    
  end;
  
begin
  try
    foreach var (tname, lines) in FixerUtils.ReadBlocks(GetFullPathRTA('!Def\Wrappers.dat'), true) do
    begin
      if tname=nil then continue;
      var t := TypeDescr.ByName(tname);
      
      foreach var (setting_name, setting_lines) in FixerUtils.ReadBlocks(lines, '!', false) do
        match setting_name with
          
          nil:
          if t.base<>nil then
            raise new System.InvalidOperationException else
            t.base := setting_lines.Single;
          
          'Generic':
          t.generics.AddRange(setting_lines);
          
          'operator=':
          if t.operator_equ<>nil then
            raise new System.InvalidOperationException else
            t.operator_equ := setting_lines.Single;
          
          'ToString':
          if t.to_string_def<>nil then
            raise new System.InvalidOperationException else
            t.to_string_def := setting_lines.ConvertAll(l->l.TrimStart(#9));
          
          else raise new System.InvalidOperationException($'#{tname}!{setting_name}');
        end;
      
    end;
    
    var dir := GetFullPathRTA('Wrappers');
    System.IO.Directory.CreateDirectory(dir);
    
    var res := new FileWriter(GetFullPath('Common.template', dir));
    loop 3 do res += '  '#10;
    
    foreach var t: TypeDescr in TypeDescr.All.Values do
    begin  
      var is_direct_wrap := t.base not in TypeDescr.All.Keys;
      
      var WriteGenerics := procedure->
      if t.generics.Count<>0 then
      begin
        res += '<';
        res += t.generics.JoinToString(', ');
        res += '>';
      end;
      
      {$region header}
      
      res += '  ';
      res += t.name;
      WriteGenerics;
      res += ' = partial class';
      if not is_direct_wrap then
      begin
        res += '(';
        res += t.base;
        res += ')';
      end;
      res += #10;
      
      res += '    '#10;
      
      {$endregion header}
      
      {$region Native}
      
      if is_direct_wrap then
      begin
        
        res += '    public property Native: ';
        res += t.base;
        res += ' read ntv;'#10;
        
        res += '    '#10;
      end;
      
      {$endregion Native}
      
      {$region Properties}
      
      res += '    private prop: ';
      res += t.name;
      res += 'Properties;'#10;
      
      res += '    private function GetProperties: ';
      res += t.name;
      res += 'Properties;'#10;
      
      res += '    begin'#10;
      
      res += '      if prop=nil then prop := new ';
      res += t.name;
      res += 'Properties(ntv);'#10;
      
      res += '      Result := prop;'#10;
      
      res += '    end;'#10;
      
      res += '    public property Properties: ';
      res += t.name;
      res += 'Properties read GetProperties;'#10;
      
      res += '    '#10;
      
      {$endregion Properties}
      
      {$region operator=}
      
      if is_direct_wrap then
      begin
        
        res += '    public static function operator=(wr1, wr2: ';
        res += t.name;
        WriteGenerics;
        res += '): boolean :='#10;
        res += '    if ReferenceEquals(wr1,nil) then ReferenceEquals(wr2,nil) else not ReferenceEquals(wr2,nil) and ';
        res += t.operator_equ ?? '(wr1.ntv = wr2.ntv)';
        res += ';'#10;
        
        res += '    public static function operator<>(wr1, wr2: ';
        res += t.name;
        WriteGenerics;
        //TODO #????: not (wr1=wr2)
        res += '): boolean := false='#10;
        res += '    if ReferenceEquals(wr1,nil) then ReferenceEquals(wr2,nil) else not ReferenceEquals(wr2,nil) and ';
        res += t.operator_equ ?? '(wr1.ntv = wr2.ntv)';
        res += ';'#10;
        
        res += '    '#10;
        
        res += '    public function Equals(obj: object): boolean; override :='#10;
        
        res += '    (obj is ';
        res += t.name;
        WriteGenerics;
        res += '(var wr)) and (self = wr);'#10;
        
        res += '    '#10;
      end;
      
      {$endregion operator=}
      
      {$region ToString}
      
      res += '    public procedure ToString(res: StringBuilder);'#10;
      res += '    begin'#10;
      foreach var l in t.to_string_def ?? |
        'TypeName(self, res);',
        'res += ''['';',
        'res += ntv.val.ToString;',
        'res += '']'';'
      | do
      begin
        res += '      ';
        res += l;
        res += #10;
      end;
      res += '    end;'#10;
      res += '    public function ToString: string; override;'#10;
      res += '    begin'#10;
      res += '      var res := new StringBuilder;'#10;
      res += '      self.ToString(res);'#10;
      res += '      Result := res.ToString;'#10;
      res += '    end;'#10;
      
      res += '    '#10;
      
      {$endregion ToString}
      
      res += '  end;'#10;
      
      res += '  '#10;
      
    end;
    
    res += '  '#10'  ';
    res.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.