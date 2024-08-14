unit CodeContainerItems;

{$zerobasedstrings}

interface

uses System;

uses '../../../POCGL_Utils';
uses '../../../Utils/AOtp';
uses '../../../Utils/CodeGen';

uses '../Common/PackingUtils';

uses BinUtils;
uses LLPackingUtils;
uses ItemNames;
uses ChoiceSets;
uses FuncHelpers;

uses NamedItemBase;
uses NamedItemFixerBase;

uses TypeRefering; //TODO Только для временных авто-фиксеров в Func

uses EnumItems;
uses ParData;

uses NamedTypeItems; //TODO Только для костыля obj_info (enum_to_type)

type
  
  {$region Func}
  
  Func = sealed class(NamedLoadedItem<Func, ApiVendorLName>)
    private entry_point_name: string;
    private ntv_pars: array of LoadedParData;
    private alias_ind: integer?;
    
    private changed_by_fixer := false;
    
    public property TotalParamCount: integer read ntv_pars.Length;
    public property ExistingParCount: integer read TotalParamCount - Ord(is_proc);
    public property NativePar[par_i: integer]: LoadedParData read ntv_pars[par_i];
    
    private static max_unfixed_overload_count := 0;
    public static procedure SetMaxUnfixedOverloads(c: integer) :=
      max_unfixed_overload_count := c;
    
    {$region Load}
    
    static constructor := RegisterLoader(br->
    begin
      Result := new Func(new ApiVendorLName(br), false);
      Result.entry_point_name := br.ReadString;
      Result.ntv_pars := br.ReadArr((br,i)->LoadedParData.Load(br, i<>0));
      Result.alias_ind := br.ReadIndexOrNil;
    end);
    
    //TODO Use for code-gen
    public property HasAlias: boolean read alias_ind<>nil;
    public property Alias: Func read Func.ByIndex(alias_ind.Value);
    
    public function is_proc := ntv_pars[0].IsNakedVoid;
    
    {$endregion Load}
    
    //TODO Transport to XML
    // - Mostly a question of adding [in/out] parameters
    {$region Ugly old fix's}
    
    private procedure AddAutoFixerPPT(per_par: array of ()->sequence of ValueTuple<boolean,FuncParamT>);
    
    public static procedure AddAutoFixersForAllOutParams := ForEachDefined(f->
    begin
      
      var fix_pars := f.ntv_pars.ConvertAll((par,par_i)->
      begin
        Result := false;
        if par_i=0 then exit;
        Result := par.name.EndsWith('_ret');
      end);
      var fix_all_pars := f.Name.l_name.StartsWith('Get');
      if not fix_pars.Any(b->b) and not fix_all_pars then exit;
      
      var changes := new Func<IEnumerable<ValueTuple<boolean,FuncParamT>>>[f.ntv_pars.Length];
      changes[0] := ()->System.Linq.Enumerable.Empty&<ValueTuple<boolean,FuncParamT>>;
      for var i := 1 to changes.Length-1 do
      begin
        var par_i := i;
        changes[i] := ()->
        begin
          Result := System.Linq.Enumerable.Empty&<ValueTuple<boolean,FuncParamT>>;
          var ppt0 := f.possible_par_types[par_i][0];
          if ppt0.arr_lvl<>1 then exit;
          var need_keep := ppt0.arr_lvl in f.ntv_pars[par_i].CalculatedReadonlyLvls;
          var need_rem := fix_pars[par_i] or (fix_all_pars and not need_keep);
          if need_keep and need_rem then raise new NotImplementedException(f.ToString);
          if need_rem then Result := |ValueTuple.Create(false,ppt0)|;
        end;
      end;
      f.AddAutoFixerPPT(changes);
      
    end);
    
    public static procedure AddAutoFixersForCL := ForEachDefined(f->
    begin
      
      var calculated_changes: array of sequence of ValueTuple<boolean,FuncParamT>;
      var make_changes := procedure->
      begin
        if calculated_changes<>nil then exit;
        calculated_changes := ArrFill(f.ntv_pars.Length, System.Linq.Enumerable.Empty&<ValueTuple<boolean,FuncParamT>>);
        
        // from_incl:to_excl:step
        var rev_pars := f.ntv_pars[:0:-1];
        
        var err_code_t  := TypeLookup.FromNameString('cl::ErrorCode');
        var event_t     := TypeLookup.FromNameString('cl::event');
        
        if rev_pars.Length < 1 then exit;
        var last_err_code := rev_pars[0].CalculatedDirectType = err_code_t;
        if last_err_code then
          calculated_changes[^1] := |ValueTuple.Create(false, new FuncParamT(false,false,0,KnownDirectTypes.IntPtr))|;
        
        var ind_sh := Ord(last_err_code);
        if rev_pars.Length < 2+ind_sh then exit;
        if rev_pars.Skip(ind_sh).Take(2).All(par->(par.CalculatedDirectType=event_t) and (par.CalculatedPtr=1)) then
        begin
          calculated_changes[^(1+ind_sh)] := |ValueTuple.Create(false, new FuncParamT(false,false,1,event_t))|;
          f.unopt_arr[^(2+ind_sh)] := true;
        end;
        
      end;
      
      var changes := new Func<IEnumerable<ValueTuple<boolean,FuncParamT>>>[f.ntv_pars.Length];
      for var i := 0 to changes.Length-1 do
      begin
        var par_i := i;
        changes[i] := ()->
        begin
          make_changes;
          Result := calculated_changes[par_i];
        end;
      end;
      f.AddAutoFixerPPT(changes);
      
    end);
    
    {$endregion Ugly old fix's}
    
    {$region PPT}
    
    // ": array of possible_par_type_collection"
    public possible_par_types: array of List<FuncParamT>;
    public unopt_arr: array of boolean;
    public procedure InitPossibleParTypes;
    begin
      if possible_par_types<>nil then exit;
      unopt_arr := ArrFill(ntv_pars.Length, false);
      possible_par_types := ntv_pars.ConvertAll((par,par_i)->
      begin
        Result := nil;
        if is_proc and (par_i=0) then exit;
        
        var is_enum_to_type_data := false;
        if ntv_pars.Select(par->par.CalculatedDirectType as Group).Select(gr->gr?.Body as ObjInfoEnumsInGroup).SingleOrDefault(gr_body->gr_body<>nil) is ObjInfoEnumsInGroup(var gr_body) then
          is_enum_to_type_data := gr_body.EnmrBindings(self.ntv_pars).Any(b->b.data_par_ind=par_i);
        
        Result := par.MakePPT(self.ToString, par_i=0, is_enum_to_type_data);
      end);
    end;
    
    {$endregion PPT}
    
    {$region Overloads}
    
    private has_enum_to_type := false;
    private enum_to_type_gr := default(IDirectNamedType);
    
    public all_overloads: List<FuncOverload>;
    public procedure InitOverloads;
    begin
      if all_overloads<>nil then exit;
      InitPossibleParTypes;
      
      var opt_arr := new boolean[ntv_pars.Length];
      foreach var types in possible_par_types index par_i do
      begin
        if is_proc and (par_i=0) then continue;
        if unopt_arr[par_i] then continue;
        opt_arr[par_i] := types.Any(par->par.arr_lvl=0) and types.Any(par->par.arr_lvl<>0);
        if unopt_arr[par_i] then
          if opt_arr[par_i] then
            opt_arr[par_i] := false else
            Otp($'WARNING: {self} had par#{par_i} as unopt_arr, but it does not need it: {ObjectToString(types.Select(par->par.ToString(true,true,true)))}');
      end;
      
      {$region Sort}
      for var par_i := ntv_pars.Length-1 downto 0 do
      begin
        if is_proc and (par_i=0) then continue;
        possible_par_types[par_i].Sort((p1,p2)->
        begin
          Result := 0;
          if object.ReferenceEquals(p1,p2) then exit; // Because List.Sort
          if p1=p2 then raise new System.InvalidOperationException(
            $'ERROR: {self} par#{par_i}: Type [{p1.ToString(true,true,true)}] is allowed twice'
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
          Result += integer(p1.TypeOrder);
          Result -= integer(p2.TypeOrder);
          if Result<>0 then exit;
          
          // 7. Different reference target or enum group
          if p1.var_arg or (p1.arr_lvl<>0) or (p1.TypeOrder <> FuncParamTypeOrder.FPTO_Basic) then
            Result := string.Compare(p1.tname, p2.tname);
          if Result<>0 then exit;
          
          Otp($'ERROR: {self} par#{par_i}: Failed to sort [{p1.ToString(true,true,true)}] vs [{p2.ToString(true,true,true)}]');
        end);
      end;
      {$endregion Sort}
      
      var enum_to_type_gr := ntv_pars.Select(par->par.CalculatedDirectType as Group).SingleOrDefault(gr->gr?.Body is ObjInfoEnumsInGroup);
      self.enum_to_type_gr := enum_to_type_gr;
      var enum_to_type_gr_body := ObjInfoEnumsInGroup(enum_to_type_gr?.Body);
      var enum_to_type_gr_par_ind := -1;
      if enum_to_type_gr_body<>nil then
      begin
        enum_to_type_gr_par_ind := ntv_pars.FindIndex(par->par.CalculatedDirectType=enum_to_type_gr);
        if enum_to_type_gr_par_ind=-1 then raise new InvalidOperationException;
      end;
      
      var ppt_choices := new MultiChoiceSet(possible_par_types.ConvertAll((ppt,par_i)->
        is_proc and (par_i=0) ? 1 : ppt.Count
      ));
      
      var expected_ovr_count := 0;
      if enum_to_type_gr<>nil then
        expected_ovr_count += 1 + 2*enum_to_type_gr_body.Enums.Length;
      expected_ovr_count += ppt_choices.StateCount;
      
      all_overloads := new List<FuncOverload>(expected_ovr_count);
      
      var helper_ovrs := new HashSet<FuncOverload>;
      {$region EnumToType}
      
      if enum_to_type_gr<>nil then
      begin
        self.has_enum_to_type := true;
        
        {$region Find}
        
        var enum_to_type_bindings := enum_to_type_gr_body.EnmrBindings(self.ntv_pars).ToArray;
        if enum_to_type_bindings.Length=0 then
          raise new InvalidOperationException;
        
        foreach var b in enum_to_type_bindings do
        begin
          var p1 := new FuncParamT(b.IsInputData, false, 0, KnownDirectTypes.IntPtr);
          var p2 := new FuncParamT(b.IsInputData, false, 0, KnownDirectTypes.Pointer);
          if not possible_par_types[b.data_par_ind].Remove(p1) then
            raise new InvalidOperationException(FuncOverload.Create(possible_par_types[b.data_par_ind].ToArray).ToString);
          possible_par_types[b.data_par_ind].Add(p2);
        end;
        
        {$endregion Find}
        
        {$region Helper ovr's}
        
        var main_helper_pars := new FuncParamT[ntv_pars.Length];
        begin
          for var par_i := 0 to ntv_pars.Length-1 do
          begin
            if is_proc and (par_i=0) then continue;
            
            if enum_to_type_bindings.Find(b->par_i=b.data_par_ind) is EnumToTypeBindingInfo(var b) then
            begin
              var ntv_par := ntv_pars[par_i];
              if ntv_par.CalculatedDirectType <> KnownDirectTypes.IntPtr then
                raise new InvalidOperationException;
              if ntv_par.CalculatedPtr<>0 then
                raise new InvalidOperationException;
              case b.IsInputData of
                true: if not ntv_par.CalculatedReadonlyLvls.SequenceEqual(|1|) then
                  raise new InvalidOperationException;
                false: if ntv_par.CalculatedReadonlyLvls.Any then
                  raise new InvalidOperationException;
                else raise nil;
              end;
              if ntv_par.ArrSize <> ParArrSizeNotArray.Instance then
                raise new InvalidOperationException;
              if ntv_par.ValCombo <> nil then
                raise new InvalidOperationException;
              var t := $'T';
              if b.IsInputData then
                t += 'Inp';
              main_helper_pars[par_i] := new FuncParamT(b.IsInputData, true, 0, TypeLookup.FromName(t));
              continue;
            end;
            
            if enum_to_type_bindings.Any(b->par_i=b.returned_size_par_ind) then
            begin
              var ntv_par := ntv_pars[par_i];
              if ntv_par.CalculatedDirectType <> KnownDirectTypes.UIntPtr then
                raise new InvalidOperationException;
              if ntv_par.CalculatedPtr<>1 then
                raise new InvalidOperationException;
              if ntv_par.CalculatedReadonlyLvls.Any then
                raise new InvalidOperationException;
              if ntv_par.ArrSize <> ParArrSizeNotArray.Instance then
                raise new InvalidOperationException;
              if ntv_par.ValCombo <> nil then
                raise new InvalidOperationException;
              main_helper_pars[par_i] := new FuncParamT(false,true, 0, KnownDirectTypes.UIntPtr);
              continue;
            end;
            
            if possible_par_types[par_i].Count=1 then
            begin
              main_helper_pars[par_i] := possible_par_types[par_i].Single;
              continue;
            end;
            
            if (possible_par_types[par_i].Count=3) and (ntv_pars[par_i].CalculatedPtr=1) then
            begin
              main_helper_pars[par_i] := possible_par_types[par_i].Single(p->p.var_arg);
              continue;
            end;
            
            raise new NotImplementedException;
          end;
          
          var repl_pars := new FuncParamT[ntv_pars.Length];
          foreach var r in enum_to_type_gr_body.Enums do
          begin
            var set_inp := not r.HasInput;
            // In case of ParArrSizeArbitrary, an additional call to get size could be needed
            // But if "not r.HasOutput" - overload cannot be generated (warning below)
            var set_otp := r.HasOutput and (r.OutputT.ArrSize = ParArrSizeArbitrary.Instance);
            
            foreach var b in enum_to_type_bindings do
              if b.IsInputData ? set_inp : set_otp then
                repl_pars[b.data_par_ind] := new FuncParamT(b.IsInputData, false, 0, KnownDirectTypes.Pointer);
            
          end;
          foreach var b in enum_to_type_bindings do
            if not b.IsInputData then
              repl_pars[b.returned_size_par_ind.Value] := new FuncParamT(false, false, 0, KnownDirectTypes.IntPtr);
          
          foreach var allow_ptrs_choise in MultiBooleanChoiceSet.Create(repl_pars.ConvertAll(par->par<>nil)).Enmr do
          begin
            var pars := new FuncParamT[ntv_pars.Length];
            for var par_i := 0 to pars.Length-1 do
              pars[par_i] := if allow_ptrs_choise.Flag[par_i] then
                repl_pars[par_i] else main_helper_pars[par_i];
            var ovr: FuncOverload := pars;
            all_overloads += ovr;
            helper_ovrs += ovr;
          end;
          
        end;
        
        {$endregion Helper ovr's}
        
        {$region Per enum ovr's}
        
        foreach var r in enum_to_type_gr_body.Enums do
        begin
          if enum_to_type_bindings.Any(b->not b.IsInputData) and not r.HasOutput then
          begin
            Otp($'WARNING: {self} could not generate overload: no output type info for {enum_to_type_gr} {r.Enum}');
            continue;
          end;
          // Temp. moved to LogAllEnumToType
//          if r.HasOutput and (r.OutputT.CalculatedPtr>1) then
//          begin
//            log.Otp($'{self} did not generate overload: output type for {enum_to_type_gr} {r.Enum} is nested array');
//            continue;
//          end;
          
          var ename := r.Enum.Name;
          
          if ename.api<>enum_to_type_gr.Name.api then
            raise new InvalidOperationException;
          
          var enum_name := ename.l_name;
          if ename.vendor_suffix<>nil then
            enum_name += '_'+ename.vendor_suffix;
          
          // If inp and otp are not dynamic arrays
          // only "explicit_count_par=true" will be added
          for var explicit_count_par := false to true do
          begin
            var pars := main_helper_pars.ToArray;
            pars[ntv_pars.FindIndex(par->par.CalculatedDirectType=enum_to_type_gr)] := nil;
            
            var any_binding_dynamic := false;
            
            foreach var b in enum_to_type_bindings do
            begin
              pars[b.passed_size_par_ind] := nil;
              if b.returned_size_par_ind<>nil then
                pars[b.returned_size_par_ind.Value] := nil;
              
              if b.IsInputData ? not r.HasInput : not r.HasOutput then
              begin
                pars[b.data_par_ind] := nil;
                continue;
              end;
              
              var data_size_is_dynamic: boolean;
              if b.IsInputData then
              begin
                var inp_par := r.InputT;
                var inp_t := inp_par.CalculatedDirectType;
                
                match inp_par.ArrSize with
                  ParArrSizeNotArray(var pasna): data_size_is_dynamic := false;
                  ParArrSizeArbitrary(var pasa): data_size_is_dynamic := true;
                  else raise new NotImplementedException;
                end;
                
                if inp_par.CalculatedPtr <> Ord(data_size_is_dynamic) then
                  raise new NotImplementedException;
                if inp_par.ValCombo <> nil then
                  raise new InvalidOperationException;
                
                if data_size_is_dynamic then
                begin
                  var par := new FuncParamT(true, explicit_count_par, Ord(not explicit_count_par), inp_t);
                  par.enum_to_type_data_rep_c := nil;
                  pars[b.data_par_ind] := par;
                  any_binding_dynamic := true;
                end else
                  pars[b.data_par_ind] := new FuncParamT(true, false, 0, inp_t);
                
              end else
              // not b.IsInputData
              begin
                var otp_par := r.OutputT;
                var otp_t := otp_par.CalculatedDirectType;
                if explicit_count_par and (otp_par.CalculatedPtr>1) then
                  otp_t := KnownDirectTypes.IntPtr;
                
                var data_rep_c: integer? := 1;
                var need_arr: boolean;
                match otp_par.ArrSize with
                  
                  ParArrSizeNotArray(var pasna): need_arr := false;
                  
                  ParArrSizeConst(var pasc):
                  begin
                    data_rep_c := pasc.Value;
                    need_arr := true;
                  end;
                  
                  ParArrSizeArbitrary(var pasa):
                  begin
                    data_rep_c := nil;
                    need_arr := otp_t <> KnownDirectTypes.String;
                  end;
                  
                  else raise new NotImplementedException;
                end;
                if otp_par.CalculatedPtr<>0 <> need_arr then
                  raise new NotImplementedException;
                if otp_par.ValCombo <> nil then
                  raise new InvalidOperationException;
                
                var par := new FuncParamT(false, true, if explicit_count_par then 0 else otp_par.CalculatedPtr, otp_t);
                par.enum_to_type_data_rep_c := data_rep_c;
                pars[b.data_par_ind] := par;
                
                data_size_is_dynamic := (data_rep_c<>1) and (otp_t<>KnownDirectTypes.String);
              end;
              
              if data_size_is_dynamic then
              begin
                if explicit_count_par then
                  pars[b.passed_size_par_ind] := new FuncParamT(false, false, 0, KnownDirectTypes.EnumToTypeDataCountT);
                any_binding_dynamic := true;
              end;
            end;
            
            if any_binding_dynamic or explicit_count_par then
              all_overloads += new FuncOverload(pars, enum_to_type_bindings, enum_to_type_gr, enum_name);
          end;
          
        end;
        
        {$endregion Per enum ovr's}
        
      end;
      
      {$endregion EnumToType}
      
      for var only_arr_ovrs := opt_arr.Any(b->b) downto false do
        foreach var ppt_choices_state in ppt_choices.Enmr do
        begin
          var pars := new FuncParamT[ntv_pars.Length];
          for var par_i := 0 to ntv_pars.Length-1 do
          begin
            if is_proc and (par_i=0) then continue;
            var ppt_ind := ppt_choices_state.Choice[par_i];
            if opt_arr[par_i] and (ppt_ind=0 <> only_arr_ovrs) then
            begin
              pars := nil;
              break;
            end;
            pars[par_i] := possible_par_types[par_i][ppt_ind];
          end;
          if pars=nil then continue;
          var ovr: FuncOverload := pars;
          if ovr in helper_ovrs then continue;
          all_overloads += ovr;
        end;
      
      {$ifdef DEBUG}
      // Some overloads are filtered because of only_arr_ovrs
//      if all_overloads.Count<>expected_ovr_count then
//        raise new InvalidOperationException;
      var ovrs_hs := new HashSet<FuncOverload>(expected_ovr_count);
      foreach var ovr in all_overloads do
        if (ovr.enum_to_type_bindings=nil) and not ovrs_hs.Add(ovr) then
          Otp($'ERROR: {self} overload {ovr} was dupped');
      {$endif DEBUG}
    end;
    
    {$endregion Overloads}
    
    {$region Write}
    
    {$region Helpers}
    
    private function MakeWriteableName: string;
    begin
      Result := self.Name.l_name;
      if self.Name.vendor_suffix<>nil then
        Result += self.Name.vendor_suffix.ToUpper;
    end;
    
    public static procedure LogAllEnumToType;
    begin
      var l := new FileLogger(GetFullPathRTA('Log/All EnumToTypeBinding''s.log'));
      loop 3 do l.Otp('');
      
      ForEachDefined(f->
      begin
        f.InitOverloads;
        if not f.has_enum_to_type then exit;
        
        var bound_ovrs := f.all_overloads.Where(ovr->ovr.enum_to_type_bindings<>nil).ToArray;
        
        var (bindings, gr) := bound_ovrs
          .Select(ovr->ValueTuple.Create(ovr.enum_to_type_bindings, ovr.enum_to_type_gr))
          .Distinct.Single;
        
        l.Otp($'# {f.Name.api}.{f.MakeWriteableName}');
        l.Otp(f.ntv_pars.FindIndex(par->par.CalculatedDirectType=gr).ToString);
        foreach var b in bindings do
        begin
          if b.IsInputData then
            l.Otp('!input') else
            l.Otp('!output');
          l.Otp(b.passed_size_par_ind.ToString);
          l.Otp(b.data_par_ind.ToString);
          if b.IsInputData then continue;
          l.Otp(b.returned_size_par_ind.ToString);
        end;
        
        var visited_enum_names := new HashSet<string>;
        foreach var ovr in bound_ovrs do
        begin
          if not visited_enum_names.Add(ovr.enum_to_type_enum_name) then continue;
          
          begin
            var r := ObjInfoEnumsInGroup((gr as Group).Body).Enums.Single(r->
            begin
              var ename := r.Enum.Name;
              var enum_name := ename.l_name;
              if ename.vendor_suffix<>nil then
                enum_name += '_'+ename.vendor_suffix;
              Result := enum_name = ovr.enum_to_type_enum_name;
            end);
            if r.HasOutput and (r.OutputT.CalculatedPtr>1) then
            begin
              log.Otp($'{f} did not generate overload: output type for {gr} {r.Enum} is nested array');
              if not f.all_overloads.Remove(ovr) then
                raise new InvalidOperationException;
            end;
          end;
          
          l.Otp('--- '+ovr.enum_to_type_enum_name);
          foreach var b in bindings do
          begin
            var par := ovr[b.data_par_ind];
            if par=nil then continue;
            if b.IsInputData then
              l.Otp('!input') else
              l.Otp('!output');
            if not b.IsInputData and not par.var_arg then
              raise new InvalidOperationException;
            l.Otp(par.ToString(true,false, write_const := false));
          end;
          
        end;
        
        l.Otp('');
      end);
      
      loop 1 do l.Otp('');
      l.Close;
    end;
    
    private procedure UseBody(need_write: boolean) :=
      foreach var ovr in all_overloads do
        foreach var par in ovr.ItemsSeq index par_i do
        begin
//          if is_proc and (par_i=0) then continue;
          // In case of "is_proc" or "enum_to_type_binding"
          if par=nil then continue;
          par.Use(need_write);
        end;
    
    public procedure MarkBodyReferenced; override;
    begin
      InitOverloads;
      UseBody(false);
    end;
    
    private static in_wr_block := false;
    private static last_lib_name := default(string);
    private static last_wr_block_func_lnames := new Dictionary<string, Func>;
    public static procedure DefineWriteBlock(lib_name: string; write_funcs: Action);
    begin
      if in_wr_block then
        raise new InvalidOperationException;
      in_wr_block := true;
      last_lib_name := lib_name;
      
      write_funcs();
      
      last_wr_block_func_lnames.Clear;
      in_wr_block := false;
    end;
    
    {$endregion Helpers}
    
    private was_written := false;
    public procedure Write(wr: Writer);
    begin
      if not in_wr_block then
        raise new InvalidOperationException;
      var lib_name := last_lib_name;
      var is_dynamic := lib_name=nil;
      
//      InitOverloads;
      // Should be generated in MarkReferenced
      if all_overloads=nil then
        raise new InvalidOperationException;
      
      if not self.was_written then
      begin
        self.was_written := true;
        inherited written_c += 1;
      end;
      
      {$region Warnings}
      
      if all_overloads.Count=0 then
      begin
        Otp($'ERROR: {self} ended up having 0 overloads. [possible_par_types]:');
        foreach var par in possible_par_types index par_i do
        begin
          if is_proc and (par_i=0) then continue;
          Otp(#9+ObjectToString(par.Select(p->p.ToString(true,true,true))));
        end;
        exit;
      end else
      for var par_i := 0 to ntv_pars.Length-1 do
      begin
        if is_proc and (par_i=0) then continue;
        
        foreach var t in possible_par_types[par_i] do
        begin
          if all_overloads.Any(ovr->ovr[par_i]=t) then continue;
          Otp($'WARNING: {self} par#{par_i} ppt [{t.ToString(true,true,true)}] did not appear in final overloads. Use !ppt fixer to remove it, if this is intentional');
        end;
        
      end;
      self.UseBody(true);
      
      if not self.changed_by_fixer then
      begin
        var overload_count := all_overloads.Count(ovr->ovr.enum_to_type_bindings=nil);
        if overload_count>max_unfixed_overload_count then
          Otp($'WARNING: {overload_count}>{max_unfixed_overload_count} overloads of non-fixed {self}');
        Func.ForEachDefined(other_func->
        begin
          if ReferenceEquals(other_func, self) then exit;
          if not other_func.changed_by_fixer then exit;
          if other_func.Name.api <> self.Name.api then exit;
          if other_func.Name.l_name <> self.Name.l_name then exit;
          Otp($'WARNING: Func [{other_func}] was fixed, but {self} was not');
        end);
      end;
      
      {$endregion Warnings}
      
      {$region MiscInit}
      
      var display_name := self.MakeWriteableName;
      
      if display_name in last_wr_block_func_lnames then
        raise new InvalidOperationException($'{display_name} added in the same api (lib: {ObjectToString(lib_name)}) twice: {last_wr_block_func_lnames[display_name]} and {self}');
      last_wr_block_func_lnames.Add(display_name, self);
      
      if is_dynamic then
        wr += $'    public {display_name}_adr := GetProcAddress(''{entry_point_name}'');' + #10;
      
      {$endregion MiscInit}
      
      {$region WriteOvrT}
      
      var WriteOvrT := procedure(wr: Writer; pars: System.Collections.Generic.IReadOnlyList<FuncParamT>; par_names: array of string; generic_names: ICollection<string>; name: string)->
      begin
        
        if not is_dynamic and (name<>nil) then wr += 'static ';
        wr += if self.is_proc then 'procedure' else 'function';
        
        if name<>nil then
        begin
          wr += ' ';
          if name in pas_keywords then
            wr += '&';
          wr += name;
          if (generic_names<>nil) and (generic_names.Count<>0) then
          begin
            wr += '<';
            wr += generic_names.JoinToString(',');
            wr += '>';
          end;
        end;
        
        if pars.Skip(1).Any(p->p<>nil) then
        begin
          wr += '(';
          var first_par := true;
          for var par_i := 1 to pars.Count-1 do
          begin
            var par := pars[par_i];
            if par=nil then continue;
            if first_par then
              first_par := false else
              wr += '; ';
            if par.var_arg then wr += 'var ';
            wr += par_names[par_i];
            wr += ': ';
            loop par.arr_lvl do wr += 'array of ';
            var tname := par.tname;
            if tname.ToLower in Func.last_wr_block_func_lnames then wr += 'OpenGL.';
            wr += tname;
            if par.default_val<>nil then
            begin
              wr += ' := ';
              wr += par.default_val;
            end;
          end;
          wr += ')';
        end;
        
        if not is_proc then
        begin
          wr += ': ';
          wr += pars[0].ToString(true, write_const := false);
        end;
        
      end;
      
      {$endregion WriteOvrT}
      
      {$region MakeParMarshlers}
      var all_par_marshalers_per_ovr := new List<array of FuncParamMarshalStep>(all_overloads.Count);
      begin
        var ett_bind_info_by_ind: Dictionary<integer, EnumToTypeBindingInfo>;
        var ett_skip_inds: HashSet<integer>;
        var ett_gr: IDirectNamedType;
        if self.has_enum_to_type then
        begin
          var ett_bindings := all_overloads.Select(ovr->ovr.enum_to_type_bindings).Distinct.Single(b->b<>nil);
          ett_gr := all_overloads.Select(ovr->ovr.enum_to_type_gr).Distinct.Single(gr->gr<>nil);
          
          ett_bind_info_by_ind := new Dictionary<integer, EnumToTypeBindingInfo>(ett_bindings.Count);
          ett_skip_inds := new HashSet<integer>(ett_bindings.Count * 2);
          foreach var b in ett_bindings do
          begin
            ett_bind_info_by_ind.Add(b.data_par_ind, b);
            ett_skip_inds += b.passed_size_par_ind;
            if not b.IsInputData then
              ett_skip_inds += b.returned_size_par_ind.Value;
          end;
          
        end;
        
        foreach var ovr in all_overloads do
        begin
          var res := new List<FuncParamMarshalStep>(ntv_pars.Length);
          
          foreach var par in ovr.ItemsSeq index par_i do
          begin
            var is_ett_bound := ovr.enum_to_type_bindings<>nil;
            
            if is_proc and (par_i=0) then
            begin
              if par<>nil then raise new InvalidOperationException;
              res += FuncParamMarshalStep.ProcResult;
              continue;
            end;
            if is_ett_bound then
            begin
              if ntv_pars[par_i].CalculatedDirectType = ett_gr then
              begin
                if par<>nil then raise new InvalidOperationException;
                res += FuncParamMarshalStep.FromEnumToTypeGroup(self.possible_par_types[par_i].Single);
                continue;
              end;
              if par_i in ett_skip_inds then continue;
            end;
            
            if is_ett_bound and (par_i in ett_bind_info_by_ind) then
            begin
              if par_i=0 then
                raise new InvalidOperationException;
              var b_info := ett_bind_info_by_ind[par_i];
              
              var data_size_t := ntv_pars[b_info.passed_size_par_ind].CalculatedDirectType;
              if not b_info.IsInputData then
                if data_size_t <> ntv_pars[b_info.returned_size_par_ind.Value].CalculatedDirectType then
                  raise new InvalidOperationException;
              if data_size_t <> KnownDirectTypes.UIntPtr then
                raise new NotImplementedException;
              
              res += FuncParamMarshalStep.FromEnumToTypeInfo(b_info, data_size_t, par);
            end else
              res += FuncParamMarshalStep.FromParam(par_i=0, par);
            
          end;
          
          {$ifdef DEBUG}
          var res_ovr := new FuncOverload(res.SelectMany(s->s.EnmrPars).ToArray);
          res_ovr.enum_to_type_enum_name := ovr.enum_to_type_enum_name;
          if ovr <> res_ovr then
            raise new InvalidOperationException;
//          if ovr.Size<>res_ovr.Size then
//            raise new InvalidOperationException($'{ovr.pars.Length} <> {res_ovr.pars.Length}');
//          if not ovr.pars.SequenceEqual(res_ovr.pars) then
//            raise new InvalidOperationException(
//              ovr.pars.Zip(res_ovr.pars, (p1,p2)->p1=p2).JoinToString
//            );
          {$endif DEBUG}
          
          all_par_marshalers_per_ovr += res.ToArray;
        end;
        
      end;
//      begin
//        log.Otp(display_name);
//        var m_inds := new Dictionary<FuncParamMarshalStep, integer>;
//        var otp_par_m: (FuncParamMarshalStep,integer)->();
//        otp_par_m := (par_m,tab)->
//        begin
//          var m_ind: integer;
//          if not m_inds.TryGetValue(par_m, m_ind) then
//          begin
//            m_ind := m_inds.Count+1;
//            m_inds.Add(par_m, m_ind);
//          end;
//          log.Otp( #9*tab + $'({m_ind}) ' + par_m.ToString );
//          log.Otp('~'*30);
//          tab += 1;
//          foreach var k in par_m.NextStepKeys do
//          begin
//            log.Otp(#9*tab + k.ToString + ' =>');
//            otp_par_m(par_m.NextStep[k], tab);
//          end;
//        end;
//        foreach var par_m in all_par_marshalers_per_ovr.SelectMany(ovr_m->ovr_m).Distinct do
//          otp_par_m(par_m, 0);
//        log.Otp('='*50);
//  //      Halt;
//      end;
      
      {$endregion MakeParMarshlers}
      
      {$region MakeMethodList}
      var all_methods := new List<MethodImplData>;
      begin
        var method_by_ovr := new Dictionary<FuncOverload, MethodImplData>;
        
        var all_public_methods := new List<MethodImplData>;
        {$region Make public}
        
        foreach var (ovr,ovr_m) in all_overloads.ZipTuple(all_par_marshalers_per_ovr) do
        begin
          var ovr_name := display_name;
          var ett_enum_name := default(string);
          if ovr.enum_to_type_enum_name<>nil then
          begin
            ovr_name += '_'+ovr.enum_to_type_enum_name;
            ett_enum_name := $'{ovr.enum_to_type_gr.MakeWriteableName}.{ovr.enum_to_type_enum_name}';
          end;
          var md := new MethodImplData(ovr_name, ett_enum_name, ovr_m);
          var md_ovr := md.MakeOverload;
          all_public_methods += md;
          
          if md_ovr.Size <> ovr.Size then
            raise new InvalidOperationException;
          {$ifdef DEBUG}
          if md_ovr <> ovr then
            raise new InvalidOperationException(md_ovr.ItemsSeq.Zip(ovr.ItemsSeq, (p1,p2)->p1=p2).JoinToString);
          {$endif DEBUG}
          
          if not md.HasEnumToTypeEnumName then
          begin
            {$ifdef DEBUG}
            var old_md: MethodImplData;
            if method_by_ovr.TryGetValue(md_ovr, old_md) then
              raise new InvalidOperationException;
            {$endif DEBUG}
            method_by_ovr.Add(md_ovr, md);
          end;
          
        end;
        
        {$endregion Make public}
        
        //TODO Куча дублей логики в этой части...
        // - Если ещё раз пробовать - надо, наверное, сначала вычислить графы всех возможных зависимостей
        var all_ntv_methods := new List<MethodImplData>;
        {$region Make temp and ntv, add public and temp}
        
        foreach var public_md in all_public_methods do
        begin
          var method_insert_ind := all_methods.Count;
          all_methods += public_md;
          
          if display_name='7EnumToType' then
            display_name := display_name;
          
          var pending_methods := new Stack<ValueTuple<MethodImplData, array of MarshalCallKind>>;
          begin
            var ovr_steps := public_md.MakeOvrSteps;
            // If md should be kept native
            if ovr_steps.Length=0 then
            begin
              {$ifdef DEBUG}
              if public_md.HasEnumToTypeEnumName then
                raise new InvalidOperationException;
              {$endif DEBUG}
              // Dupe md, to separate public and native methods
              var (ff_step, ntv_md, no_marshal_choise) := public_md.NativeDup;
              begin
                {$ifdef DEBUG}
                if public_md.MakeOverload not in method_by_ovr then
                begin
                  foreach var ovr in method_by_ovr.Keys do
                    Otp($'({ovr})');
                  raise new InvalidOperationException($'Public func ovr was not in method_by_ovr: ({public_md.MakeOverload})');
                end;
                {$endif DEBUG}
                var old_md := method_by_ovr[public_md.MakeOverload];
                if old_md=public_md then
                begin
                  method_by_ovr[public_md.MakeOverload] := ntv_md;
                  all_ntv_methods += ntv_md;
                end else
                  ntv_md := old_md;
              end;
              public_md.AddCallTo(ff_step, ntv_md, no_marshal_choise);
              continue;
            end;
//            if ovr_steps.Any(ovr_step->ovr_step.original_step_kinds=nil) then
//              raise new InvalidOperationException;
            pending_methods += ValueTuple.Create(public_md, ovr_steps);
          end;
          
          while pending_methods.Count<>0 do
          begin
            var (old_md, ovr_call_kinds) := pending_methods.Pop;
            if ovr_call_kinds.Length=0 then
              // ntv md should not have been added here
              raise new InvalidOperationException;
            
            var can_flat_forward := ovr_call_kinds[0].CanFlatForwardFlags;
            {$ifdef DEBUG}
            foreach var ovr_call_kind in ovr_call_kinds.Skip(1) do
            begin
              var n_can_flat_forward := ovr_call_kind.CanFlatForwardFlags;
              if not can_flat_forward.SequenceEqual(n_can_flat_forward) then
                raise new InvalidOperationException;
            end;
            {$endif DEBUG}
            
            var found_existing_ovr := false;
            var step_marshal_choices := new MultiBooleanChoiceSet(can_flat_forward);
            // From most pars managed, to most pars marshaled
            foreach var step_marshal_choice in step_marshal_choices.Enmr(1,0) do
            begin
              var ovr_partial_call_kinds := ovr_call_kinds.Select(ovr_call_kind->
                new MarshalCallKind(
                  ovr_call_kind.original_step_kinds.ConvertAll((step_kind, step_i)->
                  begin
                    var flag := step_marshal_choice.Flag[step_i];
                    {$ifdef DEBUG}
                    if flag and step_kind.IsSingleFlatForward then
                      raise new InvalidOperationException;
                    {$endif DEBUG}
                    Result :=
                      if not flag then
                        MarshalStepKindCombo.FlatForward else
                        ovr_call_kind.original_step_kinds[step_i];
                  end)
                )
              ).Distinct.ToArray;
              var new_mds := ovr_partial_call_kinds.ConvertAll(ovr_partial_step->new MethodImplData(display_name, old_md, ovr_partial_step));
              
              var existing_mds := new MethodImplData[new_mds.Count];
              var any_need_create := false;
              for var ovr_i := 0 to new_mds.Count-1 do
              begin
                var new_md := new_mds[ovr_i];
                if method_by_ovr.TryGetValue(new_md.MakeOverload, existing_mds[ovr_i]) then
                  continue;
                if new_md.IsFinalStep then
                  continue;
                any_need_create := true;
                break;
              end;
              if any_need_create then continue;
              
              found_existing_ovr := true;
              for var ovr_i := 0 to new_mds.Count-1 do
              begin
                var new_md := new_mds[ovr_i];
                var found_md := existing_mds[ovr_i];
                var ovr_partial_call_kind := ovr_partial_call_kinds[ovr_i];
                
                if found_md=nil then
                begin
                  method_by_ovr.Add(new_md.MakeOverload, new_md);
                  if not new_md.IsFinalStep then
                    raise new InvalidOperationException;
                  all_ntv_methods += new_md;
                end else
                begin
                  if found_md.IsFinalStep or not new_md.IsFinalStep then
                    new_md := found_md else
                  if new_md.IsFinalStep then
                  begin
                    if not found_md.IsPublic then
                      if not all_methods.Remove(found_md) then
                        raise new InvalidOperationException;
                    if not method_by_ovr.Remove(found_md.MakeOverload) then
                      raise new InvalidOperationException;
                    found_md.ReplaceCallsWith(new_md);
                    method_by_ovr.Add(new_md.MakeOverload, new_md);
                    all_ntv_methods += new_md;
                  end;
                end;
                
                old_md.AddCallTo(ovr_partial_call_kind, new_md, step_marshal_choice);
              end;
              
              break;
            end;
            
            if found_existing_ovr then continue;
            // Create new full ovrs
            
            foreach var ovr_call_kind in ovr_call_kinds do
            begin
              var new_md := new MethodImplData(display_name, old_md, ovr_call_kind);
              
              begin
                var found_md: MethodImplData;
                if method_by_ovr.TryGetValue(new_md.MakeOverload, found_md) then
                  new_md := found_md else
                begin
                  method_by_ovr.Add(new_md.MakeOverload, new_md);
                  if new_md.IsFinalStep then
                    all_ntv_methods += new_md else
                    all_methods.Insert(method_insert_ind, new_md);
                  if not new_md.IsFinalStep then
                  begin
                    var next_ovr_steps := new_md.MakeOvrSteps;
                    {$ifdef DEBUG}
                    if next_ovr_steps.Length>1 then
                      // Only public methods are expected to have branching
                      // Tho technically I don't see any problem handling this
                      raise new NotImplementedException;
                    {$endif DEBUG}
                    pending_methods += ValueTuple.Create(new_md, next_ovr_steps);
                  end;
                end;
              end;
              
              old_md.AddCallTo(ovr_call_kind, new_md, step_marshal_choices.Enmr.Last);
            end;
            
          end;
          
        end;
        
        {$endregion Make temp and ntv, add public and temp}
        
//        if display_name='GetICDLoaderInfoOCLICD' then
//          display_name := display_name;
        
        all_methods.InsertRange(0, all_ntv_methods);
      end;
      {$endregion MakeMethodList}
      
      {$region Code generation}
      
      begin
        var all_method_names := new HashSet<string>;
        foreach var md in all_methods do
          md.FinalName(all_method_names);
      end;
      
//      begin
//        foreach var md in all_methods do
//          log.Otp(md.ToString);
//        log.Otp('='*50);
////        Halt
//      end;
      
      foreach var md in all_methods do
      begin
        var ovr := md.MakeOverload;
        
        var par_names := ntv_pars.ConvertAll(par->
        begin
          Result := par.Name;
          if Result in pas_keywords then
            Result := '&'+Result;
        end);
        md.FixETTCountParNames(par_names);
        
        if md.IsFinalCall then
        {$region Native}
        begin
          
          if is_dynamic then
          begin
            
            wr += '    private ';
            wr += md.FinalName(nil);
            wr += ' := GetProcOrNil&<';
            WriteOvrT(wr, ovr.ItemsSeq,par_names,nil, nil);
            wr += '>(';
            wr += display_name;
            wr += '_adr);'+#10;
            
          end else
          begin
            
            wr += '    private ';
            WriteOvrT(wr, ovr.ItemsSeq,par_names,nil, md.FinalName(nil));
            wr += ';'#10;
            wr += '      external ''';
            wr += Func.last_lib_name;
            wr += ''' name ''';
            wr += entry_point_name;
            wr += ''';'#10;
            
          end;
          
        end
        {$endregion Native} else
        {$region Managed}
        begin
          var generic_names := ovr.ItemsSeq
            .Where(par->par<>nil)
            .Where(par->par.IsGeneric)
            .Select(par->par.tname)
            .Distinct.ToArray;
          
          var mw := new ManagedMethodWriter(md, ovr, generic_names);
          
          var validate_size_par_names := new List<string>;
          mw.InitWriters(
            par_i->par_names[par_i],
            
            {$region Res}
            (par_kind, par, par_name)->
            begin
              
              case par_kind of
                
                MPK_Invalid:
                {$region ProcRes}
                begin
                  if not is_proc then
                    raise new InvalidOperationException;
                  if par<>nil then
                    raise new InvalidOperationException;
                  
                  Result := new FuncParWriter(FPWO_FlatResult,
                    wr->wr.WriteResAssign(
                      wr->wr.MakeCall(MSK_FlatForward, |nil as FuncParamT|)
                    )
                  );
                  
                end;
                {$endregion ProcRes}
                
                MPK_Basic:
                {$region Basic}
                begin
                  Result := new FuncParWriter(FPWO_FlatResult,
                    wr->wr.WriteResAssign(
                      wr->wr.MakeCall(MSK_FlatForward, |par|)
                    )
                  );
                end
                {$endregion Basic};
                
                MPK_String:
                {$region String}
                if par.is_const then
                begin
                  
                  Result := new FuncParWriter(FPWO_ResultConvert,
                    wr->wr.WriteResAssign(wr->
                    begin
                      wr += 'Marshal.PtrToStringAnsi(';
                      wr.MakeCall(MSK_StringResult, |new FuncParamT(par.is_const, false, 0, KnownDirectTypes.IntPtr)|);
                      wr += ')';
                    end)
                  );
                  
                end else
                begin
                  mw.MarkRequireBlock;
                  
                  Result := new FuncParWriter(FPWO_Multiline,
                    wr->
                    begin
                      var res_str_ptr_name := 'Result_str_ptr';
                      
                      wr.WriteTabs;
                      wr += 'var ';
                      wr += res_str_ptr_name;
                      wr += ' := ';
                      wr.MakeCall(MSK_StringResult, |new FuncParamT(par.is_const, false, 0, KnownDirectTypes.IntPtr)|);
                      wr += ';'#10;
                      
                      wr.MakeBlock('try', wr->
                      begin
                        
                        wr.WriteResAssign(wr->
                        begin
                          wr += 'Marshal.PtrToStringAnsi(';
                          wr += res_str_ptr_name;
                          wr += ')';
                        end);
                        
                        wr.WriteTabs(-1);
                        wr += 'finally'#10;
                        
                        wr.WriteTabs;
                        wr += 'Marshal.FreeHGlobal(';
                        wr += res_str_ptr_name;
                        wr += ');'#10;
                        
                      end);
                      
                    end
                  );
                  
                end;
                {$endregion String}
                
                else raise new NotImplementedException($'{md.FinalName(nil)} result: {par_kind}');
              end;
              
            end
            {$endregion Res},
            
            {$region Par}
            (par_kind, par, par_name)->
            begin
              
              case par_kind of
                
                MPK_Basic:
                {$region Basic}
                begin
                  Result := new FuncParWriter(FPWO_InPlace,
                    wr->wr.MakeCall(MSK_FlatForward, |par|, par_name)
                  );
                end
                {$endregion Basic};
                
                MPK_Generic:
                {$region Generic}
                begin
                  Result := new FuncParWriter(FPWO_InPlace,
                    wr->wr.MakeCall(MSK_GenericSubstitute, |new FuncParamT(par.is_const, true, 0, KnownDirectTypes.StubForGenericT)|, wr->
                    begin
                      wr += 'P';
                      wr += KnownDirectTypes.StubForGenericT.MakeWriteableName;
                      wr += '(pointer(@';
                      wr += par_name;
                      wr += '))^';
                    end)
                  );
                end;
                {$endregion Generic}
                
                MPK_Array:
                {$region Array}
                begin
                  mw.AddPointerType(par.tname);
                  
                  Result := new FuncParWriter(FPWO_ArrNil,
                    wr->
                    begin
                      
                      wr += 'if (';
                      wr += par_name;
                      wr += '<>nil) and (';
                      wr += par_name;
                      wr += '.Length<>0) then'#10;
                      
                      wr.MakeBlock(nil, wr->
                      begin
                        var call_par := par.WithPtr(true, 0);
                        
                        wr.WriteTabs;
                        wr.MakeCall(MSK_ArrayFirstItem, |call_par|, wr->
                        begin
                          wr += par_name;
                          wr += '[0]';
                        end);
                        wr += ' else'#10;
                        
                        wr.WriteTabs;
                        wr.MakeCall(MSK_ArrayFirstItem, |call_par|, wr->
                        begin
                          wr += 'P';
                          wr += par.tname.First.ToUpper;
                          wr += par.tname.Substring(1);
                          wr += '(nil)^';
                        end);
                        
                      end);
                      
                    end
                  );
                  
                end;
                {$endregion Array}
                
                MPK_String:
                {$region String}
                begin
                  if not par.is_const then
                    // Cannot determine string size
                    raise new NotImplementedException(self.ToString);
                  
                  mw.MarkRequireBlock;
                  
                  Result := new FuncParWriter(FPWO_Multiline,
                    wr->
                    begin
                      var str_ptr_name := $'{par_name}_str_ptr';
                      
                      wr.WriteTabs;
                      wr += 'var ';
                      wr += str_ptr_name;
                      wr += ' := Marshal.StringToHGlobalAnsi(';
                      wr += par_name;
                      wr += ');'#10;
                      
                      wr.MakeBlock('try', wr->
                      begin
                        
                        wr.MakeCall(MSK_StringParam, |new FuncParamT(par.is_const, false, 0, KnownDirectTypes.IntPtr)|, str_ptr_name);
                        
                        wr.WriteTabs(-1);
                        wr += 'finally'#10;
                        
                        wr.WriteTabs;
                        wr += 'Marshal.FreeHGlobal(';
                        wr += str_ptr_name;
                        wr += ');'#10;
                        
                      end);
                      
                    end
                  );
                  
                end;
                {$endregion String}
                
                MPK_ArrayNeedCopy:
                {$region ArrayNeedCopy}
                begin
                  mw.MarkRequireBlock;
                  if not par.is_const then
                    // How to calculate size?
                    raise new NotImplementedException(self.ToString);
                  
                  Result := new FuncParWriter(FPWO_Multiline,
                    wr->
                    begin
                      
                      {$region If empty}
                      
                      wr.WriteTabs;
                      wr += 'if (';
                      wr += par_name;
                      wr += '=nil) or (';
                      wr += par_name;
                      wr += '.Length=0) then'#10;
                      wr.MakeBlock('begin', wr->
                      begin
                        
                        wr.MakeCall(MSK_ArrayFallThrought, |new FuncParamT(par.is_const, false, 0, KnownDirectTypes.Pointer)|, 'nil');
                        // Change back if array overload would be accidentally called
//                        wr.MakeCall(MSK_ArrayFallThrought, |new FuncParamT(par.is_const, false, 0, KnownDirectTypes.Pointer)|, 'pointer(nil)');
                        
                        wr.WriteTabs;
                        wr += 'exit;'#10;
                        
                      end);
                      
                      {$endregion If empty}
                      
                      var temp_arr_name := par_name+'_temp_arr';
                      var temp_arr_lvl := par.arr_lvl-1 + Ord(par.IsString);
                      
                      wr.WriteTabs;
                      wr += 'var ';
                      wr += temp_arr_name;
                      wr += ': ';
                      loop temp_arr_lvl do
                        wr += 'array of ';
                      wr += 'IntPtr;'#10;
                      
                      wr.MakeBlock('try', wr->
                      begin
                        
                        {$region Do marshaling}
                        
                        wr.MakeBlock('begin', wr->
                        begin
                          var lvl_item_at := procedure(item_name: string; lvl: integer) ->
                          begin
                            wr += par_name;
                            wr += '_';
                            wr += item_name;
                            wr += '_';
                            wr += lvl;
                          end;
                          var org_el_at := procedure(lvl: integer) ->
                            lvl_item_at('org_el', lvl);
                          var tmp_el_at := procedure(lvl: integer) ->
                            lvl_item_at('tmp_el', lvl);
                          var len_at := procedure(lvl: integer)->
                            lvl_item_at('len', lvl);
                          var ind_at := procedure(lvl: integer)->
                            lvl_item_at('ind', lvl);
                          var prev_tmp_el_at := procedure(lvl: integer)->
                            if lvl=1 then
                              wr += temp_arr_name else
                            begin
                              tmp_el_at(lvl-1);
                              wr += '[';
                              ind_at(lvl-1);
                              wr += ']';
                            end;
                          
                          if not par.IsString then
                          begin
                            
                            wr.WriteTabs;
                            wr += 'var ';
                            wr += par_name;
                            wr += '_el_sz := Marshal.SizeOf&<';
                            wr += par.tname;
                            wr += '>;'#10;
                            
                          end;
                          
                          wr.WriteTabs;
                          wr += 'var ';
                          org_el_at(1);
                          wr += ' := ';
                          wr += par_name;
                          wr += ';'#10;
                          
                          for var lvl := 1 to temp_arr_lvl do
                          begin
                            
                            wr.WriteTabs;
                            wr += 'var ';
                            len_at(lvl);
                            wr += ' := ';
                            org_el_at(lvl);
                            wr += '.Length;'#10;
                            
                            wr.WriteTabs;
                            wr += 'SetLength(';
                            prev_tmp_el_at(lvl);
                            wr += ', ';
                            len_at(lvl);
                            wr += ');'#10;
                            
                            wr.WriteTabs;
                            wr += 'var ';
                            tmp_el_at(lvl);
                            wr += ' := ';
                            prev_tmp_el_at(lvl);
                            wr += ';'#10;
                            
                            wr.WriteTabs;
                            wr += 'for var ';
                            ind_at(lvl);
                            wr += ' := 0 to ';
                            len_at(lvl);
                            wr += '-1 do'#10;
                            
                            wr.BeginBlock('begin');
                            
                            wr.WriteTabs;
                            wr += 'var ';
                            org_el_at(lvl+1);
                            wr += ' := ';
                            org_el_at(lvl);
                            wr += '[';
                            ind_at(lvl);
                            wr += '];'#10;
                            
                            wr.WriteTabs;
                            wr += 'if (';
                            org_el_at(lvl+1);
                            wr += '=nil) or (';
                            org_el_at(lvl+1);
                            wr += '.Length=0) then continue;'#10;
                            
                          end;
                          
                          if par.IsString then
                          begin
                            
                            wr.WriteTabs;
                            prev_tmp_el_at(temp_arr_lvl+1);
                            wr += ' := Marshal.StringToHGlobalAnsi(';
                            org_el_at(temp_arr_lvl+1);
                            wr += ');'#10;
                            
                          end else
                          begin
                            
                            wr.WriteTabs;
                            wr += 'var ';
                            len_at(temp_arr_lvl+1);
                            wr += ' := ';
                            org_el_at(temp_arr_lvl+1);
                            wr += '.Length;'#10;
                            
                            wr.WriteTabs;
                            wr += 'var ';
                            tmp_el_at(temp_arr_lvl+1);
                            wr += '_ptr := Marshal.AllocHGlobal(';
                            len_at(temp_arr_lvl+1);
                            wr += ' * ';
                            wr += par_name;
                            wr += '_el_sz);'#10;
                            
                            wr.WriteTabs;
                            tmp_el_at(temp_arr_lvl);
                            wr += '[';
                            ind_at(temp_arr_lvl);
                            wr += '] := ';
                            tmp_el_at(temp_arr_lvl+1);
                            wr += '_ptr;'#10;
                            
                            wr.WriteTabs;
                            wr += 'for var ';
                            ind_at(temp_arr_lvl+1);
                            wr += ' := 0 to ';
                            len_at(temp_arr_lvl+1);
                            wr += '-1 do'#10;
                            
                            wr.BeginBlock('begin');
                            
                            wr.WriteTabs;
                            wr += 'var ';
                            tmp_el_at(temp_arr_lvl+1);
                            wr += '_ptr_typed: ^';
                            wr += par.tname;
                            wr += ' := ';
                            tmp_el_at(temp_arr_lvl+1);
                            wr += '_ptr.ToPointer;'#10;
                            
                            wr.WriteTabs;
                            tmp_el_at(temp_arr_lvl+1);
                            wr += '_ptr_typed^ := ';
                            org_el_at(temp_arr_lvl+1);
                            wr += '[';
                            ind_at(temp_arr_lvl+1);
                            wr += '];'#10;
                            
                            wr.WriteTabs;
                            tmp_el_at(temp_arr_lvl+1);
                            wr += '_ptr := ';
                            tmp_el_at(temp_arr_lvl+1);
                            wr += '_ptr + ';
                            wr += par_name;
                            wr += '_el_sz;'#10;
                            
                            wr.EndBlock(true);
                            
                          end;
                          
                          loop temp_arr_lvl do
                            wr.EndBlock(true);
                          
                        end);
                        
                        {$endregion Do marshaling}
                        
                        if temp_arr_lvl=1 then
                          wr.MakeCall(MSK_ArrayFirstItem, |new FuncParamT(par.is_const, true, 0, KnownDirectTypes.IntPtr)|, wr->
                          begin
                            wr += temp_arr_name;
                            wr += '[0]';
                          end) else
                          wr.MakeCall(MSK_ArrayCopy, |new FuncParamT(par.is_const, false, temp_arr_lvl, KnownDirectTypes.IntPtr)|, temp_arr_name);
                        
                        wr.WriteTabs(-1);
                        wr += 'finally'#10;
                        
                        {$region Cleanup}
                        
                        for var lvl := 1 to temp_arr_lvl do
                        begin
                          var el_name := 'arr_el'+lvl;
                          wr.WriteTabs(lvl-1);
                          wr += ' foreach var ';
                          wr += el_name;
                          wr += ' in ';
                          wr += temp_arr_name;
                          wr += ' do ';
                          if lvl<>temp_arr_lvl then
                          begin
                            wr += 'if ';
                            wr += el_name;
                            wr += '<>nil then'#10;
                          end else
                          begin
                            wr += 'Marshal.FreeHGlobal(';
                            wr += el_name;
                            wr += ');'#10;
                          end;
                          temp_arr_name := el_name;
                        end;
                        
                        {$endregion Cleanup}
                        
                      end);
                      
                    end
                  );
                  
                end;
                {$endregion ArrayNeedCopy}
                
                MPK_EnumToTypeGroupHole:
                {$region EnumToTypeGroupHole}
                begin
                  if par<>nil then
                    raise new InvalidOperationException;
                  
                  Result := new FuncParWriter(FPWO_InPlace,
                    wr->wr.MakeCall(MSK_EnumToTypeGroup, |new FuncParamT(false, false, 0, self.enum_to_type_gr)|, md.EnumToTypeEnumName)
                  );
                  
                end;
                {$endregion EnumToTypeGroupHole}
                
                else raise new NotImplementedException($'{md.FinalName(nil)} parameter: {par_kind}');
              end;
              
            end
            {$endregion Par},
            
            {$region EnumToType}
            pars->
            begin
              
              {$region Find data and count params}
              
              var count_par := default(FuncParamT);
              var count_par_name := default(string);
              
              var data_par := default(FuncParamT);
              var data_par_name := default(string);
              
              foreach var (par_kind, par, par_name) in pars do
                case par_kind of
                  
                  MPK_Invalid:
                    if par<>nil then
                      raise new InvalidOperationException;
                  
                  MPK_EnumToTypeCount:
                  begin
                    if count_par<>nil then raise new InvalidOperationException;
                    count_par := par;
                    count_par_name := par_name;
                  end;
                  
                  MPK_EnumToTypeBody:
                  begin
                    if data_par<>nil then raise new InvalidOperationException;
                    data_par := par;
                    data_par_name := par_name;
                  end;
                  
                  else raise new NotImplementedException($'{md.FinalName(nil)} ett: {par_kind}');
                end;
              
              {$endregion Find data and count params}
              
              {$region No input ovr}
              
              if data_par=nil then
              begin
                if pars.Length<>2 then
                  raise new NotImplementedException;
                Result := new FuncParWriter(FPWO_InPlace,
                  wr->wr.MakeCall(
                    MSK_EnumToTypeBody,
                    |
                      new FuncParamT(false, false, 0, KnownDirectTypes.UIntPtr),
                      new FuncParamT(true, false, 0, KnownDirectTypes.Pointer)
                    |,
                    'UIntPtr.Zero,nil'
                  )
                );
                exit;
              end;
              
              {$endregion No input ovr}
              
              var is_output_data := not data_par.is_const;
              if is_output_data and (data_par.arr_lvl>1) then
                raise new NotImplementedException('Cannot determine size of ett output nested array');
              
              var validate_size_par_name := default(string);
              var returned_sz_name := default(string);
              if is_output_data and (data_par.enum_to_type_data_rep_c<>nil) then
              begin
                validate_size_par_name := data_par_name+'_validate_size';
                validate_size_par_names += validate_size_par_name;
                returned_sz_name := data_par_name+'_ret_size';
              end;
              
              mw.MarkRequireBlock;
              Result := new FuncParWriter(FPWO_Multiline,
                wr->
                begin
                  var expected_sz_name := data_par_name+'_sz';
                  
                  var temp_res_name := default(string);
                  if is_output_data and (count_par=nil) and (data_par.enum_to_type_data_rep_c<>1) then
                    temp_res_name := data_par_name+'_temp_res';
                  
                  if is_output_data and (count_par=nil) and (data_par.enum_to_type_data_rep_c=nil) then
                  begin
                    wr.WriteTabs;
                    wr += 'var ';
                    wr += expected_sz_name;
                    wr += ': UIntPtr;'#10;
                    
                    wr.MakeCall(MSK_EnumToTypeGetSize,
                      |
                        new FuncParamT(false, false, 0, KnownDirectTypes.UIntPtr),
                        new FuncParamT(data_par.is_const, false, 0, KnownDirectTypes.Pointer),
                        new FuncParamT(false, true, 0, KnownDirectTypes.UIntPtr)
                      |,
                      wr->
                      begin
                        wr += 'UIntPtr.Zero,nil,';
                        wr += expected_sz_name;
                      end
                    );
                    
                    if not is_proc then
                    begin
                      var res_type := possible_par_types[0].Single;
                      if not res_type.tname.EndsWith('ErrorCode') then
                        raise new NotImplementedException(res_type.ToString(true));
                      
                      wr.WriteTabs;
                      wr += 'if Result.IS_ERROR then exit;'#10;
                      
                    end;
                    
                    if data_par.enum_to_type_data_rep_c=nil then
                    begin
                      wr.WriteTabs;
                      wr += 'if ';
                      wr += expected_sz_name;
                      wr += ' = UIntPtr.Zero then'#10;
                      wr.MakeBlock('begin', wr->
                      begin
                        wr.WriteTabs;
                        wr += data_par_name;
                        wr += ' := nil;'#10;
                        wr.WriteTabs;
                        wr += 'exit;'#10;
                      end);
                    end;
                    
                    wr.WriteTabs;
                    wr += 'var ';
                    wr += temp_res_name;
                    wr += ' := ';
                    if data_par.IsString then
                    begin
                      wr += 'Marshal.AllocHGlobal(IntPtr(';
                      wr += expected_sz_name;
                      wr += '.ToPointer));'#10;
                      wr.BeginBlock('try');
                    end else
                    begin
                      wr += 'new ';
                      wr += data_par.tname;
                      wr += '[';
                      wr += expected_sz_name;
                      wr += '.ToUInt64 div ';
                      wr += 'Marshal.SizeOf&<';
                      wr += data_par.tname;
                      wr += '>';
                      wr += '];'#10;
                    end;
                    
                  end else
                  begin
                    
                    wr.WriteTabs;
                    wr += 'var ';
                    wr += expected_sz_name;
                    wr += ' := new UIntPtr(';
                    if count_par<>nil then
                    begin
                      wr += count_par_name;
                      wr += '*';
                    end else
                    if data_par.enum_to_type_data_rep_c=nil then
                    begin
                      if is_output_data then
                        raise new InvalidOperationException;
                      wr += data_par_name;
                      wr += '.Length';
                      wr += '*';
                    end else
                    if data_par.enum_to_type_data_rep_c<>1 then
                    begin
                      wr += data_par.enum_to_type_data_rep_c.Value;
                      wr += '*';
                    end;
                    wr += 'Marshal.SizeOf&<';
                    wr += data_par.tname;
                    wr += '>';
                    wr += ');'#10;
                    
                    if temp_res_name<>nil then
                    begin
                      wr.WriteTabs;
                      wr += 'var ';
                      wr += temp_res_name;
                      wr += ' := ';
                      if data_par.IsString then
                      begin
                        wr += 'Marshal.AllocHGlobal(IntPtr(';
                        wr += expected_sz_name;
                        wr += '.ToPointer));'#10;
                        wr.BeginBlock('try');
                      end else
                      begin
                        wr += 'new ';
                        wr += data_par.tname;
                        wr += '[';
                        wr += data_par.enum_to_type_data_rep_c.Value;
                        wr += '];'#10;
                      end;
                    end;
                    
                  end;
                  
                  if returned_sz_name<>nil then
                  begin
                    wr.WriteTabs;
                    wr += 'var ';
                    wr += returned_sz_name;
                    wr += ': UIntPtr;'#10;
                  end;
                  
                  var body_call_pars := new List<FuncParamT>(pars.Length);
                  body_call_pars += new FuncParamT(false, false, 0, KnownDirectTypes.UIntPtr);
                  body_call_pars += if data_par.IsString then
                    new FuncParamT(data_par.is_const, false, 0, KnownDirectTypes.Pointer) else
                    new FuncParamT(data_par.is_const, true, 0, TypeLookup.FromName(if is_output_data then 'T' else 'TInp'));
                  if is_output_data then
                    body_call_pars += if validate_size_par_name<>nil then
                      new FuncParamT(false, true, 0, KnownDirectTypes.UIntPtr) else
                      new FuncParamT(false, false, 0, KnownDirectTypes.IntPtr);
                  if body_call_pars.Count<>pars.Length then
                    raise new InvalidOperationException($'{body_call_pars.Count}<>{pars.Length}');
                  
                  wr.MakeCall(MSK_EnumToTypeBody, body_call_pars.ToArray,
                    wr->
                    begin
                      
                      wr += expected_sz_name;
                      
                      wr += ',';
                      if temp_res_name=nil then
                      begin
                        wr += data_par_name;
                        if (count_par=nil) and (data_par.enum_to_type_data_rep_c<>1) then
                          wr += '[0]';
                      end else
                      begin
                        wr += temp_res_name;
                        if data_par.IsString then
                          wr += '.ToPointer' else
                          wr += '[0]';
                      end;
                      
                      if is_output_data then
                        if validate_size_par_name<>nil then
                        begin
                          wr += ',';
                          wr += returned_sz_name;
                        end else
                          wr += ',IntPtr.Zero';
                      
                    end
                  );
                  
                  if temp_res_name<>nil then
                    if data_par.IsString then
                    begin
                      
                      wr.WriteTabs;
                      wr += data_par_name;
                      wr += ' := Marshal.PtrToStringAnsi(';
                      wr += temp_res_name;
                      wr += ');'#10;
                      
                      wr.WriteTabs(-1);
                      wr += 'finally'#10;
                      
                      wr.WriteTabs;
                      wr += 'Marshal.FreeHGlobal(';
                      wr += temp_res_name;
                      wr += ');'#10;
                      
                      wr.EndBlock(true);
                    end else
                    begin
                      wr.WriteTabs;
                      wr += data_par_name;
                      wr += ' := ';
                      wr += temp_res_name;
                      wr += ';'#10;
                    end;
                  
                  if validate_size_par_name<>nil then
                  begin
                    
                    wr.WriteTabs;
                    wr += 'if ';
                    wr += validate_size_par_name;
                    wr += ' and (';
                    wr += returned_sz_name;
                    wr += '<>';
                    wr += expected_sz_name;
                    wr += ') then'#10;
                    
                    wr.WriteTabs(+1);
                    wr += 'raise new InvalidOperationException($''Implementation returned a size of {';
                    wr += returned_sz_name;
                    wr += '} instead of {';
                    wr += expected_sz_name;
                    wr += '}'');'#10;
                    
                  end;
                  
                end
              );
            end
            {$endregion EnumToType}
            
          );
          
          wr += '    ';
          wr += if md.IsPublic then 'public' else 'private';
          wr += ' [MethodImpl(MethodImplOptions.AggressiveInlining)] ';
          var pars := ovr.ItemsSeq.ToArray;
          if validate_size_par_names.Any then
          begin
            var boolean_t := TypeLookup.FromName('boolean');
            boolean_t.Use(true);
            var vs_par := new FuncParamT(true, false, 0, boolean_t);
            vs_par.default_val := 'false';
            pars := pars + ArrFill(validate_size_par_names.Count, vs_par);
          end;
          //TODO #2886
          WriteOvrT(wr, pars as object as System.Collections.Generic.IReadOnlyList<FuncParamT>, par_names+validate_size_par_names.ToArray, generic_names, md.FinalName(nil));
          
          mw.Write(wr);
        end
        {$endregion Managed};
        
      end;
      
      {$endregion Code generation}
      
    end;
    
    {$endregion Write}
    
    public procedure LogContents(l: Logger); override;
    begin
      InitOverloads;
      l.Otp($'# {self.Name}');
      
      {$region PPT}
      if not is_proc or (ntv_pars.Length>1) then
      begin
        l.Otp('!ppt');
        var par_names := ntv_pars.ConvertAll((par,par_i)->(
          if par_i<>0 then
            par.Name else
          if not is_proc then
            'Result' else ''
        ));
        var max_par_name_len := par_names.Max(pn->pn.Length);
        for var par_i := 0 to ntv_pars.Length-1 do
        begin
          if is_proc and (par_i=0) then continue;
          var par_name := par_names[par_i];
          var wr := new WriterSB;
          wr += par_name;
          wr += ': ';
          loop max_par_name_len-par_name.Length do
            wr += ' ';
          wr.WriteSeparated(possible_par_types[par_i], (wr,par)->
            (wr += par.ToString(true)), ' / '
          );
          l.Otp(wr.ToString);
        end;
      end;
      {$endregion PPT}
      {$region FFO}
      if not is_proc or (ntv_pars.Length>1) then
      begin
        l.Otp('!ffo');
        l.Otp($'{all_overloads.Count}');
        var i_off := integer(is_proc);
        var need_par_names := ntv_pars.Length>1;
        
        var max_w := new integer[ntv_pars.Length-i_off];
        var tt := new string[all_overloads.Count+Ord(need_par_names), max_w.Length];
        foreach var ovr in all_overloads index ovr_i do
          for var i := i_off to ntv_pars.Length-1 do
          begin
            var tt_i := i-i_off;
            var s := default(string);
            
            if ntv_pars[i].CalculatedDirectType=ovr.enum_to_type_gr then
              s := $'{ovr.enum_to_type_gr.MakeWriteableName}.{ovr.enum_to_type_enum_name}' else
            if ovr[i]<>nil then
              s := ovr[i].ToString(true, true) else
            begin
              if ovr.enum_to_type_bindings=nil then
                raise new InvalidOperationException;
              
              foreach var b in ovr.enum_to_type_bindings do
              begin
                if i=b.passed_size_par_ind then
                  s := '*' else
                if i=b.returned_size_par_ind then
                  s := '*' else
                if i=b.data_par_ind then
                  s := nil else
                  continue;
                if ovr[b.data_par_ind]=nil then
                  s := '*';
                break;
              end;
              
              if s=nil then
                raise new InvalidOperationException;
            end;
            
            max_w[tt_i] := Max(max_w[tt_i], s.Length);
            tt[ovr_i, tt_i] := s;
          end;
        if need_par_names then
          for var i := 1 to ntv_pars.Length-1 do
          begin
            var s := if i=0 then '' else ntv_pars[i].name.TrimStart('&');
            var tt_i := i-i_off;
            max_w[tt_i] := Max(max_w[tt_i], s.Length);
            tt[all_overloads.Count, tt_i] := s;
          end;
        
        var l_cap := 1+max_w.Sum + max_w.Length*3;
        var l_sb := new StringBuilder(l_cap);
        for var ovr_i := 0 to tt.GetLength(0)-1 do
        begin
          l_sb += #9;
          
          if ovr_i=all_overloads.Count then
          begin
            
            foreach var w in max_w index tt_i do
            begin
              loop w do
                l_sb += '-';
              l_sb += ' | ';
            end;
            
            l_sb.Length -= 1;
            l.Otp(l_sb.ToString);
            l_sb.Clear;
            l_sb += #9;
          end;
          
          foreach var w in max_w index tt_i do
          begin
            var s := tt[ovr_i, tt_i];
            l_sb += s;
            loop w-s.Length do
              l_sb += ' ';
            l_sb += ' | ';
          end;
          
          {$ifdef DEBUG}
          if l_sb.Length<>l_cap then raise new System.InvalidOperationException((l_sb,l_sb.Length,l_cap,ObjectToString(max_w),ObjectToString(tt)).ToString);
          {$endif DEBUG}
          l_sb.Length -= 1;
          l.Otp(l_sb.ToString);
          l_sb.Clear;
        end;
        
      end;
      {$endregion FFO}
      
      l.Otp('');
    end;
    
  end;
  
  FuncFixerApplyOrder = (FFAO_Native, FFAO_Auto_PPT, FFAO_PPT, FFAO_Overload);
  FuncFixer = abstract class(NamedItemCommonFixer<FuncFixer, Func>)
    
    protected function ApplyOrder: FuncFixerApplyOrder; abstract;
    protected function ApplyOrderBase: integer; override := integer(self.ApplyOrder);
    
  end;
  
  {$endregion Func}
  
  {$region RequiredList}
  
  RequiredList = record
    private _enums: LazyUniqueItemList<Enum>;
    private _funcs: LazyUniqueItemList<Func>;
    
    public static function Load(br: BinReader): RequiredList;
    begin
      Result._enums := Enum.MakeLazySeq(br.ReadInt32Arr);
      Result._funcs := Func.MakeLazySeq(br.ReadInt32Arr);
    end;
    
    public function Enums := _enums.ToSeq;
    public function Funcs := _funcs.ToSeq;
    
    protected procedure MarkReferenced;
    begin
      
      foreach var e in Enums do
        e.UseFromReqList;
      
      foreach var f in Funcs do
        f.Use(false);
      
    end;
    
    public static procedure ManageVer<TItem, TVer>(ver: TVer; add_v, rem_v: Dictionary<TItem, TVer>; add, rem: sequence of TItem);
    begin
      
      foreach var item in rem do
      begin
        if item not in add_v then
          Otp($'{item} was depricated before being added');
        if item in rem_v then
          log.Otp($'{item} was depricated in versions [{rem_v[item]}] and [{ver}]') else
          rem_v[item] := ver;
      end;
      
      foreach var item in add do
      begin
        if (item in add_v) and ((rem_v=nil) or not rem_v.Remove(item)) then
          log.Otp($'{item} was added in versions [{add_v[item]}] and [{ver}]') else
          add_v[item] := ver;
      end;
      
    end;
    
  end;
  
  {$endregion RequiredList}
  
  {$region Feature}
  
  Feature = sealed class(NamedLoadedItem<Feature, FeatureName>)
    private add, rem: RequiredList;
    
    private static AllFeatures := new List<Feature>;
    
    static constructor := RegisterLoader(br->
    begin
      Result := new Feature(new FeatureName(br), false);
      Result.add := RequiredList.Load(br);
      Result.rem := RequiredList.Load(br);
      AllFeatures += Result;
    end);
    
    public property Added: RequiredList read add;
    public property Removed: RequiredList read rem;
    
    public procedure MarkBodyReferenced; override;
    begin
      add.MarkReferenced;
      rem.MarkReferenced;
    end;
    public static procedure WriteAll;
    begin
      Otp($'Dumping {ItemSmallName} items');
      var intr_wr := new FileWriter(GetFullPathRTA(ItemSmallName+'.Interface.template'));
      var impl_wr := new FileWriter(GetFullPathRTA(ItemSmallName+'.Implementation.template'));
      var all_wr := intr_wr*impl_wr;
      loop 3 do
      begin
        intr_wr += '  ';
        all_wr += #10;
      end;
      
      foreach var g in AllFeatures.OrderBy(item->item.Name).GroupBy(item->item.Name.SourceAPI) do
      begin
        var api := g.Key;
        
        // all, including removed
        var enum_add_ver := new Dictionary<Enum, string>;
        // only removed
        var enum_rem_ver := new Dictionary<Enum, string>;
        //
        var func_add_ver := new Dictionary<Func, string>;
        var func_rem_ver := new Dictionary<Func, string>;
        {$region group by ver}
        begin
          var log_versions := new FileLogger(GetFullPathRTA($'Log/{api.ToUpper} versions.log'));
          loop 3 do log_versions.Otp('');
          
          foreach var ftr: Feature in g do
          begin
            ftr.Use(false);
            var ver := $'{ftr.Name.Major}.{ftr.Name.Minor}';
            var add := ftr.Added;
            var rem := ftr.Removed;
            
            RequiredList.ManageVer(ver, enum_add_ver,enum_rem_ver, add.Enums, rem.Enums);
            RequiredList.ManageVer(ver, func_add_ver,func_rem_ver, add.Funcs, rem.Funcs);
            
            log_versions.Otp($'# {ver}');
            foreach var e in enum_add_ver.Keys do
            begin
              if e in enum_rem_ver then continue;
              log_versions.Otp(#9 + e);
            end;
            foreach var f in func_add_ver.Keys do
            begin
              if f in func_rem_ver then continue;
              log_versions.Otp(#9 + f);
            end;
            log_versions.Otp('');
            
          end;
          
          loop 1 do log_versions.Otp('');
          log_versions.Close;
        end;
        {$endregion group by ver}
        if not ApiManager.ShouldKeep(api) then continue;
        Feature.written_c += 1;
        
        var is_dynamic := ApiManager.NeedDynamicLoad(api, false);
        var lib_name := if is_dynamic then nil else ApiManager.LibForApi(api);
        var class_type := if is_dynamic then 'sealed partial' else 'static';
        
        {$region WriteAPI}
        var WriteAPI := procedure(api_funcs: sequence of Func; add_ver, depr_ver: Func->string)->
        begin
          intr_wr += '  {$ifndef DEBUG}'#10;
          intr_wr += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
          intr_wr += '  {$endif DEBUG}'#10;
          intr_wr += '  [PCUNotRestore]'#10;
          intr_wr += '  ///'#10;
          intr_wr += '  ';
          intr_wr += api;
          if depr_ver<>nil then intr_wr += 'D';
          intr_wr += ' = ';
          intr_wr += class_type;
          intr_wr += ' class'#10;
          
          if is_dynamic then
          begin
            var dyn_apis_info := ApiManager.DynamicApisInfo;
            if dyn_apis_info=nil then raise nil;
            if dyn_apis_info.par_name=nil then raise new NotImplementedException;
            if dyn_apis_info.par_type=nil then raise new NotImplementedException;
            if dyn_apis_info.base_type=nil then raise new NotImplementedException;
            if dyn_apis_info.default_inst_name<>nil then raise new NotImplementedException;
            if dyn_apis_info.allow_loaderless_default then raise new NotImplementedException;
            
            intr_wr += '    public constructor(';
            intr_wr += dyn_apis_info.par_name;
            intr_wr += ': ';
            intr_wr += dyn_apis_info.par_type;
            intr_wr += ');'#10;
            intr_wr += '    private constructor := raise new NotSupportedException;'#10;
            intr_wr += '    private function GetProcAddress(name: string): IntPtr;'#10;
            intr_wr += '    private static function GetProcOrNil<T>(fadr: IntPtr) :='#10;
            intr_wr += '      if fadr=IntPtr.Zero then default(T) else'#10;
            intr_wr += '        Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
            
            impl_wr += 'type ';
            impl_wr += api;
            if depr_ver<>nil then impl_wr += 'D';
            impl_wr += ' = ';
            impl_wr += class_type;
            impl_wr += ' class(';
            impl_wr += dyn_apis_info.base_type;
            impl_wr += ') end;'#10;
            impl_wr += 'constructor ';
            impl_wr += api;
            if depr_ver<>nil then impl_wr += 'D';
            impl_wr += '.Create(';
            impl_wr += dyn_apis_info.par_name;
            impl_wr += ': ';
            impl_wr += dyn_apis_info.par_type;
            impl_wr += ') := inherited Create(';
            impl_wr += dyn_apis_info.par_name;
            impl_wr += ');'#10;
            impl_wr += 'function ';
            impl_wr += api;
            if depr_ver<>nil then impl_wr += 'D';
            impl_wr += '.GetProcAddress(name: string) := ';
            impl_wr += dyn_apis_info.par_name;
            impl_wr += '.GetProcAddress(name);'#10;
            impl_wr += #10;
            
          end;
          
          intr_wr += '    '#10;
          
          Func.DefineWriteBlock(lib_name, ()->
            foreach var f in api_funcs.OrderBy(f->f.Name) do
              begin
                var curr_add_ver := add_ver(f);
                intr_wr += '    // added in ';
                intr_wr += api;
                intr_wr += curr_add_ver;
                if depr_ver<>nil then
                begin
                  intr_wr += ', deprecated in ';
                  intr_wr += api;
                  intr_wr += depr_ver(f);
                end;
                intr_wr += #10;
                f.Write(intr_wr);
                intr_wr += $'    '+#10;
              end
          );
          
          intr_wr += $'  end;'+#10;
          intr_wr += $'  '+#10;
        end;
        {$endregion WriteAPI}
        
        WriteAPI(func_add_ver.Keys.Where(f->f not in func_rem_ver), f->func_add_ver[f], nil);
        if not func_rem_ver.Any then continue;
        WriteAPI(func_add_ver.Keys.Where(f->f     in func_rem_ver), f->func_add_ver[f], f->func_rem_ver[f]);
        
      end;
      
      intr_wr += '  '#10'  ';
      impl_wr += #10;
      all_wr.Close;
    end;
    
  end;
  
  FeatureFixer = abstract class(NamedItemFixer<FeatureFixer, Feature, FeatureName>)
    
  end;
  
  {$endregion Feature}
  
  {$region Extension}
  
  ExtensionDepOption = record
    private core_dep_ind: integer?
    private ext_dep_inds: array of integer;
    
    public constructor(br: BinReader);
    begin
      self.core_dep_ind := br.ReadIndexOrNil;
      self.ext_dep_inds := br.ReadInt32Arr;
    end;
    
  end;
  
  FeatureOrExtensionIndex = record
    public f_ind := default(integer?);
    public e_ind := default(integer?);
    
    public constructor(br: BinReader) :=
      case br.ReadInt32 of
        0: ;
        1: f_ind := br.ReadInt32;
        2: e_ind := br.ReadInt32;
        else raise new System.InvalidOperationException;
      end;
    
  end;
  
  Extension = sealed class(NamedLoadedItem<Extension, ApiVendorLName>)
    private ext_str: string;
    private add: RequiredList;
    
    private revision: string;
    private provisional: boolean;
    
    private dep_options: array of ExtensionDepOption;
    
    private obsolete_by: FeatureOrExtensionIndex;
    private promoted_to: FeatureOrExtensionIndex;
    
    private static AllExtensions := new List<Extension>;
    
    static constructor := RegisterLoader(br->
    begin
      Result := new Extension(ApiVendorLName.Create(br).SnakeToCamelCase, false);
      
      Result.ext_str := br.ReadString;
      Result.add := RequiredList.Load(br);
      
      Result.revision := br.ReadOrNil(br->br.ReadString);
      Result.provisional := br.ReadBoolean;
      
      Result.dep_options := br.ReadArr(br->new ExtensionDepOption(br));
      
      Result.obsolete_by := new FeatureOrExtensionIndex(br);
      Result.promoted_to := new FeatureOrExtensionIndex(br);
      
      AllExtensions += Result;
    end);
    
    public property ExtensionString: string read ext_str;
    public property Added: RequiredList read add;
    
    public property RevisionStr: string read revision;
    public property IsProvisional: boolean read provisional;
    
    public property DepOptionCount: integer read dep_options.Length;
    
    public function HasCoreDependency(i: integer) := dep_options[i].core_dep_ind<>nil;
    public function CoreDependency(i: integer) := Feature.ByIndex(dep_options[i].core_dep_ind.Value);
    
    public function HasExtDependencies(i: integer) := dep_options[i].ext_dep_inds.Length<>0;
    public function ExtDependencies(i: integer) := Extension.MakeLazySeq(dep_options[i].ext_dep_inds).ToSeq;
    
    public property ObsoletedBy: FeatureOrExtensionIndex read obsolete_by;
    public property PromotedTo: FeatureOrExtensionIndex read promoted_to;
    
    public procedure MarkBodyReferenced; override;
    begin
      add.MarkReferenced;
    end;
    
    private function MakeWriteableName: string;
    begin
      Result := self.Name.api + self.Name.l_name + self.Name.vendor_suffix;
    end;
    
    private static intr_wr := new FileWriter(GetFullPathRTA(ItemSmallName+'.Interface.template'));
    private static impl_wr := new FileWriter(GetFullPathRTA(ItemSmallName+'.Implementation.template'));
    private static all_wr := intr_wr*impl_wr;
    private saved := false;
    public procedure Save;
    begin
      if saved then exit;
      saved := true;
      self.Use(false);
      var api := self.Name.api;
      
      if not ApiManager.ShouldKeep(api) then exit;
      Extension.written_c += 1;
      
      for var dep_opt_i := 0 to DepOptionCount-1 do
        foreach var dep in ExtDependencies(dep_opt_i) do
          dep.Save;
      
      var any_funcs := add.Funcs.Any;
      
      var is_dynamic := any_funcs and ApiManager.NeedDynamicLoad(api, true);
      // wgl and glx extensions load from their api.GetProcAddress
      // cl extensions load from clGetExtensionFunctionAddressForPlatform
      // In these cases need_loader=false, is_dynamic=true
      var need_api_loader := any_funcs and ApiManager.NeedDynamicLoad(api, false);
      if need_api_loader and not is_dynamic then
        raise new InvalidOperationException(api);
      var dyn_info := if need_api_loader then
        ApiManager.DynamicApisInfo else
        ApiManager.LoadableExtensionsInfo;
      
      if is_dynamic then
      begin
        if dyn_info=nil then raise nil;
        if (dyn_info.par_name=nil) <> (dyn_info.par_type=nil) then
          raise new InvalidOperationException;
      end;
      
      var lib_name := if is_dynamic or not any_funcs then nil else ApiManager.LibForApi(api);
      var class_type :=
        if not is_dynamic then
          'static' else
        if dyn_info.par_name=nil then
          'sealed' else
          'sealed partial';
      var display_name := MakeWriteableName;
      
      if any_funcs then
      begin
        intr_wr += '  {$ifndef DEBUG}'#10;
        intr_wr += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
        intr_wr += '  {$endif DEBUG}'#10;
        intr_wr += '  [PCUNotRestore]'#10;
      end;
      
      {$region description}
      begin
        var curr_tab := '';
        
        var descr_block := (body: Action)->
        begin
          var old_tab := curr_tab;
          var own_tab := if curr_tab='' then ' -' else '--'+curr_tab;
          curr_tab := own_tab;
          
          body();
          
          if curr_tab <> own_tab then
            raise new InvalidOperationException;
          curr_tab := old_tab;
        end;
        //TODO #3197
        var descr_line := procedure(body: Action<Writer>)->
        begin
          var wr := intr_wr;
          
          wr += '  ///';
          wr += curr_tab;
          wr += ' ';
          
          body(wr);
          
          wr += #10;
        end;
        
        {$region id}
        
        descr_line(wr->
        begin
          wr += 'id: ';
          wr += self.ExtensionString;
        end);
        
        {$endregion id}
        
        {$region version}
        
        if (self.RevisionStr<>nil) or (self.IsProvisional) then descr_line(wr->
        begin
          wr += 'version: ';
          if self.RevisionStr<>nil then
          begin
            wr += self.RevisionStr;
            if self.IsProvisional then
              wr += ' (provisional)';
          end else
          if self.IsProvisional then
            wr += 'provisional';
        end);
        
        {$endregion version}
        
        {$region feature/extension references}
  
        var write_feature := procedure(wr: Writer; f: Feature)->
        begin
          wr += f.Name.SourceAPI;
          wr += ' ';
          wr += f.Name.Major;
          wr += '.';
          wr += f.Name.Minor;
        end;
        var write_ext := procedure(wr: Writer; e: Extension)->
        begin
          wr += e.ExtensionString;
          wr += ' (';
          wr += e.MakeWriteableName;
          wr += ')';
        end;
        
        var write_dep_opt := procedure(opt_i: integer)->
        begin
          
          if self.HasCoreDependency(opt_i) then descr_line(wr->
          begin
            wr += 'core dependency: ';
            write_feature(wr, self.CoreDependency(opt_i));
          end);
          
          if self.HasExtDependencies(opt_i) then
          begin
            descr_line(wr->(wr += 'ext dependencies:'));
            descr_block(()->
              foreach var e in self.ExtDependencies(opt_i) do
                descr_line(wr->write_ext(wr, e))
            );
          end;
          
        end;
        
        case self.DepOptionCount of
          0: ;
          1: write_dep_opt(0);
          else
            for var opt_i := 0 to self.DepOptionCount-1 do
            begin
              descr_line(wr->(wr += $'dependency option {opt_i+1}'));
              descr_block(()->write_dep_opt(opt_i));
            end;
        end;
        
        var write_foe := procedure(foe: FeatureOrExtensionIndex; header: string)->
        begin
          
          if foe.f_ind<>nil then descr_line(wr->
          begin
            wr += header;
            wr += ': ';
            write_feature(wr, Feature.ByIndex(foe.f_ind.Value));
          end);
          
          if foe.e_ind<>nil then descr_line(wr->
          begin
            wr += header;
            wr += ': ';
            write_ext(wr, Extension.ByIndex(foe.e_ind.Value));
          end);
          
        end;
        write_foe(self.ObsoletedBy, 'obsoleted by');
        write_foe(self.PromotedTo, 'promoted to');
              
        {$endregion feature/extension references}
        
      end;
      {$endregion description}
      
      intr_wr += '  ';
      intr_wr += display_name;
      intr_wr += ' = ';
      intr_wr += class_type;
      intr_wr += ' class'#10;
      
      if is_dynamic then
      begin
        var need_default_inst := (dyn_info.par_name=nil) or dyn_info.allow_loaderless_default;
        
        if dyn_info.par_name <> nil then
        begin
          if dyn_info.base_type=nil then raise nil;
          
          intr_wr += '    public constructor(';
          intr_wr += dyn_info.par_name;
          intr_wr += ': ';
          intr_wr += dyn_info.par_type;
          intr_wr += ');'#10;
          intr_wr += '    private constructor := raise new System.NotSupportedException;'#10;
          
          impl_wr += 'type ';
          impl_wr += display_name;
          impl_wr += ' = ';
          impl_wr += class_type;
          impl_wr += ' class(';
          impl_wr += dyn_info.base_type;
          impl_wr += ') end;'#10;
          impl_wr += 'constructor ';
          impl_wr += display_name;
          impl_wr += '.Create(';
          impl_wr += dyn_info.par_name;
          impl_wr += ': ';
          impl_wr += dyn_info.par_type;
          impl_wr += ') := inherited Create(';
          impl_wr += dyn_info.par_name;
          impl_wr += ');'#10;
          impl_wr += 'function ';
          impl_wr += display_name;
          impl_wr += '.GetProcAddress(name: string) := ';
          impl_wr += dyn_info.par_name;
          impl_wr += '.GetProcAddress(name);'#10;
          impl_wr += #10;
          
        end else
        if need_default_inst then
          intr_wr += '    public constructor := exit;'#10;
        
        if need_default_inst then
        begin
          if dyn_info.default_inst_name=nil then raise nil;
          intr_wr += '    public static ';
          intr_wr += dyn_info.default_inst_name;
          intr_wr += ' := new ';
          intr_wr += display_name;
          if dyn_info.par_name <> nil then
          begin
            intr_wr += '(default(';
            intr_wr += dyn_info.par_type;
            intr_wr += '))';
          end;
          intr_wr += ';'#10;
        end;
        
        intr_wr += '    private function GetProcAddress(name: string)';
        if dyn_info.par_name <> nil then
          intr_wr += ': IntPtr' else
        begin
          intr_wr += ' := ';
          intr_wr += api;
          intr_wr += '.GetProcAddress(name)';
        end;
        intr_wr += ';'#10;
        
        intr_wr += '    private static function GetProcOrNil<T>(fadr: IntPtr) :='#10;
        intr_wr += '      fadr=IntPtr.Zero ? default(T) :'#10;
        intr_wr += '        Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
      end;
      
      intr_wr += '    public const ExtensionString = ''';
      intr_wr += self.ExtensionString;
      intr_wr += ''';'+#10;
      if any_funcs then
        intr_wr += '    '+#10;
      
      Func.DefineWriteBlock(lib_name, ()->
        foreach var f in Added.Funcs do
        begin
          f.Write(intr_wr);
          intr_wr += '    '+#10;
        end
      );
      
      intr_wr += $'  end;'+#10;
      intr_wr += $'  '+#10;
    end;
    
    public static procedure WriteAll;
    begin
      Otp($'Dumping {ItemSmallName} items');
      loop 3 do
      begin
        intr_wr += '  ';
        all_wr += #10;
      end;
      
      ForEachDefined(ext->ext.Save());
      
      intr_wr += '  '#10'  ';
      impl_wr += #10;
      all_wr.Close;
    end;
    
    public procedure LogContents(l: Logger); override;
    begin
      l.Otp($'# {MakeWriteableName} ({ExtensionString})');
      
      foreach var e in Added.Enums do
        l.Otp(#9+e);
      
      foreach var f in Added.Funcs do
        l.Otp(#9+f);
      
      l.Otp('');
    end;
    
  end;
  
  ExtensionFixer = abstract class(NamedItemCommonFixer<ExtensionFixer, Extension>)
    
  end;
  
  {$endregion Extension}
  
implementation

{$region Fixers} type
  
  {$region Func}
  
  {$region PPT}
  
  [PCUAlwaysRestore]
  FuncParamTChanges = record
    private changes_maker: ()->sequence of ValueTuple<boolean, FuncParamT>;
    
    private static function ChangesFromStr(changes_str: string): sequence of ValueTuple<boolean, FuncParamT>;
    begin
      if changes_str='' then exit;
      if changes_str='*' then exit;
      
      var is_add := default(boolean?);
      var sb := new StringBuilder(changes_str.Length);
      
      var seal_t: function: ValueTuple<boolean, FuncParamT> := ()->
      begin
        Result := ValueTuple.Create(is_add.Value, FuncParamT.Parse(sb.ToString));
        is_add := nil;
        sb.Clear;
      end;
      
      var expect_new_t := true;
      foreach var ch in changes_str do
        if expect_new_t and (ch in '+-') then
        begin
          expect_new_t := false;
          if is_add<>nil then
            yield seal_t();
          is_add := ch='+';
        end else
        begin
          if is_add=nil then
            raise new FormatException(changes_str);
          sb += ch;
          expect_new_t := char.IsWhiteSpace(ch);
        end;
      
      if is_add<>nil then
        yield seal_t();
      
    end;
    public constructor(s: string) := changes_maker := ()->ChangesFromStr(s.Trim);
    
  end;
  
  [PCUAlwaysRestore]
  FuncPPTFixer = sealed class(FuncFixer)
    public changes: array of FuncParamTChanges;
    private is_auto_fixer: boolean;
    
    public constructor(name: ApiVendorLName; changes: array of FuncParamTChanges; is_auto_fixer: boolean);
    begin
      inherited Create(name, false);
      self.changes := changes;
      self.is_auto_fixer := is_auto_fixer;
    end;
    static constructor := RegisterLoader('possible_par_types',
      (name, data)->
      begin
        var l := data.Single(l->not string.IsNullOrWhiteSpace(l));
        var spl := l.Split('|');
        
        var par_c := spl.Length-1;
        if not string.IsNullOrWhiteSpace(spl[par_c]) then
          raise new FormatException(l);
        
        var changes := ArrGen(par_c, i->
          new FuncParamTChanges(spl[i])
        );
        Result := new FuncPPTFixer(name, changes, false);
      end
    );
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, false);
      var l := data.Single(l->not string.IsNullOrWhiteSpace(l));
      var spl := l.Split('|');
      
      var par_c := spl.Length-1;
      if not string.IsNullOrWhiteSpace(spl[par_c]) then
        raise new FormatException(l);
      
      self.changes := ArrGen(par_c, i->
        new FuncParamTChanges(spl[i])
      );
      
    end;
    
    private function FixerInfo(f: Func) := $'[{TypeName(self)}] of func [{f.name}]';
    
    private procedure ErrorInfo(f: Func; act: string; i: integer; t: FuncParamT; ppt: List<FuncParamT>);
    begin
      var err := $'ERROR: {FixerInfo(f)} failed to {act} type [{t.ToString(true,true,true)}] of param#{i} [{f.NativePar[i].name}]: {ObjectToString(ppt.Select(par->par.ToString(true,true,true)))}';
      if is_auto_fixer then
        raise new MessageException(err+#10'Broken auto fixer, halt') else
        Otp(err);
    end;
    
    protected function ApplyOrder: FuncFixerApplyOrder; override :=
      if is_auto_fixer then FFAO_Auto_PPT else FFAO_PPT;
    public function Apply(f: Func): boolean; override;
    begin
      f.InitPossibleParTypes;
      
      var ind_nudge := Ord(f.is_proc);
      if changes.Length<>f.TotalParamCount-ind_nudge then
        raise new MessageException($'ERROR: {FixerInfo(f)} had wrong param count');
      
      for var i := 0 to changes.Length-1 do
        foreach var (is_add, t) in changes[i].changes_maker() do
          if is_add then
          begin
            if t in f.possible_par_types[i+ind_nudge] then
              ErrorInfo(f, 'add', i+ind_nudge, t, f.possible_par_types[i+ind_nudge]) else
            begin
              self.ReportUsed;
              var ppt := f.possible_par_types[i+ind_nudge];
              ppt += t;
              if t.var_arg and ((t.tname='IntPtr') or t.IsGeneric) then
                if ppt.Remove(new FuncParamT(t.is_const, false, 0, KnownDirectTypes.IntPtr)) then
                  ppt.Add(new FuncParamT(t.is_const, false, 0, KnownDirectTypes.Pointer));
            end;
          end else
          begin
            if f.possible_par_types[i+ind_nudge].Remove(t) then
              self.ReportUsed else
              ErrorInfo(f, 'remove', i+ind_nudge, t, f.possible_par_types[i+ind_nudge]);
          end;
      
      if is_auto_fixer then
        // Some auto fixers check in changes_maker
        self.ReportUsed;
      
      Result := false;
    end;
    
  end;
  
  {$endregion PPT}
  
  {$region LimitOvrs}
  
  [PCUAlwaysRestore]
  FuncLimitOvrsFixer = sealed class(FuncFixer)
    public ovrs: sequence of FuncOverload;
    
    static constructor := RegisterLoader('limit_ovrs',
      (name, data)->new FuncLimitOvrsFixer(name, data)
    );
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, false);
      
      ovrs := data.Select(l->
      begin
        Result := nil;
        var s := l.Split('|');
        if s.Length=1 then exit; // коммент
        
        if not string.IsNullOrWhiteSpace(s[s.Length-1]) then raise new System.FormatException(l);
        s := s[:^1];
        
        var ovr := s.ConvertAll(ps->
        begin
          ps := ps.Trim;
          Result := nil;
          if ps='' then exit;
          if ps='*' then exit;
          Result := FuncParamT.Parse(ps)
        end);
        Result := FuncOverload(ovr);
      end).Where(ovr->not ReferenceEquals(ovr,nil));
      
    end;
    
    private function FixerInfo(f: Func) := $'[{TypeName(self)}] of func [{f.name}]';
    
    protected function ApplyOrder: FuncFixerApplyOrder; override := FFAO_Overload;
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      var org_ovrs := f.all_overloads.ToArray;
      
      var expected_ovr_l := f.ExistingParCount;
      foreach var ovr in self.ovrs index ovr_i do
        if ovr.Size<>expected_ovr_l then
          raise new MessageException($'ERROR: ovr#{ovr_i} in {FixerInfo(f)} had wrong param count: {expected_ovr_l} org vs {ovr.Size} custom');
      
      var unused_t_ovrs := self.ovrs.ToHashSet;
      var limited_pars := new boolean[expected_ovr_l];
      
      f.all_overloads.RemoveAll(fovr->
        not self.ovrs.Any(tovr->
        begin
          Result := true;
          for var i := 0 to tovr.Size-1 do
          begin
            if tovr[i]=fovr[i+integer(f.is_proc)] then continue;
            limited_pars[i] := true;
            if tovr[i]=nil then continue;
            Result := false;
          end;
          if Result then unused_t_ovrs.Remove(tovr);
        end)
      );
      
      if unused_t_ovrs.Count<>0 then
      begin
        foreach var ovr in unused_t_ovrs do
          Otp($'WARNING: {FixerInfo(f)} has not used mask {ObjectToString(ovr.ItemsSeq.Select(par->par?.ToString(true,true,true)??''*''))}');
        Otp('-'*10+$' Func ovrs were '+'-'*10);
        foreach var ovr in org_ovrs do
          Otp(ObjectToString(ovr.ItemsSeq.Select(par->par?.ToString(true,true,true))));
      end;
      
      var unlimited_pars := expected_ovr_l.Times
        .Where(par_i->not limited_pars[par_i])
        .Select(par_i->par_i+integer(f.is_proc))
        .Select(par_i->$'par#{par_i}:{f.NativePar[par_i].name}');
      if unlimited_pars.Any then
        Otp($'WARNING: {FixerInfo(f)} has not limited pars: {ObjectToString(unlimited_pars)}');
      
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion LimitOvrs}
  
  {$endregion Func}
  
  {$region Extension}
  
  [PCUAlwaysRestore]
  ExtensionNameFixer = sealed class(ExtensionFixer)
    public new_name: ApiVendorLName;
    
    static constructor := RegisterLoader('rename',
      (name, data)->new ExtensionNameFixer(name, data)
    );
    public constructor(name: ApiVendorLName; data: sequence of string);
    begin
      inherited Create(name, false);
      var name_l := data.Single(l->not string.IsNullOrWhiteSpace(l));
      self.new_name := ApiVendorLName.Parse( name_l );
    end;
    
    public function Apply(e: Extension): boolean; override;
    begin
      e.Rename(new_name);
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion Extension}
  
{$endregion Fixers}

procedure Func.AddAutoFixerPPT(per_par: array of ()->sequence of ValueTuple<boolean,FuncParamT>);
begin
  if per_par.Length<>self.ntv_pars.Length then
    raise new InvalidOperationException;
  new FuncPPTFixer(self.Name, per_par[Ord(is_proc):].ConvertAll(f->
  begin
    Result := default(FuncParamTChanges);
    Result.changes_maker := f;
  end), true);
end;

end.