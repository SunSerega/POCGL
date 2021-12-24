unit DescriptionsData;
{$string_nullbased+}

{ $define ParseLevelDebug}

interface

type
  CommentableBase = abstract class
    private _name: string;
    public property Name: string read _name;
    
    public constructor(name: string) := self._name := name?.TrimStart('&');
    private constructor := raise new System.NotSupportedException;
    
    public property FullName: string read; abstract;
    
    public static function FindAllCommentalbes(lns: sequence of string; on_line: string->boolean): sequence of CommentableBase;
    
  end;
  
  CommentableType = sealed class(CommentableBase)
    private re_def: string;
    private is_sealed: boolean;
    public property ReDef: string read re_def;
    
    public constructor(name: string; re_def: string; is_sealed: boolean);
    begin
      inherited Create(name);
      self.re_def := re_def;
      self.is_sealed := is_sealed;
    end;
    
    public property FullName: string read self.Name; override;
    
    public static function Parse(l: string): CommentableType;
    
  end;
  CommentableTypeMember = abstract class(CommentableBase)
    private t: CommentableType;
    public property &Type: CommentableType read t;
    
    private function GetFullName: string;
    begin
      var res := new StringBuilder;
      
      if self.Type<>nil then
      begin
        res += self.Type.FullName;
        res += '.';
      end;
      
      if self.Name<>nil then
        res += self.Name;
      
      Result := res.ToString;
    end;
    public property FullName: string read GetFullName; override;
    
    public constructor(t: CommentableType; name: string);
    begin
      inherited Create(name);
      self.t := t;
    end;
    
  end;
  
  CommentableMethod = class(CommentableTypeMember)
    private _args: array of string;
    public property Args: array of string read _args;
    
    public constructor(t: CommentableType; name: string; args: array of string);
    begin
      inherited Create(t, name);
      self._args := args;
    end;
    
    private function GetFullName: string;
    begin
      var res := new StringBuilder(inherited GetFullName);
      
      if self.Args<>nil then
      begin
        res += '(';
        res += Args.JoinToString(', ');
        res += ')';
      end;
      
      Result := res.ToString;
    end;
    public property FullName: string read GetFullName; override;
    
    public static function Parse(l: string; t: CommentableType): CommentableMethod;
    
  end;
  CommentableConstructor = sealed class(CommentableMethod)
    
    public constructor(t: CommentableType; args: array of string) :=
    inherited Create(t, nil, args);
    
    public static function Parse(l: string; t: CommentableType): CommentableConstructor;
    
  end;
  
  CommentableProp = sealed class(CommentableTypeMember)
    private args: array of string;
    
    public constructor(t: CommentableType; name: string; args: array of string);
    begin
      inherited Create(t, name);
      self.args := args;
    end;
    
    private function GetFullName: string;
    begin
      var res := new StringBuilder(inherited GetFullName);
      
      if self.Args<>nil then
      begin
        res += '[';
        res += Args.JoinToString(', ');
        res += ']';
      end;
      
      Result := res.ToString;
    end;
    public property FullName: string read GetFullName; override;
    
    public static function Parse(l: string; t: CommentableType): CommentableProp;
    
  end;
  
  CommentableEvent = sealed class(CommentableTypeMember)
    
    public static function Parse(l: string; t: CommentableType): CommentableEvent;
    
  end;
  
implementation

{$region Utils}

function IsNamePart(self: char): boolean; extensionmethod :=
self.IsLetter or self.IsDigit or (self = '_');

function IndexOfSpaced(self: string; start_ind: integer; kw: string): integer?; extensionmethod;
begin
  Result := nil;
  var res := self.IndexOf(kw, start_ind);
  if res=-1 then exit;
  if (res<>0) and self[res-1].IsNamePart then exit;
  if (res+kw.Length<>self.Length) and self[res+kw.Length].IsNamePart then exit;
  Result := res;
end;
function IndexOfSpaced(self: string; kw: string): integer?; extensionmethod :=
self.IndexOfSpaced(0, kw);

function ContainsSpaced(self: string; kw: string): boolean; extensionmethod :=
self.IndexOfSpaced(kw) <> nil;

function IndexOfAnyG(self: string; start_ind: integer; finder: (string,integer,string)->integer?; params strs: array of string): integer?; extensionmethod;
begin
  Result := nil;
  
  foreach var s in strs do
  begin
    var res := finder(self, start_ind, s);
    if res=nil then continue;
    if (Result=nil) or (res.Value < Result.Value) then
      Result := res;
  end;
  
end;

function IndexOfAny(self: string; start_ind: integer; params strs: array of string): integer?; extensionmethod :=
self.IndexOfAnyG(start_ind, (self,start_ind,s)->
begin
  Result := self.IndexOf(s, start_ind);
  if Result=-1 then Result := nil;
end, strs);
function IndexOfAny(self: string; params strs: array of string): integer?; extensionmethod :=
self.IndexOfAny(0, strs);

function IndexOfAnySpaced(self: string; start_ind: integer; params strs: array of string): integer?; extensionmethod :=
self.IndexOfAnyG(start_ind, (self,start_ind,s)->self.IndexOfSpaced(start_ind, s), strs);
function IndexOfAnySpaced(self: string; params strs: array of string): integer?; extensionmethod :=
self.IndexOfAnySpaced(0, strs);

//function IndexOfAny(self: string; params strs: array of string): integer; extensionmethod :=
//self.IndexOfAny(0, strs);

function SmartIndexOf(self: string; ch: char; ind: integer): integer; extensionmethod;
begin
  
  var br_lvl := 0;
  while (self[ind]<>ch) or (br_lvl<>0) do
  begin
    
    case self[ind] of
      '(': br_lvl += 1;
      ')': br_lvl -= 1;
    end;
    
    ind += 1;
    if ind=self.Length then
    begin
      Result := -1;
      exit;
    end;
    
  end;
  
  Result := ind;
end;

function RemoveBlock(self: string; f,t: string): string; extensionmethod;
begin
  
  while true do
  begin
    var ind1 := self.IndexOf(f);
    if ind1=-1 then break;
    var ind2 := self.IndexOf(t, ind1+f.Length);
    if ind2=-1 then break;
    ind2 += t.Length;
    self := self.Remove(ind1, ind2-ind1);
  end;
  
  Result := self;
end;

function GetArgs(l: string; ind1: integer; start_sym, end_sym: char): array of string;
begin
  if l[ind1] <> start_sym then exit;
  
  ind1 += 1;
  
  var ind2 := l.SmartIndexOf(end_sym, ind1);
  if ind2=-1 then raise new System.InvalidOperationException(l);
  
  Result := l.Substring(ind1, ind2-ind1).Split(';').SelectMany(arg->
  begin
    
    var ind := arg.IndexOf(':=');
    if ind<>-1 then arg := arg.Remove(ind);
    
    ind := arg.IndexOf(':');
    Result := SeqFill(arg.Take(ind).Count(ch->ch=',')+1, arg.Substring(ind+1).Trim);
    
  end).ToArray;
  
end;

{$endregion Utils}

{$region Member parser's}

static function CommentableType.Parse(l: string): CommentableType;
const separator = ' = ';
const type_keywords: array of string = ('record', 'class', 'interface');
begin
  var ind := l.IndexOf(separator);
  if ind=-1 then exit;
  if l.Contains('class;') then exit;
  
  var def := l.Substring(ind+separator.Length);
  var ind2 := def.IndexOf('(');
  if ind2<>-1 then def := def.Remove(ind2);
  var def_wds := def.ToWords;
  
  Result := new CommentableType(
    l.Remove(ind).Trim,
    def_wds.Last in type_keywords ? nil : def,
    'sealed' in def_wds
  );
  
end;

static function CommentableMethod.Parse(l: string; t: CommentableType): CommentableMethod;
const method_keywords: array of string = ('function', 'procedure');
begin
  var ind := l.IndexOfAnySpaced(method_keywords);
  if ind=nil then exit;
  
  ind := l.IndexOf(' ', ind.Value+1) + 1;
  var ind2 := l.IndexOfAny(ind.Value, '(', ':', ':=', ';');
  if ind2=nil then raise new System.InvalidOperationException(l);
  
  var name := l.Substring(ind.Value, ind2.Value-ind.Value).Trim;
  if name.ContainsSpaced('operator') then exit;
  if name.Contains('.') then exit; // Явные реализации интерфейсов
  
  Result := new CommentableMethod(t, name,
    GetArgs(l, ind2.Value, '(', ')')
  );
  
end;

static function CommentableConstructor.Parse(l: string; t: CommentableType): CommentableConstructor;
const constructor_keywords: array of string = ('constructor');
begin
  var ind := l.IndexOfAnySpaced(constructor_keywords);
  if ind=nil then exit;
  
  ind := l.IndexOfAny(ind.Value, '(', ':=', ';');
  if ind=nil then raise new System.InvalidOperationException(l);
  
  Result := new CommentableConstructor(t,
    GetArgs(l, ind.Value, '(', ')')
  );
  
end;

static function CommentableProp.Parse(l: string; t: CommentableType): CommentableProp;
const prop_keywords: array of string = ('property');
begin
  var ind := l.IndexOfAnySpaced(prop_keywords);
  if ind=nil then exit;
  
  ind := l.IndexOf(' ', ind.Value+1) + 1;
  var ind2 := l.IndexOfAny(ind.Value, '[', ':');
  if ind2=nil then raise new System.InvalidOperationException(l);
  
  var name := l.Substring(ind.Value, ind2.Value-ind.Value).Trim;
  if name.Contains('.') then exit; // явные реализации интерфейсов
  
  Result := new CommentableProp(t, name,
    GetArgs(l, ind2.Value, '[', ']')
  );
  
end;

static function CommentableEvent.Parse(l: string; t: CommentableType): CommentableEvent;
const event_keywords: array of string = ('event');
begin
  var ind := l.IndexOfAnySpaced(event_keywords);
  if ind=nil then exit;
  
  ind := l.IndexOf(' ', ind.Value+1) + 1;
  var ind2 := l.IndexOf(':', ind.Value);
  if ind2=-1 then raise new System.InvalidOperationException(l);
  
  Result := new CommentableEvent(t,
    l.Substring(ind.Value, ind2-ind.Value).Trim
  );
  
end;

{$endregion Member parser's}

{$region File parser's}

{$ifdef ParseLevelDebug}
var parse_level := 0;
{$endif ParseLevelDebug}

function SkipCodeBlock(l: string; enmr: IEnumerator<string>): boolean;
const block_open_kvds: array of string = ('begin', 'case', 'match', 'try');
begin
  Result := false;
  if l.IndexOfAnySpaced(block_open_kvds)=nil then exit;
  var bl_lvl := 1;
  {$ifdef ParseLevelDebug}
  parse_level += 1;
  {$endif ParseLevelDebug}
  
  while true do
  begin
    
    if l.ContainsSpaced('end') then
    begin
      bl_lvl -= 1;
      {$ifdef ParseLevelDebug}
      parse_level -= 1;
      {$endif ParseLevelDebug}
      if bl_lvl=0 then break;
    end;
    
    if not enmr.MoveNext then raise new System.InvalidOperationException;
    l := enmr.Current;
    
    if l.IndexOfAnySpaced(block_open_kvds)<>nil then
    begin
      bl_lvl += 1;
      {$ifdef ParseLevelDebug}
      parse_level += 1;
      {$endif ParseLevelDebug}
    end;
    
  end;
  
  Result := true;
end;

static function CommentableBase.FindAllCommentalbes(lns: sequence of string; on_line: string->boolean): sequence of CommentableBase;
begin
  var enmr: IEnumerator<string> := lns
  .Where(on_line)
  .Select(l->
  begin
    {$ifdef ParseLevelDebug}
    Writeln($'{parse_level}: {l}');
    {$endif ParseLevelDebug}
    
    var ind := l.IndexOf('//');
    if ind<>-1 then l := l.Remove(ind);
    
    Result := l
      .RemoveBlock('{','}')
      .RemoveBlock('''','''')
      .Trim(' ')
    ;
  end)
  .Where(l->not string.IsNullOrWhiteSpace(l))
  .GetEnumerator;
  
  var start_checking := false;
  var end_checking := false;
  
  while true do
  begin
    {$ifdef ParseLevelDebug}
    parse_level := 0;
    {$endif ParseLevelDebug}
    if not enmr.MoveNext then break;
    var l := enmr.Current;
    
    if not start_checking then
      if l.Contains('interface') then
        start_checking := true else
        continue;
    
    if not end_checking and l.Contains('implementation') then end_checking := true;
    if end_checking then continue;
    
    if CommentableType.Parse(l) is CommentableType(var t) then
    begin
      {$ifdef ParseLevelDebug}
      parse_level := 1;
      {$endif ParseLevelDebug}
      yield t;
      if t.ReDef<>nil then continue;
      if l.Contains('end') then continue;
      
      while true do
      begin
        if not enmr.MoveNext then raise new System.InvalidOperationException;
        l := enmr.Current;
        
        if l.StartsWith('private ') then continue;
        if t.is_sealed and l.StartsWith('protected ') then continue;
        
        if CommentableProp.Parse(l, t) is CommentableProp(var p) then
          yield p else
        if CommentableEvent.Parse(l, t) is CommentableEvent(var e) then
          yield e else
          
        if CommentableMethod.Parse(l, t) is CommentableMethod(var m) then
          yield m else
        if CommentableConstructor.Parse(l, t) is CommentableConstructor(var c) then
          yield c else
          
        if SkipCodeBlock(l, enmr) then
          else
        if l.Contains('end') then
          break;
        
      end;
      
    end else
    begin
      
      if CommentableMethod.Parse(l, nil) is CommentableMethod(var m) then
        yield m else
      if CommentableConstructor.Parse(l, nil) is CommentableConstructor(var c) then
        yield c else
        
    end;
    
  end;
  
end;

{$endregion File parser's}

end.