uses '../../../../POCGL_Utils';

uses '../../../../Utils/CodeGen';
uses '../../../../Utils/Fixers';
uses '../../../../Utils/ATask';

const MaxQueueStaticArraySize = 7;

const exec_order_s = 'Sync';
const exec_order_a = 'Async';
const exec_orders: array of string = (exec_order_s, exec_order_a);

const work_t_conv = 'Conv';
const work_t_use = 'Use';
const work_ts: array of string = (work_t_conv, work_t_use);

begin
  try
    System.IO.Directory.CreateDirectory(GetFullPathRTA('CombineQueues'));
    
    var intr := new FileWriter(GetFullPathRTA('CombineQueues/Interface.template'));
    var impl := new FileWriter(GetFullPathRTA('CombineQueues/Implementation.template'));
    var wr := intr * impl;
    
    loop 3 do wr += #10;
    
    foreach var exec_order in exec_orders do
    begin
      wr += '{$region ';
      wr += exec_order;
      wr += '}'#10#10;
      
      {$region Simple}
      
      wr += '{$region Simple}'#10#10;
      
      foreach var with_last in |false,true| do
      begin
        foreach var tq in |'Base', 'Nil', '<T>'| do
        begin
          wr += 'function Combine';
          wr += exec_order;
          wr += 'Queue';
          begin
            var gen := new List<string>;
            if tq='<T>' then
              gen += $'T';
            if with_last then
              gen += 'TQ';
            if gen.Count<>0 then
            begin
              wr += '<';
              wr += gen.JoinToString(', ');
              wr += '>';
            end;
          end;
          wr += '(';
          if not with_last then
            wr += 'params ';
          wr += 'qs: array of ';
          if with_last then
            wr += 'TQ; last: ';
          wr += 'CommandQueue';
          wr += tq;
          wr += ')';
          
          intr += ': CommandQueue';
          intr += tq;
          intr += ';';
          if with_last then
            intr += ' where TQ: CommandQueueBase;';
          intr += #10;
          
          impl += ' := QueueArrayUtils.Construct';
          impl += exec_order;
          impl += '&<CommandQueue';
          impl += tq;
          impl += '>(qs.Cast&<CommandQueueBase>';
          if with_last then
            impl += '.Append&<CommandQueueBase>(last)';
          impl += ');'#10;
          
        end;
        wr += #10;
      end;
      
      wr += '{$endregion Simple}'#10#10;
      
      {$endregion Simple}
      
      {$region Lazy}
      
      var TODO := 0;
      Otp($'WARNING: Lazy not implemented');
      
      {$endregion Lazy}
      
      {$region WithWork}
      
      foreach var work_t in work_ts do
      begin
        wr += '{$region ';
        wr += work_t;
        wr += '}'#10#10;
        
        for var need_context := false to true do
        begin
          var reg_name := need_context ? 'Context' : 'NonContext';
          var context_par := need_context ? ', CLContext' : nil;
          
          wr += '{$region ';
          wr += reg_name;
          wr += '}'#10#10;
          
          foreach var c in 0+(2..MaxQueueStaticArraySize) do
          begin
            var WriteNumbered := procedure(wr: Writer; a: string)->
              wr.WriteNumbered(c, a);
            
            var WriteTInps := procedure(wr: Writer)->
            if c=0 then wr += 'TInp' else
            WriteNumbered(wr, 'TInp%!,');
            
            {$region Def}
            
            wr += 'function Combine';
            wr += work_t;
            wr += exec_order;
            wr += 'Queue';
            if c<>0 then
            begin
              wr += 'N';
              wr += c;
            end;
            wr += '<';
            WriteTInps(wr);
            if work_t=work_t_conv then
              wr += ', TRes';
            wr += '>(';
            wr += work_t.ToLower;
            wr += ': ';
            case work_t of
              work_t_conv: wr += 'Func';
              work_t_use: wr += 'Action';
            end;
            wr += '<';
            if c=0 then
              wr += 'array of TInp' else
              WriteNumbered(wr, 'TInp%!, ');
            wr += context_par;
            if work_t=work_t_conv then
              wr += ', TRes';
            wr += '>; ';
            if c=0 then
              wr += 'qs: array of CommandQueue<TInp>; ' else
              WriteNumbered(wr, 'q%: CommandQueue<TInp%>; ');
            intr += 'need_own_thread: boolean := true; can_pre_calc: boolean := false';
            impl += 'need_own_thread, can_pre_calc: boolean';
            wr += '): CommandQueue<';
            case work_t of
              work_t_conv:
                wr += 'TRes';
              work_t_use:
              if c=0 then
                wr += 'array of TInp' else
              begin
                wr += 'ValueTuple<';
                WriteTInps(wr);
                wr += '>';
              end;
            end;
            wr += '>;'#10;
            
            {$endregion Def}
            
            {$region Impl}
            
            impl += 'begin'#10;
            
            impl += '  if ';
            if c=0 then
              impl += 'qs.All(q->q.IsConstResDepEmpty)' else
              WriteNumbered(impl, 'q%.IsConstResDepEmpty! and ');
            impl += ' then'#10;
            
            impl += '  begin'#10;
            
            if c=0 then
              impl += '    var inp := qs.ConvertAll(q->q.expected_const_res);'#10 else
              WriteNumbered(impl, '    var inp% := q%.expected_const_res;'#10);
            
            var WriteWorkCall := procedure(cont: string)->
            begin
              impl += work_t.ToLower;
              impl += '(';
              if c=0 then
                impl += 'inp' else
                WriteNumbered(impl, 'inp%!,');
              if need_context then
              begin
                impl += ', ';
                impl += cont;
              end;
              impl += ')';
            end;
            
            if work_t=work_t_conv then
            begin
              impl += '    Result := if can_pre_calc then'#10;
              
              impl += '      CQ(';
              WriteWorkCall('nil');
              impl += ') else'#10;
              
              impl += '      HFQ(';
              impl += if need_context then 'c' else '()';
              impl += '->';
              WriteWorkCall('c');
              impl += ', need_own_thread);'#10;
              
            end else
            begin
              impl += '    Result := CQ(';
              if c=0 then
                impl += 'inp' else
              begin
                impl += 'ValueTuple.Create(';
                WriteNumbered(impl, 'inp%!, ');
                impl += ')';
              end;
              impl += ');'#10;
              
              impl += '    if can_pre_calc then'#10;
              
              impl += '      ';
              WriteWorkCall('nil');
              impl += ' else'#10;
              
              impl += '      Result := HPQ(';
              impl += if need_context then 'c' else '()';
              impl += '->';
              WriteWorkCall('c');
              impl += ', need_own_thread) + Result;'#10;
              
            end;
            
            impl += '    Result := Combine';
            impl += exec_order;
            impl += 'Queue(';
            if c=0 then
              impl += 'qs' else
            begin
              impl += 'new CommandQueueBase[](';
              WriteNumbered(impl, 'q%!,');
              impl += ')';
            end;
            impl += ', Result);'#10;
            
            impl += '  end else'#10;
            
            impl += '  if need_own_thread then'#10;
            foreach var w_thr in |true, false| do
            begin
              impl += '    Result := new CommandQueue';
              case work_t of
                work_t_conv: impl += 'Convert';
                work_t_use:  impl += 'Use';
                else raise new System.NotImplementedException;
              end;
              impl += if w_thr then 'Threaded' else 'Quick';
              impl += 'Array';
              if c<>0 then impl += c;
              if not w_thr then impl += '   ';
              impl += '<';
              WriteTInps(impl);
              if work_t=work_t_conv then
                impl += ', TRes';
              
              impl += ', QueueArray';
              if c<>0 then impl += c;
              impl += exec_order;
              impl += 'Invoker';
              
              impl += ', Simple';
              case work_t of
                work_t_conv: impl += 'Func';
                work_t_use:  impl += 'Proc';
              end;
              if c<>0 then impl += c;
              impl += 'Container';
              if need_context then
                impl += 'C';
              impl += '<';
              if c=0 then
                impl += 'array of TInp' else
                WriteNumbered(impl, 'TInp%!, ');
              if work_t=work_t_conv then
                impl += ', TRes';
              impl += '>';
              
              impl += '>(';
              if c=0 then
                impl += 'qs.ToArray,' else
                WriteNumbered(impl, 'q%,');
              impl += ' ';
              impl += work_t.ToLower;
              impl += ', can_pre_calc)';
              impl += if w_thr then ' else' else ';';
              
              impl += #10;
            end;
            impl += 'end;'#10;
            
            {$endregion Impl}
            
            if c=0 then wr += #10;
          end;
          wr += #10;
          
          wr += '{$endregion ';
          wr += reg_name;
          wr += '}'#10#10;
          
        end;
        
        wr += '{$endregion ';
        wr += work_t;
        wr += '}'#10#10;
      end;
      
      {$endregion WithWork}
      
      wr += '{$endregion ';
      wr += exec_order;
      wr += '}'#10#10;
    end;
    
    wr += #10;
    wr.Close;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.