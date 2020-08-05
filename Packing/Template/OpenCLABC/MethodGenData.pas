unit MethodGenData;

uses MiscUtils    in '..\..\..\Utils\MiscUtils';
uses Fixers       in '..\..\..\Utils\Fixers';
uses CodeGenUtils in '..\CodeGenUtils';
{$string_nullbased+}

type
  Writer = Writer;
  
  {$region MethodArg}
  
  MethodArgType = abstract class
    public org_text: string;
    
    public function Enmr: sequence of MethodArgType; abstract;
    
    public static function FromString(s: string): MethodArgType;
    
  end;
  
  MethodArgTypeArray = sealed class(MethodArgType)
    public next: MethodArgType;
    public rank := 1;
    
    public function Enmr: sequence of MethodArgType; override;
    begin
      yield self;
      yield sequence next.Enmr;
    end;
    
    public constructor(s: string);
    begin
      org_text := s;
      
      var c := 'array'.Length;
      if s[c] = '[' then
      begin
        while s[c] <> ']' do
        begin
          if s[c] = ',' then rank += 1;
          c += 1;
        end;
        c += 1;
      end;
      
      while char.IsWhiteSpace(s[c]) do c += 1;
      c += 'of'.Length;
      
      next := MethodArgType.FromString(s.Substring(c));
    end;
    
  end;
  
  MethodArgTypeCQ = sealed class(MethodArgType)
    public next: MethodArgType;
    
    public function Enmr: sequence of MethodArgType; override;
    begin
      yield self;
      yield sequence next.Enmr;
    end;
    
    public constructor(s: string);
    const cq_def = 'CommandQueue<';
    begin
      org_text := s;
      
      next := MethodArgType.FromString(s.Substring(cq_def.Length, s.Length-cq_def.Length-1));
    end;
    
  end;
  
  MethodArgTypeKernelArg = sealed class(MethodArgType)
    
    public function Enmr: sequence of MethodArgType; override := new MethodArgType[](self);
    
    public constructor(s: string) := org_text := s;
    
  end;
  
  MethodArgTypeBasic = sealed class(MethodArgType)
    
    public function Enmr: sequence of MethodArgType; override := new MethodArgType[](self);
    
    public constructor(s: string) := org_text := s;
    
  end;
  
static function MethodArgType.FromString(s: string): MethodArgType;
begin
  s := s.Trim;
  
  if s.StartsWith('array') then
    Result := new MethodArgTypeArray(s) else
  if s.StartsWith('CommandQueue<') then
    Result := new MethodArgTypeCQ(s) else
  if s = 'KernelArg' then
    Result := new MethodArgTypeKernelArg(s) else
    Result := new MethodArgTypeBasic(s);
  
end;

function IsCQ(self: MethodArgType): boolean; extensionmethod :=
self.Enmr.OfType&<MethodArgTypeCQ>.Any;
function IsKA(self: MethodArgType): boolean; extensionmethod :=
self.Enmr.Last is MethodArgTypeKernelArg;

function ArrLvl(self: MethodArgType): integer; extensionmethod :=
self.Enmr.TakeWhile(at->at is MethodArgTypeArray).Count;

type
  MethodArg = sealed class
    public name: string;
    public t: MethodArgType;
    
    public constructor(name: string; t: MethodArgType);
    begin
      self.name := name;
      self.t := t;
    end;
    
    public static function AllFromString(l: string) :=
    l.Split(';').SelectMany(arg_str->
    begin
      arg_str := arg_str.Trim;
      if arg_str.StartsWith('params ') then arg_str := arg_str.Remove(0, 'params '.Length);
      var ind := arg_str.IndexOf(':=');
      if ind<>-1 then arg_str := arg_str.Remove(ind);
      
      ind := arg_str.IndexOf(':');
      if ind=-1 then raise new System.InvalidOperationException(arg_str);
      
      var arg_type := MethodArgType.FromString(arg_str.SubString(ind+1));
      Result := arg_str.Remove(ind).Split(',').ConvertAll(arg_name->new MethodArg(arg_name.Trim, arg_type));
    end);
    
  end;
  
  {$endregion MethodArg}
  
  {$region MethodSettings}
  
  MethodSettings = abstract class
    
    public args_str: string := nil;
    public args: array of MethodArg := nil;
    public arg_usage := new Dictionary<string, string>;
    
    public impl_args: List<string> := nil;
    public impl_args_str: string := nil;
    
    public def: sequence of string;
    public is_short_def: boolean;
    
    public need_thread := false;
    public implicit_only := false;
    
    public generics := new HashSet<string>;
    public where_record := new HashSet<string>;
    
    public generics_str: string := nil;
    public where_record_str: string := nil;
    
    public procedure Apply(setting_name: string; setting_lns: sequence of string; debug_tn: string); virtual :=
    match setting_name with
      
      nil: args_str := setting_lns.Single;
      
      'ShortDef':
      begin
        if def<>nil then raise new System.InvalidOperationException($'{debug_tn}({args_str})');
        def := setting_lns;
        is_short_def := true;
      end;
      
      'Enqueue':
      begin
        if def<>nil then raise new System.InvalidOperationException($'{debug_tn}({args_str})');
        def := setting_lns;
        is_short_def := false;
      end;
      
      'NeedThread': need_thread := true;
      'ImplicitOnly': implicit_only := true;
      
      else raise new System.InvalidOperationException(setting_name);
    end;
    
    protected procedure ProcessSpecialDefVar(sb: StringBuilder; arg_name, usage: string; debug_tn: string); virtual :=
    case arg_name of
      
      'evs':
      begin
        if usage<>nil then raise new System.NotSupportedException;
        sb += 'evs.count, evs.evs, ';
        sb += need_thread ? 'IntPtr.Zero' : 'res_ev';
      end;
      
      else
      begin
        if arg_usage.ContainsKey(arg_name) and (arg_usage[arg_name]<>usage) then
          raise new System.NotSupportedException($'arg [{arg_name}] in {debug_tn}({args_str}) had usages [{arg_usage[arg_name]}] and [{usage}]');
        
        //ToDo #?
        var arg := args=nil ? nil : args.SingleOrDefault(arg->arg.name=arg_name);
        if arg=nil then raise new System.InvalidOperationException($'arg [{arg_name}] not found in params of func {debug_tn}({args_str})');
        
        arg_usage[arg_name] := usage;
        
        sb += arg_name;
        if usage<>nil then
        case usage of
          
          'ptr': if args.Single(arg->arg.name=arg_name).t.IsCQ then sb += '.GetPtr';
          
          else raise new System.InvalidOperationException;
        end;
        
      end;
    end;
    private function ProcessDefLine(l: string; debug_tn: string): string;
    begin
      var sb := new StringBuilder;
      
      foreach var arg_t in FixerUtils.FindTemplateInsertions(l, '!', '!') do
        if arg_t[0] then
        begin
          var arg_name := arg_t[1];
          var usage: string := nil;
          begin
            var ind := arg_name.IndexOf(':');
            if ind<>-1 then
            begin
              usage := arg_name.Remove(0,ind+1);
              arg_name := arg_name.Remove(ind);
            end;
          end;
          
          ProcessSpecialDefVar(sb, arg_name, usage, debug_tn);
        end else
          sb += arg_t[1];
      
      Result := sb.ToString;
    end;
    
    protected function GetArgTNames: sequence of string; virtual :=
    args=nil? System.Array.Empty&<string> : args.Select(arg->arg.t.Enmr.Last.org_text);
    
    public procedure Seal(t: string; debug_tn: string); virtual;
    begin
      
      if def=nil then raise new System.InvalidOperationException($'{debug_tn}({args_str})');
      
      if implicit_only and need_thread then raise new System.NotSupportedException($'{debug_tn}({args_str})');
      if implicit_only and not is_short_def then raise new System.NotSupportedException($'{debug_tn}({args_str})');
      
      if args_str<>nil then
      begin
        impl_args_str := args_str;
        
        args := MethodArg.AllFromString(args_str).ToArray;
        impl_args := args.Select(arg->arg.name).ToList;
      end;
      
      foreach var arg_t in GetArgTNames do
      begin
        if not arg_t.StartsWith('T') then continue;
        
        if arg_t.StartsWith('TRecord') and arg_t.Skip('TRecord'.Length).All(ch->ch.IsDigit) then
          where_record += arg_t else
        if arg_t.Skip(1).All(ch->ch.IsDigit) then
          generics += arg_t;
        
      end;
      generics.UnionWith(where_record);
      
      if generics.Count<>0 then
      begin
        generics_str := Concat('<',generics.JoinToString(', '),'>');
        if where_record.Count<>0 then
          where_record_str := Concat('where ',where_record.JoinToString(', '),': record;');
      end;
      
      def := def.Select(l->ProcessDefLine(l, debug_tn)).ToArray;
      
    end;
    
  end;
  
  {$endregion MethodSettings}
  
  MethodGenerator<TSettings> = abstract class
  where TSettings: MethodSettings, constructor;
    
    protected res_IIn, res_IIm, res_EIn, res_EIm: Writer;
    protected res_In, res_Im: Writer;
    protected res_I, res_E: Writer;
    protected res: Writer;
    
    protected t: string;
    
    {$region Global}
    
    protected function MakeOtpFileName(t: string): string; abstract;
    
    public constructor(t: string);
    begin
      self.t := t;
      
      self.res_IIn := new FileWriter(GetFullPathRTE($'{MakeOtpFileName(t)}.Implicit.Interface.template'));
      self.res_IIm := new FileWriter(GetFullPathRTE($'{MakeOtpFileName(t)}.Implicit.Implementation.template'));
      self.res_EIn := new FileWriter(GetFullPathRTE($'{MakeOtpFileName(t)}.Explicit.Interface.template'));
      self.res_EIm := new FileWriter(GetFullPathRTE($'{MakeOtpFileName(t)}.Explicit.Implementation.template'));
      
      self.res_In := new WriterArr(res_IIn, res_EIn);
      self.res_Im := new WriterArr(res_IIm, res_EIm);
      
      self.res_I := new WriterArr(res_IIn, res_IIm);
      self.res_E := new WriterArr(res_EIn, res_EIm);
      
      self.res := new WriterArr(res_I, res_E);
      
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public procedure Open;
    begin
      
      loop 3 do
      begin
        res_In += '    ';
        res += #10;
      end;
      
    end;
    
    public procedure Close;
    begin
      
      res_In += '    ';
      res += #10;
      res_In += '    ';
      
      res.Close;
    end;
    
    {$endregion Global}
    
    protected procedure WriteInvokeHeader(settings: TSettings); abstract;
    protected procedure WriteInvokeFHeader; abstract;
    protected procedure AddGCHandleArgs(args_with_GCHandle: List<string>; settings: TSettings); virtual := exit;
    
    private procedure WriteCommandTypeInvoke(fn: string; max_arg_w: integer; settings: TSettings);
    begin
      WriteInvokeHeader(settings);
      res_EIm += '    begin'#10;
      
      if (settings as MethodSettings).args <> nil then
        foreach var arg in (settings as MethodSettings).args do
          if not (settings as MethodSettings).arg_usage.ContainsKey(arg.name) then
            Otp($'WARNING: arg [{arg.name}] is defined for {fn}({settings.args_str}), but never used');
      
      {$region param .Invoke's}
      
      if (settings as MethodSettings).args <> nil then
      begin
        var first_arg := true;
        foreach var arg in (settings as MethodSettings).args do
          if (settings as MethodSettings).arg_usage.ContainsKey(arg.name) then
          begin
            var IsCQ := arg.t.IsCQ;
            var IsKA := arg.t.IsKA;
            if IsCQ or IsKA then
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
              res_EIm += arg.t is MethodArgTypeArray ? nil : first_arg ? '    ' : 'NewQ';
              res_EIm += '(tsk, c, main_dvc';
              if IsCQ then
              begin
                res_EIm += ', ';
                res_EIm += ((settings as MethodSettings).arg_usage[arg.name]='ptr').ToString.PadLeft(5);
                res_EIm += ', ';
                res_EIm += first_arg ? 'cq, ' : arg.t is MethodArgTypeArray ? nil : '    ';
                res_EIm += 'nil';
              end;
              res_EIm += '); ';
              
              if (settings as MethodSettings).arg_usage[arg.name]='ptr' then
                res_EIm += $'({arg.name}_qr is QueueResDelayedPtr&<{arg.t.Enmr.Last.org_text}>?evs_l2:evs_l1)' else
                res_EIm += 'evs_l1';
              
              res_EIm += '.Add(';
              if arg.t is MethodArgTypeArray then
                res_EIm += 'Result' else
              begin
                res_EIm += arg.name;
                res_EIm += '_qr';
              end;
              res_EIm += '.ev)';
              
              if arg.t is MethodArgTypeArray then res_EIm += '; end';
              loop arg.t.ArrLvl do res_EIm += ')';
              res_EIm += ';'#10;
              
              if first_arg and IsCQ then first_arg := false;
            end;
          end;
      end;
      
      {$endregion param .Invoke's}
      
      res_EIm += '      '#10;
      
      res_EIm += '      Result := ';
      WriteInvokeFHeader;
      res_EIm += '      begin'#10;
      
      {$region param .GetRes's}
      
      var args_with_GCHandle := new List<string>;
      if (settings as MethodSettings).args <> nil then
        foreach var arg in (settings as MethodSettings).args do
          if (settings as MethodSettings).arg_usage.ContainsKey(arg.name) then
          begin
            var IsCQ := arg.t.IsCQ;
            var IsKA := arg.t.IsKA;
            if not IsCQ and not IsKA then continue;
            
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
            
            var usage := (settings as MethodSettings).arg_usage[arg.name];
            if usage=nil then
              res_EIm += '.GetRes' else
            case usage of
              
              'ptr':
              begin
                res_EIm += '.ToPtr';
                if not (settings as MethodSettings).need_thread then args_with_GCHandle += arg.name;
              end;
              
              else raise new System.NotImplementedException;
            end;
            
            loop arg.t.ArrLvl do res_EIm += ')';
            res_EIm += ';'#10;
            
          end;
      
      {$endregion param .GetRes's}
      
      if not (settings as MethodSettings).need_thread then
        res_EIm += '        var res_ev: cl_event;'#10;
      res_EIm += '        '#10;
      
      var tabs := 4;
      
      if (settings as MethodSettings).need_thread then
      begin
        res_EIm += '  '*tabs;
        res_EIm += 'try'#10;
        tabs += 1;
      end;
      
      foreach var l in (settings as MethodSettings).def do
      begin
        res_EIm += '  '*tabs;
        res_EIm += l;
        res_EIm += #10;
      end;
      
      if (settings as MethodSettings).need_thread then
      begin
        res_EIm += '        finally'#10;
        res_EIm += '          evs.Release({$ifdef EventDebug}$''after use in waiting of {self.GetType}''{$endif});'#10;
        res_EIm += '        end;'#10;
      end;
      
      res_EIm += '        '#10;
      
      {$region GCHandle.Free for PtrRes's}
      
      AddGCHandleArgs(args_with_GCHandle, settings);
      
      var max_awg_w := args_with_GCHandle.Select(arg->arg.Length).DefaultIfEmpty(0).Max;
      if args_with_GCHandle.Count<>0 then
      begin
        
        foreach var arg in args_with_GCHandle do
        begin
          res_EIm += '        var ';
          res_EIm += arg.PadLeft(max_awg_w);
          res_EIm += '_hnd := GCHandle.Alloc(';
          res_EIm += arg.PadLeft(max_awg_w);
          res_EIm += ');'#10;
        end;
        res_EIm += '        '#10;
        
      end;
      
      {$endregion GCHandle.Free for PtrRes's}
      
      {$region FinallyCallback}
      
      if (args_with_GCHandle.Count<>0) or not (settings as MethodSettings).need_thread then
      begin
        res_EIm += '        EventList.AttachFinallyCallback(res_ev, ()->'#10;
        res_EIm += '        begin'#10;
        
        if not (settings as MethodSettings).need_thread then
          res_EIm += '          evs.Release({$ifdef EventDebug}$''after use in waiting of {self.GetType}''{$endif});'#10;
        
        foreach var arg in args_with_GCHandle do
        begin
          res_EIm += '          ';
          res_EIm += arg.PadLeft(max_awg_w);
          res_EIm += '_hnd.Free;'#10;
        end;
        
        res_EIm += '        end, tsk, false{$ifdef EventDebug}, nil{$endif});'#10;
        res_EIm += '        '#10;
        
      end;
      
      {$endregion FinallyCallback}
      
      res_EIm += '        Result := ';
      res_EIm += (settings as MethodSettings).need_thread ? 'cl_event.Zero' : 'res_ev';
      res_EIm += ';'#10;
      res_EIm += '      end;'#10;
      
      res_EIm += '      '#10;
      
      res_EIm += '    end;'#10;
      
    end;
    
    protected procedure WriteCommandBaseTypeName(t: string; settings: TSettings); abstract;
    protected procedure WriteCommandTypeInhConstructor; virtual := exit;
    protected procedure WriteMiscMethods(settings: TSettings); virtual := exit;
    protected procedure WriteCommandType(fn, tn: string; settings: TSettings);
    begin
      res_EIm += '{$region ';
      res_EIm += tn;
      res_EIm += '}'#10;
      res_EIm += #10;
      
      res_EIm += 'type'#10;
      res_EIm += '  ';
      res_EIm += t;
      res_EIm += 'Command';
      res_EIm += tn;
      res_EIm += (settings as MethodSettings).generics_str;
      res_EIm += ' = sealed class(';
      WriteCommandBaseTypeName(t, settings);
      res_EIm += ')'#10;
      
      if (settings as MethodSettings).where_record_str<>nil then
      begin
        res_EIm += '  ';
        res_EIm += (settings as MethodSettings).where_record_str;
        res_EIm += #10;
      end;
      
      {$region field's}
      
      var max_arg_w := (settings as MethodSettings).args=nil ? 0 : (settings as MethodSettings).args.Max(arg->arg.name.Length);
      
      var val_ptr_args := new HashSet<string>;
      if (settings as MethodSettings).args<>nil then
        foreach var arg: MethodArg in (settings as MethodSettings).args do
          if (settings as MethodSettings).arg_usage.ContainsKey(arg.name) then
          begin
            var is_val_ptr := ((settings as MethodSettings).arg_usage[arg.name]='ptr') and not arg.t.IsCQ;
            if is_val_ptr then val_ptr_args += arg.name;
            
            res_EIm += '    private ';
            res_EIm += arg.name.PadLeft(max_arg_w);
            res_EIm += ': ';
            
            if is_val_ptr then
            begin
              res_EIm += '^';
              res_EIm += arg.t.org_text;
              res_EIm += ' := pointer(Marshal.AllocHGlobal(Marshal.SizeOf&<';
              res_EIm += arg.t.org_text;
              res_EIm += '>))';
            end else
              res_EIm += arg.t.org_text;
            
            res_EIm += ';'#10;
          end;
      
      {$endregion field's}
      
      res_EIm += '    '#10;
      
      {$region Misc}
      
      if val_ptr_args.Count<>0 then
      begin
        res_EIm += '    protected procedure Finalize; override;'#10;
        res_EIm += '    begin'#10;
        
        var max_val_ptr_arg_w := val_ptr_args.Max(arg->arg.Length);
        foreach var arg_name in val_ptr_args do
        begin
          res_EIm += '      Marshal.FreeHGlobal(new IntPtr(';
          res_EIm += arg_name.PadLeft(max_val_ptr_arg_w);
          res_EIm += '));'#10;
        end;
        
        res_EIm += '    end;'#10;
        res_EIm += '    '#10;
      end;
      
      if (settings as MethodSettings).need_thread then
      begin
        res_EIm += '    protected function NeedThread: boolean; override := true;'#10;
        res_EIm += '    '#10;
      end;
      WriteMiscMethods(settings);
      
      var param_count_l1 := 0;
      var param_count_l2 := 0;
      if (settings as MethodSettings).args<>nil then
        foreach var arg in (settings as MethodSettings).args do
          if (settings as MethodSettings).arg_usage.ContainsKey(arg.name) then
          begin
            if not arg.t.IsCQ and not arg.t.IsKA then continue;
            
            if (settings as MethodSettings).arg_usage[arg.name] = 'ptr' then
              param_count_l2 += 1 else
              param_count_l1 += 1;
            
          end;
      // +param_count_l2, потому что, к примеру, .Cast может вернуть не QueueResDelayedPtr, даже при need_ptr_qr
      res_EIm += $'    protected function ParamCountL1: integer; override := {param_count_l1+param_count_l2};'+#10;
      res_EIm += $'    protected function ParamCountL2: integer; override := {param_count_l2};'+#10;
      
      res_EIm += '    '#10;
      
      {$endregion Misc}
      
      {$region constructor}
      
      res_EIm += '    public constructor';
      if (settings as MethodSettings).impl_args_str = nil then
        res_EIm += ' := exit;'#10 else
      begin
        res_EIm += '(';
        res_EIm += (settings as MethodSettings).impl_args_str;
        res_EIm += ');'#10;
        res_EIm += '    begin'#10;
        WriteCommandTypeInhConstructor;
        if (settings as MethodSettings).args <> nil then
          foreach var arg in (settings as MethodSettings).args do
          begin
            res_EIm += '      self.';
            res_EIm += arg.name.PadLeft(max_arg_w);
            
            if arg.name in val_ptr_args then
              res_EIm += '^' else
            if val_ptr_args.Count<>0 then
              res_EIm += ' ';
            
            res_EIm += ' := ';
            res_EIm += arg.name.PadLeft(max_arg_w);
            res_EIm += ';'#10;
          end;
        res_EIm += '    end;'#10;
        res_EIm += '    private constructor := raise new System.InvalidOperationException;'#10;
      end;
      
      {$endregion constructor}
      
      res_EIm += '    '#10;
      
      WriteCommandTypeInvoke(fn, max_arg_w, settings);
      
      res_EIm += '    '#10;
      
      {$region RegisterWaitables}
      
      res_EIm += '    protected procedure RegisterWaitables(tsk: CLTaskBase; prev_hubs: HashSet<MultiusableCommandQueueHubBase>); override';
      if (settings as MethodSettings).args = nil then
        res_EIm += ' := exit;'#10 else
      begin
        res_EIm += ';'#10;
        res_EIm += '    begin'#10;
        
        foreach var arg in (settings as MethodSettings).args.OrderBy(arg->arg.t.ArrLvl) do
          if arg.t.IsKA or arg.t.IsCQ then
          begin
            res_EIm += '      ';
            
            var vname := arg.name;
            for var i := 1 to arg.t.ArrLvl do
            begin
              var nvname := $'temp{i}';
              res_EIm += 'foreach var ';
              res_EIm += nvname;
              res_EIm += ' in ';
              res_EIm += vname;
              res_EIm += ' do ';
              vname := nvname;
            end;
            
            res_EIm += arg.t is MethodArgTypeArray ? vname : vname.PadLeft(max_arg_w);
            res_EIm += '.RegisterWaitables(tsk, prev_hubs);'#10;
          end;
        
        res_EIm += '    end;'#10;
      end;
      
      {$endregion RegisterWaitables}
      
      res_EIm += '    '#10;
      
      res_EIm += '  end;'#10;
      res_EIm += '  '#10;
      
      res_EIm += '{$endregion ';
      res_EIm += tn;
      res_EIm += '}'#10;
      res_EIm += #10;
    end;
    
    protected procedure WriteMethodResT(l_res, l_res_E: Writer; settings: TSettings); abstract;
    protected procedure WriteMethodEImBody(write_new_ct: Action0; settings: TSettings); abstract;
    protected function GetIImResT(settings: TSettings): string; virtual := t;
    public procedure WriteMethod(bl: (string, array of string));
    begin
      var name_separator_ind := bl[0].IndexOf('!');
      var fn := name_separator_ind=-1 ? bl[0] : bl[0].Remove(name_separator_ind);
      var tn := name_separator_ind=-1 ? bl[0] : bl[0].Remove(name_separator_ind,1);
      
      var settings := new TSettings;
      foreach var setting in FixerUtils.ReadBlocks(bl[1], '!', false) do
        settings.Apply(setting[0], setting[1], tn);
      settings.Seal(t, tn);
      
      //ToDo #?
      // - и ещё в куче мест убрать "as MethodSettings"
      if not (settings as MethodSettings).is_short_def then
        WriteCommandType(fn, tn, settings);
      
      {$region Header}
      
      begin
        var l_res_EIm := (settings as MethodSettings).implicit_only ? new WriterEmpty  : res_EIm;
        
        var l_res_In  := (settings as MethodSettings).implicit_only ? res_IIn          : res_In;
        var l_res_Im  := (settings as MethodSettings).implicit_only ? res_IIm          : res_Im;
        
        var l_res_E   := (settings as MethodSettings).implicit_only ? new WriterEmpty  : res_E;
        
        var l_res     := (settings as MethodSettings).implicit_only ? res_I            : res;
        
        l_res_In += '    public ';
        l_res += 'function ';
        l_res_Im += t;
        l_res_EIm += 'CommandQueue';
        l_res_Im += '.';
        l_res_E += 'Add';
        l_res += fn;
        l_res += (settings as MethodSettings).generics_str;
        if (settings as MethodSettings).args_str <> nil then
        begin
          l_res += '(';
          l_res += (settings as MethodSettings).args_str;
          l_res += ')';
        end;
        l_res += ': ';
        WriteMethodResT(l_res, l_res_E, settings);
        l_res_In += ';';
        if (settings as MethodSettings).where_record_str<>nil then
        begin
          l_res_In += ' ';
          l_res_In += (settings as MethodSettings).where_record_str;
        end;
        l_res_Im += ' :=';
        l_res += #10;
        
      end;
      
      {$endregion Header}
      
      {$region Body}
      
      if (settings as MethodSettings).is_short_def then
      begin
        var l_res_Im  := (settings as MethodSettings).implicit_only ? res_IIm          : res_Im;
        var l_res_EIm := (settings as MethodSettings).implicit_only ? new WriterEmpty  : res_EIm;
        
        l_res_EIm += 'Add';
        l_res_Im += (settings as MethodSettings).def.Single;
        l_res_Im += #10;
        
      end else
      begin
        
        res_IIm += 'Context.Default.SyncInvoke(self.NewQueue.Add';
        res_IIm += fn;
        if (settings as MethodSettings).generics_str <> nil then
        begin
          res_IIm += '&';
          res_IIm += (settings as MethodSettings).generics_str;
        end;
        if (settings as MethodSettings).args<>nil then
        begin
          res_IIm += '(';
          res_IIm += (settings as MethodSettings).args.Select(arg->arg.name).JoinToString(', ');
          res_IIm += ')';
        end;
        res_IIm += ' as CommandQueue<';
        res_IIm += GetIImResT(settings);
        res_IIm += '>);'#10;
        
        //ToDo #2278
        var temp_res_EIm := res_EIm;
        var temp_t := t;
        
        WriteMethodEImBody(()->
        begin
          temp_res_EIm += 'new ';
          temp_res_EIm += temp_t;
          temp_res_EIm += 'Command';
          temp_res_EIm += tn;
          temp_res_EIm += (settings as MethodSettings).generics_str;
          if (settings as MethodSettings).impl_args<>nil then
          begin
            temp_res_EIm += '(';
            temp_res_EIm += (settings as MethodSettings).impl_args.JoinToString(', ');
            temp_res_EIm += ')';
          end;
        end, settings);
        
      end;
      
      {$endregion Body}
      
      res_In += '    ';
      res += #10;
      
    end;
    
    public procedure WriteMethodGroup(fname, nick: string);
    begin
      
      res_In += '    ';
      res += '{$region ';
      res += nick;
      res += '}'#10;
      res_In += '    ';
      res += #10;
      
      foreach var bl in FixerUtils.ReadBlocks(fname, false) do
        WriteMethod(bl);
      
      res_In += '    ';
      res += '{$endregion ';
      res += nick;
      res += '}'#10;
      res_In += '    ';
      res += #10;
      
    end;
    
  end;
  
end.