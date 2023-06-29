uses '../../../../POCGL_Utils';
uses '../../../../Utils/ATask';
uses '../../../../Utils/Fixers';
uses '../../../../Utils/CodeGen';

uses '../../Common/PackingUtils';

begin
  try
    
    FixerUtils.ReadBlocks(GetFullPathRTA('!Def/ContainerCommon.dat'), true).TaskForEach(\(t,lines)->
    begin
      var generics := new List<string>;
      
      foreach var (setting_name, setting_lines) in FixerUtils.ReadBlocks(lines, '!', false) do
      match setting_name with
        
        'Generic':
        generics.AddRange(setting_lines);
        
        else raise new System.InvalidOperationException(setting_name);
      end;
      
      var dir := GetFullPathRTA($'ContainerCommon/{t}');
      System.IO.Directory.CreateDirectory(dir);
      
      var res_In := new FileWriter(GetFullPath('Interface.template',      dir));
      var res_Im := new FileWriter(GetFullPath('Implementation.template', dir));
      
      var res := res_In * res_Im;
      
      loop 3 do
      begin
        res_In += '    ';
        res += #10;
      end;
      
      var WriteGenerics := procedure(wr: Writer)->
      if generics.Count<>0 then
      begin
        wr += '<';
        wr += generics.JoinToString(', ');
        wr += '>';
      end;
      
      var WriteCCQ := procedure(wr: Writer)->
      begin
        wr += t;
        wr += 'CCQ';
        WriteGenerics(wr);
      end;
      
      var WriteHeader := procedure(keyword, vis: string)->
      begin
        res_In += '    ';
        res_In += vis;
        res_In += ' ';
        res += keyword;
        res_Im += ' ';
        if keyword<>'constructor' then
          res_In += ' ';
        WriteCCQ(res_Im);
        res_Im += '.';
      end;
      
      {$region constructor's}
      
      WriteHeader('constructor', 'public');
      res_Im += 'Create';
      res += '(q: CommandQueue<';
      res += t;
      WriteGenerics(res);
      res += '>)';
      res_Im += ' := inherited';
      res += ';'#10;
      
      WriteHeader('constructor', 'private');
      res_Im += 'Create';
      res_Im += ' := inherited';
      res += ';'#10;
      
      res_In += '    ';
      res += #10;
      
      {$endregion constructor's}
      
      {$region MakeCCQ}
      
      res_Im += '/// %CommandQueue<';
      res_Im += t;
      WriteGenerics(res_Im);
      res_Im += '>.MakeCCQ%'#10;
      res_Im += 'function MakeCCQ';
      WriteGenerics(res_Im);
      res_Im += '(self: CommandQueue<';
      res_Im += t;
      WriteGenerics(res_Im);
      res_Im += '>): ';
      res_Im += t;
      res_Im += 'CCQ';
      WriteGenerics(res_Im);
      res_Im += '; extensionmethod;';
      if generics.Count<>0 then
      begin
        res_Im += ' where ';
        res_Im += generics.JoinToString(',');
        res_Im += ': record;';
      end;
      res_Im += #10;
      res_Im += 'begin'#10;
      res_Im += '  Result := new ';
      res_Im += t;
      res_Im += 'CCQ';
      WriteGenerics(res_Im);
      res_Im += '(self);'#10;
      res_Im += 'end;'#10;
      res_Im += #10;
      
      {$endregion MakeCCQ}
      
      res_In += '    ';
      res += '{$region Special .Add''s}'#10;
      
      res_In += '    ';
      res += #10;
      
      {$region ThenQueue}
      
      WriteHeader('function', 'public');
      res += 'ThenQueue(q: CommandQueueBase): ';
      WriteCCQ(res);
      res += ';'#10;
      res_Im += 'begin'#10;
      res_Im += '  var comm := QueueCommandConstructor&<';
      res_Im += t;
      WriteGenerics(res_Im);
      res_Im += '>.Make(q);'#10;
      res_Im += '  Result := if comm=nil then self else AddCommand(self, comm);'#10;
      
      res_Im += 'end;'#10;
      
      res_In += '    ';
      res += #10;
      
      {$endregion ThenQueue}
      
      {$region ThenProc}
      
      foreach var need_c in |false,true| do
      begin
        WriteHeader('function', 'public');
        res += 'ThenProc(p: ';
        if need_c then res += '(';
        res += t;
        WriteGenerics(res);
        if need_c then res += ', CLContext)';
        res += '->(); ';
        res_In += 'need_own_thread: boolean := true; can_pre_calc: boolean := false';
        res_Im += 'need_own_thread, can_pre_calc: boolean';
        res += ')';
        res_In += ': ';
        WriteCCQ(res_In);
        res_Im += ' := AddCommand(self, ProcCommandConstructor&<';
        res_Im += t;
        WriteGenerics(res_Im);
        res_Im += '>.Make&<SimpleProcContainer';
        if need_c then res_Im += 'C';
        res_Im += '<';
        res_Im += t;
        WriteGenerics(res_Im);
        res_Im += '>>(p, need_own_thread, can_pre_calc))';
        res += ';'#10;
      end;
      
      res_In += '    ';
      res += #10;
      
      {$endregion ThenProc}
      
      {$region ThenWait}
      
      WriteHeader('function', 'public');
      res += 'ThenWait(marker: WaitMarker)';
      res_In += ': ';
      WriteCCQ(res_In);
      res_Im += ' := AddCommand(self, WaitCommandConstructor&<';
      res_Im += t;
      WriteGenerics(res_Im);
      res_Im += '>.Make(marker))';
      res += ';'#10;
      
      res_In += '    ';
      res += #10;
      
      {$endregion ThenWait}
      
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