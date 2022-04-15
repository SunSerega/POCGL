uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses Fixers       in '..\..\..\Utils\Fixers';
uses CodeGen      in '..\..\..\Utils\CodeGen';

uses PackingUtils in '..\PackingUtils';

function FixWord(w: string): string;
begin
  w := w.ToLower;
  w[1] := w[1].ToUpper;
  Result := w;
end;

type
  Prop = sealed class
    t, base_name, name, escaped_name: string;
    special_args := new List<string>;
    
    constructor(header: string; data: sequence of string);
    begin
      var wds := header.ToWords(':');
      base_name := wds[0].Trim;
      t := wds[1].Trim;
      
      name := base_name.TrimStart('!').ToWords('_').Select(FixWord).JoinToString('');
      escaped_name := if name.ToLower in pas_keywords then '&'+name else name;
      
      special_args.AddRange(data);
      
    end;
    
  end;
  
begin
  try
    var dir := GetFullPathRTA('WrapperProperties');
    System.IO.Directory.CreateDirectory(dir);
    
    var res_In := new FileWriter(GetFullPath(     'Interface.template', dir));
    var res_Im := new FileWriter(GetFullPath('Implementation.template', dir));
    var res := res_In * res_Im;
    
    loop 3 do
    begin
      res_In += '  ';
      res += #10;
    end;
    
    foreach var fname in EnumerateFiles(GetFullPathRTA('!Def\WrapperProperties'), '*.dat') do
    begin
      var t := System.IO.Path.GetFileNameWithoutExtension(fname);
      if t.Contains('#') then t := t.Remove(0, t.IndexOf('#')+1);
      
      var ntv_t: string := nil;
      var info_t: string := nil;
      var ntv_proc_name: string := nil;
      var ps := new List<Prop>;
      
      var base_t: string := nil;
      
      foreach var (bl_name, bl_data) in FixerUtils.ReadBlocks(fname, false) do
        if bl_name<>nil then
          ps += new Prop(bl_name, bl_data) else
          foreach var (setting_name, setting_data) in FixerUtils.ReadBlocks(bl_data, '!', false) do
            match setting_name with
              nil: (ntv_t, info_t, ntv_proc_name) := setting_data;
              
              'Base': base_t := setting_data.Single;
              
              else raise new System.InvalidOperationException(setting_name);
            end;
      
      var max_type_len := ps.Select(p->p.t.Length).DefaultIfEmpty(0).Max;
      var max_name_len := ps.Select(p->p.name.Length).DefaultIfEmpty(0).Max;
      var max_esc_name_len := ps.Select(p->p.escaped_name.Length).DefaultIfEmpty(0).Max;
      
      
      
      res_In += '  ';
      res += '{$region ';
      res += t;
      res += '}'#10;
      
      res_In += '  ';
      res += #10;
      
      
      
      res_Im += 'type'#10;
      res += '  ';
      res += t;
      res += 'Properties = partial class';
      if base_t=nil then
      begin
        res_Im += '(NtvPropertiesBase<';
        res_Im += ntv_t;
        res_Im += ', ';
        res_Im += info_t;
        res_Im += '>)';
      end else
      begin
        res += '(';
        res += base_t;
        res += 'Properties)';
      end;
      res += #10;
      
      res += '    '#10;
      
      
      
      res_In += '    public constructor(ntv: ';
      res_In += ntv_t;
      res_In += ');'#10;
      res_In += '    private constructor := raise new System.InvalidOperationException($''%Err:NoParamCtor%'');'#10;
      
      res_In += '    '#10;
      
      
      
      if ps.Any then
      begin
        
        foreach var p in ps do
        begin
          
          res_In += '    private function Get';
          res_In += p.name;
          res_In += ': ';
          res_In += p.t;
          res_In += ';'#10;
          
        end;
        res_In += '    '#10;
        
        foreach var p in ps do
        begin
          
          res_In += '    public property ';
          res_In += p.escaped_name;
          res_In += ': ';
          res_In += ' '*(max_esc_name_len-p.escaped_name.Length);
          res_In += p.t.PadRight(max_type_len);
          res_In += ' read Get';
          res_In += p.name;
          res_In += ';'#10;
          
        end;
        res_In += '    '#10;
        
        begin
          res_In += '    public procedure ToString(res: StringBuilder);';
          res_In += if base_t<>nil then ' override;' else ' virtual;';
          res_In += #10;
          res_In += '    begin'#10;
          var max_p_w := ps.Max(p->p.name.Length);
          var any_p := false;
          if base_t<>nil then
          begin
            res_In += '      inherited;'#10;
            any_p := true;
          end;
          foreach var p in ps do
          begin
            if any_p then
              res_In += '      res += #10;'#10 else
              any_p := true;
            res_In += '      res += ''';
            res_In += p.name.PadRight(max_p_w+1);
            res_In += '= '';'#10;
            res_In += '      try'#10;
            //TODO Использовать второй параметр _ObjectToString
            res_In += '        res += _ObjectToString(';
            res_In += p.escaped_name;
            res_In += ');'#10;
            res_In += '      except'#10;
            res_In += '        on e: OpenCLException do'#10;
            res_In += '          res += e.Code.ToString;'#10;
            res_In += '      end;'#10;
          end;
          res_In += '    end;'#10;
        end;
        
        if base_t=nil then
        begin
          res_In += '    public function ToString: string; override;'#10;
          res_In += '    begin'#10;
          res_In += '      var res := new StringBuilder;'#10;
          res_In += '      ToString(res);'#10;
          res_In += '      Result := res.ToString;'#10;
          res_In += '    end;'#10;
        end;
        res_In += '    '#10;
        
      end;
      
      
      res_Im += '    private static function clGetSize(ntv: ';
      res_Im += ntv_t;
      res_Im += '; param_name: ';
      res_Im += info_t;
      res_Im += '; param_value_size: UIntPtr; param_value: IntPtr; var param_value_size_ret: UIntPtr): ErrorCode;'#10;
      
      res_Im += '    external ''opencl.dll'' name ''';
      res_Im += ntv_proc_name;
      res_Im += ''';'#10;
      
      res_Im += '    private static function clGetVal(ntv: ';
      res_Im += ntv_t;
      res_Im += '; param_name: ';
      res_Im += info_t;
      res_Im += '; param_value_size: UIntPtr; var param_value: byte; param_value_size_ret: IntPtr): ErrorCode;'#10;
      
      res_Im += '    external ''opencl.dll'' name ''';
      res_Im += ntv_proc_name;
      res_Im += ''';'#10;
      
      res_Im += '    '#10;
      
      
      
      res_Im += '    protected procedure GetSizeImpl(id: ';
      res_Im += info_t;
      res_Im += '; var sz: UIntPtr); override :='#10;
      
      res_Im += '    clGetSize(ntv, id, UIntPtr.Zero, IntPtr.Zero, sz).RaiseIfError;'#10;
      
      res_Im += '    protected procedure GetValImpl(id: ';
      res_Im += info_t;
      res_Im += '; sz: UIntPtr; var res: byte); override :='#10;
      
      res_Im += '    clGetVal(ntv, id, sz, res, IntPtr.Zero).RaiseIfError;'#10;
      
      res_Im += '    '#10;
      
      
      
      res += '  end;'#10;
      
      res += '  '#10;
      
      
      
      res_Im += 'constructor ';
      res_Im += t;
      res_Im += 'Properties.Create(ntv: ';
      res_Im += ntv_t;
      res_Im += ') := inherited Create(ntv);'#10;
      
      res_Im += #10;
      
      
      
      foreach var p in ps do
      begin
        
        res_Im += 'function ';
        res_Im += t;
        res_Im += 'Properties.Get';
        res_Im += p.name.PadRight(max_name_len);
        res_Im += ' := ';
        if p.t = 'String' then
          res_Im += 'GetString' else
        begin
          var arr_c := 0;
          while p.t.StartsWith('array of ' * (arr_c+1)) do arr_c += 1;
          res_Im += 'GetVal';
          loop arr_c do
            res_Im += 'Arr';
          res_Im += '&<';
          res_Im += p.t.Substring('array of '.Length * arr_c);
          res_Im += '>';
        end;
        res_Im += '(';
        res_Im += info_t;
        res_Im += '.';
        if not p.base_name.StartsWith('!') then
        begin
          res_Im += info_t.Remove(info_t.Length-'Info'.Length).ToUpper;
          res_Im += '_';
        end;
        res_Im += p.base_name.TrimStart('!');
        foreach var arg in p.special_args do
        begin
          res_Im += ', ';
          res_Im += arg;
        end;
        res_Im += ');'#10;
        
      end;
      
      res_Im += #10;
      
      
      
      res_In += '  ';
      res += '{$endregion ';
      res += t;
      res += '}'#10;
      
      res_In += '  ';
      res += #10;
      
    end;
    
    loop 1 do
    begin
      res_In += '  ';
      res += #10;
    end;
    res_In += '  ';
    
    res.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.