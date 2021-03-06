﻿unit FuncData;

interface

uses POCGL_Utils  in '..\..\POCGL_Utils';
uses PackingUtils;

uses AOtp         in '..\..\Utils\AOtp';
uses Fixers       in '..\..\Utils\Fixers';

{$string_nullbased+}

{$region Log and Misc}

var log := new FileLogger(GetFullPathRTA('Log\Funcs.log')) +
           new FileLogger(GetFullPathRTA('Log\Funcs (Timed).log'), true);
var log_groups    := new FileLogger(GetFullPathRTA('Log\FinalGroups.log'));
var log_structs   := new FileLogger(GetFullPathRTA('Log\FinalStructs.log'));
var log_func_ovrs := new FileLogger(GetFullPathRTA('Log\FinalFuncOverloads.log'));

type
  LogCache = static class
    static invalid_ext_names  := new HashSet<string>;
    static invalid_ntv_types  := new HashSet<string>;
    static loged_ffo          := new HashSet<string>; // final func ovrs
  end;
  
var allowed_ext_names: HashSet<string>;
function GetExt(s: string): string;
function GetDllNameForAPI(api: string): string;

var api_name: string := nil;

{$endregion Log and Misc}

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
    
    public static procedure WarnAllUnused :=
    foreach var ntv_t in All.Keys do
      if not Used.Contains(ntv_t) then
        Otp($'WARNING: TypeTable key [{ntv_t}] wasn''t used');
    
  end;
  
  {$endregion TypeTable}
  
  {$region Group}
  
  //ToDo #2264
  // - сделать конструктор, принемающий фиксер
//  GroupFixer = class;
  Group = sealed class
    public name, t: string;
    public bitmask: boolean;
    public enums: Dictionary<string, int64>;
    
    public ext_name: string;
    public screened_enums: Dictionary<string,string>;
    
    public custom_members := new List<array of string>;
    
    public procedure FinishInit;
    begin
      
      ext_name := GetExt(name);
      
      screened_enums := new Dictionary<string, string>;
      foreach var key in enums.Keys do
        screened_enums.Add(key, key.ToLower in pas_keywords ? '&'+key : key);
      
    end;
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader);
    begin
      
      name := br.ReadString;
      t := TypeTable.Convert(br.ReadString);
      if TypeTable.All.ContainsKey(name) then
        Otp($'ERROR: Record name [{name}] in TypeTable') else
        TypeTable.All.Add(name, name);
      TypeTable.Used += name;
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
    private static ByName: Dictionary<string, Group> := nil;
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      All.Capacity := br.ReadInt32;
      loop All.Capacity do All += new Group(br);
    end;
    
    public static procedure FixCL_Names :=
    foreach var gr in All do
      if gr.name.StartsWith('cl_') then
        gr.name := gr.name.ToWords('_').Skip(1).Select(w->
        begin
          w[0] := w[0].ToUpper;
          Result := w;
        end).JoinToString('');
    
    public used := false;
    public explicit_existence := false;
    public procedure MarkUsed;
    begin
      if used then exit;
      used := true;
    end;
    public static procedure MarkUsed(name: string);
    begin
      if ByName=nil then ByName := All.ToDictionary(gr->gr.name);
      var res: Group;
      if ByName.TryGetValue(name, res) then
        res.MarkUsed;
    end;
    
    private function EnumrKeys := enums.Keys.OrderBy(ename->Abs(enums[ename])).ThenBy(ename->ename);
    private property ValueStr[ename: string]: string read not bitmask and (enums[ename]<0) ? enums[ename].ToString : '$'+enums[ename].ToString('X4');
    
    public static procedure WarnAllUnused :=
    foreach var gr in All do
      if not gr.used then
        if gr.explicit_existence then
          Otp($'WARNING: Group [{gr.name}] was explicitly added, but wasn''t used') else
          log.Otp($'Group [{gr.name}] was skipped');
    
    public procedure Write(sb: StringBuilder);
    begin
      log_groups.Otp($'# {name}[{t}]');
      foreach var ename in enums.Keys do
        log_groups.Otp($'{#9}{ename} = {enums[ename]:X}');
      log_groups.Otp('');
      
      if not used then exit;
      
      if enums.Count=0 then Otp($'WARNING: Group [{name}] had 0 enums');
      var max_scr_w := screened_enums.Values.DefaultIfEmpty('').Max(ename->ename.Length);
      sb +=       $'  {name} = record' + #10;
      
      sb +=       $'    public val: {t};' + #10;
      sb +=       $'    public constructor(val: {t}) := self.val := val;' + #10;
      if t = 'IntPtr' then
        sb +=     $'    public constructor(val: Int32) := self.val := new {t}(val);' + #10;
      sb +=       $'    ' + #10;
      
      foreach var ename in EnumrKeys do
        sb +=     $'    public static property {screened_enums[ename]}:{'' ''*(max_scr_w-screened_enums[ename].Length)} {name} read new {name}({ValueStr[ename]});' + #10;
      sb +=       $'    ' + #10;
      
      if bitmask then
      begin
        
        sb +=     $'    public static function operator+(f1,f2: {name}) := new {name}(f1.val or f2.val);' + #10;
        sb +=     $'    public static function operator or(f1,f2: {name}) := f1+f2;' + #10;
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
        sb +=     $'      var res := new StringBuilder;'+#10;
      foreach var ename in EnumrKeys do
      begin
        sb +=     $'      if self.val ';
        var val_str := ValueStr[ename];
        if bitmask then sb += $'and {t}({val_str}) ';
        sb += $'= {t}({val_str}) then ';
        if bitmask then
          sb +=   $'res += ''{ename}+'';' else
          sb +=   $'Result := ''{ename}'' else';
        sb += #10;
      end;
      if bitmask then
      begin
        sb +=     $'      if res.Length<>0 then'+#10;
        sb +=     $'      begin'+#10;
        sb +=     $'        res.Length -= 1;'+#10;
        sb +=     $'        Result := res.ToString;'+#10;
        sb +=     $'      end else'+#10;
      end;
      sb +=       $'        Result := $''{name}[{{self.val}}]'';'+#10;
      sb +=       $'    end;' + #10;
      sb +=       $'    ' + #10;
      
      foreach var m in custom_members do
      begin
        foreach var l in m do
          sb +=   $'    {l}' + #10;
        sb +=     $'    ' + #10;
      end;
      
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
      if not g.Any(gr->gr.used) then continue;
      
      sb += $'  {{$region {gn}}}'+#10;
      sb += $'  '+#10;
      
      foreach var gr in g.OrderBy(gr->gr.name) do
        gr.Write(sb);
      
      sb += $'  {{$endregion {gn}}}'+#10;
      sb += $'  '+#10;
    end;
    
  end;
  GroupFixer = abstract class(Fixer<GroupFixer, Group>)
    
    public static procedure InitAll;
    
    protected procedure WarnUnused(all_unused_for_name: List<GroupFixer>); override :=
    Otp($'WARNING: {all_unused_for_name.Count} fixers of group [{self.name}] wasn''t used');
    
  end;
  
  {$endregion Group}
  
  {$region Struct}
  
  StructField = sealed class
    public name, t: string;
    public rep_c: int64 := 1;
    public ptr: integer;
    public gr: Group;
    
    public vis := 'public';
    public def_val: string := nil;
    public comment: string := nil;
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader);
    begin
      self.name := br.ReadString;
      self.t := TypeTable.Convert(br.ReadString);
      self.rep_c := br.ReadInt64;
      
      if br.ReadBoolean then raise new System.NotSupportedException; // readonly
      
      self.ptr := br.ReadInt32 - self.t.Count(ch->ch='-');
      if self.ptr<0 then raise new System.InvalidOperationException;
//      if self.ptr>0 then raise new System.NotSupportedException(name); // cl_dx9_surface_info_khr содержит поле-указатель
      self.t := self.t.Remove('-').Trim;
      
      // static_arr_len
      if br.ReadInt32 <> -1 then raise new System.NotSupportedException;
      
      var gr_ind := br.ReadInt32;
      self.gr := gr_ind=-1 ? nil : Group.All[gr_ind];
    end;
    
    public procedure FixT :=
    if gr<>nil then
    begin
      self.t := gr.name;
      self.gr := nil;
    end;
    
    public function MakeDef: string;
    begin
      var res := new StringBuilder;
      res += name;
      res += ': ';
      res.Append('^',ptr);
      res += t;
      Result := res.ToString;
    end;
    
    public procedure Write(sb: StringBuilder);
    begin
      sb += '    ';
      if name<>nil then
      begin
        sb += vis;
        sb += ' ';
        sb += self.MakeDef;
        if def_val<>nil then
        begin
          sb += ' := ';
          sb += def_val;
        end;
        sb += ';';
        if comment<>nil then
        begin
          sb += ' // ';
          sb += comment;
        end;
      end;
      sb += #10;
    end;
    
  end;
  Struct = sealed class
    private name: string;
    // (name, ptr, type)
    private flds := new List<StructField>;
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader);
    begin
      self.name := br.ReadString;
      flds.Capacity := br.ReadInt32;
      loop flds.Capacity do
        flds += new StructField(br);
      TypeTable.All.Add(self.name,self.name);
      TypeTable.Used += self.name;
    end;
    
    private static All := new List<Struct>;
    private static ByName: Dictionary<string, Struct> := nil;
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      All.Capacity := br.ReadInt32;
      loop All.Capacity do All += new Struct(br);
    end;
    
    public used := false;
    public explicit_existence := false;
    public procedure MarkUsed;
    begin
      if used then exit;
      used := true;
      foreach var fld in flds do
      begin
        fld.FixT;
        Group.MarkUsed(fld.t);
        Struct.MarkUsed(fld.t);
      end;
    end;
    public static procedure MarkUsed(name: string);
    begin
      if ByName=nil then ByName := All.ToDictionary(s->s.name);
      var res: Struct;
      if ByName.TryGetValue(name, res) then
        res.MarkUsed;
    end;
    
    public static procedure WarnAllUnused :=
    foreach var s in All do
      if not s.used then
        if s.explicit_existence then
          Otp($'WARNING: Struct [{s.name}] was explicitly added, but wasn''t used') else
          log.Otp($'Struct [{s.name}] was skipped');
    
    private static ValueStringNamesCache := new HashSet<string>;
    private function MakeValueString(sb: StringBuilder; len: integer): string;
    begin
      Result := $'_ValueString_{len}';
      if not ValueStringNamesCache.Add(Result) then exit;
      
      log_structs.Otp($'# {Result}');
      log_structs.Otp($'{#9}body: ntv_char[{len}]');
      log_structs.Otp('');
      
      if not used then exit;
      
      sb += '  [StructLayout(LayoutKind.Explicit, Size = ';
      sb += len.ToString;
      sb += ')]'#10;
      
      sb += '  ///--'#10;
      sb += '  ';
      sb += Result;
      sb += ' = record'#10;
      sb += '    '#10;
      
      sb += '    public property NtvChars[i: integer]: Byte'#10;
      sb += '    read Marshal.ReadByte(new IntPtr(@self), i)'#10;
      sb += '    write Marshal.WriteByte(new IntPtr(@self), i, value);';
      
      sb += '    public property Chars[i: integer]: char read ChrAnsi(NtvChars[i]) write NtvChars[i] := OrdAnsi(value); default;'#10;
      sb += '    '#10;
      
      sb += '    public constructor(s: string);'#10;
      sb += '    begin'#10;
      sb += '      if s.Length >= ';
      sb += len.ToString;
      sb += ' then raise new System.OverflowException;'#10;
      sb += '      '#10;
      sb += '      for var i := 0 to s.Length-1 do'#10;
      sb += '        self[i] := s[i+1];'#10;
      sb += '      self.NtvChars[s.Length] := 0;'#10;
      sb += '      '#10;
      sb += '    end;'#10;
      sb += '    '#10;
      
      sb += '    public function ToString: string; override :='#10;
      sb += '    Marshal.PtrToStringAnsi(new IntPtr(@self));'#10;
      sb += '    '#10;
      
      sb += '  end;'#10;
      sb += '  '#10;
      
    end;
    
    public procedure Write(sb: StringBuilder);
    begin
      foreach var fld in flds do
        if fld.rep_c<>1 then
        begin
          if fld.t<>'ntv_char' then raise new System.NotSupportedException;
          fld.t := MakeValueString(sb, fld.rep_c);
          fld.rep_c := 1;
        end;
      
      log_structs.Otp($'# {name}');
      foreach var fld in flds do
        log_structs.Otp($'{#9}{fld.MakeDef}' + (fld.rep_c<>1 ? $'[{fld.rep_c}]' : '') );
      log_structs.Otp('');
      
      if not used then exit;
      
      sb += $'  {name} = record' + #10;
      
      foreach var fld in flds do
        fld.Write(sb);
      sb += '    '#10;
      
      var constr_flds := flds.ToList;
      constr_flds.RemoveAll(fld->fld.name=nil);
      constr_flds.RemoveAll(fld->fld.def_val<>nil);
      sb += '    public constructor(';
      sb += constr_flds.Select(fld->fld.MakeDef).JoinToString('; ');
      sb += ');'#10;
      sb += '    begin'#10;
      foreach var fld in constr_flds do
        sb += $'      self.{fld.name} := {fld.name};'+#10;
      sb += '    end;'#10;
      sb += '    '#10;
      
      sb +=       '  end;'#10;
      sb +=       '  '#10;
    end;
    public static procedure WriteAll(sb: StringBuilder);
    begin
      var sorted := new List<Struct>;
      foreach var s in All.OrderBy(s->s.name) do
      begin
        var ind := sorted.FindIndex(ps->ps.flds.Any(fld->fld.t=s.name));
        if ind=-1 then
          sorted += s else
          sorted.Insert(ind, s);
      end;
      foreach var s in sorted do s.Write(sb);
    end;
    
  end;
  StructFixer = abstract class(Fixer<StructFixer, Struct>)
    
    public static procedure InitAll;
    
    protected procedure WarnUnused(all_unused_for_name: List<StructFixer>); override :=
    Otp($'WARNING: {all_unused_for_name.Count} fixers of struct [{self.name}] wasn''t used');
    
  end;
  
  {$endregion Struct}
  
  {$region Func}
  
  {$region Help types}
  
  FuncOrgParam = sealed class
    public name, t: string;
    public readonly: boolean;
    public ptr: integer := 0;
    public static_arr_len: integer;
    public gr: Group;
    
    private static KnownClasses: HashSet<string>;
    public static procedure LoadClasses(br: System.IO.BinaryReader);
    begin
      var c := br.ReadInt32;
      KnownClasses := new HashSet<string>(c);
      loop c do KnownClasses += br.ReadString;
    end;
    private static function ConvertClassName(t: string) :=
    t.ToWords.Prepend(api_name).JoinToString('_');
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader; proto: boolean);
    begin
      self.name := br.ReadString;
      if not proto and (self.name.ToLower in pas_keywords) then self.name := '&'+self.name;
      
      var ntv_t := br.ReadString;
      self.t := ntv_t in KnownClasses ?
        ConvertClassName(ntv_t) :
        TypeTable.Convert(ntv_t);
      self.ptr += self.t.Count(ch->ch='*') - self.t.Count(ch->ch='-');
      self.t := self.t.Remove('*','-').Trim;
      
      var rep_c := br.ReadInt64;
      if rep_c<>1 then
      begin
        if rep_c<1 then raise new System.InvalidOperationException(rep_c.ToString);
        self.ptr += 1;
        rep_c := 1;
      end;
      
      self.readonly := br.ReadBoolean;
      if self.t.StartsWith('const ') then
      begin
        self.readonly := true;
        self.t := self.t.Remove(0, 'const '.Length);
      end;
      
      self.ptr += br.ReadInt32;
      if self.ptr<0 then
      begin
        if proto and (ntv_t.ToLower='void') and (ptr=-1) then // void конвертирует в IntPtr-
          self.t := nil else
          raise new MessageException($'ERROR: par [{name}] with type [{ntv_t}] got negative ref count: [{self.ptr}]');
      end;
      
      self.static_arr_len := br.ReadInt32;
      
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
    
    public arr_hlp_skip := false;
    
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
  FuncOverload = sealed class(System.IEquatable<FuncOverload>)
    public pars: array of FuncParamT;
    public constructor(pars: array of FuncParamT) := self.pars := pars;
    
    public static function operator=(ovr1, ovr2: FuncOverload): boolean :=
    ovr1.pars.Zip(ovr2.pars, (par1,par2)->par1=par2).All(b->b);
    
    public function Equals(other: FuncOverload) := self=other;
    
    public function GetHashCode: integer; override := pars.Last.tname.GetHashCode;
    
  end;
  
  FuncParamMarshaler = sealed class
    public par: FuncParamT;
    public call_str: string; // res_str для [0]
    public generic_name: string;
    public vars: List<(string, string)>;
    public init, fnls: List<string>;
    
    public constructor(par: FuncParamT; call_str: string; generic_name: string; vars: List<(string, string)>; init, fnls: List<string>);
    begin
      self.par          := par;
      self.call_str     := call_str;
      self.generic_name := generic_name;
      self.vars         := vars;
      self.init         := init;
      self.fnls         := fnls;
    end;
    
    public constructor(par: FuncParamT) := 
    self.par := par;
    
  end;
  
  {$endregion Help types}
  
  Func = sealed class
    
    {$region Basic}
    
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
    
    {$endregion Basic}
    
    {$region Misc}
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader);
    begin
      org_par := ArrGen(br.ReadInt32, i->new FuncOrgParam(br, i=0));
      BasicInit;
    end;
    
    private static All := new List<Func>;
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      All.Capacity := br.ReadInt32;
      loop All.Capacity do All += new Func(br);
    end;
    
    {$endregion Misc}
    
    {$region PPT}
    
    // ": array of possible_par_type_collection"
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
            log.Otp($'Param [{par.name}] with type [{par.t}] in func [{self.name}]');
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
            Result := Lst(new FuncParamT(false, 0, new string('^',par.ptr.ClampBottom(0)) + par.GetTName));
            exit;
          end;
          
          var can_be_arr      := (par.static_arr_len=-1) or (par.static_arr_len>1);
          var can_be_var_arg  := (par.static_arr_len=-1) or (par.static_arr_len>0);
          
          var res := new List<FuncParamT>(
            can_be_arr ? Max(3,par.ptr+1) :
            can_be_var_arg ? 2 :
              1
          );
          var par_t := par.GetTName;
          
          if (par.ptr=1) or not can_be_arr then
          begin
            if par.ptr<>1 then
              log.Otp($'Param [{par.name}] in func [{self.name}] had type of multi-array, but also cound not be array');
            
            res += new FuncParamT(false, 0,
              can_be_var_arg and (par_t='IntPtr') ?
                'pointer' :
                'IntPtr'
            );
            if can_be_var_arg then
              res += new FuncParamT(true, 0, par_t);
          end else
          for var ptr := 0 to par.ptr-1 do
            res += new FuncParamT(false, ptr, 'IntPtr');
          
          var ToDo := 0; //ToDo костыль, надо маршлинг нормально настроить
          // Но проблема в том, что для "array of boolean" не работает копирование в неуправляемую память
          // Очевидное решение - через указатели получить "array of Byte". Только как покрасивше?
          if can_be_arr then
            res += new FuncParamT(false, par.ptr,
              (par_t='boolean') and (par.ptr>1) ?
                'Byte' : par_t
            );
          
          res.Reverse;
          Result := res;
        end;
        
      end);
    end;
    
    private procedure FixCL_ErrCodeRet;
    begin
      if org_par.Length=1 then exit;
      if org_par[org_par.Length-1].GetTName <> 'ErrorCode' then exit;
      InitPossibleParTypes;
      possible_par_types[org_par.Length-1].RemoveAt(2);
      possible_par_types[org_par.Length-1].RemoveAt(0);
    end;
    
    {$endregion PPT}
    
    {$region Overloads}
    
    public all_overloads: List<FuncOverload>;
    public procedure InitOverloads;
    begin
      if all_overloads<>nil then exit;
      InitPossibleParTypes;
      
      all_overloads := new List<FuncOverload>(
        possible_par_types.Select(types->types.Count).Product
      );
      var overloads := Seq&<sequence of FuncParamT>(Seq&<FuncParamT>());
      
      foreach var types in possible_par_types do
        overloads := overloads.SelectMany(ovr->types.Select(t->ovr.Append(t)));
      
      foreach var ovr in overloads do
      begin
        var enmr := ovr.GetEnumerator();
        all_overloads += new FuncOverload(ArrGen(org_par.Length, i->
        begin
          if not enmr.MoveNext then raise new System.InvalidOperationException;
          Result := enmr.Current;
        end));
        if enmr.MoveNext then raise new System.InvalidOperationException;
      end;
      
    end;
    
    {$endregion Overloads}
    
    {$region MarkUsed}
    
    public used := false;
    public procedure MarkUsed;
    begin
      if used then exit;
      used := true;
      InitOverloads;
      foreach var ovr in all_overloads do
        foreach var par in is_proc ? ovr.pars.Skip(1) : ovr.pars do
        begin
          var tname := par.tname.TrimStart('^');
          Group.MarkUsed(tname);
          Struct.MarkUsed(tname);
        end;
    end;
    
    public static procedure WarnAllUnused :=
    foreach var f in All do
      if not f.used then
        Otp($'ERROR: Func [{f.name}] wasn''t used');
    
    {$endregion MarkUsed}
    
    public static prev_func_names := new HashSet<string>;
    public procedure Write(sb, ntv_sb: StringBuilder; ntv_t_name, api, version: string; static_container: boolean);
    begin
      InitOverloads;
      var arr_hlp_ovr_par := new FuncParamT(false, 0, 'IntPtr');
      arr_hlp_ovr_par.arr_hlp_skip := true;
      
      {$region MiscInit}
      
      if LogCache.loged_ffo.Add(self.name) then
      begin
        
        if not is_proc or (org_par.Length>1) then
        begin
          log_func_ovrs.Otp($'# {name}');
          foreach var ovr in all_overloads do
            log_func_ovrs.Otp(
              (is_proc ? ovr.pars.Skip(1) : ovr.pars)
              .Select(par->$' {par.ToString(true,true)}{#9}|')
              .JoinToString('')
            );
          log_func_ovrs.Otp('');
        end;
        
      end;
      
      if all_overloads.Count=0 then
      begin
        Otp($'ERROR: Func [{name}] ended up having 0 overloads. [possible_par_types]: ');
        foreach var par in possible_par_types do
          Otp(_ObjectToString(par));
        exit;
      end;
      if all_overloads.Count>18 then Otp($'WARNING: Too many ({all_overloads.Count}) overloads of func [{name}]');
      
      for var par_i := 1 to org_par.Length-1 do
        if all_overloads.Any(ovr->ovr.pars[par_i].tname.ToLower=org_par[par_i].name.ToLower) then
          org_par[par_i].name := '_' + org_par[par_i].name;
      
      var l_name := name;
      if l_name.ToLower.StartsWith(api) then
        l_name := l_name.Substring(api.Length) else
      if api<>'gdi' then
        log.Otp($'Func [{name}] had api [{api}], which isn''t start of it''s name');
      prev_func_names += l_name.ToLower;
      
      var use_external := static_container;
      case api of
        'gl': use_external := (version<>nil) and (version <= '1.1');
      end;
      if not use_external then
        sb += $'    private z_{l_name}_adr := GetFuncAdr(''{name}'');' + #10;
      
      {$endregion MiscInit}
      
      {$region WriteOvrT}
      
      var WriteOvrT := procedure(sb: StringBuilder; ovr: FuncOverload; generic_names: List<string>; name: string; is_static, allow_skip_arr_hlp: boolean)->
      begin
        
        var use_standart_dt := false; // единственное применение - в "Marshal.GetDelegateForFunctionPointer". Но он их и не принимает
        if use_standart_dt then
        begin
          sb += is_proc ? 'Action' : 'Func';
        end else
        begin
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
        
        if ovr.pars.Length>1 then
        begin
          sb += use_standart_dt ? '<' : '(';
          for var par_i := 1 to ovr.pars.Length-1 do
          begin
            var par := ovr.pars[par_i];
            if allow_skip_arr_hlp and par.arr_hlp_skip then continue;
            if not use_standart_dt then
            begin
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
            if ovr.pars.Length>1 then
            begin
              sb.Length -= 1;
              sb += ', ';
            end else
              sb += '<';
            sb += ovr.pars[0].ToString(true);
            sb += '>';
          end else
          begin
            sb += ': ';
            sb += ovr.pars[0].ToString(true);
          end;
        
      end;
      
      {$endregion WriteOvrT}
      
      var PrevOvrNames := new Dictionary<FuncOverload, (string,array of boolean)>;
      
      for var ovr_i := 0 to all_overloads.Count-1 do
      begin
        var ovr := all_overloads[ovr_i];
        
        {$region Constructing ntv/temp ovrs}
        
        var marshalers := ArrGen(ovr.pars.Length, i->new List<FuncParamMarshaler>);
        
        {$region Result}
        if not is_proc then
        begin
          var par := ovr.pars[0];
          var ntv := new FuncParamT(par.var_arg, 0, par.tname);
          
          var relevant_res_str := 'Result';
          
          var init := new List<string>;
          var fnls := new List<string>;
          var vars := new List<(string, string)>;
          
          // нельзя определить размер массива в результате
          if par.arr_lvl<>0 then raise new System.NotSupportedException;
          
          if ntv.tname='string' then
          begin
            var str_ptr_name := $'res_str_ptr';
            vars += (str_ptr_name, 'IntPtr');
            
            fnls += $'{relevant_res_str} := Marshal.PtrToStringAnsi({str_ptr_name});';
            if not org_par[0].readonly then
              fnls += $'Marshal.FreeHGlobal({str_ptr_name});';
            
            relevant_res_str := str_ptr_name;
            ntv.tname := 'IntPtr';
          end;
          
          marshalers[0] += new FuncParamMarshaler(ntv);
          marshalers[0] += new FuncParamMarshaler(par, relevant_res_str, nil, vars,init,fnls);
        end;
        {$endregion Result}
        
        {$region Param}
        for var par_i := 1 to ovr.pars.Length-1 do
        begin
          var par := ovr.pars[par_i];
          var ntv := new FuncParamT(par.var_arg, 0, par.tname);
          
          var relevant_call_str := org_par[par_i].name;
          var generic_name: string := nil;
          
          var init := new List<string>;
          var fnls := new List<string>;
          var vars := new List<(string, string)>;
          
          {$region string}
          
          if ntv.tname='string' then
          begin
            var str_ptr_arr_name := $'par_{par_i}_str_ptr';
            vars += (str_ptr_arr_name, 'array of '*par.arr_lvl + 'IntPtr');
            
            var str_ptr_arr_init := new StringBuilder;
            str_ptr_arr_init += $'{str_ptr_arr_name} := ';
            var prev_arr_name := relevant_call_str;
            for var i := 1 to par.arr_lvl do
            begin
              var new_arr_name := $'arr_el{i}';
              str_ptr_arr_init += $'{prev_arr_name}?.ConvertAll({new_arr_name}->';
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
            fnls += str_ptr_arr_finl.ToString;
            
            relevant_call_str := str_ptr_arr_name;
            ntv.tname := 'IntPtr';
          end;
          
          {$endregion string}
          
          {$region array}
          
          if par.arr_lvl>1 then
            for var temp_arr_i := par.arr_lvl-1 downto 1 do
            begin
              var temp_arr_name := $'par_{par_i}_temp_arr{temp_arr_i}';
              vars += (temp_arr_name, 'array of '*temp_arr_i + 'IntPtr');
              
              var temp_arr_init := new StringBuilder;
              temp_arr_init += $'{temp_arr_name} := {relevant_call_str}';
              for var i := 1 to temp_arr_i-1 do
                temp_arr_init += $'?.ConvertAll(arr_el{i}->arr_el{i}';
              temp_arr_init += $'?.ConvertAll(arr_el{temp_arr_i}->begin';
              init += temp_arr_init.ToString;
              init += $'  if (arr_el{temp_arr_i}=nil) or (arr_el{temp_arr_i}.Length=0) then';
              init += $'    Result := IntPtr.Zero else';
              init += $'  begin';
              init += $'    var l := Marshal.SizeOf&<{ntv.tname}>*arr_el{temp_arr_i}.Length;';
              init += $'    Result := Marshal.AllocHGlobal(l);';
              init += $'    Marshal.Copy(arr_el{temp_arr_i},0,Result,l);';
              init += $'  end;';
              init += Concat('end)', ')'*(temp_arr_i-1), ';');
              
              var temp_arr_finl := new StringBuilder;
              var prev_arr_name := temp_arr_name;
              for var i := 1 to temp_arr_i do
              begin
                var new_arr_name := $'arr_el{i}';
                temp_arr_finl += $'if {prev_arr_name}<>nil then foreach var {new_arr_name} in {prev_arr_name} do ';
                prev_arr_name := new_arr_name;
              end;
              temp_arr_finl += $'Marshal.FreeHGlobal(arr_el{temp_arr_i});';
              fnls += temp_arr_finl.ToString;
              
              relevant_call_str := temp_arr_name;
              ntv.tname := 'IntPtr'; // внутри цикла для того, чтоб в следующей итерации "sizeof({ntv.tname})" было правильным
            end;
          
          if par.arr_lvl<>0 then
          begin
            ntv.var_arg := true;
            // Учтено ниже
            // Перед получением [0] - надо сначала проверить на nil
//            relevant_call_str += '[0]';
          end;
          
          {$endregion array}
          
          {$region genetic}
          
          if ntv.tname.StartsWith('T') and ntv.tname.Skip(1).All(ch->ch.IsDigit) then
          begin
            generic_name := ntv.tname;
            
            if par.arr_lvl=0 then
            begin
              if not ntv.var_arg then raise new System.NotSupportedException;
            end else
            begin
              ntv.var_arg := true;
              
              marshalers[par_i] += new FuncParamMarshaler(par, relevant_call_str, generic_name, vars,init,fnls);
              par := new FuncParamT(true, 0, generic_name);
              relevant_call_str := org_par[par_i].name;
              vars := new List<(string, string)>;
              init := new List<string>;
              fnls := new List<string>;
              
            end;
            
            relevant_call_str := $'PByte(pointer(@{relevant_call_str}))^';
            ntv.tname := 'Byte';
          end;
          
          {$endregion genetic}
          
          marshalers[par_i] += new FuncParamMarshaler(par, relevant_call_str, generic_name, vars,init,fnls);
          marshalers[par_i] += new FuncParamMarshaler(ntv);
          marshalers[par_i].Reverse;
        end;
        {$endregion Param}
        
        {$endregion Constructing ntv/temp ovrs}
        
        {$region Code-generation}
        var max_marshal_chain := marshalers.Max(lst->lst.Count);
        if max_marshal_chain<2 then max_marshal_chain := 2;
        
        // имя перегрузки, обрабатываемой на текущей итерации m_ovr_i
        // имена _anh сюда не попадают
        var relevant_ovr_name: (string,array of boolean) := nil;
        for var m_ovr_i := 0 to max_marshal_chain-1 do
        begin
          var ms := ArrGen(marshalers.Length, par_i->
            m_ovr_i < marshalers[par_i].Count ?
              marshalers[par_i][m_ovr_i] : nil
          );
          
          // имя перегрузки, обработанной на предыдущей итерации m_ovr_i
          // имена _anh сюда попадают только если перегрузку нашло в PrevOvrNames
          var prev_ovr_name := relevant_ovr_name;
          
          marshalers.Select(m_lst->
            (m_ovr_i < m_lst.Count-1) and
            (m_lst[m_ovr_i+1].par.arr_lvl <> 0)
          ).Aggregate(Seq&<sequence of boolean>(Seq&<boolean>()), (prev, b)->
          begin
            var res := prev.Select(v->v.Append(false));
            if b then
              res := res + prev.Select(v->v.Append(true));
            Result := res;
          end).Select(v->v.ToArray)
          .Foreach((nil_arr_par_flags, nil_arr_hlp_ovr_i)->
          begin
            var curr_ovr_holey := new FuncOverload( ms.ConvertAll((m,par_i)->nil_arr_par_flags[par_i] ? arr_hlp_ovr_par : m?.par) );
            var curr_ovr := new FuncOverload( curr_ovr_holey.pars.ConvertAll((par,par_i)->par as object=nil ? ovr.pars[par_i] : par) );
            
            {$region Name construction}
            
            var is_static := static_container;
            
            var ovr_name: (string,array of boolean);
            var vis := 'public';
            if m_ovr_i=max_marshal_chain-1 then
            begin
              ovr_name := (l_name, new boolean[0]);
            end else
            if PrevOvrNames.TryGetValue(curr_ovr, ovr_name) then
            begin
              if nil_arr_hlp_ovr_i=0 then relevant_ovr_name := ovr_name;
              exit;
            end else
            begin
              is_static := is_static or use_external;
              var ovr_name_str: string;
              var ovr_name_arr_nil := nil_arr_par_flags;
              
              if m_ovr_i=0 then
                ovr_name_str := $'z_{l_name}_ovr_{ovr_i}' else
              begin
                vis := 'private';
                ovr_name_str := $'temp_{l_name}_ovr_{ovr_i}';
              end;
              
              ovr_name := (ovr_name_str, ovr_name_arr_nil);
              
              if nil_arr_hlp_ovr_i = 0 then
              begin
                relevant_ovr_name := ovr_name;
                PrevOvrNames.Add(curr_ovr, ovr_name);
              end else
                vis := 'private';
              
            end;
            
            var ovr_name_str := ovr_name[0];
            if ovr_name[1].Any(b->b) then
              ovr_name_str += '_anh' + ovr_name[1].Select(b->b?'1':'0').JoinToString else
            if ovr_name_str.ToLower in pas_keywords then
              ovr_name_str := '&'+ovr_name_str;
            
            {$endregion Name construction}
            
            if m_ovr_i=0 then
            begin
              {$region ntv}
              
              if use_external then
              begin
                var ext_ovr_name := {'_'+}ovr_name_str;
                
                ntv_sb += '    ';
                ntv_sb += ntv_t_name<>nil ? 'public' : 'private';
                ntv_sb += ' ';
                WriteOvrT(ntv_sb, curr_ovr,nil, ext_ovr_name, true, false);
                ntv_sb += ';'#10;
                ntv_sb += $'    external ''{GetDllNameForAPI(api)}'' name ''{name}'';'+#10;
                
//                sb += $'    {vis} static {ovr_name_str}';
//                if (org_par.Length=1) and not is_proc then
//                begin
//                  sb += ': ';
//                  WriteOvrT(curr_ovr,nil, nil, false, false);
//                end;
//                sb += $' := {ext_ovr_name};' + #10;
                
              end else
              begin
                
                sb += $'    private {ovr_name_str} := GetFuncOrNil&<';
                WriteOvrT(sb, curr_ovr,nil, nil, false, false);
                sb += $'>(z_{l_name}_adr);'+#10;
                
              end;
              
              {$endregion ntv}
            end else
            begin
              {$region non-ntv}
              
              var generic_names := new List<string>;
              foreach var par_i in ms.Indices do
                if (ms[par_i]<>nil) and (ms[par_i].generic_name<>nil) and not nil_arr_par_flags[par_i] then
                  generic_names += ms[par_i].generic_name;
              
              var need_init := ms.Any(m-> (m?.init<>nil) and (m.init.Count<>0) );
              var need_fnls := ms.Any(m-> (m?.fnls<>nil) and (m.fnls.Count<>0) );
              
              var need_block :=
                (generic_names.Count <> 0) or
                need_init or need_fnls
              ;
              
              sb += $'    {vis} [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
              WriteOvrT(sb, curr_ovr, generic_names, ovr_name_str, is_static, m_ovr_i>0);
              
              if need_block then
              begin
                sb += ';';
                if generic_names.Count<>0 then
                begin
                  sb += ' where ';
                  foreach var gn in generic_names do
                  begin
                    sb += gn;
                    sb += ', ';
                  end;
                  sb.Length -= 2;
                  sb += ': record;';
                end;
                sb += #10;
                sb += '    begin'#10;
              end else
                sb += ' :='#10;
              
              foreach var g in ms.Where(m->m?.vars<>nil).SelectMany(m->m.vars).GroupBy(t->t[1], t->t[0]).OrderBy(g->g.Key) do
              begin
                sb += '  '*3;
                sb += 'var ';
                sb += g.JoinToString(', ');
                sb += ': ';
                sb += g.Key;
                sb += ';'#10;
              end;
              
              if need_init then
              begin
                
                if need_fnls then sb += '      try'#10;
                var padding := '  '*(3+integer(need_fnls));
                foreach var m in ms do
                  if m?.init<>nil then foreach var l in m.init do
                  begin
                    sb += padding;
                    sb += l;
                    sb += #10;
                  end;
                
              end;
              
              var tabs := 2 + integer(need_block) + integer(need_init and need_fnls);
              
              var arr_par_inds := Range(0, curr_ovr.pars.Length-1)
              .Where(par_i->
                (curr_ovr_holey.pars[par_i] <> nil) and
                (curr_ovr.pars[par_i].arr_lvl <> 0)
              ).ToHashSet;
              
              var nil_arr_call_flags := new List<boolean>;
              var cont_call_cascade := true;
              while cont_call_cascade do
                if nil_arr_call_flags.Count < curr_ovr.pars.Length then
                begin
                  
                  if nil_arr_call_flags.Count in arr_par_inds then
                  begin
                    sb += '  '*tabs;
                    var par_call_str := ms[nil_arr_call_flags.Count].call_str;
                    sb += $'if ({par_call_str}<>nil) and ({par_call_str}.Length<>0) then';
                    sb += #10;
                    tabs += 1;
                  end;
                  
                  nil_arr_call_flags += false;
                end else
                begin
                  
                  sb += '  '*tabs;
                  if need_block and not is_proc then
                  begin
                    sb += ms[0]=nil ? 'Result' : ms[0].call_str;
                    sb += ' := '
                  end;
                  
                  sb += prev_ovr_name[0];
                  if prev_ovr_name[1].Any(b->b) or nil_arr_call_flags.Any(b->b) then
                  begin
                    sb += '_anh';
                    for var par_i := 0 to curr_ovr.pars.Length-1 do
                      sb += prev_ovr_name[1][par_i] or nil_arr_call_flags[par_i] ? '1' : '0';
                  end;
                  
                  if curr_ovr.pars.Length>1 then
                  begin
                    sb += '(';
                    for var par_i := 1 to ms.Length-1 do
                    begin
                      if nil_arr_call_flags[par_i] then
                      begin
                        if m_ovr_i>1 then continue;
                        sb += 'IntPtr.Zero';
                      end else
                      if nil_arr_par_flags[par_i] then
                        sb += 'PByte(nil)^' else
                      begin
                        sb += ms[par_i]=nil ? org_par[par_i].name : ms[par_i].call_str;
                        if arr_par_inds.Contains(par_i) and (curr_ovr.pars[par_i].arr_lvl <> 0) then sb += '[0]';
                      end;
                      sb += ', ';
                    end;
                    sb.Length -= ', '.Length;
                    sb += ')';
                  end;
                  sb += ' else'#10;
                  
                  while true do
                  begin
                    var last_ind := nil_arr_call_flags.Count-1;
                    var last := nil_arr_call_flags[last_ind];
                    nil_arr_call_flags.RemoveAt(last_ind);
                    
                    if arr_par_inds.Contains(last_ind) then
                    begin
                      if last then
                        tabs -= 1 else
                      begin
                        nil_arr_call_flags += true;
                        break;
                      end;
                    end;
                    
                    if nil_arr_call_flags.Count=0 then
                    begin
                      cont_call_cascade := false;
                      break;
                    end;
                  end;
                  
                end;
              sb.Length -= ' else'#10.Length;
              sb += ';'#10;
              
              if need_fnls then
              begin
                if need_init then sb += '      finally'#10;
                var padding := '  '*(3+integer(need_init));
                
                foreach var m in ms do
                  if m?.fnls<>nil then foreach var l in m.fnls do
                  begin
                    sb += padding;
                    sb += l;
                    sb += #10;
                  end;
                
                if need_init then sb += '      end;'#10;
              end;
              
              if need_block then
                sb += '    end;'#10;
              
              {$endregion non-ntv}
            end;
            
          end);
          
          if use_external and (ntv_t_name<>nil) then
            relevant_ovr_name := (
              $'{ntv_t_name}.{relevant_ovr_name[0]}',
              relevant_ovr_name[1]
            );
          
        end;
        
        {$endregion Code-generation}
        
      end;
      
      if use_external and (ntv_t_name<>nil) then
        ntv_sb += '    '#10;
      sb += '    '#10;
    end;
    
  end;
  FuncFixer = abstract class(Fixer<FuncFixer, Func>)
    
    public static procedure InitAll;
    
    protected function ApplyOrder: integer; abstract;
    protected function ApplyOrderBase: integer; override := ApplyOrder;
    
    protected procedure WarnUnused(all_unused_for_name: List<FuncFixer>); override :=
    Otp($'WARNING: {all_unused_for_name.Count} fixers of func [{self.name}] wasn''t used');
    
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
    
    public static procedure FixCL_ErrCodeRet :=
    foreach var lst in Feature.ByApi.Values do
      foreach var f in lst do
      begin
        foreach var fnc in f.add do fnc.FixCL_ErrCodeRet;
        foreach var fnc in f.rem do fnc.FixCL_ErrCodeRet;
      end;
    
    private procedure MarkUsed;
    begin
      foreach var fnc in add do fnc.MarkUsed;
      foreach var fnc in rem do fnc.MarkUsed;
    end;
    public static procedure MarkAllUsed :=
    foreach var lst in Feature.ByApi.Values do
      foreach var f in lst do
        f.MarkUsed;
    
    public static function IsAPIDynamic(api: string): boolean;
    begin
      case api of
        
        'gl':   Result := true;
        'wgl':  Result := false;
        'glx':  Result := false;
        'gdi':  Result := false;
        
        'cl':   Result := false;
        
        else raise new System.NotSupportedException(api);
      end;
    end;
    
    public static procedure WriteAll(sb, ntv_sb: StringBuilder) :=
    foreach var api in Feature.ByApi.Keys do
    begin
      
      // func - addition version
      var all_funcs := new Dictionary<Func, string>;
      // func - deprecation version
      var deprecated := new Dictionary<Func, string>;
      
      var log_func_ver := new FileLogger(GetFullPathRTA($'Log\FuncsVer ({api}).log'));
      loop 3 do log_func_ver.Otp('');
      
      foreach var ftr in ByApi[api] do
      begin
        
        foreach var f in ftr.add do
          if all_funcs.ContainsKey(f) and not deprecated.Remove(f) then
            Otp($'WARNING: Func [{f.name}] was added in versions [{all_funcs[f]}] and [{ftr.version}]') else
            all_funcs[f] := ftr.version;
        
        foreach var f in ftr.rem do
          if deprecated.ContainsKey(f) then
            Otp($'WARNING: Func [{f.name}] was deprecated in versions [{deprecated[f]}] and [{ftr.version}]') else
            deprecated.Add(f, ftr.version);
        
        log_func_ver.Otp($'# {ftr.version}');
        foreach var f in all_funcs.Keys do
          if not deprecated.ContainsKey(f) then
            log_func_ver.Otp($'{#9}{f.name}');
        log_func_ver.Otp('');
        
      end;
      
      loop 1 do log_func_ver.Otp('');
      log_func_ver.Close;
      
      var is_dynamic := IsAPIDynamic(api);
      var class_type := is_dynamic ? 'sealed' : 'static';
      
      var ntv_t_name := default(string);
      if is_dynamic then
      begin
        ntv_t_name := api + '_ntv';
        ntv_sb += '  [PCUNotRestore]'#10;
        ntv_sb += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
        ntv_sb += '  ///--'#10;
        ntv_sb += '  ';
        ntv_sb += ntv_t_name;
        ntv_sb += ' = static class'#10;
        ntv_sb += '    '#10;
      end;
      
      sb += '  [PCUNotRestore]'#10;
      sb += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
      sb += '  ';
      sb += api;
      if is_dynamic then
        sb += '<TPlatformAPI>';
      sb += ' = ';
      sb += class_type;
      sb += ' class'#10;
      if is_dynamic then
      begin
        sb += '  where TPlatformAPI: record, IPlatformAPI;'#10;
        sb += '    private static platform_api := default(TPlatformAPI);'#10;
        sb += '    private static function GetFuncAdr(lpszProc: string) := platform_api.GetProcAddress(lpszProc);'#10;
        sb += '    private static function GetFuncOrNil<T>(fadr: IntPtr) :='#10;
        sb += '    fadr=IntPtr.Zero ? default(T) :'#10;
        sb += '    Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
      end;
      
      sb += '    '#10;
      
      foreach var f in all_funcs.Keys.OrderBy(f->f.name) do
        if not deprecated.ContainsKey(f) then
        begin
          if api<>'gdi' then
            sb += $'    // added in {api}{all_funcs[f]}'+#10;
          f.Write(sb, is_dynamic ? ntv_sb : sb, ntv_t_name, api,all_funcs[f], not is_dynamic);
        end;
      
      Func.prev_func_names.Clear;
      sb += $'  end;'+#10;
      sb += $'  '+#10;
      
      if not deprecated.Any then continue;
      sb += '  [PCUNotRestore]'#10;
      sb += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
      
      sb += '  ';
      sb += api;
      sb += 'D';
      if is_dynamic then
        sb += '<TPlatformAPI>';
      sb += ' = ';
      sb += class_type;
      sb += ' class'#10;
      if is_dynamic then
      begin
        sb += '  where TPlatformAPI: record, IPlatformAPI;'#10;
        sb += '    private static platform_api := default(TPlatformAPI);'#10;
        sb += '    private static function GetFuncAdr(lpszProc: string) := platform_api.GetProcAddress(lpszProc);'#10;
        sb += '    private static function GetFuncOrNil<T>(fadr: IntPtr) :='#10;
        sb += '    fadr=IntPtr.Zero ? default(T) :'#10;
        sb += '    Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
      end;
      
      sb += $'    '+#10;
      
      foreach var f in all_funcs.Keys.Where(deprecated.ContainsKey).OrderBy(f->f.name) do
      begin
        if api<>'gdi' then
          sb += $'    // added in {api}{all_funcs[f]}, deprecated in {api}{deprecated[f]}'+#10;
        f.Write(sb, ntv_t_name<>nil ? ntv_sb : sb, ntv_t_name, api,all_funcs[f], not is_dynamic);
      end;
      
      Func.prev_func_names.Clear;
      sb += '  end;'#10;
      sb += '  '#10;
      
      if is_dynamic then
      begin
        ntv_sb += '  end;'#10;
        ntv_sb += '  '#10;
      end;
      
    end;
    
  end;
  Extension = sealed class
    public name, display_name: string;
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
      ext_group := name.Remove(ind).ToUpper;
      if ext_group in allowed_ext_names then
        display_name := name.Substring(ind+1) else
      begin
        display_name := name;
        if LogCache.invalid_ext_names.Add(ext_group) then
          log.Otp($'Ext group [{ext_group}] of ext [{name}] is not supported');
        ext_group := '';
      end;
      
      display_name := api+display_name.Split('_').Select(w->
      begin
        if w.Length<>0 then w[0] := w[0].ToUpper;
        Result := w;
      end).JoinToString('') + ext_group;
      
    end;
    
    public static All := new List<Extension>;
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      All.Capacity := br.ReadInt32;
      
      loop All.Capacity do
      begin
        var ext := new Extension(br);
        
        All += ext;
      end;
      
    end;
    
    public static procedure FixCL_ErrCodeRet :=
    foreach var ext in All do
      foreach var f in ext.add do
        f.FixCL_ErrCodeRet;
    
    private procedure MarkUsed;
    begin
      foreach var fnc in add do fnc.MarkUsed;
    end;
    public static procedure MarkAllUsed :=
    foreach var ext in All do
      ext.MarkUsed;
    
    public static function IsAPIDynamic(api: string): boolean;
    begin
      case api of
        
        'gl':   Result := true;
        'wgl':  Result := true;
        'glx':  Result := true;
        'gdi':  Result := false;
        
        'cl':   Result := false;
        
        else raise new System.NotSupportedException(api);
      end;
    end;
    
    public procedure Write(sb, ntv_sb: StringBuilder);
    begin
      if add.Count=0 then exit;
      
      sb += '  [PCUNotRestore]'#10;
      sb += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
      
      sb += '  ';
      sb += display_name;
      if Feature.IsAPIDynamic(api) then
        sb += '<TPlatformAPI>';
      sb += ' = ';
      var is_dynamic := IsAPIDynamic(api);
      sb += is_dynamic ? 'sealed' : 'static';
      sb += ' class'#10;
      
      var ntv_t_name := default(string);
//      if is_dynamic then
//      begin
//        ntv_t_name := display_name + '_ntv';
//        ntv_sb += '  [PCUNotRestore]'#10;
//        ntv_sb += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
//        ntv_sb += '  ///--'#10;
//        ntv_sb += '  ';
//        ntv_sb += ntv_t_name;
//        ntv_sb += ' = static class'#10;
//        ntv_sb += '    '#10;
//      end;
      
      if is_dynamic then
      begin
        if Feature.IsAPIDynamic(api) then
        begin
          sb += '  where TPlatformAPI: record, IPlatformAPI;'#10;
          sb += '    private static platform_api := default(TPlatformAPI);'#10;
          sb += '    private static function GetFuncAdr(lpszProc: string) := platform_api.GetProcAddress(lpszProc);'#10;
        end else
        begin
          sb += $'    private static function GetFuncAdr(lpszProc: string) := {api}.GetProcAddress(lpszProc);'+#10;
        end;
        sb += '    private static function GetFuncOrNil<T>(fadr: IntPtr) :='#10;
        sb += '    fadr=IntPtr.Zero ? default(T) :'#10;
        sb += '    Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
      end;
      
      sb += $'    public const _ExtStr = ''{name}'';'+#10;
      sb += $'    '+#10;
      
      foreach var f in add do
        f.Write(sb, ntv_t_name<>nil ? ntv_sb : sb, ntv_t_name, api,nil, not is_dynamic);
      Func.prev_func_names.Clear;
      sb += $'  end;'+#10;
      sb += $'  '+#10;
      
//      if is_dynamic then
//      begin
//        ntv_sb += $'  end;'+#10;
//        ntv_sb += $'  '+#10;
//      end;
      
    end;
    public static procedure WriteAll(sb, ntv_sb: StringBuilder);
    begin
      sb += '  {$region Extensions}'#10;
      sb += '  '#10;
      foreach var ext in All do ext.Write(sb, ntv_sb);
      sb += '  {$endregion Extensions}'#10;
      sb += '  '#10;
    end;
    
  end;
  
  {$endregion FuncContainers}
  
procedure InitAll;
procedure LoadBin(fname: string);
procedure ApplyFixers;
procedure MarkUsed;
procedure FinishAll;

implementation

{$region Misc}

procedure InitAll;
begin
  
  allowed_ext_names :=
    ReadLines(GetFullPathRTA('MiscInput\AllowedExtNames.dat'))
    .Where(l->not string.IsNullOrWhiteSpace(l))
    .Select(l->l.Trim)
    .OrderByDescending(l->l.Length)
    .Append('')
    .ToHashSet
  ;
  
  loop 3 do log_groups.Otp('');
  loop 3 do log_structs.Otp('');
  loop 3 do log_func_ovrs.Otp('');
  
  StructFixer.InitAll;
  GroupFixer.InitAll;
  FuncFixer.InitAll;
  
end;

procedure LoadBin(fname: string);
begin
  var br := new System.IO.BinaryReader(System.IO.File.OpenRead(fname));
  Group.LoadAll(br);
  Struct.LoadAll(br);
  FuncOrgParam.LoadClasses(br);
  Func.LoadAll(br);
  Feature.LoadAll(br);
  Extension.LoadAll(br);
  if br.BaseStream.Position<>br.BaseStream.Length then raise new System.FormatException;
end;

procedure ApplyFixers;
begin
  StructFixer.ApplyAll(Struct.All);
  GroupFixer.ApplyAll(Group.All);
  FuncFixer.ApplyAll(Func.All);
end;

procedure MarkUsed;
begin
  Feature.MarkAllUsed;
  Extension.MarkAllUsed;
end;

procedure FinishAll;
begin
  
  TypeTable.WarnAllUnused;
  StructFixer.WarnAllUnused;
  GroupFixer.WarnAllUnused;
  FuncFixer.WarnAllUnused;
  
  Struct.WarnAllUnused;
  Group.WarnAllUnused;
  Func.WarnAllUnused;
  
  log.Otp('done');
  
  loop 1 do log_groups.Otp('');
  loop 1 do log_structs.Otp('');
  loop 1 do log_func_ovrs.Otp('');
  
  log.Close;
  log_groups.Close;
  log_structs.Close;
  log_func_ovrs.Close;
  
end;

function GetExt(s: string): string;
begin
  
  var i := s.Length-1;
  while s[i].IsUpper or s[i].IsDigit do i -= 1;
  
  Result := s.Remove(0,i+1);
  if allowed_ext_names.Contains(Result) then exit;
  
  var prev_res := Result;
  Result := allowed_ext_names
    .First(ext->prev_res.EndsWith(ext))
  ;
  if LogCache.invalid_ext_names.Add(prev_res) and (prev_res.Length>1) then
    log.Otp($'Invalid ext name [{prev_res}], replaced with [{Result}]');
  
end;

function GetDllNameForAPI(api: string): string;
begin
  case api of
    'cl':   Result := 'opencl.dll';
    'gl':   Result := 'opengl32.dll';
    'wgl':  Result := 'opengl32.dll';
    'glx':  Result := 'libGL.so.1';
    'gdi':  Result := 'gdi32.dll';
    else raise new System.NotSupportedException(api);
  end;
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
      gr.explicit_existence := true;
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
      gr.FinishInit;
      self.used := true;
      Result := false;
    end;
    
  end;
  GroupAddEnumFixer = sealed class(GroupFixer)
    public enums := new List<(string,int64)>;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      
      foreach var l in data.Where(l->not string.IsNullOrWhiteSpace(l)) do
      begin
        var s := l.Split('=');
        var key := s[0].Trim;
        var val := s[1].Trim;
        enums += (key, val.StartsWith('0x') ?
          System.Convert.ToInt64(val, 16) :
          System.Convert.ToInt64(val)
        );
      end;
      
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      foreach var t in enums do
        gr.enums.Add(t[0],t[1]);
      gr.FinishInit;
      self.used := true;
      Result := false;
    end;
    
  end;
  GroupCustopMemberFixer = sealed class(GroupFixer)
    public member_lns: array of string;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      
      var res := new List<string>;
      var skiped := new List<string>;
      
      foreach var l in data do
        if not string.IsNullOrWhiteSpace(l) then
        begin
          res.AddRange(skiped);
          skiped.Clear;
          res += l;
        end else
        if res.Count<>0 then
          skiped += l;
      
      member_lns := res.ToArray;
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      gr.custom_members += member_lns;
      self.used := true;
      Result := false;
    end;
    
  end;
  
static procedure GroupFixer.InitAll;
begin
  GroupFixer.GetFixableName := gr->gr.name;
  GroupFixer.MakeNewFixable := f->
  begin
    Result := new Group;
    f.Apply(Result);
  end;
  
  var fls := EnumerateAllFiles(GetFullPathRTA('Fixers\Enums'), '*.dat');
  foreach var gr in fls.SelectMany(fname->FixerUtils.ReadBlocks(fname,true)) do
    foreach var bl in FixerUtils.ReadBlocks(gr[1],'!',false) do
    case bl[0] of
      
      'add':        GroupAdder            .Create(gr[0], bl[1]);
      'remove':     GroupRemover          .Create(gr[0], bl[1]);
      
      'rename':     GroupNameFixer        .Create(gr[0], bl[1]);
      'add_enum':   GroupAddEnumFixer     .Create(gr[0], bl[1]);
      'cust_memb':  GroupCustopMemberFixer.Create(gr[0], bl[1]);
      
      else raise new MessageException($'Invalid group fixer type [!{bl[0]}] for group [{gr[0]}]');
    end;
  
end;

{$endregion GroupFixer}

{$region StructFixer}

type
  StructAdder = sealed class(StructFixer)
    private name: string;
    private flds := new List<StructField>;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(nil);
      self.name := name;
      
      foreach var l in data do
        if not string.IsNullOrWhiteSpace(l) then
        begin
          var fld := new StructField;
          
          if l.Trim<>'*' then
          begin
            var ind := l.IndexOf(':');
            fld.name := l.Remove(ind).Trim;
            
            var t := l.SubString(ind+1).Trim;
            fld.ptr := t.Count(ch->ch='*');
            fld.t := t.Remove('*').Trim;
            
            ind := fld.t.IndexOf('[');
            if ind <> -1 then
            begin
              if not fld.t.EndsWith(']') then raise new System.FormatException(fld.t);
              fld.rep_c := StrToInt64( fld.t.SubString(ind+1, fld.t.Length-ind-2) );
              fld.t := fld.t.Remove(ind);
            end;
          end else
            fld.name := nil;
          
          flds += fld;
        end;
      
      self.RegisterAsAdder;
    end;
    
    public function Apply(s: Struct): boolean; override;
    begin
      s.name := self.name;
      s.flds := self.flds;
      s.explicit_existence := true;
      Result := false;
    end;
    
  end;
  
  StructFieldFixer = abstract class(StructFixer)
    private fn, val: string;
    
    public constructor(name: string; data: string);
    begin
      inherited Create(name);
      var s := data.Split('=');
      fn := s[0].Trim;
      val := s[1].Trim;
    end;
    
    public procedure Apply(f: StructField); abstract;
    
    public function Apply(s: Struct): boolean; override;
    begin
      var f := s.flds.Find(f->f.name=fn);
      if f<>nil then
      begin
        self.Apply(f);
        used := true;
      end else
        Otp($'WARNING: Faild to apply [{self.GetType.Name}] to struct [{s.name}]');
      Result := false;
    end;
    
  end;
  StructVisFixer = sealed class(StructFieldFixer)
    
    public constructor(name: string; data: string) :=
    inherited Create(name, data);
    public static procedure Create(name: string; data: sequence of string) :=
    foreach var l in data do
      if not string.IsNullOrWhiteSpace(l) then
        new StructVisFixer(name, l);
    
    public procedure Apply(f: StructField); override :=
    f.vis := self.val;
    
  end;
  StructDefaultFixer = sealed class(StructFieldFixer)
    
    public constructor(name: string; data: string) :=
    inherited Create(name, data);
    public static procedure Create(name: string; data: sequence of string) :=
    foreach var l in data do
      if not string.IsNullOrWhiteSpace(l) then
        new StructDefaultFixer(name, l);
    
    public procedure Apply(f: StructField); override :=
    f.def_val := self.val;
    
  end;
  StructCommentFixer = sealed class(StructFieldFixer)
    
    public constructor(name: string; data: string) :=
    inherited Create(name, data);
    public static procedure Create(name: string; data: sequence of string) :=
    foreach var l in data do
      if not string.IsNullOrWhiteSpace(l) then
        new StructCommentFixer(name, l);
    
    public procedure Apply(f: StructField); override :=
    f.comment := self.val;
    
  end;
  
static procedure StructFixer.InitAll;
begin
  StructFixer.GetFixableName := s->s.name;
  StructFixer.MakeNewFixable := f->
  begin
    Result := new Struct;
    f.Apply(Result);
  end;
  
  var fls := EnumerateAllFiles(GetFullPathRTA('Fixers\Structs'), '*.dat');
  foreach var gr in fls.SelectMany(fname->FixerUtils.ReadBlocks(fname,true)) do
    foreach var bl in FixerUtils.ReadBlocks(gr[1],'!',false) do
    case bl[0] of
      
      'add':      StructAdder       .Create(gr[0], bl[1]);
      'vis':      StructVisFixer    .Create(gr[0], bl[1]);
      'default':  StructDefaultFixer.Create(gr[0], bl[1]);
      'comment':  StructCommentFixer.Create(gr[0], bl[1]);
      
      else raise new MessageException($'Invalid struct fixer type [!{bl[0]}] for struct [{gr[0]}]');
    end;
  
end;

{$endregion StructFixer}

{$region FuncFixer}

type
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
    
    protected function ApplyOrder: integer; override := 1;
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
        Otp($'ERROR: Only {tn_id}/{new_tnames.Length} {_ObjectToString(new_tnames)} of [FuncReplParTFixer] of func [{f.name}] were used');
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
          if (t<>'') and (t<>'*') then
            if curr_lst=nil then
              raise new MessageException($'Syntax ERROR of [{self.GetType}] for func [{name}] in [{s[i]}]') else
              curr_lst += new FuncParamT(t);
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
    
    protected function ApplyOrder: integer; override := 2;
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
  
  FuncOvrsFixerBase = abstract class(FuncFixer)
    public ovrs := new List<FuncOverload>;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      
      foreach var l in data do
      begin
        var s := l.Split('|');
        if s.Length=1 then continue; // коммент
        
        if not string.IsNullOrWhiteSpace(s[s.Length-1]) then raise new System.FormatException(l);
        
        ovrs += new FuncOverload(ArrGen(s.Length-1, i->new FuncParamT(s[i]) ));
      end;
      
    end;
    
    protected function ApplyOrder: integer; override := 3;
    
  end;
  FuncReplOvrsFixer = sealed class(FuncOvrsFixerBase)
    
    public static function PrepareOvr(add_void: boolean; ovr: FuncOverload): FuncOverload;
    begin
      if add_void then
      begin
        var res := new FuncParamT[ovr.pars.Length+1];
        res[0] := new FuncParamT(false,0,nil);
        ovr.pars.CopyTo(res,1);
        Result := new FuncOverload(res);
      end else
        Result := ovr;
    end;
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      f.all_overloads.Clear;
      
      foreach var ovr in ovrs do
      begin
        var povr := PrepareOvr(f.is_proc, ovr);
        if f.org_par.Length<>povr.pars.Length then
          raise new MessageException($'ERROR: [FuncReplOvrsFixer] of func [{self.name}] had wrong param count: {f.org_par.Length} org vs {povr.pars.Length} custom');
        
        if f.all_overloads.Contains(povr) then
          Otp($'ERROR: [FuncReplOvrsFixer] of func [{f.name}] failed to add overload [{povr.pars.JoinToString}]') else
          f.all_overloads += povr;
        
      end;
        
      self.used := true;
      Result := false;
    end;
    
  end;
  FuncLimitOvrsFixer = sealed class(FuncOvrsFixerBase)
    
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      
      var expected_ovr_l := f.org_par.Length - integer(f.is_proc);
      foreach var ovr in ovrs do
        if ovr.pars.Length<>expected_ovr_l then
          raise new MessageException($'ERROR: [FuncLimitOvrsFixer] of func [{f.name}] had wrong param count: {f.org_par.Length} org vs {ovr.pars.Length+integer(f.is_proc)} custom');
      
      var unused_t_ovrs := self.ovrs.ToList;
      f.all_overloads.RemoveAll(fovr->
        not self.ovrs.Any(tovr->
        begin
          Result := tovr.pars.Zip(fovr.pars,
            (tp,fp)-> (tp.tname='*') or (tp=fp)
          ).All(b->b);
          if Result then unused_t_ovrs.Remove(tovr);
        end)
      );
      
      foreach var ovr in unused_t_ovrs do
        Otp($'WARNING: [FuncLimitOvrsFixer] of func [{f.name}] hasn''t used mask {_ObjectToString(ovr)}');
      
      self.used := true;
      Result := false;
    end;
    
  end;
  
static procedure FuncFixer.InitAll;
begin
  FuncFixer.GetFixableName := f->f.name;
  
  var fls := EnumerateAllFiles(GetFullPathRTA('Fixers\Funcs'), '*.dat');
  foreach var gr in fls.SelectMany(fname->FixerUtils.ReadBlocks(fname,true)) do
    foreach var bl in FixerUtils.ReadBlocks(gr[1],'!',false) do
    case bl[0] of
      
      'repl_par_t':         FuncReplParTFixer .Create(gr[0], bl[1]);
      
      'possible_par_types': FuncPPTFixer      .Create(gr[0], bl[1]);
      
      'repl_ovrs':          FuncReplOvrsFixer .Create(gr[0], bl[1]);
      'limit_ovrs':         FuncLimitOvrsFixer.Create(gr[0], bl[1]);
      
      else raise new MessageException($'Invalid func fixer type [!{bl[0]}] for func [{gr[0]}]');
    end;
  
end;

{$endregion FuncFixer}

end.