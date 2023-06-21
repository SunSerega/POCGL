uses System;

uses '..\..\..\..\POCGL_Utils';
uses '..\..\..\..\Utils\AOtp';
uses '..\..\..\..\Utils\Fixers';
uses '..\..\..\..\Utils\CodeGen';

uses '..\..\Common\PackingUtils';

var log := new FileLogger('WrapperProperties.log');

type
  ETTFunc = sealed class
    private name: string;
    private ett: Dictionary<string, string>;
    private used := false;
    
    public static ByName := new Dictionary<string, ETTFunc>;
    private static All := new List<ETTFunc>;
    
    public constructor(name: string; ett: Dictionary<string, string>);
    begin
      self.name := name;
      self.ett := ett;
      
      ByName.Add(name, self);
      All += self;
      
    end;
    private constructor := raise new InvalidOperationException;
    
    public static procedure InitAll;
    begin
      var ett_log_fname := GetFullPathRTA('..\..\LowLvl\OpenCL\Log\All EnumToTypeBinding''s.log');
      foreach var (func_name, lines1) in FixerUtils.ReadBlocks(ett_log_fname, nil) do
      begin
        var ett := new Dictionary<string, string>;
        
        foreach var (enum_name, lines2) in FixerUtils.ReadBlocks(lines1, '---', nil) index func_data_ind do
        begin
          if func_data_ind=0 then
          {$region ett info}
          begin
            if (enum_name<>nil) then
              raise new System.InvalidOperationException;
            
            var has_inp := false;
            var has_otp := false;
            foreach var (ett_dir, lines3) in FixerUtils.ReadBlocks(lines2, '!', nil) do
            begin
              foreach var l in lines3 do
                if not l.IsInteger then
                  raise new InvalidOperationException;
              match ett_dir with
                
                nil: lines3.Single; // gr_par_ind
                
                'input':
                begin
                  has_inp := true;
                  if lines3.Length<>2 then
                    raise new InvalidOperationException;
                end;
                
                'output':
                begin
                  has_otp := true;
                  if lines3.Length<>3 then
                    raise new InvalidOperationException;
                end;
                
                else raise new NotImplementedException;
              end;
            end;
            
            if has_inp then break;
            if not has_otp then
              raise new InvalidOperationException;
            continue;
          end
          {$endregion ett info};
          
          foreach var (ett_dir, lines3) in FixerUtils.ReadBlocks(lines2, '!', nil) do
          begin
            if ett_dir<>'output' then
              raise new InvalidOperationException;
            ett.Add(enum_name, lines3.Single.RegexReplace('array\[\d+\]', 'array'));
          end;
          
        end;
        
        if ett.Count=0 then
          log.Otp($'Func [{func_name}] was skipped when loading') else
          new ETTFunc(func_name, ett);
        
      end;
    end;
    
    public static procedure ReportUnused :=
      foreach var f in All do
      begin
        if f.used then continue;
        log.Otp($'Func [{f.name}] was not used');
      end;
    
  end;
  
  EnumName = record
    private short_name, escaped_name, full_name: string;
    
    public constructor(name, prefix: string);
    begin
      self.short_name := name
        .TrimStart('!')
        .Split('_')
        .Select(w->w.First+w.SubString(1).ToLower)
        .JoinToString('');
      
      self.escaped_name := short_name;
      if escaped_name in pas_keywords then
        self.escaped_name := '&'+escaped_name;
      
      if name.StartsWith('!') then
        name := name.Substring(1) else
        name := prefix+name;
      self.full_name := name;
      
    end;
    public constructor := raise new InvalidOperationException;
    
  end;
  
  WrapPropType = sealed class
    private name, ntv_t, info_t: string;
    private f: ETTFunc;
    private base: WrapPropType;
    private writeable_enums: array of EnumName;
    private all_enums: Dictionary<EnumName, boolean>;
    
    private static ByName := new Dictionary<string, WrapPropType>;
    public static All := new List<WrapPropType>;
    
    public constructor(name, ntv_t, info_t: string; f: ETTFunc; base: WrapPropType; writeable_enums: array of EnumName; all_enums: Dictionary<EnumName, boolean>);
    begin
      self.name := name;
      self.ntv_t := ntv_t;
      self.info_t := info_t;
      self.f := f;
      self.base := base;
      self.writeable_enums := writeable_enums;
      self.all_enums := all_enums;
      
      ByName.Add(name, self);
      All += self;
      
      var expected_enum_names := f.ett.Keys.ToHashSet;
      var count_disabled := true;
      var wpt := self;
      while wpt<>nil do
      begin
        
        foreach var enum_name in wpt.all_enums.Keys do
        begin
          if not count_disabled and not wpt.all_enums[enum_name] then continue;
          if expected_enum_names.Remove(enum_name.full_name) then continue;
          if enum_name.full_name in f.ett then
            Otp($'WARNING: {name} double added {enum_name.full_name}') else
            Otp($'ERROR: {name} added {enum_name.full_name}, but it was not defined in ett');
        end;
        
        count_disabled := false;
        wpt := wpt.base;
      end;
      
      foreach var enum_name in expected_enum_names do
        Otp($'WARNING: {name} did not add {enum_name}');
      
    end;
    private constructor := raise new InvalidOperationException;
    
    public static procedure InitAll :=
      foreach var fname in EnumerateFiles(GetFullPathRTA('!Def\WrapperProperties'), '*.dat') do
      begin
        var name := System.IO.Path.GetFileNameWithoutExtension(fname);
        if '#' in name then name := name.Remove(0, name.IndexOf('#')+1);
        
        var ntv_t := default(string);
        var info_t := default(string);
        var f := default(ETTFunc);
        var base := default(WrapPropType);
        var all_enums := new Dictionary<EnumName, boolean>;
        
        var enum_prefix := default(string);
        
        foreach var (enum_name, lines) in FixerUtils.ReadBlocks(fname, true) index enum_i do
        begin
          
          if enum_i=0 then
          {$region Header}
          begin
            
            foreach var (header_kind, header_lines) in FixerUtils.ReadBlocks(lines, '!', nil) do
              match header_kind with
                
                nil:
                begin
                  if header_lines.Length<>3 then
                    raise new InvalidOperationException;
                  
                  var func_name: string;
                  (ntv_t, info_t, func_name) := header_lines;
                  
                  enum_prefix := info_t.Matches('cl(.*)Info').Single.Groups[1].Value.ToUpper+'_';
                  
                  f := ETTFunc.ByName[func_name];
                  f.used := true;
                end;
                
                'Base':
                begin
                  var base_name := header_lines.Single;
                  if base_name not in ByName then
                    raise new InvalidOperationException($'{name} => {base_name}');
                  base := ByName[base_name];
                end;
                
                else raise new NotImplementedException(header_kind);
              end;
            
            continue;
          end
          {$endregion Header};
          
          if f=nil then
            raise new InvalidOperationException;
          
          var need_write: boolean;
          case lines.Single of
            'Flat': need_write := true;
            'Disable': need_write := false;
            else raise new NotImplementedException;
          end;
          
          all_enums.Add(new EnumName(enum_name, enum_prefix), need_write);
        end;
        
        new WrapPropType(name, ntv_t, info_t, f, base, all_enums.Keys.Where(e->all_enums[e]).ToArray, all_enums);
      end;
    
  end;
  
begin
  try
    var dir := GetFullPathRTA('WrapperProperties');
    System.IO.Directory.CreateDirectory(dir);
    
    ETTFunc.InitAll;
//    foreach var f in ETTFunc.All do
//    begin
//      Otp('');
//      Otp($'{f.name}:');
//      foreach var kvp in f.ett do
//        Otp($'{kvp.Key} => {kvp.Value}');
//    end;
//    Halt;
    
    WrapPropType.InitAll;
    ETTFunc.ReportUnused;
    
    var wr := new FileWriter(GetFullPathRTA('WrapperProperties.template'));
    loop 3 do wr += '  '#10;
    
    foreach var wpt in WrapPropType.All do
    begin
      
      wr += '  ';
      wr += '{$region ';
      wr += wpt.name;
      wr += '}'#10;
      
      wr += '  ';
      wr += #10;
      
      if (wpt.base<>nil) and not wpt.writeable_enums.Any then
      begin
        
        wr += '  ///'#10;
        wr += '  ';
        wr += wpt.name;
        wr += 'Properties = ';
        wr += wpt.base.name;
        wr += 'Properties;'#10;
        
      end else
      begin
        
        {$region type}
        
        wr += '  ///'#10;
        wr += '  ';
        wr += wpt.name;
        wr += 'Properties = class';
        if wpt.base<>nil then
        begin
          wr += '(';
          wr += wpt.base.name;
          wr += 'Properties)';
        end;
        wr += #10;
        
        if wpt.base=nil then
        begin
          
          wr += '    private ntv: ';
          wr += wpt.ntv_t;
          wr += ';'#10;
          
          wr += '    '#10;
          
          wr += '    public constructor(ntv: ';
          wr += wpt.ntv_t;
          wr += ') := self.ntv := ntv;'#10;
          wr += '    private constructor := raise new OpenCLABCInternalException;'#10;
          
        end;
        
        wr += '    '#10;
        
        if wpt.writeable_enums.Any then
        begin
          var ett := wpt.writeable_enums.ToDictionary(e->e, e->
          begin
            Result := wpt.f.ett[e.full_name];
            if WrapPropType.All.Select(w->w.name+'Properties').Contains(Result, StringComparer.OrdinalIgnoreCase) then
              Result := 'OpenCL.'+Result;
          end);
          
          var max_name_len := ett.Keys.Max(e->e.short_name.Length);
          var max_esc_name_len := ett.Keys.Max(e->e.escaped_name.Length);
          var max_type_len := ett.Values.Max(t->t.Length);
          
          {$region function Get}
          
          foreach var enum_name in wpt.writeable_enums do
          begin
            
            wr += '    private function Get';
            wr += enum_name.short_name;
            wr += ': ';
            wr += ett[enum_name];
            wr += ';'#10;
            wr += '    begin'#10;
            
            wr += '      ';
            wr += wpt.f.name;
            wr += '_';
            wr += enum_name.full_name;
            wr += '(self.ntv, Result).RaiseIfError;'#10;
            
            wr += '    end;'#10;
            
          end;
          wr += '    '#10;
          
          {$endregion function Get}
          
          {$region property}
          
          foreach var enum_name in wpt.writeable_enums do
          begin
            
            wr += '    public property ';
            wr += enum_name.escaped_name;
            wr += ': ';
            loop max_esc_name_len-enum_name.escaped_name.Length do
              wr += ' ';
            wr += ett[enum_name];
            loop max_type_len-ett[enum_name].Length do
              wr += ' ';
            wr += ' read Get';
            wr += enum_name.short_name;
            wr += ';'#10;
            
          end;
          wr += '    '#10;
          
          {$endregion property}
          
          {$region ToString}
          
          if wpt.base=nil then
          begin
            wr += '    private static procedure AddProp(res: StringBuilder; v: object) :='#10;
            wr += '      try'#10;
            //TODO Использовать второй параметр _ObjectToString
            wr += '        res += _ObjectToString(v);'#10;
            wr += '      except'#10;
            wr += '        on e: OpenCLException do'#10;
            wr += '          res += e.Code.ToString;'#10;
            wr += '      end;'#10;
          end;
          
          wr += '    public procedure ToString(res: StringBuilder); ';
          wr += if wpt.base<>nil then 'override' else 'virtual';
          wr += ';'#10;
          wr += '    begin'#10;
          if wpt.base<>nil then
            wr += '      inherited; res += #10;'#10;
          wr.WriteSeparated(wpt.writeable_enums,
            (wr, enum_name)->
            begin
              wr += '      res += ''';
              wr += enum_name.short_name;
              loop max_name_len-enum_name.short_name.Length do
                wr += ' ';
              wr += ' = ''; AddProp(res, ';
              wr += enum_name.escaped_name;
              loop max_esc_name_len-enum_name.escaped_name.Length do
                wr += ' ';
              wr += ');';
            end, ' res += #10;'#10
          );
          wr += #10;
          wr += '    end;'#10;
          
          if wpt.base=nil then
          begin
            wr += '    public function ToString: string; override;'#10;
            wr += '    begin'#10;
            wr += '      var res := new StringBuilder;'#10;
            wr += '      ToString(res);'#10;
            wr += '      Result := res.ToString;'#10;
            wr += '    end;'#10;
          end;
          
          wr += '    '#10;
          
          {$endregion ToString}
          
        end;
        
        wr += '  end;'#10;
        
        {$endregion type}
        
      end;
      
      wr += '  '#10;
      
      wr += '  ';
      wr += '{$endregion ';
      wr += wpt.name;
      wr += '}'#10;
      
      wr += '  ';
      wr += #10;
      
    end;
    
    wr += '  '#10'  ';
    wr.Close;
    
    log.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.