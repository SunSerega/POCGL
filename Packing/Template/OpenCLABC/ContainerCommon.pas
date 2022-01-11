uses POCGL_Utils  in '..\..\..\POCGL_Utils';
uses ATask        in '..\..\..\Utils\ATask';
uses Fixers       in '..\..\..\Utils\Fixers';
uses CodeGen      in '..\..\..\Utils\CodeGen';

uses PackingUtils in '..\PackingUtils';

begin
  try
    
    FixerUtils.ReadBlocks(GetFullPathRTA('ContainerCommon\Def.dat'), false).TaskForEach(bl->
    begin
      var t := bl[0];
      
      // (name, where)
      // Вообще where ни на что не используется, потому что эта программа не описывает свои классы
      var generics := new List<(string,string)>;
      
      foreach var (setting_name, setting_data) in FixerUtils.ReadBlocks(bl[1], '!', false) do
      match setting_name with
        
        'Generic':
        foreach var l in setting_data do
        begin
          var ind := l.IndexOf(':');
          generics += (
            (if ind=-1 then l else l.Remove(ind)).Trim,
            if ind=-1 then nil else l.Substring(ind+1).Trim
          );
        end;
        
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
        wr += generics.Select(g->g[0]).JoinToString(', ');
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
      
      {$region AddQueue}
      
      WriteHeader('function', 'public');
      res += 'AddQueue(q: CommandQueueBase): ';
      WriteCCQ(res);
      res += ';'#10;
      res_Im += 'begin'#10;
      res_Im += '  Result := self;'#10;
      res_Im += '  //TODO UseTyped'#10;
      res_Im += '//  if q is IConstQueue then raise new System.ArgumentException($''%Err:AddQueue(Const)%'');'#10;
      res_Im += '//  if q is ICastQueue(var cq) then q := cq.GetQ;'#10;
      
      res_Im += '  commands.Add( BasicGPUCommand&<';
      res_Im += t;
      WriteGenerics(res_Im);
      res_Im += '>.MakeQueue(q) );'#10;
      
      res_Im += 'end;'#10;
      
      res_In += '    ';
      res += #10;
      
      {$endregion AddQueue}
      
      {$region AddProc}
      
      for var need_c := false to true do
      begin
        WriteHeader('function', 'public');
        res += 'AddProc(p: ';
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
        res_Im += '>.MakeProc(p))';
        res += ';'#10;
      end;
      
      res_In += '    ';
      res += #10;
      
      {$endregion AddProc}
      
      {$region AddWait}
      
      WriteHeader('function', 'public');
      res += 'AddWait(marker: WaitMarker)';
      res_In += ': ';
      WriteCCQ(res_In);
      res_Im += ' := AddCommand(self, BasicGPUCommand&<';
      res_Im += t;
      WriteGenerics(res_Im);
      res_Im += '>.MakeWait(marker))';
      res += ';'#10;
      
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