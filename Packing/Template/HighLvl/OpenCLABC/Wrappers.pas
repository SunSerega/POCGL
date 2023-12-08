uses '../../../../POCGL_Utils';
uses '../../../../Utils/Fixers';
uses '../../../../Utils/CodeGen';

uses '../../Common/PackingUtils';

type
  TypeDescr = sealed class
    private name: string;
    private base := default(string);
    private interfaces := new List<string>;
    private generics := new List<string>;
    private need_native := true;
    private operator_equ := default(string);
    private to_string_def := default(string);
    private get_hash_code_def := default(string);
    private need_prop := true;
    private is_abstract := false;
    
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
    foreach var (tname, lines) in FixerUtils.ReadBlocks(GetFullPathRTA('!Def/Wrappers.dat'), true) do
    begin
      if tname=nil then continue;
      var t := TypeDescr.ByName(tname);
      
      foreach var (setting_name, setting_lines) in FixerUtils.ReadBlocks(lines, '!', false) do
        match setting_name with
          
          nil:
            if t.base<>nil then
              raise new System.InvalidOperationException else
              t.base := setting_lines.Single;
          
          'Interfaces':
            t.interfaces.AddRange(setting_lines);
          
          'Generic':
            t.generics.AddRange(setting_lines);
          
          'NoNative':
            t.need_native := false;
          
          'operator=':
            if t.operator_equ<>nil then
              raise new System.InvalidOperationException else
              t.operator_equ := setting_lines.Single;
          
          'ToString':
            if t.to_string_def<>nil then
              raise new System.InvalidOperationException else
              t.to_string_def := setting_lines.Single;
          
          'GetHashCode':
            if t.get_hash_code_def<>nil then
              raise new System.InvalidOperationException else
              t.get_hash_code_def := setting_lines.Single;
          
          'NoProp':
            t.need_prop := false;
          
          'Abstract':
            t.is_abstract := true;
          
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
      res += ' = ';
      if t.is_abstract then
        res += 'abstract ';
      res += 'partial class';
      if t.interfaces.Any or not is_direct_wrap then
      begin
        res += '(';
        var first_base := true;
        if not is_direct_wrap then
        begin
          res += t.base;
          first_base := false;
        end;
        foreach var intr in t.interfaces do
        begin
          if not first_base then
            res += ', ';
          first_base := false;
          res += intr;
        end;
        res += ')';
      end;
      res += #10;
      
      res += '    '#10;
      
      {$endregion header}
      
      {$region Native}
      
      if is_direct_wrap and t.need_native then
      begin
        
        res += '    public property Native: ';
        res += t.base;
        res += ' read ntv;'#10;
        
        res += '    '#10;
      end;
      
      {$endregion Native}
      
      {$region Properties}
      
      if t.need_native and t.need_prop then
      begin
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
      end;
      
      {$endregion Properties}
      
      {$region operator=}
      
      if is_direct_wrap then
      begin
        
        res += '    public static function operator=(wr1, wr2: ';
        res += t.name;
        WriteGenerics;
        res += '): boolean :='#10;
        res += '    ReferenceEquals(wr1,wr2) or not ReferenceEquals(wr1,nil) and not ReferenceEquals(wr2,nil) and ';
        res += t.operator_equ ?? '(wr1.ntv = wr2.ntv)';
        res += ';'#10;
        
        res += '    public static function operator<>(wr1, wr2: ';
        res += t.name;
        WriteGenerics;
        //TODO #????: not (wr1=wr2)
        res += '): boolean := false='#10;
        res += '    ReferenceEquals(wr1,wr2) or not ReferenceEquals(wr1,nil) and not ReferenceEquals(wr2,nil) and ';
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
      
      {$region GetHashCode}
      
      if is_direct_wrap or (t.get_hash_code_def<>nil) then
      begin
        res += '    public function GetHashCode: integer; override :='#10;
        res += '    ';
        res += t.get_hash_code_def ?? 'ntv.val.GetHashCode';
        res += ';'#10;
        
        res += '    '#10;
      end;
      
      {$endregion GetHashCode}
      
      {$region ToString}
      
      if is_direct_wrap or (t.to_string_def<>nil) then
      begin
        res += '    public function ToString: string; override :='#10;
        res += '    $''';
        res += t.to_string_def ?? '{TypeName(self)}[{ntv.val}]';
        res += ''';'#10;
        
        res += '    '#10;
      end;
      
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