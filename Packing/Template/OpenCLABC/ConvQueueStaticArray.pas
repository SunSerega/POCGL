uses POCGL_Utils  in '..\..\..\POCGL_Utils';

uses CodeGen      in '..\..\..\Utils\CodeGen';
uses Fixers       in '..\..\..\Utils\Fixers';
uses ATask        in '..\..\..\Utils\ATask';

const MaxQueueStaticArraySize = 7;

function quick_word(is_quick: boolean) :=
if is_quick then 'Quick' else 'Background';

begin
  try
    var dir := GetFullPathRTA('ConvQueue');
    System.IO.Directory.CreateDirectory(dir);
    
    (
      Range(2, MaxQueueStaticArraySize).TaskForEach(c->
      begin
        var wr := new FileWriter(GetFullPath($'StaticArray[{c}].template', dir));
        loop 3 do wr += #10;
        wr += 'type'#10;
        
        var WriteNumbered := procedure(a: string)->
        begin
          var ind := a.IndexOf('!');
          var a_long := if ind=-1 then a else a.Remove(ind,1);
          var a_short := if ind=-1 then a else a.Remove(ind);
          for var i := 1 to c-1 do wr += a_long.Replace('%', i.ToString);
          wr += a_short.Replace('%', c.ToString);
        end;
        
        var WriteVTDef := procedure->
        begin
          wr += 'ValueTuple<';
          WriteNumbered('TInp%!, ');
          wr += '>';
        end;
        
        var WriteBaseDef := procedure(is_quick: boolean; exec_order: string)->
        begin
          wr += '  ';
          wr += quick_word(is_quick);
          wr += 'Conv';
          wr += exec_order;
          wr += 'QueueArray';
          wr += c;
          wr += 'Base<';
          WriteNumbered('TInp%, ');
          wr += 'TRes, TFunc> = abstract class';
        end;
        
        {$region ConvQueueArrayBase}
        
        for var is_quick := false to true do
        begin
          WriteBaseDef(is_quick, nil);
          wr += '(';
          if not is_quick then
          begin
            wr += 'HostQueue<';
            WriteVTDef;
            wr += ', '
          end else
            wr += 'CommandQueue<';
          wr += 'TRes>)'#10;
          wr += '  where TFunc: Delegate;'#10;
          
          WriteNumbered('    protected q%: CommandQueue<TInp%>;'#10);
          wr += '    protected f: TFunc;'#10;
          wr += '    '#10;
          
          wr += '    public constructor(';
          WriteNumbered('q%: CommandQueue<TInp%>; ');
          wr += 'f: TFunc);'#10;
          
          wr += '    begin'#10;
          WriteNumbered('      self.q% := q%;'#10);
          wr += '      self.f := f;'#10;
          wr += '    end;'#10;
          wr += '    private constructor := raise new InvalidOperationException($''%Err:NoParamCtor%'');'#10;
          wr += '    '#10;
          
          wr += '    protected function CombineQRs(';
          WriteNumbered('qr%: QueueRes<TInp%>; ');
          wr += 'ev: EventList';
          if is_quick then wr += '; need_ptr_qr: boolean; c: Context';
          wr += '): QueueRes<';
          if not is_quick then
            WriteVTDef else
            wr += 'TRes';
          wr += '>;'#10;
          wr += '    begin'#10;
          
          wr += '      if ';
          WriteNumbered('qr%.IsConst! and ');
          wr += ' then'#10;
          
          wr += '      begin'#10;
          if not is_quick then
          begin
            wr += '        var res := ValueTuple.Create(';
            WriteNumbered('qr%.GetResImpl!, ');
            wr += ');'#10;
            wr += '        Result := new QueueResVal<';
            WriteVTDef;
            wr += '>(ev, res);'#10;
          end else
          begin
            wr += '        var res := ExecFunc(';
            WriteNumbered('qr%.GetResImpl, ');
            wr += 'c);'#10;
            wr += '        Result := QueueRes&<TRes>.MakeNewConstOrPtr(need_ptr_qr, ev, res);'#10;
          end;
          wr += '      end else'#10;
          
          if not is_quick then
          begin
            wr += '        Result := new QueueResVal<';
            WriteVTDef;
            wr += '>(ev);'#10;
            wr += '        Result.AddResSetter(()->ValueTuple.Create(';
            WriteNumbered('qr%.GetResImpl!, ');
            wr += '));'#10;
          end else
          begin
            wr += '        Result := QueueRes&<TRes>.MakeNewDelayedOrPtr(need_ptr_qr, ev);'#10;
            wr += '        Result.AddResSetter(()->ExecFunc(';
            WriteNumbered('qr%.GetResImpl, ');
            wr += 'c));'#10;
          end;
          
          wr += '    end;'#10;
          wr += '    '#10;
          
          if is_quick then
          begin
            wr += '    protected function ExecFunc(';
            WriteNumbered('o%: TInp%; ');
            wr += 'c: Context): TRes; abstract;'#10;
            wr += '    '#10;
          end;
          
          wr += '    protected procedure RegisterWaitables(g: CLTaskGlobalData; prev_hubs: HashSet<IMultiusableCommandQueueHub>); override;'#10;
          wr += '    begin'#10;
          WriteNumbered('      self.q%.RegisterWaitables(g, prev_hubs);'#10);
          wr += '    end;'#10;
          wr += '    '#10;
          
          wr += '    private procedure ToStringImpl(sb: StringBuilder; tabs: integer; index: Dictionary<object,integer>; delayed: HashSet<CommandQueueBase>); override;'#10;
          wr += '    begin'#10;
          wr += '      sb += #10;'#10;
          WriteNumbered('      self.q%.ToString(sb, tabs, index, delayed);'#10);
          wr += '    end;'#10;
          wr += '    '#10;
          
          wr += '  end;'#10;
          
          wr += '  '#10;
        end;
        
        {$endregion ConvQueueArrayBase}
        
        var WriteDerBaseDef := procedure(is_quick: boolean; exec_order: string; write_invoke: Action0)->
        begin
          WriteBaseDef(is_quick, exec_order);
          wr += '(';
          wr += quick_word(is_quick);
          wr += 'ConvQueueArray';
          wr += c;
          wr += 'Base<';
          WriteNumbered('TInp%, ');
          wr += 'TRes, TFunc>)'#10;
          wr += '  where TFunc: Delegate;'#10;
          wr += '    '#10;
          
          write_invoke();
          wr += '      Result := CombineQRs(';
          WriteNumbered('qr%, ');
          case exec_order of
            'Sync': wr += 'l.prev_ev';
            'Async': wr += 'res_ev';
            else raise new System.InvalidOperationException(exec_order);
          end;
          if is_quick then wr += ', l.need_ptr_qr, g.c';
          wr += ');'#10;
          wr += '    end;'#10;
          wr += '    '#10;
          
          wr += '  end;'#10;
          wr += '  '#10;
          
          for var context := false to true do
          begin
            wr += '  ';
            wr += quick_word(is_quick);
            wr += 'Conv';
            wr += exec_order;
            wr += 'QueueArray';
            wr += c;
            if context then
              wr += 'C';
            wr += '<';
            WriteNumbered('TInp%, ');
            wr += 'TRes> = sealed class(';
            wr += quick_word(is_quick);
            wr += 'Conv';
            wr += exec_order;
            wr += 'QueueArray';
            wr += c;
            wr += 'Base<';
            WriteNumbered('TInp%, ');
            wr += 'TRes, (';
            WriteNumbered('TInp%!, ');
            if context then
              wr += ', Context';
            wr += ')->TRes>)'#10;
            wr += '    '#10;
            
            wr += '    protected function ExecFunc(';
            if not is_quick then
            begin
              wr += 't: ';
              WriteVTDef;
              wr += '; ';
            end else
              WriteNumbered('o%: TInp%; ');
            wr += 'c: Context): TRes; override := f(';
            WriteNumbered(if not is_quick then
              't.Item%!, ' else 'o%!, '
            );
            if context then
              wr += ', c';
            wr += ');'#10;
            wr += '    '#10;
            
            wr += '  end;'#10;
          end;
          wr += '  '#10;
          
        end;
        
        {$region Background}
        
        {$region Sync}
        
        WriteDerBaseDef(false, 'Sync', ()->
        begin
          wr += '    protected function InvokeSubQs(g: CLTaskGlobalData; l_nil: CLTaskLocalDataNil): QueueRes<';
          WriteVTDef;
          wr += '>; override;'#10;
          wr += '    begin'#10;
          wr += '      var l := l_nil.WithPtrNeed(false);'#10;
          
          WriteNumbered('      var qr% := q%.Invoke(g, l); l.prev_ev := qr%.ThenAttachInvokeActions(g);'#10);
          
        end);
        
        {$endregion Sync}
        
        {$region Async}
        
        WriteDerBaseDef(false, 'Async', ()->
        begin
          wr += '    protected function InvokeSubQs(g: CLTaskGlobalData; l_nil: CLTaskLocalDataNil): QueueRes<';
          WriteVTDef;
          wr += '>; override;'#10;
          wr += '    begin'#10;
          wr += '      var l := l_nil.WithPtrNeed(false);'#10;
          
          wr += '      if l.prev_ev.count<>0 then loop ';
          wr += c-1;
          wr += ' do l.prev_ev.Retain({$ifdef EventDebug}''for all async branches''{$endif});'#10;
          
          WriteNumbered('      var qr%: QueueRes<TInp%>;'#10);
          
          wr += '      g.ParallelInvoke(l, false, ';
          wr += c;
          wr += ', invoker->'#10;
          wr += '      begin'#10;
          WriteNumbered('        qr% := invoker.InvokeBranch(q%.Invoke);'#10);
          wr += '      end);'#10;
          
          wr += '      var res_ev := EventList.Combine(|';
          WriteNumbered('qr%.ThenAttachInvokeActions(g)!, ');
          wr += '|);'#10;
          
        end);
        
        {$endregion Async}
        
        {$endregion Background}
        
        {$region Quick}
        
        {$region Sync}
        
        WriteDerBaseDef(true, 'Sync', ()->
        begin
          wr += '    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<TRes>; override;'#10;
          wr += '    begin'#10;
          
          WriteNumbered('      var qr% := q%.Invoke(g, l); l.prev_ev := qr%.ThenAttachInvokeActions(g);'#10);
          
        end);
        
        {$endregion Sync}
        
        {$region Async}
        
        WriteDerBaseDef(true, 'Async', ()->
        begin
          wr += '    protected function Invoke(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<TRes>; override;'#10;
          wr += '    begin'#10;
          
          wr += '      if l.prev_ev.count<>0 then loop ';
          wr += c-1;
          wr += ' do l.prev_ev.Retain({$ifdef EventDebug}''for all async branches''{$endif});'#10;
          
          WriteNumbered('      var qr%: QueueRes<TInp%>;'#10);
          
          wr += '      g.ParallelInvoke(l, false, ';
          wr += c;
          wr += ', invoker->'#10;
          wr += '      begin'#10;
          WriteNumbered('        qr% := invoker.InvokeBranch(q%.Invoke);'#10);
          wr += '      end);'#10;
          
          wr += '      var res_ev := EventList.Combine(|';
          WriteNumbered('qr%.ThenAttachInvokeActions(g)!, ');
          wr += '|);'#10;
          
        end);
        
        {$endregion Async}
        
        {$endregion Quick}
        
        wr += '  '#10'  ';
        wr.Close;
      end)
    *
      ProcTask(()->
      begin
        var wr := new FileWriter(GetFullPath('AllStaticArrays.template', dir));
        loop 3 do wr += '  '#10;
        
        for var c := 2 to MaxQueueStaticArraySize do
        begin
          wr += '{$region [';
          wr += c;
          wr += ']}'#10#10;
          wr += '{%StaticArray[';
          wr += c;
          wr += ']%}'#10#10;
          wr += '{$endregion [';
          wr += c;
          wr += ']}'#10#10;
        end;
        
        wr += '  '#10'  ';
        wr.Close;
      end)
    ).SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.