uses POCGL_Utils  in '..\..\..\POCGL_Utils';

uses CodeGen      in '..\..\..\Utils\CodeGen';
uses Fixers       in '..\..\..\Utils\Fixers';
uses ATask        in '..\..\..\Utils\ATask';

const MaxQueueStaticArraySize = 7;

const exec_order_s = 'Sync';
const exec_order_a = 'Async';
const exec_orders: array of string = (exec_order_s, exec_order_a);

const q_t_base = 'Base';
const q_ts: array of string = (q_t_base,'Nil','&<T>');

const work_t_conv = 'Conv';
const work_t_use = 'Use';
const work_ts: array of string = (work_t_conv, work_t_use);

const exec_speed_const = 'Const';
const exec_speed_quick = 'Quick';
const exec_speed_threaded = 'Threaded';
const exec_speeds: array of string = (exec_speed_const, exec_speed_quick, exec_speed_threaded);

begin
  try
    System.IO.Directory.CreateDirectory(GetFullPathRTA('CombineQueues'));
    
    var intr := new FileWriter(GetFullPathRTA('CombineQueues\Interface.template'));
    var impl := new FileWriter(GetFullPathRTA('CombineQueues\Implementation.template'));
    var wr := intr * impl;
    
    loop 3 do wr += #10;
    
    foreach var exec_order in exec_orders do
    begin
      wr += '{$region ';
      wr += exec_order;
      wr += '}'#10#10;
      
      wr += '{$region Simple}'#10#10;
      
      foreach var q_t in q_ts do
      begin
        
        wr += 'function Combine';
        wr += exec_order;
        wr += 'Queue';
        wr += q_t.TrimStart('&');
        wr += '(params qs: array of CommandQueue';
        wr += q_t.TrimStart('&');
        wr += ')';
        
        intr += ': CommandQueue';
        intr += q_t.TrimStart('&');
        intr += ';'#10;
        
        impl += ' := QueueArrayUtils.Construct';
        impl += exec_order;
        if q_t<>q_t_base then impl += q_t;
        impl += '(qs';
        if q_t=q_t_base then
          impl += ', true' else
          impl += '.Cast&<CommandQueueBase>';
        impl += ');'#10;
        
        if q_t<>q_t_base then
        begin
          wr += 'function Combine';
          wr += exec_order;
          wr += 'Queue';
          wr += q_t.TrimStart('&');
          wr += '(qs: array of CommandQueueBase; last: CommandQueue';
          wr += q_t.TrimStart('&');
          wr += ')';
          
          intr += ': CommandQueue';
          intr += q_t.TrimStart('&');
          intr += ';'#10;
          
          impl += ' := QueueArrayUtils.Construct';
          impl += exec_order;
          impl += q_t;
          impl += '(qs.Append&<CommandQueueBase>(last));'#10;
        end;
        
        wr += #10;
      end;
      
      wr += '{$endregion Simple}'#10#10;
      
      foreach var work_t in work_ts do
      begin
        wr += '{$region ';
        wr += work_t;
        wr += '}'#10#10;
        
        for var need_context := false to true do
        begin
          var reg_name := need_context ? 'CLContext' : 'NonContext';
          var context_par := need_context ? ', CLContext' : nil;
          
          wr += '{$region ';
          wr += reg_name;
          wr += '}'#10#10;
          
          foreach var exec_speed in exec_speeds do
          begin
            
            wr += 'function Combine';
            wr += exec_speed;
            wr += work_t;
            wr += exec_order;
            wr += 'Queue<TInp';
            if work_t=work_t_conv then
              wr += ', TRes';
            wr += '>(';
            wr += work_t.ToLower;
            wr += ': ';
            case work_t of
              work_t_conv: wr += 'Func';
              work_t_use: wr += 'Action';
            end;
            wr += '<array of TInp';
            wr += context_par;
            if work_t=work_t_conv then
              wr += ', TRes';
            wr += '>; ';
            wr += 'params qs: array of CommandQueue<TInp>): CommandQueue<';
            case work_t of
              work_t_conv: wr += 'TRes';
              work_t_use:  wr += 'array of TInp';
            end;
            wr += '>;'#10;
            
            impl += 'begin'#10;
            if exec_speed=exec_speed_const then
            begin
              impl += '  if qs.All(q->q is ConstQueue<TInp>) then'#10;
              impl += '  begin'#10;
              impl += '    var res := qs.ConvertAll(q->ConstQueue&<TInp>(q).Value);'#10;
              impl += '    ';
              if work_t=work_t_conv then
                impl += 'Result := ';
              impl += work_t.ToLower;
              impl += '(res';
              if need_context then
                impl += ', nil';
              impl += ');'#10;
              if work_t=work_t_use then
                impl += '    Result := res;'#10;
              impl += '  end else'#10;
              impl += '  ';
            end;
            impl += '  Result := new CommandQueue';
            case work_t of
              work_t_conv: impl += 'Convert';
              work_t_use:  impl += 'Use';
              else raise new System.NotImplementedException;
            end;
            impl += if exec_speed<>exec_speed_threaded then exec_speed_quick else exec_speed;
            impl += 'Array<TInp';
            if work_t=work_t_conv then
              impl += ', TRes';
            
            impl += ', QueueArray';
            impl += exec_order;
            impl += 'Invoker';
            
            impl += ', Simple';
            case work_t of
              work_t_conv: impl += 'Func';
              work_t_use:  impl += 'Proc';
            end;
            impl += 'Container';
            if need_context then
              impl += 'C';
            impl += '<array of TInp';
            if work_t=work_t_conv then
              impl += ', TRes';
            impl += '>';
            
            if exec_speed<>exec_speed_threaded then
            begin
              impl += ', TBoolean';
              impl += (exec_speed=exec_speed_const).ToString;
              impl += 'Flag';
            end;
            
            impl += '>(qs.ToArray, ';
            impl += work_t.ToLower;
            impl += ');'#10;
            impl += 'end;'#10;
            
            wr += #10;
            
            for var c := 2 to MaxQueueStaticArraySize do
            begin
              var WriteNumbered := procedure(wr: Writer; a: string)->
              wr.WriteNumbered(c, a);
              
              wr += 'function Combine';
              wr += exec_speed;
              wr += work_t;
              wr += exec_order;
              wr += 'QueueN';
              wr += c;
              wr += '<';
              WriteNumbered(wr, 'TInp%, ');
              wr += 'TRes>(';
              wr += work_t.ToLower;
              wr += ': ';
              case work_t of
                work_t_conv: wr += 'Func';
                work_t_use: wr += 'Action';
              end;
              wr += '<';
              WriteNumbered(wr, 'TInp%!, ');
              wr += context_par;
              if work_t=work_t_conv then wr += ', TRes';
              wr += '>';
              WriteNumbered(wr, '; q%: CommandQueue<TInp%>');
              wr += '): CommandQueue<';
              case work_t of
                work_t_conv:
                  wr += 'TRes';
                work_t_use:
                begin
                  wr += 'ValueTuple<';
                  WriteNumbered(wr, 'TInp%!,');
                  wr += '>';
                end;
              end;
              wr += '>;'#10;
              
              impl += 'begin'#10;
              if exec_speed=exec_speed_const then
              begin
                impl += '  if ';
                WriteNumbered(impl, '(q% is ConstQueue<TInp%>(var c_q%))! and ');
                impl += ' then'#10;
                impl += '  begin'#10;
                impl += '    ';
                if work_t=work_t_conv then
                  impl += 'Result := ';
                impl += work_t.ToLower;
                impl += '(';
                WriteNumbered(impl, 'c_q%.Value!, ');
                if need_context then
                  impl += ', nil';
                impl += ');'#10;
                if work_t=work_t_use then
                begin
                  impl += '    Result := ValueTuple.Create(';
                  WriteNumbered(impl, 'c_q%.Value!, ');
                  impl += ');'#10;
                end;
                impl += '  end else'#10;
                impl += '  ';
              end;
              impl += '  Result := new CommandQueue';
              case work_t of
                work_t_conv: impl += 'Convert';
                work_t_use:  impl += 'Use';
                else raise new System.NotImplementedException;
              end;
              impl += if exec_speed<>exec_speed_threaded then exec_speed_quick else exec_speed;
              impl += 'Array';
              impl += c;
              impl += '<';
              WriteNumbered(impl, 'TInp%!,');
              if work_t=work_t_conv then
                impl += ',TRes';
              
              impl += ', QueueArray';
              impl += c;
              impl += exec_order;
              impl += 'Invoker';
              
              impl += ', Simple';
              case work_t of
                work_t_conv: impl += 'Func';
                work_t_use:  impl += 'Proc';
              end;
              impl += c;
              impl += 'Container';
              if need_context then
                impl += 'C';
              impl += '<';
              WriteNumbered(impl, 'TInp%!,');
              if work_t=work_t_conv then
                impl += ',TRes';
              impl += '>';
              
              if exec_speed<>exec_speed_threaded then
              begin
                impl += ', TBoolean';
                impl += (exec_speed=exec_speed_const).ToString;
                impl += 'Flag';
              end;
              
              impl += '>(';
              WriteNumbered(impl, 'q%,');
              impl += ' ';
              impl += work_t.ToLower;
              impl += ');'#10;
              impl += 'end;'#10;
              
            end;
            wr += #10;
            
          end;
          
          wr += '{$endregion ';
          wr += reg_name;
          wr += '}'#10#10;
          
        end;
        
        wr += '{$endregion ';
        wr += work_t;
        wr += '}'#10#10;
      end;
      
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