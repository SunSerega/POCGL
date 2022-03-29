uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses ATask        in '..\..\..\Utils\ATask';
uses Fixers       in '..\..\..\Utils\Fixers';
uses CodeGen      in '..\..\..\Utils\CodeGen';

uses PackingUtils in '..\PackingUtils';

begin
  try
    
    FixerUtils.ReadBlocks(GetFullPathRTA('!Def\ContainerCommon.dat'), true).TaskForEach(\(t,lines)->
    begin
      var generics := new List<string>;
      
      foreach var (setting_name, setting_lines) in FixerUtils.ReadBlocks(lines, '!', false) do
      match setting_name with
        
        'Generic':
        generics.AddRange(setting_lines);
        
        else raise new System.InvalidOperationException(setting_name);
      end;
      
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
      res += '(o: ';
      res += t;
      WriteGenerics(res);
      res += ')';
      res_Im += ' := inherited';
      res += ';'#10;
      
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
      res_Im += '  var comm := BasicGPUCommand&<';
      res_Im += t;
      WriteGenerics(res_Im);
      res_Im += '>.MakeQueue(q);'#10;
      res_Im += '  Result := if comm=nil then self else AddCommand(self, comm);'#10;
      
      res_Im += 'end;'#10;
      
      res_In += '    ';
      res += #10;
      
      {$endregion ThenQueue}
      
      {$region ThenProc}
      
      for var is_quick := false to true do
      begin
        var quick_word := if is_quick then 'Quick' else 'Background';
        
        for var need_c := false to true do
        begin
          WriteHeader('function', 'public');
          res += 'Then';
          if is_quick then res += quick_word;
          res += 'Proc(p: ';
          if need_c then res += '(';
          res += t;
          WriteGenerics(res);
          if need_c then res += ', Context)';
          res += '->())';
          res_In += ': ';
          WriteCCQ(res_In);
          res_Im += ' := AddCommand(self, BasicGPUCommand&<';
          res_Im += t;
          WriteGenerics(res_Im);
          res_Im += '>.Make';
          res_Im += quick_word;
          res_Im += 'Proc(p))';
          res += ';'#10;
        end;
        
      end;
      
      res_In += '    ';
      res += #10;
      
      {$endregion ThenProc}
      
      {$region ThenWait}
      
      WriteHeader('function', 'public');
      res += 'ThenWait(marker: WaitMarker)';
      res_In += ': ';
      WriteCCQ(res_In);
      res_Im += ' := AddCommand(self, BasicGPUCommand&<';
      res_Im += t;
      WriteGenerics(res_Im);
      res_Im += '>.MakeWait(marker))';
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