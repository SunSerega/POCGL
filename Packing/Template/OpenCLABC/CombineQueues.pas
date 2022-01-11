uses POCGL_Utils  in '..\..\..\POCGL_Utils';

uses CodeGen      in '..\..\..\Utils\CodeGen';
uses Fixers       in '..\..\..\Utils\Fixers';
uses ATask        in '..\..\..\Utils\ATask';

const exec_orders: array of string = ('Sync', 'Async');

const qs_defs: array of string = (
  'params qs: array of ',
  'qs: sequence of '
);

const MaxQueueStaticArraySize = 7;

begin
  try
    System.IO.Directory.CreateDirectory(GetFullPathRTA('Global\CombineQueues'));
    
    var intr := new FileWriter(GetFullPathRTA('Global\CombineQueues\Interface.template'));
    var impl := new FileWriter(GetFullPathRTA('Global\CombineQueues\Implementation.template'));
    var wr := intr * impl;
    
    loop 3 do wr += #10;
    
    foreach var exec_order in exec_orders do
    begin
      wr += '{$region ';
      wr += exec_order;
      wr += '}'#10#10;
      
      wr += '{$region NonConv}'#10#10;
      
      foreach var q_t in |'Base','Nil','&<T>'| do
      begin
        
        foreach var qs_def in qs_defs do
        begin
          
          wr += 'function Combine';
          wr += exec_order;
          wr += 'Queue';
          wr += q_t.TrimStart('&');
          wr += '(';
          wr += qs_def;
          wr += 'CommandQueue';
          wr += q_t.TrimStart('&');
          wr += ')';
          
          intr += ': CommandQueue';
          intr += q_t.TrimStart('&');
          intr += ';'#10;
          
          impl += ' := QueueArrayUtils.Construct';
          impl += exec_order;
          if q_t<>'Base' then impl += q_t;
          impl += '(qs';
          if q_t<>'Base' then impl += '.Cast&<CommandQueueBase>';
          impl += ');'#10;
          
        end;
        wr += #10;
        
      end;
      
      foreach var q_t in |'Nil','&<T>'| do
      begin
        
        wr += 'function Combine';
        wr += exec_order;
        wr += 'Queue';
        wr += q_t.TrimStart('&');
        wr += '(qs: sequence of CommandQueueBase; last: CommandQueue';
        wr += q_t.TrimStart('&');
        wr += ')';
        
        intr += ': CommandQueue';
        intr += q_t.TrimStart('&');
        intr += ';'#10;
        
        impl += ' := QueueArrayUtils.Construct';
        impl += exec_order;
        impl += q_t;
        impl += '(qs.Append&<CommandQueueBase>(last));'#10;
        wr += #10;
        
      end;
      
      wr += '{$endregion NonConv}'#10#10;
      
      wr += '{$region Conv}'#10#10;
      
      for var need_context := false to true do
      begin
        var reg_name := need_context ? 'Context' : 'NonContext';
        var context_par := need_context ? 'Context, ' : nil;
        
        wr += '{$region ';
        wr += reg_name;
        wr += '}'#10#10;
        
        foreach var qs_def in qs_defs do
        begin
          wr += 'function Combine';
          wr += exec_order;
          wr += 'Queue<TInp, TRes>(conv: Func<array of TInp, ';
          wr += context_par;
          wr += 'TRes>; ';
          wr += qs_def;
          wr += 'CommandQueue<TInp>)';
          
          intr += ': CommandQueue<TRes>;'#10;
          
          impl += ' := new Conv';
          impl += exec_order;
          impl += 'QueueArray';
          if need_context then
            impl += 'C';
          impl += '<TInp, TRes>(qs.ToArray, conv);'#10;
          
        end;
        wr += #10;
        
        for var c := 2 to MaxQueueStaticArraySize do
        begin
          var WriteNumbered := procedure(wr: Writer; a: string)->
          for var i := 1 to c do wr += a.Replace('%', i.ToString);
          
          wr += 'function Combine';
          wr += exec_order;
          wr += 'QueueN';
          wr += c;
          wr += '<';
          WriteNumbered(wr, 'TInp%, ');
          wr += 'TRes>(conv: Func<';
          WriteNumbered(wr, 'TInp%, ');
          wr += context_par;
          wr += 'TRes>';
          WriteNumbered(wr, '; q%: CommandQueue<TInp%>');
          wr += ')';
          
          intr += ': CommandQueue<TRes>;'#10;
          
          impl += ' := new Conv';
          impl += exec_order;
          impl += 'QueueArray';
          impl += c;
          if need_context then
            impl += 'C';
          impl += '<';
          WriteNumbered(impl, 'TInp%, ');
          impl += 'TRes>(';
          WriteNumbered(impl, 'q%, ');
          impl += 'conv);'#10;
          
        end;
        wr += #10;
        
        wr += '{$endregion ';
        wr += reg_name;
        wr += '}'#10#10;
        
      end;
      
      wr += '{$endregion Conv}'#10#10;
      
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