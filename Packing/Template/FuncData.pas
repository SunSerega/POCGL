unit FuncData;

interface

uses CodeGen      in '..\..\Utils\CodeGen';
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
    static invalid_api        := new HashSet<string>;
    static invalid_ext_names  := new HashSet<string>;
    static invalid_ntv_types  := new HashSet<string>;
    static base_t_used        := new HashSet<string>;
    static enum_conflicts     := new HashSet<string>;
    static loged_ffo          := new HashSet<string>; // final func ovrs
  end;
  
var allowed_ext_names := new HashSet<string>(|''|);
function GetExt(s: string): string;
function GetDllNameForAPI(api: string): string;

var api_name: string := nil;

{$endregion Log and Misc}

type
  
  {$region TypeTable}
  
  TypeTable = static class
    
    private static All := new Dictionary<string,string>;
    private static Used := new HashSet<string>;
    
    public static function Convert(ntv_t: string; base_t: (string, integer)): string;
    begin
      if All.TryGetValue(ntv_t, Result) then
        Used += ntv_t else
      if (base_t<>nil) and All.TryGetValue(base_t[0], Result) then
      begin
        if LogCache.base_t_used.Add(ntv_t) then
          log.Otp($'Type conversion for [{ntv_t}] not found, so base type [{base_t[0]}] converted to [{Result}]');
        if base_t[1]>0 then
          Result += new string('*', base_t[1]) else
        if base_t[1]<0 then
          Result += new string('-', -base_t[1]);
        Used += base_t[0];
      end else
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
  
  {$region WriteableNode}
  
  WriteableNode<TSelf> = abstract class
  where TSelf: WriteableNode<TSelf>;
    protected static All := new List<TSelf>;
    protected name: string;
    
    private static name_cache := default(Dictionary<string, TSelf>);
    private static function GetNameCache: Dictionary<string, TSelf>;
    begin
      Result := name_cache;
      if Result<>nil then exit;
      Result := new Dictionary<string, TSelf>(All.Count);
      foreach var n in All do
      begin
        if Result.ContainsKey(n.name) then
          raise new System.InvalidOperationException($'{TypeName(n)} [{n.name}] was defined twice');
        Result[n.name] := n;
      end;
      name_cache := Result;
    end;
    
    private static name_remap := new Dictionary<string, string>;
    private static function ByName(name: string): TSelf;
    begin
      var new_name: string;
      while name_remap.TryGetValue(name, new_name) do
        name := new_name;
      GetNameCache.TryGetValue(name, Result);
    end;
    protected procedure Rename(new_name: string);
    begin
      if name_cache<>nil then
      begin
        name_cache.Remove(name);
        name_cache.Add(new_name, TSelf(self));
        name_remap.Add(name, new_name);
      end;
      self.name := new_name;
    end;
    
    protected referenced := false;
    protected procedure OnMarkReferenced; virtual := exit;
    public procedure MarkReferenced;
    begin
      if referenced then exit;
      referenced := true;
      OnMarkReferenced;
    end;
    public static function MarkReferenced(name: string): boolean;
    begin
      var n := ByName(name);
      Result := n<>nil;
      if not Result then exit;
      n.MarkReferenced;
    end;
    
    public static procedure WarnAllUnreferenced :=
    foreach var n in All do
      if not n.referenced then
        if n.explicit_existence then
          Otp($'WARNING: {TypeName(n)} [{n.name}] was explicitly added, but was not referenced') else
          log.Otp($'{TypeName(n)} [{n.name}] was not referenced');
    
    protected writeable := false;
    protected procedure OnMarkWriteable; virtual := exit;
    public procedure MarkWriteable;
    begin
      if writeable then exit;
      writeable := true;
      OnMarkWriteable;
    end;
    public static function MarkWriteable(name: string): boolean;
    begin
      var n := ByName(name);
      Result := n<>nil;
      if not Result then exit;
      n.MarkWriteable;
    end;
    
    protected explicit_existence := false;
    
  end;
  
  {$endregion WriteableNode}
  
  {$region Group}
  
  //TODO #2264
  // - сделать конструктор, принемающий фиксер
//  GroupFixer = class;
  Group = sealed class(WriteableNode<Group>)
    private bitmask: boolean;
    private enums: Dictionary<string, int64>;
    
    private types: List<string>;
    private types_use_replacements: Dictionary<string, string>;
    
    private custom_members := new List<array of string>;
    private function BoundToAllEnums := not bitmask;
    
    private static all_enums := new Dictionary<string, int64>;
    
    private procedure AddKeyVal(key: string; val: int64);
    begin
      enums.Add(key, val);
      
      if not BoundToAllEnums then exit;
      var old_val: int64;
      if not all_enums.TryGetValue(key, old_val) then
        all_enums.Add(key, val) else
      if val <> old_val then
        raise new System.InvalidOperationException(
          $'Group [{self.name}]: Added val for [{key}] was [${val}], not [${old_val}] as in other groups'
        );
      
    end;
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader);
    begin
      
      name := br.ReadString;
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
        
        // GL_/CL_
        if not key.ToLower.StartsWith(api_name+'_') then
          raise new System.InvalidOperationException(key);
        key := key.Substring(api_name.Length+1);
        
        if key.First.IsDigit then key := '_'+key;
        
        // To not intersect with get_* methods of properties
        if key.ToLower.StartsWith('get_') then key := key.Insert(3,'_');
        AddKeyVal(key, br.ReadInt64);
        
      end;
      
      types := new List<string>(br.ReadInt32);
      types_use_replacements := new Dictionary<string, string>(types.Capacity);
      loop types.Capacity do
      begin
        var new_t := TypeTable.Convert(br.ReadString, nil);
        var found := false;
        for var i := 0 to types.Count-1 do
        begin
          var old_t := types[i];
          if old_t=new_t then raise new System.InvalidOperationException;
          
          if old_t.TrimStart('U')=new_t.TrimStart('U') then
          begin
            var unsigned_t := |old_t,new_t|.Single(t->t.StartsWith('U'));
            types[i] := unsigned_t.SubString(1);
            types_use_replacements.Add(unsigned_t, types[i]);
            found := true;
            break;
          end;
          
        end;
        
        if not found then
          types += new_t;
      end;
      types.Sort((t1,t2)->
      begin
        Result := 0;
        if t1=t2 then exit;
        
        var t_float := function(t: string): boolean ->
        case t of
          'Byte':   Result := false;
          'UInt32': Result := false;
          'single': Result := true;
        end;
        // Is floating point (false, true)
        Result += Ord(t_float(t1));
        Result -= Ord(t_float(t2));
        if Result<>0 then exit;
        
        var t_size := function(t: string): integer ->
        case t of
          'Byte':   Result := 1;
          'UInt32': Result := 4;
          'single': Result := 4;
          else raise new System.NotImplementedException(t);
        end;
        // Size (ascending)
        Result += t_size(t1);
        Result -= t_size(t2);
        if Result<>0 then exit;
        
        Otp($'ERROR: Group [{self.name}]: Failed to sort types [{t1}] vs [{t2}]');
      end);
      
    end;
    
    public function SuffixForType(t: string): string;
    begin
      if types_use_replacements.TryGetValue(t, Result) then
        t := Result;
      
      if t in |self.types[0],self.name| then
        Result := '' else
      if t in self.types then
        Result := t.First.ToUpper + t.Substring(1) else
        raise new System.InvalidOperationException($'Group [{self.name}]: Type [{t}] is not in [{self.types.JoinToString}] or [{self.types_use_replacements.JoinToString}]');
      
    end;
    
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      All.Capacity := br.ReadInt32;
      loop All.Capacity do All += new Group(br);
    end;
    
    public static procedure FixAllEndExt;
    begin
      All.RemoveAll(gr->
      begin
        Result := false;
        var gname := gr.name;
        var ext := GetExt(gname);
        if ext='' then exit;
        if gr.explicit_existence then
        begin
          Otp($'WARNING: Groups [{gname}] was explicitly added with [{ext}] at the end');
          exit;
        end;
        var s_gname := gname.Remove(gname.Length-ext.Length);
        
        if ByName(s_gname) is Group(var gr2) then
        begin
          Result := gr2.enums.Values.ToHashSet.SetEquals(gr.enums.Values);
          if Result then
          begin
            Otp($'WARNING: Group [{gr.name}] was merged into [{gr2.name}]');
            foreach var kvp in gr.enums do
              if not gr2.enums.ContainsKey(kvp.Key) then
                gr2.AddKeyVal(kvp.Key, kvp.Value);
            Group.name_cache.Remove(gname);
            Group.name_remap.Add(gname, s_gname);
          end else
            Otp($'WARNING: Group [{gname}] had different enums from [{s_gname}]');
          exit;
        end;
        
        gr.Rename(s_gname);
        
      end);
      
      foreach var gr in All do
        foreach var ename in gr.enums.Keys.ToArray do
        begin
          var curr_v := gr.enums[ename];
          if allowed_ext_names.Any(ext->
          begin
            Result := false;
            var _ext := '_'+ext;
            if not ename.EndsWith(_ext) then exit;
            var base_ename := ename.Remove(ename.Length-_ext.Length);
            var v: int64;
            var found_v := false;
            
            foreach var base_ext in |'', '_ARB', '_EXT'| do
            begin
              if _ext=base_ext then break;
              found_v := gr.enums.TryGetValue(base_ename+base_ext, v);
              if found_v then break;
            end;
            
            if not found_v then
            begin
              found_v := gr.BoundToAllEnums and all_enums.TryGetValue(base_ename, v);
              if not found_v then
              begin
                var conflict := all_enums
                  .Where(kvp->
                    (kvp.Value<>curr_v) and
                    kvp.Key.StartsWith(base_ename+'_') and (kvp.Key.SubString(base_ename.Length+1) in allowed_ext_names)
                  )
                  .Select(kvp->kvp.Key)
                  .Prepend(ename).Order
                  .JoinToString(',');
                if conflict.Length>ename.Length then
                begin
                  if LogCache.enum_conflicts.Add(conflict) then
                    log.Otp($'Enums [{conflict}] have different values');
                  exit;
                end else
                begin
                  found_v := true;
                  v := curr_v;
                end;
              end;
              if v=curr_v then
                gr.AddKeyVal(base_ename, v);
            end;
            
            if found_v then
            begin
              Result := v=curr_v;
              if not Result then
                log.Otp($'Group [{gr.name}]: Enum [{ename}]=${curr_v:X}, but without [{_ext}]=${v:X}');
            end else
              log.Otp($'Group [{gr.name}]: Enum [{ename}] had name ending in vendor name');
            
          end) then gr.enums.Remove(ename);
        end;
      
    end;
    
    public static procedure FixCL_Names :=
    foreach var gr in All do
      if gr.name.StartsWith('cl_') then
        gr.Rename(gr.name.ToWords('_').Skip(1).Select(w->
        begin
          w[0] := w[0].ToUpper;
          Result := w;
        end).JoinToString(''));
    
    private function EnumrKeys := enums.Keys.OrderBy(ename->Abs(enums[ename]));//.ThenBy(ename->ename);
    private property ValueStr[ename: string]: string read
    if not bitmask and (enums[ename]<0) then
      enums[ename].ToString else
      '$'+enums[ename].ToString('X4');
    
    public procedure Write(wr: Writer);
    begin
      if not referenced then exit;
      
      log_groups.Otp($'# {name}[{types.JoinToString(''/'')}]');
      foreach var ename in EnumrKeys do
        log_groups.Otp($'{#9}{ename} = {enums[ename]:X}');
      log_groups.Otp('');
      
      var screened_enums := enums.ToDictionary(kvp->kvp.Key, kvp->
      begin
        Result := kvp.Key;
        if Result.ToLower in pas_keywords then
          Result := '&'+Result;
      end);
      
      if not writeable then exit;
      if enums.Count=0 then Otp($'WARNING: Group [{name}] had 0 enums');
      var max_scr_w := screened_enums.Values.DefaultIfEmpty('').Max(ename->ename.Length);
      
      foreach var t in types index i do
      begin
        var cur_name := name+SuffixForType(t);
        wr +=       $'  {cur_name} = record' + #10;
        
        wr +=       $'    public val: {t};' + #10;
        wr +=       $'    public constructor(val: {t}) := self.val := val;' + #10;
        if t in |'IntPtr', 'UIntPtr'| then
          wr +=     $'    public constructor(val: Int32) := self.val := new {t}(val);' + #10;
        wr +=       $'    ' + #10;
        
        if i<>0 then
        begin
          var val_str1 := 'v.val'; if t in |'single'| then val_str1 := $'Round({val_str1})';
          var val_str2 := 'v.val';
          wr +=     $'    public static function operator implicit(v: {cur_name}): {name} := new {    name}({val_str1});' + #10;
          wr +=     $'    public static function operator implicit(v: {name}): {cur_name} := new {cur_name}({val_str2});' + #10;
          wr +=     $'    ' + #10;
        end;
        
        foreach var ename in EnumrKeys do
          wr +=     $'    public static property {screened_enums[ename]}:{'' ''*(max_scr_w-screened_enums[ename].Length)} {cur_name} read new {cur_name}({ValueStr[ename]});' + #10;
        wr +=       $'    ' + #10;
        
        if bitmask then
        begin
          
          wr +=     $'    public static function operator+(f1,f2: {cur_name}) := new {cur_name}(f1.val or f2.val);' + #10;
          wr +=     $'    public static function operator or(f1,f2: {cur_name}) := f1+f2;' + #10;
          wr +=     $'    ' + #10;
          
          wr +=     $'    public static procedure operator+=(var f1: {cur_name}; f2: {cur_name}) := f1 := f1+f2;' + #10;
          wr +=     $'    ' + #10;
          
          foreach var ename in EnumrKeys do
            if enums[ename]<>0 then
              wr += $'    public property HAS_FLAG_{screened_enums[ename]}:{'' ''*(max_scr_w-screened_enums[ename].Length)} boolean read self.val and {ValueStr[ename]} <> 0;' + #10 else
              wr += $'    public property ANY_FLAGS: boolean read self.val<>0;' + #10;
          wr +=     $'    ' + #10;
          
        end;
        
        wr +=       $'    public function ToString: string; override;' + #10;
        wr +=       $'    begin' + #10;
        if bitmask then
          wr +=     $'      var res := new StringBuilder;'+#10;
        foreach var ename in EnumrKeys do
        begin
          if bitmask and (enums[ename]=0) then continue;
          wr +=     $'      if self.val ';
          var val_str := ValueStr[ename];
          if bitmask then wr += $'and {t}({val_str}) ';
          wr += $'= {t}({val_str}) then ';
          if bitmask then
            wr +=   $'res += ''{ename}+'';' else
            wr +=   $'Result := ''{ename}'' else';
          wr += #10;
        end;
        if bitmask then
        begin
          wr +=     $'      if res.Length<>0 then'+#10;
          wr +=     $'      begin'+#10;
          wr +=     $'        res.Length -= 1;'+#10;
          wr +=     $'        Result := res.ToString;'+#10;
          wr +=     $'      end else'+#10;
          wr +=     $'      if self.val=0 then'+#10;
          wr +=     $'        Result := ''NONE'' else'+#10;
        end;
        wr +=       $'        Result := $''{cur_name}[{{self.val}}]'';'+#10;
        wr +=       $'    end;' + #10;
        wr +=       $'    ' + #10;
        
        foreach var m in custom_members do
        begin
          foreach var l in m do
            wr +=   $'    {l}' + #10;
          wr +=     $'    ' + #10;
        end;
        
        wr +=       $'  end;'+#10;
        wr +=       $'  ' + #10;
      end;
      
    end;
    public static procedure WriteAll(wr: Writer) :=
    foreach var gr in All.OrderBy(gr->gr.name) do gr.Write(wr);
    
  end;
  GroupFixer = abstract class(Fixer<GroupFixer, Group>)
    
    static constructor;
    begin
      GroupFixer.GetFixableName := gr->gr.name;
      GroupFixer.MakeNewFixable := f->
      begin
        Result := new Group;
        f.Apply(Result);
      end;
    end;
    
    public static procedure LoadAll;
    
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
      self.t := br.ReadString;
      self.rep_c := br.ReadInt64;
      
      self.ptr := br.ReadInt32;
      
      // static_arr_len
      if br.ReadInt32 <> -1 then raise new System.NotSupportedException;
      
      //TODO More uses? (only for sanity checks rn)
      var readonly_lvls := ArrGen(br.ReadInt32, i->br.ReadInt32);
      if 0 in readonly_lvls then
        // Unassignable field
        raise new System.NotSupportedException;
      
      var gr_ind := br.ReadInt32;
      self.gr := if gr_ind=-1 then nil else Group.All[gr_ind];
      
      var base_t: (string, integer) := nil;
      if br.ReadBoolean then
        base_t := (br.ReadString, br.ReadInt32);
      
      self.t := TypeTable.Convert(self.t, base_t);
      var gr_suffix := if gr=nil then '' else gr.SuffixForType(self.t);
      
      self.ptr -= self.t.Count(ch->ch='-');
      if self.ptr<0 then raise new System.InvalidOperationException;
//      if self.ptr>0 then raise new System.NotSupportedException(name); // cl_dx9_surface_info_khr содержит поле-указатель
      self.t := self.t.Remove('-').Trim + gr_suffix;
      
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
      if name in pas_keywords then
        res += '&';
      res += name;
      res += ': ';
      res.Append('^',ptr);
      res += t;
      Result := res.ToString;
    end;
    
    public procedure Write(wr: Writer);
    begin
      wr += '    ';
      if name<>nil then
      begin
        wr += vis;
        wr += ' ';
        wr += self.MakeDef;
        if def_val<>nil then
        begin
          wr += ' := ';
          wr += def_val;
        end;
        wr += ';';
        if comment<>nil then
        begin
          wr += ' // ';
          wr += comment;
        end;
      end;
      wr += #10;
    end;
    
  end;
  Struct = sealed class(WriteableNode<Struct>)
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
    
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      All.Capacity := br.ReadInt32;
      loop All.Capacity do All += new Struct(br);
    end;
    
    protected procedure OnMarkReferenced; override :=
    foreach var fld in flds do
    begin
      fld.FixT;
      if Group.MarkReferenced(fld.t) or Struct.MarkReferenced(fld.t) then else;
    end;
    protected procedure OnMarkWriteable; override :=
    foreach var fld in flds do
    begin
      fld.FixT;
      if Group.MarkWriteable(fld.t) or Struct.MarkWriteable(fld.t) then else;
    end;
    
    private static ValueStringNamesCache := new HashSet<string>;
    private static function MakeValueString(wr: Writer; len: integer): string;
    begin
      Result := $'ValueAnsiString_{len}';
      if not ValueStringNamesCache.Add(Result) then exit;
      
      log_structs.Otp($'# {Result}');
      log_structs.Otp($'{#9}body: ntv_char[{len}]');
      log_structs.Otp('');
      
      wr += '  [StructLayout(LayoutKind.Explicit, Size = ';
      wr += len.ToString;
      wr += ')]'#10;
      
      wr += '  ';
      wr += Result;
      wr += ' = record'#10;
      wr += '    '#10;
      
      wr += '    public property AnsiChars[i: integer]: Byte'#10;
      wr += '    read Marshal.ReadByte(new IntPtr(@self), i)'#10;
      wr += '    write Marshal.WriteByte(new IntPtr(@self), i, value);'#10;
      
      wr += '    public property Chars[i: integer]: char read ChrAnsi(AnsiChars[i]) write AnsiChars[i] := OrdAnsi(value); default;'#10;
      wr += '    '#10;
      
      wr += '    public constructor(s: string; can_trim: boolean := false);'#10;
      wr += '    begin'#10;
      wr += '      var len := s.Length;'#10;
      wr += '      if len>';
      wr += len-1;
      wr += ' then'#10;
      wr += '        if can_trim then'#10;
      wr += '          len := ';
      wr += len-1;
      wr += ' else'#10;
      wr += '          raise new System.OverflowException;'#10;
      wr += '      '#10;
      wr += '      self.AnsiChars[len] := 0;'#10;
      wr += '      for var i := 0 to len-1 do'#10;
      wr += '        self[i] := s[i+1];'#10;
      wr += '      '#10;
      wr += '    end;'#10;
      wr += '    '#10;
      
      wr += '    public function ToString: string; override :='#10;
      wr += '    Marshal.PtrToStringAnsi(new IntPtr(@self));'#10;
      wr += '    '#10;
      
      wr += '    public static function operator implicit(s: string): ';
      wr += Result;
      wr += ' := new ';
      wr += Result;
      wr += '(s);'#10;
      wr += '    public static function operator explicit(s: string): ';
      wr += Result;
      wr += ' := new ';
      wr += Result;
      wr += '(s, true);'#10;
      wr += '    '#10;
      
      wr += '    public static function operator implicit(s: ';
      wr += Result;
      wr += '): string := s.ToString;'#10;
      wr += '    '#10;
      
      wr += '  end;'#10;
      wr += '  '#10;
      
    end;
    
    public procedure Write(wr: Writer);
    begin
      if not referenced then exit;
      foreach var fld in flds do
        if fld.rep_c<>1 then
        begin
          if fld.t<>'ntv_char' then raise new System.NotSupportedException;
          fld.t := MakeValueString(wr, fld.rep_c);
          fld.rep_c := 1;
        end;
      
      log_structs.Otp($'# {name}');
      foreach var fld in flds do
        log_structs.Otp($'{#9}{fld.MakeDef}' + (fld.rep_c<>1 ? $'[{fld.rep_c}]' : '') );
      log_structs.Otp('');
      
      if not writeable then exit;
      wr += $'  {name} = record' + #10;
      
      foreach var fld in flds do
        fld.Write(wr);
      wr += '    '#10;
      
      var constr_flds := flds.ToList;
      constr_flds.RemoveAll(fld->fld.name=nil);
      constr_flds.RemoveAll(fld->fld.def_val<>nil);
      wr += '    public constructor(';
      wr += constr_flds.Select(fld->fld.MakeDef).JoinToString('; ');
      wr += ');'#10;
      wr += '    begin'#10;
      foreach var fld in constr_flds do
      begin
        wr += '      self.';
        wr += fld.name;
        wr += ' := ';
        if fld.name in pas_keywords then
          wr += '&';
        wr += fld.name;
        wr += ';'#10;
      end;
      wr += '    end;'#10;
      wr += '    '#10;
      
      wr +=       '  end;'#10;
      wr +=       '  '#10;
    end;
    public static procedure WriteAll(wr: Writer);
    begin
      var left := All.ToHashSet;
      
      var WriteWithDep: procedure(s: Struct); WriteWithDep := s->
      begin
        if s not in left then exit;
        foreach var fld in s.flds do
          if ByName(fld.t) is Struct(var dep) then
            WriteWithDep(dep);
        left.Remove(s);
        s.Write(wr);
      end;
      
      while left.Any do
        WriteWithDep( left.MinBy(s->s.name) );
      
    end;
    
  end;
  StructFixer = abstract class(Fixer<StructFixer, Struct>)
    
    static constructor;
    begin
      StructFixer.GetFixableName := s->s.name;
      StructFixer.MakeNewFixable := f->
      begin
        Result := new Struct;
        f.Apply(Result);
      end;
    end;
    
    public static procedure LoadAll;
    
    protected procedure WarnUnused(all_unused_for_name: List<StructFixer>); override :=
    Otp($'WARNING: {all_unused_for_name.Count} fixers of struct [{self.name}] wasn''t used');
    
  end;
  
  {$endregion Struct}
  
  {$region Func}
  
  {$region Help types}
  
  FuncOrgParam = sealed class
    public name, t: string;
    public ptr: integer;
    public static_arr_len := -1; //TODO Нигде не использовано
    public readonly_lvls := new List<integer>; //TODO Использовать в маршлинге на полную
    public gr := default(Group);
    public gr_suffix := default(string);
    
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
      
      self.t := br.ReadString;
      
      var rep_c := br.ReadInt64;
      if rep_c<>1 then
      begin
        if rep_c<1 then raise new System.InvalidOperationException(rep_c.ToString);
        self.ptr += 1;
        rep_c := 1;
      end;
      
      self.ptr := br.ReadInt32;
      
      self.static_arr_len := br.ReadInt32;
      
      self.readonly_lvls.Capacity := br.ReadInt32;
      loop readonly_lvls.Capacity do
        readonly_lvls += br.ReadInt32;
      
      var gr_ind := br.ReadInt32;
      self.gr := gr_ind=-1 ? nil : Group.All[gr_ind];
      
      var base_t: (string, integer) := nil;
      if br.ReadBoolean then
        base_t := (br.ReadString, br.ReadInt32);
      
      if self.t in KnownClasses then
      begin
        if base_t<>nil then raise new System.InvalidOperationException;
        self.t := ConvertClassName(self.t);
      end else
      if proto and (self.t.ToLower='void') and (ptr=0) then
      begin
        if base_t<>nil then raise new System.InvalidOperationException;
        self.t := nil;
      end else
      begin
        self.t := TypeTable.Convert(self.t, base_t);
        if gr<>nil then self.gr_suffix := gr.SuffixForType(self.t);
        
        foreach var s in self.t.Split('*').Reverse index i do
          if 'const' in s then
            self.readonly_lvls += self.ptr+i;
        
        self.ptr += self.t.Count(ch->ch='*');
        self.ptr -= self.t.Count(ch->ch='-');
        self.t := self.t.Remove('*','-','const').Trim;
        
        if self.ptr<0 then
          raise new MessageException($'ERROR: par [{name}] with type [{self.t}] got negative ref count: [{self.ptr}]');
        
      end;
      
    end;
    
    public function GetTName: string;
    begin
      Result := t;
      if gr=nil then exit;
      gr := Group.ByName(gr.name);
      Result := gr.name + gr_suffix;
    end;
    
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
    
    public function GetTName: string;
    begin
      if Group.ByName(tname) is Group(var gr) then
        tname := gr.name;
      Result := tname;
    end;
    
    public property IsGeneric: boolean read tname.StartsWith('T') and tname.Skip(1).All(char.IsDigit);
    
    public property IsNakedType: boolean read (Group.ByName(tname)=nil) and (Struct.ByName(tname)=nil);
    
    public function ToString(generate_code: boolean; with_var: boolean := false): string;
    begin
      if generate_code then
      begin
        var res := new StringBuilder;
        if with_var and var_arg then res += 'var ';
        loop arr_lvl do res += 'array of ';
        res += GetTName;
        Result := res.ToString;
      end else
        Result := $'({var_arg}, {arr_lvl}, {GetTName})';
    end;
    public function ToString: string; override := ToString(false);
    
    public static function operator=(par1,par2: FuncParamT): boolean;
    begin
      var par1_nil := Object.ReferenceEquals(par1,nil);
      var par2_nil := Object.ReferenceEquals(par2,nil);
      Result :=
        if par1_nil then par2_nil else
        not par2_nil and
        (par1.var_arg   = par2.var_arg) and
        (par1.arr_lvl   = par2.arr_lvl) and
        (par1.GetTName  = par2.GetTName);
    end;
    
    public function Equals(other: FuncParamT) := self=other;
    
  end;
  FuncOverload = sealed class(System.IEquatable<FuncOverload>)
    public pars: array of FuncParamT;
    public constructor(pars: array of FuncParamT) := self.pars := pars;
    
    public static function operator implicit(pars: array of FuncParamT): FuncOverload := new FuncOverload(pars);
    
    public static function operator=(ovr1, ovr2: FuncOverload): boolean;
    begin
      if ovr1.pars.Length<>ovr2.pars.Length then raise new System.InvalidOperationException;
      Result := ovr1.pars.Zip(ovr2.pars, (par1,par2)->par1=par2).All(b->b);
    end;
    
    public function Equals(other: FuncOverload) := self=other;
    public function GetHashCode: integer; override :=
    pars.Where(par->par<>nil).Aggregate(0, (res,par)->res xor par.GetTName.GetHashCode);
    
  end;
  
  FuncParamMarshaler = sealed class
    public par: FuncParamT;
    
    /// Changes to name of var with marshaled value
    public par_str := default(string);
    /// 'abc('#0')' will call abc() func on result
    public res_par_conv := default(string);
    
    public vars := new List<(string, string)>;
    public init := new StringBuilder;
    public fnls := new StringBuilder;
    
    public constructor(par: FuncParamT; par_str: string);
    begin
      self.par     := par;
      self.par_str := par_str;
    end;
    private constructor := raise new System.InvalidOperationException;
    
  end;
  FuncOvrMarshalers = sealed class
    private marshalers: array of record
      lst := new List<FuncParamMarshaler>;
      ind := 0;
    end;
    
    public constructor(par_c: integer) := SetLength(marshalers, par_c);
    private constructor := raise new System.InvalidOperationException;
    
    public procedure AddMarshaler(par_i: integer; m: FuncParamMarshaler);
    begin
      marshalers[par_i].lst += m;
      marshalers[par_i].ind += 1;
    end;
    
    public procedure Seal :=
    for var i := 0 to marshalers.Length-1 do
      if marshalers[i].lst.Count=0 then
        marshalers[i].lst := nil else
      begin
        marshalers[i].lst.Capacity := marshalers[i].lst.Count;
        marshalers[i].lst.Reverse;
      end;
    
    public function MaxMarshalInd: integer;
    begin
      Result := -1; // Default "-1" if "marshalers.Length=0"
      for var par_i := 0 to marshalers.Length-1 do
        Result := Max(Result, marshalers[par_i].ind);
    end;
    
    public function GetCurrent(par_i: integer) :=
    marshalers[par_i].lst[marshalers[par_i].ind];
    
    public function GetPossible(par_i, max_ind: integer): (boolean,FuncParamMarshaler);
    begin
      var ind := marshalers[par_i].ind;
      var is_fast_forward := false;
      if ind<>0 then
      begin
        is_fast_forward := ind<=max_ind;
        ind -= 1;
        if not is_fast_forward then
          marshalers[par_i].ind := ind;
      end;
      Result := (is_fast_forward, marshalers[par_i].lst[ind]);
    end;
    public procedure ChosenFastForward(par_i: integer) :=
    marshalers[par_i].ind -= 1;
    
  end;
  MethodImplData = sealed class
    public pars: array of FuncParamMarshaler;
    public name := default(string);
    public is_public := false;
    public call_by := new List<MethodImplData>;
    public call_to := default(MethodImplData); // "nil" if this is a native method
    
    public constructor(pars: array of FuncParamMarshaler) := self.pars := pars;
    
  end;
  
  MultiBooleanChoise = record
    private flags: array of integer;
    public state := 0;
    
    public property Flag[i: integer]: boolean read (state and flags[i]) <> 0;
    
  end;
  MultiBooleanChoiseSet = record
    public size := 1;
    private flags: array of integer;
    
    private procedure Init(c: integer; can: array of boolean);
    begin
      flags := new integer[c];
      for var i := 0 to c-1 do
      begin
        if (can<>nil) and not can[i] then continue;
        flags[i] := size;
        size *= 2;
      end;
      if size=0 then raise new System.NotSupportedException; // >32
    end;
    
    public constructor(c: integer) := Init(c, nil);
    public constructor(can: array of boolean) := Init(can.Length, can);
    public constructor := raise new System.InvalidOperationException;
    
    public function Enmr: sequence of MultiBooleanChoise;
    begin
      var res: MultiBooleanChoise;
      res.flags := self.flags;
      while res.state<self.size do
      begin
        yield res;
        res.state += 1;
      end;
    end;
    
  end;
  
  {$endregion Help types}
  
  Func = sealed class(WriteableNode<Func>)
    
    {$region Basic}
    
    public org_par: array of FuncOrgParam;
    
    public ext_name: string;
    public is_proc: boolean;
    public procedure BasicInit;
    begin
      name := org_par[0].name;
      ext_name := GetExt(name);
      is_proc := org_par[0].t=nil;
      if is_proc then org_par[0] := nil;
    end;
    
    private static fixed_names := new HashSet<string>;
    
    {$endregion Basic}
    
    {$region Misc}
    
    public constructor := exit;
    public constructor(br: System.IO.BinaryReader);
    begin
      org_par := ArrGen(br.ReadInt32, i->new FuncOrgParam(br, i=0));
      BasicInit;
    end;
    
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      All.Capacity := br.ReadInt32;
      loop All.Capacity do All += new Func(br);
    end;
    
    {$endregion Misc}
    
    {$region PPT}
    
    // ": array of possible_par_type_collection"
    public possible_par_types: array of List<FuncParamT>;
    public unopt_arr: array of boolean;
    public procedure InitPossibleParTypes;
    begin
      if possible_par_types<>nil then exit;
      unopt_arr := ArrFill(org_par.Length, false);
      possible_par_types := org_par.ConvertAll((par,par_i)->
      begin
        if is_proc and (par_i=0) then exit;
        
        if par.ptr=0 then
        begin
          var t := par.GetTName;
          if t='ntv_char' then
          begin
            log.Otp($'Param [{par.name}] with type [{par.t}] in func [{self.name}]');
            t := 'SByte';
          end;
          Result := Lst(new FuncParamT(false, 0, t));
        end else
        begin
          var t := par.GetTName;
          var ptr := par.ptr;
          
          var is_string := t='ntv_char';
          if is_string then
          begin
            t := 'string';
            ptr -= 1;
          end;
          
          if par_i=0 then
          begin
            if (ptr<>0) and is_string then
              Otp($'ERROR: Func [{self.name}] returns pointer to strings');
            Result := Lst(new FuncParamT(false, 0, '^'*ptr + t));
            exit;
          end;
          
          var org_t := t;
          
          var need_var := ptr<>0;
          var need_arr := need_var and (t<>'boolean');
          var need_plain := if is_string then (par.ptr in par.readonly_lvls) or (ptr<>0) else true;
          var need_str_ptr := (par_i<>0) and is_string;
          var skip_last_arr := need_arr and ( (ptr>1) or is_string );
          var cap := ptr*ord(need_arr) + ord(need_var) + Ord(need_plain) + ord(need_str_ptr) - ord(skip_last_arr);
          Result := new List<FuncParamT>(cap);
          
          if need_str_ptr and (ptr<>0) then
          begin
            Result += new FuncParamT(false, ptr, 'string');
            t := 'IntPtr';
          end;
          
          if need_arr then for var i := ptr downto 1 do
          begin
            if (i=1) and (t<>org_t) then break;
            Result += new FuncParamT(false, i, t);
            if i>1 then t := 'IntPtr';
          end;
          
          if ptr>0 then
          begin
            Result += new FuncParamT(true, 0, t);
            t := if t='IntPtr' then 'pointer' else 'IntPtr';
          end;
          
          if need_plain then
            Result += new FuncParamT(false, 0, t);
          
          if need_str_ptr and (ptr=0) then
            Result += new FuncParamT(false, 0, 'IntPtr');
          
          if Result.Count<>cap then raise new System.InvalidOperationException;
        end;
        
      end);
    end;
    
    private procedure _FixAllGet;
    begin
      if all_overloads<>nil then exit;
      
      var fix_pars := org_par.ConvertAll((par,par_i)->
      begin
        Result := false;
        if par_i=0 then exit;
        Result := par.name.EndsWith('_ret');
      end);
      var fix_all_pars := 'Get' in name;
      if not fix_pars.Any(b->b) and not fix_all_pars then exit;
      InitPossibleParTypes;
      
      for var par_i := 1 to possible_par_types.Length-1 do
      begin
        var ppt := possible_par_types[par_i];
        if ppt[0].arr_lvl<>1 then continue;
        var need_keep := ppt[0].arr_lvl in org_par[par_i].readonly_lvls;
        var need_rem := fix_pars[par_i] or (fix_all_pars and not need_keep);
        if need_keep and need_rem then raise new System.NotImplementedException(name);
        if need_rem then ppt.RemoveAll(par->par.arr_lvl=1);
      end;
      
    end;
    public static procedure FixAllGet :=
    foreach var f in All do f._FixAllGet;
    
    private procedure _FixCL;
    begin
      if all_overloads<>nil then exit;
      var rev_pars := org_par?[:-Ord(is_proc):-1];
      
      var rem_from := procedure(ppt: List<FuncParamT>; t: FuncParamT)->
      if not ppt.Remove(t) then Otp($'ERROR: Func [{self.name}] failed to FixCL, removing [{t}] from par#{possible_par_types.IndexOf(ppt)}: {_ObjectToString(ppt.Select(par->par.ToString(true,true)))}');
      
      if rev_pars.Length < 1 then exit;
      var last_err_code := rev_pars[0].GetTName = 'ErrorCode';
      if last_err_code then
      begin
        InitPossibleParTypes;
        rem_from(possible_par_types[^1], new FuncParamT('IntPtr'));
      end;
      
      var ind_sh := Ord(last_err_code);
      if rev_pars.Length < 2+ind_sh then exit;
      if rev_pars.Skip(ind_sh).Take(2).All(par->(par.GetTName='cl_event') and (par.ptr=1)) then
      begin
        InitPossibleParTypes;
        rem_from(possible_par_types[^(1+ind_sh)], new FuncParamT('array of cl_event'));
        unopt_arr[^(2+ind_sh)] := true;
      end;
      
    end;
    public static procedure FixCL :=
    foreach var f in All do f._FixCL;
    
    {$endregion PPT}
    
    {$region Overloads}
    
    public all_overloads: List<FuncOverload>;
    public procedure InitOverloads;
    begin
      if all_overloads<>nil then exit;
      InitPossibleParTypes;
      
      var opt_arr := new boolean[org_par.Length];
      foreach var types in possible_par_types index par_i do
      begin
        if is_proc and (par_i=0) then continue;
        if unopt_arr[par_i] then continue;
        opt_arr[par_i] := types.Any(par->par.arr_lvl=0) and types.Any(par->par.arr_lvl<>0);
        if unopt_arr[par_i] then
          if opt_arr[par_i] then
            opt_arr[par_i] := false else
            Otp($'WARNING: Func [{self.name}] had par#{par_i} as unopt_arr, but it does not need it: {_ObjectToString(types.Select(par->par.ToString(true,true)))}');
      end;
      
      var cap := 1;
      var par_ind_div := new integer[org_par.Length];
      for var par_i := org_par.Length-1 downto 0 do
      begin
        if is_proc and (par_i=0) then continue;
        
        par_ind_div[par_i] := cap;
        cap *= possible_par_types[par_i].Count;
        
        possible_par_types[par_i].Sort((p1,p2)->
        begin
          Result := 0;
          if object.ReferenceEquals(p1,p2) then exit; // Because List.Sort
          if p1=p2 then raise new System.InvalidOperationException(
            $'ERROR: Func [{self.name}] par#{par_i}: Type [{p1.ToString(true,true)}] is allowed twice'
          );
          
          // 1. arr_lvl (descending)
          Result -= p1.arr_lvl;
          Result += p2.arr_lvl;
          if Result<>0 then exit;
          
          // 2. var- vs plain
          Result -= Ord(p1.var_arg);
          Result += Ord(p2.var_arg);
          if Result<>0 then exit;
          
          // 3. string vs IntPtr
          Result -= Ord(p1.tname='string');
          Result += Ord(p2.tname='string');
          if Result<>0 then exit;
          
          // 4. special vs generic
          Result += Ord(p1.IsGeneric);
          Result -= Ord(p2.IsGeneric);
          
          // 5. OpenGL.Vec** vs plain
          Result -= Ord(p1.tname.StartsWith('Vec') and p1.tname.Skip('Vec'.Length).FirstOrDefault.InRange('1','4'));
          Result += Ord(p2.tname.StartsWith('Vec') and p2.tname.Skip('Vec'.Length).FirstOrDefault.InRange('1','4'));
          if Result<>0 then exit;
          
          // 6. Group vs naked
          Result += Ord(p1.IsNakedType);
          Result -= Ord(p2.IsNakedType);
          if Result<>0 then exit;
          
          // 7. Different reference target or enum group
          if p1.var_arg or (p1.arr_lvl<>0) or not p1.IsNakedType then
            Result := string.Compare(p1.tname, p2.tname);
          if Result<>0 then exit;
          
          Otp($'ERROR: Func [{self.name}] par#{par_i}: Failed to sort [{p1.ToString(true,true)}] vs [{p2.ToString(true,true)}]');
        end);
        
      end;
      
      all_overloads := new List<FuncOverload>(cap);
      for var only_arr_ovrs := opt_arr.Any(b->b) downto false do
        for var par_state := 0 to cap-1 do
        begin
          var ppt_inds := new integer[org_par.Length];
          for var par_i := 0 to ppt_inds.Length-1 do
          begin
            if is_proc and (par_i=0) then continue;
            var ppt_ind := par_state div par_ind_div[par_i] mod possible_par_types[par_i].Count;
            if opt_arr[par_i] and (ppt_ind=0 <> only_arr_ovrs) then
            begin
              ppt_inds := nil;
              break;
            end;
            ppt_inds[par_i] := ppt_ind;
          end;
          if ppt_inds=nil then continue;
          var ovr := ArrGen(org_par.Length, par_i->
            is_proc and (par_i=0) ? nil :
              possible_par_types[par_i][ppt_inds[par_i]]
          );
          all_overloads += FuncOverload(ovr);
        end;
        
    end;
    
    {$endregion Overloads}
    
    {$region MarkUsed}
    
    protected procedure OnMarkReferenced; override;
    begin
      InitOverloads;
      foreach var ovr in all_overloads do
        foreach var par in is_proc ? ovr.pars.Skip(1) : ovr.pars do
        begin
          var tname := par.tname.TrimStart('^');
          Group.MarkReferenced(tname);
          Struct.MarkReferenced(tname);
        end;
    end;
    protected procedure OnMarkWriteable; override;
    begin
      InitOverloads;
      foreach var ovr in all_overloads do
        foreach var par in is_proc ? ovr.pars.Skip(1) : ovr.pars do
        begin
          var tname := par.tname.TrimStart('^');
          Group.MarkWriteable(tname);
          Struct.MarkWriteable(tname);
        end;
    end;
    
    {$endregion MarkUsed}
    
    public static prev_func_names := new HashSet<string>;
    //TODO #2623
    /// Name of type-substitute for generic type
    const gen_t_sub = 'Byte';
    public procedure Write(wr: Writer; api, version: string; static_container: boolean);
    begin
      if not self.writeable then
        raise new System.InvalidOperationException($'MarkWriteable was not called');
      InitOverloads;
      
      {$region Log and Warn}
      
      if LogCache.loged_ffo.Add(self.name) then
      begin
        log_func_ovrs.Otp($'# {name}[{all_overloads.Count}]:');
        
        if not is_proc or (org_par.Length>1) then
        begin
          var i_off := integer(is_proc);
          var need_par_names := org_par.Length>1;
          
          var max_w := new integer[org_par.Length-i_off];
          var tt := new string[all_overloads.Count+Ord(need_par_names), max_w.Length];
          foreach var ovr in all_overloads index ovr_i do
            for var i := i_off to org_par.Length-1 do
            begin
              var tt_i := i-i_off;
              var s := ovr.pars[i].ToString(true, true);
              max_w[tt_i] := Max(max_w[tt_i], s.Length);
              tt[ovr_i, tt_i] := s;
            end;
          if need_par_names then
            for var i := 1 to org_par.Length-1 do
            begin
              var s := if i=0 then '' else org_par[i].name.TrimStart('&');
              var tt_i := i-i_off;
              max_w[tt_i] := Max(max_w[tt_i], s.Length);
              tt[all_overloads.Count, tt_i] := s;
            end;
          
          var l_cap := 1+max_w.Sum + max_w.Length*3;
          var l := new StringBuilder(l_cap);
          for var ovr_i := 0 to tt.GetLength(0)-1 do
          begin
            l += #9;
            
            if ovr_i=all_overloads.Count then
            begin
              
              foreach var w in max_w index tt_i do
              begin
                loop w do l += '-';
                l += ' | ';
              end;
              
              l.Length -= 1;
              log_func_ovrs.Otp(l.ToString);
              l.Clear;
              l += #9;
            end;
            
            foreach var w in max_w index tt_i do
            begin
              var s := tt[ovr_i, tt_i];
              l += s;
              //TODO #2664
              for var todo2664 := 1 to w-s.Length do l += ' ';
              l += ' | ';
            end;
            
            {$ifdef DEBUG}
            if l.Length<>l_cap then raise new System.InvalidOperationException((l,l.Length,l_cap,_ObjectToString(max_w),_ObjectToString(tt)).ToString);
            {$endif DEBUG}
            l.Length -= 1;
            log_func_ovrs.Otp(l.ToString);
            l.Clear;
          end;
          
        end;
        
        log_func_ovrs.Otp('');
      end;
      
      if all_overloads.Count=0 then
      begin
        Otp($'ERROR: Func [{name}] ended up having 0 overloads. [possible_par_types]:');
        foreach var par in possible_par_types index par_i do
        begin
          if is_proc and (par_i=0) then continue;
          Otp(#9+_ObjectToString(par.Select(p->p.ToString(true,true))));
        end;
        exit;
      end else
      for var par_i := 0 to org_par.Length-1 do
      begin
        if is_proc and (par_i=0) then continue;
        
        foreach var t in possible_par_types[par_i] do
        begin
          if all_overloads.Any(ovr->ovr.pars[par_i]=t) then continue;
          Otp($'WARNING: Func [{self.name}] par#{par_i} ppt [{t.ToString(true,true)}] did not appear in final overloads. Use !ppt fixer to remove it, if this is intentional');
        end;
        
      end;
      
      if self.name not in fixed_names then
      begin
        if all_overloads.Count>12 then
          Otp($'WARNING: {all_overloads.Count} overloads of non-fixed Func [{name}]');
        if self.ext_name<>'' then
        begin
          var name_wo_ext := self.name[:^self.ext_name.Length];
          if name_wo_ext in fixed_names then
            Otp($'WARNING: Func [{name_wo_ext}] was fixed, but [{name}] was not');
        end else
        begin
          var fixed_ext := fixed_names.FirstOrDefault(name->
            name.StartsWith(self.name) and
            name.Substring(self.name.Length).All(
              ch->ch.IsUpper or ch.IsDigit
            )
          );
          if fixed_ext<>nil then
            Otp($'WARNING: Func [{fixed_ext}] was fixed, but [{name}] was not');
        end;
      end;
      
      {$endregion Log and Warn}
      
      {$region MiscInit}
      
      for var par_i := 1 to org_par.Length-1 do
        if all_overloads.Any(ovr->org_par[par_i].name.ToLower in ovr.pars.Skip(1).Select(org_par->org_par.GetTName.ToLower).Append('pointer')) then
          org_par[par_i].name := '_' + org_par[par_i].name;
      
      var l_name := name;
      if l_name.ToLower.StartsWith(api.ToLower) then
        l_name := l_name.Substring(api.Length) else
      if api<>'gdi' then
        log.Otp($'Func [{name}] had api [{api}], which isn''t start of it''s name');
      prev_func_names += l_name.ToLower;
      
      if not static_container then
        wr += $'    private z_{l_name}_adr := GetProcAddress(''{name}'');' + #10;
      
      {$endregion MiscInit}
      
      {$region WriteOvrT}
      
      var WriteOvrT := procedure(wr: Writer; pars: array of FuncParamT; generic_names: HashSet<string>; name: string)->
      begin
        
        if static_container and (name<>nil) then wr += 'static ';
        wr += is_proc ? 'procedure' : 'function';
        
        if name<>nil then
        begin
          wr += ' ';
          wr += name;
          if (generic_names<>nil) and (generic_names.Count<>0) then
          begin
            wr += '<';
            wr += generic_names.JoinToString(',');
            wr += '>';
          end;
        end;
        
        if pars.Length>1 then
        begin
          wr += '(';
          var first_par := true;
          for var par_i := 1 to pars.Length-1 do
          begin
            var par := pars[par_i];
            if first_par then
              first_par := false else
              wr += '; ';
            if par.var_arg then wr += 'var ';
            wr += org_par[par_i].name;
            wr += ': ';
            //TODO #2664
            for var todo2664 := 1 to par.arr_lvl do wr += 'array of ';
            var tname := par.GetTName;
            if tname.ToLower in prev_func_names then wr += 'OpenGL.';
            wr += tname;
          end;
          wr += ')';
        end;
        
        if not is_proc then
        begin
          wr += ': ';
          wr += pars[0].ToString(true);
        end;
        
      end;
      
      {$endregion WriteOvrT}
      
      //TODO FuncParamMarshaler безполезен
      // - Вся информация хранится в FuncParamT
      // - И получать init,fnls и т.п. лучше на стадии кодогенерации
      {$region MakeMarshlers}
      
      //TODO #2623
      var gen_t_sub := gen_t_sub;
      var all_ovr_marshalers := all_overloads.ConvertAll(ovr->
      begin
        Result := new FuncOvrMarshalers(org_par.Length);
        for var par_i := 0 to ovr.pars.Length-1 do
        begin
          if is_proc and (par_i=0) then continue;
          var par := ovr.pars[par_i];
          if (par.var_arg) and (par.arr_lvl<>0) then raise new System.NotSupportedException;
          
          var initial_par_str := if par_i=0 then 'Result' else org_par[par_i].name;
          var relevant_m := new FuncParamMarshaler(par, initial_par_str);
          
          {$region Result}
          if par_i=0 then
          begin
            // Cannot determine array size if it is returned
            if par.var_arg or (par.arr_lvl<>0) then raise new System.NotSupportedException;
            
            {$region boolean}
            
            if par.tname='boolean' then
            begin
              relevant_m.res_par_conv := '0<>'#0'';
              Result.AddMarshaler(par_i, relevant_m);
              
              par := new FuncParamT(false, 0, 'byte');
              relevant_m := new FuncParamMarshaler(par, initial_par_str);
            end;
            
            {$endregion boolean}
            
            {$region string}
            
            if par.tname='string' then
            begin
              var str_ptr_name := $'{relevant_m.par_str}_str_ptr';
              relevant_m.vars += (str_ptr_name, 'IntPtr');
              
              begin
                var fnls := relevant_m.fnls;
                fnls += relevant_m.par_str;
                fnls += ' := Marshal.PtrToStringAnsi(';
                fnls += str_ptr_name;
                fnls += ');';
                if org_par[par_i].ptr not in org_par[par_i].readonly_lvls then
                begin
                  fnls += #10;
                  fnls += 'Marshal.FreeHGlobal(';
                  fnls += str_ptr_name;
                  fnls += ');';
                end;
              end;
              
              relevant_m.par_str := str_ptr_name;
              Result.AddMarshaler(par_i, relevant_m);
              
              par := new FuncParamT(false, 0, 'IntPtr');
              relevant_m := new FuncParamMarshaler(par, initial_par_str);
            end;
            
            {$endregion string}
            
          end
          {$endregion Result}
          else
          {$region Param}
          begin
            
            {$region boolean}
            
            if (par.tname='boolean') and not par.var_arg then
            begin
              if par.arr_lvl<>0 then raise new System.NotImplementedException(
                $'Func [{name}] par#{par_i} [{par}]: Standard boolean marshaling will gen in the way of copying'
              );
              
              relevant_m.par_str := $'byte({relevant_m.par_str})';
              Result.AddMarshaler(par_i, relevant_m);
              
              par := new FuncParamT(false, 0, 'byte');
              relevant_m := new FuncParamMarshaler(par, initial_par_str);
            end;
            
            {$endregion boolean}
            
            {$region string}
            
            // Note: This is before "array of array of string", because string=>IntPtr conversion is not just a copy
            if par.tname='string' then
            begin
              var str_ptr_name := $'{relevant_m.par_str}_str_ptr';
              if par.arr_lvl<>0 then str_ptr_name += 's';
              relevant_m.vars += (str_ptr_name, 'array of '*par.arr_lvl + 'IntPtr');
              
              begin
                var init := relevant_m.init;
                init += str_ptr_name;
                init += ' := ';
                var el_str := relevant_m.par_str;
                for var i := 1 to par.arr_lvl do
                begin
                  var new_el_str := 'arr_el'+i;
                  init += el_str;
                  init += '?.ConvertAll(';
                  init += new_el_str;
                  init += '->'#10;
                  //TODO #2664
                  for var temp2664 := 1 to i do init += '  ';
                  el_str := new_el_str;
                end;
                init += 'Marshal.StringToHGlobalAnsi(';
                init += el_str;
                for var i := par.arr_lvl downto 0 do
                begin
                  init += ')';
                  init += if i=0 then
                    ';' else #10;
                  for var temp2664 := 1 to i-1 do init += '  ';
                end;
              end;
              
              begin
                var fnls := relevant_m.fnls;
                var el_str := str_ptr_name;
                for var i := 1 to par.arr_lvl do
                begin
                  var new_el_str := 'arr_el'+i;
                  fnls += 'if ';
                  fnls += el_str;
                  fnls += '<>nil then foreach var ';
                  fnls += new_el_str;
                  fnls += ' in ';
                  fnls += el_str;
                  fnls += ' do'#10;
                  //TODO #2664
                  for var temp2664 := 1 to i do fnls += '  ';
                  el_str := new_el_str;
                end;
                fnls += 'Marshal.FreeHGlobal(';
                fnls += el_str;
                fnls += ');';
              end;
              
              relevant_m.par_str := str_ptr_name;
              Result.AddMarshaler(par_i, relevant_m);
              
              par := new FuncParamT(false, par.arr_lvl, 'IntPtr');
              relevant_m := new FuncParamMarshaler(par, initial_par_str);
            end;
            
            {$endregion string}
            
            {$region array of array}
            
            // Handle "array of array" separately, because they can't be passed without copy
            // Note: This is before generic, because "array of array of T" also needs copy
            //TODO This generates only [In] version... Without even specifying [In]
            while par.arr_lvl>1 do
            begin
              var temp_arr_name := $'{relevant_m.par_str}_temp_arr';
              relevant_m.vars += (temp_arr_name, 'array of '*(par.arr_lvl-1) + 'IntPtr');
              
              begin
                var init := relevant_m.init;
                init += temp_arr_name;
                init += ' := ';
                init += relevant_m.par_str;
                for var i := 1 to par.arr_lvl-2 do
                begin
                  init += '?.ConvertAll(arr_el';
                  init += i.ToString;
                  init += '->'#10;
                  //TODO #2664
                  for var temp2664 := 1 to i do init += '  ';
                  init += 'arr_el';
                  init += i.ToString;
                end;
                init += '?.ConvertAll(managed_a->'#10;
                
                for var temp2664 := 1 to par.arr_lvl-1 do init += '  '; init += 'if (managed_a=nil) or (managed_a.Length=0) then'#10;
                for var temp2664 := 1 to par.arr_lvl-1 do init += '  '; init += '  Result := IntPtr.Zero else'#10;
                for var temp2664 := 1 to par.arr_lvl-1 do init += '  '; init += 'begin'#10;
                for var temp2664 := 1 to par.arr_lvl-1 do init += '  '; init += '  var l := managed_a.Length*Marshal.SizeOf&<'; init += par.GetTName; init += '>;'#10;
                for var temp2664 := 1 to par.arr_lvl-1 do init += '  '; init += '  Result := Marshal.AllocHGlobal(l);'#10;
                for var temp2664 := 1 to par.arr_lvl-1 do init += '  '; init += '  Marshal.Copy(managed_a,0,Result,l);'#10;
                for var temp2664 := 1 to par.arr_lvl-1 do init += '  '; init += 'end';
                
                for var i := par.arr_lvl-1 downto 1 do
                begin
                  init += #10;
                  for var temp2664 := 1 to i-1 do init += '  ';
                  init += ')';
                end;
                init += ';';
              end;
              
              begin
                var fnls := relevant_m.fnls;
                var el_str := temp_arr_name;
                for var i := 1 to par.arr_lvl-1 do
                begin
                  var new_el_str := 'arr_el'+i;
                  fnls += 'if ';
                  fnls += el_str;
                  fnls += '<>nil then foreach var ';
                  fnls += new_el_str;
                  fnls += ' in ';
                  fnls += el_str;
                  fnls += ' do'#10;
                  //TODO #2664
                  for var temp2664 := 1 to i do fnls += '  ';
                  el_str := new_el_str;
                end;
                fnls += 'Marshal.FreeHGlobal(';
                fnls += el_str;
                fnls += ');';
              end;
              
              relevant_m.par_str := temp_arr_name;
              Result.AddMarshaler(par_i, relevant_m);
              
              par := new FuncParamT(false, par.arr_lvl-1, 'IntPtr');
              relevant_m := new FuncParamMarshaler(par, initial_par_str);
            end;
            
            if par.arr_lvl=1 then
            begin
              relevant_m.par_str := relevant_m.par_str; // +'[0]'; - but it will be added in codegen stage
              Result.AddMarshaler(par_i, relevant_m);
              
              par := new FuncParamT(true, 0, par.GetTName);
              relevant_m := new FuncParamMarshaler(par, initial_par_str);
            end;
            
            {$endregion array of array}
            
            {$region genetic}
            
            //TODO Instead of boolean check, parameter should have type BooleanByte
            // - And boolean itself should be disallowed except for plain case
            // - glAreTexturesResidentEXT rn only returns 1 value
            //TODO Tho type manipulation with [FieldOffset] to convert boolean to byte - also works
            if par.IsGeneric or (par.tname='boolean') then
            begin
              // Ovr's like "p<T>(o: T)" don't make sense
              if not par.var_arg then raise new System.NotSupportedException;
              
              relevant_m.par_str := $'P{gen_t_sub}(pointer(@{relevant_m.par_str}))^';
              Result.AddMarshaler(par_i, relevant_m);
              
              par := new FuncParamT(par.var_arg, par.arr_lvl, gen_t_sub);
              relevant_m := new FuncParamMarshaler(par, initial_par_str);
            end;
            
            {$endregion genetic}
            
          end;
          {$endregion Param}
          
          Result.AddMarshaler(par_i, relevant_m);
        end;
        Result.Seal; // Reverses marshalers order
      end);
      
      {$endregion MakeMarshlers}
      
      {$region MakeMethodList}
      var MethodList := new List<MethodImplData>;
      begin
        var MethodByPars := new Dictionary<FuncOverload, MethodImplData>;
        
        var pending_md := new MethodImplData[all_overloads.Count];
        // First add all public methods to MethodList
        // This also checks for duplicates in overloads
        foreach var ovr_m: FuncOvrMarshalers in all_ovr_marshalers index ovr_i do
        begin
          var ovr := all_overloads[ovr_i];
          
          var curr_marshalers := ArrGen(ovr.pars.Length, par_i->
          begin
            if is_proc and (par_i=0) then exit;
            // max_ind=0 to force choose next marshler
            var (is_fast_forward, m) := ovr_m.GetPossible(par_i, 0);
            if is_fast_forward then raise new System.InvalidOperationException;
            Result := m;
          end);
          
          var md := new MethodImplData(curr_marshalers);
          md.name := l_name;
          md.is_public := true;
          pending_md[ovr_i] := md;
          MethodByPars.Add(curr_marshalers.ConvertAll(m->m?.par), md);
          MethodList.Add(md);
        end;
        
        MethodList.Reverse;
        // Then another reverse at the end, to have better method order
        foreach var ovr_m: FuncOvrMarshalers in all_ovr_marshalers index ovr_i do
        begin
          var prev_md := pending_md[ovr_i];
          
          for var max_marshaler_ind := (all_ovr_marshalers[ovr_i].MaxMarshalInd-1).ClampBottom(0) downto 0 do
          begin
            var can_be_fast_forward := new boolean[org_par.Length];
            var possible_m := new FuncParamMarshaler[org_par.Length];
            for var par_i := 0 to org_par.Length-1 do
            begin
              if is_proc and (par_i=0) then continue;
              (can_be_fast_forward[par_i], possible_m[par_i]) := ovr_m.GetPossible(par_i, max_marshaler_ind);
            end;
            
            var new_pars := default(FuncOverload);
            var new_md := default(MethodImplData);
            var found_md := default(MethodImplData);
            foreach var fast_forward in MultiBooleanChoiseSet.Create(can_be_fast_forward).Enmr do
            begin
              var curr_marshalers := ArrGen(org_par.Length, par_i->
                is_proc and (par_i=0) ?
                  nil :
                fast_forward.Flag[par_i] ?
                  possible_m[par_i] :
                  ovr_m.GetCurrent(par_i)
              );
              var pars: FuncOverload := curr_marshalers.ConvertAll(m->m?.par);
              
              if fast_forward.state=0 then
              begin
                new_pars := pars;
                new_md := new MethodImplData(curr_marshalers);
              end;
              
              if not MethodByPars.TryGetValue(pars, found_md) then continue;
              
              if max_marshaler_ind<>0 then break;
              // Native method. It should be called instead of another method with same parameters
              
              if fast_forward.state<>0 then raise new System.InvalidOperationException;
              
              foreach var calling_md in found_md.call_by do
              begin
                new_md.call_by += calling_md;
                calling_md.call_to := new_md;
              end;
              found_md.call_by := nil;
              
              MethodByPars.Remove(pars);
              // Can't remove public methods, even if they have same pars
              if not found_md.is_public then
                MethodList.Remove(found_md);
              
              found_md := nil;
            end;
            
            var md := found_md ?? new_md;
            if found_md=nil then
            begin
              md.name := (if max_marshaler_ind=0 then 'z_' else 'temp_') + l_name;
              MethodList.Add(md);
              MethodByPars.Add(new_pars, md);
            end;
            
            md.call_by += prev_md;
            prev_md.call_to := md;
            if found_md<>nil then break;
            prev_md := md;
          end;
          
        end;
        MethodList.Reverse;
        
      end;
      {$endregion MakeMethodList}
      
      {$region CodeGen}
      
      begin
        var method_names := new HashSet<string>;
        foreach var md in MethodList do
        begin
          
          if not md.is_public then
            md.name := (1).Step(1)
            .Select(i->$'{md.name}_{i}')
            .First(method_names.Add);
          
          if md.name.ToLower in pas_keywords then
            md.name := '&'+md.name;
          
        end;
      end;
      
//      foreach var md in MethodList do
//      begin
//        PABCSystem.Write(md.name);
//        PABCSystem.Write('(');
//        PABCSystem.Write(md.pars.Select(m->m?.par.ToString(true,true)).Where(s->s<>nil).JoinToString('; '));
//        PABCSystem.Write(')');
//        if md.call_to<>nil then
//        begin
//          PABCSystem.Write(' => ');
//          PABCSystem.Write(md.call_to.name);
//        end;
//        Writeln;
//      end;
//      Writeln;
//      Halt;
      
      foreach var md in MethodList do
      begin
        if md.call_to not in MethodList.Prepend(nil) then raise new System.InvalidOperationException(l_name);
        var pars := md.pars.ConvertAll(m->m?.par);
        
        if md.call_to=nil then
        {$region Native}
        begin
          
          if static_container then
          begin
            
            wr += '    private ';
            WriteOvrT(wr, pars,nil, md.name);
            wr += ';'#10;
            wr += '    external ''';
            wr += GetDllNameForAPI(api);
            wr += ''' name ''';
            wr += name;
            wr += ''';'#10;
            
          end else
          begin
            
            wr += '    private ';
            wr += md.name;
            wr += ' := GetProcOrNil&<';
            WriteOvrT(wr, pars,nil, nil);
            wr += '>(z_';
            wr += l_name;
            wr += '_adr);'+#10;
            
          end;
          
        end else
        {$endregion Native}
        {$region Other}
        begin
          var need_conv := new boolean[pars.Length];
          
          var generic_names := new HashSet<string>;
          
          var arr_nil_pars := new boolean[pars.Length];
          var ptr_need_names := new HashSet<string>;
          
          foreach var par in pars index par_i do
          begin
            if is_proc and (par_i=0) then continue;
            
            need_conv[par_i] := par <> md.call_to.pars[par_i].par;
            
            if par.IsGeneric then
              generic_names += par.tname;
            
            arr_nil_pars[par_i] := need_conv[par_i] and (par.arr_lvl=1) and (par.tname<>'string');
            if arr_nil_pars[par_i] then
              ptr_need_names += par.GetTName;
            
          end;
          
          var need_init := md.pars.Where((m,i)->need_conv[i]).Any(m->m.init.Length<>0);
          var need_fnls := md.pars.Where((m,i)->need_conv[i]).Any(m->m.fnls.Length<>0);
          
          var need_block :=
            generic_names.Any or
            ptr_need_names.Any or
            need_init or need_fnls
          ;
          
          wr += '    ';
          wr += if md.is_public then 'public' else 'private';
          wr += ' [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
          WriteOvrT(wr, pars, generic_names, md.name);
          
          if need_block then
          begin
            wr += ';';
            if generic_names.Count<>0 then
            begin
              wr += ' where ';
              wr += generic_names.JoinToString(', ');
              wr += ': record;';
            end;
            wr += #10;
            foreach var t in ptr_need_names do
            begin
              wr += '    type P';
              wr += t;
              wr += '=^';
              wr += t;
              wr += ';'#10;
            end;
            wr += '    begin'#10;
          end else
            wr += ' :='#10;
          
          foreach var g in md.pars.Where((m,i)->need_conv[i]).SelectMany(m->m.vars).GroupBy(t->t[1], t->t[0]).OrderBy(g->g.Key) do
          begin
            wr += '  '*3;
            wr += 'var ';
            wr += g.JoinToString(', ');
            wr += ': ';
            wr += g.Key;
            wr += ';'#10;
          end;
          
          var need_try_finally := need_init and need_fnls;
          if need_try_finally then wr += '      try'#10;
          
          var tabs := 2 + Ord(need_block) + Ord(need_try_finally);
          
          if need_init then
          begin
            
            var padding := '  '*tabs;
            foreach var m in md.pars index par_i do
            begin
              if not need_conv[par_i] then continue;
              if m.init.Length=0 then continue;
              wr += padding;
              wr += m.init.Replace(#10, #10+padding).ToString;
              wr += #10;
            end;
            
          end;
          
          loop tabs do wr += '  ';
          if need_block and not is_proc then
          begin
            wr += if need_conv[0] then md.pars[0].par_str else 'Result';
            wr += ' := ';
          end;
          
          // md.pars[0] is nil if is_proc
          // md.pars[0].res_par_conv is nil by default
          var res_par_conv := md.pars[0]?.res_par_conv?.Split(|#0|,2);
          if res_par_conv<>nil then
            wr += res_par_conv[0];
          
          var need_call_tabs := false;
          var arr_nil_set := new MultiBooleanChoiseSet(arr_nil_pars);
          var if_used := new boolean[arr_nil_pars.Length];
          foreach var arr_nil in arr_nil_set.Enmr do
          begin
            var call_tabs := tabs;
            
            for var par_i := pars.Length-1 downto 1 do
            begin
              if not arr_nil_pars[par_i] then continue;
              
              var iu := not arr_nil.Flag[par_i];
              if not if_used[par_i] and iu then
              begin
                if not need_call_tabs then
                  need_call_tabs := true else
                  loop call_tabs do wr += '  ';
                wr += 'if (';
                wr += md.pars[par_i].par_str;
                wr += '<>nil) and (';
                wr += md.pars[par_i].par_str;
                wr += '.Length<>0) then'#10;
              end;
              if_used[par_i] := iu;
              
              call_tabs += 1;
            end;
            
            if not need_call_tabs then
              need_call_tabs := true else
              loop call_tabs do wr += '  ';
            wr += md.call_to.name;
            wr += '(';
            for var par_i := 1 to md.pars.Length-1 do
            begin
              var par := md.pars[par_i];
              if par_i<>1 then wr += ', ';
              if arr_nil.Flag[par_i] then
              begin
                wr += 'P';
                wr += par.par.GetTName;
                wr += '(nil)^';
              end else
              if need_conv[par_i] then
              begin
                wr += par.par_str;
                if arr_nil_pars[par_i] then
                  wr += '[0]';
              end else
                wr += org_par[par_i].name;
            end;
            wr += ')';
            
            if arr_nil.state=arr_nil_set.size-1 then
            begin
              if res_par_conv<>nil then
                wr += res_par_conv[1];
              wr += ';';
            end else
              wr += ' else';
            wr += #10;
            
          end;
          
          if need_try_finally then wr += '      finally'#10;
          if need_fnls then
          begin
            
            var padding := '  '*tabs;
            foreach var m in md.pars index par_i do
            begin
              if not need_conv[par_i] then continue;
              if m.fnls.Length=0 then continue;
              wr += padding;
              wr += m.fnls.Replace(#10, #10+padding).ToString;
              wr += #10;
            end;
            
          end;
          if need_try_finally then wr += '      end;'#10;
          
          if need_block then
            wr += '    end;'#10;
          
        end;
        {$endregion Other}
        
      end;
      
      {$endregion CodeGen}
      
      wr += '    '#10;
    end;
    
  end;
  FuncFixer = abstract class(Fixer<FuncFixer, Func>)
    
    static constructor;
    begin
      FuncFixer.GetFixableName := f->f.name;
      FuncFixer.MakeNewFixable := f->
      begin
        Result := new Func;
        f.Apply(Result);
      end;
    end;
    
    public static procedure LoadFile(fname: string);
    
    public static procedure LoadAll;
    
    protected function ApplyOrder: integer; abstract;
    protected function ApplyOrderBase: integer; override := ApplyOrder;
    
    protected procedure WarnUnused(all_unused_for_name: List<FuncFixer>); override :=
    Otp($'WARNING: {all_unused_for_name.Count} fixers of func [{self.name}] wasn''t used');
    
  end;
  
  {$endregion Func}
  
  {$region FuncContainers}
  
  Feature = sealed class
    public api     := default(string);
    public version := default(string);
    public add := new List<Func>;
    public rem := new List<Func>;
    
    public constructor(br: System.IO.BinaryReader);
    begin
      api := br.ReadString;
      version := ArrGen(br.ReadInt32, i->br.ReadInt32).JoinToString('.');
      add.Capacity := br.ReadInt32; loop add.Capacity do add += Func.All[br.ReadInt32];
      rem.Capacity := br.ReadInt32; loop rem.Capacity do rem += Func.All[br.ReadInt32];
    end;
    
    public static ByApi := new Dictionary<string, List<Feature>>;
    public static function GetListByApi(api: string): List<Feature>;
    begin
      if ByApi.TryGetValue(api, Result) then exit;
      Result := new List<Feature>;
      ByApi[api] := Result;
    end;
    public static procedure LoadAll(br: System.IO.BinaryReader);
    begin
      loop br.ReadInt32 do
      begin
        var f := new Feature(br);
        GetListByApi(f.api).Add(f);
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
    
    private procedure MarkReferenced;
    begin
      foreach var fnc in add do fnc.MarkReferenced;
      foreach var fnc in rem do fnc.MarkReferenced;
    end;
    public static procedure MarkAllReferenced :=
    foreach var lst in Feature.ByApi.Values do
      foreach var f in lst do
        f.MarkReferenced;
    
    private static valid_api := HSet(
      $'v','vDyn',
      'gl','wgl','glx','gdi',
      'cl'
    );
    private static function IsValidAPI(api: string): boolean;
    begin
      Result := api in valid_api;
      if not Result and LogCache.invalid_api.Add(api) then
        log.Otp($'Invalid API: [{api}]');
    end;
    
    private static function IsAPIDynamic(api: string): boolean;
    begin
      case api of
        
        'v':    Result := false;
        'vDyn': Result := true;
        
        'gl':   Result := true;
        'wgl':  Result := false;
        'glx':  Result := false;
        'gdi':  Result := false;
        
        'cl':   Result := false;
        
        else raise new System.NotSupportedException(api);
      end;
    end;
    
    public static procedure WriteAll(wr, impl_wr: Writer) :=
    foreach var api in Feature.ByApi.Keys do
    begin
      if not IsValidAPI(api) then continue;
      
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
            log.Otp($'Func [{f.name}] was added in versions [{all_funcs[f]}] and [{ftr.version}]') else
            all_funcs[f] := ftr.version;
        
        foreach var f in ftr.rem do
          if deprecated.ContainsKey(f) then
            Otp($'WARNING: Func [{f.name}] was deprecated in versions [{deprecated[f]}] and [{ftr.version}]') else
            deprecated.Add(f, ftr.version);
        
        if ftr.version<>nil then
          log_func_ver.Otp($'# {ftr.version}');
        var tab := if ftr.version<>nil then #9'' else nil;
        foreach var f in all_funcs.Keys do
          if not deprecated.ContainsKey(f) then
            log_func_ver.Otp(tab + f.name);
        log_func_ver.Otp('');
        
      end;
      
      loop 1 do log_func_ver.Otp('');
      log_func_ver.Close;
      
      var is_dynamic := IsAPIDynamic(api);
      var class_type := is_dynamic ? 'sealed partial' : 'static';
      
      var WriteAPI := procedure(api_funcs: sequence of Func; add_ver, depr_ver: Func->string)->
      begin
        wr += '  [PCUNotRestore]'#10;
        wr += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
        wr += '  ';
        wr += api;
        if depr_ver<>nil then wr += 'D';
        wr += ' = ';
        wr += class_type;
        wr += ' class'#10;
        if is_dynamic then
        begin
          
          wr += '    public constructor(loader: PlatformLoader);'#10;
          wr += '    private constructor := raise new System.NotSupportedException;'#10;
          wr += '    private function GetProcAddress(name: string): IntPtr;'#10;
          
          impl_wr += 'type ';
          impl_wr += api;
          if depr_ver<>nil then impl_wr += 'D';
          impl_wr += ' = ';
          impl_wr += class_type;
          impl_wr += ' class(api_with_loader) end;'#10;
          impl_wr += 'constructor ';
          impl_wr += api;
          if depr_ver<>nil then impl_wr += 'D';
          impl_wr += '.Create(loader: PlatformLoader) := inherited Create(loader);'#10;
          impl_wr += 'function ';
          impl_wr += api;
          if depr_ver<>nil then impl_wr += 'D';
          impl_wr += '.GetProcAddress(name: string) := loader.GetProcAddress(name);'#10;
          impl_wr += #10;
          
          wr += '    private static function GetProcOrNil<T>(fadr: IntPtr) :='#10;
          wr += '    fadr=IntPtr.Zero ? default(T) :'#10;
          wr += '    Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
        end;
        
        wr += '    '#10;
        
        foreach var f in api_funcs.OrderBy(f->f.name) do
          begin
            if (api<>'gdi') and (add_ver(f) is string(var curr_add_ver)) then
            begin
              wr += '    // added in ';
              wr += api;
              wr += curr_add_ver;
              if depr_ver<>nil then
              begin
                wr += ', deprecated in ';
                wr += api;
                wr += depr_ver(f);
              end;
              wr += #10;
            end;
            f.MarkWriteable;
            f.Write(wr, api,all_funcs[f], not is_dynamic);
          end;
        
        Func.prev_func_names.Clear;
        wr += $'  end;'+#10;
        wr += $'  '+#10;
      end;
      
      WriteAPI(all_funcs.Keys.Where(f->not deprecated.ContainsKey(f)), f->all_funcs[f], nil);
      if not deprecated.Any then continue;
      WriteAPI(all_funcs.Keys.Where(f->    deprecated.ContainsKey(f)), f->all_funcs[f], f->deprecated[f]);
      
    end;
    
  end;
  Extension = sealed class
    public name, api: string;
    public add: List<Func>;
    
    public constructor(br: System.IO.BinaryReader);
    begin
      name := br.ReadString;
      api := br.ReadString;
      add := ArrGen(br.ReadInt32, i->Func.All[br.ReadInt32]).ToList;
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
    
    private procedure MarkReferenced;
    begin
      foreach var fnc in add do fnc.MarkReferenced;
    end;
    public static procedure MarkAllReferenced :=
    foreach var ext in All do
      ext.MarkReferenced;
    
    private static function IsAPIDynamic(api: string): boolean;
    begin
      case api of
        
        'v':    Result := false;
        'vDyn': Result := true;
        
        'gl':   Result := true;
        'wgl':  Result := true;
        'glx':  Result := true;
        'gdi':  Result := false;
        
        'cl':   Result := false;
        
        else raise new System.NotSupportedException(api);
      end;
    end;
    
    public procedure Write(wr, impl_wr: Writer; log_func_ext: FileLogger);
    begin
      if add.Count=0 then exit;
      if not Feature.IsValidAPI(self.api) then exit;
      
      var is_dynamic := Extension.IsAPIDynamic(api);
      var need_loader := Feature.IsAPIDynamic(api);
      var class_type := is_dynamic ? 'sealed partial' : 'static';
      
      {$region name}
      
      var display_name := name;
      if not display_name.ToLower.StartsWith(api+'_') then
        raise new System.NotSupportedException($'Extension name [{name}] must start from api [{api}]');
      display_name := display_name.Substring(api.Length+1);
      
      var ind := display_name.IndexOf('_');
      var ext_group := display_name.Remove(ind).ToUpper;
      if ext_group in allowed_ext_names then
        display_name := display_name.Substring(ind+1) else
      begin
        if LogCache.invalid_ext_names.Add(ext_group) then
          log.Otp($'Ext group [{ext_group}] of ext [{name}] is not supported');
        ext_group := '';
      end;
      
      display_name := api+display_name.Split('_').Select(w->
      begin
        if w.Length<>0 then w[0] := w[0].ToUpper else
          raise new System.InvalidOperationException(display_name);
        Result := w;
      end).JoinToString('') + ext_group;
      
      {$endregion name}
      
      log_func_ext.Otp($'# {display_name} ({name})');
      
      wr += '  [PCUNotRestore]'#10;
      wr += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
      
      wr += '  ';
      wr += display_name;
      wr += ' = ';
      wr += class_type;
      wr += ' class'#10;
      
      if is_dynamic then
      begin
        if need_loader then
        begin
          wr += '    public constructor(loader: PlatformLoader);'#10;
          wr += '    private constructor := raise new System.NotSupportedException;'#10;
          
          impl_wr += 'type ';
          impl_wr += display_name;
          impl_wr += ' = ';
          impl_wr += class_type;
          impl_wr += ' class(api_with_loader) end;'#10;
          impl_wr += 'constructor ';
          impl_wr += display_name;
          impl_wr += '.Create(loader: PlatformLoader) := inherited Create(loader);'#10;
          impl_wr += 'function ';
          impl_wr += display_name;
          impl_wr += '.GetProcAddress(name: string) := loader.GetProcAddress(name);'#10;
          impl_wr += #10;
          
        end;
        
        wr += '    private function GetProcAddress(name: string)';
        if need_loader then
          wr += ': IntPtr' else
        begin
          wr += ' := ';
          wr += api;
          wr += '.GetProcAddress(name)';
        end;
        wr += ';'#10;
        
        wr += '    private static function GetProcOrNil<T>(fadr: IntPtr) :='#10;
        wr += '    fadr=IntPtr.Zero ? default(T) :'#10;
        wr += '    Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
      end;
      
      wr += '    public const _ExtStr = ''';
      wr += name.ToLower;
      wr += ''';'+#10;
      wr += '    '+#10;
      
      foreach var f in add do
      begin
        f.MarkWriteable;
        f.Write(wr, api,nil, not is_dynamic);
        log_func_ext.Otp($'{#9}{f.name}');
      end;
      Func.prev_func_names.Clear;
      wr += $'  end;'+#10;
      wr += $'  '+#10;
      
      log_func_ext.Otp($'');
    end;
    public static procedure WriteAll(wr, impl_wr: Writer);
    begin
      if All.Count=0 then exit;
      
      var log_func_ext := new FileLogger(GetFullPathRTA($'Log\FuncsExt.log'));
      loop 3 do log_func_ext.Otp('');
      
      wr += '  {$region Extensions}'#10;
      wr += '  '#10;
      foreach var ext in All do ext.Write(wr, impl_wr, log_func_ext);
      wr += '  {$endregion Extensions}'#10;
      wr += '  '#10;
      
      loop 3 do log_func_ext.Otp('');
      log_func_ext.Close;
    end;
    
  end;
  
  {$endregion FuncContainers}
  
procedure LoadMiscInput;
procedure LoadFixers;
procedure LoadBin(fname: string);
procedure ApplyFixers;
procedure MarkReferenced;
procedure FinishAll;

implementation

{$region Misc}

procedure LoadMiscInput;
begin
  
  foreach var ext in 
    ReadLines(GetFullPathRTA('MiscInput\AllowedExtNames.dat'))
    .Where(l->not string.IsNullOrWhiteSpace(l))
    .Select(l->l.Trim)
    .OrderByDescending(l->l.Length)
  do allowed_ext_names += ext;
  
  foreach var l in ReadLines(GetFullPathRTA('MiscInput\TypeTable.dat')) do
  begin
    var s := l.Split('=');
    if s.Length<2 then continue;
    TypeTable.All.Add(s[0].Trim,s[1].Trim);
  end;
  
end;

procedure LoadFixers;
begin
  
  StructFixer.LoadAll;
  GroupFixer.LoadAll;
  FuncFixer.LoadAll;
  
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
  if br.BaseStream.Position<>br.BaseStream.Length then
    raise new System.FormatException($'{br.BaseStream.Position} <> {br.BaseStream.Length}');
end;

procedure ApplyFixers;
begin
  StructFixer.ApplyAll(Struct.All);
  GroupFixer.ApplyAll(Group.All);
  FuncFixer.ApplyAll(Func.All);
end;

procedure MarkReferenced;
begin
  Feature.MarkAllReferenced;
  Extension.MarkAllReferenced;
end;

procedure FinishAll;
begin
  
  TypeTable.WarnAllUnused;
  StructFixer.WarnAllUnused;
  GroupFixer.WarnAllUnused;
  FuncFixer.WarnAllUnused;
  
  Struct.WarnAllUnreferenced;
  Group.WarnAllUnreferenced;
  Func.WarnAllUnreferenced;
  
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
    .OrderByDescending(ext->ext.Length)
    .First(prev_res.EndsWith)
  ;
  if LogCache.invalid_ext_names.Add(prev_res) and (prev_res.Length>1) then
    log.Otp($'Invalid ext name [{prev_res}] of [{s}], replaced with [{Result}]');
  
end;

function GetDllNameForAPI(api: string): string;
begin
  case api of
    'v':    Result := 'virtual.dll';
    
    'wgl':  Result := 'opengl32.dll';
    'glx':  Result := 'libGL.so.1';
    'gdi':  Result := 'gdi32.dll';
    
    'cl':   Result := 'opencl';
    
    else raise new System.NotSupportedException(api);
  end;
end;

{$endregion Misc}

{$region GroupFixer}

type
  GroupAdder = sealed class(GroupFixer)
    private name, t: string;
    private bitmask: boolean;
    private enums := new List<(string, int64)>;
    
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
        enums.Add((key, val.StartsWith('0x') ?
          System.Convert.ToInt64(val, 16) :
          System.Convert.ToInt64(val)
        ));
      end;
      
      self.RegisterAsAdder;
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      gr.name     := self.name;
      gr.bitmask  := self.bitmask;
      gr.enums    := new Dictionary<string, int64>(self.enums.Count);
      foreach var (key, val) in self.enums do
        gr.AddKeyVal(key, val);
      gr.types    := new List<string>(|self.t|);
      gr.types_use_replacements := new Dictionary<string, string>;
      gr.explicit_existence := true;
      Group.name_cache := nil;
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
  
  GroupBaseFixer = sealed class(GroupFixer)
    public new_base: string;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      self.new_base := data.Single(l->not string.IsNullOrWhiteSpace(l));
    end;
    
    public function Apply(gr: Group): boolean; override;
    begin
      if gr.types.SingleOrDefault=new_base then
        log.Otp($'Group [{gr.name}] fixer did not change base type, it was already [{gr.types.Single}]');
      gr.types := new List<string>(|new_base|);
      self.used := true;
      Result := false;
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
      gr.Rename(new_name);
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
      foreach var (key, val) in enums do
        gr.AddKeyVal(key, val);
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
  
static procedure GroupFixer.LoadAll;
begin
  
  var fls := EnumerateAllFiles(GetFullPathRTA('Fixers\Enums'), '*.dat');
  foreach var gr in fls.SelectMany(fname->FixerUtils.ReadBlocks(fname,true)) do
    foreach var bl in FixerUtils.ReadBlocks(gr[1],'!',false) do
    case bl[0] of
      
      'add':        GroupAdder            .Create(gr[0], bl[1]);
      'remove':     GroupRemover          .Create(gr[0], bl[1]);
      
      'base':       GroupBaseFixer        .Create(gr[0], bl[1]);
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
  
static procedure StructFixer.LoadAll;
begin
  
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
  FuncAdder = sealed class(FuncFixer)
    private pars := new List<FuncOrgParam>;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(nil);
      self.name := name;
      
      foreach var l in data do
      begin
        if string.IsNullOrWhiteSpace(l) then continue;
        
        var par := new FuncOrgParam;
        
        var text := l.Trim;
        if pars.Count=0 then
          par.name := name else
        begin
          var ind := text.LastIndexOfAny(|' ',#9|);
          if ind=-1 then raise new System.FormatException($'[{name}]: [{text}]');
          par.name := text.SubString(ind+1);
          text := text.Remove(ind).TrimEnd;
        end;
        
        par.ptr := text.CountOf('*');
        
        foreach var s in text.Split('*').Reverse index i do
          if 'const' in s then
            par.readonly_lvls += i;
        par.t := text.Remove('*','const').Trim;
        
        if (pars.Count=0) and (par.t='void') and (par.ptr=0) then par.t := nil;
        
        pars += par;
      end;
      
      loop virtual_apis.Length do self.RegisterAsAdder;
    end;
    
    private static virtual_apis := |'v', 'vDyn'|;
    //TODO #????: AsEnumerable
    private api_enmr := virtual_apis.AsEnumerable.GetEnumerator;
    static constructor :=
    foreach var api in virtual_apis do
    begin
      var f := new Feature;
      f.api := api;
      Feature.GetListByApi(api).Add(f);
    end;
    
    protected function ApplyOrder: integer; override := 0;
    public function Apply(f: Func): boolean; override;
    begin
      if not api_enmr.MoveNext then raise new System.InvalidOperationException;
      var api := api_enmr.Current;
      
      f.org_par := pars.ToArray;
      
      f.org_par[0] := new FuncOrgParam;
      f.org_par[0].name           := api+self.name;
      f.org_par[0].t              := pars[0].t;
      f.org_par[0].ptr            := pars[0].ptr;
      f.org_par[0].readonly_lvls  := pars[0].readonly_lvls;
      f.BasicInit;
      
      Func.fixed_names += f.name;
      f.explicit_existence := true;
      
      Feature.GetListByApi(api).Single.add += f;
      
      Result := false;
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
    
    private function FixerInfo(f: Func) := $'{_ObjectToString(new_tnames.Select(par->par.ToString(true,true)))} replacement types for {old_tname.ToString(true,true)} in [{TypeName(self)}] of func [{f.name}]';
    
    protected function ApplyOrder: integer; override := 1;
    public function Apply(f: Func): boolean; override;
    begin
      f.InitPossibleParTypes;
      
      var tn_id := 0;
      foreach var par in f.possible_par_types index par_i do
      begin
        if f.is_proc and (par_i=0) then continue;
        for var i := 0 to par.Count-1 do
          if par[i]=old_tname then
          begin
            if tn_id=new_tnames.Length then
            begin
              Otp($'ERROR: Not enough {FixerInfo(f)}');
              exit;
            end;
            par[i] := new_tnames[tn_id];
            tn_id += 1;
          end;
      end;
      if tn_id<>new_tnames.Length then
      begin
        Otp($'ERROR: Only {tn_id}/{new_tnames.Length} {FixerInfo(f)} were used');
        exit;
      end;
      
      self.used := true;
      Result := false;
    end;
    
  end;
  
  FuncPPTFixer = sealed class(FuncFixer)
    public changes: array of record
      add := new List<FuncParamT>;
      rem := new List<FuncParamT>;
    end;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      foreach var l in data do
      begin
        if string.IsNullOrWhiteSpace(l) then continue;
        var s := l.Split('|');
        var par_c := s.Length-1;
        if not string.IsNullOrWhiteSpace(s[par_c]) then raise new System.FormatException(s.JoinToString('|'));
        
        if changes=nil then
          SetLength(changes, par_c) else
        if changes.Length<>par_c then
          raise new MessageException($'ERROR: [{name}]: {changes.Length} <> {par_c}');
        
        var res := new StringBuilder;
        for var i := 0 to par_c-1 do
        begin
          
          var curr_lst: List<FuncParamT> := nil;
          //TODO #????: inherited ctor + foreach
          var _name := name;
          var _self := self;
          var _s := s;
          var seal_t := procedure->
          begin
            var t := res.ToString.Trim;
            res.Clear;
            if t='' then exit;
            if t='*' then exit;
            if curr_lst=nil then
              raise new MessageException($'Syntax ERROR of [{TypeName(_self)}] for func [{_name}] in [{_s[i]}]') else
              curr_lst += new FuncParamT(t);
          end;
          
          res.EnsureCapacity(s.Length);
          foreach var ch in s[i] do
            if ch in '-+' then
            begin
              seal_t();
              curr_lst := ch='+' ? changes[i].add : changes[i].rem;
            end else
              res += ch;
          
          seal_t();
        end;
        
      end;
    end;
    
    private function FixerInfo(f: Func) := $'[{TypeName(self)}] of func [{f.name}]';
    
    private function ErrorInfo(f: Func; act: string; i: integer; t: FuncParamT; ppt: List<FuncParamT>): string :=
    $'ERROR: {FixerInfo(f)} failed to {act} type [{t.ToString(true,true)}] of param#{i} [{f.org_par[i]?.name}]: {_ObjectToString(ppt.Select(par->par.ToString(true,true)))}';
    
    protected function ApplyOrder: integer; override := 2;
    public function Apply(f: Func): boolean; override;
    begin
      f.InitPossibleParTypes;
      
      var ind_nudge := integer(f.is_proc);
      if changes.Length<>f.org_par.Length-ind_nudge then
        raise new MessageException($'ERROR: {FixerInfo(f)} had wrong param count');
      
      for var i := 0 to changes.Length-1 do
      begin
        foreach var t in changes[i].rem do
          if f.possible_par_types[i+ind_nudge].Remove(t) then
            self.used := true else
            Otp(ErrorInfo(f, 'remove', i, t, f.possible_par_types[i+ind_nudge]));
        foreach var t in changes[i].add do
          if f.possible_par_types[i+ind_nudge].Contains(t) then
            Otp(ErrorInfo(f, 'add',    i, t, f.possible_par_types[i+ind_nudge])) else
          begin
            self.used := true;
            var ppt := f.possible_par_types[i+ind_nudge];
            ppt += t;
            if t.var_arg and ((t.tname='IntPtr') or t.IsGeneric) then
              if ppt.Remove(new FuncParamT('IntPtr')) then
                ppt.Add(new FuncParamT('pointer'));
          end;
      end;
      
      Result := false;
    end;
    
  end;
  
  FuncLimitOvrsFixer = sealed class(FuncFixer)
    public ovrs := new List<FuncOverload>;
    
    public constructor(name: string; data: sequence of string);
    begin
      inherited Create(name);
      
      foreach var l in data do
      begin
        var s := l.Split('|');
        if s.Length=1 then continue; // коммент
        
        if not string.IsNullOrWhiteSpace(s[s.Length-1]) then raise new System.FormatException(l);
        s := s[:^1];
        
        var ovr := s.ConvertAll(ps->
        begin
          ps := ps.Trim;
          Result := nil;
          if ps='' then exit;
          if ps='*' then exit;
          Result := new FuncParamT(ps)
        end);
        ovrs += FuncOverload(ovr);
      end;
      
      if self.ovrs.Select(o->o.pars.Count(p->p<>nil)).Distinct.Count<=1 then exit;
      raise new System.NotSupportedException; // Nothing to test on
//      self.ovrs.Sort((o1,o2)->o1.pars.Count(p->p<>nil).CompareTo(o2.pars.Count(p->p<>nil)));
//      foreach var o in ovrs do
//        Println(o.pars.Count(p->p<>nil), o.pars);
//      Writeln('-'*50);
    end;
    
    private function FixerInfo(f: Func) := $'[{TypeName(self)}] of func [{f.name}]';
    
    protected function ApplyOrder: integer; override := 3;
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      var org_ovrs := f.all_overloads.ToArray;
      
      var expected_ovr_l := f.org_par.Length - integer(f.is_proc);
      foreach var ovr in self.ovrs index ovr_i do
        if ovr.pars.Length<>expected_ovr_l then
          raise new MessageException($'ERROR: ovr#{ovr_i} in {FixerInfo(f)} had wrong param count: {f.org_par.Length} org vs {ovr.pars.Length+integer(f.is_proc)} custom');
      
      var unused_t_ovrs := self.ovrs.ToHashSet;
      var limited_pars := new boolean[expected_ovr_l];
      
      f.all_overloads.RemoveAll(fovr->
        not self.ovrs.Any(tovr->
        begin
          Result := true;
          for var i := 0 to tovr.pars.Length-1 do
          begin
            if tovr.pars[i]=fovr.pars[i+integer(f.is_proc)] then continue;
            limited_pars[i] := true;
            if tovr.pars[i]=nil then continue;
            Result := false;
          end;
          if Result then unused_t_ovrs.Remove(tovr);
        end)
      );
      
      if unused_t_ovrs.Count<>0 then
      begin
        foreach var ovr in unused_t_ovrs do
          Otp($'WARNING: {FixerInfo(f)} has not used mask {_ObjectToString(ovr.pars.Select(par->par?.ToString(true,true)))}');
        Otp('-'*10+$' Func ovrs were '+'-'*10);
        foreach var ovr in org_ovrs do
          Otp(_ObjectToString(ovr.pars.Select(par->par?.ToString(true,true))));
      end;
      
      var unlimited_pars := expected_ovr_l.Times
        .Where(par_i->not limited_pars[par_i])
        .Select(par_i->par_i+integer(f.is_proc))
        .Select(par_i->$'par#{par_i}:{f.org_par[par_i].name}');
      if unlimited_pars.Any then
        Otp($'WARNING: {FixerInfo(f)} has not limited pars: {_ObjectToString(unlimited_pars)}');
      
      self.used := true;
      Result := false;
    end;
    
  end;
  
static procedure FuncFixer.LoadFile(fname: string) :=
foreach var (gr_name, gr_body) in FixerUtils.ReadBlocks(fname,true) do
begin
  Func.fixed_names += gr_name;
  foreach var (bl_name, bl_body) in FixerUtils.ReadBlocks(gr_body,'!',false) do
    case bl_name of
      
      'add':                FuncAdder         .Create(gr_name, bl_body);
      
      'repl_par_t':         FuncReplParTFixer .Create(gr_name, bl_body);
      
      'possible_par_types': FuncPPTFixer      .Create(gr_name, bl_body);
      
      'limit_ovrs':         FuncLimitOvrsFixer.Create(gr_name, bl_body);
      
      else raise new MessageException($'Invalid func fixer type [!{bl_name}] for func [{gr_name}]');
    end;
end;

static procedure FuncFixer.LoadAll :=
foreach var fname in EnumerateAllFiles(GetFullPathRTA('Fixers\Funcs'), '*.dat') do
  FuncFixer.LoadFile(fname);

{$endregion FuncFixer}

begin
  try
    
    loop 3 do log_groups.Otp('');
    loop 3 do log_structs.Otp('');
    loop 3 do log_func_ovrs.Otp('');
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.