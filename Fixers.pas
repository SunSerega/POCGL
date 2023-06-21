unit Fixers;

interface

uses Parsing;

type
  FixerUtils = static class
    public static esc_sym := '\';
    
    /// Result = sequence of (
    ///   is_in_template,
    ///   text
    /// )
    public static function FindTemplateInsertions(s: StringSection; br1str, br2str: string): sequence of (boolean, StringSection);
    begin
      while true do
      begin
        
        var br1 := s.SubSectionOfFirstUnescaped(esc_sym, br1str);
        if br1.IsInvalid then break;
        
        var br2 := s.WithI1(br1.I2).SubSectionOfFirstUnescaped(esc_sym, br2str);
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
    public static function DeTemplateName(name: StringSection): array of (string, string->string);
    public static function DeTemplateName(name: string) := DeTemplateName(new StringSection(name));
    
    public static function ReadBlockTemplates(lines: sequence of string; power_sign: string; concat_blocks: boolean?): sequence of (array of string, array of string);
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
          
          var need_concat := bl_start;
          if bl_start and names.Any then
          begin
            if concat_blocks=nil then
              raise new System.InvalidOperationException($'Tried to concat [{power_sign}{names.Single}] and [{l}]');
            need_concat := concat_blocks.Value;
          end;
          
          if not need_concat then
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
    public static function ReadBlocks(lines: sequence of string; power_sign: string; concat_blocks: boolean?): sequence of (string,array of string) :=
      ReadBlockTemplates(lines, power_sign, concat_blocks)
      .SelectMany(\(names,lines)->names.SelectMany(name->
      begin
        if name=nil then
        begin
          Result := |(name,lines)|;
          exit;
        end;
        var name_mirriad := DetemplateName(name);
        if lines.Length=0 then
          Result := name_mirriad.Select(\(name,conv)->(name,lines)) else
        begin
          var body := if lines.Length=0 then nil else lines.JoinToString(#10);
          Result := name_mirriad.Select(\(name,conv)->(name,conv(body).Split(#10)));
        end;
      end));
    
    public static function ReadBlocks(fname: string; concat_blocks: boolean?) := ReadBlocks(ReadLines(fname), '#', concat_blocks);
    
  end;
  
  Fixer<TSelf, TFixable, TName> = abstract class
  where TSelf: Fixer<TSelf, TFixable, TName>;
//  where TFixable: class; //TODO #2736
  where TName: System.IEquatable<TName>;
    private _name: TName;
    private used: boolean;
    
    private static adders := new List<TSelf>;
    private static all := new Dictionary<TName, List<TSelf>>;
    
    private static GetFixableName: TFixable->TName;
    protected static procedure RegisterFixableNameExtractor(f: TFixable->TName);
    begin
      if GetFixableName<>nil then
        raise new System.InvalidOperationException;
      GetFixableName := f;
    end;
    private static MakeNewFixable: TSelf->TFixable;
    protected static procedure RegisterPreAdder(f: TSelf->TFixable);
    begin
      if MakeNewFixable<>nil then
        raise new System.InvalidOperationException;
      MakeNewFixable := f;
    end;
    
    static constructor;
    begin
      if not typeof(TFixable).IsClass then
        raise new System.NotSupportedException;
      foreach var t in SeqWhile(typeof(TSelf), t->t.BaseType, t->t<>nil).Reverse do
        System.Runtime.CompilerServices.RuntimeHelpers.RunClassConstructor(t.TypeHandle);
    end;
    
    protected constructor(name: TName; is_adder: boolean);
    begin
      self._name := name;
      
      var typed_self := TSelf(self);
      if is_adder then
        adders += typed_self else
        ByName[name].Add(typed_self);
      
    end;
    
    public property Name: TName read _name;
    
    private static function GetByName(name: TName): List<TSelf>;
    begin
      if not all.TryGetValue(name, Result) then
      begin
        Result := new List<TSelf>;
        all[name] := Result;
      end;
    end;
    private static property ByName[name: TName]: List<TSelf> read GetByName;
    
    public static property AnyExist: boolean read adders.Any or all.Any;
    
    protected procedure ReportUsed := self.used := true;
    
    protected function ApplyOrderBase: integer; virtual := 0;
    /// Return "True" if "o" needs to be deleted
    protected function Apply(o: TFixable): boolean; abstract;
    public static procedure ApplyAll(ensure_add_cap: integer->(); add: TFixable->(); remove_where: Func<TFixable,boolean>->());
    begin
      if ensure_add_cap<>nil then
        ensure_add_cap(adders.Count);
      
      if (adders.Count<>0) and (MakeNewFixable=nil) then
        raise new System.NotImplementedException;
      foreach var a in adders do
      begin
        var item := MakeNewFixable(a);
        if add<>nil then add( item );
      end;
      
      if GetFixableName=nil then
        raise new System.NotImplementedException;
      remove_where(o->
      begin
        var fixers: List<TSelf>;
        // Do not create lists if there are no fixers
        if not all.TryGetValue(GetFixableName(o), fixers) then exit;
        
        Result := false;
        foreach var f in fixers.OrderBy(f->f.ApplyOrderBase) do
          if f.Apply(o) then
          begin
            Result := true;
            break;
          end;
        
      end);
      
      WarnAllUnused;
    end;
    public static procedure ApplyAll(lst: List<TFixable>);
    begin
      ApplyAll(
        add_cap->(lst.Capacity := lst.Count+add_cap),
        lst.Add, pred->lst.RemoveAll(pred)
      );
      lst.TrimExcess;
    end;
    
    protected procedure WarnUnused(all_unused_for_name: List<TSelf>); abstract;
    private static procedure WarnAllUnused :=
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
  
static function FixerUtils.DeTemplateName(name: StringSection): array of (string, string->string);
begin
  var conv: function(f: string->string): string->string := f->f;
  
  {$region name_parts}
  var name_parts := FindTemplateInsertions(name, '[%','%]')
    .Select(\(is_v, s)->
    begin
      Result := new SVariants;
      if not is_v then
      begin
        Result.vals := |s.ToString|;
        exit;
      end;
      
      begin
        var name_sep := s.SubSectionOfFirstUnescaped(esc_sym, ':');
        if name_sep.IsInvalid then
          Result.name := '' else
        begin
          Result.name := s.WithI2(name_sep.I1).TrimWhile(char.IsWhiteSpace).ToString;
          s.range.i1 := name_sep.I2;
        end;
      end;
      
      var vals := s.SplitByUnescaped(',', esc_sym);
      Result.vals := new string[vals.Count];
      for var i := 0 to vals.Count-1 do
        Result.vals[i] := vals[i].TrimWhile(char.IsWhiteSpace).Unescape(esc_sym);
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
        s.UnescapeTo(sb, esc_sym) else
      begin
        var pname, pbody: StringSection;
        
        begin
          var pname_sep := s.SubSectionOfFirstUnescaped(esc_sym, '?');
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
          var vals := pbody.SplitByUnescaped(':', esc_sym);
          if vals.Count<>name_parts[i].vals.Length then
            raise new System.InvalidOperationException($'[{name}]: Instance of [{name_parts[i].name}] had {vals.Count} vals instead of {name_parts[i].vals.Length}:{#10}'+vals.JoinToString(#10));
          AppendWithInsertions(sb, vals[choise].TrimWhile(char.IsWhiteSpace).Unescape(esc_sym));
        end;
        
      end;
    {$endregion AppendWithInsertions}
    
    var name_sb := new StringBuilder;
    for var i := 0 to name_parts.Length-1 do
    begin
      var choise := choise_i div choise_ind_div[i] mod name_parts[i].vals.Length;
      AppendWithInsertions(name_sb, name_parts[i].vals[choise]);
    end;
    
    Result := (name_sb.ToString, conv(body->
    begin
      var body_sb := new StringBuilder;
      AppendWithInsertions(body_sb, body);
      Result := body_sb.ToString;
    end));
  end);
end;

end.