﻿unit Fixers;

type
  FixerUtils = static class
    
    /// Result = sequence of (
    ///   is_in_template,
    ///   text
    /// )
    public static function FindTemplateInsertions(s: string; open_br, close_br: string): sequence of (boolean, string);
    begin
      var ind := 0;
      
      while true do
      begin
        var ind1 := s.IndexOf(open_br, ind);
        if ind1=-1 then break;
        var ind2 := s.IndexOf(close_br, ind1+open_br.Length);
        if ind2=-1 then break;
        
        yield (false, s.Substring(ind, ind1-ind));
        ind1 += open_br.Length;
        
        yield (true, s.Substring(ind1, ind2-ind1));
        
        ind := ind2 + close_br.Length;
      end;
      
      if ind<>s.Length then yield (false, s.Substring(ind));
    end;
    
    // Syntax:
    //# abc[%arg1:1,2,3%]
    //def{%arg1?4:5:6%}gh
    // 
    // ShortSyntax:
    //# abc[%1,2,3%]
    //def{%0%}gh
    // 
    private static function DeTemplateName(name: string; lns: array of string): sequence of (string, array of string);
    begin
      var res := Seq(('',lns));
      
      var i := 0;
      FindTemplateInsertions(name, '[%', '%]').ForEach(t->
        if t[0] then
        begin
          var template_ids := new List<string>(2);
          template_ids += i.ToString;
          
          var ind := t[1].IndexOf(':');
          if ind<>-1 then
          begin
            template_ids += t[1].Remove(ind);
            t := (t[0], t[1].Remove(0,ind+1));
          end;
          
          res := res.SelectMany(bl->t[1].Replace('\,',#0).Split(',').Select(arg_def->arg_def.Replace(#0,',').Trim).Select((arg_def,arg_i)->(bl[0]+arg_def, bl[1].ConvertAll(l->
          begin
            var sb := new StringBuilder;
            foreach var st in FindTemplateInsertions(l, '{%', '%}') do
              if not st[0] then
                sb += st[1] else
              if not template_ids.Any(template_id->(st[1]=template_id) or (st[1].StartsWith(template_id) and st[1].Contains('?'))) then
              begin
                sb += '{%';
                sb += st[1];
                sb += '%}';
              end else
              begin
                var ind := st[1].IndexOf('?');
                if ind=-1 then
                  sb += arg_def else
                  sb += st[1].Remove(0,ind+1).Replace('\:',#0).Split(':')[arg_i].Replace(#0,':').Trim;
              end;
            Result := sb.ToString;
          end))));
          
          i += 1;
        end else
          res := res.Select(bl->(bl[0]+t[1], bl[1]))
      );
      
      Result := res;
    end;
    public static function ReadBlocks(lines: sequence of string; power_sign: string; concat_blocks: boolean): sequence of (string, array of string);
    begin
      var make_lns: List<string>->array of string := lst->
      begin
        var lc := lst.Count;
        while (lc<>0) and string.IsNullOrWhiteSpace(lst[lc-1]) do lc -= 1;
        lst.RemoveRange(lc, lst.Count-lc);
        Result := lst.ToArray;
        lst.Clear;
      end;
      
      var res := new List<string>;
      var names := new List<string>;
      var start := true;
      var bl_start := true;
      
      foreach var l in lines do
        if l.StartsWith(power_sign) then
        begin
          
          if not bl_start or not concat_blocks then
          begin
            
            if start then
            begin
              if res.Count<>0 then
                yield (nil as string, make_lns(res));
            end else
            begin
              var lns := make_lns(res);
              yield sequence names.SelectMany(name->DetemplateName(name, lns));
              names.Clear;
            end;
            
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
      
      if start then
      begin
        if res.Count<>0 then
          yield (nil as string, make_lns(res));
      end else
      begin
        var lns := make_lns(res);
        yield sequence names.SelectMany(name->DetemplateName(name, lns));
      end;
    end;
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
  
end.