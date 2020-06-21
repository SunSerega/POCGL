uses MiscUtils  in '..\..\..\Utils\MiscUtils';
uses Fixers     in '..\..\..\Utils\Fixers';
{$string_nullbased+}

uses System.IO;

type
  Writer = abstract class
    
    procedure Write(l: string); abstract;
    static procedure operator+=(wr: Writer; l: string) := wr.Write(l);
    
    procedure Close; abstract;
    
  end;
  FileWriter = sealed class(Writer)
    sw: StreamWriter;
    
    constructor(fname: string) :=
    sw := new StreamWriter(fname, false, enc);
    
    procedure Write(l: string); override := sw.Write(l);
    
    procedure Close; override := sw.Close;
    
  end;
  WriterWrapper = sealed class(Writer)
    base: Writer;
    f: string->string;
    
    constructor(base: Writer; f: string->string);
    begin
      self.base := base;
      self.f := f;
    end;
    
    procedure Write(l: string); override := base.Write(f(l));
    
    procedure Close; override := base.Close;
    
  end;
  WriterArr = sealed class(Writer)
    base: array of Writer;
    
    constructor(params base: array of Writer) :=
    self.base := base;
    
    procedure Write(l: string); override :=
    foreach var wr in base do wr.Write(l);
    
    procedure Close; override :=
    foreach var wr in base do wr.Close;
    
  end;
  
begin
  try
    
    System.IO.Directory.EnumerateDirectories(GetFullPathRTE('MethodDef'))
    .Select(dir->ProcTask(()->
    begin
      var t := System.IO.Path.GetFileNameWithoutExtension(dir);
      
      var res_IIn := new FileWriter(GetFullPathRTE($'{t}Methods.Implicit.Interface.template'));
      var res_IIm := new FileWriter(GetFullPathRTE($'{t}Methods.Implicit.Implementation.template'));
      var res_EIn := new FileWriter(GetFullPathRTE($'{t}Methods.Explicit.Interface.template'));
      var res_EIm := new FileWriter(GetFullPathRTE($'{t}Methods.Explicit.Implementation.template'));
      
      var res_In := new WriterArr(res_IIn, res_EIn);
      var res_Im := new WriterArr(res_IIm, res_EIm);
      
      var res_I := new WriterArr(res_IIn, res_IIm);
      var res_E := new WriterArr(res_EIn, res_EIm);
      
      var res := new WriterArr(res_I, res_E);
      
      loop 3 do
      begin
        res_In += '    ';
        res += #10;
      end;
      foreach var fname in System.IO.Directory.EnumerateFiles(dir, '*.dat') do
      begin
        var reg_name := System.IO.Path.GetFileNameWithoutExtension(fname);
        
        res_In += '    ';
        res += $'{{$region {reg_name}}}'+#10;
        res_In += '    ';
        res += #10;
        
        foreach var bl in FixerUtils.ReadBlocks(fname, false) do
        begin
          var name_separator_ind := bl[0].IndexOf('!');
          var fn := name_separator_ind=-1 ? bl[0] : bl[0].Remove(name_separator_ind);
          var tn := name_separator_ind=-1 ? bl[0] : bl[0].Remove(name_separator_ind,1);
          
          var args_str: string := nil;
          
          var def: sequence of string := nil;
          var is_short_def: boolean;
          
          var need_thread := false;
          foreach var setting in FixerUtils.ReadBlocks(bl[1], '!', false) do
            if setting[0] = nil then
              args_str := setting[1].Single else
            case setting[0] of
              
              'ShortDef':
              begin
                if def<>nil then raise new System.InvalidOperationException($'{tn}({args_str})');
                def := setting[1];
                is_short_def := true;
              end;
              
              'Enqueue':
              begin
                if def<>nil then raise new System.InvalidOperationException($'{tn}({args_str})');
                def := setting[1];
                is_short_def := false;
              end;
              
              'NeedThread': need_thread := true;
              
              else raise new System.InvalidOperationException(setting[0]);
            end;
          
          if args_str=nil then raise new System.NullReferenceException($'{tn}({args_str})');
          if def=nil then raise new System.InvalidOperationException($'{tn}({args_str})');
          
          var generics := new HashSet<string>;
          var where_record := new HashSet<string>;
          
          // array of (name, type)
          var args := args_str.Split(';').SelectMany(arg_str->
          begin
            var ind := arg_str.IndexOf(':=');
            if ind<>-1 then arg_str := arg_str.Remove(ind);
            ind := arg_str.IndexOf(':');
            var arg_type := arg_str.SubString(ind+1).Trim;
            
            Result := arg_str.Remove(ind).Split(',').ConvertAll(arg_name->(arg_name.Trim, arg_type));
            
            while true do
              if arg_type.StartsWith('CommandQueue<') then
                arg_type := arg_type.SubString('CommandQueue<'.Length, arg_type.Length-'CommandQueue<'.Length-1) else
              if arg_type.StartsWith('array of ') then
                arg_type := arg_type.SubString('array of '.Length) else
              if arg_type.StartsWith('array[') then
                arg_type := arg_type.Skip('array['.Length).SkipWhile(ch->ch in [',',']',' ']).Skip('of'.Length).SkipWhile(ch->ch=' ').JoinToString else
                break;
            
            ind := 0;
            while (ind<>arg_type.Length) and arg_type[ind].IsLetter do ind += 1;
            if arg_type.Skip(ind).All(ch->ch.IsDigit) then
              case arg_type.SubString(0, ind) of
                'T'+'': generics += arg_type;
                'TRecord':
                begin
                  generics += arg_type;
                  where_record += arg_type;
                end;
              end;
            
          end).ToArray;
          var max_arg_w := args.Max(arg->arg[0].Length);
          
          var arg_usage := new Dictionary<string, string>;
          def := def.Select(l->
          begin
            var sb := new StringBuilder;
            
            foreach var arg_t in FixerUtils.FindTemplateInsertions(l, '!', '!') do
              if arg_t[0] then
              begin
                var arg := arg_t[1];
                var usage: string := nil;
                var ind := arg.IndexOf(':');
                if ind<>-1 then
                begin
                  usage := arg.Remove(0,ind+1);
                  arg := arg.Remove(ind);
                end;
                case arg of
                  
                  'evs': sb += 'evs.count, evs.evs, res';
                  
                  else
                  begin
                    if arg_usage.ContainsKey(arg) and (arg_usage[arg]<>usage) then
                      raise new System.NotSupportedException;
                    arg_usage[arg] := usage;
                    
                    sb += arg;
                    if usage<>nil then
                    case usage of
                      
                      'ptr': if args.Single(arg_t->arg_t[0]=arg)[1].Contains('CommandQueue<') then sb += '.GetPtr';
                      
                      else raise new System.InvalidOperationException;
                    end;
                    
                  end;
                end;
              end else
                sb += arg_t[1];
            
            Result := sb.ToString;
          end).ToArray;
          
          var generics_str :=     generics    .Count=0 ? '' : Concat('<',generics.JoinToString(', '),'>');
          var where_record_str := where_record.Count=0 ? '' : Concat('where ',where_record.JoinToString(', '),': record;');
          
          {$region CommandType}
          
          if not is_short_def then
          begin
            res_EIm += $'{{$region {tn}}}'+#10;
            res_EIm += #10;
            
            res_EIm += 'type'#10;
            
            res_EIm += '  ';
            res_EIm += t;
            res_EIm += 'Command';
            res_EIm += tn;
            res_EIm += generics_str;
            res_EIm += ' = sealed class(EnqueueableGPUCommand<';
            res_EIm += t;
            res_EIm += '>)'#10;
            
            if where_record.Count<>0 then
            begin
              res_EIm += '  ';
              res_EIm += where_record_str;
              res_EIm += #10;
            end;
            
            var ptr_args := new HashSet<string>;
            foreach var arg in args do
            begin
              var is_ptr := (arg_usage[arg[0]]='ptr') and not arg[1].Contains('CommandQueue<');
              if is_ptr then ptr_args += arg[0];
              
              res_EIm += '    private ';
              res_EIm += arg[0].PadLeft(max_arg_w);
              res_EIm += ': ';
              if is_ptr then
              begin
                res_EIm += '^';
                res_EIm += arg[1];
                res_EIm += ' := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<';
                res_EIm += arg[1];
                res_EIm += '>))';
              end else
                res_EIm += arg[1];
              res_EIm += ';'#10;
              
            end;
            
            res_EIm += '    '#10;
            
            if ptr_args.Count<>0 then
            begin
              res_EIm += '    protected procedure Finalize; override;'#10;
              res_EIm += '    begin'#10;
              
              var max_ptr_arg_w := ptr_args.Max(arg->arg.Length);
              foreach var arg in ptr_args do
              begin
                res_EIm += '      Marshal.FreeHGlobal(new IntPtr(';
                res_EIm += arg.PadLeft(max_ptr_arg_w);
                res_EIm += '));'#10;
              end;
              
              res_EIm += '    end;'#10;
              res_EIm += '    '#10;
            end;
            
            if need_thread then
            begin
              res_EIm += '    protected function NeedThread: boolean; override := true;'#10;
              res_EIm += '    '#10;
            end;
            
            res_EIm += '    public constructor(';
            res_EIm += args_str;
            res_EIm += ');'#10;
            res_EIm += '    begin'#10;
            foreach var arg in args do
            begin
              res_EIm += '      self.';
              res_EIm += arg[0].PadLeft(max_arg_w);
              if arg[0] in ptr_args then
                res_EIm += '^' else
              if ptr_args.Count<>0 then
                res_EIm += ' ';
              res_EIm += ' := ';
              res_EIm += arg[0].PadLeft(max_arg_w);
              res_EIm += ';'#10;
            end;
            res_EIm += '    end;'#10;
            
            res_EIm += '    '#10;
            
            res_EIm += '    protected function InvokeParams(tsk: CLTaskBase; c: Context; main_dvc: cl_device_id; var cq: cl_command_queue; evs_l1, evs_l2: List<EventList>): (';
            res_EIm += t;
            res_EIm += ', cl_command_queue, CLTaskBase, EventList)->cl_event; override;'#10;
            res_EIm += '    begin'#10;
            
            var first_arg := true;
            foreach var arg in args do
              if not arg_usage.ContainsKey(arg[0]) then
                Otp($'WARNING: arg [{arg[0]}] is defined for {fn}({args_str}), but never used') else
              begin
                var tname := arg[1];
                var arr_c := 0;
                while tname.StartsWith('array of ') do
                begin
                  arr_c += 1;
                  tname := tname.SubString('array of '.Length);
                end;
                
                if arg[1].StartsWith('CommandQueue<') then
                begin
                  res_EIm += '      var ';
                  res_EIm += arg[0].PadLeft(max_arg_w);
                  res_EIm += '_qr := ';
                  res_EIm += arg[0].PadLeft(max_arg_w);
                  
                  for var i := 1 to arr_c do
                  begin
                    res_EIm += '.ConvertAll(temp';
                    res_EIm += i.ToString;
                    res_EIm += '->temp';
                    res_EIm += i.ToString;
                  end;
                  
                  res_EIm += '.Invoke';
                  res_EIm += first_arg ? '    ' : 'NewQ';
                  res_EIm += '(tsk, c, main_dvc, ';
                  res_EIm += (arg_usage[arg[0]]='ptr').ToString.PadLeft(5);
                  res_EIm += ', ';
                  res_EIm += first_arg ? 'cq, ' : '    ';
                  res_EIm += 'nil)';
                  
                  loop arr_c do res_EIm += ')';
                  res_EIm += '; ';
                  
                  res_EIm += 'evs_l';
                  res_EIm += arg_usage[arg[0]]='ptr' ? '2' : '1';
                  res_EIm += ' += ';
                  res_EIm += arg[0].PadLeft(max_arg_w);
                  res_EIm += '_qr.ev;'#10;
                  
                  first_arg := false;
                end;
                
              end;
            
            res_EIm += '      '#10;
            
            res_EIm += '      Result := (o, cq, tsk, evs)->'#10;
            res_EIm += '      begin'#10;
            
            var args_with_GCHandle := new List<string>;
            foreach var arg in args do
              if arg_usage.ContainsKey(arg[0]) then
              begin
                var tname := arg[1];
                var arr_c := 0;
                while tname.StartsWith('array of ') do
                begin
                  arr_c += 1;
                  tname := tname.SubString('array of '.Length);
                end;
                
                if not tname.StartsWith('CommandQueue<') then continue;
                
                res_EIm += '        var ';
                res_EIm += arg[0].PadLeft(max_arg_w);
                
                var usage := arg_usage[arg[0]];
                if usage=nil then
                begin
                  res_EIm += ' := ';
                  res_EIm += arg[0].PadLeft(max_arg_w);
                  res_EIm += '_qr.GetRes;'#10;
                end else
                case usage of
                  
                  'ptr':
                  begin
                    res_EIm += ' := ';
                    res_EIm += arg[0].PadLeft(max_arg_w);
                    res_EIm += '_qr.ToPtr;'#10;
                    if not need_thread then args_with_GCHandle += arg[0];
                  end;
                  
                  else raise new System.NotImplementedException;
                end;
                
              end;
            res_EIm += '        '#10;
            
            res_EIm += '        var res: cl_event;'#10;
            res_EIm += '        '#10;
            
            foreach var l in def do
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
            
            res_EIm += '        Result := res;'#10;
            res_EIm += '      end;'#10;
            
            res_EIm += '      '#10;
            
            res_EIm += '    end;'#10;
            
            res_EIm += '    '#10;
            
            res_EIm += '    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override;'#10;
            res_EIm += '    begin'#10;
            foreach var arg in args do
            begin
              var tname := arg[1];
              var arr_c := 0;
              while tname.StartsWith('array of ') do
              begin
                arr_c += 1;
                tname := tname.SubString('array of '.Length);
              end;
              
              if tname.StartsWith('CommandQueue<') then
              begin
                res_EIm += '      ';
                
                var vname := arg[0];
                for var i := 1 to arr_c do
                begin
                  var nvname := $'temp{i}';
                  res_EIm += 'foreach var ';
                  res_EIm += nvname;
                  res_EIm += ' in ';
                  res_EIm += vname;
                  res_EIm += ' do ';
                  vname := nvname;
                end;
                
                res_EIm += arr_c=0 ? vname.PadLeft(max_arg_w) : vname;
                res_EIm += '.RegisterWaitables(tsk, prev_hubs);'#10;
              end;
              
            end;
            res_EIm += '    end;'#10;
            
            res_EIm += '    '#10;
            
            res_EIm += '  end;'#10;
            res_EIm += '  '#10;
            
            res_EIm += $'{{$endregion {tn}}}'+#10;
            res_EIm += #10;
            
          end;
          
          {$endregion CommandType}
          
          res_In += '    public ';
          res += 'function ';
          res_Im += t;
          res_EIm += 'CommandQueue';
          res_Im += '.';
          res_E += 'Add';
          res += fn;
          res += generics_str;
          res += '(';
          res += args_str;
          res += '): ';
          res += t;
          res_E += 'CommandQueue';
          res_In += '; ';
          res_Im += ' :=';
          if where_record.Count<>0 then
            res_In += where_record_str;
          res += #10;
          
          if is_short_def then
          begin
            res_EIm += 'Add';
            res_Im += def.Single;
            res_Im += #10;
          end else
          begin
            
            res_IIm += 'Context.Default.SyncInvoke(self.NewQueue.Add';
            res_IIm += fn;
            res_IIm += '(';
            res_IIm += args.Select(arg->arg[0]).JoinToString(', ');
            res_IIm += ') as CommandQueue<';
            res_IIm += t;
            res_IIm += '>);'#10;
            
            res_EIm += 'AddCommand(new ';
            res_EIm += t;
            res_EIm += 'Command';
            res_EIm += tn;
            res_EIm += generics_str;
            res_EIm += '(';
            res_EIm += args.Select(arg->arg[0]).JoinToString(', ');
            res_EIm += '));'#10;
            
          end;
          
          res_In += '    ';
          res += #10;
        end;
        
        res_In += '    ';
        res += $'{{$endregion {reg_name}}}'+#10;
        res_In += '    ';
        res += #10;
        
      end;
      res_In += '    ';
      res += #10;
      res_In += '    ';
      
      res.Close;
      Otp($'Packed methods for [{t}]');
    end))
    .CombineAsyncTask
    .SyncExec;
    
    if not is_secondary_proc then Otp('Done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.