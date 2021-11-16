uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses MethodGenData;

uses ATask        in '..\..\..\Utils\ATask';

{$string_nullbased+}

type
  GetMethodSettings = sealed class(MethodSettings)
    
    public result_type: MethodArgType;
    public result_init := default(string);
    
    public force_ptr_qr := false;
    public need_pinn := false;
    
    public procedure Apply(setting_name: string; setting_lns: sequence of string; debug_tn: string); override :=
    match setting_name with
      
      'ResultType': result_type := MethodArgType.FromString(setting_lns.Single);
      
      'SetRes': result_init := ProcessDefLine(setting_lns.Single, debug_tn);
      
      'ForcePtrQr':
      begin
        if force_ptr_qr or need_pinn then raise new System.InvalidOperationException;
        force_ptr_qr := true;
      end;
      
      'PinnRes':
      begin
        if force_ptr_qr or need_pinn then raise new System.InvalidOperationException;
        need_pinn := true;
      end;
      
      else inherited;
    end;
    
    protected procedure ProcessSpecialDefVar(sb: StringBuilder; arg_name, usage: string; debug_tn: string); override :=
    case arg_name of
      
      'res':
      begin
        if result_init=nil then raise new System.InvalidOperationException;
        sb += 'res';
      end;
      
      'res_ptr':
      begin
        sb += '(own_qr as QueueResDelayedPtr<';
        sb += result_type.org_text;
        sb += '>).ptr';
      end;
      
      'res_pinn_adr':
      begin
        if not need_pinn then raise new System.InvalidOperationException;
        sb += 'res_hnd.AddrOfPinnedObject';
      end;
      
      else inherited;
    end;
    protected function GetArgTNames: sequence of string; override := args=nil? Seq(result_type.Enmr.Last.org_text) : args.Select(arg->arg.t.Enmr.Last.org_text).Append(result_type.Enmr.Last.org_text);
    
    public procedure Seal(t: string; type_generics: sequence of string; debug_tn: string); override;
    begin
      inherited;
      
      begin
        var impl_args_sb := new StringBuilder;
        
        impl_args_sb += 'ccq: ';
        impl_args_sb += t;
        impl_args_sb += 'CCQ';
        if type_generics.Any then
        begin
          impl_args_sb += '<';
          impl_args_sb += type_generics.JoinToString(', ');
          impl_args_sb += '>';
        end;
        
        if impl_args_str<>nil then
        begin
          impl_args_sb += '; ';
          impl_args_sb += impl_args_str;
        end;
        
        impl_args_str := impl_args_sb.ToString;
      end;
      
      if impl_args=nil then impl_args := new List<string>;
      impl_args.Insert(0, 'self');
      
      if not is_short_def and not force_ptr_qr and (result_init=nil) then raise new System.InvalidOperationException(debug_tn);
      
    end;
    
  end;
  
  GetMethodGenerator = sealed class(MethodGenerator<GetMethodSettings>)
    
    protected function MakeOtpFileName(t: string): string; override := $'{t}.Get';
    
    protected procedure WriteInvokeHeader(settings: GetMethodSettings); override;
    begin
      res_EIm += '    protected function InvokeParamsImpl(g: CLTaskGlobalData; l: CLTaskLocalData; evs_l1, evs_l2: List<EventList>): (';
      res_EIm += t;
      if generics.Count <> 0 then
      begin
        res_EIm += '<';
        res_EIm += generics.Select(g->g[0]).JoinToString(', ');
        res_EIm += '>';
      end;
      res_EIm += ', cl_command_queue, CLTaskErrHandler, EventList, QueueResDelayedBase<';
      res_EIm += settings.result_type.org_text;
      res_EIm += '>)->cl_event; override;'#10;
    end;
    protected procedure WriteInvokeFHeader; override;
    begin
      res_EIm += '(o, cq, err_handler, evs, own_qr)->'#10;
    end;
    protected procedure AddGCHandleArgs(args_with_GCHandle, args_with_pinn: List<string>; settings: GetMethodSettings); override :=
    if settings.force_ptr_qr then
      args_with_GCHandle += 'own_qr' else
    if settings.need_pinn then
      args_with_pinn += 'res';
    protected procedure WriteResInit(wr: Writer; settings: GetMethodSettings); override :=
    if settings.result_init<>nil then
    begin
      wr += '        var res := ';
      wr += settings.result_init;
      wr += ';'#10;
      wr += '        own_qr.SetRes(res);'#10;
    end;
    protected function WriteLocalDataForParam(wr: Writer; settings: GetMethodSettings): boolean?; override;
    begin
      Result :=
        if not settings.arg_usage.Values.Any(use->use='ptr') then false else
        if settings.arg_usage.Values.All(use->use='ptr') then true else
          nil;
      if Result<>nil then
      begin
        wr += '.WithPtrNeed(';
        wr += Result.Value.ToString;
        wr += ')';
      end;
    end;
    
    protected procedure WriteCommandBaseTypeName(t: string; settings: GetMethodSettings); override;
    begin
      res_EIm += 'EnqueueableGetCommand<';
      res_EIm += t;
      if generics.Count <> 0 then
      begin
        res_EIm += '<';
        res_EIm += generics.Select(g->g[0]).JoinToString(', ');
        res_EIm += '>';
      end;
      res_EIm += ', ';
      res_EIm += settings.result_type.org_text;
      res_EIm += '>';
    end;
    protected procedure WriteCommandTypeInhConstructor; override :=
    res_EIm += '      inherited Create(ccq);'#10;
    protected procedure WriteMiscMethods(settings: GetMethodSettings); override;
    begin
      
      if settings.force_ptr_qr then
      begin
        res_EIm += '    public function ForcePtrQr: boolean; override := true;'#10;
        res_EIm += '    '#10;
      end;
      
    end;
    
    protected procedure WriteMethodResT(l_res, l_res_E: Writer; settings: GetMethodSettings); override;
    begin
      l_res_E += 'CommandQueue<';
      l_res += settings.result_type.org_text;
      l_res_E += '>';
    end;
    protected procedure WriteMethodEImBody(write_new_ct: Action0; settings: GetMethodSettings); override;
    begin
      write_new_ct;
      res_EIm += ' as CommandQueue<';
      res_EIm += settings.result_type.org_text;
      res_EIm += '>;'#10;
    end;
    protected function GetIImResT(settings: GetMethodSettings): string; override := settings.result_type.org_text;
    
  end;
  
begin
  try
    
    EnumerateFiles(GetFullPathRTA('ContainerMethods\GetDef'), '*.dat')
    .Select(fname->ProcTask(()->
    begin
      var t := System.IO.Path.GetFileNameWithoutExtension(fname);
      var g := new GetMethodGenerator(t);
      g.Open;
      
      g.WriteMethodGroup(fname, 'Get');
      
      g.Close;
      Otp($'Packed .Get methods for [{t}]');
    end))
    .CombineAsyncTask
    .SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.