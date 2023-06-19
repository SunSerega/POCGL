unit ChoiseSets;

type
  
  {$region MultiBooleanChoiseSet}
  
  MultiBooleanChoise = record
    private flags: array of cardinal;
    private state := cardinal(0);
    
    public property IsFirst: boolean read state=0;
    public property IsLast: boolean read state=flags.Last(f->f<>0)*2-1;
    
    public property Flag[i: integer]: boolean read (state and flags[i]) <> 0;
    
  end;
  
  MultiBooleanChoiseSet = record
    private size := cardinal(1);
    private flags: array of cardinal;
    
    private procedure Init(c: integer; can: array of boolean);
    begin
      flags := new cardinal[c];
      for var i := 0 to c-1 do
      begin
        if (can<>nil) and not can[i] then continue;
        flags[i] := size;
        size *= 2;
      end;
      if size=0 then raise new System.NotSupportedException; // >32
    end;
    
    public constructor(c: integer) := Init(c, nil);
    public constructor(can: array of boolean) := Init(can.Length, can);
    public constructor := raise new System.InvalidOperationException;
    
    public property StatesCount: cardinal read self.size;
    
    public function Enmr: sequence of MultiBooleanChoise;
    begin
      var res: MultiBooleanChoise;
      res.flags := self.flags;
      while res.state<self.size do
      begin
        yield res;
        res.state += 1;
      end;
    end;
    
  end;
  
  {$endregion MultiBooleanChoiseSet}
  
  {$region MultiIntegerChoiseSet}
  //TODO Actually use (in InitOverloads)
  
  _MultiChoiseSep = record
    private s_div, s_mod: cardinal;
    
    private function Next: cardinal;
    begin
      Result := s_div * s_mod;
      {$ifdef DEBUG}
      if Result div s_mod <> s_div then
        raise new System.InvalidOperationException;
      {$endif DEBUG}
    end;
    
  end;
  
  MultiChoise = record
    private state_seps: array of _MultiChoiseSep;
    private state := cardinal(0);
    
    public property IsFirst: boolean read state=0;
    public property IsLast: boolean read state=state_seps[0].Next;
    
    public property Choise[i: integer]: integer read
      state div state_seps[i].s_div mod state_seps[i].s_mod;
    
  end;
  
  MultiChoiseSet = record
    private size := cardinal(1);
    private state_seps: array of _MultiChoiseSep;
    
    private procedure Init(c: integer; state_counts: sequence of integer);
    begin
      state_seps := new _MultiChoiseSep[c];
      foreach var state_c in state_counts.Reverse index i do
      begin
        var si := c-1-i;
        self.state_seps[si].s_div := self.size;
        self.state_seps[si].s_mod := state_c;
        self.size := self.state_seps[si].Next;
      end;
      {$ifdef DEBUG}
      if self.state_seps[0].s_mod=0 then
        raise new System.InvalidOperationException;
      {$endif DEBUG}
    end;
    
    public constructor(number_of_state, state_counts: integer) := Init(number_of_state, state_counts.Step(0));
    public constructor(state_counts: IList<integer>) := Init(state_counts.Count, state_counts);
    public constructor := raise new System.InvalidOperationException;
    
    public property StateCount: cardinal read self.size;
    
    public function Enmr: sequence of MultiChoise;
    begin
      var res: MultiChoise;
      res.state_seps := self.state_seps;
      while res.state<self.size do
      begin
        yield res;
        res.state += 1;
      end;
    end;
    
  end;
  
  {$endregion MultiIntegerChoiseSet}
  
end.