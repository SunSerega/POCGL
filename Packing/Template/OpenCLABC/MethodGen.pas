uses MiscUtils    in '..\..\..\Utils\MiscUtils';
uses MethodGenData;
{$string_nullbased+}

type
  MethodSettings = sealed class(MethodGenData.MethodSettings) end;
  MethodGenerator = sealed class(MethodGenData.MethodGenerator<MethodSettings>)
    
    protected function MakeOtpFileName(t: string): string; override := $'{t}Methods';
    
    protected procedure WriteCommandBaseTypeName(t: string; settings: MethodSettings); override;
    begin
      res_EIm += 'EnqueueableGPUCommand<';
      res_EIm += t;
      res_EIm += '>';
    end;
    
    protected procedure WriteCommandTypeInvoke(fn: string; max_arg_w: integer; settings: MethodSettings); override;
    begin
      res_EIm += '    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (';
      res_EIm += t;
      res_EIm += ', cl_command_queue, CLTaskBase, Context, EventList)->cl_event; override;'#10;
      res_EIm += '    begin'#10;
      
      var first_arg := true;
      foreach var arg in settings.args do
        if not settings.arg_usage.ContainsKey(arg.name) then
          Otp($'WARNING: arg [{arg.name}] is defined for {fn}({settings.args_str}), but never used') else
        begin
          
          if arg.t.IsCQ then
          begin
            res_EIm += '      var ';
            res_EIm += arg.name.PadLeft(max_arg_w);
            res_EIm += '_qr := ';
            
            var arg_name := arg.name.PadLeft(max_arg_w);
            for var i := 1 to arg.t.ArrLvl do
            begin
              var n_arg_name := $'temp{i}';
              
              res_EIm += arg_name;
              res_EIm += '.ConvertAll(';
              res_EIm += n_arg_name;
              res_EIm += '->';
              
              arg_name := n_arg_name;
            end;
            
            if arg.t is MethodArgTypeArray then res_EIm += 'begin Result := ';
            
            res_EIm += arg_name;
            res_EIm += '.Invoke';
            res_EIm += first_arg ? '    ' : 'NewQ';
            res_EIm += '(tsk, c, main_dvc, ';
            res_EIm += (settings.arg_usage[arg.name]='ptr').ToString.PadLeft(5);
            res_EIm += ', ';
            res_EIm += first_arg ? 'cq, ' : arg.t is MethodArgTypeArray ? nil : '    ';
            res_EIm += 'nil); ';
            
            res_EIm += 'evs_l';
            res_EIm += settings.arg_usage[arg.name]='ptr' ? '2' : '1';
            res_EIm += ' += ';
            if arg.t is MethodArgTypeArray then
              res_EIm += 'Result' else
            begin
              res_EIm += arg.name.PadLeft(max_arg_w);
              res_EIm += '_qr';
            end;
            res_EIm += '.ev';
            
            if arg.t is MethodArgTypeArray then res_EIm += '; end';
            loop arg.t.ArrLvl do res_EIm += ')';
            res_EIm += ';'#10;
            
            first_arg := false;
          end;
          
        end;
      
      res_EIm += '      '#10;
      
      res_EIm += '      Result := (o, cq, tsk, c, evs)->'#10;
      res_EIm += '      begin'#10;
      
      var args_with_GCHandle := new List<string>;
      foreach var arg in settings.args do
        if settings.arg_usage.ContainsKey(arg.name) then
        begin
          if not arg.t.IsCQ then continue;
          
          res_EIm += '        var ';
          res_EIm += arg.name.PadLeft(max_arg_w);
          res_EIm += ' := ';
          res_EIm += arg.name.PadLeft(max_arg_w);
          res_EIm += '_qr';
          
          for var i := 1 to arg.t.ArrLvl do
          begin
            res_EIm += '.ConvertAll(temp';
            res_EIm += i.ToString;
            res_EIm += '->temp';
            res_EIm += i.ToString;
          end;
          
          var usage := settings.arg_usage[arg.name];
          if usage=nil then
            res_EIm += '.GetRes' else
          case usage of
            
            'ptr':
            begin
              res_EIm += '.ToPtr';
              if not settings.need_thread then args_with_GCHandle += arg.name;
            end;
            
            else raise new System.NotImplementedException;
          end;
          
          loop arg.t.ArrLvl do res_EIm += ')';
          res_EIm += ';'#10;
          
        end;
      res_EIm += '        '#10;
      
      if not settings.need_thread then
        res_EIm += '        var res: cl_event;'#10;
      res_EIm += '        '#10;
      
      foreach var l in settings.def do
      begin
        res_EIm += '        ';
        res_EIm += l;
        res_EIm += #10;
      end;
      
      res_EIm += '        '#10;
      
      if args_with_GCHandle.Count<>0 then
      begin
        
        var max_awg_w := args_with_GCHandle.Max(arg->arg.Length);
        foreach var arg in args_with_GCHandle do
        begin
          res_EIm += '        var ';
          res_EIm += arg.PadLeft(max_awg_w);
          res_EIm += '_hnd := GCHandle.Alloc(';
          res_EIm += arg.PadLeft(max_awg_w);
          res_EIm += ');'#10;
        end;
        res_EIm += '        '#10;
        
        res_EIm += '        EventList.AttachFinallyCallback(res, ()->'#10;
        res_EIm += '        begin'#10;
        foreach var arg in args_with_GCHandle do
        begin
          res_EIm += '          ';
          res_EIm += arg.PadLeft(max_awg_w);
          res_EIm += '_hnd.Free;'#10;
        end;
        res_EIm += '        end, tsk);'#10;
        res_EIm += '        '#10;
      end;
      
      res_EIm += '        Result := ';
      res_EIm += settings.need_thread ? 'cl_event.Zero' : 'res';
      res_EIm += ';'#10;
      res_EIm += '      end;'#10;
      
      res_EIm += '      '#10;
      
      res_EIm += '    end;'#10;
      
    end;
    
  end;
  
begin
  try
    
    EnumerateDirectories(GetFullPathRTE('MethodDef'))
    .Select(dir->ProcTask(()->
    begin
      var t := System.IO.Path.GetFileName(dir);
      var g := new MethodGenerator(t);
      g.Open;
      
      foreach var fname in System.IO.Directory.EnumerateFiles(dir, '*.dat') do
        g.WriteMethodGroup(fname, System.IO.Path.GetFileNameWithoutExtension(fname));
      
      g.Close;
      Otp($'Packed methods for [{t}]');
    end))
    .CombineAsyncTask
    .SyncExec;
    
    if not is_secondary_proc then Otp('Done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.