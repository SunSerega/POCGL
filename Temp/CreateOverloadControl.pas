program prog;

type
  
  BasicFuncDef = auto class
    name: string := nil;
    pars: array of string;
    ret: string := nil;
    
    static function FromStr(l: string): BasicFuncDef;
    begin
      Result := new BasicFuncDef;
      
      var ind2 :=
        Arr&<string>('(',':',';',' := ')
        .Select(ch->l.IndexOf(ch))
        .Where(ind->ind<>-1)
        .Min
      ;
      var ind1 := l.LastIndexOf(' ', ind2-1)+1;
      Result.name := l.SubString(ind1,ind2-ind1);
      
      ind2 += 1;
      if l[ind2]='(' then
      begin
        var ind3 := l.IndexOf(')',ind2);
        
        Result.pars :=
          l.SubString(ind2,ind3-ind2)
          .Split(';')
          .SelectMany(p->
          begin
            var ind := p.IndexOf(':');
            Result := Arr(p.SubString(ind+1).Trim).Cycle.Take(p.Remove(ind).Count(ch->ch=',')+1);
          end)
          .ToArray
        ;
        
        ind2 := ind3+2;
      end else
        Result.pars := new string[0];
      
      if l[ind2]=':' then
      begin
        var ind3 :=
          Arr&<string>(';',' := ')
          .Select(ch->l.IndexOf(ch,ind2))
          .Where(ind->ind<>-1)
          .Min
        ;
        
        Result.ret := l.SubString(ind2,ind3-ind2).Trim;
        
      end;
      
    end;
    
    public function ToString: string; override :=
    $'BasicFuncDef( name="{name}"; pars=[{pars.JoinIntoString}]; ret="{ret}")';
    
  end;
  
  AdvFuncDef = auto class
    name: string := nil;
    full_par_defs := new List<array of string>;
    all_par_types: array of HashSet<string>;
  end;
  
function RemoveAttrs(self: sequence of string); extensionmethod :=
self.Select(l->
begin
  
  while l.Contains('[') do
  begin
    var ind1 := l.LastIndexOf('[');
    var ind2 := l.IndexOf(']',ind1)+1;
    l := l.Remove(ind1,ind2-ind1);
  end;
  
  Result := l;
end);

function LoadOldFuncs :=
ReadLines('OpenGL old.dat')
.SkipWhile(l->not l.Contains('gl = static class'))
.TakeWhile(l->not l.Contains('end;'))
.Pairwise
.Where(t->t[1].Contains('external'))
.Select(t->t[0])
.RemoveAttrs
.Select(BasicFuncDef.FromStr);

function LoadNewFuncs :=
ReadLines('OpenGL new.dat')
.SkipWhile(l->not l.Contains('gl = sealed class'))
.TakeWhile(l->not l.Contains('wgl = sealed class'))
.Where(l->l.Contains('[MethodImpl(MethodImplOptions.AggressiveInlining)]'))
.RemoveAttrs
.Select(BasicFuncDef.FromStr);

function BatchFuncs(self: sequence of BasicFuncDef): sequence of AdvFuncDef; extensionmethod :=
self.GroupBy(fd->fd.name)
.Select(g->
begin
  var res := new AdvFuncDef;
  
  res.name := g.Key;
  
  foreach var fd in g do
    if fd.ret=nil then
      res.full_par_defs.Add(fd.pars) else
      res.full_par_defs.Add(fd.pars.Append(fd.ret).ToArray);
  
  var par_c: integer;
  try
    par_c := res.full_par_defs.Select(ovr->ovr.Length).Distinct.Single;
  except
    raise new Exception($'func {res.name}: [{res.full_par_defs.Select(t->_ObjectToString(t)).JoinIntoString}]');
  end;
  
  res.all_par_types := ArrGen(par_c,i->new HashSet<string>);
  foreach var a in res.full_par_defs do
    for var i := 0 to par_c-1 do
      res.all_par_types[i] += a[i];
  
  Result := res;
end);

begin
  try
    var old_f: List<AdvFuncDef> := LoadOldFuncs.BatchFuncs.ToList;
    var new_f: List<AdvFuncDef> := LoadNewFuncs.BatchFuncs.ToList;
    
    var sw := new System.IO.StreamWriter(System.IO.File.Create('Core.cfg'), new System.Text.UTF8Encoding(true));
    sw.WriteLine;
    
    foreach var f in old_f.OrderBy(f->f.name) do
    begin
      var ind := new_f.FindIndex(nf->nf.name=f.name);
      if ind=-1 then
      begin
//        writeln($'функция "{f.name}" исчезла');
        continue;
      end;
      
      var nf := new_f[ind];
      new_f.RemoveAt(ind);
      
      if f.name in [
        'InvalidateSubFramebuffer',
        'InvalidateNamedFramebufferSubData'
      ] then continue;
      
      if f.all_par_types.Length<>nf.all_par_types.Length then raise new Exception(f.name);
      
      sw.Write('F%gl');
      sw.WriteLine(f.name);
      
      if f.all_par_types.Select(hs->hs.Count).Aggregate(1,(i1,i2)->i1*i2) <> f.full_par_defs.Count then
      begin
        sw.WriteLine('T%3');
        
        foreach var ovr in f.full_par_defs do
          sw.WriteLine(ovr.JoinIntoString(' | '));
        
      end else
      if f.all_par_types.Zip(nf.all_par_types,
          (hs1,hs2)->
          ((hs1.Count<>1) or (hs2.Count<>1))
          and not hs1.SequenceEqual(hs2)
        ).Any(b->b) then
      begin
        sw.WriteLine('T%2');
        
        for var i := 0 to f.all_par_types.Length-1 do
        begin
          
          if f.all_par_types[i].SetEquals(nf.all_par_types[i]) then
            sw.Write(' * ') else
          begin
            sw.Write(' ');
            foreach var p in nf.all_par_types[i].Except(f.all_par_types[i]) do sw.Write($'-{p} ');
            foreach var p in f.all_par_types[i].Except(nf.all_par_types[i]) do sw.Write($'+{p} ');
          end;
          
          if i<>f.all_par_types.Length-1 then sw.Write('|');
        end;
        
        sw.WriteLine;
      end else
      if not nf.all_par_types.Zip(f.all_par_types,(hs1,hs2)->hs1.SequenceEqual(hs2)).All(b->b) then
      begin
        sw.WriteLine('T%1');
        
        var repl := new HashSet<string>;
        for var i := 0 to f.all_par_types.Length-1 do
          if f.all_par_types[i].Count=1 then
          begin
            var np := nf.all_par_types[i].Single;
            var p := f.all_par_types[i].Single;
            if np<>p then
              repl += np;
          end;
        
        foreach var np in repl do
        begin
          var ps := nf.all_par_types.ZipTuple(f.all_par_types).Where(t->(t[0].Count=1) and (t[0].Single=np)).Select(t->t[1].Single).ToList;
          if ps.Distinct.Count=1 then
            sw.WriteLine($'{np}=>{ps[0]}') else
            sw.WriteLine($'{np}=> {ps.JoinIntoString('' | '')}');
        end;
        
      end else
        sw.WriteLine('T%0');
      
      sw.WriteLine;
    end;
    
//    foreach var f in new_f.OrderBy(f->f.name) do
//      writeln($'новая функция: "{f.name}"');
    
    sw.Close;
  except
    on e: Exception do writeln(e);
  end;
end.