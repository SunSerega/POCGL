unit StringPatterns;
{$zerobasedstrings}

interface

uses Parsing;
uses ColoredStrings;

type
  StringPattern = sealed partial class
    
    public constructor(pattern: StringSection);
    public constructor(pattern: string) := Create(new StringSection(pattern));
    private constructor := raise new System.InvalidOperationException;
    
    public static function Literal(s: string): StringPattern;
    
    public function Includes(text: StringSection): boolean;
    public function Includes(text: string) := Includes(new StringSection(text));
    
    public static function operator*(p1, p2: StringPattern): StringPattern;
    
    private procedure WriteTo(b: ColoredStringBuilderBase<string>);
    public function ToColoredString: ColoredString<string>;
    begin
      var b := new ColoredStringBuilder<string>('root');
      WriteTo(b);
      Result := b.Finish;
    end;
    public function ToString: string; override;
    begin
      var b := new UnColoredStringBuilder<string>;
      WriteTo(b);
      Result := b.Finish;
    end;
    
  end;
  
implementation

type
  {$region Misc}
  
  CharsMinT = cardinal;
  CharsMaxT = StringIndex;
  
  CharsCount = record
    min: CharsMinT;
    max: CharsMaxT;
    
    property IsSimple: boolean read min=max;
    
    constructor(min: CharsMinT; max: CharsMaxT);
    begin
      self.min := min;
      self.max := max;
    end;
    constructor(c: integer) := Create(c, c);
    constructor := exit;
    
    static function CombineInline(c1, c2: CharsCount): CharsCount;
    begin
      Result.min := c1.min+c2.min;
      Result.max := if c1.max.IsInvalid or c2.max.IsInvalid then
        CharsMaxT.Invalid else c1.max + c2.max;
    end;
    
    static function CombineParallel(c1, c2: CharsCount): CharsCount;
    begin
      Result.min := PABCSystem.Min(c1.min,c2.min);
      Result.max := if c1.max.IsInvalid or c2.max.IsInvalid then
        CharsMaxT.Invalid else PABCSystem.Max(integer(c1.max), integer(c2.max));
    end;
    
  end;
  
  StringPatternSymJump = record
    count: CharsCount;
    valid := '';
    
    constructor(count: CharsCount; valid: string);
    begin
      self.count := count;
      self.valid := valid;
    end;
    constructor(c_min: CharsMinT; c_max: CharsMaxT; valid: string) :=
    Create(new CharsCount(c_min,c_max), valid);
    
  end;
  
  {$endregion Misc}
  
  {$region StringPatternPart}
  
  StringPatternPart = abstract class
    
    public property Length: CharsCount read; abstract;
    
    public function TryApply(text: StringSection; c_min, c_max: integer): sequence of StringSection; abstract;
    
    public function EnmrSymbols: sequence of StringPatternSymJump; abstract;
    
    public procedure WriteTo(b: ColoredStringBuilderBase<string>); abstract;
    
    private const wild_beg = '@[';
    private const wild_end = ']';
    private const count_chs_sep = '*';
    private const range_sep = '..';
    
    private static escapable_chs := (wild_beg+wild_end+count_chs_sep+range_sep+'\').ToHashSet;
    protected static procedure AddEscaped(b: ColoredStringBuilderBase<string>; ch: char);
    begin
      if ch in escapable_chs then
        b += '\';
      b += ch;
    end;
    
  end;
  StringPatternPartSolid = sealed class(StringPatternPart)
    private val: string;
    
    public constructor(val: string) := self.val := val;
    private constructor := raise new System.InvalidOperationException;
    
    public property Length: CharsCount read new CharsCount(val.Length); override;
    
    public function TryApply(text: StringSection; c_min, c_max: integer): sequence of StringSection; override :=
    if val.Length.InRange(c_min, c_max) and text.StartsWith(val) then
      |text.TakeFirst(val.Length)| else
      System.Array.Empty&<StringSection>;
    
    public function EnmrSymbols: sequence of StringPatternSymJump; override :=
    val.Select(ch->new StringPatternSymJump(1,1, ch));
    
    public procedure WriteTo(b: ColoredStringBuilderBase<string>); override :=
    b.AddSubRange('solid', b->
      foreach var ch in self.val do AddEscaped(b, ch)
    );
    
  end;
  StringPatternPartWild = sealed class(StringPatternPart)
    private count: CharsCount;
    private allowed: HashSet<char>;
    
    {$region constructor's}
    
    public constructor(count: CharsCount; allowed: HashSet<char>);
    begin
      self.count := count;
      self.allowed := allowed;
    end;
    private constructor := raise new System.InvalidOperationException;
    
    private static function TryParseCountFrom(s: StringSection; var c: StringIndex): boolean;
    begin
      Result := false;
      if s.Length=0 then
        c := StringIndex.Invalid else
      if s.All(char.IsDigit) then
        c := s.ToString.ToInteger else
        exit;
      Result := true;
    end;
    private static function TryParseCountFrom(s: StringSection; var c: CharsMinT): boolean;
    begin
      var nc: StringIndex;
      Result := TryParseCountFrom(s, nc);
      if not Result then exit;
      c := if nc.IsInvalid then 0 else nc;
    end;
    
    public static function TryParse(read_head: StringSection): System.ValueTuple<StringSection,StringPatternPartWild>;
    begin
      
      while true do
      begin
        var wild_beg_s := read_head.SubSectionOfFirstUnescaped(wild_beg);
        if wild_beg_s.IsInvalid then break;
        read_head := read_head.WithI1(wild_beg_s.I2);
        
        var wild_end_s := read_head.SubSectionOfFirstUnescaped(wild_end);
        if wild_end_s.IsInvalid then continue;
        var body := read_head.WithI2(wild_end_s.I1);
        
        var count_chs_sep_s := body.SubSectionOfFirst(count_chs_sep);
        if count_chs_sep_s.IsInvalid then continue;
        var count_s := body.WithI2(count_chs_sep_s.I1);
        
        var count := new CharsCount(0, CharsMaxT.Invalid);
        if count_s.Length<>0 then
        begin
          var count_sep_s := count_s.SubSectionOfFirst(range_sep);
          
          if count_sep_s.IsInvalid then
          begin
            if not TryParseCountFrom(count_s, count.max) then continue;
            count.min := if count.max.IsInvalid then 0 else count.max;
          end else
          begin
            if not TryParseCountFrom(count_s.WithI2(count_sep_s.I1), count.min) then continue;
            if not TryParseCountFrom(count_s.WithI1(count_sep_s.I2), count.max) then continue;
          end;
          
        end;
        
        var allowed := new HashSet<char>;
        var chars := body.WithI1(count_chs_sep_s.I2);
        
        var escaped := false;
        while chars.Length<>0 do
        begin
          var ch1 := chars[0];
          chars := chars.TrimFirst(1);
          escaped := not escaped and (ch1='\');
          if escaped then continue;
          if (chars.Length>=range_sep.Length+1) and chars.StartsWith(range_sep) then
          begin
            var ch2 := chars[range_sep.Length];
            chars := chars.TrimFirst(range_sep.Length+1);
            for var ch := ch1 to ch2 do
              allowed += ch;
          end else
            allowed += ch1;
        end;
        
        Result.Item1 := wild_beg_s.WithI2(wild_end_s.I2);
        Result.Item2 := new StringPatternPartWild(count, allowed);
        
        if allowed.Count=0 then
          raise new System.InvalidOperationException($'Pattern {Result.Item1} had 0 allowed chars');
        
        exit;
      end;
      
    end;
    
    {$endregion constructor's}
    
    public property Length: CharsCount read count; override;
    
    public function TryApply(text: StringSection; c_min, c_max: integer): sequence of StringSection; override;
    begin
      
      if text.Length>c_max then
        text := text.TakeFirst(c_max);
      if not self.count.max.IsInvalid and (text.Length>count.max) then
        text := text.TakeFirst(count.max);
      text := text.TakeFirstWhile(allowed.Contains);
      
      if c_min<self.count.min then
        c_min := count.min;
      
      var res := text.TakeFirst(c_min);
      while true do
      begin
        yield res;
        if res.I2=text.I2 then break;
        res.range.i2 += 1;
      end;
      
    end;
    
    public function EnmrSymbols: sequence of StringPatternSymJump; override :=
    |new StringPatternSymJump(count, allowed.Order.JoinToString)|;
    
    private static function AreCharsCombineable(ch1, ch2: char): boolean;
    begin
      Result := false;
      if ch2.Code-ch1.Code <> 1 then exit;
      if ch1.IsDigit then
        Result := ch2.IsDigit else
      if ch1.IsLetter then
      begin
        if not ch2.IsLetter then exit;
        Result := ch1.IsUpper=ch2.IsUpper;
      end;
    end;
    
    public procedure WriteTo(b: ColoredStringBuilderBase<string>); override :=
    b.AddSubRange('wild', b->
    begin
      b += wild_beg;
      
      b.AddSubRange('count', b->
      begin
        var c_min_s := if count.min=0 then '' else count.min.ToString;
        var c_max_s := if count.max.IsInvalid then '' else count.max.ToString;
        
        b += c_min_s;
        if c_max_s<>c_min_s then
        begin
          b += range_sep;
          b += c_max_s;
        end;
        
      end);
      
      b += count_chs_sep;
      
      b.AddSubRange('chars', b->
      begin
        var enmr := allowed.Order.GetEnumerator;
        if not enmr.MoveNext then raise new System.InvalidOperationException;
        
        var ch1 := enmr.Current;
        var ch2 := ch1;
        
        var FlushPrev := procedure->b.AddSubRange('sym', b->
        begin
          AddEscaped(b, ch1);
          if ch1<>ch2 then
          begin
            if ch2.Code-ch1.Code <> 1 then
              //TODO #????: Need "StringPatternPart."
              b += StringPatternPart.range_sep;
            AddEscaped(b, ch2);
          end;
        end);
        
        while enmr.MoveNext do
        begin
          var ch := enmr.Current;
          if AreCharsCombineable(ch2, ch) then
            ch2 := ch else
          begin
            FlushPrev;
            ch1 := ch;
            ch2 := ch;
          end;
        end;
        
        FlushPrev;
      end);
      
      b += wild_end;
    end);
    
  end;
  
  {$endregion StringPatternPart}
  
{$region StringPattern.Create}

//TODO #2714
function StringPattern_MakeParts(pattern: StringSection): sequence of StringPatternPart;
begin
  
  var used_head := pattern.TakeFirst(0);
  //TODO #2715
  var make_solid_until: function(ind: StringIndex): StringPatternPart := function(ind: StringIndex): StringPatternPart->
  begin
    var leftover := used_head.TakeLast(0).WithI2(ind);
    if leftover.Length=0 then exit;
    Result := new StringPatternPartSolid(leftover.Unescape);
    used_head.range.i2 := ind;
  end;
  
  while true do
  begin
    var (wild_s, wild) := StringPatternPartWild.TryParse(pattern.WithI1(used_head.I2));
    if wild=nil then break;
    
    if make_solid_until(wild_s.I1) is StringPatternPart(var solid) then yield solid;
    yield wild;
    used_head := used_head.WithI2(wild_s.I2);
    
  end;
  
  if make_solid_until(pattern.I2) is StringPatternPart(var p) then yield p;
end;

type
  StringPattern = sealed partial class
    private parts: array of StringPatternPart;
    private len_caps: array of CharsCount;
    
    private constructor(parts: array of StringPatternPart);
    begin
      self.parts := parts;
      SetLength(len_caps, parts.Count);
      
      var cap := new CharsCount(0);
      for var i := parts.Count-1 to 0 step -1 do
      begin
        len_caps[i] := cap;
        cap := CharsCount.CombineInline(cap, parts[i].Length);
      end;
      
    end;
    
  end;
  
//TODO #2714
function StringPattern_EnmrSymbols(self: StringPattern): sequence of StringPatternSymJump;
begin
  var enmr: IEnumerator<StringPatternSymJump> := self.parts.SelectMany(part->part.EnmrSymbols).GetEnumerator;
  if not enmr.MoveNext then exit;
  var last := enmr.Current;
  
  while enmr.MoveNext do
  begin
    var curr := enmr.Current;
    //TODO Maybe it's bad to merge "abc"*"abbc" => "a@[1..2*b]c"
    // - But @[] sections with same filter should still merge
    if curr.valid<>last.valid then
    begin
      yield last;
      last := curr;
    end else
      last.count := CharsCount.CombineInline(last.count, curr.count);
  end;
  
  yield last;
end;

constructor StringPattern.Create(pattern: StringSection) := Create(StringPattern_MakeParts(pattern).ToArray);

static function StringPattern.Literal(s: string) :=
//TODO #????: adding params breaks case where array is passed to "new StringPattern"
new StringPattern(new StringPatternPart[](new StringPatternPartSolid(s)));

{$endregion StringPattern.Create}

{$region StringPattern.Includes}

function StringPattern.Includes(text: StringSection): boolean;
begin
  Result := false;
  var leftover := text;
  
  var enmrs := new IEnumerator<StringSection>[parts.Length];
  var part_i := 0;
  
  if part_i=parts.Length then
  begin
    Result := leftover.Length=0;
    exit;
  end;
  
  while true do
  begin
    
    if enmrs[part_i]=nil then
    begin
      var caps := len_caps[part_i];
      var left_len := leftover.Length;
      enmrs[part_i] := parts[part_i].TryApply(leftover,
        if caps.max.IsInvalid then 0 else (left_len-integer(caps.max)).ClampBottom(0),
        left_len-caps.min
      ).ToArray.AsEnumerable.GetEnumerator;
    end;
    
    if not enmrs[part_i].MoveNext then
    begin
      enmrs[part_i] := nil;
      part_i -= 1;
      if part_i<0 then exit;
      leftover.range.i1 := enmrs[part_i].Current.I2;
    end else
    begin
      leftover.range.i1 := enmrs[part_i].Current.I2;
      part_i += 1;
      if part_i=parts.Length then
      begin
        Result := leftover.Length=0;
        exit;
      end;
    end;
    
  end;
  
end;

{$endregion StringPattern.Includes}

{$region StringPattern.operator*}

type
  StringPatternMergeNode = sealed class
    x_to, y_to: integer;
    prev: StringPatternMergeNode;
    
    constructor(x_to, y_to: integer; prev: StringPatternMergeNode);
    begin
      self.x_to := x_to;
      self.y_to := y_to;
      self.prev := prev;
    end;
    constructor := Create(0, 0, nil);
    
  end;
  
  StringPatternMerger = static class
    
    const cost_snake        = 0;
//    const cost_take_count   = 1;
    const cost_merge_count  = 1;
    const cost_strafe       = 2;
    
    const cost_max          = cost_strafe;
    
    static function FindMinPath(syms_x, syms_y: array of StringPatternSymJump): StringPatternMergeNode;
    begin
      Result := nil;
      
      var len_x := syms_x.Length;
      var len_y := syms_y.Length;
      
      // (node, cost)
      var best_per_k := new System.ValueTuple<StringPatternMergeNode, integer>[len_x+1+len_y];
      best_per_k[len_x].Item1 := new StringPatternMergeNode;
      
      var end_k := len_y-len_x;
      
      // True if end point reached
      var snake := function(k, ind: integer): boolean->
      begin
        var node := best_per_k[ind].Item1;
        var x := node.x_to;
        
        while true do
        begin
          if x>=len_x then break;
          var y := x+k;
          if y>=len_y then break;
          if syms_x[x]<>syms_y[y] then break;
          x += 1;
        end;
        
        if x<>node.x_to then
        begin
          node := new StringPatternMergeNode(x, x+k, node);
          best_per_k[ind].Item1 := node;
        end;
        
        Result := (k=end_k) and (x=len_x);
      end;
      if snake(0, len_x) then
      begin
        Result := best_per_k[len_x].Item1;
        exit;
      end;
      
      var min_k := 0;
      var max_k := 0;
      
      var limit_min_k := procedure(k: integer)->
      begin
        if k<=min_k then exit;
        for var i := min_k+len_x to (k-1)+len_x do
          best_per_k[i].Item1 := nil;
        min_k := k;
      end;
      var limit_max_k := procedure(k: integer)->
      begin
        if k>=max_k then exit;
        for var i := (k+1)+len_x to max_k+len_x do
          best_per_k[i].Item1 := nil;
        max_k := k;
      end;
      
      for var allowed_cost := 1 to (len_x+len_y)*cost_max do
      begin
        var k := min_k-1;
        
        while true do
        begin
          k += 1;
          if k>max_k then break;
          
          var ind := k+len_x;
          var (node, cost) := best_per_k[ind];
          var cost_step := allowed_cost - cost;
          case cost_step of
            
            {$region Straight}
            
            cost_merge_count:
            begin
              var x := node.x_to;
              if x=len_x then
              begin
                limit_min_k(k);
                continue;
              end;
              var y := x+k;
              if y=len_y then
              begin
                limit_max_k(k);
                continue;
              end;
              if syms_x[x].valid<>syms_y[y].valid then continue;
              best_per_k[ind].Item1 := new StringPatternMergeNode(x+1,y+1, node);
              best_per_k[ind].Item2 := allowed_cost;
              if not snake(k, ind) then continue;
              Result := best_per_k[ind].Item1;
              exit;
            end;
            
            {$endregion Straight}
            
            {$region Jump k}
            
//            cost_take_count,
            cost_strafe:
            begin
              var x := node.x_to;
              
              foreach var k_dir in |-1,+1| do
              begin
                var nk := k+k_dir;
                var dx := k_dir=-1;
                var nx := x + Ord(dx);
                var ny := nx + nk;
                if dx then
                begin
                  if nx>len_x then
                  begin
                    limit_min_k(nk+1);
                    continue;
                  end;
                  if k=min_k then
                    min_k -= 1;
                end else
                begin
                  if ny>len_y then
                  begin
                    limit_max_k(nk-1);
                    continue;
                  end;
                  if k=max_k then
                    max_k += 1;
                end;
                
                var parent := node;
                begin
                  var prev := parent.prev;
                  if (prev<>nil) and (dx ? parent.y_to=prev.y_to : parent.x_to=prev.x_to) then
                    parent := prev;
                end;
                
                var n_ind := nk+len_x;
                
                var old := best_per_k[n_ind].Item1;
                if (old<>nil) and (old.x_to>nx) then continue;
                
                best_per_k[n_ind].Item1 := new StringPatternMergeNode(nx,ny, node);
                best_per_k[n_ind].Item2 := allowed_cost;
                
                if not snake(nk, n_ind) then continue;
                Result := best_per_k[n_ind].Item1;
                exit;
              end;
              
            end;
            
            {$endregion Jump k}
            
          end;
          
        end;
        
      end;
      
      raise new System.InvalidOperationException;
    end;
    
  end;
  
static function StringPattern.operator*(p1, p2: StringPattern): StringPattern;
begin
  Result := nil;
  
  var jumps := new List<StringPatternSymJump>;
  
  begin
    var syms_x := StringPattern_EnmrSymbols(p1).ToArray;
    var syms_y := StringPattern_EnmrSymbols(p2).ToArray;
    var node := StringPatternMerger.FindMinPath(syms_x, syms_y);
    var x := node.x_to;
    var y := node.y_to;
    
    var strafe_end: (integer, integer);
    var consume_strafe := procedure->
    begin
      if strafe_end=nil then exit;
      var (ex,ey) := strafe_end;
      
      var syms_x_r := syms_x.Take(ex).Skip(x);
      var syms_y_r := syms_y.Take(ey).Skip(y);
      
      jumps += new StringPatternSymJump(
        CharsCount.CombineParallel(
          syms_x_r.Select(sym->sym.count).DefaultIfEmpty.Aggregate((c1,c2)->CharsCount.CombineInline(c1,c2)),
          syms_y_r.Select(sym->sym.count).DefaultIfEmpty.Aggregate((c1,c2)->CharsCount.CombineInline(c1,c2))
        ),
        (syms_x_r.SelectMany(j->j.valid)+syms_y_r.SelectMany(j->j.valid)).ToHashSet.Order.JoinToString
      );
      
      strafe_end := nil;
    end;
    
    while true do
    begin
      node := node.prev;
      if node=nil then break;
      
      var px := node.x_to;
      var py := node.y_to;
      
      if (x=px) or (y=py) then
      begin
        if strafe_end=nil then
          strafe_end := (x,y);
      end else
      begin
        consume_strafe;
        
        {$ifdef DEBUG}
        if x-px <> y-py then raise new System.InvalidOperationException;
        {$endif DEBUG}
        for var i := (x-px)-1 to 0 step -1 do
        begin
          var sym_x := syms_x[px+i];
          var sym_y := syms_y[py+i];
          {$ifdef DEBUG}
          if sym_x.valid<>sym_y.valid then raise new System.InvalidOperationException;
          {$endif DEBUG}
          jumps += new StringPatternSymJump(
            CharsCount.CombineParallel(sym_x.count, sym_y.count),
            sym_x.valid
          );
        end;
        
      end;
      
      x := px;
      y := py;
    end;
    
    consume_strafe;
  end;
  
  jumps.Reverse;
  
  var parts := new List<StringPatternPart>(jumps.Count);
  var last_solid := new StringBuilder;
  
  foreach var jump in jumps do
    if (jump.valid.Length=1) and (jump.count.IsSimple) then
      last_solid.Append(jump.valid.Single, jump.count.min) else
    begin
      if last_solid.Length<>0 then
      begin
        parts.Add(new StringPatternPartSolid(last_solid.ToString));
        last_solid.Clear;
      end;
      parts.Add(new StringPatternPartWild(jump.count, jump.valid.ToHashSet));
    end;
  if last_solid.Length<>0 then
    parts.Add(new StringPatternPartSolid(last_solid.ToString));
  
  Result := new StringPattern(parts.ToArray);
end;

{$endregion StringPattern.operator*}

{$region StringPattern.ToString}

procedure StringPattern.WriteTo(b: ColoredStringBuilderBase<string>) :=
foreach var part in parts do part.WriteTo(b);

{$endregion StringPattern.ToString}

end.