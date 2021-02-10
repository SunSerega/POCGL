uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses ATask        in '..\..\..\Utils\ATask';
uses Fixers       in '..\..\..\Utils\Fixers';

uses PackingUtils in '..\PackingUtils';
uses CodeGenUtils in '..\CodeGenUtils';

begin
  try
    
    FixerUtils.ReadBlocks(GetFullPathRTA('ContainerCommon\Def.dat'), false).TaskForEach(bl->
    begin
      var t := bl[0];
      var expl_constructor_arg := bl[1].SingleOrDefault;
      
      var dir := GetFullPathRTA($'ContainerCommon\{t}');
      System.IO.Directory.CreateDirectory(dir);
      
      var res_In := new FileWriter(GetFullPath('Interface.template',      dir));
      var res_Im := new FileWriter(GetFullPath('Implementation.template', dir));
      
      var res := res_In * res_Im;
      
      loop 3 do
      begin
        res_In += '    ';
        res += #10;
      end;
      
      var WriteHeader := procedure->
      begin
        res_In += '    ';
        res_In += 'public ';
        res += 'function ';
        res_Im += t;
        res_Im += 'CommandQueue.';
      end;
      
      var WriteResT := procedure->
      begin
        res_In += ': ';
        res_In += t;
        res_In += 'CommandQueue;';
      end;
      
      {$region constructor's}
      
      res_In += '    ';
      res_In += 'public ';
      res += 'constructor';
      res_Im += ' ';
      res_Im += t;
      res_Im += 'CommandQueue.Create';
      res += '(o: ';
      res += t;
      res += ')';
      res_Im += ' := inherited';
      res += ';'#10;
      
      res_In += '    ';
      res_In += 'public ';
      res += 'constructor';
      res_Im += ' ';
      res_Im += t;
      res_Im += 'CommandQueue.Create';
      res += '(q: CommandQueue<';
      res += t;
      res += '>)';
      res_Im += ' := inherited';
      if expl_constructor_arg <> nil then
      begin
        res_Im += ' Create(';
        res_Im += expl_constructor_arg;
        res_Im += ')';
      end;
      res += ';'#10;
      
      res_In += '    ';
      res_In += 'private ';
      res += 'constructor';
      res_Im += ' ';
      res_Im += t;
      res_Im += 'CommandQueue.Create';
      res_Im += ' := inherited';
      res += ';'#10;
      
      res_In += '    ';
      res += #10;
      
      {$endregion constructor's}
      
      res_In += '    ';
      res += '{$region Special .Add''s}'#10;
      
      res_In += '    ';
      res += #10;
      
      {$region AddQueue}
      
      WriteHeader;
      res += 'AddQueue(q: CommandQueueBase)';
      res += ': ';
      res += t;
      res += 'CommandQueue;'#10;
      res_Im += 'begin'#10;
      res_Im += '  Result := self;'#10;
      res_Im += '  if q is IConstQueue then raise new System.ArgumentException($''%Err:AddQueue(Const)%'');'#10;
      res_Im += '  if q is ICastQueue(var cq) then q := cq.GetQ;'#10;
      
      res_Im += '  commands.Add( new QueueCommand<';
      res_Im += t;
      res_Im += '>(q) );';
      res_Im += #10;
      
      res_Im += 'end;'#10;
      
      res_In += '    ';
      res += #10;
      
      {$endregion AddQueue}
      
      {$region AddProc}
      
      for var need_c := false to true do
      begin
        WriteHeader;
        res += 'AddProc(p: ';
        if need_c then res += '(';
        res += t;
        if need_c then res += ', Context)';
        res += '->())';
        WriteResT;
        res_Im += ' := AddCommand(self, new ProcCommand<';
        res_Im += t;
        res_Im += '>(';
        res_Im += if need_c then 'p' else '(o,c)->p(o)';
        res_Im += '));';
        res += #10;
      end;
      
      res_In += '    ';
      res += #10;
      
      {$endregion AddProc}
      
      {$region AddWait}
      
      foreach var order in |'All', 'Any'| do
      begin
        
        foreach var arg_t in |'array of WaitMarkerBase', 'sequence of WaitMarkerBase'| do
        begin
          WriteHeader;
          res += 'AddWait';
          res += order;
          res += '(';
          if arg_t.StartsWith('array') then res += 'params ';
          res += 'markers: ';
          res += arg_t;
          res += ')';
          WriteResT;
          res_Im += ' := AddCommand(self, new WaitCommand<';
          res_Im += t;
          res_Im += '>(new WCQWaiter';
          res_Im += order;
          res_Im += '(markers.ToArray)));';
          res += #10;
        end;
        
        res_In += '    ';
        res += #10;
      end;
      
      WriteHeader;
      res += 'AddWait(marker: WaitMarkerBase)';
      WriteResT;
      res_Im += ' := AddWaitAll(marker);';
      res += #10;
      
      res_In += '    ';
      res += #10;
      
      {$endregion AddWait}
      
      res_In += '    ';
      res += '{$endregion Special .Add''s}'#10;
      
      loop 2 do
      begin
        res_In += '    ';
        res += #10;
      end;
      res_In += '    ';
      
      res.Close;
    end).SyncExec;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.