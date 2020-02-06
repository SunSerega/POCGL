unit FuncData;

interface

uses MiscUtils in '..\..\Utils\MiscUtils.pas';

var log := InitLog('Log\Funcs.log');
var log_func_ovrs := InitLog('Log\FinalFuncOverloads.log');

type
  LogCache = static class
    static invalid_ext_names  := new HashSet<string>;
    static invalid_ntv_types  := new HashSet<string>;
    static used_t_names       := new HashSet<string>;
  end;
  
var allowed_ext_names := HSet(
  '','ARB','EXT','GDI',
  'NV','AMD','ATI','APPLE','SGI','HP','IBM','PGI','SGIS','SGIX','SUN','GREMEDY','INTEL','S3',
  'NVX','OES','OVR','SUNX','OML','INGR','KHR','3DFX','3DL','I3D','WIN','MESA','MESAX','REND'
);
function GetExt(s: string): string;

var unallowed_words: HashSet<string>;

type
  
  {$region TypeTable}
  
  TypeTable = static class
    
    private static All := new Dictionary<string,string>;
    private static Used := new HashSet<string>;
    static constructor;
    begin
      foreach var l in ReadLines(GetFullPath('..\MiscInput\TypeTable.dat', GetEXEFileName)) do
      begin
        var s := l.Split('=');
        if s.Length<2 then continue;
        All.Add(s[0].Trim,s[1].Trim);
      end;
    end;
    
    public static function Convert(ntv_t: string): string;
    begin
      if All.TryGetValue(ntv_t, Result) then
        Used += ntv_t else
      begin
        Result := ntv_t;
        if LogCache.invalid_ntv_types.Add(ntv_t) then
          Otp($'WARNING: Type conversion for [{ntv_t}] isn''t defined');
      end;
    end;
    
    public static procedure WarnUnused :=
    foreach var ntv_t in All.Keys do
      if not Used.Contains(ntv_t) then
        Otp($'WARNING: TypeTable key [{ntv_t}] wasn''t used');
    
  end;
  
  {$endregion TypeTable}
  
  {$region Group}
  
  Group = sealed class(INamed)
    public name, t: string;
    public bitmask: boolean;
    public enums: Dictionary<string, int64>;
    
    public function GetName: string := name;
    
    public ext_name: string;
    public screened_enums: Dictionary<string,string>;
    
    public procedure FinishInit;
    begin
      
      ext_name := GetExt(name);
      
      screened_enums := new Dictionary<string, string>;
      foreach var key in enums.Keys do
        screened_enums.Add(key, key.ToLower in unallowed_words ? '&'+key : key);
      
    end;
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader);
    begin
      
      name := br.ReadString;
      t := TypeTable.Convert(br.ReadString);
      bitmask := br.ReadBoolean;
      
      var enums_count := br.ReadInt32;
      enums := new Dictionary<string, int64>(enums_count);
      loop enums_count do
      begin
        var key := br.ReadString;
        if not key.ElementAt(3).IsDigit then key := key.Substring(3);
        if key.ToLower.StartsWith('get_') then key := key.Insert(3,'_');
        var val := br.ReadInt64;
        enums.Add(key, val);
      end;
      
      FinishInit;
    end;
    
    private static All := new List<Group>;
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      All.Capacity := br.ReadInt32;
      loop All.Capacity do All += new Group(br);
    end;
    
    private function EnumrKeys := enums.Keys.OrderBy(ename->enums[ename]).ThenBy(ename->ename);
    private property ValueStr[ename: string]: string read '$'+enums[ename].ToString('X4');
    
    public procedure Write(sb: StringBuilder);
    begin
      var max_w := screened_enums.Keys.Max(ename->ename.Length);
      var max_scr_w := screened_enums.Values.Max(ename->ename.Length);
      sb +=       $'  {name} = record' + #10;
      
      sb +=       $'    public val: {t};' + #10;
      sb +=       $'    public constructor(val: {t}) := self.val := val;' + #10;
      sb +=       $'    ' + #10;
      
      foreach var ename in EnumrKeys do
        sb +=     $'    private static _{ename.PadRight(max_w)} := new {name}({ValueStr[ename]});' + #10;
      sb +=       $'    ' + #10;
      
      foreach var ename in EnumrKeys do
        sb +=     $'    public static property {screened_enums[ename]}:{'' ''*(max_scr_w-screened_enums[ename].Length)} {name} read _{ename};' + #10;
      sb +=       $'    ' + #10;
      
      if bitmask then
      begin
        
        sb +=     $'    public static function operator or(f1,f2: {name}) := new {name}(f1.val or f2.val);' + #10;
        sb +=     $'    ' + #10;
        
        foreach var ename in EnumrKeys do
          if enums[ename]<>0 then
            sb += $'    public property HAS_FLAG_{screened_enums[ename]}:{'' ''*(max_scr_w-screened_enums[ename].Length)} boolean read self.val and {ValueStr[ename]} <> 0;' + #10 else
            sb += $'    public property ANY_FLAGS: boolean read self.val<>0;' + #10;
        sb +=     $'    ' + #10;
        
      end;
      
      sb +=       $'    public function ToString: string; override;' + #10;
      sb +=       $'    begin' + #10;
      if bitmask then
      begin
        sb +=     $'      var res := typeof({name}).GetProperties.Where(prop->prop.Name.StartsWith(''HAS_FLAG_'') and boolean(prop.GetValue(self))).Select(prop->prop.Name.TrimStart(''&'')).ToList;' + #10;
        sb +=     $'      Result := res.Count=0?' + #10;
        sb +=     $'        $''{name}[{{ self.val=0 ? ''''NONE'''' : self.val.ToString(''''X'''') }}]'':' + #10;
        sb +=     $'        res.JoinIntoString(''+'');' + #10;
      end else
      begin
        sb +=     $'      var res := typeof({name}).GetProperties(System.Reflection.BindingFlags.Static or System.Reflection.BindingFlags.Public).FirstOrDefault(prop->UInt32(prop.GetValue(self))=self.val);' + #10;
        sb +=     $'      Result := res=nil?' + #10;
        sb +=     $'        $''{name}[{{ self.val=0 ? ''''NONE'''' : self.val.ToString(''''X'''') }}]'':' + #10;
        sb +=     $'        res.Name.TrimStart(''&'');' + #10;
      end;
      sb +=       $'    end;' + #10;
      sb +=       $'    ' + #10;
      
      sb +=       $'  end;'+#10;
      sb +=       $'  ' + #10;
    end;
    public static procedure WriteAll(sb: StringBuilder) :=
    foreach var g in All.GroupBy(gr->gr.ext_name).OrderBy(g->
    begin
      case g.Key of
        '':     Result := 0;
        'ARB':  Result := 1;
        'EXT':  Result := 2;
        else    Result := 3;
      end;
    end).ThenBy(g->g.Key) do
    begin
      var gn := g.Key;
      if gn='' then gn := 'Core';
      
      sb += $'  {{$region {gn}}}'+#10;
      sb += $'  '+#10;
      
      foreach var gr in g.OrderBy(gr->gr.name) do
        gr.Write(sb);
      
      sb += $'  {{$endregion {gn}}}'+#10;
      sb += $'  '+#10;
    end;
    
    public static procedure WarnAllUnused :=
    foreach var gr in All do
      if not LogCache.used_t_names.Contains(gr.name) then
        Otp($'WARNING: Group [{gr.name}] wasn''t used');
    
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
    public readonly: boolean;
    public ptr: integer;
    public gr: Group;
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader; proto: boolean);
    begin
      self.name := br.ReadString;
      if not proto and (self.name.ToLower in unallowed_words) then self.name := '&'+self.name;
      
      var ntv_t := br.ReadString;
      self.t := TypeTable.Convert(ntv_t);
      
      self.readonly := br.ReadBoolean;
      self.ptr := br.ReadInt32 + self.t.Count(ch->ch='*') - self.t.Count(ch->ch='-');
      self.t := self.t.Remove('*','-').Trim;
      if self.ptr<0 then
      begin
        if proto and (ntv_t.ToLower='void') and (ptr=-1) then
          self.t := nil else
          raise new MessageException($'ERROR: par [{name}] with type [{ntv_t}] got negative ref count: [{self.ptr}]');
      end;
      
      var gr_ind := br.ReadInt32;
      self.gr := gr_ind=-1 ? nil : Group.All[gr_ind];
      
    end;
    
    public function GetTName :=
    gr=nil ? t : gr.name;
    
  end;
  FuncParamT = sealed class(System.IEquatable<FuncParamT>)
    public var_arg: boolean;
    public arr_lvl: integer;
    public tname: string;
    
    public constructor(str: string);
    begin
      str := str.Trim;
      
      self.var_arg := str.StartsWith('var ');
      if var_arg then str := str.Substring('var '.Length).Trim;
      
      while str.StartsWith('array of ') do
      begin
        self.arr_lvl += 1;
        str := str.Substring('array of '.Length).Trim;
      end;
      self.tname := str;
    end;
    
    public constructor(var_arg: boolean; arr_lvl: integer; tname: string);
    begin
      self.var_arg := var_arg;
      self.arr_lvl := arr_lvl;
      self.tname   := tname;
    end;
    
    public function ToString(generate_code: boolean; with_var: boolean := false): string;
    begin
      if generate_code then
      begin
        var res := new StringBuilder;
        if with_var and var_arg then res += 'var ';
        loop arr_lvl do res += 'array of ';
        res += tname;
        Result := res.ToString;
      end else
        Result := $'({var_arg}, {arr_lvl}, {tname})';
    end;
    public function ToString: string; override := ToString(false);
    
    public static function operator=(par1,par2: FuncParamT): boolean :=
    (par1.var_arg = par2.var_arg) and
    (par1.arr_lvl = par2.arr_lvl) and
    (par1.tname   = par2.tname  );
    
    public function Equals(other: FuncParamT) := self=other;
    
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
    public constructor(br: System.IO.BinaryReader);
    begin
      org_par := ArrGen(br.ReadInt32, i->new FuncOrgParam(br, i=0));
      BasicInit;
    end;
    
    private static All := new List<Func>;
    private static Used := new HashSet<Func>;
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      All.Capacity := br.ReadInt32;
      loop All.Capacity do All += new Func(br);
    end;
    
    // ": array of possible_par_type_collection"
    // (array_lvl, array_el_type)
    public possible_par_types: array of List<FuncParamT>;
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
            Result := Lst(new FuncParamT(false, 0, 'SByte'));
          end else
            Result := Lst(new FuncParamT(false, 0, par.GetTName)); // (0,nil) for procedure ret par
        end else
        
        // string
        if par.t='ntv_char' then
        begin
          if par_i=0 then
          begin
            Result := Lst(new FuncParamT(false, par.ptr-1, 'string'));
            exit;
          end;
          var res := new List<FuncParamT>(par.ptr+integer(par.readonly));
          
          for var ptr := 0 to par.ptr-1 do
            res += new FuncParamT(false, ptr,       'IntPtr');
          if par.readonly then
            res += new FuncParamT(false, par.ptr-1, 'string');
          
          res.Reverse;
          Result := res;
        end else
        
        // array/var-arg
        begin
          if par_i=0 then
          begin
            Result := Lst(new FuncParamT(false, 0, new string('^',Max(0,par.ptr))+par.GetTName));
            exit;
          end;
          var res := new List<FuncParamT>( Max(3,par.ptr+1) );
          var par_t := par.GetTName;
          
          if par.ptr=1 then
          begin
            res += new FuncParamT(false, 0,
              par_t='IntPtr' ?
                'pointer' :
                'IntPtr'
            );
            res += new FuncParamT(true, 0, par_t);
          end else
          for var ptr := 0 to par.ptr-1 do
            res += new FuncParamT(false, ptr, 'IntPtr');
          
          var ToDo := 0; //ToDo костыль, надо маршлинг нормально настроить
          // но проблема в том, что для "array of boolean" не работает копирование в неуправляемую память
          // очевидное решение - через указатели получить "array of Byte". Только как покрасивше?
          res += new FuncParamT(false, par.ptr,
            (par_t='boolean') and (par.ptr>1) ?
              'Byte' : par_t
          );
          
          res.Reverse;
          Result := res;
        end;
        
      end);
    end;
    
    public all_overloads: List<array of FuncParamT>;
    public procedure InitOverloads;
    begin
      if all_overloads<>nil then exit;
      InitPossibleParTypes;
      
      all_overloads := new List<array of FuncParamT>(
        possible_par_types.Select(types->types.Count).Product
      );
      var overloads := Seq&<sequence of FuncParamT>(Seq&<FuncParamT>());
      
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
    
    public static procedure WriteGetPtrFunc(sb: StringBuilder; api: string);
    begin
      if api='wgl' then exit;
      if api='gdi' then exit;
      sb += '    public static function GetFuncAdr([MarshalAs(UnmanagedType.LPStr)] lpszProc: string): IntPtr;'#10;
      if api='glx' then
        sb += '    external ''opengl32.dll'' name ''glXGetProcAddress'';'#10 else
        sb += '    external ''opengl32.dll'' name ''wglGetProcAddress'';'#10;
      sb += '    public static function GetFuncOrNil<T>(fadr: IntPtr) :='#10;
      sb += '    fadr=IntPtr.Zero ? default(T) :'#10;
      sb += '    Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
    end;
    
    public function MarkUsed: boolean;
    begin
      InitOverloads;
      Result := Used.Add(self);
      if not Result then exit;
      foreach var ovr in all_overloads do
        foreach var par in is_proc ? ovr.Skip(1) : ovr do
          LogCache.used_t_names += par.tname;
    end;
    
    public static prev_func_names := new HashSet<string>;
    public procedure Write(sb: StringBuilder; api, version: string);
    begin
      InitOverloads;
      
      if MarkUsed then
      begin
        
        if not is_proc or (org_par.Length>1) then
        begin
          log_func_ovrs.WriteLine($'# {name}');
          foreach var ovr in all_overloads do
          begin
            foreach var par in is_proc?ovr.Skip(1):ovr do
              log_func_ovrs.Write($' {par.ToString(true,true)}{#9}|');
            log_func_ovrs.WriteLine;
          end;
          log_func_ovrs.WriteLine;
        end;
        
      end;
      
      if all_overloads.Count=0 then
      begin
        Otp($'ERROR: Func [{name}] ended up having 0 overloads. [possible_par_types]: ');
        foreach var par in possible_par_types do
          Otp(_ObjectToString(par));
        exit;
      end;
      if all_overloads.Count>15 then Otp($'WARNING: Too many ({all_overloads.Count}) overloads of func [{name}]');
      
      for var par_i := 1 to org_par.Length-1 do
        if all_overloads.Any(ovr->ovr[par_i].tname.ToLower=org_par[par_i].name.ToLower) then
          org_par[par_i].name := '_' + org_par[par_i].name;
      
      var l_name := name;
      if l_name.ToLower.StartsWith(api) then
        l_name := l_name.Substring(api.Length) else
      if api<>'gdi' then
        log.WriteLine($'Func [{name}] had api [{api}], which isn''t start of it''s name');
      prev_func_names += l_name.ToLower;
      if l_name.ToLower in unallowed_words then l_name := '&'+l_name;
      
      var WriteMarshalAs: (FuncParamT, boolean)->() := (par,res)->
      begin
        if (par.arr_lvl=0) and (par.tname<>'string') then exit;
        sb += '[';
        if res then sb += 'Result: ';
        if par.arr_lvl>0 then
        begin
          sb += 'MarshalAs(UnmanagedType.LPArray';
          if par.arr_lvl>1 then
            sb += ', ArraySubType=UnmanagedType.LPArray' else
          if par.tname='string' then
            sb += ', ArraySubType=UnmanagedType.LPStr';
          sb += ')';
        end else
        if par.tname='string' then
          sb += 'MarshalAs(UnmanagedType.LPStr)';
        sb += '] ';
      end;
      
      var WriteOvrT: procedure(ovr: array of FuncParamT; generic_names: List<string>; name: string; marshals, is_static: boolean) := (ovr,generic_names,name, marshals,is_static)->
      begin
        var use_standart_dt := false; // единственное применение - в "Marshal.GetDelegateForFunctionPointer". Но он их и не принимает
        if use_standart_dt then
        begin
          sb += is_proc ? 'Action' : 'Func';
        end else
        begin
          if marshals then WriteMarshalAs(ovr[0],true);
          if is_static and (name<>nil) then sb += 'static ';
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
              if par.var_arg then sb += 'var ';
              sb += org_par[par_i].name;
              sb += ': ';
            end;
            loop par.arr_lvl do sb += 'array of ';
            if par.tname.ToLower in prev_func_names then sb += 'OpenGL.';
            sb += par.tname;
            sb += use_standart_dt ? ', ' : '; ';
          end;
          sb.Length -= 2; // лишнее '; '
          sb += use_standart_dt ? '>' : ')';
        end;
        
        if not is_proc then
          if use_standart_dt then
          begin
            if ovr.Length>1 then
            begin
              sb.Length -= 1;
              sb += ', ';
            end else
              sb += '<';
            sb += ovr[0].ToString(true);
            sb += '>';
          end else
          begin
            sb += ': ';
            sb += ovr[0].ToString(true);
          end;
        
      end;
      
      var use_external := ((api='gl') and (version<>nil) and (version <= '1.1')) or (api='wgl') or (api='gdi');
      if use_external and (
        true
      ) then
      begin
        
        for var ovr_i := 0 to all_overloads.Count-1 do
        begin
          var ovr := all_overloads[ovr_i];
          
          sb += '    private ';
          WriteOvrT(ovr,nil, $'_z_{l_name.TrimStart(''&'')}_ovr{ovr_i}', true,true);
          sb += ';'#10;
          if api='gdi' then
            sb += $'    external ''gdi32.dll'' name ''{name}'';'+#10 else
            sb += $'    external ''opengl32.dll'' name ''{name}'';'+#10;
          
          sb += $'    public static z_{l_name.TrimStart(''&'')}_ovr{ovr_i}';
          if (org_par.Length=1) and not is_proc then
          begin
            sb += ': ';
            WriteOvrT(ovr,nil, nil, false,false);
          end;
          sb += $' := _z_{l_name.TrimStart(''&'')}_ovr{ovr_i};' + #10;
          
          sb += $'    public [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
          WriteOvrT(ovr,nil, l_name, false,api<>'gl');
          sb += $' := z_{l_name.TrimStart(''&'')}_ovr{ovr_i}';
          if ovr.Length>1 then
          begin
            sb += '(';
            for var par_i := 1 to ovr.Length-1 do
            begin
              sb += org_par[par_i].name;
              sb += ', ';
            end;
            sb.Length -= 2;
            sb += ')';
          end;
          sb += ';'#10;
          
        end;
        
      end else
      begin
        sb += $'    public z_{l_name}_adr := GetFuncAdr(''{name}'');' + #10;
        var PrevNtvOvrs := new List<array of FuncParamT>(all_overloads.Count);
        
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
            var res_var_arg := par.var_arg;
            var res_t := par.tname;
            
            if par_i=0 then
            begin
              if is_proc then
              begin
                Result := new FuncParamT(false,0,nil);
                exit;
              end;
              
              // нельзя определить размер массива в результате
              if par.arr_lvl<>0 then raise new System.NotSupportedException;
              var relevant_par_name := 'Result';
              
              if par.tname='string' then
              begin
                var str_ptr_name := $'par_{par_i}_str_ptr';
                
                finl += $'{relevant_par_name} := Marshal.PtrToStringAnsi({str_ptr_name});';
                // Marshal.FreeHGlobal не нужно, потому что строка в возвращаемом значении - всегда статичная строка
                
                par_strs[par_i] := str_ptr_name;
                relevant_par_name := str_ptr_name;
                res_t := 'IntPtr';
              end;
              
              if relevant_par_name<>'Result' then relevant_par_name := 'var '+relevant_par_name;
              par_strs[par_i] := relevant_par_name;
            end else
            begin
              var relevant_par_name := org_par[par_i].name;
              
              var sres_t := res_t;
              var generic := (res_t<>nil) and sres_t.StartsWith('T') and sres_t.Skip(1).All(ch->ch.IsDigit);
              if generic then
                if par.arr_lvl=0 then
                begin
                  relevant_par_name := $'PByte(pointer(@{relevant_par_name}))^';
                  res_var_arg := true;
                  res_t := 'Byte';
                  all_generic_names += sres_t;
                end else
                begin
                  generic_inds += par_i;
                  temp_generic_names += sres_t;
                  all_generic_names += sres_t;
                  res_t := 'Byte';
                end;
              
              if par.tname='string' then
              begin
                var str_ptr_arr_name := $'par_{par_i}_str_ptr';
                
                var str_ptr_arr_init := new StringBuilder;
                str_ptr_arr_init += $'var {str_ptr_arr_name} := ';
                var prev_arr_name := relevant_par_name;
                for var i := 1 to par.arr_lvl do
                begin
                  var new_arr_name := $'arr_el{i}';
                  str_ptr_arr_init += $'{prev_arr_name}.ConvertAll({new_arr_name}->';
                  prev_arr_name := new_arr_name;
                end;
                str_ptr_arr_init += $'Marshal.StringToHGlobalAnsi({prev_arr_name})';
                str_ptr_arr_init.Append(')',par.arr_lvl);
                str_ptr_arr_init += ';';
                init += str_ptr_arr_init.ToString;
                
                var str_ptr_arr_finl := new StringBuilder;
                prev_arr_name := str_ptr_arr_name;
                for var i := 1 to par.arr_lvl do
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
              
              if par.arr_lvl>1 then
                for var temp_arr_i := par.arr_lvl-1 downto 1 do
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
              
              if par.arr_lvl<>0 then
              begin
                res_var_arg := true;
                par_strs[par_i] := $'{relevant_par_name}[0]';
              end else
                par_strs[par_i] := relevant_par_name;
              
            end;
            
            Result := new FuncParamT(res_var_arg, 0, res_t);
          end);
          
          var same_ntv_ovr_ind := PrevNtvOvrs.FindIndex(pntv_ovr->(pntv_ovr<>nil) and pntv_ovr.SequenceEqual(ntv_ovr));
          var z_ovr_name: string;
          if same_ntv_ovr_ind=-1 then
          begin
            z_ovr_name := $'z_{l_name}_ovr_{ovr_i}';
            PrevNtvOvrs += ntv_ovr;
            
            sb += $'    public {z_ovr_name} := GetFuncOrNil&<';
            WriteOvrT(ntv_ovr,nil, nil, false,false);
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
              Result := g_ind=-1 ? par : new FuncParamT(true, par.arr_lvl, temp_generic_names[g_ind]);
            end),temp_generic_names, temp_z_ovr_name, false,false);
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
          WriteOvrT(ovr,all_generic_names, l_name, false,false);
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
    
    public static procedure WarnAllUnused :=
    foreach var f in All do
      if not Used.Contains(f) then
        Otp($'WARNING: Func [{f.name}] wasn''t used');
    
  end;
  FuncFixer = abstract class(Fixer<FuncFixer, Func>)
    
    public static constructor;
    
    protected procedure WarnUnused; override :=
    Otp($'WARNING: Fixer of func [{self.name}] wasn''t used');
    
  end;
  
  {$endregion Func}
  
  {$region FuncContainers}
  
  Feature = sealed class
    public api: string;
    public version: string;
    public add: List<Func>;
    public rem: List<Func>;
    
    public constructor(br: System.IO.BinaryReader);
    begin
      api := br.ReadString;
      version := ArrGen(br.ReadInt32, i->br.ReadInt32).JoinToString('.');
      add := ArrGen(br.ReadInt32, i->Func.All[br.ReadInt32]).ToList;
      rem := ArrGen(br.ReadInt32, i->Func.All[br.ReadInt32]).ToList;
      
      if not (api in ['gl','wgl','glx']) then raise new System.NotSupportedException;
      
    end;
    
    public static ByApi := new Dictionary<string, List<Feature>>;
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      loop br.ReadInt32 do
      begin
        var f := new Feature(br);
        
        var lst: List<Feature>;
        if not ByApi.TryGetValue(f.api, lst) then
        begin
          lst := new List<Feature>;
          ByApi[f.api] := lst;
        end;
        lst += f;
        
      end;
    end;
    
    public static procedure FixGL_GDI;
    begin
      ByApi['gdi'] := new List<Feature>;
      var gdi := new Feature;
      gdi.version := '';
      gdi.add := new List<Func>;
      gdi.rem := new List<Func>;
      ByApi['gdi'].Add(gdi);
      
      foreach var f in ByApi['wgl'] do
        f.add.RemoveAll(fnc->
        begin
          Result := not fnc.name.StartsWith('wgl');
          if Result then gdi.add += fnc;
        end);
      
    end;
    
    public static procedure WriteAll(sb: StringBuilder) :=
    foreach var api in Feature.ByApi.Keys do
    begin
      if api='glx' then
      begin
        foreach var ftr in Feature.ByApi[api] do
          foreach var f in ftr.add do
            f.MarkUsed;
        continue; //ToDo Требует бОльшего тестирования. В расширениях тоже такое стоит
      end;
      
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
      
      var class_type := api='gl' ? 'sealed' : 'static';
      
      sb += $'  {api} = {class_type} class'+#10;
      Func.WriteGetPtrFunc(sb, api);
      sb += $'    '+#10;
      
      foreach var f in all_funcs.Keys.OrderBy(f->f.name) do
        if not deprecated.ContainsKey(f) then
        begin
          if api<>'gdi' then
            sb += $'    // added in {api}{all_funcs[f]}'+#10;
          f.Write(sb, api, all_funcs[f]);
        end;
      
      Func.prev_func_names.Clear;
      sb += $'  end;'+#10;
      sb += $'  '+#10;
      
      if not deprecated.Any then continue;
      sb += $'  {api}D = {class_type} class'+#10;
      Func.WriteGetPtrFunc(sb, api);
      sb += $'    '+#10;
      
      foreach var f in all_funcs.Keys.Where(f->deprecated.ContainsKey(f)).OrderBy(f->f.name) do
      begin
        if api<>'gdi' then
          sb += $'    // added in {api}{all_funcs[f]}, deprecated in {api}{deprecated[f]}'+#10;
        f.Write(sb, api, all_funcs[f]);
      end;
      
      Func.prev_func_names.Clear;
      sb += $'  end;'+#10;
      sb += $'  '+#10;
    end;
    
  end;
  Extension = sealed class
    public name: string;
    public api: string;
    public ext_group: string;
    public add: List<Func>;
    
    public constructor(br: System.IO.BinaryReader);
    begin
      name := br.ReadString;
      api := br.ReadString;
      add := ArrGen(br.ReadInt32, i->Func.All[br.ReadInt32]).ToList;
      
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
    
    private static All := new List<Extension>;
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      All.Capacity := br.ReadInt32;
      loop All.Capacity do All += new Extension(br);
    end;
    
    public procedure Write(sb: StringBuilder);
    begin
      if add.Count=0 then exit;
      if api='glx' then
      begin
        foreach var f in add do
          f.MarkUsed;
        exit; //ToDo Требует бОльшего тестирования. В фичах ядра тоже такое стоит
      end;
      
      var display_name := api+name.Split('_').Select(w->
      begin
        if w.Length<>0 then w[1] := w[1].ToUpper;
        Result := w;
      end).JoinToString('') + ext_group;
      
      sb += $'  {display_name} = ';
      sb += api='gl' ? 'sealed' : 'static';
      sb += ' class'#10;
      Func.WriteGetPtrFunc(sb, api);
      sb += $'    '+#10;
      
      foreach var f in add do
        f.Write(sb, api, nil);
      Func.prev_func_names.Clear;
      sb += $'  end;'+#10;
      sb += $'  '+#10;
    end;
    
    public static procedure WriteAll(sb: StringBuilder);
    begin
      sb += '  {region Extensions}'#10;
      sb += '  '#10;
      foreach var ext in All do ext.Write(sb);
      sb += '  {endregion Extensions}'#10;
      sb += '  '#10;
    end;
    
  end;
  
  {$endregion FuncContainers}
  
procedure InitAll;
procedure LoadBin;
procedure ApplyFixers;
procedure FinishAll;

implementation

{$region Misc}

procedure InitAll;
begin
  
  unallowed_words :=
    ReadLines(GetFullPath('..\MiscInput\UnAllowedWords.dat',GetEXEFileName))
    .Where(l->not string.IsNullOrWhiteSpace(l))
    .Select(l->l.ToLower)
    .ToHashSet
  ;
  
  loop 3 do log_func_ovrs.WriteLine;
  
end;

procedure LoadBin;
begin
  var br := new System.IO.BinaryReader(System.IO.File.OpenRead('DataScraping\XML\GL\funcs.bin'));
  Group.LoadAll(br);
  Func.LoadAll(br);
  Feature.LoadAll(br);
  Extension.LoadAll(br);
  if br.BaseStream.Position<>br.BaseStream.Length then raise new System.FormatException;
end;

procedure ApplyFixers;
begin
  GroupFixer.ApplyAll(Group.All);
  FuncFixer.ApplyAll(Func.All);
end;

procedure FinishAll;
begin
  
  TypeTable.WarnUnused;
  GroupFixer.WarnAllUnused;
  FuncFixer.WarnAllUnused;
  
  Group.WarnAllUnused;
  Func.WarnAllUnused;
  
  loop 1 do log_func_ovrs.WriteLine;
  
  log.Close;
  log_func_ovrs.Close;
  
end;

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

{$endregion Misc}

{$region GroupFixer}

type
  GroupAdder = sealed class(GroupFixer)
    private name, t: string;
    private bitmask: boolean;
    private enums := new Dictionary<string, int64>;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(nil);
      self.name := name;
      var enmr := data.Where(l->not string.IsNullOrWhiteSpace(l)).GetEnumerator;
      
      if not enmr.MoveNext then raise new System.FormatException;
      t := enmr.Current;
      
      if not enmr.MoveNext then raise new System.FormatException;
      bitmask := boolean.Parse(enmr.Current);
      
      while enmr.MoveNext do
      begin
        var t := enmr.Current.Split('=');
        var key := t[0].Trim;
        var val := t[1].Trim;
        enums.Add(key, val.StartsWith('0x') ?
          System.Convert.ToInt64(val, 16) :
          System.Convert.ToInt64(val)
        );
      end;
      
      self.RegisterAsAdder;
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      gr.name     := self.name;
      gr.t        := self.t;
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
  foreach var gr in fls.SelectMany(fname->GroupFixer.ReadBlocks(fname,true)) do
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
    public old_tname: FuncParamT;
    public new_tnames: array of FuncParamT;
    
    public constructor(name: string; data: string);
    begin
      inherited Create(name);
      var s := data.Split('=');
      old_tname := new FuncParamT( s[0] );
      new_tnames := s[1].Split('|').ConvertAll(par->new FuncParamT(par));
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
            begin
              Otp($'ERROR: Not enough {_ObjectToString(new_tnames)} replacement type for {old_tname} in [FuncReplParTFixer] of func [{f.name}]');
              exit;
            end;
            par[i] := new_tnames[tn_id];
            tn_id += 1;
          end;
      if tn_id<>new_tnames.Length then
      begin
        Otp($'ERROR: Only {tn_id}/{new_tnames.Length} [new_tnames] of [FuncReplParTFixer] of func [{f.name}] were used');
        exit;
      end;
      
      self.used := true;
      Result := false;
    end;
    
  end;
  FuncPPTFixer = sealed class(FuncFixer)
    public add_ts: array of List<FuncParamT>;
    public rem_ts: array of List<FuncParamT>;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      var s := data.Single(l->not string.IsNullOrWhiteSpace(l)).Split('|');
      var par_c := s.Length-1;
      if not string.IsNullOrWhiteSpace(s[par_c]) then raise new System.FormatException(s.JoinToString('|'));
      
      SetLength(add_ts, par_c);
      SetLength(rem_ts, par_c);
      
      var res := new StringBuilder;
      for var i := 0 to par_c-1 do
      begin
        add_ts[i] := new List<FuncParamT>;
        rem_ts[i] := new List<FuncParamT>;
        
        var curr_lst: List<FuncParamT> := nil;
        var seal_t: ()->() := ()->
        begin
          var t := res.ToString.Trim;
          if (t<>'') and (t<>'*') then curr_lst += new FuncParamT(t);
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
      
      var ind_nudge := integer(f.is_proc);
      if add_ts.Length<>f.org_par.Length-ind_nudge then
        raise new MessageException($'ERROR: [FuncPPTFixer] of func [{f.name}] had wrong param count');
      
      for var i := 0 to add_ts.Length-1 do
      begin
        foreach var t in rem_ts[i] do
          if not f.possible_par_types[i+ind_nudge].Remove(t) then
            Otp($'ERROR: [FuncPPTFixer] of func [{f.name}] failed to remove type [{t}] of param #{i} {_ObjectToString(f.possible_par_types[i+ind_nudge])}');
        foreach var t in add_ts[i] do
          if f.possible_par_types[i+ind_nudge].Contains(t) then
            Otp($'ERROR: [FuncPPTFixer] of func [{f.name}] failed to add type [{t}] to param #{i}') else
            f.possible_par_types[i+ind_nudge] += t;
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
    public ovr: array of FuncParamT;
    
    public constructor(name: string; data: string);
    begin
      inherited Create(name);
      
      var s := data.Split('|');
      if not string.IsNullOrWhiteSpace(s[s.Length-1]) then raise new System.FormatException(data);
      
      SetLength(ovr, s.Length-1);
      ovr.Fill(i->new FuncParamT(s[i]));
      
    end;
    
    public static function PrepareOvr(add_void: boolean; ovr: array of FuncParamT): array of FuncParamT;
    begin
      if add_void then
      begin
        var res: array of FuncParamT;
        SetLength(res, ovr.Length+1);
        res[0] := new FuncParamT(false,0,nil);
        ovr.CopyTo(res,1);
        Result := res;
      end else
        Result := ovr;
    end;
    
    public function OvrInd(lst: List<array of FuncParamT>; ovr: array of FuncParamT) :=
    lst.FindIndex(povr->povr.SequenceEqual(ovr));
    
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
      if f.org_par.Length<>povr.Length then
        raise new MessageException($'ERROR: [FuncAddOvrsFixer] of func [{self.name}] had wrong param count: {f.org_par.Length} org vs {povr.Length} custom');
      
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
      if f.org_par.Length<>povr.Length then
        raise new MessageException($'ERROR: [FuncRemOvrsFixer] of func [{self.name}] had wrong param count: {f.org_par.Length} org vs {povr.Length} custom');
      
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
  foreach var gr in fls.SelectMany(fname->GroupFixer.ReadBlocks(fname,true)) do
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