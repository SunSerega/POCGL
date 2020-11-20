uses POCGL_Utils  in '..\..\..\POCGL_Utils';

uses AOtp         in '..\..\..\Utils\AOtp';
uses ATask        in '..\..\..\Utils\ATask';
uses Fixers       in '..\..\..\Utils\Fixers';

const exec_orders: array of string = ('Sync', 'Async');

const qs_defs: array of string = (
  'params qs: array of ',
  'qs: sequence of '
);

const MaxQueueStaticArraySize = 7;

begin
  try
    
    (
      ProcTask(()->
      begin
        var res := new System.IO.StreamWriter(GetFullPathRTA('CombineQueues.Interface.template'), false, enc);
        loop 3 do res.WriteLine;
        
        foreach var exec_order in exec_orders do
        begin
          res.WriteLine($'{{$region {exec_order}}}');
          res.WriteLine;
          
          res.WriteLine($'{{$region NonConv}}');
          res.WriteLine;
          foreach var qs_def in qs_defs do
            res.WriteLine($'function Combine{exec_order}QueueBase({qs_def}CommandQueueBase): CommandQueueBase;');
          res.WriteLine;
          res.WriteLine($'function Combine{exec_order}Queue<T>(qs: sequence of CommandQueueBase; last: CommandQueue<T>): CommandQueue<T>;');
          res.WriteLine;
          foreach var qs_def in qs_defs do
            res.WriteLine($'function Combine{exec_order}Queue<T>({qs_def}CommandQueue<T>): CommandQueue<T>;');
          res.WriteLine;
          res.WriteLine($'{{$endregion NonConv}}');
          res.WriteLine;
          
          res.WriteLine($'{{$region Conv}}');
          res.WriteLine;
          for var need_context := false to true do
          begin
            var reg_name := need_context ? 'Context' : 'NonContext';
            var context_par := need_context ? 'Context, ' : nil;
            
            res.WriteLine($'{{$region {reg_name}}}');
            res.WriteLine;
            foreach var qs_def in qs_defs do
              res.WriteLine($'function Combine{exec_order}Queue<TRes>(conv: Func<array of object, {context_par}TRes>; {qs_def}CommandQueueBase): CommandQueue<TRes>;');
            res.WriteLine;
            foreach var qs_def in qs_defs do
              res.WriteLine($'function Combine{exec_order}Queue<TInp, TRes>(conv: Func<array of TInp, {context_par}TRes>; {qs_def}CommandQueue<TInp>): CommandQueue<TRes>;');
            res.WriteLine;
            for var c := 2 to MaxQueueStaticArraySize do
            begin
              res.Write($'function Combine{exec_order}Queue{c}<');
              for var i := 1 to c do
                res.Write($'TInp{i}, ');
              res.Write('TRes>(conv: Func<');
              for var i := 1 to c do
                res.Write($'TInp{i}, ');
              res.Write($'{context_par}TRes>');
              for var i := 1 to c do
                res.Write($'; q{i}: CommandQueue<TInp{i}>');
              res.Write('): CommandQueue<TRes>;');
              res.WriteLine;
            end;
            res.WriteLine;
            res.WriteLine($'{{$endregion {reg_name}}}');
            res.WriteLine;
          end;
          res.WriteLine($'{{$endregion Conv}}');
          res.WriteLine;
          
          res.WriteLine($'{{$endregion {exec_order}}}');
          res.WriteLine;
        end;
        
        loop 1 do res.WriteLine;
        res.Close;
      end)
    *
      ProcTask(()->
      begin
        var res := new System.IO.StreamWriter(GetFullPathRTA('CombineQueues.Implementation.template'), false, enc);
        loop 3 do res.WriteLine;
        
        foreach var exec_order in exec_orders do
        begin
          res.WriteLine($'{{$region {exec_order}}}');
          res.WriteLine;
          
          res.WriteLine($'{{$region NonConv}}');
          res.WriteLine;
          foreach var qs_def in qs_defs do
            res.WriteLine($'function Combine{exec_order}QueueBase({qs_def}CommandQueueBase) := new Simple{exec_order}QueueArray<object>(QueueArrayUtils.Flatten{exec_order}QueueArray(qs));');
          res.WriteLine;
          res.WriteLine($'function Combine{exec_order}Queue<T>(qs: sequence of CommandQueueBase; last: CommandQueue<T>) := new Simple{exec_order}QueueArray<T>(QueueArrayUtils.Flatten{exec_order}QueueArray(qs.Append(last as CommandQueueBase)));');
          res.WriteLine;
          foreach var qs_def in qs_defs do
            res.WriteLine($'function Combine{exec_order}Queue<T>({qs_def}CommandQueue<T>) := new Simple{exec_order}QueueArray<T>(QueueArrayUtils.Flatten{exec_order}QueueArray(qs.Cast&<CommandQueueBase>));');
          res.WriteLine;
          res.WriteLine($'{{$endregion NonConv}}');
          res.WriteLine;
          
          res.WriteLine($'{{$region Conv}}');
          res.WriteLine;
          for var need_context := false to true do
          begin
            var reg_name := need_context ? 'Context' : 'NonContext';
            var context_par := need_context ? 'Context, ' : nil;
            var conv_in_call := need_context ? 'conv' : '(a,c)->conv(a)';
            
            res.WriteLine($'{{$region {reg_name}}}');
            res.WriteLine;
            foreach var qs_def in qs_defs do
              res.WriteLine($'function Combine{exec_order}Queue<TRes>(conv: Func<array of object, {context_par}TRes>; {qs_def}CommandQueueBase) := new Conv{exec_order}QueueArray<object, TRes>(qs.Select(q->q.Cast&<object>).ToArray, {conv_in_call});');
            res.WriteLine;
            foreach var qs_def in qs_defs do
              res.WriteLine($'function Combine{exec_order}Queue<TInp, TRes>(conv: Func<array of TInp, {context_par}TRes>; {qs_def}CommandQueue<TInp>) := new Conv{exec_order}QueueArray<TInp, TRes>(qs.ToArray, {conv_in_call});');
            res.WriteLine;
            for var c := 2 to MaxQueueStaticArraySize do
            begin
              res.Write($'function Combine{exec_order}Queue{c}<');
              for var i := 1 to c do
                res.Write($'TInp{i}, ');
              res.Write('TRes>(conv: Func<');
              for var i := 1 to c do
                res.Write($'TInp{i}, ');
              res.Write($'{context_par}TRes>');
              for var i := 1 to c do
                res.Write($'; q{i}: CommandQueue<TInp{i}>');
              res.Write($') := new Conv{exec_order}QueueArray{c}<');
              for var i := 1 to c do
                res.Write($'TInp{i}, ');
              res.Write($'TRes>(');
              for var i := 1 to c do
                res.Write($'q{i}, ');
              if need_context then
                res.Write('conv') else
              begin
                res.Write('(');
                for var i := 1 to c do
                  res.Write($'o{i}, ');
                res.Write('c)->conv(o1');
                for var i := 2 to c do
                  res.Write($', o{i}');
                res.Write(')');
              end;
              res.Write(');');
              res.WriteLine;
            end;
            res.WriteLine;
            res.WriteLine($'{{$endregion {reg_name}}}');
            res.WriteLine;
          end;
          res.WriteLine($'{{$endregion Conv}}');
          res.WriteLine;
          
          res.WriteLine($'{{$endregion {exec_order}}}');
          res.WriteLine;
        end;
        
        loop 2 do res.WriteLine;
        res.Close;
      end)
    ).SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.