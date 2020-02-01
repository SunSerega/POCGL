unit FuncData;

interface

uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

var log, log_func_ovrs: System.IO.StreamWriter;

procedure InitLog(var initable_log: System.IO.StreamWriter; fname: string);

type
  LogCache = static class
    static invalid_ext_names := new HashSet<string>;
    static invalid_ntv_types := new HashSet<string>;
  end;
  
var allowed_ext_names := HSet(
  '','ARB','EXT',
  'NV','AMD','ATI','APPLE','SGI','HP','IBM','PGI','SGIS','SGIX','SUN','GREMEDY','INTEL','MESA','NVX','OES','OVR','SUNX','OML','INGR','KHR','3DFX','3DL','I3D','WIN','MESAX','S3','REND'
);
function GetExt(s: string): string;

type
  
  {$region Group}
  
  Group = sealed class(INamed)
    public name: string;
    public bitmask: boolean;
    public enums: Dictionary<string, int64>;
    
    public function GetName: string := name;
    
    public ext_name: string;
    
    public procedure FinishInit;
    begin
      ext_name := GetExt(name);
    end;
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader);
    begin
      name := br.ReadString;
      bitmask := br.ReadBoolean;
      
      var enums_count := br.ReadInt32;
      enums := new Dictionary<string, int64>(enums_count);
      loop enums_count do
      begin
        var key := br.ReadString.Substring(3);
        var val := br.ReadInt64;
        enums.Add(key, val);
      end;
      
      FinishInit;
    end;
    
    private function EnumrKeys := enums.Keys.OrderBy(ename->enums[ename]).ThenBy(ename->ename);
    private property ValueStr[ename: string]: string read '$'+enums[ename].ToString('X4');
    
    public procedure Write(sb: StringBuilder);
    begin
      var max_w := enums.Keys.Max(ename->ename.Length);
      sb +=       $'  {name} = record' + #10;
      
      sb +=       $'    public val: UInt32;' + #10;
      sb +=       $'    public constructor(val: UInt32) := self.val := val;' + #10;
      sb +=       $'    ' + #10;
      
      foreach var ename in EnumrKeys do
        sb +=     $'    private static _{ename.PadRight(max_w)} := new {name}({ValueStr[ename]});' + #10;
      sb +=       $'    ' + #10;
      
      foreach var ename in EnumrKeys do
        sb +=     $'    public static property {ename}:{'' ''*(max_w-ename.Length)} {name} read _{ename};' + #10;
      sb +=       $'    ' + #10;
      
      if bitmask then
      begin
        
        sb +=     $'    public static function operator or(f1,f2: {name}) := new {name}(f1.val or f2.val);' + #10;
        sb +=     $'    ' + #10;
        
        foreach var ename in EnumrKeys do
          if enums[ename]<>0 then
            sb += $'    public property HAS_FLAG_{ename}:{'' ''*(max_w-ename.Length)} boolean read self.val and {ValueStr[ename]} <> 0;' + #10 else
            sb += $'    public property ANY_FLAGS: boolean read self.val<>0;' + #10;
        sb +=     $'    ' + #10;
        
      end;
      
      sb +=       $'    public function ToString: string; override;' + #10;
      sb +=       $'    begin' + #10;
      if bitmask then
      begin
        sb +=     $'      var res := typeof({name}).GetProperties.Where(prop->prop.Name.StartsWith(''HAS_FLAG_'') and boolean(prop.GetValue(self))).Select(prop->prop.Name).ToList;' + #10;
        sb +=     $'      Result := res.Count=0?' + #10;
        sb +=     $'        $''{name}[{{ self.val=0 ? ''''NONE'''' : self.val.ToString(''''X'''') }}]'':' + #10;
        sb +=     $'        res.JoinIntoString(''+'');' + #10;
      end else
      begin
        sb +=     $'      var res := typeof({name}).GetProperties(System.Reflection.BindingFlags.Static or System.Reflection.BindingFlags.Public).FirstOrDefault(prop->UInt32(prop.GetValue(self))=self.val);' + #10;
        sb +=     $'      Result := res=nil?' + #10;
        sb +=     $'        $''{name}[{{ self.val=0 ? ''''NONE'''' : self.val.ToString(''''X'''') }}]'':' + #10;
        sb +=     $'        res.Name;' + #10;
      end;
      sb +=       $'    end;' + #10;
      sb +=       $'    ' + #10;
      
      sb +=       $'  end;'+#10;
      sb +=       $'  ' + #10;
    end;
    
  end;
  GroupFixer = abstract class(Fixer<GroupFixer, Group>)
    
    public static constructor;
    
    protected procedure WarnUnused; override :=
    Otp($'WARNING: Fixer of group [{self.name}] wasn''t used');
    
  end;
  
  {$endregion Group}
  
  {$region Func}
  
  FuncOrgParam = sealed class
    public name, t: string;
    public ptr: integer;
    public gr: Group;
    
    private static TypeTable := new Dictionary<string,string>;
    private static UsedTypeTable := new HashSet<string>;
    static constructor;
    begin
      foreach var l in ReadLines(GetFullPath('..\MiscInput\TypeTable.dat', GetEXEFileName)) do
      begin
        var s := l.Split('=');
        if s.Length<2 then continue;
        TypeTable.Add(s[0].Trim,s[1].Trim);
      end;
    end;
    
    public static procedure WarnUnusedTypeTable :=
    foreach var ntv_t in TypeTable.Keys do
      if not UsedTypeTable.Contains(ntv_t) then
        Otp($'WARNING: TypeTable key [{ntv_t}] wasn''t used');
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader; grs: List<Group>; var proto: boolean);
    begin
      self.name := br.ReadString;
      
      var ntv_t := br.ReadString;
      if TypeTable.TryGetValue(ntv_t,self.t) then
        UsedTypeTable += ntv_t else
        if LogCache.invalid_ntv_types.Add(ntv_t) then
          Otp($'ERROR: Nativ type [{ntv_t}] isn''t defined');
      
      self.ptr := br.ReadInt32 + self.t.Count(ch->ch='*') - self.t.Count(ch->ch='-');
      self.t := self.t.Remove('*','-').Trim;
      if self.ptr<0 then
      begin
        if proto and (ntv_t.ToLower='void') and (ptr=-1) then
          self.t := nil else
          raise new MessageException($'ERROR: par [{name}] with type [{ntv_t}] got negative ref count: [{self.ptr}]');
      end;
      
      var gr_ind := br.ReadInt32;
      self.gr := gr_ind=-1 ? nil : grs[gr_ind];
      
      proto := false;
    end;
    
    public function GetTName :=
    gr=nil ? t : gr.name;
    
  end;
  Func = sealed class(INamed)
    public org_par: array of FuncOrgParam;
    
    public name: string;
    public ext_name: string;
    public is_proc: boolean;
    public procedure BasicInit;
    begin
      name := org_par[0].name;
      ext_name := GetExt(name);
      is_proc := org_par[0].t=nil;
    end;
    
    public function GetName: string := name;
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader; grs: List<Group>);
    begin
      var proto := true;
      org_par := ArrGen(br.ReadInt32, i->new FuncOrgParam(br, grs, proto));
      BasicInit;
    end;
    
    // ": array of possible_par_type_collection"
    // (array_lvl, array_el_type)
    public possible_par_types: array of List<(integer, string)>;
    public procedure InitPossibleParTypes;
    begin
      if possible_par_types<>nil then exit;
      possible_par_types := org_par.ConvertAll((par,par_i)->
      begin
        
        // record
        if par.ptr=0 then
        begin
          if par.t='ntv_char' then
          begin
            log.WriteLine('Param [{par.name}] with type [{par.t}] in func [{self.name}]');
            Result := Lst((0,'SByte'));
          end else
            Result := Lst((0,par.GetTName)); // (0,nil) for procedure ret par
        end else
        
        // string
        if par.t='ntv_char' then
        begin
          if par_i=0 then
          begin
            Result := Lst((par.ptr-1, 'string'));
            exit;
          end;
          var res := new List<System.Tuple<integer,string>>(par.ptr+1);
          
          for var ptr := 0 to par.ptr-1 do
            res += (    ptr  , 'IntPtr');
          res +=   (par.ptr-1, 'string');
          
          res.Reverse;
          Result := res;
        end else
        
        // array/var-arg
        begin
          if par_i=0 then
          begin
            Result := Lst((0, '^'+par.GetTName));
            exit;
          end;
          var res := new List<(integer,string)>( Max(3,par.ptr+1) );
          
          if par.ptr=1 then
          begin
            res += (0, 'IntPtr');
            res += (0, 'var!'+par.GetTName);
          end else
          for var ptr := 0 to par.ptr-1 do
            res += (    ptr  , 'IntPtr');
          
          res +=   (par.ptr  , par.GetTName);
          
          res.Reverse;
          Result := res;
        end;
        
      end);
    end;
    
    public all_overloads: List<array of (integer, string)>;
    public procedure InitOverloads;
    begin
      if all_overloads<>nil then exit;
      InitPossibleParTypes;
      
      all_overloads := new List<array of (integer,string)>(
        possible_par_types.Select(types->types.Count).Product
      );
      var overloads := Seq&<sequence of (integer,string)>(Seq&<(integer,string)>());
      
      foreach var types in possible_par_types do
        overloads := overloads.SelectMany(ovr->types.Select(t->ovr.Append(t)));
      
      foreach var ovr in overloads do
      begin
        var enmr := ovr.GetEnumerator();
        all_overloads += ArrGen(org_par.Length, i->
        begin
          if not enmr.MoveNext then raise new System.InvalidOperationException;
          Result := enmr.Current;
        end);
        if enmr.MoveNext then raise new System.InvalidOperationException;
      end;
      
    end;
    
    public static procedure WriteGetPtrFunc(sb: StringBuilder);
    begin
      sb += '    public static function GetFuncAdr([MarshalAs(UnmanagedType.LPStr)] lpszProc: string): IntPtr;'#10;
      sb += '    external ''opengl32.dll'' name ''wglGetProcAddress'';'#10;
      sb += '    public static function GetFuncOrNil<T>(fadr: IntPtr) :='#10;
      sb += '    fadr=IntPtr.Zero ? default(T) :'#10;
      sb += '    Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
    end;
    
    public procedure Write(sb: StringBuilder; api, version: string);
    begin
      InitOverloads;
      
      if not is_proc or (org_par.Length>1) then
      begin
        log_func_ovrs.WriteLine($'# {name}');
        foreach var ovr in all_overloads do
        begin
          foreach var par in is_proc?ovr.Skip(1):ovr do
            log_func_ovrs.Write($' {par[0]*''array of ''}{par[1]} |');
          log_func_ovrs.WriteLine;
        end;
        log_func_ovrs.WriteLine;
      end;
      
      if all_overloads.Count=0 then
      begin
        Otp($'ERROR: Func [{name}] ended up having 0 overloads. [possible_par_types]: ');
        foreach var par in possible_par_types do
          Otp(_ObjectToString(par));
        exit;
      end;
      if all_overloads.Count>15 then Otp($'WARNING: Too many ({all_overloads.Count}) overloads of func [{name}]');
      
      var l_name := name;
      if name.ToLower.StartsWith(api) then
        l_name := name.Substring(api.Length) else
        log.WriteLine($'Func [{name}] had api [{api}], which isn''t start of it''s name');
      
      var WriteMarshalAs: (System.Tuple<integer,string>, boolean)->() := (par,res)->
      begin
        if (par[0]=0) and (par[1]<>'string') then exit;
        sb += '[';
        if res then sb += 'Result: ';
        if par[0]>0 then
        begin
          sb += 'MarshalAs(UnmanagedType.LPArray';
          if par[0]>1 then
            sb += ', ArraySubType=UnmanagedType.LPArray' else
          if par[1]='string' then
            sb += ', ArraySubType=UnmanagedType.LPStr';
          sb += ')';
        end else
        if par[1]='string' then
          sb += 'MarshalAs(UnmanagedType.LPStr)';
        sb += '] ';
      end;
      
      var WriteOvrT: procedure(ovr: array of (integer,string); generic_names: List<string>; name: string; marshals: boolean) := (ovr,generic_names,name,marshals)->
      begin
        var use_standart_dt := (name=nil) and ovr.Skip(1).All(par->not par[1].StartsWith('var!'));
        if use_standart_dt then
        begin
          sb += is_proc ? 'Action' : 'Func';
        end else
        begin
          if marshals then WriteMarshalAs(ovr[0],true);
          sb += is_proc ? 'procedure' : 'function';
        end;
        if name<>nil then
        begin
          sb += ' ';
          sb += name;
          if (generic_names<>nil) and (generic_names.Count<>0) then
          begin
            sb += '<';
            foreach var gn in generic_names do
            begin
              sb += gn;
              sb += ',';
            end;
            sb.Length -= 1;
            sb += '>';
          end;
        end;
        
        if ovr.Length>1 then
        begin
          sb += use_standart_dt ? '<' : '(';
          for var par_i := 1 to ovr.Length-1 do
          begin
            var par := ovr[par_i];
            if not use_standart_dt then
            begin
              if marshals then WriteMarshalAs(par,false);
              if par[1].StartsWith('var!') then sb += 'var ';
              sb += org_par[par_i].name;
              sb += ': ';
            end;
            loop par[0] do sb += 'array of ';
            sb += par[1].Split('!').Last;
            sb += use_standart_dt ? ', ' : '; ';
          end;
          sb.Length -= 2; // лишнее '; '
          sb += use_standart_dt ? '>' : ')';
        end;
        
        if not is_proc then
          if use_standart_dt then
          begin
            sb.Length -= 1;
            sb += ', ';
            loop ovr[0][0] do sb += 'array of ';
            sb += ovr[0][1];
            sb += '>';
          end else
          begin
            sb += ': ';
            loop ovr[0][0] do sb += 'array of ';
            sb += ovr[0][1];
          end;
        
      end;
      
      if (api='gl') and (version <= '1.1') then // use_external
      begin
        
        for var ovr_i := 0 to all_overloads.Count-1 do
        begin
          var ovr := all_overloads[ovr_i];
          
          sb += '    public static ';
          WriteOvrT(ovr,nil, $'z_{l_name}', true);
          sb += ';'#10;
          sb += $'    external ''opengl32.dll'' name ''{name}'';'+#10;
          
          sb += $'    public [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
          WriteOvrT(ovr,nil, l_name, false);
          sb += $' := z_{l_name};'+#10;
          
        end;
        
      end else
      begin
        sb += $'    public z_{l_name}_adr := GetFuncAdr(''{name}'');' + #10;
        var PrevNtvOvrs := new List<array of (integer,string)>(all_overloads.Count);
        
        for var ovr_i := 0 to all_overloads.Count-1 do
        begin
          var ovr := all_overloads[ovr_i];
          
          var generic_inds := new List<integer>; // индексы шаблонных параметров с шаблонным типом в temp перегрузке
          var temp_generic_names := new List<string>; // шаблонные параметры temp перегрузки
          var all_generic_names := new List<string>; // шаблонные параметры основной публичной перегрузки
          
          var init := new List<string>;
          var finl := new List<string>;
          var par_strs := new string[ovr.Length];
          
          var ntv_ovr := ovr.ConvertAll((par,par_i)->
          begin
            var res_t := par[1];
            
            if par_i=0 then
            begin
              if is_proc then
              begin
                Result := (0,string(nil));
                exit;
              end;
              
              // нельзя определить размер массива в результате
              if par[0]<>0 then raise new System.NotSupportedException;
              var relevant_par_name := 'Result';
              
              if par[1]='string' then
              begin
                var str_ptr_name := $'par_{par_i}_str_ptr';
                
                finl += $'{relevant_par_name} := Marshal.PtrToStringAnsi({str_ptr_name});';
                // Marshal.FreeHGlobal не нужно, потому что строка в возвращаемом значении - всегда статичная строка
                
                par_strs[par_i] := str_ptr_name;
                relevant_par_name := str_ptr_name;
                res_t := 'IntPtr';
              end;
              
              par_strs[par_i] := relevant_par_name;
            end else
            begin
              var relevant_par_name := org_par[par_i].name;
              
              var sres_t := res_t.Split('!').Last;
              var generic := (res_t<>nil) and sres_t.StartsWith('T') and sres_t.Skip(1).All(ch->ch.IsDigit);
              if generic then
                if par[0]=0 then
                begin
                  relevant_par_name := $'PByte(pointer(@{relevant_par_name}))^';
                  res_t := 'var!Byte';
                  all_generic_names += sres_t;
                end else
                begin
                  generic_inds += par_i;
                  temp_generic_names += sres_t;
                  all_generic_names += sres_t;
                  res_t := 'Byte';
                end;
              
              if par[1]='string' then
              begin
                var str_ptr_arr_name := $'par_{par_i}_str_ptr';
                
                var str_ptr_arr_init := new StringBuilder;
                str_ptr_arr_init += $'var {str_ptr_arr_name} := ';
                var prev_arr_name := relevant_par_name;
                for var i := 1 to par[0] do
                begin
                  var new_arr_name := $'arr_el{i}';
                  str_ptr_arr_init += $'{prev_arr_name}.ConvertAll({new_arr_name}->';
                  prev_arr_name := new_arr_name;
                end;
                str_ptr_arr_init += $'Marshal.StringToHGlobalAnsi({prev_arr_name})';
                str_ptr_arr_init.Append(')',par[0]);
                str_ptr_arr_init += ';';
                init += str_ptr_arr_init.ToString;
                
                var str_ptr_arr_finl := new StringBuilder;
                prev_arr_name := str_ptr_arr_name;
                for var i := 1 to par[0] do
                begin
                  var new_arr_name := $'arr_el{i}';
                  str_ptr_arr_finl += $'foreach var {new_arr_name} in {prev_arr_name} do ';
                  prev_arr_name := new_arr_name;
                end;
                str_ptr_arr_finl += $'Marshal.FreeHGlobal({prev_arr_name});';
                finl += str_ptr_arr_finl.ToString;
                
                relevant_par_name := str_ptr_arr_name;
                res_t := 'IntPtr';
              end;
              
              if par[0]>1 then
                for var temp_arr_i := par[0]-1 downto 1 do
                begin
                  var temp_arr_name := $'par_{par_i}_temp_arr{temp_arr_i}';
                  
                  var temp_arr_init := new StringBuilder;
                  temp_arr_init += $'var {temp_arr_name} := {relevant_par_name}';
                  for var i := 1 to temp_arr_i-1 do
                    temp_arr_init += $'.ConvertAll(arr_el{i}->arr_el{i}';
                  temp_arr_init += $'.ConvertAll(arr_el{temp_arr_i}->begin{#10}';
                  temp_arr_init += $'        var l := sizeof({res_t})*arr_el{temp_arr_i}.Length;{#10}';
                  temp_arr_init += $'        Result := Marshal.AllocHGlobal(l);{#10}';
                  temp_arr_init += $'        Marshal.Copy(arr_el{temp_arr_i},0,Result,l);{#10}';
                  temp_arr_init += $'      end)';
                  temp_arr_init.Append(')',temp_arr_i-1);
                  temp_arr_init += ';';
                  init += temp_arr_init.ToString;
                  
                  var temp_arr_finl := new StringBuilder;
                  var prev_arr_name := temp_arr_name;
                  for var i := 1 to temp_arr_i do
                  begin
                    var new_arr_name := $'arr_el{i}';
                    temp_arr_finl += $'foreach var {new_arr_name} in {prev_arr_name} do ';
                    prev_arr_name := new_arr_name;
                  end;
                  temp_arr_finl += $'Marshal.FreeHGlobal(arr_el{temp_arr_i});';
                  finl += temp_arr_finl.ToString;
                  
                  relevant_par_name := temp_arr_name;
                  res_t := 'IntPtr'; // внутри цикла, чтоб в следующей итерации "sizeof({res_t})" было правильным
                end;
              
              if par[0]<>0 then
              begin
                res_t := $'var!{res_t}';
                par_strs[par_i] := $'{relevant_par_name}[0]';
              end else
                par_strs[par_i] := relevant_par_name;
              
            end;
            
            Result := (0, res_t);
          end);
          
          var same_ntv_ovr_ind := PrevNtvOvrs.FindIndex(pntv_ovr->(pntv_ovr<>nil) and pntv_ovr.SequenceEqual(ntv_ovr));
          var z_ovr_name: string;
          if same_ntv_ovr_ind=-1 then
          begin
            z_ovr_name := $'z_{l_name}_ovr_{ovr_i}';
            PrevNtvOvrs += ntv_ovr;
            
            sb += $'    public {z_ovr_name} := GetFuncOrNil&<';
            WriteOvrT(ntv_ovr,nil, nil, false);
            sb += $'>(z_{l_name}_adr);'+#10;
            
          end else
          begin
            z_ovr_name := $'z_{l_name}_ovr_{same_ntv_ovr_ind}';
            PrevNtvOvrs.Add(nil);
          end;
          
          if generic_inds.Count<>0 then
          begin
            var temp_z_ovr_name := z_ovr_name+'_temp';
            
            sb += '    private [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
            WriteOvrT(ntv_ovr.ConvertAll((par,par_i)->
            begin
              var g_ind := generic_inds.IndexOf(par_i);
              Result := g_ind=-1 ? par : (par[0],'var!'+temp_generic_names[g_ind]);
            end),temp_generic_names, temp_z_ovr_name, false);
            sb += ' :='#10;
            sb += $'    {z_ovr_name}(';
            for var par_i := 1 to ntv_ovr.Length-1 do
            begin
              sb += par_i in generic_inds ? $'PByte(pointer(@{org_par[par_i].name}))^' : org_par[par_i].name ;
              sb += ', ';
            end;
            sb.Length -= 2;
            sb += ');'#10;
            
            z_ovr_name := temp_z_ovr_name;
          end;
          
          sb += '    public [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
          WriteOvrT(ovr,all_generic_names, l_name, false);
          sb += ';'#10;
          sb += '    begin'#10;
          
          foreach var l in init do
          begin
            sb += '      ';
            sb += l;
            sb += #10;
          end;
          
          sb += '      ';
          if not is_proc then sb += $'{par_strs[0]} := ';
          sb += z_ovr_name;
          if ovr.Length>1 then
          begin
            sb += '(';
            foreach var par_str in par_strs.Skip(1) do
            begin
              sb += par_str;
              sb += ', ';
            end;
            sb.Length -= 2;
            sb += ')';
          end;
          sb += ';'#10;
          
          foreach var l in finl do
          begin
            sb += '      ';
            sb += l;
            sb += #10;
          end;
          
          sb += '    end;'#10;
        end;
        
      end;
      
      sb += '    '#10;
    end;
    
  end;
  FuncFixer = abstract class(Fixer<FuncFixer, Func>)
    
    public static constructor;
    
    protected procedure WarnUnused; override :=
    Otp($'WARNING: Fixer of func [{self.name}] wasn''t used');
    
  end;
  
  {$endregion Func}
  
  {$region FuncContainers}
  
  Feature = sealed class
    public version: string;
    public add: List<Func>;
    public rem: List<Func>;
    
    public static ByApi := new Dictionary<string, List<Feature>>;
    
    public constructor(br: System.IO.BinaryReader; funcs: List<Func>);
    begin
      var api := br.ReadString;
      version := ArrGen(br.ReadInt32, i->br.ReadInt32).JoinToString('.');
      add := ArrGen(br.ReadInt32, i->funcs[br.ReadInt32]).ToList;
      rem := ArrGen(br.ReadInt32, i->funcs[br.ReadInt32]).ToList;
      
      if not (api in ['gl','wgl','glx']) then raise new System.NotSupportedException;
      
      var lst: List<Feature>;
      if not ByApi.TryGetValue(api, lst) then
      begin
        lst := new List<Feature>;
        ByApi[api] := lst;
      end;
      lst += self;
      
    end;
    
    public static procedure WriteAll(sb: StringBuilder) :=
    foreach var api in Feature.ByApi.Keys do
    begin
      // func - addition version
      var all_funcs := new Dictionary<Func, string>;
      // func - deprecation version
      var deprecated := new Dictionary<Func, string>;
      
      foreach var ftr in Feature.ByApi[api].AsEnumerable.Reverse do
      begin
        foreach var f in ftr.rem do
          if not all_funcs.Remove(f) then // glGetPointerv было добавлено, убрано и ещё раз добавлено
            deprecated.Add(f, ftr.version);
        foreach var f in ftr.add do
          if all_funcs.ContainsKey(f) then
            Otp($'WARNING: Func [{f.name}] was added in versions [{all_funcs[f]}] and [{ftr.version}]') else
            all_funcs[f] := ftr.version;
      end;
      
      sb += $'  {api} = sealed class'+#10;
      if api='gl' then Func.WriteGetPtrFunc(sb);
      sb += $'    '+#10;
      
      foreach var f in all_funcs.Keys.Where(f->not deprecated.ContainsKey(f)).OrderBy(f->f.name) do
      begin
        sb += $'    // added in {api}{all_funcs[f]}'+#10;
        f.Write(sb, api, all_funcs[f]);
      end;
      
      sb += $'  end;'+#10;
      sb += $'  '+#10;
      
      if not deprecated.Any then continue;
      sb += $'  {api}D = sealed class'+#10;
      if api='gl' then Func.WriteGetPtrFunc(sb);
      sb += $'    '+#10;
      
      foreach var f in all_funcs.Keys.Where(f->deprecated.ContainsKey(f)).OrderBy(f->f.name) do
      begin
        sb += $'    // added in {api}{all_funcs[f]}, deprecated in {api}{deprecated[f]}'+#10;
        f.Write(sb, api, all_funcs[f]);
      end;
      
      sb += $'  end;'+#10;
      sb += $'  '+#10;
    end;
    
  end;
  Extension = sealed class
    public name: string;
    public api: string;
    public ext_group: string;
    public add: List<Func>;
    
    public constructor(br: System.IO.BinaryReader; funcs: List<Func>);
    begin
      name := br.ReadString;
      api := br.ReadString;
      add := ArrGen(br.ReadInt32, i->funcs[br.ReadInt32]).ToList;
      
      if not name.ToLower.StartsWith(api+'_') then
        raise new System.NotSupportedException($'Extension name [{name}] must start from api [{api}]');
      name := name.Substring(api.Length+1);
      
      var ind := name.IndexOf('_');
      ext_group := name.Remove(ind);
      if ext_group in allowed_ext_names then
        name := name.Substring(ind+1) else
      if LogCache.invalid_ext_names.Add(ext_group) then
        log.WriteLine($'Ext group [{ext_group}] of ext [{name}] is not supported');
      
    end;
    
    public procedure Write(sb: StringBuilder);
    begin
      
      var ToDo := 0;
      
    end;
    
  end;
  
  {$endregion FuncContainers}
  
implementation

{$region Misc}

procedure InitLog(var initable_log: System.IO.StreamWriter; fname: string) :=
initable_log := new System.IO.StreamWriter(
  GetFullPath(fname, GetEXEFileName),
  false, enc
);

function GetExt(s: string): string;
begin
  
  var i := s.Length;
  while s[i].IsUpper or s[i].IsDigit do i -= 1;
  Result := i=s.Length ? '' : s.Substring(i);
  if allowed_ext_names.Contains(Result) then exit;
  
  var _Result := Result;
  Result :=
    allowed_ext_names.OrderByDescending(ext->ext.Length)
    .First(ext->_Result.EndsWith(ext))
  ;
  if LogCache.invalid_ext_names.Add(_Result) and (_Result.Length>1) then
    log.WriteLine($'Invalid ext name [{_Result}], replaced with [{Result}]');
  
end;

function ToTName(tname: string): (integer,string);
begin
  tname := tname.Trim;
  var c := 0;
  while tname.StartsWith('array of ') do
  begin
    c += 1;
    tname := tname.Substring('array of '.Length).Trim;
  end;
  Result := (c,tname);
end;

{$endregion Misc}

{$region GroupFixer}

type
  GroupAdder = sealed class(GroupFixer)
    private name: string;
    private bitmask: boolean;
    private enums := new Dictionary<string, int64>;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(nil);
      self.name := name;
      var enmr := data.Where(l->not string.IsNullOrWhiteSpace(l)).GetEnumerator;
      
      if not enmr.MoveNext then raise new System.FormatException;
      bitmask := boolean.Parse(enmr.Current);
      
      while enmr.MoveNext do
      begin
        var t := enmr.Current.Split('=');
        enums.Add(t[0], t[1].StartsWith('0x') ?
          System.Convert.ToInt64(t[1], 16) :
          System.Convert.ToInt64(t[1])
        );
      end;
      
      self.RegisterAsAdder;
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      gr.name     := self.name;
      gr.bitmask  := self.bitmask;
      gr.enums    := self.enums;
      gr.FinishInit;
      self.used := true;
      Result := false;
    end;
    
  end;
  GroupRemover = sealed class(GroupFixer)
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      if data.Any(l->not string.IsNullOrWhiteSpace(l)) then raise new System.FormatException;
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      self.used := true;
      Result := true;
    end;
    
  end;
  
  GroupNameFixer = sealed class(GroupFixer)
    public new_name: string;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      self.new_name := data.Single(l->not string.IsNullOrWhiteSpace(l));
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      gr.name := new_name;
      self.used := true;
      Result := false;
    end;
    
  end;
  
static constructor GroupFixer.Create;
begin
  
  var fls := System.IO.Directory.EnumerateFiles(GetFullPath('..\Fixers\Enums', GetEXEFileName), '*.dat');
  foreach var gr in fls.SelectMany(fname->GroupFixer.ReadBlocks(fname)) do
    foreach var bl in ReadBlocks(gr[1],'!',false) do
    case bl[0] of
      
      'add':    GroupAdder    .Create(gr[0], bl[1]);
      'remove': GroupRemover  .Create(gr[0], bl[1]);
      
      'rename': GroupNameFixer.Create(gr[0], bl[1]);
      
      else raise new MessageException($'Invalid group fixer type [!{bl[0]}] for group [{gr[0]}]');
    end;
  
end;

{$endregion GroupFixer}

{$region FuncFixer}

type
  FuncAdder = sealed class(FuncFixer)
    public org_par := new List<FuncOrgParam>;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(nil);
      var enmr := data.Where(l->not string.IsNullOrWhiteSpace(l)).GetEnumerator;
      
      if not enmr.MoveNext then raise new System.FormatException;
      var proto := new FuncOrgParam;
      proto.name := name;
      proto.t := enmr.Current;
      if proto.t.Trim='void' then
        proto.t := nil else
      begin
        proto.ptr := proto.t.Count(ch->ch='*');
        proto.t := proto.t.Remove('*').Trim;
      end;
      org_par += proto;
      
      while enmr.MoveNext do
      begin
        var param := new FuncOrgParam;
        var s := enmr.Current.Split(':');
        param.name := s[0].Trim;
        param.t := s[1].Remove('*').Trim;
        param.ptr := s[1].Count(ch->ch='*');
        org_par += param;
      end;
      
      self.RegisterAsAdder;
    end;
    
    public function Apply(f: Func): boolean; override;
    begin
      f.org_par := self.org_par.ToArray;
      f.BasicInit;
      self.used := true;
      Result := false;
    end;
    
  end;
  FuncRemover = sealed class(FuncFixer)
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      if data.Any(l->not string.IsNullOrWhiteSpace(l)) then raise new System.FormatException;
    end;
    
    public function Apply(f: Func): boolean; override;
    begin
      self.used := true;
      Result := true;
    end;
    
  end;
  
  FuncReplParTFixer = sealed class(FuncFixer)
    public old_tname: (integer,string);
    public new_tnames: array of (integer,string);
    
    public constructor(name: string; data: string);
    begin
      inherited Create(name);
      var s := data.Split('=');
      old_tname := ToTName( s[0] );
      new_tnames := s[1].Split('|').ConvertAll(ToTName);
    end;
    public static procedure Create(name: string; data: sequence of string) :=
    foreach var l in data do
      if not string.IsNullOrWhiteSpace(l) then
        new FuncReplParTFixer(name, l);
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitPossibleParTypes;
      
      var tn_id := 0;
      foreach var par in f.possible_par_types do
        for var i := 0 to par.Count-1 do
          if par[i]=old_tname then
          begin
            if tn_id=new_tnames.Length then
              raise new MessageException($'ERROR: Not enough {_ObjectToString(new_tnames)} replacement type for {old_tname} in [FuncReplParTFixer] of func [{f.name}]');
            par[i] := new_tnames[tn_id];
            tn_id += 1;
          end;
      if tn_id<>new_tnames.Length then
        raise new MessageException($'ERROR: Only {tn_id}/{new_tnames.Length} [new_tnames] of [FuncReplParTFixer] of func [{f.name}] were used');
      
      self.used := true;
      Result := false;
    end;
    
  end;
  FuncPPTFixer = sealed class(FuncFixer)
    public add_ts: array of List<(integer,string)>;
    public rem_ts: array of List<(integer,string)>;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      var s := data.Single(l->not string.IsNullOrWhiteSpace(l)).Split('|');
      var par_c := s.Length-1;
      if not string.IsNullOrWhiteSpace(s[par_c]) then raise new System.FormatException;
      
      SetLength(add_ts, par_c);
      SetLength(rem_ts, par_c);
      
      var res := new StringBuilder;
      for var i := 0 to par_c-1 do
      begin
        add_ts[i] := new List<(integer,string)>;
        rem_ts[i] := new List<(integer,string)>;
        
        var curr_lst: List<(integer,string)> := nil;
        var seal_t: ()->() := ()->
        begin
          var t := res.ToString.Trim;
          if t<>'' then curr_lst += ToTName(t);
          res.Clear;
        end;
        
        foreach var ch in s[i] do
          if ch in ['-','+'] then
          begin
            seal_t();
            curr_lst := ch='+' ? add_ts[i] : rem_ts[i];
          end else
            res += ch;
        
        seal_t();
      end;
      
    end;
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitPossibleParTypes;
      
      if add_ts.Length<>f.org_par.Length-integer(f.is_proc) then
        raise new MessageException($'ERROR: [FuncPPTFixer] of func [{f.name}] had wrong param count');
      
      for var i := 0 to add_ts.Length-1 do
      begin
        foreach var t in rem_ts[i] do
          if not f.possible_par_types[i].Remove(t) then
            Otp($'ERROR: [FuncPPTFixer] of func [{f.name}] failed to remove type [{t}] of param #{i}');
        foreach var t in add_ts[i] do
          if f.possible_par_types[i].Contains(t) then
            Otp($'ERROR: [FuncPPTFixer] of func [{f.name}] failed to add type [{t}] to param #{i}') else
            f.possible_par_types[i] += t;
      end;
      
      self.used := true;
      Result := false;
    end;
    
  end;
  
  FuncClearOvrsFixer = sealed class(FuncFixer)
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      if data.Any(l->not string.IsNullOrWhiteSpace(l)) then raise new System.FormatException;
    end;
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      f.all_overloads.Clear;
      self.used := true;
      Result := false;
    end;
    
  end;
  FuncOvrsFixerBase = abstract class(FuncFixer)
    public ovr: array of (integer,string);
    
    public constructor(name: string; data: string);
    begin
      inherited Create(name);
      
      var s := data.Split('|');
      if not string.IsNullOrWhiteSpace(s[s.Length-1]) then raise new System.FormatException(data);
      
      SetLength(ovr, s.Length-1);
      ovr.Fill(i->ToTName(s[i]));
      
    end;
    
    public static function PrepareOvr(add_void: boolean; ovr: array of (integer,string)): array of (integer,string);
    begin
      if add_void then
      begin
        var res: array of (integer,string);
        SetLength(res, ovr.Length+1);
        res[0] := (0,string(nil));
        ovr.CopyTo(res,1);
        Result := res;
      end else
        Result := ovr;
    end;
    
    public function OvrInd(lst: List<array of (integer,string)>; ovr: array of (integer,string)): integer;
    begin
      Result := -1;
      if lst.Count=0 then exit;
      if lst[0].Length<>ovr.Length then
        raise new MessageException($'ERROR: [{self.GetType}] of func [{self.name}] had wrong param count: {lst[0].Length} org vs {ovr.Length} custom');
      Result := lst.FindIndex(povr->povr.SequenceEqual(ovr));
    end;
    
  end;
  FuncAddOvrsFixer = sealed class(FuncOvrsFixerBase)
    
    public constructor(name: string; data: string) :=
    inherited Create(name, data);
    public static procedure Create(name: string; data: sequence of string) :=
    foreach var l in data do
      if not string.IsNullOrWhiteSpace(l) then
        new FuncAddOvrsFixer(name, l);
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      
      var povr := PrepareOvr(f.is_proc, ovr);
      if OvrInd(f.all_overloads, povr)<>-1 then
        Otp($'ERROR: [FuncAddOvrsFixer] of func [{f.name}] failed to add overload [{povr.JoinToString}]') else
        f.all_overloads += povr;
        
      self.used := true;
      Result := false;
    end;
    
  end;
  FuncRemOvrsFixer = sealed class(FuncOvrsFixerBase)
    
    public constructor(name: string; data: string) :=
    inherited Create(name, data);
    public static procedure Create(name: string; data: sequence of string) :=
    foreach var l in data do
      if not string.IsNullOrWhiteSpace(l) then
        new FuncRemOvrsFixer(name, l);
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      
      var povr := PrepareOvr(f.is_proc, ovr);
      var ind := OvrInd(f.all_overloads, povr);
      if ind=-1 then
        Otp($'ERROR: [FuncRemOvrsFixer] of func [{f.name}] failed to remove overload [{povr.JoinToString}]') else
        f.all_overloads.RemoveAt(ind);
      
      self.used := true;
      Result := false;
    end;
    
  end;
  
static constructor FuncFixer.Create;
begin
  
  var fls := System.IO.Directory.EnumerateFiles(GetFullPath('..\Fixers\Funcs', GetEXEFileName), '*.dat');
  foreach var gr in fls.SelectMany(fname->GroupFixer.ReadBlocks(fname)) do
    foreach var bl in ReadBlocks(gr[1],'!',false) do
    case bl[0] of
      
      'add':                FuncAdder         .Create(gr[0], bl[1]);
      'remove':             FuncRemover       .Create(gr[0], bl[1]);
      
      'repl_par_t':         FuncReplParTFixer .Create(gr[0], bl[1]);
      'possible_par_types': FuncPPTFixer      .Create(gr[0], bl[1]);
      
      'clear_ovrs':         FuncClearOvrsFixer.Create(gr[0], bl[1]);
      'add_ovrs':           FuncAddOvrsFixer  .Create(gr[0], bl[1]);
      'rem_ovrs':           FuncRemOvrsFixer  .Create(gr[0], bl[1]);
      
      else raise new MessageException($'Invalid func fixer type [!{bl[0]}] for func [{gr[0]}]');
    end;
  
end;

{$endregion FuncFixer}

end.