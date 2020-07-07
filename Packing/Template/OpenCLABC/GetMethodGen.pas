uses MiscUtils    in '..\..\..\Utils\MiscUtils';
uses MethodGenData;
{$string_nullbased+}

type
  GetMethodSettings = sealed class(MethodSettings)
    
    public result_type: MethodArgType;
    
    public force_ptr_qr := false;
    
    public procedure Apply(setting_name: string; setting_lns: sequence of string; debug_tn: string); override :=
    match setting_name with
      
      'ResultType': result_type := MethodArgType.FromString(setting_lns.Single);
      
      'ForcePtrQr': force_ptr_qr := true;
      
      else inherited;
    end;
    
    protected function GetArgTNames: sequence of string; override := args=nil? Seq(result_type.Enmr.Last.org_text) : args.Select(arg->arg.t.Enmr.Last.org_text).Append(result_type.Enmr.Last.org_text);
    
  end;
  
  GetMethodGenerator = sealed class(MethodGenerator<GetMethodSettings>)
    
    protected function MakeOtpFileName(t: string): string; override := $'{t}GetMethods';
    
    protected procedure WriteCommandBaseTypeName(t: string; settings: GetMethodSettings); override;
    begin
      res_EIm += 'EnqueueableGetCommand<';
      res_EIm += t;
      res_EIm += ', ';
      res_EIm += settings.result_type.org_text;
      res_EIm += '>';
    end;
    
    protected procedure WriteCommandTypeInvoke(fn: string; max_arg_w: integer; settings: GetMethodSettings); override;
    begin
      var ToDo := 0;
    end;
    
  end;
  
begin
  try
    
    EnumerateFiles(GetFullPathRTE('GetMethodDef'), '*.dat')
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
    
    if not is_secondary_proc then Otp('Done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.