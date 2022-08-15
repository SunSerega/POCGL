unit Fixers;

interface

uses Parsing;

type
  FixerUtils = static class
    
    /// Result = sequence of (
    ///   is_in_template,
    ///   text
    /// )
    public static function FindTemplateInsertions(s: StringSection; br1str, br2str: string): sequence of (boolean, StringSection);
    begin
      while true do
      begin
        
        var br1 := s.SubSectionOfFirstUnescaped(br1str);
        if br1.IsInvalid then break;
        
        var br2 := s.WithI1(br1.I2).SubSectionOfFirstUnescaped(br2str);
        if br2.IsInvalid then break;
        
        if s.I1<>br1.I1 then
          yield (false, s.WithI2(br1.I1));
        yield (true, new StringSection(s.text, br1.I2,br2.I1));
        
        s.range.i1 := br2.I2;
      end;
      
      if s.Length<>0 then
        yield (false, s);
    end;
    public static function FindTemplateInsertions(s, br1str, br2str: string) := FindTemplateInsertions(new StringSection(s), br1str, br2str);
    
    // Syntax:
    //# abc[%arg1:1,2,3%]
    //def{%arg1?4:5:6%}gh
    // 
    // ShortSyntax:
    //# abc[%1,2,3%]
    //def{%0%}gh
    // 
    private static function DeTemplateName(name, body: string): array of (string, string);
    
    public static function ReadBlockTemplates(lines: sequence of string; power_sign: string; concat_blocks: boolean): sequence of (array of string, array of string);
    begin
      var res := new List<string>;
      var names := new List<string>;
      var start := true;
      var bl_start := true;
      
      //TODO #2683
      var make_res: function: (array of string,array of string) := ()->
      begin
        var lc := res.Count;
        while (lc<>0) and string.IsNullOrWhiteSpace(res[lc-1]) do lc -= 1;
        res.RemoveRange(lc, res.Count-lc);
        
        if names.Count=0 then
          names += default(string);
        
        Result := (names.ToArray, res.ToArray);
        
        res.Clear;
      end;
      
      foreach var l in lines do
        if l.StartsWith(power_sign) then
        begin
          
          if not (bl_start and concat_blocks) then
          begin
            if not (start and (res.Count=0)) then
              yield make_res();
            names.Clear;
          end;
          
          names += l.Substring(power_sign.Length).Trim;
          start := false;
          bl_start := true;
        end else
        begin
          
          if (res.Count<>0) or not string.IsNullOrWhiteSpace(l) then
            res += l;
          
          bl_start := false;
        end;
      
      if not (start and (res.Count=0)) then
        yield make_res();
      
//      $'=== ORIGINAL ==='.Println;
//      lines.PrintLines;
//      $'=== PARSED ==='.Println;
//      foreach var (name, lns) in Result do
//      begin
//        $'# {name}'.Println;
//        foreach var l in lns do
//          l.Println;
//        Println;
//      end;
    end;
    public static function ReadBlocks(lines: sequence of string; power_sign: string; concat_blocks: boolean) :=
    ReadBlockTemplates(lines, power_sign, concat_blocks)
    .SelectMany(\(names,lines)->names.SelectMany(name->
      DetemplateName(name, lines.JoinToString(#10))
      .Select(\(name, body)->(name,
        body='' ?
          System.Array.Empty&<string> :
          body.Split(#10)
      ))
    ));
    
    public static function ReadBlocks(fname: string; concat_blocks: boolean) := ReadBlocks(ReadLines(fname), '#', concat_blocks);
    
  end;
  
  Fixer<TFixer, TFixable> = abstract class
  where TFixer: Fixer<TFixer, TFixable>;
    protected name: string;
    protected used: boolean;
    
    private static all := new Dictionary<string, List<TFixer>>;
    private static function GetItem(name: string): List<TFixer>;
    begin
      if not all.TryGetValue(name, Result) then
      begin
        Result := new List<TFixer>;
        all[name] := Result;
      end;
    end;
    public static property Item[name: string]: List<TFixer> read GetItem; default;
    
    private static adders := new List<TFixer>;
    protected procedure RegisterAsAdder := adders.Add( TFixer(self) );
    
    protected static GetFixableName: TFixable->string;
    protected static MakeNewFixable: TFixer->TFixable;
    
    protected constructor(name: string);
    begin
      self.name := name;
      if name=nil then exit;
      Item[name].Add( TFixer(self) );
    end;
    
    protected function ApplyOrderBase; virtual := 0;
    /// Return "True" if "o" needs to be deleted
    protected function Apply(o: TFixable): boolean; abstract;
    public static procedure ApplyAll(lst: List<TFixable>);
    begin
      lst.Capacity := lst.Count + adders.Count;
      
      foreach var a in adders do
        lst += MakeNewFixable(a);
      
      for var i := lst.Count-1 downto 0 do
      begin
        var o := lst[i];
        foreach var f in Item[GetFixableName(o)].OrderBy(f->f.ApplyOrderBase) do
          if f.Apply(o) then
            lst.RemoveAt(i);
      end;
      
      lst.TrimExcess;
    end;
    
    protected procedure WarnUnused(all_unused_for_name: List<TFixer>); abstract;
    public static procedure WarnAllUnused :=
    foreach var l in all.Values do
    begin
      var unused := l.ToList;
      unused.RemoveAll(f->f.used);
      if unused.Count=0 then continue;
      unused[0].WarnUnused(unused);
    end;
    
  end;
  
implementation

type
  SVariants = record
    name := default(string);
    vals: array of string;
  end;
  
function SplitByUnescaped(self: StringSection; by: string): List<StringSection>; extensionmethod;
begin
  Result := new List<StringSection>;
  while true do
  begin
    var sep := self.SubSectionOfFirstUnescaped(by);
    if sep.IsInvalid then break;
    Result += self.WithI2(sep.I1);
    self.range.i1 := sep.I2;
  end;
  Result += self;
end;

static function FixerUtils.DeTemplateName(name, body: string): array of (string, string);
begin
  if name=nil then
  begin
    Result := |(name,body)|;
    exit;
  end;
  
  {$region name_parts}
  var name_parts := FindTemplateInsertions(new StringSection(name), '[%','%]')
    .Select(\(is_v, s)->
    begin
      Result := new SVariants;
      if not is_v then
      begin
        Result.vals := |s.ToString|;
        exit;
      end;
      
      begin
        var name_sep := s.SubSectionOfFirstUnescaped(':');
        if name_sep.IsInvalid then
          Result.name := '' else
        begin
          Result.name := s.WithI2(name_sep.I1).TrimWhile(char.IsWhiteSpace).ToString;
          s.range.i1 := name_sep.I2;
        end;
      end;
      
      var vals := s.SplitByUnescaped(',');
      Result.vals := new string[vals.Count];
      for var i := 0 to vals.Count-1 do
        Result.vals[i] := vals[i].TrimWhile(char.IsWhiteSpace).Unescape;
    end).ToArray;
  {$endregion name_parts}
  
  {$region Misc setup}
  
  begin
    var n := 0;
    for var i := 0 to name_parts.Length-1 do
    begin
      var npn := name_parts[i].name;
      if npn=nil then continue;
      if npn='' then name_parts[i].name := n.ToString;
      n += 1;
    end;
  end;
  
  var pname_ind := name_parts.Numerate(0)
    .Where(\(i,np)->np.name <> nil)
    .ToDictionary(\(i,np)->np.name, \(i,np)->i)
  ;
  
  var choise_cap := 1;
  var choise_ind_div := new integer[name_parts.Length];
  for var i := name_parts.Length-1 downto 0 do
  begin
    choise_ind_div[i] := choise_cap;
    choise_cap *= name_parts[i].vals.Length;
  end;
  
  {$endregion Misc setup}
  
  Result := ArrGen(choise_cap, choise_i->
  begin
    {$region AppendWithInsertions}
    var AppendWithInsertions: procedure(sb: StringBuilder; text: string); AppendWithInsertions := (sb,text)->
    foreach var (repl, s) in FindTemplateInsertions(new StringSection(text), '{%','%}') do
      if not repl then
        s.UnescapeTo(sb) else
      begin
        var pname, pbody: StringSection;
        
        begin
          var pname_sep := s.SubSectionOfFirstUnescaped('?');
          if pname_sep.IsInvalid then
          begin
            pname := s;
            pbody := s.TakeLast(0);
          end else
          begin
            pname := s.WithI2(pname_sep.I1);
            pbody := s.WithI1(pname_sep.I2);
          end;
        end;
        
        var i: integer;
        if not pname_ind.TryGetValue(pname.TrimWhile(char.IsWhiteSpace).ToString, i) then
          raise new System.InvalidOperationException($'[{name}]: [{pname}] template is not defined. All templates:{#10}'+pname_ind.Keys.Select(key->$'[{key}]').JoinToString(#10));
//        begin
//          sb += '{%';
//          sb *= s;
//          sb += '%}';
//          continue;
//        end;
        var choise := choise_i div choise_ind_div[i] mod name_parts[i].vals.Length;
        
        if pbody.Length=0 then
          AppendWithInsertions(sb, name_parts[i].vals[choise]) else
        begin
          var vals := pbody.SplitByUnescaped(':');
          if vals.Count<>name_parts[i].vals.Length then
            raise new System.InvalidOperationException($'[{name}]: Instance of [{name_parts[i].name}] had {vals.Count} vals instead of {name_parts[i].vals.Length}:{#10}'+vals.JoinToString(#10));
          AppendWithInsertions(sb, vals[choise].TrimWhile(char.IsWhiteSpace).Unescape);
        end;
        
      end;
    {$endregion AppendWithInsertions}
    
    var name_sb := new StringBuilder;
    for var i := 0 to name_parts.Length-1 do
    begin
      var choise := choise_i div choise_ind_div[i] mod name_parts[i].vals.Length;
      AppendWithInsertions(name_sb, name_parts[i].vals[choise]);
    end;
    
    var body_sb := new StringBuilder;
    AppendWithInsertions(body_sb, body);
    
    Result := (name_sb.ToString, body_sb.ToString);
  end);
end;

end.