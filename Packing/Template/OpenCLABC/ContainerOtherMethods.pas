uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses ContainerMethodData;

uses ATask        in '..\..\..\Utils\ATask';

{$string_nullbased+}

type
  MethodSettings = sealed class(ContainerMethodData.MethodSettings) end;
  MethodGenerator = sealed class(ContainerMethodData.MethodGenerator<MethodSettings>)
    
    protected function MakeOtpFileName(t: string): string; override := t;
    
    protected procedure WriteInvokeHeader(settings: MethodSettings); override;
    begin
      res_EIm += '    protected function InvokeParams(enq_c: integer; o_const: boolean; g: CLTaskGlobalData; enq_evs: DoubleEventListList): ParamInvRes<';
      res_EIm += t;
      if generics.Count <> 0 then
      begin
        res_EIm += '<';
        res_EIm += generics.Select(g->g[0]).JoinToString(', ');
        res_EIm += '>';
      end;
      res_EIm += '>; override;'#10;
    end;
    
    protected procedure WriteCommandBaseTypeName(t: string; settings: MethodSettings); override;
    begin
      res_EIm += 'EnqueueableGPUCommand<';
      res_EIm += t;
      if generics.Count <> 0 then
      begin
        res_EIm += '<';
        res_EIm += generics.Select(g->g[0]).JoinToString(', ');
        res_EIm += '>';
      end;
      res_EIm += '>';
    end;
    
    protected procedure WriteMethodResT(l_res, l_res_E: Writer; settings: MethodSettings); override;
    begin
      l_res += t;
      l_res_E += 'CCQ';
      if generics.Count <> 0 then
      begin
        l_res += '<';
        l_res += generics.Select(g->g[0]).JoinToString(', ');
        l_res += '>';
      end;
    end;
    
  end;
  
begin
  try
    
    EnumerateDirectories(GetFullPathRTA('!Def\ContainerMethods\Other'))
    .TaskForEach(dir->
    begin
      var t := System.IO.Path.GetFileName(dir);
      
      var g := new MethodGenerator(t);
      foreach var fname in System.IO.Directory.EnumerateFiles(dir, '*.dat') do
        g.WriteMethodGroup(fname, System.IO.Path.GetFileNameWithoutExtension(fname));
      
      g.Close;
      Otp($'Packed other methods for [{t}]');
    end)
    .SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.