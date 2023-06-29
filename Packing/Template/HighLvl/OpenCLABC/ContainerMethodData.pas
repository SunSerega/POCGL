unit ContainerMethodData;

uses '../../../../Utils/CodeGen';
uses '../../../../POCGL_Utils';
uses '../../../../Utils/Fixers';

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
  
  MethodArgTypeGeneric = sealed class(MethodArgType)
    public name: string;
    public next: MethodArgType;
    
    public function Enmr: sequence of MethodArgType; override;
    begin
      yield self;
      yield sequence next.Enmr;
    end;
    
    public constructor(s: string);
    begin
      org_text := s;
      
      var ind1 := s.IndexOf('<');
      var ind2 := s.LastIndexOf('>');
      self.name := s.Remove(ind1);
      ind1 += 1;
      self.next := MethodArgType.FromString(s.Substring(ind1, ind2-ind1));
      if ind2<>s.Length-1 then raise new System.NotSupportedException;
      
    end;
    
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
  if '<' in s then
    Result := new MethodArgTypeGeneric(s) else
    Result := new MethodArgTypeBasic(s);
  
end;

function IsCQ(self: MethodArgType): boolean; extensionmethod :=
self.Enmr.OfType&<MethodArgTypeCQ>.Any;

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
  
  {$region MethodArgEvCount}
  
  MethodArgEvCount = sealed class
    arg: MethodArg;
    conv := new List<boolean>; // need_cast
    
    constructor(arg: MethodArg);
    begin
      self.arg := arg;
      var t := arg.t;
      while true do
        if t is MethodArgTypeArray(var ta) then
        begin
          conv += ta.rank<>1;
          t := ta.next;
        end else
          break;
    end;
    
    static procedure WriteAll(wr: Writer; l: List<MethodArgEvCount>);
    begin
      var prev := false;
      
      begin
        var c := l.Count(ec->ec.conv.Count=0);
        if c<>0 then
        begin
          prev := true;
          wr += c.ToString;
        end;
      end;
      
      foreach var ec in l do
      begin
        if ec.conv.Count=0 then continue;
        if prev then wr += ' + ';
        prev := true;
        wr += ec.arg.name;
        var ta := ec.arg.t as MethodArgTypeArray;
        for var i := 0 to ec.conv.Count-2 do
        begin
          if ec.conv[i] then
          begin
            wr += '.Cast&<';
            wr += ta.org_text;
            wr += '>';
          end;
          ta := ta.next as MethodArgTypeArray;
          wr += '.Sum(temp';
          wr += i.ToString;
          wr += '->temp';
          wr += i.ToString;
        end;
        wr += '.Length';
        loop ec.conv.Count-1 do
          wr += ')';
      end;
      
      if not prev then wr += '0';
    end;
    
  end;
  
  {$endregion MethodArgEvCount}
  
  {$region MethodSettings}
  
  MethodSettings = abstract class
    
    public args_str: string := nil;
    public args: List<MethodArg> := nil;
    public arg_usage := new Dictionary<string, string>;
    
    public impl_args: List<string> := nil;
    public impl_args_str: string := nil;
    
    public def: sequence of string;
    public is_short_def: boolean;
    public callback_lines: sequence of string;
    
    public implicit_only := false;
    
    // generics метода
    public generics := new HashSet<string>;
    public where_record := new HashSet<string>;
    
    public generics_str: string := nil;
    public where_record_str: string := nil;
    
    public procedure Apply(setting_name: string; setting_lns: sequence of string; debug_tn: string); virtual :=
    match setting_name with
      
      nil:
      begin
        args_str := setting_lns.Single;
        impl_args_str := args_str;
        
        args := MethodArg.AllFromString(args_str).ToList;
        impl_args := args.ConvertAll(arg->arg.name).ToList;
      end;
      
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
      
      'ImplicitOnly': implicit_only := true;
      
      'AttachCallback': callback_lines := setting_lns;
      
      else raise new System.InvalidOperationException($'!{setting_name} in {debug_tn}');
    end;
    
    protected procedure ProcessSpecialDefVar(sb: StringBuilder; arg_name, usage: string; debug_tn: string); virtual :=
    case arg_name of
      
      'evs':
      begin
        if usage<>nil then raise new System.NotSupportedException;
        sb += 'evs.count, evs.evs, res_ev';
      end;
      
      else
      begin
        if arg_usage.ContainsKey(arg_name) and (arg_usage[arg_name]<>usage) then
          raise new System.NotSupportedException($'arg [{arg_name}] in {debug_tn}({args_str}) had usages [{arg_usage[arg_name]}] and [{usage}]');
        
        var arg := args?.SingleOrDefault(arg->arg.name=arg_name);
        if arg=nil then raise new System.InvalidOperationException($'arg [{arg_name}] not found in params of func {debug_tn}({args_str})');
        
        arg_usage[arg_name] := usage;
        
        match usage with
          
          nil: sb += arg_name;
          
          'ptr': if arg.t.IsCQ then
          begin
            sb += arg_name;
          end else
          begin
            sb += arg_name;
            sb += '.Pointer';
          end;
          
          'pinn': sb += arg_name; // array indeces defined in .dat file
          
          else if usage<>nil then raise new System.InvalidOperationException(usage);
        end;
        
      end;
    end;
    protected function ProcessDefLine(l: string; debug_tn: string): string;
    begin
      var sb := new StringBuilder;
      
      foreach var (is_arg, text) in FixerUtils.FindTemplateInsertions(l, '!', '!') do
        if not is_arg then
          sb *= text else
        begin
          var arg_name := text;
          var usage := default(string);
          begin
            var ind := arg_name.IndexOf(':');
            if not ind.IsInvalid then
            begin
              usage := text.TrimFirst(ind+1).TrimWhile(char.IsWhiteSpace).ToString;
              arg_name := arg_name.TakeFirst(ind);
            end;
          end;
          arg_name := arg_name.TrimWhile(char.IsWhiteSpace);
          
          ProcessSpecialDefVar(sb, arg_name.ToString, usage, debug_tn);
        end;
      
      Result := sb.ToString;
    end;
    
    protected function GetArgTNames: sequence of string; virtual :=
    args=nil? System.Array.Empty&<string> : args.Select(arg->arg.t.Enmr.Last.org_text);
    
    public procedure Seal(t: string; type_generics: sequence of string; debug_tn: string); virtual;
    begin
      
      if def=nil then raise new System.InvalidOperationException($'{debug_tn}({args_str})');
      
      if implicit_only and not is_short_def then raise new System.NotSupportedException($'{debug_tn}({args_str})');
      
      if (callback_lines<>nil) and is_short_def then raise new System.NotSupportedException($'{debug_tn}({args_str})');
      
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
    
    // generics типа
    protected generics := new List<(string,string)>;
    
    {$region Global}
    
    protected function MakeOtpFileName(t: string): string; abstract;
    
    public constructor(t: string);
    begin
      self.t := t;
      
      var dir := GetFullPathRTA($'ContainerMethods/{MakeOtpFileName(t)}');
      System.IO.Directory.CreateDirectory(dir);
      
      self.res_IIn := new FileWriter(GetFullPath('Implicit.Interface.template',       dir));
      self.res_IIm := new FileWriter(GetFullPath('Implicit.Implementation.template',  dir));
      self.res_EIn := new FileWriter(GetFullPath('Explicit.Interface.template',       dir));
      self.res_EIm := new FileWriter(GetFullPath('Explicit.Implementation.template',  dir));
      
      self.res_In := res_IIn * res_EIn;
      self.res_Im := res_IIm * res_EIm;
      
      self.res_I := res_IIn * res_IIm;
      self.res_E := res_EIn * res_EIm;
      
      self.res := res_I * res_E;
      
      loop 3 do
      begin
        res_In += '    ';
        res += #10;
      end;
      
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public procedure Close;
    begin
      
      res_In += '    ';
      res += #10;
      res_In += '    ';
      
      res.Close;
    end;
    
    {$endregion Global}
    
    protected procedure WriteInvokeHeader(settings: TSettings); abstract;
    protected procedure AddGCHandleArgs(args_keep_alive: List<string>; args_with_pinn: List<(string,string)>; settings: TSettings); virtual := exit;
    
    protected function GetSpecialInvokeResVars(settings: TSettings): sequence of MethodArg; virtual := new MethodArg[0];
    protected procedure WriteBasicInvokeRes(wr: Writer; arg: MethodArg; settings: TSettings); virtual := raise new System.InvalidOperationException;
    protected procedure WriteBasicArgInvoke(wr: Writer; arg: MethodArg; settings: TSettings); virtual := raise new System.InvalidOperationException;
    protected procedure WriteSpecialPreEnq(wr: Writer; settings: TSettings); virtual := exit;
    protected procedure WriteSpecialPostEnq(wr: Writer; settings: TSettings); virtual := exit;
    
    private procedure WriteParamInvokes(fn: string; max_arg_w: integer; settings: TSettings);
    begin
      //TODO #2654
      var invokeable_args :=
        settings.args?.&Where(arg->(settings as MethodSettings).arg_usage.ContainsKey(arg.name) and arg.t.IsCQ)
        .Concat(GetSpecialInvokeResVars(settings)).ToArray
      ?? System.Array.Empty&<MethodArg>;
      
      var any_val := invokeable_args.Any(arg->(settings as MethodSettings).arg_usage[arg.name]<>'ptr');
      if not any_val then
        res_EIm += '      Result.Item1 := new CLTaskErrHandlerEmpty;'#10;
      
      if invokeable_args.Length=0 then exit;
      
      {$region var *_qr: ...}
      
      foreach var arg in invokeable_args do
      begin
        res_EIm += '      var ';
        if arg.t is MethodArgTypeBasic then
        begin
          WriteBasicInvokeRes(res_EIm, arg, settings);
          res_EIm += ';'#10;
          continue;
        end;
        res_EIm += arg.name.PadLeft(max_arg_w);
        res_EIm += '_qr: ';
        
        var t := arg.t;
        while true do
          if t is MethodArgTypeArray(var ta) then
          begin
            res_EIm += 'array';
            if ta.rank<>1 then
            begin
              res_EIm += '[';
              loop ta.rank-1 do
                res_EIm += ',';
              res_EIm += ']';
            end;
            res_EIm += ' of ';
            t := ta.next;
          end else
            break;
        
        res_EIm += 'QueueRes';
        //TODO #2654
        if (settings as MethodSettings).arg_usage[arg.name]='ptr' then
          res_EIm += 'Ptr';
        res_EIm += '<';
        res_EIm += MethodArgTypeCQ(t).next.org_text;
        res_EIm += '>;'#10;
        
      end;
      res_EIm += '      '#10;
      
      {$endregion var *_qr: ...}
      
      {$region WriteArgInvoke}
      
      var WriteArgInvoke := procedure(arg: MethodArg; to_ptr: boolean)->
      begin
        //TODO #2654
        if to_ptr <> ((settings as MethodSettings).arg_usage[arg.name]='ptr') then exit;
        
        res_EIm += '        ';
        if arg.t is MethodArgTypeBasic then
        begin
          WriteBasicArgInvoke(res_EIm, arg, settings);
          exit;
        end;
        
        var res_EIm := res_EIm; //TODO #???? (issue с 3 переменными)
        
        res_EIm += arg.name.PadLeft(max_arg_w);
        res_EIm += '_qr := ';
        
        var arg_name := arg.name;
        var arr_lvl := arg.t.ArrLvl;
        for var i := 1 to arr_lvl do
        begin
          var n_arg_name := $'temp{i}';
          
          res_EIm += arg_name;
          res_EIm += '.ConvertAll(';
          res_EIm += n_arg_name;
          res_EIm += '->';
          
          arg_name := n_arg_name;
        end;
        
        res_EIm += 'invoker.InvokeBranch(';
        //TODO Вместо max_arg_w тут надо что то отдельное, потому что не все проходят это условие
        res_EIm += if arg.t.ArrLvl<>0 then arg_name else arg_name.PadLeft(max_arg_w);
        res_EIm += '.Invoke';
        res_EIm += to_ptr ? 'ToPtr' : 'ToAny';
        res_EIm += ').AddToEvLst(g, enq_evs, ';
        res_EIm += (not to_ptr).ToString;
        res_EIm += ')';
        
        loop arr_lvl do res_EIm += ')';
        res_EIm += ';'#10;
      end;
      
      {$endregion WriteArgInvoke}
      
      if any_val then
        res_EIm += '      var l1_err_handler: CLTaskErrHandler;'#10;
      
      // At least one branch, all full separated
      res_EIm += '      g.ParallelInvoke(nil, enq_c, invoker->'#10;
      res_EIm += '      begin'#10;
      
      foreach var arg in invokeable_args do
        WriteArgInvoke(arg, false);
      
      if any_val then
        res_EIm += '        l1_err_handler := invoker.GroupHandlers;'#10;
      
      foreach var arg in invokeable_args do
        WriteArgInvoke(arg, true);
      
      res_EIm += '      end);'#10;
      
      if any_val then
        res_EIm += '      Result.Item1 := l1_err_handler;'#10;
      
    end;
    
    private procedure WriteCommandTypeInvoke(fn: string; max_arg_w: integer; settings: TSettings);
    begin
      WriteInvokeHeader(settings);
      res_EIm += '    begin'#10;
      
      if settings.args <> nil then
        foreach var arg in settings.args do
          if not settings.arg_usage.ContainsKey(arg.name) then
            Otp($'WARNING: arg [{arg.name}] is defined for {fn}({settings.args_str}), but never used');
      
      WriteParamInvokes(fn, max_arg_w, settings);
      
      res_EIm += '      '#10;
      
      res_EIm += '      Result.Item2 := (o, cq, evs)->'#10;
      res_EIm += '      begin'#10;
      
      {$region param .GetRes's}
      
      var args_keep_alive := new List<string>;
      var args_with_pinn := new List<(string,string)>;
      if settings.args <> nil then
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
              res_EIm += '.GetResDirect' else
            case usage of
              
              'ptr':
              begin
                res_EIm += '.GetResPtrForRead';
                args_keep_alive += arg.name+'_qr';
              end;
              
              'pinn':
              begin
                res_EIm += '.GetResDirect';
                var pinn_name := arg.name;
                var t := arg.t;
                if t is MethodArgTypeCQ(var cqt) then t := cqt.next;
                if (t is MethodArgTypeGeneric(var gt)) and (gt.name = 'ArraySegment') then
                  pinn_name += '.Array' else
                if not (t is MethodArgTypeArray) then
                  raise new System.NotSupportedException(arg.name);
                args_with_pinn += (arg.name, pinn_name);
              end;
              
              else raise new System.NotImplementedException;
            end;
            
            loop arg.t.ArrLvl do res_EIm += ')';
            res_EIm += ';'#10;
            
          end;
      AddGCHandleArgs(args_keep_alive, args_with_pinn, settings);
      
      {$endregion param .GetRes's}
      
      WriteSpecialPreEnq(res_EIm, settings);
      
      {$region GCHandle for arrays}
      
      var max_awp_w := args_with_pinn.Select(\(arg_name, pinn_o)->arg_name.Length).DefaultIfEmpty(0).Max;
      if args_with_pinn.Count<>0 then
      begin
        
        foreach var (arg_name, pinn_o) in args_with_pinn do
        begin
          res_EIm += '        var ';
          res_EIm += arg_name.PadLeft(max_awp_w);
          res_EIm += '_hnd := GCHandle.Alloc(';
          res_EIm += pinn_o;
          res_EIm += ', GCHandleType.Pinned);'#10;
        end;
        res_EIm += '        '#10;
        
      end;
      
      {$endregion GCHandle for arrays}
      
      res_EIm += '        var res_ev: cl_event;'#10;
      res_EIm += '        '#10;
      
      foreach var l in settings.def do
      begin
        res_EIm += '  '*4;
        res_EIm += l;
        res_EIm += #10;
      end;
      res_EIm += '        '#10;
      
      WriteSpecialPostEnq(res_EIm, settings);
      
      res_EIm += '        Result := new DirectEnqRes(res_ev, ';
      
      {$region FinallyAction}
      
      if (args_keep_alive.Count<>0) or (args_with_pinn.Count<>0) or (settings.callback_lines<>nil) then
      begin
        res_EIm += 'c->'#10;
        res_EIm += '        begin'#10;
        
        if settings.callback_lines<>nil then foreach var l in settings.callback_lines do
        begin
          res_EIm += '          ';
          res_EIm += l;
          res_EIm += #10;
        end;
        
        var max_aka_w := args_keep_alive.Select(arg->arg.Length).DefaultIfEmpty(0).Max;
        foreach var arg in args_keep_alive do
        begin
          res_EIm += '          GC.KeepAlive(';
          res_EIm += arg.PadLeft(max_aka_w);
          res_EIm += ');'#10;
        end;
        
        foreach var (arg_name, pinn_o) in args_with_pinn do
        begin
          res_EIm += '          ';
          res_EIm += arg_name.PadLeft(max_awp_w);
          res_EIm += '_hnd.Free;'#10;
        end;
        
        res_EIm += '        end';
      end else
        res_EIm += 'nil';
      
      {$endregion FinallyAction}
      
      res_EIm += ');'#10;
      res_EIm += '      end;'#10;
      
      res_EIm += '      '#10;
      
      res_EIm += '    end;'#10;
      
    end;
    
    protected procedure WriteCommandBaseTypeName(t: string; settings: TSettings); abstract;
    protected procedure WriteCommandTypeInhConstructor; virtual := exit;
    protected function GetInitBeforeInvokeExtra: string; virtual := nil;
    protected procedure WriteBasicValueToString(wr: Writer; tab, vname: string; stored_as_ptr: boolean); virtual;
    begin
      res_EIm += tab;
      res_EIm += 'sb += '' '';'#10;
      
      res_EIm += tab;
      res_EIm += 'sb.Append(';
      res_EIm += vname;
      if stored_as_ptr then
        res_EIm += '.Value';
      res_EIm += ');'#10;
    end;
    protected procedure WriteCommandType(fn, tn: string; settings: TSettings);
    begin
      
      res_EIm += 'type'#10;
      res_EIm += '  ';
      res_EIm += t;
      res_EIm += 'Command';
      res_EIm += tn;
      if generics.Count+settings.generics.Count <> 0 then
      begin
        res_EIm += '<';
        res_EIm += generics.Select(g->g[0]).Concat(settings.generics).JoinToString(', ');
        res_EIm += '>';
      end;
      res_EIm += ' = sealed class(';
      WriteCommandBaseTypeName(t, settings);
      res_EIm += ')'#10;
      
      foreach var g in generics do
      begin
        if g[1]=nil then continue;
        res_EIm += '  where ';
        res_EIm += g[0];
        res_EIm += ': ';
        res_EIm += g[1];
        res_EIm += ';'#10
      end;
      if settings.where_record_str<>nil then
      begin
        res_EIm += '  ';
        res_EIm += settings.where_record_str;
        res_EIm += #10;
      end;
      
      {$region field's}
      
      var max_arg_w := settings.args=nil ? 0 : settings.args.Max(arg->arg.name.Length);
      
      var val_ptr_args := new HashSet<string>;
      if settings.args<>nil then
        foreach var arg: MethodArg in settings.args do
          if settings.arg_usage.ContainsKey(arg.name) then
          begin
            var is_val_ptr := (settings.arg_usage[arg.name]='ptr') and not arg.t.IsCQ;
            if is_val_ptr then val_ptr_args += arg.name;
            
            res_EIm += '    private ';
            res_EIm += arg.name.PadLeft(max_arg_w);
            
            if is_val_ptr then
            begin
              res_EIm += ' := new NativeValueArea<';
              res_EIm += arg.t.org_text;
              res_EIm += '>(true)';
            end else
            begin
              res_EIm += ': ';
              res_EIm += arg.t.org_text;
            end;
            
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
          res_EIm += '      ';
          res_EIm += arg_name.PadLeft(max_val_ptr_arg_w);
          res_EIm += '.Release;'#10;
        end;
        
        res_EIm += '    end;'#10;
        res_EIm += '    '#10;
      end;
      
      res_EIm += '    protected function ExpectedEnqCount: integer; override := ';
      begin
        var param_count := new List<MethodArgEvCount>;
        if settings.args<>nil then
          foreach var arg in settings.args do
            if settings.arg_usage.ContainsKey(arg.name) then
            begin
              if not arg.t.IsCQ then continue;
              param_count += new MethodArgEvCount(arg);
            end;
        MethodArgEvCount.WriteAll(res_EIm, param_count);
      end;
      res_EIm += ';'+#10;
      
      res_EIm += '    '#10;
      
      {$endregion Misc}
      
      {$region constructor}
      
      if settings.where_record.Count<>0 then
      begin
        res_EIm += '    static constructor;'#10;
        res_EIm += '    begin'#10;
        foreach var r in settings.where_record do
        begin
          res_EIm += '      BlittableHelper.RaiseIfBad(typeof(';
          res_EIm += r;
          res_EIm += '), ''%Err:Blittable:Source:';
          res_EIm += t;
          res_EIm += ':';
          res_EIm += tn;
          if settings.where_record.Count<>1 then
          begin
            res_EIm += ':';
            res_EIm += r;
          end;
          res_EIm += '%'');'#10;
        end;
        res_EIm += '    end;'#10;
      end;
      
      res_EIm += '    public constructor';
      if settings.impl_args_str = nil then
        res_EIm += ' := exit;'#10 else
      begin
        res_EIm += '(';
        res_EIm += settings.impl_args_str;
        res_EIm += ');'#10;
        res_EIm += '    begin'#10;
        WriteCommandTypeInhConstructor;
        if settings.args <> nil then
          foreach var arg in settings.args do
          begin
            res_EIm += '      self.';
            res_EIm += arg.name.PadLeft(max_arg_w);
            
            if arg.name in val_ptr_args then
              res_EIm += '.Value' else
            if val_ptr_args.Count<>0 then
              res_EIm += '      ';
            
            res_EIm += ' := ';
            res_EIm += arg.name.PadLeft(max_arg_w);
            res_EIm += ';'#10;
          end;
        res_EIm += '    end;'#10;
        res_EIm += '    private constructor := raise new System.InvalidOperationException;'#10;
      end;
      
      res_EIm += '    '#10;
      
      {$endregion constructor}
      
      {$region InitBeforeInvoke}
      
      var init_before_invoke_extra := GetInitBeforeInvokeExtra;
      res_EIm += '    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; prev_hubs: HashSet<IMultiusableCommandQueue>); override';
      if settings.args = nil then
      begin
        res_EIm += ' := ';
        res_EIm += init_before_invoke_extra ?? 'exit';
        res_EIm += ';'#10;
      end else
      begin
        res_EIm += ';'#10;
        res_EIm += '    begin'#10;
        
        if init_before_invoke_extra<>nil then
        begin
          res_EIm += '      ';
          res_EIm += init_before_invoke_extra;
          res_EIm += ';'#10;
        end;
        
        foreach var arg in settings.args.OrderBy(arg->arg.t.ArrLvl) do
          if arg.t.IsCQ then
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
            res_EIm += '.InitBeforeInvoke(g, prev_hubs);'#10;
          end;
        
        res_EIm += '    end;'#10;
      end;
      
      res_EIm += '    '#10;
      
      {$endregion InitBeforeInvoke}
      
      WriteCommandTypeInvoke(fn, max_arg_w, settings);
      res_EIm += '    '#10;
      
      {$region ToStringImpl}
      
      res_EIm += '    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override';
      if settings.args = nil then
        res_EIm += ' := sb += #10;'#10 else
      begin
        res_EIm += ';'#10;
        res_EIm += '    begin'#10;
        res_EIm += '      sb += #10;'#10;
        res_EIm += '      '#10;
        
        foreach var arg in MethodSettings(settings).args do
        begin
          var vname := arg.name;
          var arr_lvl := arg.t.ArrLvl;
          var tab := '      ';
          
          for var i := 1 to arr_lvl do
          begin
            res_EIm += tab;
            res_EIm += 'for var i';
            if arr_lvl<>1 then
              res_EIm += i.ToString;
            res_EIm += ' := 0 to ';
            res_EIm += vname;
            res_EIm += '.Length-1 do ';
            vname += if arr_lvl=1 then '[i]' else $'[i{i}]';
            tab += '  ';
          end;
          if arr_lvl<>0 then
          begin
            res_EIm += #10;
            res_EIm += tab.Substring(2);
            res_EIm += 'begin'#10;
          end;
          
          res_EIm += tab;
          res_EIm += 'sb.Append(#9, tabs);'#10;
          res_EIm += tab;
          res_EIm += 'sb += ''';
          res_EIm += arg.name;
          for var i := 1 to arr_lvl do
          begin
            res_EIm += '['';'#10;
            
            res_EIm += tab;
            res_EIm += 'sb.Append(i';
            if arr_lvl<>1 then
              res_EIm += i.ToString;
            res_EIm += ');'#10;
            
            res_EIm += tab;
            res_EIm += 'sb += '']';
          end;
          res_EIm += ':'';'#10;
          
          if arg.t.IsCQ then
          begin
            res_EIm += tab;
            res_EIm += 'sb += '' '';'#10;
            
            res_EIm += tab;
            res_EIm += vname;
            res_EIm += '.ToString(sb, tabs, index, delayed, false);'#10;
          end else
            WriteBasicValueToString(res_EIm, tab, vname, arg.name in val_ptr_args);
          
          if arr_lvl<>0 then
          begin
            res_EIm += tab.Substring(2);
            res_EIm += 'end;'#10;
          end;
          
          res_EIm += '      '#10;
        end;
        
        res_EIm += '    end;'#10;
      end;
      
      res_EIm += '    '#10;
      
      {$endregion ToStringImpl}
      
      res_EIm += '  end;'#10;
      res_EIm += '  '#10;
      
    end;
    
    protected procedure WriteMethodResT(l_res, l_res_E: Writer; settings: TSettings); abstract;
    protected procedure WriteMethodEImBody(write_new_ct: Action0; settings: TSettings); virtual;
    begin
      res_EIm += 'AddCommand(self, ';
      write_new_ct;
      res_EIm += ');'#10;
    end;
    protected function GetIImResT(settings: TSettings): string; virtual := t;
    public procedure WriteMethod(bl: (string, array of string));
    begin
      var reg_name := bl[0].ToWords('!').JoinToString('!');
      var name_separator_ind := bl[0].IndexOf('!');
      var fn := name_separator_ind=-1 ? bl[0] : bl[0].Remove(name_separator_ind);
      var tn := name_separator_ind=-1 ? bl[0] : bl[0].Remove(name_separator_ind,1);
      
      var settings := new TSettings;
      foreach var (setting_name, setting_data) in FixerUtils.ReadBlocks(bl[1], '!', false) do
        settings.Apply(setting_name, setting_data, tn);
      settings.Seal(t, generics.Select(g->g[0]), tn);
      
      res_EIm += '{$region ';
      res_EIm += reg_name;
      res_EIm += '}'#10;
      res_EIm += #10;
      
      if not settings.is_short_def then
        WriteCommandType(fn, tn, settings);
      
      {$region Setup}
      
      var l_res_EIm := settings.implicit_only ? WriterEmpty.Instance  : res_EIm;
      
      var l_res_In  := settings.implicit_only ? res_IIn               : res_In;
      var l_res_Im  := settings.implicit_only ? res_IIm               : res_Im;
      
      var l_res_E   := settings.implicit_only ? WriterEmpty.Instance  : res_E;
      
      var l_res     := settings.implicit_only ? res_I                 : res;
      
      {$endregion Setup}
      
      {$region Header}
      
      l_res_In += '    public ';
      l_res += 'function ';
      l_res_Im += t;
      l_res_EIm += 'CCQ';
      if generics.Count <> 0 then
      begin
        l_res_Im += '<';
        l_res_Im += generics.Select(g->g[0]).JoinToString(', ');
        l_res_Im += '>';
      end;
      l_res_Im += '.';
      l_res_E += 'Then';
      l_res += fn;
      l_res += settings.generics_str;
      if settings.args_str <> nil then
      begin
        l_res += '(';
        l_res += settings.args_str;
        l_res += ')';
      end;
      l_res += ': ';
      WriteMethodResT(l_res, l_res_E, settings);
      l_res += ';';
      if settings.where_record_str<>nil then
      begin
        l_res += ' ';
        l_res += settings.where_record_str;
      end;
      l_res += #10;
      
      {$endregion Header}
      
      {$region Body}
      
      l_res_Im += 'begin'#10;
      l_res_Im += '  Result := ';
      
      if settings.is_short_def then
      begin
        
        l_res_EIm += 'Then';
        l_res_Im += settings.def.Single;
        l_res_Im += #10;
        
      end else
      begin
        
        res_IIm += 'CLContext.Default.SyncInvoke(self.MakeCCQ.Then';
        res_IIm += fn;
        if settings.generics_str <> nil then
        begin
          res_IIm += '&';
          res_IIm += settings.generics_str;
        end;
        if settings.args<>nil then
        begin
          res_IIm += '(';
          res_IIm += settings.args.Select(arg->arg.name).JoinToString(', ');
          res_IIm += ')';
        end;
        res_IIm += ');'#10;
        
        WriteMethodEImBody(()->
        begin
          res_EIm += 'new ';
          res_EIm += t;
          res_EIm += 'Command';
          res_EIm += tn;
          //TODO #2654
          if generics.Count+(settings as MethodSettings).generics.Count <> 0 then
          begin
            res_EIm += '<';
            res_EIm += generics.Select(g->g[0]).Concat(settings.generics).JoinToString(', ');
            res_EIm += '>';
          end;
          if settings.impl_args<>nil then
          begin
            res_EIm += '(';
            //TODO #2654
            res_EIm += (settings as MethodSettings).impl_args.JoinToString(', ');
            res_EIm += ')';
          end;
        end, settings);
        
      end;
      
      l_res_Im += 'end;'#10;
      
      {$endregion Body}
      
      res_In += '    ';
      res += #10;
      
      res_EIm += '{$endregion ';
      res_EIm += reg_name;
      res_EIm += '}'#10;
      res_EIm += #10;
      
    end;
    
    public procedure WriteMethodGroup(fname, nick: string);
    begin
      var reg_defined := false;
      
      foreach var bl in FixerUtils.ReadBlocks(fname, false) do
        if bl[0]<>nil then
        begin
          if not reg_defined then
          begin
            res_In += '    ';
            res += '{$region ';
            res += nick;
            res += '}'#10;
            res_In += '    ';
            res += #10;
            reg_defined := true;
          end;
          WriteMethod(bl);
        end else
          foreach var (special_name, special_data) in FixerUtils.ReadBlocks(bl[1], '!', false) do
            match special_name with
              
              'Generics':
              foreach var l in special_data do
              begin
                var ind := l.IndexOf(':');
                self.generics += (
                  (if ind=-1 then l else l.Remove(ind)).Trim,
                  if ind=-1 then nil else l.Substring(ind+1).Trim
                );
              end;
              
              else raise new System.InvalidOperationException(special_name);
            end;
      
      if reg_defined then
      begin
        res_In += '    ';
        res += '{$endregion ';
        res += nick;
        res += '}'#10;
        res_In += '    ';
        res += #10;
      end;
      
    end;
    
  end;
  
end.