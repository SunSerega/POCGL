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
            wr += 'BackgroundConvertQueue<';
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
          
          wr += '    protected procedure InitBeforeInvoke(g: CLTaskGlobalData; prev_hubs: HashSet<IMultiusableCommandQueueHub>); override;'#10;
          wr += '    begin'#10;
          WriteNumbered('      self.q%.InitBeforeInvoke(g, prev_hubs);'#10);
          wr += '    end;'#10;
          wr += '    '#10;
          
          if is_quick then
          begin
            wr += '    protected function ExecFunc(';
            WriteNumbered('o%: TInp%; ');
            wr += 'c: Context): TRes; abstract;'#10;
            wr += '    '#10;
          end;
          
          for var need_res := not is_quick to true do
          begin
            
            wr += '    protected function CombineQRs';
            if is_quick then wr += if not need_res then 'Nil' else 'Res<TF,TR>';
            wr += '(';
            WriteNumbered('qr%: QueueRes<TInp%>; ');
            if is_quick then wr += 'g: CLTaskGlobalData; ';
            wr += 'l: CLTaskLocalData): ';
            if not is_quick  then
            begin
              wr += 'QueueResVal<';
              WriteVTDef;
              wr += '>';
            end else
              wr += if not need_res then 'QueueResNil' else 'TR; where TF: IQueueResFactory<TRes,TR>, constructor; where TR: QueueRes<TRes>';
            wr += ';'#10;
            
            wr += '    begin'#10;
            if not need_res then
              wr += '      Result := new QueueResNil(l);'#10;
            wr += '      if l.ShouldInstaCallAction then'#10;
            
            wr += '      begin'#10;
            if not is_quick then
            begin
              wr += '        var res := ValueTuple.Create(';
              WriteNumbered('qr%.GetResDirect!, ');
              wr += ');'#10;
              wr += '        Result := new QueueResVal<';
              WriteVTDef;
              wr += '>(l, res);'#10;
            end else
            begin
              if need_res then
                wr += '        var res: TRes;';
              wr += '        if not g.curr_err_handler.HadError(true) then'#10;
              wr += '        try'#10;
              
              wr += '          ';
              if need_res then
                wr += 'res := ';
              wr += 'ExecFunc(';
              WriteNumbered('qr%.GetResDirect, ');
              wr += 'g.c);'#10;
              
              wr += '        except'#10;
              wr += '          on e: Exception do g.curr_err_handler.AddErr(e)'#10;
              wr += '        end;'#10;
              if need_res then
                wr += '        Result := TF.Create.MakeConst(l, res);'#10;
            end;
            wr += '      end else'#10;
            
            wr += '      begin'#10;
            if not is_quick then
            begin
              wr += '        Result := new QueueResVal<';
              WriteVTDef;
              wr += '>(l);'#10;
              wr += '        Result.AddResSetter(c->ValueTuple.Create(';
              WriteNumbered('qr%.GetResDirect!, ');
              wr += '));'#10;
            end else
            begin
              if need_res then
                wr += '        Result := TF.Create.MakeDelayed(l);'#10;
              wr += '        var err_handler := g.curr_err_handler;'#10;
              wr += '        Result.';
              wr += if need_res then 'AddResSetter' else 'AddAction';
              wr += '(c->'#10;
              wr += '        if not err_handler.HadError(true) then'#10;
              wr += '        try'#10;
              
              wr += '          ';
              if need_res then
                wr += 'Result := ';
              wr += 'ExecFunc(';
              WriteNumbered('qr%.GetResDirect, ');
              wr += 'c);'#10;
              
              wr += '        except'#10;
              wr += '          on e: Exception do err_handler.AddErr(e)'#10;
              wr += '        end);'#10;
            end;
            wr += '      end;'#10;
            
            wr += '    end;'#10;
            wr += '    '#10;
            
          end;
          
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
          if is_quick then wr += 'g, ';
          case exec_order of
            'Sync': wr += 'l';
            'Async': wr += 'new CLTaskLocalData(res_ev)';
            else raise new System.InvalidOperationException(exec_order);
          end;
          wr += ');'#10;
          if exec_order='Sync' then
            WriteNumbered('      qr%.TransplantActionsNowhere;'#10);
          wr += '    end;'#10;
          wr += '    '#10;
          
          if is_quick then
          begin
            
            foreach var res_t in |'Nil', 'Val', 'Ptr'| do
            begin
              
              wr += '    protected function InvokeTo';
              wr += res_t;
              wr += '(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes';
              wr += res_t;
              wr += if res_t<>'Nil' then
                '<TRes>; ' else
                ';       ';
              wr += 'override := Invoke';
              
              //TODO #????
              if res_t<>'Nil' then
              begin
                wr += '&<QueueRes';
                wr += res_t;
                wr += 'Factory<TRes>,QueueRes';
                wr += res_t;
                wr += '<TRes>>';
              end;
              
              wr += '(g, l, qr_';
              wr += res_t.ToLower;
              wr += '_factory, CombineQRs';
              if res_t='Nil' then
                wr += res_t else
              begin
                wr += 'Res&<QueueRes';
                wr += res_t;
                wr += 'Factory<TRes>,QueueRes';
                wr += res_t;
                wr += '<TRes>>';
              end;
              wr += ');'#10;
              
            end;
            
            wr += '    '#10;
          end;
          
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
          wr += '    protected function InvokeSubQs(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<';
          WriteVTDef;
          wr += '>; override;'#10;
          wr += '    begin'#10;
          
          WriteNumbered('      var qr% := q%.InvokeToAny(g, l); l := qr%.base;'#10);
          
        end);
        
        {$endregion Sync}
        
        {$region Async}
        
        WriteDerBaseDef(false, 'Async', ()->
        begin
          wr += '    protected function InvokeSubQs(g: CLTaskGlobalData; l: CLTaskLocalData): QueueRes<';
          WriteVTDef;
          wr += '>; override;'#10;
          wr += '    begin'#10;
          
          WriteNumbered('      var qr%: QueueRes<TInp%>;'#10);
          
          wr += '      g.ParallelInvoke(l, false, ';
          wr += c;
          wr += ', invoker->'#10;
          wr += '      begin'#10;
          WriteNumbered('        qr% := invoker.InvokeBranch(q%.InvokeToAny);'#10);
          wr += '      end);'#10;
          
          wr += '      var res_ev := EventList.Combine(|';
          WriteNumbered('qr%.AttachInvokeActions(g)!, ');
          wr += '|);'#10;
          
        end);
        
        {$endregion Async}
        
        {$endregion Background}
        
        {$region Quick}
        
        {$region Sync}
        
        WriteDerBaseDef(true, 'Sync', ()->
        begin
          wr += '    private [MethodImpl(MethodImplOptions.AggressiveInlining)]'#10;
          wr += '    function Invoke<TF,TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory_sample: TF; CombineQRs: Func<';
          WriteNumbered('QueueRes<TInp%>, ');
          wr += 'CLTaskGlobalData, CLTaskLocalData, TR>): TR; where TF: IQueueResBaseFactory<TR>, constructor; where TR: IQueueRes;'#10;
          wr += '    begin'#10;
          
          WriteNumbered('      var qr% := q%.InvokeToAny(g, l); l := qr%.base;'#10);
          
        end);
        
        {$endregion Sync}
        
        {$region Async}
        
        WriteDerBaseDef(true, 'Async', ()->
        begin
          wr += '    private [MethodImpl(MethodImplOptions.AggressiveInlining)]'#10;
          wr += '    function Invoke<TF,TR>(g: CLTaskGlobalData; l: CLTaskLocalData; qr_factory_sample: TF; CombineQRs: Func<';
          WriteNumbered('QueueRes<TInp%>, ');
          wr += 'CLTaskGlobalData, CLTaskLocalData, TR>): TR; where TF: IQueueResBaseFactory<TR>, constructor; where TR: IQueueRes;'#10;
          wr += '    begin'#10;
          
          WriteNumbered('      var qr%: QueueRes<TInp%>;'#10);
          
          wr += '      g.ParallelInvoke(l, false, ';
          wr += c;
          wr += ', invoker->'#10;
          wr += '      begin'#10;
          WriteNumbered('        qr% := invoker.InvokeBranch(q%.InvokeToAny);'#10);
          wr += '      end);'#10;
          
          wr += '      var res_ev := EventList.Combine(|';
          WriteNumbered('qr%.AttachInvokeActions(g)!, ');
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