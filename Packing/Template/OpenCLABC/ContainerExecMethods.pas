﻿uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses ContainerMethodData;

uses ATask        in '..\..\..\Utils\ATask';

{$string_nullbased+}

type
  ExecMethodSettings = sealed class(MethodSettings)
    private static arg_k_args := new MethodArg('args', new MethodArgTypeBasic('array of KernelArg'));
    
    public procedure Seal(t: string; type_generics: sequence of string; debug_tn: string); override;
    begin
      inherited;
      
      begin
        var args_sb := new StringBuilder;
        if args_str<>nil then
        begin
          args_sb += args_str;
          args_sb += '; ';
        end;
        args_sb += 'params args: array of KernelArg';
        args_str := args_sb.ToString;
        impl_args_str := args_str;
      end;
      
      if args=nil then args := new List<MethodArg>;
      args += arg_k_args;
      
      if impl_args=nil then impl_args := new List<string>;
      impl_args += arg_k_args.name;
      
      arg_usage[arg_k_args.name] := nil;
      
      callback_lines := (callback_lines??new string[0]) + |'self.KeepArgsGCAlive;'|;
    end;
    
  end;
  ExecMethodGenerator = sealed class(MethodGenerator<ExecMethodSettings>)
    
    protected function MakeOtpFileName(t: string): string; override := $'{t}.Exec';
    
    protected procedure WriteInvokeHeader(settings: ExecMethodSettings); override;
    begin
      res_EIm += '    protected function InvokeParams(g: CLTaskGlobalData; enq_evs: DoubleEventListList; arg_cache: KernelArgCache; cache_lock: ExecCommandOwnKLock): EnqFunc<cl_kernel>; override;'#10;
    end;
    
    protected function GetSpecialInvokeResVars(settings: ExecMethodSettings): sequence of MethodArg; override := |ExecMethodSettings.arg_k_args|;
    protected procedure WriteBasicInvokeRes(wr: Writer; arg: MethodArg; settings: ExecMethodSettings); override :=
    if arg=ExecMethodSettings.arg_k_args then wr += 'arg_setters: array of KernelArgSetter' else inherited;
    protected procedure WriteBasicArgInvoke(wr: Writer; arg: MethodArg; settings: ExecMethodSettings); override :=
    if arg=ExecMethodSettings.arg_k_args then wr += 'arg_setters := self.InvokeArgs(invoker, enq_evs)' else inherited;
    
    protected procedure WriteSpecialPreEnq(wr: Writer; settings: ExecMethodSettings); override;
    begin
      wr += '        for var i := 0 to arg_setters.Length-1 do'#10;
      wr += '          arg_setters[i].Apply(o, i, arg_cache);'#10;
    end;
    protected procedure WriteSpecialPostEnq(wr: Writer; settings: ExecMethodSettings); override :=
    wr += '        cache_lock.TryReleaseLock;'#10;
    
    protected procedure WriteCommandBaseTypeName(t: string; settings: ExecMethodSettings); override :=
    res_EIm += 'EnqueueableExecCommand';
    protected procedure WriteCommandTypeInhConstructor; override :=
    res_EIm += '      inherited Create(args);'#10;
    protected function GetInitBeforeInvokeExtra: string; override := 'foreach var arg in args do arg.InitBeforeInvoke(g, prev_hubs)';
    
    protected procedure WriteBasicValueToString(wr: Writer; tab, vname: string; stored_as_ptr: boolean); override;
    begin
      case vname of
        
        'args':
        begin
          res_EIm += tab;
          res_EIm += 'sb += #10;'#10;
          
          res_EIm += tab;
          res_EIm += 'foreach var arg in args do arg.ToString(sb, tabs+1, index, delayed);'#10;
        end;
        
        else inherited;
      end;
    end;
    
    protected procedure WriteMethodResT(l_res, l_res_E: Writer; settings: ExecMethodSettings); override;
    begin
      l_res += 'Kernel';
      l_res_E += 'CCQ';
    end;
    
  end;
  
begin
  try
    
    var fname := GetFullPathRTA('!Def\ContainerMethods\Exec\0.dat');
    var t := 'Kernel';
    
    var g := new ExecMethodGenerator(t);
    g.WriteMethodGroup(fname, 'Exec');
    
    g.Close;
    Otp($'Packed .Exec methods for [{t}]');
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.