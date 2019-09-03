unit FuncOverloadControlData;

interface

type
  
  {$region Base types}
  
  IOverloadChange = interface
    
    function ApplyToSingleMask(tname: string): string;
    function ApplyToOneOfMasks(par_n: integer; tnames: sequence of string): sequence of string;
    function MakeAllOverloads: List<List<string>>;
    
  end;
  
  OverloadController = abstract class
    public been_used: boolean;
    
    private static AllLoaded := new Dictionary<string, OverloadController>;
    private static property Item[fn: string]: OverloadController read AllLoaded.ContainsKey(fn)?AllLoaded[fn]:nil; default;
    
    public static function ContructNewEmpty(func_name, file_name: string): OverloadController;
    
    public function GetChange: IOverloadChange;
    begin
      been_used := true;
      Result := GetChangeInternal;
    end;
    private function GetChangeInternal: IOverloadChange; abstract;
    
    private static function RemoveCFGComment(l: string) :=
    l.Contains('//')?l.Remove(l.IndexOf('//')):l;
    public static procedure LoadAllFromFile(fname: string);
    
  end;
  
  {$endregion Base types}
  
implementation

type
  
  {$region LVL0}
  
  LVL0ChangeController = sealed class(OverloadController, IOverloadChange)
    
    public function ApplyToSingleMask(tname: string): string := tname;
    public function ApplyToOneOfMasks(par_n: integer; tnames: sequence of string): sequence of string := tnames;
    public function MakeAllOverloads: List<List<string>> := nil;
    
    public function GetChangeInternal: IOverloadChange; override := self;
    
  end;
  
  {$endregion LVL0}
  
  {$region LVL1}
  
  LVL1Change = sealed class(IOverloadChange)
    d: Dictionary<string,IEnumerator<string>>;
    constructor(d: Dictionary<string,IEnumerator<string>>) := self.d := d;
    function NextVal(key: string): string;
    begin
      var enm := d[key];
      if not enm.MoveNext then raise new System.IndexOutOfRangeException;
      Result := enm.Current;
    end;
    
    public function ApplyToSingleMask(tname: string): string := d.ContainsKey(tname)?NextVal(tname):tname;
    public function ApplyToOneOfMasks(par_n: integer; tnames: sequence of string): sequence of string := tnames;
    public function MakeAllOverloads: List<List<string>> := nil;
    
  end;
  
  LVL1Controller = sealed class(OverloadController)
    d: Dictionary<string, sequence of string>;
    
    function GetChangeInternal: IOverloadChange; override := new LVL1Change(self.d.ToDictionary(kvp->kvp.Key,kvp->kvp.Value.GetEnumerator as IEnumerator<string>));
    
    static function Load(sr: System.IO.StreamReader): LVL1Controller;
    begin
      Result := new LVL1Controller;
      
      while not sr.EndOfStream do
      begin
        var l := RemoveCFGComment(sr.ReadLine).Trim;
        if l='' then break;
        
        var ind := l.IndexOf('=>');
        var key := l.Remove(ind);
        
        var vals := l.Substring(ind+2).Split('|').ConvertAll(v->v.Trim);
        var val := vals.Length=1?vals.Cycle:vals;
        
        Result.d.Add(key,val);
      end;
      
      if Result.d.Count=0 then raise new System.InvalidOperationException;
    end;
    
  end;
  
  {$endregion LVL1}
  
  {$region LVL2}
  
  LVL2ChangeController = sealed class(OverloadController, IOverloadChange)
    par_changes: array of (HashSet<string>,HashSet<string>);
    
    function GetChangeInternal: IOverloadChange; override := self;
    
    public function ApplyToSingleMask(tname: string): string := tname;
    public function ApplyToOneOfMasks(par_n: integer; tnames: sequence of string): sequence of string := tnames.Except(par_changes[par_n][0]) + par_changes[par_n][1];
    public function MakeAllOverloads: List<List<string>> := nil;
    
    static function Load(sr: System.IO.StreamReader): LVL2ChangeController;
    begin
      Result := new LVL2ChangeController;
      
      if sr.EndOfStream then raise new System.InvalidOperationException;
      var l := RemoveCFGComment(sr.ReadLine).Trim;
      if l='' then raise new System.InvalidOperationException;
      
      var vals := l.Split('|').ConvertAll(v->v.Trim);
      SetLength(Result.par_changes, vals.Length);
      for var i := 0 to vals.Length-1 do
        if vals[i]='*' then
          Result.par_changes[i] := (new HashSet<string>,new HashSet<string>) else
        begin
          var ind := 1;
          var rem_f := new HashSet<string>;
          var new_f := new HashSet<string>;
          var curr_hs: HashSet<string>;
          var sb := new StringBuilder;
          
          while true do
          begin
            if curr_hs=nil then
              case vals[i][ind] of
                '-': curr_hs := rem_f;
                '+': curr_hs := new_f;
                else raise new System.InvalidOperationException(vals[i]);
              end else
                sb += vals[i][ind];
            
            ind+=1;
            
            if i>vals[i].Length then
            begin
              curr_hs += sb.ToString.Trim;
              break;
            end;
            
            case vals[i][ind] of
              '+','-':
              begin
                curr_hs += sb.ToString.Trim;
                sb.Clear;
                curr_hs := nil;
              end;
            end;
            
          end;
          
          Result.par_changes[i] := (rem_f,new_f);
        end;
      
    end;
    
  end;
  
  {$endregion LVL2}
  
  {$region LVL3}
  
  LVL3ChangeController = sealed class(OverloadController, IOverloadChange)
    pars := new List<List<string>>;
    
    function GetChangeInternal: IOverloadChange; override := self;
    
    public function ApplyToSingleMask(tname: string): string := tname;
    public function ApplyToOneOfMasks(par_n: integer; tnames: sequence of string): sequence of string := tnames;
    public function MakeAllOverloads: List<List<string>> := pars.ConvertAll(l->l.ToList);
    
    static function Load(sr: System.IO.StreamReader): LVL3ChangeController;
    begin
      Result := new LVL3ChangeController;
      
      while not sr.EndOfStream do
      begin
        var l := RemoveCFGComment(sr.ReadLine).Trim;
        if l='' then break;
        
        Result.pars += l.Split('|').ConvertAll(v->v.Trim).ToList;
      end;
      
      if Result.pars.Count=0 then raise new System.InvalidOperationException;
    end;
    
  end;
  
  {$endregion LVL3}
  
static function OverloadController.ContructNewEmpty(func_name, file_name: string): OverloadController;
begin
  Result := new LVL0ChangeController;
  AllLoaded.Add(func_name, Result);
  
  if not System.IO.File.Exists(file_name) then WriteAllText(file_name,#10,new System.Text.UTF8Encoding(true));
  System.IO.File.AppendAllLines(file_name,Seq($'F%{func_name}','T%0',''));
  
end;

static procedure OverloadController.LoadAllFromFile(fname: string);
begin
  var sr := System.IO.File.OpenText(fname);
  
  while not sr.EndOfStream do
  begin
    var l := RemoveCFGComment(sr.ReadLine).Trim;
    if l='' then continue;
    if not l.StartsWith('F%') then raise new System.ArgumentException(l);
    var fn := l.Substring(2);
    if AllLoaded.ContainsKey(fn) then raise new System.InvalidOperationException(fn);
    
    l := RemoveCFGComment(sr.ReadLine).Trim;
    if not l.StartsWith('T%') then raise new System.ArgumentException(l);
    
    var curr: OverloadController;
    case l.Substring(2).ToInteger of
      0: curr := new LVL0ChangeController;
      1: curr := LVL1Controller.Load(sr);
      2: curr := LVL2ChangeController.Load(sr);
      3: curr := LVL3ChangeController.Load(sr);
      else raise new System.NotImplementedException(l);
    end;
    
    AllLoaded.Add(fn, curr);
  end;
end;

end.