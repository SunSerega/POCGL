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
    
    var n := new FileWriter(GetFullPath(     'Interface.template', dir));
    var m := new FileWriter(GetFullPath('Implementation.template', dir));
    var all := n * m;
    
    loop 3 do
    begin
      n += '  ';
      all += #10;
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
      
      
      
      n += '  ';
      all += '{$region ';
      all += t;
      all += '}'#10;
      
      n += '  ';
      all += #10;
      
      
      
      m += 'type'#10;
      n += '  ///'#10;
      all += '  ';
      all += t;
      all += 'Properties = partial class';
      if base_t=nil then
      begin
        m += '(NtvPropertiesBase<';
        m += ntv_t;
        m += ', ';
        m += info_t;
        m += '>)';
      end else
      begin
        all += '(';
        all += base_t;
        all += 'Properties)';
      end;
      all += #10;
      
      all += '    '#10;
      
      
      
      n += '    public constructor(ntv: ';
      n += ntv_t;
      n += ');'#10;
      n += '    private constructor := raise new System.InvalidOperationException($''%Err:NoParamCtor%'');'#10;
      
      n += '    '#10;
      
      
      
      if ps.Any then
      begin
        
        foreach var p in ps do
        begin
          
          n += '    private function Get';
          n += p.name;
          n += ': ';
          n += p.t;
          n += ';'#10;
          
        end;
        n += '    '#10;
        
        foreach var p in ps do
        begin
          
          n += '    public property ';
          n += p.escaped_name;
          n += ': ';
          n += ' '*(max_esc_name_len-p.escaped_name.Length);
          n += p.t.PadRight(max_type_len);
          n += ' read Get';
          n += p.name;
          n += ';'#10;
          
        end;
        n += '    '#10;
        
        begin
          n += '    public procedure ToString(res: StringBuilder);';
          n += if base_t<>nil then ' override;' else ' virtual;';
          n += #10;
          n += '    begin'#10;
          var max_p_w := ps.Max(p->p.name.Length);
          var any_p := false;
          if base_t<>nil then
          begin
            n += '      inherited;'#10;
            any_p := true;
          end;
          foreach var p in ps do
          begin
            if any_p then
              n += '      res += #10;'#10 else
              any_p := true;
            n += '      res += ''';
            n += p.name.PadRight(max_p_w+1);
            n += '= '';'#10;
            n += '      try'#10;
            //TODO Использовать второй параметр _ObjectToString
            n += '        res += _ObjectToString(';
            n += p.escaped_name;
            n += ');'#10;
            n += '      except'#10;
            n += '        on e: OpenCLException do'#10;
            n += '          res += e.Code.ToString;'#10;
            n += '      end;'#10;
          end;
          n += '    end;'#10;
        end;
        
        if base_t=nil then
        begin
          n += '    public function ToString: string; override;'#10;
          n += '    begin'#10;
          n += '      var res := new StringBuilder;'#10;
          n += '      ToString(res);'#10;
          n += '      Result := res.ToString;'#10;
          n += '    end;'#10;
        end;
        n += '    '#10;
        
      end;
      
      
      m += '    private static function clGetSize(ntv: ';
      m += ntv_t;
      m += '; param_name: ';
      m += info_t;
      m += '; param_value_size: UIntPtr; param_value: IntPtr; var param_value_size_ret: UIntPtr): ErrorCode;'#10;
      
      m += '    external ''OpenCL'' name ''';
      m += ntv_proc_name;
      m += ''';'#10;
      
      m += '    private static function clGetVal(ntv: ';
      m += ntv_t;
      m += '; param_name: ';
      m += info_t;
      m += '; param_value_size: UIntPtr; var param_value: byte; param_value_size_ret: IntPtr): ErrorCode;'#10;
      
      m += '    external ''OpenCL'' name ''';
      m += ntv_proc_name;
      m += ''';'#10;
      
      m += '    '#10;
      
      
      
      m += '    protected procedure GetSizeImpl(id: ';
      m += info_t;
      m += '; var sz: UIntPtr); override :='#10;
      
      m += '    clGetSize(ntv, id, UIntPtr.Zero, IntPtr.Zero, sz).RaiseIfError;'#10;
      
      m += '    protected procedure GetValImpl(id: ';
      m += info_t;
      m += '; sz: UIntPtr; var res: byte); override :='#10;
      
      m += '    clGetVal(ntv, id, sz, res, IntPtr.Zero).RaiseIfError;'#10;
      
      m += '    '#10;
      
      
      
      all += '  end;'#10;
      
      all += '  '#10;
      
      
      
      m += 'constructor ';
      m += t;
      m += 'Properties.Create(ntv: ';
      m += ntv_t;
      m += ') := inherited Create(ntv);'#10;
      
      m += #10;
      
      
      
      foreach var p in ps do
      begin
        
        m += 'function ';
        m += t;
        m += 'Properties.Get';
        m += p.name.PadRight(max_name_len);
        m += ' := ';
        if p.t = 'String' then
          m += 'GetString' else
        begin
          var arr_c := 0;
          while p.t.StartsWith('array of ' * (arr_c+1)) do arr_c += 1;
          m += 'GetVal';
          loop arr_c do
            m += 'Arr';
          m += '&<';
          m += p.t.Substring('array of '.Length * arr_c);
          m += '>';
        end;
        m += '(';
        m += info_t;
        m += '.';
        if not p.base_name.StartsWith('!') then
        begin
          m += info_t.Remove(info_t.Length-'Info'.Length).ToUpper;
          m += '_';
        end;
        m += p.base_name.TrimStart('!');
        foreach var arg in p.special_args do
        begin
          m += ', ';
          m += arg;
        end;
        m += ');'#10;
        
      end;
      
      m += #10;
      
      
      
      n += '  ';
      all += '{$endregion ';
      all += t;
      all += '}'#10;
      
      n += '  ';
      all += #10;
      
    end;
    
    loop 1 do
    begin
      n += '  ';
      all += #10;
    end;
    n += '  ';
    
    all.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.