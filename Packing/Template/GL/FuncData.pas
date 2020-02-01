unit FuncData;

interface

uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

var log, func_ovrs_log: System.IO.StreamWriter;

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
    
    public procedure Write(sb: StringBuilder; api, version: string);
    begin
      InitOverloads;
      
      if not is_proc or (org_par.Length>1) then
      begin
        func_ovrs_log.WriteLine($'# {name}');
        foreach var ovr in all_overloads do
        begin
          foreach var par in is_proc?ovr.Skip(1):ovr do
            func_ovrs_log.Write($' {par[0]*''array of ''}{par[1]} |');
          func_ovrs_log.WriteLine;
        end;
        func_ovrs_log.WriteLine;
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
      
      var WriteOvrT: procedure(ovr: array of (integer,string); name: string; marshals: boolean) := (ovr,name,marshals)->
      begin
        if marshals then WriteMarshalAs(ovr[0],true);
        sb += is_proc ? 'procedure' : 'function';
        if name<>nil then
        begin
          sb += ' ';
          sb += name;
        end;
        
        if ovr.Length>1 then
        begin
          sb += '(';
          for var par_i := 1 to ovr.Length-1 do
          begin
            var par := ovr[par_i];
            if marshals then WriteMarshalAs(par,false);
            if par[1].StartsWith('var!') then sb += 'var ';
            sb += org_par[par_i].name;
            sb += ': ';
            loop par[0] do sb += 'array of ';
            sb += par[1].Split('!').Last;
            sb += '; ';
          end;
          sb.Length -= 2; // лишнее '; '
          sb += ')';
        end;
        
        if not is_proc then
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
          WriteOvrT(ovr, $'z_{l_name}', true);
          sb += ';'#10;
          sb += $'    external ''opengl32.dll'' name ''{name}'';'+#10;
          
          sb += $'    public [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
          WriteOvrT(ovr, l_name, false);
          sb += $' := z_{l_name};'+#10;
          
        end;
        
      end else
      begin
        sb += $'    public z_{l_name}_adr := GetFuncAdr(''{name}'');' + #10;
        var PrevNtvOvrs := new List<array of (integer,string)>(all_overloads.Count);
        
        for var ovr_i := 0 to all_overloads.Count-1 do
        begin
          var ovr := all_overloads[ovr_i];
          
          //ToDo для этого нужна отдельная перегрузка, принимающая "var a: T" и вызывающая "var a: byte"
          var generic_inds := new List<integer>;
          
          var init := new List<string>;
          var finl := new List<string>;
          var par_strs := new string[ovr.Length];
          
          var ntv_ovr := ovr.ConvertAll((par,par_i)->
          begin
            var res_t := par[1];
            var generic := (res_t<>nil) and res_t.StartsWith('T') and res_t.Skip(1).All(ch->ch.IsDigit);
            if generic then generic_inds += par_i;
            
            // шаблоны работают только для элементов массивов
            if generic and (par[0]=0) then raise new System.NotSupportedException;
            
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
            WriteOvrT(ntv_ovr, nil, false);
            sb += $'>(z_{l_name}_adr);'+#10;
            
          end else
          begin
            z_ovr_name := $'z_{l_name}_ovr_{same_ntv_ovr_ind}';
            PrevNtvOvrs.Add(nil);
          end;
          
          sb += '    public [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
          WriteOvrT(ovr, l_name, false);
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
    
    public procedure Write(sb: StringBuilder);
    begin
      
      var ToDo := 0;
      
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

{$endregion Misc}

{$region GroupFixer}

type
  GroupFixerContainer = sealed class(GroupFixer)
    private fixers: array of GroupFixer;
    public constructor(name: string; fixers: sequence of GroupFixer);
    begin
      inherited Create(name);
      self.fixers := fixers.ToArray;
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
//      Result := fixers.Any(f->f.Apply(gr)); //ToDo #2197
      
      foreach var f in fixers do
        if f.Apply(gr) then
        begin
          Result := true;
          exit;
        end;
      
    end;
    
  end;
  InternalGroupFixer = abstract class(GroupFixer)
    
    public constructor :=
    inherited Create(nil);
    
  end;
  
  GroupAdder = sealed class(InternalGroupFixer)
    private name: string;
    private bitmask: boolean;
    private enums := new Dictionary<string, int64>;
    
    public constructor(name: string; data: sequence of string);
    begin
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
      
      GroupFixer.adders.Add( self );
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      gr.name     := self.name;
      gr.bitmask  := self.bitmask;
      gr.enums    := self.enums;
      gr.FinishInit;
      Result := false;
    end;
    
  end;
  GroupRemover = sealed class(InternalGroupFixer)
    
    public constructor(data: sequence of string) :=
    if data.Any(l->not string.IsNullOrWhiteSpace(l)) then raise new System.FormatException;
    
    public function Apply(gr: Group): boolean; override := true;
    
  end;
  
  GroupNameFixer = sealed class(InternalGroupFixer)
    public new_name: string;
    
    public constructor(data: sequence of string) :=
    self.new_name := data.Single(l->not string.IsNullOrWhiteSpace(l));
    
    public function Apply(gr: Group): boolean; override;
    begin
      gr.name := new_name;
      Result := false;
    end;
    
  end;
  
static constructor GroupFixer.Create;
begin
  empty := new GroupFixerContainer(nil, new GroupFixer[0]);
  
  var fls := System.IO.Directory.EnumerateFiles(GetFullPath('..\Fixers\Enums', GetEXEFileName), '*.dat');
  foreach var gr in fls.SelectMany(fname->GroupFixer.ReadBlocks(fname)) do
  begin
    var ToDo2196 := 0; //ToDo #2196
    
    new GroupFixerContainer(gr[0],
      ReadBlocks(gr[1],'!')
      .Select(bl->
      begin
        var res: GroupFixer;
        
        case bl[0] of
          
          'add': new GroupAdder(gr[0], bl[1]);
          'remove': res := new GroupRemover(bl[1]);
          
          'rename': res := new GroupNameFixer(bl[1]);
          
          else raise new MessageException($'Invalid group fixer type [!{bl[0]}] for group [{gr[0]}]');
        end;
        
        Result := res;
      end)
      .Where(f->f<>nil)
    );
    
  end;
  
end;

{$endregion GroupFixer}

{$region FuncFixer}

type
  FuncFixerContainer = sealed class(FuncFixer)
    private fixers: array of FuncFixer;
    public constructor(name: string; fixers: sequence of FuncFixer);
    begin
      inherited Create(name);
      self.fixers := fixers.ToArray;
    end;
    
    public function Apply(fnc: Func): boolean; override;
    begin
//      Result := fixers.Any(f->f.Apply(gr)); //ToDo #2197
      
      foreach var f in fixers do
        if f.Apply(fnc) then
        begin
          Result := true;
          exit;
        end;
      
    end;
    
  end;
  InternalFuncFixer = abstract class(FuncFixer)
    
    public constructor :=
    inherited Create(nil);
    
    static function ToTName(tname: string): (integer, string);
    begin
      tname := tname.Trim;
      var c := 0;
      while tname.StartsWith('array of') do
      begin
        c += 1;
        tname := tname.Substring('array of'.Length).Trim;
      end;
      Result := (c,tname);
    end;
    
  end;
  
  FuncAdder = sealed class(InternalFuncFixer)
    public org_par := new List<FuncOrgParam>;
    
    public constructor(name: string; data: sequence of string);
    begin
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
      
      FuncFixer.adders.Add( self );
    end;
    
    public function Apply(f: Func): boolean; override;
    begin
      f.org_par := self.org_par.ToArray;
      f.BasicInit;
      Result := false;
    end;
    
  end;
  FuncRemover = sealed class(InternalFuncFixer)
    
    public constructor(data: sequence of string) :=
    if data.Any(l->not string.IsNullOrWhiteSpace(l)) then raise new System.FormatException;
    
    public function Apply(f: Func): boolean; override := true;
    
  end;
  
  FuncReplParTFixer = sealed class(InternalFuncFixer)
    public old_tname: (integer,string);
    public new_tnames: array of (integer,string);
    
    public constructor(data: sequence of string);
    begin
      var s := data.Single(l->not string.IsNullOrWhiteSpace(l)).Split('=');
      old_tname := ToTName( s[0] );
      new_tnames := s[1].Split('|').ConvertAll(ToTName);
    end;
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitPossibleParTypes;
      
      if new_tnames.Length=1 then
      begin
        foreach var par in f.possible_par_types do
          for var i := 0 to par.Count-1 do
            if par[i]=old_tname then
              par[i] := new_tnames[0];
      end else
      begin
        var tn_id := 0;
        foreach var par in f.possible_par_types do
          for var i := 0 to par.Count-1 do
            if par[i]=old_tname then
            begin
              par[i] := new_tnames[tn_id];
              tn_id += 1;
            end;
        if tn_id<>new_tnames.Length then
          raise new MessageException($'ERROR: Only {tn_id}/{new_tnames.Length} [new_tnames] of [FuncReplParTFixer] of func [{f.name}] were used');
      end;
      
      Result := false;
    end;
    
  end;
  FuncPPTFixer = sealed class(InternalFuncFixer)
    public add_ts: array of List<(integer,string)>;
    public rem_ts: array of List<(integer,string)>;
    
    public constructor(data: sequence of string);
    begin
      var s := data.Single(l->not string.IsNullOrWhiteSpace(l)).Split('|');
      var par_c := s.Length-1;
      if s[par_c].Trim<>'' then raise new System.FormatException;
      
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
      
      Result := false;
    end;
    
  end;
  
  FuncClearOvrsFixer = sealed class(InternalFuncFixer)
    
    public constructor(data: sequence of string);
    begin
      if data.Any(l->not string.IsNullOrWhiteSpace(l)) then raise new System.FormatException;
    end;
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      f.all_overloads.Clear;
      Result := false;
    end;
    
  end;
  FuncOvrsFixerBase = abstract class(InternalFuncFixer)
    public overloads := new List<array of (integer,string)>;
    
    public constructor(data: sequence of string);
    begin
      foreach var l in data do
      begin
        if string.IsNullOrWhiteSpace(l) then continue;
        var s := l.Split('|');
        if s[s.Length-1].Trim<>'' then raise new System.FormatException;
        var ovr: array of (integer,string) := nil;
        SetLength(ovr, s.Length-1);
        ovr.Fill(i->ToTName(s[i]));
        overloads += ovr;
      end;
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
    
    public function OvrInd(lst: List<array of (integer,string)>; ovr: array of (integer,string); fn: string): integer;
    begin
      Result := -1;
      if lst.Count=0 then exit;
      if lst[0].Length<>ovr.Length then
        raise new MessageException($'ERROR: [{self.GetType}] of func [{fn}] had wrong param count: {lst[0].Length} org vs {ovr.Length} custom');
      Result := lst.FindIndex(povr->povr.SequenceEqual(ovr));
    end;
    
  end;
  FuncAddOvrsFixer = sealed class(FuncOvrsFixerBase)
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      
      foreach var ovr in overloads.Select(ovr-> PrepareOvr(f.is_proc,ovr) ) do
        if OvrInd(f.all_overloads, ovr, f.name)<>-1 then
          Otp($'ERROR: [FuncAddOvrsFixer] of func [{f.name}] failed to add overload [{ovr.JoinToString}]') else
          f.all_overloads += ovr;
        
      Result := false;
    end;
    
  end;
  FuncRemOvrsFixer = sealed class(FuncOvrsFixerBase)
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      
      foreach var ovr in overloads.Select(ovr-> PrepareOvr(f.is_proc,ovr) ) do
      begin
        var ind := OvrInd(f.all_overloads, ovr, f.name);
        if ind=-1 then
          Otp($'ERROR: [FuncRemOvrsFixer] of func [{f.name}] failed to remove overload [{ovr.JoinToString}]') else
          f.all_overloads.RemoveAt(ind);
      end;
      
      
      Result := false;
    end;
    
  end;
  
static constructor FuncFixer.Create;
begin
  empty := new FuncFixerContainer(nil, new FuncFixer[0]);
  
  var fls := System.IO.Directory.EnumerateFiles(GetFullPath('..\Fixers\Funcs', GetEXEFileName), '*.dat');
  foreach var gr in fls.SelectMany(fname->FuncFixer.ReadBlocks(fname)) do
  begin
    var ToDo2196 := 0; //ToDo #2196
    
    new FuncFixerContainer(gr[0],
      ReadBlocks(gr[1],'!')
      .Select(bl->
      begin
        var res: FuncFixer;
        
        case bl[0] of
          
          'add': new FuncAdder(gr[0], bl[1]);
          'remove': res := new FuncRemover(bl[1]);
          
          'repl_par_t':         res := new FuncReplParTFixer(bl[1]);
          'possible_par_types': res := new FuncPPTFixer(bl[1]);
          'clear_ovrs':         res := new FuncClearOvrsFixer(bl[1]);
          'add_ovrs':           res := new FuncAddOvrsFixer(bl[1]);
          'rem_ovrs':           res := new FuncRemOvrsFixer(bl[1]);
          
          else raise new MessageException($'Invalid func fixer type [!{bl[0]}] for func [{gr[0]}]');
        end;
        
        Result := res;
      end)
      .Where(f->f<>nil)
    );
    
  end;
  
end;

{$endregion FuncFixer}

end.