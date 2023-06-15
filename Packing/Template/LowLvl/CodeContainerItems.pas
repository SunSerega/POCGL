unit CodeContainerItems;

{$zerobasedstrings}

interface

uses System;

uses '..\..\..\POCGL_Utils';
uses '..\..\..\Utils\AOtp';
uses '..\..\..\Utils\CodeGen';

uses '..\Common\PackingUtils';

uses BinUtils;
uses LLPackingUtils;
uses ItemNames;
uses ChoiseSets;
uses FuncHelpers;

uses NamedItemBase;
uses NamedItemFixerBase;

uses TypeRefering; //TODO Только для временных авто-фиксеров в Func

uses EnumItems;
uses ParData;

uses NamedTypeItems; //TODO Только для костыля obj_info

type
  FuncParamT = FuncHelpers.FuncParamT;
  
  {$region Func}
  
  Func = sealed class(NamedLoadedItem<Func, ApiVendorLName>)
    private entry_point_name: string;
    private ntv_pars: array of LoadedParData;
    private alias_ind: integer?;
    
    private changed_by_fixer := false;
    
    public property TotalParamCount: integer read ntv_pars.Length;
    public property ExistingParCount: integer read TotalParamCount - Ord(is_proc);
    public property NativePar[par_i: integer]: LoadedParData read ntv_pars[par_i];
    
    {$region Load}
    
    static constructor := RegisterLoader(br->
    begin
      Result := new Func(new ApiVendorLName(br), false);
      Result.entry_point_name := br.ReadString;
      Result.ntv_pars := br.ReadArr((br,i)->LoadedParData.Load(br, i<>0));
      Result.alias_ind := br.ReadNullable(br->br.ReadInt32);
    end);
    
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
          calculated_changes[^1] := |ValueTuple.Create(false, new FuncParamT(false,0,KnownDirectTypes.IntPtr))|;
        
        var ind_sh := Ord(last_err_code);
        if rev_pars.Length < 2+ind_sh then exit;
        if rev_pars.Skip(ind_sh).Take(2).All(par->(par.CalculatedDirectType=event_t) and (par.CalculatedPtr=1)) then
        begin
          calculated_changes[^(1+ind_sh)] := |ValueTuple.Create(false, new FuncParamT(false,1,event_t))|;
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
        Result := par.MakePPT(self.ToString, par_i=0);
      end);
    end;
    
    {$endregion PPT}
    
    {$region Overloads}
    
    private enum_to_type_binding_helper_ovr := default(FuncOverload);
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
            Otp($'WARNING: {self} had par#{par_i} as unopt_arr, but it does not need it: {_ObjectToString(types.Select(par->par.ToString(true,true,true)))}');
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
      
      var enum_to_type_binding_gr := ntv_pars.Select(par->par.CalculatedDirectType as Group).SingleOrDefault(gr->gr?.Body is ObjInfoEnumsInGroup);
      var enum_to_type_binding_gr_body := ObjInfoEnumsInGroup(enum_to_type_binding_gr?.Body);
      var enum_to_type_binding_gr_par_ind := -1;
      if enum_to_type_binding_gr_body<>nil then
      begin
        enum_to_type_binding_gr_par_ind := ntv_pars.FindIndex(par->par.CalculatedDirectType=enum_to_type_binding_gr);
        if enum_to_type_binding_gr_par_ind=-1 then raise new InvalidOperationException;
      end;
      
      var ppt_choises := new MultiChoiseSet(possible_par_types.ConvertAll((ppt,par_i)->
        is_proc and (par_i=0) ? 1 : ppt.Count
      ));
      
      var expected_ovr_count := 0;
      if enum_to_type_binding_gr<>nil then
        expected_ovr_count += 1 + enum_to_type_binding_gr_body.Enums.Length;
      expected_ovr_count += ppt_choises.StatesCount;
      
      all_overloads := new List<FuncOverload>(expected_ovr_count);
      
      {$region EnumToType}
      
      if enum_to_type_binding_gr<>nil then
      begin
        
        {$region Find}
        
        var enum_to_type_bindings: array of EnumToTypeBindingInfo;
        begin
          var enum_to_type_bindings_l := new List<EnumToTypeBindingInfo>(2);
          
          if enum_to_type_binding_gr_body.Enums.Any(r->r.HasInput) then
          begin
            var data_par_i := ntv_pars.FindIndex(par->
              (par.Name<>nil) and par.Name.EndsWith('_value')
              and (par.CalculatedDirectType = KnownDirectTypes.IntPtr)
              and (par.CalculatedPtr=0)
              and par.CalculatedReadonlyLvls.SequenceEqual(|1|)
            );
            if data_par_i=-1 then
              raise new InvalidOperationException;
            var size_par_i := data_par_i-1;
            if not ntv_pars[size_par_i].Name.EndsWith('_value_size') then
              raise new NotImplementedException;
            enum_to_type_bindings_l += new EnumToTypeBindingInfo(size_par_i, data_par_i, nil); 
          end;
          
          if enum_to_type_binding_gr_body.Enums.Any(r->r.HasOutput) then
          begin
            var data_par_i := ntv_pars.FindIndex(par->
              (par.Name<>nil) and par.Name.EndsWith('_value')
              and (par.CalculatedDirectType = KnownDirectTypes.IntPtr)
              and (par.CalculatedPtr=0)
              and not par.CalculatedReadonlyLvls.Any
            );
            if data_par_i=-1 then
              raise new InvalidOperationException;
            var size_par_i := data_par_i-1;
            if not ntv_pars[size_par_i].Name.EndsWith('_value_size') then
              raise new NotImplementedException;
            var ret_size_par_i := data_par_i+1;
            if not ntv_pars[ret_size_par_i].Name.EndsWith('_value_size_ret') then
              raise new NotImplementedException;
            enum_to_type_bindings_l += new EnumToTypeBindingInfo(size_par_i, data_par_i, ret_size_par_i); 
          end;
          
          enum_to_type_bindings := enum_to_type_bindings_l.ToArray;
        end;
        
        {$endregion Find}
        
        {$region enum_to_type_binding_helper_ovr}
        
        begin
          var pars := new FuncParamT[ntv_pars.Length];
          for var par_i := 0 to pars.Length-1 do
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
              pars[par_i] := new FuncParamT(true, 0, TypeLookup.FromName(t));
              continue;
            end;
            
            if enum_to_type_bindings.Find(b->par_i=b.returned_size_par_ind) <> nil then
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
              pars[par_i] := new FuncParamT(true, 0, KnownDirectTypes.UIntPtr);
              continue;
            end;
            
            if possible_par_types[par_i].Count=1 then
            begin
              pars[par_i] := possible_par_types[par_i].Single;
              continue;
            end;
            
            if (possible_par_types[par_i].Count=3) and (ntv_pars[par_i].CalculatedPtr=1) then
            begin
              pars[par_i] := possible_par_types[par_i].Single(p->p.var_arg);
              continue;
            end;
            
            raise new NotImplementedException;
          end;
          
          self.enum_to_type_binding_helper_ovr := new FuncOverload(pars);
          all_overloads += enum_to_type_binding_helper_ovr;
        end;
        
        {$endregion enum_to_type_binding_helper_ovr}
        
        {$region other ovr's}
        
        foreach var r in enum_to_type_binding_gr_body.Enums do
        begin
          if enum_to_type_bindings.Any(b->not b.IsInputData) and not r.HasOutput then
          begin
            Otp($'WARNING: {self} could not generate overload: no output type info for {enum_to_type_binding_gr} {r.Enum}');
            continue;
          end;
          
          var ename := r.Enum.Name;
          
          if ename.api<>enum_to_type_binding_gr.Name.api then
            raise new InvalidOperationException;
          
          var enum_name := ename.l_name;
          if ename.vendor_suffix<>nil then
            enum_name += '_'+ename.vendor_suffix;
          
          var pars := enum_to_type_binding_helper_ovr.pars.ToArray;
          pars[ntv_pars.FindIndex(par->par.CalculatedDirectType=enum_to_type_binding_gr)] := nil;
          
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
            
            if b.IsInputData then
            begin
              var inp_par := r.InputT;
              var inp_t := inp_par.CalculatedDirectType;
              
              var data_size_is_dynamic: boolean;
              match inp_par.ArrSize with
                ParArrSizeNotArray(var pasna): data_size_is_dynamic := false;
                ParArrSizeArbitrary(var pasa): data_size_is_dynamic := true;
                else raise new NotImplementedException;
              end;
              
              if inp_par.CalculatedPtr <> Ord(data_size_is_dynamic) then
                raise new NotImplementedException;
              if inp_par.ValCombo <> nil then
                raise new InvalidOperationException;
              
              var t := inp_t.MakeWriteableName;
                if data_size_is_dynamic then
                  t := $'ArraySegment<{t}>';
                pars[b.data_par_ind] := new FuncParamT(false, 0, t, inp_t);
            end else
            // not b.IsInputData
            begin
              var otp_par := r.OutputT;
              var otp_t := otp_par.CalculatedDirectType;
              
              var data_size_mlt := 1;
              var data_size_is_dynamic := false;
              
              var need_arr: boolean;
              
              match otp_par.ArrSize with
                
                ParArrSizeNotArray(var pasna): need_arr := false;
                
                ParArrSizeConst(var pasc):
                begin
                  data_size_mlt := pasc.Value;
                  need_arr := true;
                end;
                
                ParArrSizeArbitrary(var pasa):
                begin
                  need_arr := otp_t <> KnownDirectTypes.String;
                  data_size_is_dynamic := need_arr;
                end;
                
                else raise new NotImplementedException;
              end;
              if otp_par.CalculatedPtr<>0 <> need_arr then
                raise new NotImplementedException;
              if otp_par.ValCombo <> nil then
                raise new InvalidOperationException;
              
              var par := new FuncParamT(true, otp_par.CalculatedPtr, otp_t);
              if data_size_mlt<>1 then
                par.otp_data_const_sz := data_size_mlt;
              pars[b.data_par_ind] := par;
            end;
            
          end;
          
          all_overloads += new FuncOverload(pars, enum_to_type_bindings, enum_to_type_binding_gr, enum_name);
        end;
        
        {$endregion other ovr's}
        
      end;
      
      {$endregion EnumToType}
      
      for var only_arr_ovrs := opt_arr.Any(b->b) downto false do
        foreach var ppt_choises_state in ppt_choises.Enmr do
        begin
          var ovr := new FuncParamT[ntv_pars.Length];
          for var par_i := 0 to ntv_pars.Length-1 do
          begin
            if is_proc and (par_i=0) then continue;
            var ppt_ind := ppt_choises_state.Choise[par_i];
            if opt_arr[par_i] and (ppt_ind=0 <> only_arr_ovrs) then
            begin
              ovr := nil;
              break;
            end;
            ovr[par_i] := possible_par_types[par_i][ppt_ind];
          end;
          if ovr=nil then continue;
          all_overloads += FuncOverload(ovr);
        end;
      
      {$ifdef DEBUG}
      // Some overloads are filtered because of only_arr_ovrs
//      if all_overloads.Count<>expected_ovr_count then
//        raise new InvalidOperationException;
      var ovrs_hs := new HashSet<FuncOverload>(expected_ovr_count);
      foreach var ovr in all_overloads do
        if not ovrs_hs.Add(ovr) then
          Otp($'ERROR: {self} overload {ovr} was dupped');
      {$endif DEBUG}
    end;
    
    {$endregion Overloads}
    
    {$region Write}
    
    public static procedure LogAllEnumToType;
    begin
      var l := new FileLogger(GetFullPathRTA('Log\All EnumToTypeBinding''s.log'));
      loop 3 do l.Otp('');
      
      ForEachDefined(f->
      begin
        f.InitOverloads;
        if f.enum_to_type_binding_helper_ovr=nil then exit;
        
        var bound_ovrs := f.all_overloads.Where(ovr->ovr.enum_to_type_bindings<>nil);
        
        var (bindings, gr) := bound_ovrs
          .Select(ovr->ValueTuple.Create(ovr.enum_to_type_bindings, ovr.enum_to_type_gr))
          .Distinct.Single;
        
        l.Otp($'# {f.Name}');
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
        
        foreach var ovr in bound_ovrs do
        begin
          l.Otp('--- '+ovr.enum_to_type_enum_name);
          foreach var b in bindings do
          begin
            var par := ovr.pars[b.data_par_ind];
            if par=nil then continue;
            if b.IsInputData then
              l.Otp('!input') else
              l.Otp('!output');
            if not b.IsInputData and not par.var_arg then
              raise new InvalidOperationException;
            l.Otp(par.ToString(true,false));
          end;
        end;
        
        l.Otp('');
      end);
      
      loop 1 do l.Otp('');
      l.Close;
    end;
    
    private procedure UseBody(need_write: boolean) :=
      foreach var ovr in all_overloads do
        foreach var par in ovr.pars index par_i do
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
    
    private was_written := false;
    private ffo_logged := false;
    //TODO #2623: Move inside Save
    /// Name of type-substitute for generic type
    public procedure Save(wr: Writer);
    begin
      if not in_wr_block then
        raise new InvalidOperationException;
      var lib_name := last_lib_name;
      var is_dynamic := lib_name=nil;
      
//      InitOverloads;
      // Should be generated in MarkReferenced
      if all_overloads=nil then
        raise new InvalidOperationException;
      
      {$region Log and Warn}
      
      if not self.was_written then
      begin
        self.was_written := true;
        written_c += 1;
      end;
      
      //TODO Переместить запись log_func_ovrs в другое место
      // - Чтобы их сортировало по имени
      if not self.ffo_logged then
      begin
        self.ffo_logged := true;
        log_func_ovrs.Otp($'# {self.Name}[{all_overloads.Count}]:');
        
        if not is_proc or (ntv_pars.Length>1) then
        begin
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
              if ovr.pars[i]<>nil then
                s := ovr.pars[i].ToString(true, true) else
              begin
                if ovr.enum_to_type_bindings=nil then
                  raise new InvalidOperationException;
                
                foreach var b in ovr.enum_to_type_bindings do
                begin
                  if i=b.passed_size_par_ind then
                    s := '%inp_size%' else
                  if i=b.returned_size_par_ind then
                    s := '%ret_size%' else
                  if i=b.data_par_ind then
                    s := nil else
                    continue;
                  if ovr.pars[b.data_par_ind]=nil then
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
              loop w-s.Length do l += ' ';
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
        Otp($'ERROR: {self} ended up having 0 overloads. [possible_par_types]:');
        foreach var par in possible_par_types index par_i do
        begin
          if is_proc and (par_i=0) then continue;
          Otp(#9+_ObjectToString(par.Select(p->p.ToString(true,true,true))));
        end;
        exit;
      end else
      for var par_i := 0 to ntv_pars.Length-1 do
      begin
        if is_proc and (par_i=0) then continue;
        
        foreach var t in possible_par_types[par_i] do
        begin
          if all_overloads.Any(ovr->ovr.pars[par_i]=t) then continue;
          Otp($'WARNING: {self} par#{par_i} ppt [{t.ToString(true,true,true)}] did not appear in final overloads. Use !ppt fixer to remove it, if this is intentional');
        end;
        
      end;
      self.UseBody(true);
      
      if not self.changed_by_fixer then
      begin
        if all_overloads.Count>12 then
          Otp($'WARNING: {all_overloads.Count}>12 overloads of non-fixed {self}');
        Func.ForEachDefined(other_func->
        begin
          if ReferenceEquals(other_func, self) then exit;
          if not other_func.changed_by_fixer then exit;
          if other_func.Name.api <> self.Name.api then exit;
          if other_func.Name.l_name <> self.Name.l_name then exit;
          Otp($'WARNING: Func [{other_func}] was fixed, but {self} was not');
        end);
      end;
      
      {$endregion Log and Warn}
      
      {$region MiscInit}
      
      var par_names := ntv_pars.ConvertAll((par,par_i)->
      begin
        Result := 'Result';
        if par_i=0 then exit;
        Result := par.Name;
        if all_overloads.Any(ovr->par.Name.ToLower in ovr.pars.Select(ovr_par->ovr_par?.tname.ToLower).Where(tname->tname<>nil).Append('pointer')) then
          Result := '_'+Result;
      end);
      
      var display_name := self.Name.l_name;
      if self.Name.vendor_suffix<>nil then
        display_name += self.Name.vendor_suffix.ToUpper;
      
      if display_name in last_wr_block_func_lnames then
        raise new InvalidOperationException($'{display_name} added in the same api (lib: {_ObjectToString(lib_name)}) twice: {last_wr_block_func_lnames[display_name]} and {self}');
      last_wr_block_func_lnames.Add(display_name, self);
      
      if is_dynamic then
        wr += $'    private {display_name}_adr := GetProcAddress(''{entry_point_name}'');' + #10;
      
      {$endregion MiscInit}
      
      {$region WriteOvrT}
      
      var WriteOvrT := procedure(wr: Writer; pars: array of FuncParamT; generic_names: HashSet<string>; name: string)->
      begin
        
        if not is_dynamic and (name<>nil) then wr += 'static ';
        wr += if self.is_proc then 'procedure' else 'function';
        
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
        
        if pars.Skip(1).Any(p->p<>nil) then
        begin
          wr += '(';
          var first_par := true;
          for var par_i := 1 to pars.Length-1 do
          begin
            var par := pars[par_i];
            if par=nil then continue;
            if first_par then
              first_par := false else
              wr += '; ';
            if par.var_arg then wr += 'var ';
            wr += ntv_pars[par_i].name;
            wr += ': ';
            loop par.arr_lvl do wr += 'array of ';
            var tname := par.tname;
            if tname.ToLower in Func.last_wr_block_func_lnames then wr += 'OpenGL.';
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
      
      //TODO FuncParamMarshaler не нужен
      // - Вся информация хранится в FuncParamT
      // - И получать init,fnls и т.п. лучше на стадии кодогенерации
      // - Только объявления всех var и т.п. станут сложнее
      // - Но их тоже надо переделать на самом деле, потому что сейчас finally криво работает
      //TODO Перенести алгоритм в ParData
      // - Так же как MakePPT?
      {$region MakeMarshlers}
      
      var all_ovr_marshalers := all_overloads.ConvertAll(ovr->
      begin
        Result := new FuncOvrMarshalers(ntv_pars.Length);
        for var par_i := 0 to ovr.pars.Length-1 do
        begin
          if is_proc and (par_i=0) then continue;
          var par := ovr.pars[par_i];
          
          var initial_par_str := par_names[par_i];
          var relevant_m := new FuncParamMarshaler(par, initial_par_str);
          
          if par_i=0 then
          {$region Result}
          begin
            // Cannot determine array size if it is returned
            if par.var_arg or (par.arr_lvl<>0) then raise new System.NotSupportedException;
            
            {$region boolean}
            
            if par.tname='boolean' then
              raise new NotSupportedException('Use api::Bool8');
//            begin
//              relevant_m.res_par_conv := '0<>'#0'';
//              Result.AddMarshaler(par_i, relevant_m);
//              
//              par := new FuncParamT(false, 0, KnownDirectTypes.StubForGenericT);
//              relevant_m := new FuncParamMarshaler(par, initial_par_str);
//            end;
            
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
                if ntv_pars[par_i].CalculatedPtr+1 not in ntv_pars[par_i].CalculatedReadonlyLvls then
                begin
                  fnls += #10;
                  fnls += 'Marshal.FreeHGlobal(';
                  fnls += str_ptr_name;
                  fnls += ');';
                end;
              end;
              
              relevant_m.par_str := str_ptr_name;
              Result.AddMarshaler(par_i, relevant_m);
              
              par := new FuncParamT(false, 0, KnownDirectTypes.StubForGenericT);
              relevant_m := new FuncParamMarshaler(par, initial_par_str);
            end;
            
            {$endregion string}
            
          end
          {$endregion Result}
          else
          {$region Param}
          begin
            
            //TODO Для этого наверное придётся всё же переделать систему маршлеров
            // - В первую очередь, есть случаи, где надо несколько вызовов разных более простых перегрузок
            // - Но уже давно надо перенести всё это на стадию кодогенерации
            // - Тогда сам факт добавления переменной с инициализацией будет создавать блок begin-end
            // - Но с финализацией не так просто...
            // - Наверное нужно start_extra_block('try', ()->begin end)
            // - И отдельное indicate_need_block(), чтобы более явно создавать основной begin-end; перегрузки
            {$region enum_to_type_bindings}
            
            if ovr.enum_to_type_bindings<>nil then
            begin
              
              if ntv_pars[par_i].CalculatedDirectType=ovr.enum_to_type_gr then
              begin
                relevant_m.par_str := $'{ovr.enum_to_type_gr.MakeWriteableName}.{ovr.enum_to_type_enum_name}';
                Result.AddMarshaler(par_i, relevant_m);
                
                par := new FuncParamT(false, 0, ovr.enum_to_type_gr);
                relevant_m := new FuncParamMarshaler(par, initial_par_str);
              end else
              foreach var b in ovr.enum_to_type_bindings do
              begin
                //TODO Очень временно, чисто чтобы ошибки упаковки не давало...
                if par_i=b.data_par_ind then
                begin
                  Result.AddMarshaler(par_i, relevant_m);
                  var t := $'T';
                  if b.IsInputData then
                    t += 'Inp';
                  par := new FuncParamT(true, 0, TypeLookup.FromName(t));
                  relevant_m := new FuncParamMarshaler(par, initial_par_str);
                end else
                if par_i=b.passed_size_par_ind then
                begin
                  relevant_m.par_str := '%inp_size%';
                  Result.AddMarshaler(par_i, relevant_m);
                  par := new FuncParamT(false, 0, KnownDirectTypes.UIntPtr);
                  relevant_m := new FuncParamMarshaler(par, initial_par_str);
                end else
                if par_i=b.returned_size_par_ind then
                begin
                  relevant_m.par_str := '%otp_size%';
                  Result.AddMarshaler(par_i, relevant_m);
                  par := new FuncParamT(true, 0, KnownDirectTypes.UIntPtr);
                  relevant_m := new FuncParamMarshaler(par, initial_par_str);
                end else
                  continue;
                break;
              end;
              
            end;
            
            {$endregion enum_to_type_bindings}
            
            // enum_to_type_bindings can return var-array
            if (par.var_arg) and (par.arr_lvl<>0) then
              raise new System.NotSupportedException;
            
            {$region boolean}
            
            if (par.tname='boolean'){ and not par.var_arg} then
              raise new NotSupportedException('Use {api}::Bool8');
//            begin
//              if par.arr_lvl<>0 then raise new System.NotImplementedException(
//                $'Func [{name}] par#{par_i} [{par}]: Standard boolean marshaling will gen in the way of copying'
//              );
//              
//              relevant_m.par_str := $'{KnownDirectTypes.StubForGenericT.MakeWriteableName}({relevant_m.par_str})';
//              Result.AddMarshaler(par_i, relevant_m);
//              
//              par := new FuncParamT(false, 0, KnownDirectTypes.StubForGenericT);
//              relevant_m := new FuncParamMarshaler(par, initial_par_str);
//            end;
            
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
              
              par := new FuncParamT(false, par.arr_lvl, KnownDirectTypes.IntPtr);
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
                for var temp2664 := 1 to par.arr_lvl-1 do init += '  '; init += '  var l := managed_a.Length*Marshal.SizeOf&<'; init += par.tname; init += '>;'#10;
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
              
              par := new FuncParamT(false, par.arr_lvl-1, KnownDirectTypes.IntPtr);
              relevant_m := new FuncParamMarshaler(par, initial_par_str);
            end;
            
            if par.arr_lvl=1 then
            begin
              relevant_m.par_str := relevant_m.par_str; // +'[0]'; - but it will be added in codegen stage
              Result.AddMarshaler(par_i, relevant_m);
              
              par := par.WithPtr(true, 0);
              relevant_m := new FuncParamMarshaler(par, initial_par_str);
            end;
            
            {$endregion array of array}
            
            {$region genetic}
            
            if par.IsGeneric then
            begin
              // Ovr's like "p<T>(o: T)" don't make sense
              if not par.var_arg then
                raise new System.NotSupportedException;
              
              relevant_m.par_str := $'P{KnownDirectTypes.StubForGenericT.MakeWriteableName}(pointer(@{relevant_m.par_str}))^';
              Result.AddMarshaler(par_i, relevant_m);
              
              par := new FuncParamT(par.var_arg, par.arr_lvl, KnownDirectTypes.StubForGenericT);
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
            if is_fast_forward then
              raise new System.InvalidOperationException;
            // Why check this?
            if (m.par<>nil) and (m.par.tname=nil) then
              raise new InvalidOperationException;
            Result := m;
          end);
          
          var md := new MethodImplData(curr_marshalers);
          md.name := display_name;
          if ovr.enum_to_type_enum_name<>nil then
            md.name += '_'+ovr.enum_to_type_enum_name;
          md.is_public := true;
          pending_md[ovr_i] := md;
          
          if not curr_marshalers.Select(m->m?.par).SequenceEqual(ovr.pars) then
            raise new InvalidOperationException(curr_marshalers.Select(m->m?.par).Zip(ovr.pars, (p1,p2)->p1=p2).JoinToString);
          
          begin
            var old_md: MethodImplData;
            if MethodByPars.TryGetValue(ovr, old_md) then
              raise new InvalidOperationException;
          end;
          MethodByPars.Add(ovr, md);
          MethodList.Add(md);
        end;
        
        MethodList.Reverse;
        // Then another reverse at the end, to have better method order
        foreach var ovr_m: FuncOvrMarshalers in all_ovr_marshalers index ovr_i do
        begin
          var prev_md := pending_md[ovr_i];
          
          for var max_marshaler_ind := (all_ovr_marshalers[ovr_i].MaxMarshalInd-1).ClampBottom(0) downto 0 do
          begin
            var can_be_fast_forward := new boolean[ntv_pars.Length];
            var possible_m := new FuncParamMarshaler[ntv_pars.Length];
            for var par_i := 0 to ntv_pars.Length-1 do
            begin
              if is_proc and (par_i=0) then continue;
              (can_be_fast_forward[par_i], possible_m[par_i]) := ovr_m.GetPossible(par_i, max_marshaler_ind);
            end;
            
            var new_pars := default(FuncOverload);
            var new_md := default(MethodImplData);
            var found_md := default(MethodImplData);
            foreach var fast_forward in MultiBooleanChoiseSet.Create(can_be_fast_forward).Enmr do
            begin
              var curr_marshalers := ArrGen(ntv_pars.Length, par_i->
                is_proc and (par_i=0) ?
                  nil :
                fast_forward.Flag[par_i] ?
                  possible_m[par_i] :
                  ovr_m.GetCurrent(par_i)
              );
              var pars: FuncOverload := curr_marshalers.ConvertAll(m->m?.par);
              
              if fast_forward.IsFirst then
              begin
                new_pars := pars;
                new_md := new MethodImplData(curr_marshalers);
              end;
              
              if not MethodByPars.TryGetValue(pars, found_md) then continue;
              
              if max_marshaler_ind<>0 then break;
              // Native method. It should be called instead of another method with same parameters
              
              if not fast_forward.IsFirst then raise new InvalidOperationException;
              
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
              md.name := (if max_marshaler_ind=0 then 'ntv_' else 'temp_') + display_name;
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
          
          if md.name in pas_keywords then
            md.name := '&'+md.name;
          
        end;
      end;
      
//      foreach var md in MethodList do
//      begin
//        PABCSystem.Write(md.name);
//        PABCSystem.Write('(');
//        PABCSystem.Write(md.pars.Select(m->m?.par.ToString(true,true,true)).Where(s->s<>nil).JoinToString('; '));
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
        if md.call_to not in MethodList.Prepend(nil) then
          raise new System.InvalidOperationException(self.ToString);
        var pars := md.pars.ConvertAll(m->m?.par);
        
        if md.call_to=nil then
        {$region Native}
        begin
          
          if is_dynamic then
          begin
            
            wr += '    private ';
            wr += md.name;
            wr += ' := GetProcOrNil&<';
            WriteOvrT(wr, pars,nil, nil);
            wr += '>(';
            wr += display_name;
            wr += '_adr);'+#10;
            
          end else
          begin
            
            wr += '    private ';
            WriteOvrT(wr, pars,nil, md.name);
            wr += ';'#10;
            wr += '    external ''';
            wr += Func.last_lib_name;
            wr += ''' name ''';
            wr += entry_point_name;
            wr += ''';'#10;
            
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
//            if is_proc and (par_i=0) then continue;
            if par=nil then continue;
            
            need_conv[par_i] := par <> md.call_to.pars[par_i].par;
            
            if par.IsGeneric then
              generic_names += par.tname;
            
            arr_nil_pars[par_i] := need_conv[par_i] and (par.arr_lvl=1) and (par.tname<>'string');
            if arr_nil_pars[par_i] then
              ptr_need_names += par.tname;
            
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
                wr += par.par.tname;
                wr += '(nil)^';
              end else
              if need_conv[par_i] then
              begin
                wr += par.par_str;
                if arr_nil_pars[par_i] then
                  wr += '[0]';
              end else
                wr += ntv_pars[par_i].name;
            end;
            wr += ')';
            
            if arr_nil.IsLast then
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
      
    end;
    
    public static procedure DefineWriteBlock(lib_name: string; write_funcs: ()->());
    begin
      if in_wr_block then
        raise new InvalidOperationException;
      in_wr_block := true;
      last_lib_name := lib_name;
      
      write_funcs();
      
      last_wr_block_func_lnames.Clear;
      in_wr_block := false;
    end;
    
    {$endregion Write}
    
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
          var log_versions := new FileLogger(GetFullPathRTA($'Log\{api.ToUpper} versions.log'));
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
          intr_wr += '  [PCUNotRestore]'#10;
          intr_wr += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
          intr_wr += '  ';
          intr_wr += api;
          if depr_ver<>nil then intr_wr += 'D';
          intr_wr += ' = ';
          intr_wr += class_type;
          intr_wr += ' class'#10;
          
          if is_dynamic then
          begin
            
            intr_wr += '    public constructor(loader: PlatformLoader);'#10;
            intr_wr += '    private constructor := raise new System.NotSupportedException;'#10;
            intr_wr += '    private function GetProcAddress(name: string): IntPtr;'#10;
            intr_wr += '    private static function GetProcOrNil<T>(fadr: IntPtr) :='#10;
            intr_wr += '      if fadr=IntPtr.Zero then default(T) else'#10;
            intr_wr += '        Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
            
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
                f.Save(intr_wr);
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
  
  Extension = sealed class(NamedLoadedItem<Extension, ApiVendorLName>)
    private ext_str: string;
    private add: RequiredList;
    private dep_inds: array of integer;
    
    private static AllExtensions := new List<Extension>;
    
    static constructor := RegisterLoader(br->
    begin
      Result := new Extension(new ApiVendorLName(br), false);
      Result.ext_str := br.ReadString;
      Result.add := RequiredList.Load(br);
      Result.dep_inds := br.ReadInt32Arr;
      AllExtensions += Result;
    end);
    
    public property Added: RequiredList read add;
    
    public function Dependencies := Extension.MakeLazySeq(dep_inds).ToSeq;
    
    public procedure MarkBodyReferenced; override;
    begin
      add.MarkReferenced;
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
      
      if not add.Enums.Any and not add.Funcs.Any then exit;
      if not ApiManager.ShouldKeep(api) then exit;
      Extension.written_c += 1;
      
      foreach var dep in Dependencies.AsEnumerable do //TODO #2852
        dep.Save;
      
      var is_dynamic := ApiManager.NeedDynamicLoad(api, true);
      // wgl and glx load from their api.GetProcAddress
      // in that case need_loader=false, is_dynamic=true
      var need_loader := ApiManager.NeedDynamicLoad(api, false);
      if need_loader and not is_dynamic then
        raise new InvalidOperationException(api);
      
      var any_funcs := add.Funcs.Any;
      if not any_funcs then
      begin
        is_dynamic := false;
        need_loader := false;
      end;
      
      var lib_name := if is_dynamic or not any_funcs then nil else ApiManager.LibForApi(api);
      var class_type := if is_dynamic then 'sealed partial' else 'static';
      
      var display_name := api + self.Name.l_name.Split('_').Select(w->
      begin
        if w.Length<>0 then w[0] := w[0].ToUpper else
          raise new System.InvalidOperationException(self.ToString);
        Result := w;
      end).JoinToString('') + self.Name.vendor_suffix?.ToUpper;
      
      if any_funcs then
      begin
        intr_wr += '  [PCUNotRestore]'#10;
        intr_wr += '  [System.Security.SuppressUnmanagedCodeSecurity]'#10;
      end;
      
      intr_wr += '  ';
      intr_wr += display_name;
      intr_wr += ' = ';
      intr_wr += class_type;
      intr_wr += ' class'#10;
      
      if is_dynamic then
      begin
        if need_loader then
        begin
          intr_wr += '    public constructor(loader: PlatformLoader);'#10;
          intr_wr += '    private constructor := raise new System.NotSupportedException;'#10;
          
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
        
        intr_wr += '    private function GetProcAddress(name: string)';
        if need_loader then
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
      
      intr_wr += '    public const _ExtStr = ''';
      intr_wr += ext_str;
      intr_wr += ''';'+#10;
      if any_funcs then
        intr_wr += '    '+#10;
      
      log_ext_bodies.Otp($'# {display_name} ({ext_str})');
      
      foreach var e in Added.Enums do
        log_ext_bodies.Otp(#9+e);
      
      Func.DefineWriteBlock(lib_name, ()->
        foreach var f in Added.Funcs do
        begin
          f.Save(intr_wr);
          intr_wr += '    '+#10;
          log_ext_bodies.Otp(#9+f);
        end
      );
      
      log_ext_bodies.Otp($'');
      
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
      
      foreach var ext in AllExtensions do
        ext.Save;
      
      intr_wr += '  '#10'  ';
      impl_wr += #10;
      all_wr.Close;
    end;
    
  end;
  
  ExtensionFixer = abstract class(NamedItemCommonFixer<ExtensionFixer, Extension>)
    
  end;
  
  {$endregion Extension}
  
implementation

{$region Fixers} type
  
  {$region PPT}
  
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
      var err := $'ERROR: {FixerInfo(f)} failed to {act} type [{t.ToString(true,true,true)}] of param#{i} [{f.NativePar[i].name}]: {_ObjectToString(ppt.Select(par->par.ToString(true,true,true)))}';
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
                if ppt.Remove(new FuncParamT(false, 0, KnownDirectTypes.IntPtr)) then
                  ppt.Add(new FuncParamT(false, 0, KnownDirectTypes.Pointer));
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
      end).Where(ovr->ovr<>nil);
      
    end;
    
    private function FixerInfo(f: Func) := $'[{TypeName(self)}] of func [{f.name}]';
    
    protected function ApplyOrder: FuncFixerApplyOrder; override := FFAO_Overload;
    public function Apply(f: Func): boolean; override;
    begin
      f.InitOverloads;
      var org_ovrs := f.all_overloads.ToArray;
      
      var expected_ovr_l := f.ExistingParCount;
      foreach var ovr in self.ovrs index ovr_i do
        if ovr.pars.Length<>expected_ovr_l then
          raise new MessageException($'ERROR: ovr#{ovr_i} in {FixerInfo(f)} had wrong param count: {expected_ovr_l} org vs {ovr.pars.Length} custom');
      
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
          Otp($'WARNING: {FixerInfo(f)} has not used mask {_ObjectToString(ovr.pars.Select(par->par?.ToString(true,true,true)??''*''))}');
        Otp('-'*10+$' Func ovrs were '+'-'*10);
        foreach var ovr in org_ovrs do
          Otp(_ObjectToString(ovr.pars.Select(par->par?.ToString(true,true,true))));
      end;
      
      var unlimited_pars := expected_ovr_l.Times
        .Where(par_i->not limited_pars[par_i])
        .Select(par_i->par_i+integer(f.is_proc))
        .Select(par_i->$'par#{par_i}:{f.NativePar[par_i].name}');
      if unlimited_pars.Any then
        Otp($'WARNING: {FixerInfo(f)} has not limited pars: {_ObjectToString(unlimited_pars)}');
      
      self.ReportUsed;
      Result := false;
    end;
    
  end;
  
  {$endregion LimitOvrs}
  
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

begin
  {$region TODO#2844}
  //TODO #2844: These types are deleted from .exe, if not used
  
  if nil=default(FuncPPTFixer) then;
  if nil=default(FuncLimitOvrsFixer) then;
  
  {$endregion TODO#2844}
end.