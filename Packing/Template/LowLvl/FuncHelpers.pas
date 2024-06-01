unit FuncHelpers;

{$zerobasedstrings}

uses System;

uses '../../../Utils/AOtp';
uses '../../../Utils/CodeGen';

uses BinUtils;
uses ChoiceSets;
uses HashableArrays;

uses TypeRefering;

type
  
  {$region FuncParamT}
  
  FuncParamTypeOrder = TypeRefering.FuncParamTypeOrder;
  FuncParamT = sealed class(System.IEquatable<FuncParamT>)
    public is_const: boolean;
    public var_arg: boolean;
    public arr_lvl: integer;
    public tname: string;
    
    public default_val := default(string);
    
    private raw_t: IDirectNamedType;
    
    // nil: Any number of items
    // 1: Send/Recieve 1 item (no repeat)
    // 5: Send/Recieve 5 items
    public enum_to_type_data_rep_c := new Nullable<integer>(1);
    
    public constructor(is_const, var_arg: boolean; arr_lvl: integer; tname: string; raw_t: IDirectNamedType);
    begin
      self.is_const  := is_const;
      self.var_arg  := var_arg;
      self.arr_lvl  := arr_lvl;
      self.tname    := tname;
      self.raw_t    := raw_t;
      if (tname.ToLower='boolean') and (var_arg or (arr_lvl<>0)) then
        raise new NotSupportedException('Use api::Bool8');
    end;
    public constructor(is_const, var_arg: boolean; arr_lvl: integer; raw_t: IDirectNamedType) :=
      Create(is_const, var_arg, arr_lvl, raw_t.MakeWriteableName, raw_t);
    private constructor := raise new InvalidOperationException;
    
    public function WithPtr(var_arg: boolean; arr_lvl: integer): FuncParamT;
    begin
      Result := new FuncParamT(is_const, var_arg, arr_lvl, tname, raw_t);
      Result.enum_to_type_data_rep_c := enum_to_type_data_rep_c;
    end;
    
    public static function Parse(str: string): FuncParamT;
      const const_s = 'const';
      const var_arg_s = 'var ';
      const array_arg_s = 'array of ';
    begin
      str := str.Trim;
      
      var is_const := str.EndsWith(const_s);
      if is_const then
      begin
        str := str.Remove(str.Length-const_s.Length);
        if not char.IsWhiteSpace(str.Last) then
          raise new FormatException;
        str := str.TrimEnd;
      end;
      
      var var_arg := str.StartsWith(var_arg_s);
      if var_arg then str := str.Substring(var_arg_s.Length).Trim;
      
      var arr_lvl := 0;
      while str.StartsWith(array_arg_s) do
      begin
        arr_lvl += 1;
        str := str.Substring(array_arg_s.Length).Trim;
      end;
      
      Result := new FuncParamT(is_const, var_arg, arr_lvl, TypeLookup.FromNameString(str));
    end;
    
    public property TypeOrder: FuncParamTypeOrder read raw_t.GetTypeOrder;
    public procedure Use(need_write: boolean) := raw_t.Use(need_write);
    
    public property IsString: boolean read raw_t = KnownDirectTypes.String;
    
    // TInp is also generic
    public property IsGeneric: boolean read tname.StartsWith('T'){ and tname.Skip(1).All(char.IsDigit)};
    
    public function ToString(generate_code: boolean; write_var: boolean := true; raw_t_name: boolean := false; write_const: boolean := true): string;
    begin
      if not generate_code then
      begin
        Result := $'({var_arg}, {arr_lvl}, {tname}, {ObjectToString(enum_to_type_data_rep_c)})';
        exit;
      end;
      var res := new StringBuilder;
      
      if write_var and var_arg then
        res += 'var ';
      
      var rep_c_str := if enum_to_type_data_rep_c=1 then nil else
        enum_to_type_data_rep_c?.ToString;
      
      if arr_lvl<>0 then
      begin
        res += 'array';
        if rep_c_str<>nil then
        begin
          res += '[';
          res += rep_c_str;
          res += ']';
          rep_c_str := nil;
        end;
        res += ' of ';
        loop arr_lvl-1 do res += 'array of ';
      end;
      
      if raw_t_name then
        res += self.raw_t.GetRawName.ToString else
        res += self.tname;
      
      if rep_c_str<>nil then
      begin
        if not self.var_arg and not self.IsString then 
          raise new InvalidOperationException;
        res += '[';
        res += rep_c_str;
        res += ']';
        rep_c_str := nil;
      end;
      
      if write_const and self.is_const then
        res += ' const';
      
      Result := res.ToString;
    end;
    public function ToString: string; override := ToString(false);
    
    public static function operator=(par1,par2: FuncParamT): boolean;
    begin
      var par1_nil := Object.ReferenceEquals(par1,nil);
      var par2_nil := Object.ReferenceEquals(par2,nil);
      Result :=
        if par1_nil then par2_nil else
        not par2_nil and
        (par1.is_const = par2.is_const) and
        (par1.var_arg = par2.var_arg) and
        (par1.arr_lvl = par2.arr_lvl) and
        (par1.tname   = par2.tname);
    end;
    public static function operator<>(par1,par2: FuncParamT) := not(par1=par2);
    
    public function Equals(other: FuncParamT) := self=other;
    public function Equals(o: object): boolean; override :=
      (o is FuncParamT(var other)) and (self=other);
    
    public function GetHashCode: integer; override;
    begin
      Result := tname.GetHashCode
        xor (Ord(is_const) shl 0)
        xor (Ord(var_arg) shl 1)
        xor (arr_lvl.GetHashCode shl 2);
      if enum_to_type_data_rep_c<>nil then
        Result := Result xor enum_to_type_data_rep_c.Value;
    end;
    
  end;
  
  {$endregion FuncParamT}
  
  {$region FuncOverload}
  
  FuncOverload = sealed class(HashableReadonlyArray<FuncOverload,FuncParamT>)
    
    public enum_to_type_bindings: array of EnumToTypeBindingInfo := nil;
    public enum_to_type_gr := default(IDirectNamedType);
    public enum_to_type_enum_name := default(string);
    
    public constructor(pars: array of FuncParamT) := inherited Create(pars);
    public constructor(pars: array of FuncParamT; enum_to_type_bindings: array of EnumToTypeBindingInfo; enum_to_type_gr: IDirectNamedType; enum_to_type_enum_name: string);
    begin
      inherited Create(pars);
      self.enum_to_type_bindings := enum_to_type_bindings;
      self.enum_to_type_gr := enum_to_type_gr;
      self.enum_to_type_enum_name := enum_to_type_enum_name;
    end;
    private constructor := raise new InvalidOperationException;
    
    public static function operator implicit(pars: array of FuncParamT): FuncOverload := new FuncOverload(pars);
    
    public function ToString: string; override :=
      ItemsSeq.Select(par->par?.ToString(true)??'-').JoinToString('; ');
    
  end;
  
  {$endregion FuncOverload}
  
  {$region MarshalStepKindCombo}
  
  MarshalStepKind = (MSK_Invalid
    , MSK_EnumToTypeGroup, MSK_EnumToTypeGetSize, MSK_EnumToTypeBody
    , MSK_StringResult, MSK_StringParam
    , MSK_ArrayFallThrought, MSK_ArrayCopy
    , MSK_ArrayFirstItem
    , MSK_GenericSubstitute
    , MSK_FlatForward
  );
  
  MarshalStepKindCombo = sealed class(HashableReadonlyArray<MarshalStepKindCombo, MarshalStepKind>)
    
    public static function operator implicit(par_group_kinds: array of MarshalStepKind): MarshalStepKindCombo :=
      new MarshalStepKindCombo(par_group_kinds);
    
    private static flat_forward: MarshalStepKindCombo := |MSK_FlatForward|;
    public static property FlatForward: MarshalStepKindCombo read flat_forward;
    public function IsSingleFlatForward: boolean;
    begin
      Result := ReferenceEquals(self, FlatForward);
      {$ifdef DEBUG}
      if not Result and ItemsSeq.All(k->k=MSK_FlatForward) then
        raise new InvalidOperationException($'Use MarshalStepKindCombo.FlatForward');
      {$endif DEBUG}
    end;
    
    protected function HashCodeBitShift: integer; override := 4;
    
    public function ToString: string; override :=
      ItemsSeq.JoinToString;
    
  end;
  
  {$endregion MarshalStepKindCombo}
  
  {$region MarshalCallKind}
  
  MarshalCallKind = sealed class(HashableReadonlyArray<MarshalCallKind, MarshalStepKind>)
    public original_step_kinds: array of MarshalStepKindCombo := nil;
    
    private static function CombineKindCombos(step_kinds: array of MarshalStepKindCombo): array of MarshalStepKind;
    begin
      Result := new MarshalStepKind[step_kinds.Sum(step_kind->step_kind.Size)];
      var i := 0;
      foreach var step_kind in step_kinds do
        foreach var k in step_kind.ItemsSeq do
        begin
          Result[i] := k;
          i += 1;
        end;
      {$ifdef DEBUG}
      if i <> Result.Length then
        raise new InvalidOperationException;
      {$endif DEBUG}
    end;
    
    public constructor(par_kinds: array of MarshalStepKind) := inherited Create(par_kinds);
    public constructor(step_kinds: array of MarshalStepKindCombo);
    begin
      inherited Create(CombineKindCombos(step_kinds));
      original_step_kinds := step_kinds;
    end;
    
    public static function operator implicit(par_kinds: array of MarshalStepKind): MarshalCallKind :=
      new MarshalCallKind(par_kinds);
    
    public function IsAllFlatForward :=
      original_step_kinds.All(step_kind->step_kind.IsSingleFlatForward);
    public function CanFlatForwardFlags :=
      original_step_kinds.ConvertAll(step_kind->not step_kind.IsSingleFlatForward);
    
    protected function HashCodeBitShift: integer; override := 16-1;
    
    public function ToString: string; override :=
      ItemsSeq.JoinToString;
    
  end;
  
  {$endregion MarshalCallKind}
  
  {$region FuncParamMarshalStep}
  
  MarshalParamKind = (MPK_Invalid
    , MPK_Basic
    , MPK_Generic
    , MPK_Array
    , MPK_String
    , MPK_ArrayNeedCopy
    , MPK_EnumToTypeGroupHole, MPK_EnumToTypeCount, MPK_EnumToTypeBody
  );
  
  FuncParamMarshalStep = sealed class
    // Usually only 1 par, but EnumToType also has in/out sizes
    private pars: array of ValueTuple<MarshalParamKind, FuncParamT>;
    // 0 items for final (ntv_) steps
    private next_steps := new Dictionary<MarshalStepKindCombo, array of FuncParamMarshalStep>;
    
    private constructor(pars: array of ValueTuple<MarshalParamKind, FuncParamT>);
    begin
      self.pars := pars;
    end;
    private constructor := raise new InvalidOperationException;
    
    private static next_step_generators_pending := default(Stack<Action>);
    private procedure UnwrapNextStepGenerators(set_next_steps: Action);
    begin
      if next_step_generators_pending<>nil then
      begin
        next_step_generators_pending += set_next_steps;
        exit;
      end;
      next_step_generators_pending := new Stack<Action>;
      next_step_generators_pending += set_next_steps;
      
      while next_step_generators_pending.Any do
        next_step_generators_pending.Pop()();
      
      next_step_generators_pending := nil;
    end;
    
    private next_step_size := default(integer?);
    private procedure AddNext(kinds: MarshalStepKindCombo; steps: array of FuncParamMarshalStep);
    begin
      {$ifdef DEBUG}
      if steps.Length=0 then
        raise new InvalidOperationException;
      if kinds.Size <> steps.Length then
        raise new InvalidOperationException;
      if next_step_size=nil then
        next_step_size := steps.Length else
      if next_step_size <> steps.Length then
        raise new InvalidOperationException;
      {$endif DEBUG}
      next_steps.Add(kinds, steps);
    end;
    private procedure AddNext(kind: MarshalStepKind; step: FuncParamMarshalStep) := AddNext(|kind|, |step|);
    
    private static nil_par := ValueTuple.Create(MPK_Invalid, nil as FuncParamT);
    private static zero_par_arr := System.Array.Empty&<ValueTuple<MarshalParamKind, FuncParamT>>;
    
    private static proc_result := new FuncParamMarshalStep(|nil_par|);
    public static function ProcResult := FuncParamMarshalStep.proc_result;
    
    private static from_ett_group := new Dictionary<FuncParamT, FuncParamMarshalStep>;
    public static function FromEnumToTypeGroup(gr_par: FuncParamT): FuncParamMarshalStep;
    begin
      if from_ett_group.TryGetValue(gr_par, Result) then exit;
      Result := new FuncParamMarshalStep(|ValueTuple.Create(MPK_EnumToTypeGroupHole, nil as FuncParamT)|);
      Result.AddNext(MSK_EnumToTypeGroup, FromParam(false, gr_par));
      from_ett_group.Add(gr_par, Result);
    end;
    
    private static from_param_steps := new Dictionary<ValueTuple<boolean,FuncParamT>, FuncParamMarshalStep>;
    public static function FromParam(is_res: boolean; par: FuncParamT): FuncParamMarshalStep;
    begin
      var from_param_key := ValueTuple.Create(is_res, par);
      if from_param_steps.TryGetValue(from_param_key, Result) then exit;
      var par_kind := MPK_Invalid;
      var generate_next_steps: Action<FuncParamMarshalStep>;
      
      if par.enum_to_type_data_rep_c <> 1 then
        raise new InvalidOperationException('Use .FromEnumToTypeInfo');
      if (par.arr_lvl<>0) and par.var_arg then
        raise new InvalidOperationException;
      
      if is_res then
      begin
        if par.arr_lvl<>0 then
          raise new InvalidOperationException;
        if par.var_arg then
          raise new InvalidOperationException;
        if par.IsGeneric then
          raise new InvalidOperationException;
      end;
      
      // Note: This is before generic, because "array of array of T" also needs copy,
      // where "array of T" turns into simply "IntPtr"
      if par.arr_lvl+Ord(par.IsString) > 1 then
      {$region ArrayNeedCopy}
      begin
        par_kind := MPK_ArrayNeedCopy;
        
        generate_next_steps := res->
        begin
          res.AddNext(MSK_ArrayFallThrought, FromParam(is_res, new FuncParamT(par.is_const, false, 0, KnownDirectTypes.Pointer)));
          
          if par.arr_lvl+Ord(par.IsString) = 2 then
            res.AddNext(MSK_ArrayFirstItem, FromParam(is_res, new FuncParamT(par.is_const, true, 0, KnownDirectTypes.IntPtr))) else
            res.AddNext(MSK_ArrayCopy, FromParam(is_res, new FuncParamT(par.is_const, false, par.arr_lvl-1+Ord(par.IsString), KnownDirectTypes.IntPtr)));
          
        end;
        
      end else
      {$endregion ArrayNeedCopy}
      
      if par.IsString then
      {$region String}
      begin
        par_kind := MPK_String;
        
        if par.arr_lvl<>0 then
          raise new InvalidOperationException;
        if par.var_arg then
          raise new InvalidOperationException;
        
        generate_next_steps := res->
          res.AddNext(if is_res then MSK_StringResult else MSK_StringParam, FromParam(is_res, new FuncParamT(par.is_const, false, 0, KnownDirectTypes.IntPtr)));
        
      end
      {$endregion String} else
      
      if par.arr_lvl=1 then
      {$region Array}
      begin
        par_kind := MPK_Array;
        
        generate_next_steps := res->
          res.AddNext(MSK_ArrayFirstItem, FromParam(is_res, par.WithPtr(true,0)));
        
      end
      {$endregion Array} else
      
      if par.IsGeneric then
      {$region Generic}
      begin
        par_kind := MPK_Generic;
        
        if par.arr_lvl<>0 then
          raise new InvalidOperationException;
        if not par.var_arg then
          raise new InvalidOperationException;
        
        generate_next_steps := res->
          res.AddNext(MSK_GenericSubstitute, FromParam(is_res, new FuncParamT(par.is_const, true, 0, KnownDirectTypes.StubForGenericT)));
        
      end
      {$endregion Generic} else
      
      {$region Basic}
      begin
        par_kind := MPK_Basic;
        
        if par.is_const and not par.var_arg and (par.raw_t <> KnownDirectTypes.IntPtr) and (par.raw_t <> KnownDirectTypes.Pointer) and not par.tname.StartsWith('^') then
          Otp($'WARNING: const but not ptr param: {par.ToString(true)}');
        if par.arr_lvl<>0 then
          raise new InvalidOperationException;
        
        generate_next_steps := res->exit();
        
      end;
      {$endregion Basic}
      
      Result := new FuncParamMarshalStep(|ValueTuple.Create(par_kind, par)|);
      from_param_steps.Add(from_param_key, Result);
      
      var res := Result;
      Result.UnwrapNextStepGenerators(()->generate_next_steps(res));
      
    end;
    
    private static from_ett_steps := new Dictionary<ValueTuple<EnumToTypeBindingInfo,IDirectNamedType,FuncParamT>, FuncParamMarshalStep>;
    public static function FromEnumToTypeInfo(info: EnumToTypeBindingInfo; data_size_t: IDirectNamedType; data_par: FuncParamT): FuncParamMarshalStep;
    begin
      var from_ett_key := ValueTuple.Create(info, data_size_t, data_par);
      if from_ett_steps.TryGetValue(from_ett_key, Result) then exit;
      
      var need_count_par := (data_par<>nil)
        and (data_par.arr_lvl=0)
        and (data_par.enum_to_type_data_rep_c<>1)
        and (data_par.raw_t<>KnownDirectTypes.String);
      
      if (data_par<>nil) and (data_par.is_const <> info.IsInputData) then
        raise new InvalidOperationException;
      
      Result := new FuncParamMarshalStep(|
        if not need_count_par then
          nil_par else
          ValueTuple.Create(
            MPK_EnumToTypeCount,
            new FuncParamT(false, false, 0, KnownDirectTypes.EnumToTypeDataCountT)
          ),
        ValueTuple.Create(MPK_EnumToTypeBody, data_par)
      |+if info.IsInputData then zero_par_arr else |nil_par|);
      var res := Result;
      
      var add_step := procedure(step_kind: MarshalStepKind; pars: array of FuncParamT) ->
      begin
        var simple_par_steps := pars.ConvertAll(par->FromParam(false, par));
        
        var ett_step := new FuncParamMarshalStep(simple_par_steps.ConvertAll(simple_par_step->simple_par_step.pars.Single));
        res.AddNext(step_kind, ett_step);
        
        if simple_par_steps.All(simple_par_step->simple_par_step.next_steps.Count=0) then
          exit;
        var step_kinds := new MarshalStepKind[pars.Length];
        var steps := new FuncParamMarshalStep[pars.Length];
        for var par_i := 0 to pars.Length-1 do
        begin
          if simple_par_steps[par_i].next_steps.Count=0 then
          begin
            step_kinds[par_i] := MSK_FlatForward;
            // Kinda hacky, but otherwise ett_step.next would have less "FuncParamT"s then ett_step itself
            steps[par_i] := simple_par_steps[par_i];
            continue;
          end;
          var simple_step_kvp := simple_par_steps[par_i].next_steps.Single;
          step_kinds[par_i] := simple_step_kvp.Key.ItemsSeq.Single;
          steps[par_i] := simple_step_kvp.Value.Single;
        end;
        
        ett_step.AddNext(step_kinds, steps);
      end;
      
      if not need_count_par and (data_par<>nil) and (data_par.enum_to_type_data_rep_c=nil) and not info.IsInputData then
        add_step(MSK_EnumToTypeGetSize,
          |
            new FuncParamT(false, false, 0, data_size_t),
            new FuncParamT(info.IsInputData, false, 0, KnownDirectTypes.Pointer),
            new FuncParamT(false, true, 0, data_size_t)
          |
        );
      
      var prev_data_par := new FuncParamT(info.IsInputData, true, 0, TypeLookup.FromName('T'+if info.IsInputData then 'Inp' else ''));
      if (data_par=nil) or data_par.IsString then
      begin
        prev_data_par := new FuncParamT(info.IsInputData, false, 0, KnownDirectTypes.Pointer);
      end;
      
      add_step(MSK_EnumToTypeBody,
        |
          new FuncParamT(false, false, 0, data_size_t),
          prev_data_par
        | +
        if info.IsInputData then
          System.Array.Empty&<FuncParamT> else
        if data_par.enum_to_type_data_rep_c<>nil then
          |new FuncParamT(false, true, 0, data_size_t)| else
          |new FuncParamT(false, false, 0, KnownDirectTypes.IntPtr)|
      );
      
      from_ett_steps.Add(from_ett_key, Result);
    end;
    
    {$ifdef DEBUG}
    public function EnmrPars := pars.Select(\(par_kind,par)->par);
    {$endif DEBUG}
    
    public function ToString: string; override :=
      self.pars.Select(\(par_kind,par)->$'{par_kind}: {ObjectToString(par?.ToString(true,true))}').JoinToString('; ');
    
  end;
  
  {$endregion FuncParamMarshalStep}
  
  {$region MethodImplData}
  
  MethodImplData = sealed class
    private name := default(string);
    private ett_enum_name := default(string);
    private is_public: boolean;
    
    private par_groups: array of FuncParamMarshalStep;
    
    // Used for:
    // - Replace call_to with newly discovered native MethodImplData
    private call_by := new List<MethodImplData>;
    
    private step_marshal_choice := default(MultiBooleanChoice);
    // Used for:
    // - Check: if step is the same, pass pars as is
    // - Get callable name for a given step
    private call_to := new Dictionary<MarshalCallKind, MethodImplData>;
    
    public constructor(public_name, ett_enum_name: string; par_groups: array of FuncParamMarshalStep);
    begin
      self.name := public_name;
      self.ett_enum_name := ett_enum_name;
      self.is_public := true;
      
      self.par_groups := par_groups;
      
    end;
    public constructor(private_name: string; prev_md: MethodImplData; ovr_kind: MarshalCallKind);
    begin
      self.name := private_name;
      self.is_public := false;
      
      if ovr_kind.original_step_kinds.Length <> prev_md.par_groups.Length then
        raise new InvalidOperationException;
      var par_groups := new List<FuncParamMarshalStep>;
      for var i := 0 to ovr_kind.original_step_kinds.Length-1 do
      begin
        var step_kind := ovr_kind.original_step_kinds[i];
        if step_kind.IsSingleFlatForward then
          par_groups += prev_md.par_groups[i] else
          par_groups.AddRange( prev_md.par_groups[i].next_steps[step_kind] );
      end;
      self.par_groups := par_groups.ToArray;
      
    end;
    public constructor(ntv_dup_name: string; prev_md: MethodImplData);
    begin
      self.name := ntv_dup_name;
      self.is_public := false;
      self.par_groups := prev_md.par_groups;
    end;
    private constructor := raise new InvalidOperationException;
    
    public function NativeDup: ValueTuple<MarshalCallKind, MethodImplData, MultiBooleanChoice>;
    begin
      if not self.IsPublic then
        // .NativeDup only used to separate ntv and public ovr's
        raise new InvalidOperationException;
      Result.Item1 := ArrFill(self.par_groups.Length, MSK_FlatForward);
      Result.Item2 := new MethodImplData(self.name, self);
      Result.Item3 := MultiBooleanChoiceSet.Create(self.par_groups.Length).Enmr.First;
    end;
    
    private created_ovr := default(FuncOverload);
    public function MakeOverload: FuncOverload;
    begin
      Result := created_ovr;
      if not ReferenceEquals(Result, nil) then exit;
      var pars := new List<FuncParamT>;
      foreach var s in par_groups do
        foreach var (par_kind, par) in s.pars do
          pars += par;
      Result := pars.ToArray;
      created_ovr := Result;
    end;
    
    public function MakeOvrSteps: array of MarshalCallKind;
    begin
      var branching_counts := par_groups.Select(s->s.next_steps.Count);
      var max_branching := branching_counts.Max;
      
      if max_branching>2 then
        raise new InvalidOperationException;
      if (max_branching=2) and (branching_counts.CountOf(max_branching)<>1) then
        raise new NotImplementedException;
      
      Result := ArrGen(max_branching, i->
        new MarshalCallKind(
          self.par_groups.ConvertAll(s->
            s.next_steps.Keys.Take(max_branching-i).DefaultIfEmpty(MarshalStepKindCombo.FlatForward).Last
          )
        )
      );
      
      {$ifdef DEBUG}
      if Result.Any(call->call.IsAllFlatForward) then
        raise new InvalidOperationException;
      {$endif DEBUG}
    end;
    
    public function IsFinalStep :=
      not is_public and par_groups.All(s->s.next_steps.Count=0);
    public function IsFinalCall: boolean;
    begin
      Result := call_to.Count=0;
      {$ifdef DEBUG}
      if Result <> IsFinalStep then
        raise new InvalidOperationException;
      {$endif DEBUG}
    end;
    
    public property IsPublic: boolean read is_public;
    
    private final_name := default(string);
    public function FinalName(cache: HashSet<string>): string;
    begin
      
      if final_name<>nil then
      begin
        Result := final_name;
        exit;
      end;
      
      if IsPublic then
      begin
        if IsFinalCall then
          raise new InvalidOperationException;
        Result := self.name;
        final_name := Result;
        exit;
      end;
      
      final_name := (IsFinalCall?'ntv_':'temp_') + self.name;
      
      if cache=nil then
        raise new InvalidOperationException($'Name for {final_name} was not inited');
      
      Result := (1).Step
        .Select(i->$'{final_name}_{i}')
        .First(cache.Add);
      final_name := Result;
      
    end;
    
    public procedure AddCallTo(ovr_step_kind: MarshalCallKind; md: MethodImplData; step_marshal_choice: MultiBooleanChoice);
    begin
      {$ifdef DEBUG}
      if ovr_step_kind in self.call_to then
      begin
        Otp(self.name);
        foreach var k in self.call_to.Keys do
          Otp(k.ToString);
        raise new InvalidOperationException(ovr_step_kind.ToString);
      end;
      {$endif DEBUG}
      self.call_to.Add(ovr_step_kind, md);
      md.call_by += self;
      {$ifdef DEBUG}
      if step_marshal_choice.FlagCount <> self.par_groups.Length then
        raise new InvalidOperationException;
      {$endif DEBUG}
      if self.step_marshal_choice=default(MultiBooleanChoice) then
        self.step_marshal_choice := step_marshal_choice else
      begin
        {$ifdef DEBUG}
        for var i := 0 to step_marshal_choice.FlagCount-1 do
          if self.step_marshal_choice.Flag[i]<>step_marshal_choice.Flag[i] then
            raise new InvalidOperationException;
        {$endif DEBUG}
      end;
    end;
    
    public procedure ReplaceCallsWith(md: MethodImplData);
    begin
      foreach var caller in self.call_by do
      begin
        var k := caller.call_to.Keys.Single(k->caller.call_to[k]=self);
        caller.call_to[k] := md;
        md.call_by += caller;
      end;
    end;
    
    public procedure FixETTCountParNames(par_names: array of string);
    begin
      var par_i := 0;
      foreach var step in par_groups do
        foreach var (par_kind, par) in step.pars do
        begin
          if par_kind=MPK_EnumToTypeCount then
          begin
            var end1 := '_size';
            var end2 := '_count';
            var par_name := par_names[par_i];
            if not par_name.EndsWith(end1) then
              raise new NotImplementedException;
            par_name := par_name.Remove(par_name.Length-end1.Length) + end2;
            par_names[par_i] := par_name;
          end;
          par_i += 1;
        end;
      if par_i<>par_names.Length then
        raise new InvalidOperationException;
    end;
    
    public function HasEnumToTypeEnumName :=
      self.ett_enum_name <> nil;
    public function EnumToTypeEnumName: string;
    begin
      Result := self.ett_enum_name;
      if Result=nil then raise new InvalidOperationException;
    end;
    
    public function ToString: string; override;
    begin
      Result := $'{self.FinalName(nil)}: ({MakeOverload})';
      if IsFinalCall then exit;
      Result += ' => ';
      Result += call_to.Values.Select(md->md.FinalName(nil)).JoinToString('+');
    end;
    
  end;
  
  {$endregion MethodImplData}
  
  {$region ManagedMethodWriter}
  
  // Lower value means simpler and more often written
  FuncParamWriteOrder = (
    FPWO_InPlace,
    FPWO_ArrNil,
    FPWO_FlatResult,
    FPWO_ResultConvert,
    FPWO_EnumToTypeWithGetCount,
    FPWO_Multiline
  );
  
  FuncParWriteContainer = sealed class(Writer)
    private wr: Writer;
    private is_proc, need_block: boolean;
    private tab: integer;
    
    public constructor(wr: Writer; is_proc, need_block: boolean; base_tab: integer);
    begin
      self.wr := wr;
      self.is_proc := is_proc;
      self.need_block := need_block;
      self.tab := base_tab;
    end;
    
    public procedure Write(s: string); override := wr += s;
    
    public procedure Flush; override := raise new InvalidOperationException;
    public procedure Close; override := raise new InvalidOperationException;
    
    public procedure WriteTabs(d_tab: integer := 0) :=
      loop tab+d_tab do
        wr += '  ';
    
    public procedure BeginBlock(block_beg: string);
    begin
      if block_beg<>nil then
      begin
        WriteTabs;
        wr += block_beg;
        wr += #10;
      end;
      tab += 1;
    end;
    public procedure EndBlock(place_end: boolean);
    begin
      tab -= 1;
      if place_end then
      begin
        WriteTabs;
        wr += 'end;'#10;
      end;
    end;
    public procedure MakeBlock(block_beg: string; write_block_body: FuncParWriteContainer->());
    begin
      BeginBlock(block_beg);
      write_block_body(self);
      EndBlock(block_beg<>nil);
    end;
    
    public procedure WriteResAssign(write_assigned_value: FuncParWriteContainer->());
    begin
      
      WriteTabs;
      if need_block and not is_proc then
        wr += 'Result := ';
      write_assigned_value(self);
      wr += ';'#10;
      
    end;
    public procedure WriteResAssign(assigned_value_str: string) :=
      WriteResAssign(wr->(wr += assigned_value_str));
    
    private event on_call: procedure(step_kind: MarshalStepKind; call_pars: array of FuncParamT; write_par: Writer->());
    public procedure MakeCall(step_kind: MarshalStepKind; call_pars: array of FuncParamT; write_par: Writer->() := nil) :=
      on_call(step_kind, call_pars, write_par);
    public procedure MakeCall(step_kind: MarshalStepKind; call_pars: array of FuncParamT; par_str: string) :=
      on_call(step_kind, call_pars, wr->(wr += par_str));
    
  end;
  
  FuncParWriterProc = procedure(wr: FuncParWriteContainer);
  FuncParWriter = ValueTuple<FuncParamWriteOrder, FuncParWriterProc>;
  
  ManagedMethodWriter = sealed class
    private md: MethodImplData;
    private ovr: FuncOverload;
    private generic_names: array of string;
    private uncalled := new HashSet<MarshalCallKind>;
    
    private is_proc: boolean;
    private need_block := false;
    
    public constructor(md: MethodImplData; ovr: FuncOverload; generic_names: array of string);
    begin
      self.md := md;
      self.ovr := ovr;
      self.generic_names := generic_names;
      
      self.is_proc := ovr[0]=nil;
      uncalled.UnionWith( md.call_to.Keys );
      
      if generic_names.Any then
        need_block := true;
      
      if md.call_to.Count>1 then
        need_block := true;
      
    end;
    private constructor := raise new InvalidOperationException;
    
    public procedure MarkRequireBlock := need_block := true;
    
    private pointer_types := new HashSet<string>;
    public procedure AddPointerType(tname: string);
    begin
      MarkRequireBlock;
      pointer_types += tname;
    end;
    
    private step_write_procs: array of FuncParWriterProc;
    private ordered_step_inds: array of integer;
    public procedure InitWriters(par_name_at: integer->string
      ; make_res_writer, make_par_writer: function(par_kind: MarshalParamKind; par: FuncParamT; par_name: string): FuncParWriter
      ; make_ett_writer: function(pars: array of ValueTuple<MarshalParamKind, FuncParamT, string>): FuncParWriter
    );
    begin
      var step_write_procs := new List<FuncParWriterProc>;
      var step_write_orders := new List<FuncParamWriteOrder>;
      
      var par_done_c := 0;
      foreach var step in md.par_groups index step_i do
        if not md.step_marshal_choice.Flag[step_i] then
        begin
          var pars := step.pars.ConvertAll(\(par_kind,par)->par);
          if par_done_c=0 then
          begin
            step_write_orders += FPWO_FlatResult;
            step_write_procs += wr->wr.WriteResAssign(wr->wr.MakeCall(MSK_FlatForward, pars))
          end else
          begin
            step_write_orders += FPWO_InPlace;
            var par_names := ArrGen(step.pars.Length, par_i->par_name_at(par_done_c+par_i));
            step_write_procs += wr->wr.MakeCall(MSK_FlatForward, pars, wr->
              wr.WriteSeparated(par_names, (wr,par_name)->(wr += par_name), ', ')
            );
          end;
          par_done_c += step.pars.Length;
        end else
        if step.pars.Any(\(par_kind,par)->par_kind=MPK_EnumToTypeBody) then
        begin
          var (order, proc) :=
            make_ett_writer(step.pars.ConvertAll((\(par_kind,par), par_i)->
              ValueTuple.Create(par_kind, par, par_name_at(par_done_c+par_i))
            ));
          step_write_orders += order;
          step_write_procs += proc;
          par_done_c += step.pars.Length;
        end else
          foreach var (par_kind, par) in step.pars do
          begin
            var (order, proc) :=
              (par_done_c=0?make_res_writer:make_par_writer)(par_kind, par, par_name_at(par_done_c));
            step_write_orders += order;
            step_write_procs += proc;
            par_done_c += 1;
          end;
      
      {$ifdef DEBUG}
      if par_done_c <> md.par_groups.Sum(step->step.pars.Length) then
        raise new InvalidOperationException;
      {$endif DEBUG}
      
      self.step_write_procs := step_write_procs.ToArray;
      
      self.ordered_step_inds := ArrGen(step_write_orders.Count, par_i->par_i);
      System.Array.Sort(step_write_orders.ToArray, self.ordered_step_inds);
      
    end;
    
    private write_step_procs: array of Action<Writer> := nil;
    private step_kinds: array of MarshalStepKind := nil;
    private call_pars: array of array of FuncParamT;
    private procedure ExecuteMarshalCore(wr: Writer; tab, left_c: integer);
    begin
      
      left_c -= 1;
      var step_i := ordered_step_inds[left_c];
      var write_proc := step_write_procs[step_i];
      
      var wr_cont := new FuncParWriteContainer(wr, is_proc, need_block, tab);
      
      wr_cont.on_call += (step_kind, call_par_arr, write_step_proc)->
      begin
        write_step_procs[step_i] := write_step_proc;
        step_kinds[step_i] := step_kind;
        call_pars[step_i] := call_par_arr;
        if (step_i=0) and (write_step_proc<>nil) then
          raise new InvalidOperationException;
        
        if left_c <> 0 then
          ExecuteMarshalCore(wr, wr_cont.tab, left_c) else
        begin
          var ovr_step_kind := new MarshalCallKind(step_kinds);
          
          var called_md: MethodImplData;
          if not md.call_to.TryGetValue(ovr_step_kind, called_md) then
            raise new InvalidOperationException($'{md.FinalName(nil)}({md.MakeOverload}) tried to call undefined{#10}({ovr_step_kind}); defined:'+
              md.call_to.Keys.Select(k->$'{#10}({k}) => {md.call_to[k]}').JoinToString('')
            );
          uncalled.Remove(ovr_step_kind);
          
          if not called_md.MakeOverload.ItemsSeq.SequenceEqual(call_pars.SelectMany(a->a)) then
          begin
            Otp($'ERORR: {md.FinalName(nil)} ({md.MakeOverload}) + ({ovr_step_kind}) reported wrong param types:');
            Otp($'Got: {new FuncOverload(call_pars.SelectMany(a->a).ToArray)}');
            Otp($'Exp: {called_md.MakeOverload}');
          end;
          
          wr += called_md.FinalName(nil);
          if write_step_procs.Any(wsp->wsp<>nil) then
          begin
            wr += '(';
            wr.WriteSeparated((1..write_step_procs.Length-1).Where(step_i->write_step_procs[step_i]<>nil),
              (wr,step_i)->write_step_procs[step_i](wr), ', '
            );
            wr += ')';
          end;
          
        end;
        
        write_step_procs[step_i] := nil;
        step_kinds[step_i] := MSK_Invalid;
        call_pars[step_i] := nil;
      end;
      
      write_proc(wr_cont);
      
      if wr_cont.tab<>tab then
        Otp('ERROR: Tab lvl was not reset');
    end;
    private procedure ExecuteMarshalCore(wr: Writer);
    begin
      self.write_step_procs := new Action<Writer>[step_write_procs.Length];
      self.step_kinds := new MarshalStepKind[step_write_procs.Length];
      SetLength(self.call_pars, step_write_procs.Length);
      
      ExecuteMarshalCore(wr, 3, step_kinds.Length);
      
      self.write_step_procs := nil;
      self.step_kinds := nil;
      self.call_pars := nil;
    end;
    
    public procedure Write(wr: Writer);
    begin
      
      {$region Finish header}
      
      if need_block then
      begin
        wr += ';';
        if generic_names.Any then
        begin
          wr += ' where ';
          wr.WriteSeparated(generic_names, (wr,gn)->(wr+=gn), ', ');
          wr += ': record;';
        end;
        wr += #10;
      end else
      begin
        wr += ' :='#10;
      end;
      
      {$endregion Finish header}
      
      {$region Write body}
      
      if need_block then
      begin
        foreach var tname in pointer_types do
        begin
          wr += '      type P';
          wr += tname.First.ToUpper;
          wr += tname.SubString(1);
          wr += ' = ^';
          wr += tname;
          wr += ';'#10;
        end;
        wr += '    begin'#10;
      end;
      
      ExecuteMarshalCore(wr);
      
      if need_block then
      begin
        wr += '    end;'#10;
      end;
      
      {$ifdef DEBUG}
      wr.Flush;
      {$endif DEBUG}
      
      {$endregion Write body}
      
      {$region Sanity checks}
      
      foreach var ovr_kind in uncalled do
        Otp($'ERROR: {md.FinalName(nil)} did not call ovr kind ({ovr_kind}) => ({md.call_to[ovr_kind].MakeOverload})');
      
      {$endregion Sanity checks}
      
    end;
    
  end;
  
  {$endregion ManagedMethodWriter}
  
end.