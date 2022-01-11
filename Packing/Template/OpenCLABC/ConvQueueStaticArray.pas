uses POCGL_Utils  in '..\..\..\POCGL_Utils';

uses CodeGen      in '..\..\..\Utils\CodeGen';
uses Fixers       in '..\..\..\Utils\Fixers';
uses ATask        in '..\..\..\Utils\ATask';

const MaxQueueStaticArraySize = 7;

begin
  try
    
    (
      Range(2, MaxQueueStaticArraySize).TaskForEach(c->
      begin
        var wr := new FileWriter(GetFullPathRTA($'ConvQueue\StaticArray[{c}].template'));
        loop 3 do wr += #10;
        
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
        
        var WriteBaseDef := procedure(exec_order: string)->
        begin
          wr += '  Conv';
          wr += exec_order;
          wr += 'QueueArray';
          wr += c;
          wr += 'Base<';
          WriteNumbered('TInp%, ');
          wr += 'TRes, TFunc> = abstract class';
        end;
        
        {$region ConvQueueArrayBase}
        
        wr += 'type'#10;
        WriteBaseDef(nil);
        wr += '(HostQueue<';
        WriteVTDef;
        wr += ', TRes>)'#10;
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
        
        {$endregion ConvQueueArrayBase}
        
        var WriteDerBaseDef := procedure(exec_order: string; write_invoke: Action0)->
        begin
          WriteBaseDef(exec_order);
          wr += '(ConvQueueArray';
          wr += c;
          wr += 'Base<';
          WriteNumbered('TInp%, ');
          wr += 'TRes, TFunc>)'#10;
          wr += '  where TFunc: Delegate;'#10;
          wr += '    '#10;
          
          wr += '    protected function InvokeSubQs(g: CLTaskGlobalData; l_nil: CLTaskLocalDataNil): QueueRes<';
          WriteVTDef;
          wr += '>; override;'#10;
          wr += '    begin'#10;
          wr += '      var l := l_nil.WithPtrNeed(false);'#10;
          write_invoke();
          wr += '    end;'#10;
          wr += '    '#10;
          
          wr += '  end;'#10;
          wr += '  '#10;
          
          for var context := false to true do
          begin
            wr += '  Conv';
            wr += exec_order;
            wr += 'QueueArray';
            wr += c;
            if context then
              wr += 'C';
            wr += '<';
            WriteNumbered('TInp%, ');
            wr += 'TRes> = sealed class(Conv';
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
            
            wr += '    protected function ExecFunc(t: ';
            WriteVTDef;
            wr += '; c: Context): TRes; override := f(';
            WriteNumbered('t.Item%!, ');
            if context then
              wr += ', c';
            wr += ');'#10;
            wr += '    '#10;
            
            wr += '  end;'#10;
          end;
          wr += '  '#10;
          
        end;
        
        {$region Sync}
        
        WriteDerBaseDef('Sync', ()->
        begin
          
          WriteNumbered('      var qr% := q%.Invoke(g, l); l.prev_ev := qr%.ev;'#10);
          
          wr += '      Result := new QueueResFunc<';
          WriteVTDef;
          wr += '>(()->ValueTuple.Create(';
          WriteNumbered('qr%.GetRes()!, ');
          wr += '), l.prev_ev);'#10;
        end);
        
        {$endregion Sync}
        
        {$region Async}
        
        WriteDerBaseDef('Async', ()->
        begin
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
          
          wr += '      Result := new QueueResFunc<';
          WriteVTDef;
          wr += '>(()->ValueTuple.Create(';
          WriteNumbered('qr%.GetRes()!, ');
          wr += '), ';
          
          wr += 'EventList.Combine(|';
          WriteNumbered('qr%.ev!, ');
          wr += '|));'#10;
        end);
        
        {$endregion Async}
        
        wr += '  '#10'  ';
        wr.Close;
      end)
    *
      ProcTask(()->
      begin
        var wr := new FileWriter(GetFullPathRTA('ConvQueue\AllStaticArrays.template'));
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