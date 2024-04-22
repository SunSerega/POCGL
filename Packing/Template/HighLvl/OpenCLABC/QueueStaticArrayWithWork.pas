uses '../../../../POCGL_Utils';

uses '../../../../Utils/CodeGen';
uses '../../../../Utils/Fixers';
uses '../../../../Utils/ATask';

const MaxQueueStaticArraySize = 7;

const exec_order_s = 'Sync';
const exec_order_a = 'Async';
const exec_orders: array of string = (exec_order_s, exec_order_a);

const exec_speed_quick = 'Quick';
const exec_speed_threaded = 'Threaded';
const exec_speeds: array of string = (exec_speed_quick, exec_speed_threaded);

const res_t_nil = 'Nil';
const res_t_any = 'Any';
const res_t_ptr = 'Ptr';
const res_ts: array of string = (res_t_nil, res_t_any, res_t_ptr);

var dir := GetFullPathRTA('QueueArray');

type
  Generator = sealed class
    private c: integer;
    private wr: Writer;
    
    public constructor(c: integer);
    begin
      self.c := c;
      self.wr := new FileWriter(GetFullPath($'StaticArray[{c}].template', dir));
      loop 3 do wr += '  '#10;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    public procedure Close;
    begin
      self.wr += '  '#10'  ';
      self.wr.Close;
    end;
    
    {$region Helpers}
    
    private procedure WriteNumbered(a: string) := wr.WriteNumbered(c, a);
    
    private procedure WriteVT;
    begin
      wr += 'ValueTuple<';
      WriteNumbered('TInp%!,');
      wr += '>';
    end;
    
    {$endregion Helpers}
    
    {$region Invokers}
    
    public procedure WriteInvokers;
    begin
      wr += '  {$region Invokers}'#10;
      wr += '  '#10;
      
      wr += '  QueueArray';
      wr += c;
      wr += 'InvokerData<';
      WriteNumbered('TInp%!,');
      wr += '> = record'#10;
      wr += '    public all_qrs_const := true;'#10;
      wr += '    public next_l: CLTaskLocalData;'#10;
      WriteNumbered('    public qr%: QueueRes<TInp%>;'#10);
      wr += '  end;'#10;
      wr += '  '#10;
      
      wr += '  IQueueArray';
      wr += c;
      wr += 'Invoker = interface'#10;
      wr += '    '#10;
      
      var WriteInvokeTo := procedure(to_nil: boolean)->
      begin
        wr += '    function InvokeTo';
        wr += if to_nil then 'Nil' else 'Any';
        wr += '<';
        WriteNumbered('TInp%!,');
        wr += '>(';
        WriteNumbered('q%: CommandQueue<TInp%>; ');
        wr += 'g: CLTaskGlobalData; l: CLTaskLocalData): ';
        if to_nil then
          wr += 'CLTaskLocalData' else
        begin
          wr += 'QueueArray';
          wr += c;
          wr += 'InvokerData<';
          WriteNumbered('TInp%!,');
          wr += '>';
        end;
        wr += ';'#10;
      end;
      
      |true,false|.ForEach(WriteInvokeTo);
      wr += '    '#10;
      
      wr += '  end;'#10;
      wr += '  '#10;
      
      foreach var exec_order in exec_orders do
      begin
        
        wr += '  QueueArray';
        wr += c;
        wr += exec_order;
        wr += 'Invoker = record(IQueueArray';
        wr += c;
        wr += 'Invoker)'#10;
        wr += '    '#10;
        
        foreach var to_nil in |true,false| do
        begin
          wr += '    public [MethodImpl(MethodImplOptions.AggressiveInlining)]'#10;
          WriteInvokeTo(to_nil);
          wr += '    begin'#10;
          
          case exec_order of
            
            exec_order_s:
            if to_nil then
            begin
              WriteNumbered('      l := q%.InvokeToNil(g, l).base;'#10);
              wr += '      Result := l;'#10;
            end else
            begin
              wr += '      '#10;
              WriteNumbered(
                '      Result.qr% := q%.InvokeToAny(g, l);'#10
                '      if not Result.qr%.IsConst then Result.all_qrs_const := false;'#10
                '      l := Result.qr%.TakeBaseOut;'#10
                '      '#10
              );
              wr += '      Result.next_l := l;'#10;
            end;
            
            exec_order_a:
            if to_nil then
            begin
              wr += '      var res_ev: EventList;'#10;
              wr += '      g.ParallelInvoke(l, ';
              wr += c;
              wr += ', invoker->(res_ev := EventList.Combine(|'#10;
              WriteNumbered('        invoker.InvokeBranch(q%.InvokeToNil).AttachInvokeActions(invoker.g)!,'#10);
              wr += #10'      |)));'#10;
              wr += '      Result := new CLTaskLocalData(res_ev);'#10;
            end else
            begin
              wr += '      '#10;
              wr += '      var res: QueueArray';
              wr += c;
              wr += 'InvokerData<';
              WriteNumbered('TInp%!,');
              wr += '>;'#10;
              wr += '      g.ParallelInvoke(l, ';
              wr += c;
              wr += ', invoker->'#10;
              wr += '      begin'#10;
              WriteNumbered(
                    '        res.qr% := invoker.InvokeBranch(q%.InvokeToAny);'#10
              );
              wr += '      end);'#10;
              wr += '      Result := res;'#10;
              wr += '      '#10;
              wr += '      Result.all_qrs_const := ';
              WriteNumbered('Result.qr%.IsConst! and ');
              wr += ';'#10;
              wr += '      Result.next_l := new CLTaskLocalData(EventList.Combine(|'#10;
              WriteNumbered('        Result.qr%.AttachInvokeActions(g)!,'#10);
              wr += #10'      |));'#10;
            end;
            
            else raise new System.NotImplementedException;
          end;
          wr += '    end;'#10;
          wr += '    '#10;
        end;
        
        wr += '  end;'#10;
        wr += '  '#10;
        
      end;
      
      wr += '  {$endregion Invokers}'#10;
      wr += '  '#10;
    end;
    
    {$endregion Invokers}
    
    {$region Work}
    
    public procedure WriteWork;
    begin
      wr += '  {$region Work}'#10;
      wr += '  '#10;
      
      wr += '  IQueueArray';
      wr += c;
      wr += 'Work<';
      WriteNumbered('TInp%,');
      wr += 'TRes, TDelegate> = interface'#10;
      wr += '  where TDelegate: ISimpleDelegateContainer;'#10;
      wr += '    '#10;
      wr += '    function PreInvoke(d: TDelegate';
      WriteNumbered('; inp%: TInp%');
      wr += '): TRes;'#10;
      wr += '    '#10;
      wr += '    function Invoke(d: TDelegate; err_handler: ErrHandler{$ifdef DEBUG}; err_test_reason: string{$endif}';
      WriteNumbered('; inp%: TInp%');
      wr += '; c: CLContext): TRes;'#10;
      wr += '    '#10;
      wr += '  end;'#10;
      wr += '  '#10;
      
      foreach var is_conv in |true,false| do
      begin
        var d_word := if is_conv then 'Func' else 'Proc';
        
        wr += '  {$region ';
        wr += d_word;
        wr += '}'#10;
        wr += '  '#10;
        
        var WriteSimpleContName := procedure(need_c: boolean)->
        begin
          wr += 'Simple';
          wr += d_word;
          wr += c;
          wr += 'Container';
          if need_c then wr += 'C';
          wr += '<';
          WriteNumbered('TInp%!,');
          if is_conv then
            wr += ',TRes';
          wr += '>';
        end;
        
        wr += '  I';
        WriteSimpleContName(false);
        wr += ' = interface(ISimpleDelegateContainer)'#10;
        wr += '    '#10;
        
        wr += '    ';
        wr += if is_conv then 'function' else 'procedure';
        wr += ' Invoke(';
        WriteNumbered('inp%: TInp%; ');
        wr += 'c: CLContext)';
        if is_conv then
          wr += ': TRes';
        wr += ';'#10;
        wr += '    '#10;
        
        wr += '  end;'#10;
        wr += '  '#10;
        
        foreach var need_c in |false,true| do
        begin
          
          wr += '  ';
          WriteSimpleContName(need_c);
          wr += ' = record(I';
          WriteSimpleContName(false);
          wr += ')'#10;
          
          var DefineD := procedure->
          begin
            wr += 'd: (';
            WriteNumbered('TInp%!,');
            if need_c then
              wr += ', CLContext';
            wr += ')->';
            wr += if is_conv then 'TRes' else '()';
          end;
          
          wr += '    private ';
          DefineD;
          wr += ';'#10;
          wr += '    '#10;
          
          wr += '    public static function operator implicit(';
          DefineD;
          wr += '): ';
          WriteSimpleContName(need_c);
          wr += ';'#10;
          wr += '    begin'#10;
          wr += '      Result.d := d;'#10;
          wr += '    end;'#10;
          wr += '    '#10;
          
          wr += '    public ';
          wr += if is_conv then 'function' else 'procedure';
          wr += ' Invoke(';
          WriteNumbered('inp%: TInp%; ');
          wr += 'c: CLContext) := d(';
          WriteNumbered('inp%!,');
          if need_c then wr += ',c';
          wr += ');'#10;
          wr += '    '#10;
          
          wr += '    public procedure ToStringB(sb: StringBuilder) :='#10;
          wr += '      _ObjectToString(d, sb);'#10;
          wr += '    '#10;
          
          wr += '  end;'#10;
        end;
        wr += '  '#10;
        
        wr += '  QueueArray';
        wr += c;
        wr += 'Work';
        wr += if is_conv then 'Convert' else 'Use';
        wr += '<';
        WriteNumbered('TInp%,');
        if is_conv then
          wr += 'TRes,';
        wr += ' T';
        wr += d_word;
        wr += '> = record(IQueueArray';
        wr += c;
        wr += 'Work<';
        WriteNumbered('TInp%,');
        if is_conv then
          wr += 'TRes' else
          WriteVT;
        wr += ', T';
        wr += d_word;
        wr += '>)'#10;
        wr += '  where T';
        wr += d_word;
        wr += ': I';
        WriteSimpleContName(false);
        wr += ';'#10;
        wr += '    '#10;
        
        wr += '    public [MethodImpl(MethodImplOptions.AggressiveInlining)]'#10;
        wr += '    function PreInvoke(';
        wr += d_word.First.ToLower;
        wr += ': T';
        wr += d_word;
        WriteNumbered('; inp%: TInp%');
        wr += ')';
        if is_conv then
        begin
          wr += ' :='#10;
          wr += '    ';
        end else
        begin
          wr += ': ';
          WriteVT;
          wr += ';'#10;
          wr += '    begin'#10;
          wr += '      ';
        end;
        wr += d_word.First.ToLower;
        wr += '.Invoke(';
        WriteNumbered('inp%,');
        wr += ' nil);'#10;
        if not is_conv then
        begin
          wr += '      Result := ValueTuple.Create(';
          WriteNumbered('inp%!,');
          wr += ');'#10;
          wr += '    end;'#10;
        end;
        wr += '    '#10;
        
        wr += '    public [MethodImpl(MethodImplOptions.AggressiveInlining)]'#10;
        wr += '    function Invoke(';
        wr += d_word.First.ToLower;
        wr += ': T';
        wr += d_word;
        wr += '; err_handler: ErrHandler{$ifdef DEBUG}; err_test_reason: string{$endif}; ';
        WriteNumbered('inp%: TInp%; ');
        wr += 'c: CLContext): ';
        if is_conv then
          wr += 'TRes' else
          WriteVT;
        wr += ';'#10;
        wr += '    begin'#10;
        wr += '      if not err_handler.HadError then'#10;
        wr += '      try'#10;
        wr += '        ';
        if is_conv then
          wr += 'Result := ';
        wr += d_word.First.ToLower;
        wr += '.Invoke(';
        WriteNumbered('inp%,');
        wr += ' c);'#10;
        if not is_conv then
        begin
          wr += '        Result := ValueTuple.Create(';
          WriteNumbered('inp%!,');
          wr += ');'#10;
        end;
        wr += '      except'#10;
        wr += '        on e: Exception do err_handler.AddErr(e{$ifdef DEBUG}, err_test_reason{$endif})'#10;
        wr += '      end;'#10;
        wr += '      {$ifdef DEBUG}'#10;
        wr += '      err_handler.EndMaybeError(err_test_reason);'#10;
        wr += '      {$endif DEBUG}'#10;
        wr += '    end;'#10;
        wr += '    '#10;
        
        wr += '  end;'#10;
        wr += '  '#10;
        
        wr += '  {$endregion ';
        wr += d_word;
        wr += '}'#10;
        wr += '  '#10;
        
      end;
      
      wr += '  {$endregion Work}'#10;
      wr += '  '#10;
    end;
    
    {$endregion Work}
    
    {$region Common}
    
    public procedure WriteCommon;
    begin
      wr += '  {$region Common}'#10;
      wr += '  '#10;
      
      wr += '  CommandQueueArray';
      wr += c;
      wr += 'WithWork<';
      WriteNumbered('TInp%,');
      wr += 'TRes, TInv,TDelegate,TWork> = abstract class(CommandQueue<TRes>)'#10;
      
      wr += '  where TInv: IQueueArray';
      wr += c;
      wr += 'Invoker, constructor;'#10;
      
      wr += '  where TDelegate: ISimpleDelegateContainer;'#10;
      
      wr += '  where TWork: IQueueArray';
      wr += c;
      wr += 'Work<';
      WriteNumbered('TInp%,');
      wr += 'TRes, TDelegate>, constructor;'#10;
      
      WriteNumbered('    protected q%: CommandQueue<TInp%>;'#10);
      wr += '    protected d: TDelegate;'#10;
      wr += '    protected can_pre_call: boolean;'#10;
      wr += '    '#10;
      
      wr += '    public constructor(';
      WriteNumbered('q%: CommandQueue<TInp%>; ');
      wr += 'd: TDelegate; can_pre_call: boolean);'#10;
      wr += '    begin'#10;
      WriteNumbered('      self.q% := q%;'#10);
      wr += '      self.d := d;'#10;
      wr += '      self.can_pre_call := can_pre_call;'#10;
      wr += '      if can_pre_call';
      WriteNumbered(' and (q%.const_res_dep<>nil)');
      wr += ' then'#10;
      wr += '      begin'#10;
      wr += '        self.expected_const_res := TWork.Create.PreInvoke(d,'#10;
      WriteNumbered('          q%.expected_const_res!,'#10);
      wr += #10'        );'#10;
      wr += '        '#10;
      wr += '        var c := ';
      WriteNumbered('q%.const_res_dep.Length! + ');
      wr += ';'#10;
      wr += '        {$ifdef DEBUG}'#10;
      wr += '        if c=0 then raise new OpenCLABCInternalException($''0dep version is CQ/HFQ/HPQ'');'#10;
      wr += '        {$endif DEBUG}'#10;
      wr += '        '#10;
      wr += '        self.const_res_dep := new CommandQueueBase[c];'#10;
      wr += '        var dep: array of CommandQueueBase;'#10;
      for var i := c downto 1 do
      begin
        wr += '        dep := q';
        wr += i;
        wr +='.const_res_dep; c -= dep.Length; dep.CopyTo(self.const_res_dep, c);'#10;
      end;
      wr += '      end;'#10;
      wr += '    end;'#10;
      wr += '    private constructor := raise new OpenCLABCInternalException;'#10;
      wr += '    '#10;
      
      wr += '    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; inited_hubs: HashSet<IMultiusableCommandQueue>); override :='#10;
      wr += '    begin'#10;
      WriteNumbered('      q%.InitBeforeInvoke(g, inited_hubs);'#10);
      wr += '    end;'#10;
      wr += '    '#10;
      
      wr += '    protected function TrySkipInvoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>; var res: TR): boolean; where TR: IQueueRes;'#10;
      wr += '    begin'#10;
      wr += '      Result := qr_factory.TrySkipInvoke('#10;
      wr += '        g, l,'#10;
      wr += '        self,(g,l)->new QueueResNil(TInv.Create.InvokeToNil(';
      WriteNumbered('q%,');
      wr += ' g,l)),'#10;
      wr += '        res'#10;
      wr += '      );'#10;
      wr += '    end;'#10;
      wr += '    '#10;
      
      wr += '    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;'#10;
      wr += '    begin'#10;
      wr += '      sb += #10;'#10;
      WriteNumbered('      q%.ToString(sb, tabs, index, delayed);'#10);
      wr += '      sb.Append(#9, tabs);'#10;
      wr += '      d.ToStringB(sb);'#10;
      wr += '      sb += #10;'#10;
      wr += '    end;'#10;
      wr += '    '#10;
      
      wr += '  end;'#10;
      wr += '  '#10;
      
      wr += '  {$endregion Common}'#10;
      wr += '  '#10;
    end;
    
    {$endregion Common}
    
    {$region Body}
    
    public procedure WriteBody := foreach var exec_speed in exec_speeds do
    begin
      wr += '  {$region ';
      wr += exec_speed;
      wr += '}'#10;
      wr += '  '#10;
      
      var WriteDMakeBody := procedure->
      begin
        wr += 'DCommandQueue';
        wr += exec_speed;
        wr += 'Array';
        wr += c;
        wr += 'MakeBody<';
        WriteNumbered('TInp%,');
        wr += ' TR>';
      end;
      
      if exec_speed=exec_speed_threaded then
      begin
        wr += '  ';
        WriteDMakeBody;
        wr += ' = function(acts: QueueResComplDelegateData; ';
        WriteNumbered('qr%: QueueRes<TInp%>; ');
        wr += 'err_handler: ErrHandler; c: CLContext; own_qr: TR{$ifdef DEBUG}; err_test_reason: string{$endif}): Action;'#10;
      end;
      
      wr += '  CommandQueue';
      wr += exec_speed;
      wr += 'Array';
      wr += c;
      wr += '<';
      WriteNumbered('TInp%,');
      wr += 'TRes, TInv, TDelegate, TWork';
      wr += '> = sealed class(CommandQueueArray';
      wr += c;
      wr += 'WithWork<';
      WriteNumbered('TInp%,');
      wr += 'TRes, TInv, TDelegate, TWork>)'#10;
      
      wr += '  where TInv: IQueueArray';
      wr += c;
      wr += 'Invoker, constructor;'#10;
      
      wr += '  where TDelegate: ISimpleDelegateContainer;'#10;
      
      wr += '  where TWork: IQueueArray';
      wr += c;
      wr += 'Work<';
      WriteNumbered('TInp%,');
      wr += 'TRes, TDelegate>, constructor;'#10;
      
      wr += '    '#10;
      
      if exec_speed=exec_speed_threaded then
        foreach var need_res in |false,true| do
        begin
          wr += '    private [MethodImpl(MethodImplOptions.AggressiveInlining)]'#10;
          wr += '    function Make';
          wr += if need_res then 'Res' else 'Nil';
          wr += 'Body';
          wr += if need_res then '<TR>' else '    ';
          wr += '(acts: QueueResComplDelegateData; ';
          WriteNumbered('qr%: QueueRes<TInp%>; ');
          wr += 'err_handler: ErrHandler; c: CLContext; own_qr: ';
          wr += if need_res then 'TR' else 'QueueResNil';
          wr += '{$ifdef DEBUG}; err_test_reason: string{$endif}): Action;';
          if need_res then
            wr += ' where TR: QueueRes<TRes>;';
          wr += #10;
          wr += '    begin'#10;
          wr += '      Result := ()->'#10;
          wr += '      begin'#10;
          wr += '        acts.Invoke(c);'#10;
          
          wr += '        ';
          if need_res then
            wr += 'own_qr.SetRes(';
          wr += 'TWork.Create.Invoke(d, err_handler{$ifdef DEBUG}, err_test_reason{$endif}, ';
          WriteNumbered('qr%.GetResDirect, ');
          wr += 'c)';
          if need_res then
            wr += ')';
          wr += ';'#10;
          
          wr += '      end;'#10;
          wr += '    end;'#10;
          wr += '    '#10;
        end;
      
      wr += '    private [MethodImpl(MethodImplOptions.AggressiveInlining)]'#10;
      wr += '    function Invoke<TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory: IQueueResFactory<TRes,TR>';
      if exec_speed=exec_speed_threaded then
      begin
        wr += '; make_body: ';
        WriteDMakeBody;
      end;
      wr += '): TR; where TR: IQueueRes;'#10;
      wr += '    begin'#10;
      wr += '      if TrySkipInvoke(g,l, qr_factory, Result) then exit;'#10;
      wr += '      var inv_data := TInv.Create.InvokeToAny(';
      WriteNumbered('q%,');
      wr += ' g, l);'#10;
      wr += '      l := inv_data.next_l;'#10;
      wr += '      '#10;
      WriteNumbered('      var qr% := inv_data.qr%;'#10);
      wr += '      var err_handler := g.curr_err_handler.Extract({$ifdef DEBUG}false{$endif});'#10;
      wr += '      '#10;
      
      wr += '      {$ifdef DEBUG}'#10;
      wr += '      var err_test_reason := $''[{self.GetHashCode}]:{TypeName(self)}.d.Invoke'';'#10;
      wr += '      ';
      wr += 'err_handler.AddMaybeError(err_test_reason);'#10;
      wr += '      {$endif DEBUG}'#10;
      wr += '      '#10;
      wr += '      var should_make_const := if can_pre_call then'#10;
      wr += '        inv_data.all_qrs_const else'#10;
      wr += '        ';
      wr += if exec_speed=exec_speed_quick then 'l.ShouldInstaCallAction' else 'false';
      wr += ';'#10;
      wr += '      '#10;
      
      var WriteSimpleMakeQR := procedure(delayed: boolean)->
      begin
        wr += '        Result := qr_factory.Make';
        wr += if delayed then 'Delayed' else 'Const';
        wr += '(l, ';
        if delayed then
          wr += 'qr->c->qr.SetRes(';
        wr += 'TWork.Create.Invoke(d,'#10;
        
        wr += '          err_handler{$ifdef DEBUG}, err_test_reason{$endif},'#10;
        wr += '          ';
        WriteNumbered('qr%.GetResDirect, ');
        if not delayed then wr += 'g.';
        wr += 'c'#10;
        
        wr += '        ))';
        wr += if delayed then ');' else ' else';
        wr += #10;
      end;
      wr += '      if should_make_const then'#10;
      WriteSimpleMakeQR(false);
      case exec_speed of
        exec_speed_quick:
          WriteSimpleMakeQR(true);
        exec_speed_threaded:
        begin
          wr += '      begin'#10;
          wr += '        var prev_ev := l.prev_ev;'#10;
          wr += '        var acts := l.prev_delegate;'#10;
          wr += '        Result := qr_factory.MakeDelayed(qr->new CLTaskLocalData(UserEvent.StartWorkThread('#10;
          wr += '          prev_ev, make_body(acts, ';
          WriteNumbered('qr%,');
          wr += ' err_handler, g.c, qr{$ifdef DEBUG}, err_test_reason{$endif}), g'#10;
          wr += '          {$ifdef EventDebug}, $''body of {TypeName(self)}''{$endif}'#10;
          wr += '        )));'#10;
          wr += '      end;'#10;
        end;
        else raise new System.NotImplementedException;
      end;
      wr += '      '#10;
      wr += '    end;'#10;
      wr += '    '#10;
      
      foreach var res_t in res_ts do
      begin
        wr += '    protected function InvokeTo';
        wr += res_t;
        wr += '(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes';
        case res_t of
          res_t_nil: wr += 'Nil;      ';
          res_t_any: wr += '   <TRes>;';
          res_t_ptr: wr += 'Ptr<TRes>;';
          else raise new System.NotImplementedException;
        end;
        wr += ' override := Invoke(g, l, qr_';
        case res_t of
          res_t_nil: wr += 'nil';
          res_t_any: wr += 'val';
          res_t_ptr: wr += 'ptr';
          else raise new System.NotImplementedException;
        end;
        wr += '_factory';
        if exec_speed=exec_speed_threaded then
        begin
          wr += ', Make';
          wr += if res_t=res_t_nil then res_t else 'Res';
          wr += 'Body';
          case res_t of
            res_t_nil: ;
            res_t_any: wr += '&<QueueResVal<TRes>>';
            res_t_ptr: wr += '&<QueueResPtr<TRes>>';
            else raise new System.NotImplementedException;
          end;
        end;
        wr += ');'#10;
      end;
      wr += '    '#10;
      
      wr += '  end;'#10;
      wr += '  '#10;
      
      foreach var is_conv in |true,false| do
      begin
        var d_word := if is_conv then 'Func' else 'Proc';
        var work_name := if is_conv then 'Convert' else 'Use';
        
        wr += '  CommandQueue';
        wr += work_name;
        wr += exec_speed;
        wr += 'Array';
        wr += c;
        if not is_conv then wr += '    ';
        wr += '<';
        WriteNumbered('TInp%,');
        wr += if is_conv then 'TRes,' else '     ';
        wr += ' TInv, T';
        wr += d_word;
        wr += '> = CommandQueue';
        wr += exec_speed;
        wr += 'Array';
        wr += c;
        wr += '<';
        WriteNumbered('TInp%,');
        if is_conv then
          wr += 'TRes' else
          WriteVT;
        wr += ', TInv, T';
        wr += d_word;
        wr += ', QueueArray';
        wr += c;
        wr += 'Work';
        wr += work_name;
        wr += '<';
        WriteNumbered('TInp%,');
        if is_conv then
          wr += 'TRes,';
        wr += ' T';
        wr += d_word;
        wr += '>';
        wr += '>;'#10;
        
      end;
      wr += '  '#10;
      
      wr += '  {$endregion ';
      wr += exec_speed;
      wr += '}'#10;
      wr += '  '#10;
    end;
    
    {$endregion Body}
    
  end;
  
begin
  try
    System.IO.Directory.CreateDirectory(dir);
    
    (2..MaxQueueStaticArraySize).Select(c->ProcTask(()->
    begin
      var g := new Generator(c);
      
      g.WriteInvokers;
      g.WriteWork;
      g.WriteCommon;
      g.WriteBody;
      
      g.Close;
    end)).Append(ProcTask(()->
    begin
      var wr := new FileWriter(GetFullPath('AllStaticArrays.template', dir));
      loop 3 do wr += #10;
      
      for var c := 2 to MaxQueueStaticArraySize do
      begin
        wr += '{$region [';
        wr += c;
        wr += ']} type'#10'  '#10;
        
        wr += '  {%StaticArray[';
        wr += c;
        wr += ']%}'#10'  '#10;
        
        wr += '{$endregion [';
        wr += c;
        wr += ']}'#10#10;
      end;
      
      wr += #10;
      wr.Close;
    end)).CombineAsyncTask.SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.