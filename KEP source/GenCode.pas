uses AOtp           in '..\AOtp';
uses SubExecutables in '..\SubExecutables';
uses CodeGen        in '..\CodeGen';

uses KEP in '..\KEP';

{$region Wrap}
type
  
  {$region Base}
  
  SyntaxDefWriterBase = abstract partial class(DefWrapperBase)
    
    public procedure RaiseError(message: string); abstract;
    
  end;
  SyntaxDefWriter<T> = abstract partial class(SyntaxDefWriterBase)
  where T: SyntaxDef;
    protected def: T;
    
    public constructor(def: T) := self.def := def;
    private constructor := raise new System.InvalidOperationException;
    
    public procedure RaiseError(message: string); override :=
    raise new DefWrapperException(message, self.def);
    
  end;
  
  {$endregion Base}
  
  {$region Independant}
  
  LiteralDefWriter = sealed partial class(SyntaxDefWriter<LiteralDef>)
    private literal_value: string;
    
    public constructor(l: LiteralDef);
    begin
      inherited Create(l);
      literal_value := l.LiteralValue;
    end;
    
    protected procedure AddChild(name: string; dw: DefWrapperBase); override :=
    raise new System.InvalidOperationException;
    protected procedure SealChildren; override := exit;
    
  end;
  
  SpecialNameDefWriter = sealed partial class(SyntaxDefWriterBase)
    private static allowed_names := |'char', 'space', 'letter', 'digit'|;
    private name: string;
    
    public constructor(name: string) := self.name := name;
    private constructor := raise new System.InvalidOperationException;
    
    protected procedure AddChild(name: string; dw: DefWrapperBase); override :=
    raise new System.InvalidOperationException;
    protected procedure SealChildren; override := exit;
    
    public procedure RaiseError(message: string); override :=
    raise new System.InvalidOperationException;
    
  end;
  
  {$endregion Independant}
  
  {$region Modifier}
  
  ModifierDefWriter<T> = abstract partial class(SyntaxDefWriter<T>)
  where T: ModifierDef;
    protected sub_def: SyntaxDefWriterBase;
    
    public constructor(m: T);
    begin
      inherited Create(m);
    end;
    
    protected procedure AddChild(name: string; dw: DefWrapperBase); override;
    begin
      if name<>'sub_def' then raise new System.InvalidOperationException;
      sub_def := SyntaxDefWriterBase(dw);
    end;
    protected procedure SealChildren; override := exit;
    
  end;
  
  OptionalDefWriter = sealed partial class(ModifierDefWriter<OptionalDef>)
    
    public constructor(o: OptionalDef);
    begin
      inherited Create(o);
    end;
    
  end;
  
  NegateDefWriter = sealed partial class(ModifierDefWriter<NegateDef>)
    
    public constructor(n: NegateDef);
    begin
      inherited Create(n);
    end;
    
  end;
  
  ArrayDefWriter = sealed partial class(ModifierDefWriter<ArrayDef>)
    protected separator := default(SyntaxDefWriterBase);
    
    public constructor(a: ArrayDef);
    begin
      inherited Create(a);
    end;
    
    protected procedure AddChild(name: string; dw: DefWrapperBase); override;
    begin
      case name of
        'sub_def':    self.sub_def    := SyntaxDefWriterBase(dw);
        'separator':  self.separator  := SyntaxDefWriterBase(dw);
        else raise new System.InvalidOperationException;
      end;
    end;
    protected procedure SealChildren; override := exit;
    
  end;
  
  {$endregion Modifier}
  
  {$region Container}
  
  ContainerChildInfo = record
    public child: SyntaxDefWriterBase;
    public name: string;
    public name_explicit: boolean;
    
    public constructor(dw: SyntaxDefWriterBase; name: string);
    begin
      self.child := dw;
      self.name := name;
      self.name_explicit := name<>nil;
    end;
    
  end;
  ContainerDefWriter<T> = abstract partial class(SyntaxDefWriter<T>)
  where T: ContainerDef;
    protected children := new List<ContainerChildInfo>;
    
    public constructor(c: T);
    begin
      inherited Create(c);
    end;
    
    protected procedure AddChild(name: string; _dw: DefWrapperBase); override :=
    children += new ContainerChildInfo(SyntaxDefWriterBase(_dw), name);
    protected procedure SealChildren; override := exit;
    
    protected procedure NameAllChildren;
    begin
      var name_i := 0;
      for var i := 0 to children.Count-1 do
      begin
        var info := children[i];
        if info.name_explicit then continue;
        repeat
          name_i += 1;
          info.name := 'item'+name_i;
        until not children.Any(info2->info2.name=info.name);
        children[i] := info;
      end;
    end;
    
  end;
  
  PaletteDefWriter = sealed partial class(ContainerDefWriter<PaletteDef>)
    
    public constructor(p: PaletteDef);
    begin
      inherited Create(p);
    end;
    
  end;
  
  BlockDefWriter<T> = abstract partial class(ContainerDefWriter<T>)
  where T: BlockDef;
    protected origin_child := default(SyntaxDefWriterBase);
    
    public constructor(bl: T);
    begin
      inherited Create(bl);
    end;
    
    protected procedure SealChildren; override;
    begin
      inherited;
      if self.def.HasOrigin then
        origin_child := children[self.def.OriginInd].child;
    end;
    
  end;
  
  NamedBlockDefWriter = sealed partial class(BlockDefWriter<NamedBlockDef>)
    private static All := new Dictionary<string, NamedBlockDefWriter>;
    private name: string;
    private can_inline := false;
    private can_replace := false;
    
    public constructor(bl: NamedBlockDef);
    begin
      inherited Create(bl);
      name := bl.BlockName;
      match bl.BlockNameModifier with
        nil: can_inline := true;
        '>': ;
        '?': can_replace := true;
        else raise new System.InvalidOperationException(bl.BlockNameModifier.Value)
      end;
      All.Add(name, self);
    end;
    
    public static procedure ReportUnused(blocks: Dictionary<string, NamedBlockDef>) :=
    foreach var name in blocks.Keys do
      if not NamedBlockDefWriter.All.ContainsKey(name) then
        Otp($'WARNING: Block [{name}] wasn''t used');
    
  end;
  
  NamelessBlockDefWriter = sealed partial class(BlockDefWriter<NamelessBlockDef>)
    
    public constructor(bl: NamelessBlockDef);
    begin
      inherited Create(bl);
    end;
    
  end;
  
  {$endregion Container}
  
{$endregion Wrap}

{$region Prepare}
type
  
  {$region Base}
  
  SyntaxDefWriterBase = abstract partial class(DefWrapperBase)
    
    //ToDo стэк инлайнинга - чтоб "#name[name]" не давало StackOverflow
    protected function Inline: SyntaxDefWriterBase; abstract;
    protected procedure AssignNewId; abstract;
    
    protected procedure OptimizeBody(cache: Dictionary<SyntaxDefWriterBase, SyntaxDefWriterBase>); abstract;
    protected function Optimize(cache: Dictionary<SyntaxDefWriterBase, SyntaxDefWriterBase>): SyntaxDefWriterBase;
    begin
      if cache.TryGetValue(self, Result) then exit;
      Result := self.Inline;
      cache[self] := Result;
      Result.AssignNewId;
      Result.OptimizeBody(cache);
    end;
    public function Optimize :=
    self.Optimize(new Dictionary<SyntaxDefWriterBase, SyntaxDefWriterBase>);
    
    private static awaiting_write := new List<SyntaxDefWriterBase>;
    protected procedure CountNeededBody(prev: HashSet<SyntaxDefWriterBase>; curr_stack: Stack<SyntaxDefWriterBase>); abstract;
    protected procedure CountNeeded(prev: HashSet<SyntaxDefWriterBase>; curr_stack: Stack<SyntaxDefWriterBase>);
    begin
      if self is NamedBlockDefWriter then exit;
      if self in curr_stack then
        self.RaiseError($'Syntax def contained itself');
      if prev.Add(self) then
      begin
        curr_stack.Push(self);
        CountNeededBody(prev, curr_stack);
        awaiting_write += self;
        curr_stack.Pop;
      end;
    end;
    
  end;
  SyntaxDefWriter<T> = abstract partial class(SyntaxDefWriterBase)
    
    private static last_id := -1;
    private id := -1;
    protected procedure AssignNewId; override;
    begin
      if self.id<>-1 then raise new System.InvalidOperationException;
      last_id += 1;
      self.id := last_id;
    end;
    
  end;
  
  {$endregion Base}
  
  {$region Independant}
  
  LiteralDefWriter = sealed partial class(SyntaxDefWriter<LiteralDef>)
    
    protected function Inline: SyntaxDefWriterBase; override := self;
    protected procedure OptimizeBody(cache: Dictionary<SyntaxDefWriterBase, SyntaxDefWriterBase>); override := exit;
    
    protected procedure CountNeededBody(prev: HashSet<SyntaxDefWriterBase>; curr_stack: Stack<SyntaxDefWriterBase>); override := exit;
    
  end;
  
  SpecialNameDefWriter = sealed partial class(SyntaxDefWriterBase)
    
    public procedure AssignNewId; override := exit;
    
    protected function Inline: SyntaxDefWriterBase; override := self;
    protected procedure OptimizeBody(cache: Dictionary<SyntaxDefWriterBase, SyntaxDefWriterBase>); override := exit;
    
    protected procedure CountNeededBody(prev: HashSet<SyntaxDefWriterBase>; curr_stack: Stack<SyntaxDefWriterBase>); override := exit;
    
  end;
  
  {$endregion Independant}
  
  {$region Modifier}
  
  ModifierDefWriter<T> = abstract partial class(SyntaxDefWriter<T>)
    
    protected procedure OptimizeBody(cache: Dictionary<SyntaxDefWriterBase, SyntaxDefWriterBase>); override :=
    self.sub_def := self.sub_def.Optimize(cache);
    
    protected procedure CountNeededBody(prev: HashSet<SyntaxDefWriterBase>; curr_stack: Stack<SyntaxDefWriterBase>); override :=
    sub_def.CountNeeded(prev, curr_stack);
    
  end;
  
  OptionalDefWriter = sealed partial class(ModifierDefWriter<OptionalDef>)
    
    protected function Inline: SyntaxDefWriterBase; override :=
    if self.sub_def is OptionalDefWriter(var o) then
      o.Inline else self;
    
  end;
  
  NegateDefWriter = sealed partial class(ModifierDefWriter<NegateDef>)
    
    protected function Inline: SyntaxDefWriterBase; override := self;
    
  end;
  
  ArrayDefWriter = sealed partial class(ModifierDefWriter<ArrayDef>)
    
    protected function Inline: SyntaxDefWriterBase; override := self;
    
    protected procedure OptimizeBody(cache: Dictionary<SyntaxDefWriterBase, SyntaxDefWriterBase>); override;
    begin
      inherited;
      self.separator := self.separator?.Optimize(cache);
    end;
    
  end;
  
  {$endregion Modifier}
  
  {$region Container}
  
  ContainerDefWriter<T> = abstract partial class(SyntaxDefWriter<T>)
    
    protected function CanInline: boolean; abstract;
    protected function Inline: SyntaxDefWriterBase; override;
    begin
      if (children.Count=1) and CanInline then
        Result := children.Single.child.Inline else
        Result := self;
    end;
    
    protected procedure OptimizeBody(cache: Dictionary<SyntaxDefWriterBase, SyntaxDefWriterBase>); override := NameAllChildren;
    
    protected procedure CountNeededBody(prev: HashSet<SyntaxDefWriterBase>; curr_stack: Stack<SyntaxDefWriterBase>); override :=
    foreach var info in children do info.child.CountNeeded(prev, curr_stack);
    
  end;
  
  PaletteDefWriter = sealed partial class(ContainerDefWriter<PaletteDef>)
    
    protected function CanInline: boolean; override;
    begin
      Result := false; //ToDo #???? - чтоб небыло предупреждения
      // children.Count>=2
      raise new System.InvalidOperationException;
    end;
    
    protected procedure OptimizeBody(cache: Dictionary<SyntaxDefWriterBase, SyntaxDefWriterBase>); override;
    begin
      var new_children := new List<ContainerChildInfo>;
      foreach var info in self.children do
      begin
        var org_child := info.child;
        info.child := org_child.Optimize(cache);
        
        if info.child is PaletteDefWriter(var p) then
        begin
          if info.name_explicit then
            //ToDo #2524
            (self as object as SyntaxDefWriter<PaletteDef>).RaiseError($'Def named [{info.name}] should not be optimizable');
          new_children.AddRange(p.children);
        end else
          new_children += info;
        
      end;
      self.children := new_children;
      inherited;
    end;
    
  end;
  
  IBlockDefWriter = interface
    
    function GetChildren: sequence of ContainerChildInfo;
    function GetOrigin: SyntaxDefWriterBase;
    
  end;
  BlockDefWriter<T> = abstract partial class(ContainerDefWriter<T>, IBlockDefWriter)
    
    public function IBlockDefWriter.GetChildren: sequence of ContainerChildInfo := self.children;
    public function IBlockDefWriter.GetOrigin: SyntaxDefWriterBase := self.origin_child;
    
    protected procedure OptimizeBody(cache: Dictionary<SyntaxDefWriterBase, SyntaxDefWriterBase>); override;
    begin
      var new_children := new List<ContainerChildInfo>;
      var new_origin := default(SyntaxDefWriterBase);
      foreach var info in self.children do
      begin
        var org_child := info.child;
        info.child := org_child.Optimize(cache);
        
        if (info.child is IBlockDefWriter(var bl)) and ((bl.GetOrigin<>nil) = (self.origin_child=org_child)) then
        begin
          if self.origin_child=org_child then
            new_origin := bl.GetOrigin;
          new_children.AddRange(bl.GetChildren);
        end else
        begin
          if self.origin_child=org_child then
            new_origin := info.child;
          new_children += info;
        end;
        
      end;
      self.children := new_children;
      self.origin_child := new_origin;
      inherited;
    end;
    
  end;
  
  NamedBlockDefWriter = sealed partial class(BlockDefWriter<NamedBlockDef>)
    
    protected function CanInline: boolean; override := self.can_inline and (self.origin_child=nil);
    
    protected static procedure CountAllNeeded;
    begin
      var prev := new HashSet<SyntaxDefWriterBase>;
      foreach var bl in All.Values do
        //ToDo #2524
        (bl as object as SyntaxDefWriter<NamedBlockDef>).CountNeededBody(prev, new Stack<SyntaxDefWriterBase>);
      foreach var bl in All.Values do
        SyntaxDefWriterBase.awaiting_write.Add(bl);
    end;
    
  end;
  
  NamelessBlockDefWriter = sealed partial class(BlockDefWriter<NamelessBlockDef>)
    
    protected function CanInline: boolean; override := self.origin_child=nil;
    
  end;
  
  {$endregion Container}
  
{$endregion Prepare}

{$region KMP}

{$region Utils}

{$region CharCondition}

type
  CharCondition = abstract class
    
    public function Check(ch: char): boolean; abstract;
    
  end;
  
  CharConditionLiteral = sealed class(CharCondition)
    private literal: char;
    
    public constructor(literal: char) := self.literal := literal;
    private constructor := raise new System.InvalidOperationException;
    
    public function Check(ch: char): boolean; override := ch=literal;
    
  end;
  CharConditionFunc = sealed class(CharCondition)
    private check_delegate: char->boolean;
    
    public constructor(check_delegate: char->boolean) := self.check_delegate := check_delegate;
    private constructor := raise new System.InvalidOperationException;
    
    public function Check(ch: char): boolean; override := self.check_delegate(ch);
    
  end;
  
  CharConditionNegated = sealed class(CharCondition)
    private sub_cond: CharCondition;
    
    public constructor(sub_cond: CharCondition) := self.sub_cond := sub_cond;
    private constructor := raise new System.InvalidOperationException;
    
    public function Check(ch: char): boolean; override := not sub_cond.Check(ch);
    
  end;
  CharConditionAll = sealed class(CharCondition)
    private sub_conds: array of CharCondition;
    
    public constructor(sub_conds: array of CharCondition) := self.sub_conds := sub_conds;
    private constructor := raise new System.InvalidOperationException;
    
    public function Check(ch: char): boolean; override := sub_conds.All(sub_cond->sub_cond.Check(ch));
    
  end;
  
function operator-(cond: CharCondition): CharCondition; extensionmethod;
begin
  if cond is CharConditionNegated then raise new System.NotImplementedException;
  Result := new CharConditionNegated(cond);
end;

function operator+(cond1, cond2: CharCondition): CharCondition; extensionmethod;
begin
  var l := new List<CharCondition>;
  if cond1 is CharConditionAll(var tca) then l.AddRange(tca.sub_conds) else l += cond1;
  if cond2 is CharConditionAll(var tca) then l.AddRange(tca.sub_conds) else l += cond2;
  Result := new CharConditionAll(l.ToArray);
end;

procedure operator+=(var cond: CharCondition; new_cond: CharCondition); extensionmethod :=
cond := cond+new_cond;

{$endregion CharCondition}

{$region StringCondition}

type
  StringCondition = record
    private chs: array of CharCondition;
    private used_as: array of integer;
    
    public constructor(chs: array of CharCondition) := self.chs := chs;
    public constructor := raise new System.InvalidOperationException;
    
  end;
  
{$endregion StringCondition}

{$region KMP_input}

type
  KMP_input = record
    public data: integer;
    public sub_inputs: array of KMP_input := nil;
    
    public constructor(data: integer) := self.data := data;
    public constructor(sub_inputs: array of KMP_input) :=
    self.sub_inputs := sub_inputs;
    
  end;
  
{$endregion KMP_input}

{$endregion Utils}

type
  {$region Base}
  
  SyntaxDefWriterBase = abstract partial class(DefWrapperBase)
    
    private KMP_conds: array of StringCondition;
    
    protected function BuildKMPTablesBody(prev_cases: array of StringCondition): array of StringCondition; abstract;
    protected function BuildKMPTables(prev_cases: array of StringCondition): array of StringCondition;
    begin
      
      Result := BuildKMPTablesBody(prev_cases);
      
      self.KMP_conds := Result;
      
    end;
    
  end;
  SyntaxDefWriter<T> = abstract partial class(SyntaxDefWriterBase)
    
  end;
  
  {$endregion Base}
  
  {$region Independant}
  
  LiteralDefWriter = sealed partial class(SyntaxDefWriter<LiteralDef>)
    
    private KMP_out_table: array of integer; // parsed_count => KMP_data[0]
    private KMP_in_table: KMP_input; // KMP_data => skip_parse_count
    
    protected function BuildKMPTablesBody(prev_cases: array of StringCondition): array of StringCondition; override;
    begin
      
    end;
    
  end;
  
  SpecialNameDefWriter = sealed partial class(SyntaxDefWriterBase)
    
  end;
  
  {$endregion Independant}
  
  {$region Modifier}
  
  ModifierDefWriter<T> = abstract partial class(SyntaxDefWriter<T>)
    
  end;
  
  OptionalDefWriter = sealed partial class(ModifierDefWriter<OptionalDef>)
    
  end;
  
  NegateDefWriter = sealed partial class(ModifierDefWriter<NegateDef>)
    
  end;
  
  ArrayDefWriter = sealed partial class(ModifierDefWriter<ArrayDef>)
    
  end;
  
  {$endregion Modifier}
  
  {$region Container}
  
  ContainerDefWriter<T> = abstract partial class(SyntaxDefWriter<T>)
    
  end;
  
  PaletteDefWriter = sealed partial class(ContainerDefWriter<PaletteDef>)
    
  end;
  
  BlockDefWriter<T> = abstract partial class(ContainerDefWriter<T>)
    
  end;
  
  NamedBlockDefWriter = sealed partial class(BlockDefWriter<NamedBlockDef>)
    
  end;
  
  NamelessBlockDefWriter = sealed partial class(BlockDefWriter<NamelessBlockDef>)
    
  end;
  
  {$endregion Container}
  
{$endregion KMP}

{$region CodeGen}
type
  
  {$region Utils}
  
  ValidateOptions = record
    private dir: (PD_Prev=0, PD_Next=1);
    private negating_force: (FT_None=0, FT_Negated=1);
    private parse_type: (PT_Direct=0, PT_Indirect=1, PT_TryDirect=2);
    
    public function ForwardParse := dir=PD_Next;
    
    public function ForceCloseLast := negating_force<>FT_None;
    
    public function IndirectParse := parse_type=PT_Indirect;
    public function NeedErrors := parse_type=PT_Direct;
    
    public function GetHashCode: integer; override :=
    (integer(dir) shl 0) or (integer(negating_force) shl 1) or (integer(parse_type) shl 2) or (integer(0) shl 4);
    public function Equals(obj: object): boolean; override :=
    (obj is ValidateOptions(var opt)) and (self=opt);
    
    public procedure Write(wr: Writer; snake_case: boolean);
    begin
      if snake_case then
        wr := new WriterWrapper(wr, s->s.ToLower);
      case dir of
        PD_Prev: wr += 'Prev';
        PD_Next: wr += 'Next';
        else raise new System.NotSupportedException;
      end;
      if negating_force<>FT_None then
      begin
        if snake_case then wr += '_';
        case negating_force of
          FT_Negated: wr += 'Negated';
          else raise new System.NotSupportedException;
        end;
      end;
      if snake_case then wr += '_';
      case parse_type of
        PT_Direct   : wr += 'Direct';
        PT_Indirect : wr += 'Indirect';
        PT_TryDirect: wr += 'TryDirect';
        else raise new System.NotSupportedException;
      end;
    end;
    
  end;
  
  {$endregion Utils}
  
  {$region Base}
  
  SyntaxDefWriterBase = abstract partial class(DefWrapperBase)
    
    protected function ClassName: string; abstract;
    
    private vldt: Writer;
    private impl: Writer;
    private wr: Writer;
    private procedure InitWriters;
    begin
      if wr<>nil then raise new System.InvalidOperationException;
      vldt := new FileWriter($'Templates\{ClassName}-validator_body.template');
      impl := new FileWriter($'Templates\{ClassName}-implementation.template');
      
      wr := vldt*impl;
      
      loop 3 do
      begin
        vldt += '    ';
        wr += #10;
      end;
      
    end;
    private procedure CloseWriters;
    begin
      vldt += '    '#10'    ';
      impl += #10;
      wr.Close;
    end;
    
    protected function IgnoreOptions(opt: ValidateOptions): boolean; abstract;
    protected function TransformOptions(opt: ValidateOptions): ValidateOptions; abstract;
    
    protected procedure WriteValidateHeader(opt: ValidateOptions);
    begin
      vldt += '    public ';
      if true then wr += 'function';
      wr += ' ';
      impl += ClassName;
      impl += 'Validator.';
      wr += 'Validator';
      opt.Write(wr, false);
      wr += '(text: StringSection; ind: StringIndex';
      if opt.NeedErrors then
        wr += '; err: HashSet<ParseException>';
      wr += '): sequence of StringIndex;'#10;
    end;
    
    private options_used := new HashSet<ValidateOptions>;
    private waiting_options := new Queue<ValidateOptions>;
    protected procedure WriteValidate(opt: ValidateOptions); abstract;
    protected procedure AddValidate(opt: ValidateOptions);
    begin
      if IgnoreOptions(opt) then exit;
      opt := TransformOptions(opt);
      waiting_options += opt;
      if waiting_options.Count>1 then exit;
      // In case validate's are added while processing this one
      while waiting_options.Count<>0 do
      begin
        opt := waiting_options.Dequeue;
        if not options_used.Add(opt) then continue;
        WriteValidate(opt);
      end;
    end;
    
    public static procedure WriteAll;
    begin
      var intr := new FileWriter($'Templates\interface.template');
      var impl := new FileWriter($'Templates\implementation.template');
      var wr := intr*impl;
      loop 3 do
      begin
        intr += '  ';
        wr += #10;
      end;
      
      foreach var dw in awaiting_write do
      begin
        intr += '  ';
        wr += '{$region ';
        wr += dw.ClassName;
        wr += '}'#10;
        
        intr += '  ';
        wr += #10;
        
        dw.InitWriters;
        begin
          //ToDo Коментарий, указывающий место в .kep файле
          
          intr += '  ';
          intr += dw.ClassName;
          intr += 'Validator = sealed partial class'#10;
          
          intr += '    '#10;
          
          intr += '    {%';
          intr += dw.ClassName;
          intr += '-validator_body%}'#10;
          
          intr += '    '#10;
          
          intr += '  end;'#10;
          
          intr += '  ';
          intr += dw.ClassName;
          intr += ' = sealed partial class'#10;
          
          intr += '    '#10;
          
          intr += '  end;'#10;
          
          intr += '  ';
          
          intr += '  '#10;
        end;
        begin
          
          impl += '{%';
          impl += dw.ClassName;
          impl += '-implementation%}'#10;
          
          impl += #10;
        end;
        
        intr += '  ';
        wr += '{$endregion ';
        wr += dw.ClassName;
        wr += '}'#10;
        
        intr += '  ';
        wr += #10;
        
      end;
      
      foreach var dw in awaiting_write do
      begin
        var opt: ValidateOptions;
        opt.dir := ValidateOptions.PD_Next;
        opt.negating_force := ValidateOptions.FT_None;
        opt.parse_type := ValidateOptions.PT_Direct;
        dw.AddValidate(opt);
      end;
      
      foreach var dw in awaiting_write do
        dw.CloseWriters;
      intr += '  '#10'  ';
      impl += #10;
      wr.Close;
    end;
    
  end;
  SyntaxDefWriter<T> = abstract partial class(SyntaxDefWriterBase)
    
  end;
  
  {$endregion Base}
  
  {$region Independant}
  
  LiteralDefWriter = sealed partial class(SyntaxDefWriter<LiteralDef>)
    
    //ToDo #2524
    protected function ClassName: string; override := 'Literal'+(self as object as SyntaxDefWriter<LiteralDef>).id;
    
    protected function IgnoreOptions(opt: ValidateOptions): boolean; override := false;
    protected function TransformOptions(opt: ValidateOptions): ValidateOptions; override;
    begin
      // There is nothing to force close in literal
      opt.negating_force := ValidateOptions.FT_None;
      Result := opt;
    end;
    
    protected procedure WriteValidate(opt: ValidateOptions); override;
    begin
      if opt.IndirectParse then
      begin
        vldt += '    private KMP_out_table_';
        vldt += if opt.ForwardParse then 'next' else 'prev';
        vldt += ' := |';
        vldt += KMP_out_table.JoinToString(', ');
        vldt += '|;'#10;
        //ToDo in_table
      end;
      
      WriteValidateHeader(opt);
      
      impl += 'begin'#10;
      var ToDo := 0;
      
      if opt.IndirectParse then
      begin
        //ToDo Записать в spfi поля для KMP
        // - И для литерала ещё + таблица индекс_литерала=>индекс_KMP
      end else
      begin
//        opt.NeedErrors;
        impl += '  '#10;
        
      end;
      
      impl += 'end;'#10;
      
    end;
    
  end;
  
  SpecialNameDefWriter = sealed partial class(SyntaxDefWriterBase)
    
    protected function ClassName: string; override := $'SN_{name}';
    
    protected function IgnoreOptions(opt: ValidateOptions): boolean; override := false;
    protected function TransformOptions(opt: ValidateOptions): ValidateOptions; override;
    begin
      // There is nothing to force close in any of special names
      opt.negating_force := ValidateOptions.FT_None;
      Result := opt;
    end;
    protected procedure WriteValidate(opt: ValidateOptions); override;
    begin
      var ToDo := 0;
    end;
    
  end;
  
  {$endregion Independant}
  
  {$region Modifier}
  
  ModifierDefWriter<T> = abstract partial class(SyntaxDefWriter<T>)
    
  end;
  
  OptionalDefWriter = sealed partial class(ModifierDefWriter<OptionalDef>)
    
    //ToDo #2524
    protected function ClassName: string; override := 'Optional'+(self as object as SyntaxDefWriter<OptionalDef>).id;
    
    protected function IgnoreOptions(opt: ValidateOptions): boolean; override :=
    // Only last def in block has negating_force - there it doesn't matter if OptionalDef would be parsed or not
    opt.negating_force=ValidateOptions.FT_Negated;
    protected function TransformOptions(opt: ValidateOptions): ValidateOptions; override;
    begin
      // No need for exception for what may or may not parse, but keep PT_Indirect
      if opt.parse_type=ValidateOptions.PT_Direct then
        opt.parse_type := ValidateOptions.PT_TryDirect;
      Result := opt;
    end;
    protected procedure WriteValidate(opt: ValidateOptions); override;
    begin
      sub_def.AddValidate(opt);
      var ToDo := 0;
    end;
    
  end;
  
  NegateDefWriter = sealed partial class(ModifierDefWriter<NegateDef>)
    
    //ToDo #2524
    protected function ClassName: string; override := 'Negate'+(self as object as SyntaxDefWriter<NegateDef>).id;
    
    protected function IgnoreOptions(opt: ValidateOptions): boolean; override := false;
    protected function TransformOptions(opt: ValidateOptions): ValidateOptions; override;
    begin
      // No need for exception for what is *expected* to not parse, but keep PT_Indirect
      if opt.parse_type=ValidateOptions.PT_Direct then
        opt.parse_type := ValidateOptions.PT_TryDirect;
      // Doesn't matter if this was negated
      opt.negating_force := ValidateOptions.FT_None;
      Result := opt;
    end;
    protected procedure WriteValidate(opt: ValidateOptions); override;
    begin
      // Whole sub_def has negating_force, but if it's a block - only last element should inherit negating_force
      opt.negating_force := ValidateOptions.FT_Negated;
      self.sub_def.AddValidate(opt);
      var ToDo := 0;
    end;
    
  end;
  
  ArrayDefWriter = sealed partial class(ModifierDefWriter<ArrayDef>)
    
    //ToDo #2524
    protected function ClassName: string; override := 'Array'+(self as object as SyntaxDefWriter<ArrayDef>).id;
    
    protected function IgnoreOptions(opt: ValidateOptions): boolean; override := false;
    protected function TransformOptions(opt: ValidateOptions): ValidateOptions; override := opt;
    protected procedure WriteValidate(opt: ValidateOptions); override;
    begin
      self.sub_def.AddValidate(opt);
      // ~[=> "abc":"d" ]
      // - Only need to indirectly parse "abc" once, then force close array
      if opt.negating_force = ValidateOptions.FT_Negated then exit;
      // No need for exception for separator and secondary sub_def passes, but keep PT_Indirect
      if opt.parse_type=ValidateOptions.PT_Direct then
        opt.parse_type := ValidateOptions.PT_TryDirect;
      self.sub_def.AddValidate(opt);
      if self.separator<>nil then
        self.separator.AddValidate(opt);
      var ToDo := 0;
    end;
    
  end;
  
  {$endregion Modifier}
  
  {$region Container}
  
  ContainerDefWriter<T> = abstract partial class(SyntaxDefWriter<T>)
    
  end;
  
  PaletteDefWriter = sealed partial class(ContainerDefWriter<PaletteDef>)
    
    //ToDo #2524
    protected function ClassName: string; override := 'Palette'+(self as object as SyntaxDefWriter<PaletteDef>).id;
    
    protected function IgnoreOptions(opt: ValidateOptions): boolean; override := false;
    protected function TransformOptions(opt: ValidateOptions): ValidateOptions; override := opt;
    protected procedure WriteValidate(opt: ValidateOptions); override :=
    foreach var info in children do info.child.AddValidate(opt);
    
  end;
  
  BlockDefWriter<T> = abstract partial class(ContainerDefWriter<T>)
    
    protected function IgnoreOptions(opt: ValidateOptions): boolean; override :=
    children.All(info->info.child.IgnoreOptions(opt));
    protected function TransformOptions(opt: ValidateOptions): ValidateOptions; override;
    begin
      
//      if origin_child<>nil then
//        // А если
//        // => #>bl[ => "abc" ]
//        // Ошибки внешнего блока не нужны
//        // То есть только менять Indirect на TryDirect?
//        opt.parse_type := ValidateOptions.PT_Direct;
      // Нет, тип парсинга на входе тоже важен
      
      // if edge children ignore negating_force - whole block does too
      if opt.negating_force=ValidateOptions.FT_Negated then
      begin
        
        if origin_child=nil then
        begin
          opt.negating_force := (
            if opt.dir=ValidateOptions.PD_Prev then
              children.First.child else
              children.Last.child
          ).TransformOptions(opt).negating_force;
        end else
        begin
          if (
            children.First.child.TransformOptions(opt)
            .negating_force = ValidateOptions.FT_None
          ) and (
            children.Last.child.TransformOptions(opt)
            .negating_force = ValidateOptions.FT_None
          ) then
            opt.negating_force := ValidateOptions.FT_None;
        end;
        
      end;
      
      Result := opt;
    end;
    protected procedure WriteValidate(opt: ValidateOptions); override;
    begin
      var ToDo := 0;
      
      var org_dir := opt.dir;
      if origin_child<>nil then
      begin
        opt.dir := ValidateOptions.PD_Prev;
        opt.parse_type := ValidateOptions.PT_TryDirect;
      end;
      
      var forced_inds := new List<integer>(2);
      if opt.negating_force=ValidateOptions.FT_Negated then
      begin
        
        if origin_child<>nil then
        begin
          forced_inds += 0;
          forced_inds += children.Count-1;
        end else
        case org_dir of
          ValidateOptions.PD_Prev: forced_inds += 0;
          ValidateOptions.PD_Next: forced_inds += children.Count-1;
          else raise new System.NotSupportedException;
        end;
        
      end;
      
      for var i := 0 to children.Count-1 do
      begin
        var curr_opt := opt;
        
        if origin_child=children[i].child then
        begin
          curr_opt.dir := org_dir;
          curr_opt.parse_type := ValidateOptions.PT_Indirect;
          opt.dir := ValidateOptions.PD_Next;
        end;
        
        if i in forced_inds then
          curr_opt.negating_force := ValidateOptions.FT_Negated;
        
        children[i].child.AddValidate(curr_opt);
      end;
      
    end;
    
  end;
  
  NamedBlockDefWriter = sealed partial class(BlockDefWriter<NamedBlockDef>)
    
    protected function ClassName: string; override := name;
    
  end;
  
  NamelessBlockDefWriter = sealed partial class(BlockDefWriter<NamelessBlockDef>)
    
    //ToDo #2524
    protected function ClassName: string; override := 'NamelessBlock'+(self as object as SyntaxDefWriter<NamelessBlockDef>).id;
    
  end;
  
  {$endregion Container}
  
{$endregion CodeGen}

begin
  try
    var KEP_source_fname := 'KEP.kep';
    
    begin
      var lines := ReadLines(KEP_source_fname).Count(l->not string.IsNullOrWhiteSpace(l));
      Otp($'{KEP_source_fname}: {lines} lines');
    end;
    
    var blocks :=
      KEParser.Create
      .AddSource(KEP_source_fname)
    .Parse;
    
    // Wrap
    var w := blocks['KEPFile'].MakeWrapper(def->
    begin
      Result := default(SyntaxDefWriterBase);
      match def with
        
        LiteralDef      (var  l): Result := new LiteralDefWriter(l);
        NameRefDef      (var nr):
        if nr.Name in SpecialNameDefWriter.allowed_names then
          Result := new SpecialNameDefWriter(nr.Name) else
          raise new MessageException($'ERROR: Undefined name reference "{nr.Name}"');
        
        OptionalDef     (var  o): Result := new OptionalDefWriter(o);
        NegateDef       (var  n): Result := new NegateDefWriter(n);
        ArrayDef        (var  a): Result := new ArrayDefWriter(a);
        
        PaletteDef      (var  p): Result := new PaletteDefWriter(p);
        NamedBlockDef   (var bl): Result := new NamedBlockDefWriter(bl);
        NamelessBlockDef(var bl): Result := new NamelessBlockDefWriter(bl);
        
        else raise new System.NotSupportedException(def.GetType.ToString);
      end;
    end) as SyntaxDefWriterBase;
    NamedBlockDefWriter.ReportUnused(blocks);
    
    // Prepare
    w := w.Optimize;
    NamedBlockDefWriter.CountAllNeeded;
    
    // Write
    SyntaxDefWriterBase.WriteAll;
    
  except
    on e: Exception do ErrOtp(e);
  end;
end.