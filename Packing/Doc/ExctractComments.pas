{$string_nullbased+}
const fname = 'OpenCLABC';

const block_open_kvds: array of string = ('begin','case','match','try');

function GetFuncEndInd(l: string): integer;
begin
  Result := l.LastIndexOf(':=');
  if Result=-1 then exit;
  var ind := l.LastIndexOf(')');
  if ind>Result then
  Result := l.LastIndexOf(':=', l.LastIndexOf('('));
end;

function GetParams(l: string): string := l.Split(';')
  .SelectMany(par->
  begin
    var ind1 := par.IndexOf(']')+1;
    var ind2 := par.IndexOf(':');
    var res := par.SubString(ind2+1);
    if res.Contains(':=') then
      res := res.Remove(res.IndexOf(':='));
    Result := Arr(res.Trim).Cycle.Take( par.Skip(ind1).Take(ind2-ind1).Count(ch->ch=',') + 1 );
  end).JoinIntoString(', ')
;

function RemoveBlock(self: string; f,t: string): string; extensionmethod;
begin
  
  while true do
  begin
    var ind1 := self.IndexOf(f);
    if ind1=-1 then break;
    var ind2 := self.IndexOf(t,ind1+f.Length)+t.Length;
    self := self.Remove(ind1,ind2-ind1);
  end;
  
  Result := self;
end;

function GetComments(lns: sequence of string): Dictionary<string,string>;
begin
  Result := new Dictionary<string, string>;
  var res: StringBuilder;
  
  var last_type := '';
  var block_lvl := 0; // 1 = class, 2+ = method body
  
  foreach var l in lns.Select(l->
    begin
      var ind := l.Replace('///','---').IndexOf('//');
      if ind<>-1 then l := l.Remove(ind);
      
      Result := l.RemoveBlock('{','}').RemoveBlock('''','''');
    end)
    .Select(l->l.Trim(' '))
    .SkipWhile(s-> s<>'interface' ).Skip(1)
    .TakeWhile(s-> s<>'implementation' )
  do
    if l.StartsWith('///') then
    begin
      if res=nil then res := new StringBuilder;
      res.AppendLine(l.Remove(0,3));
    end else
    begin
//      $'{block_lvl,5}: {l}'.Println;
      
      var bl_p := block_open_kvds.Any(kvd->l.Contains(kvd));
      var bl_m := l.Contains('end');
      
      if bl_p then block_lvl += 1;
      if bl_m then block_lvl -= 1;
      if block_lvl=0 then last_type := '' else
      if block_lvl<0 then raise new Exception($'Лишний "end" на строчке "{l}"');
      if bl_p or bl_m then continue;
      
      if block_lvl>1 then continue;
      var h_ind1 := GetFuncEndInd(l);
      if h_ind1=-1 then h_ind1 := l.Length;
      
      var ind := Max( l.IndexOf('procedure'), l.IndexOf('function') );
      if ind<>-1 then
      begin
        if res=nil then continue;
        
        var ind1 := l.IndexOf(' ',ind);
        var ind2 := l.IndexOf('(',ind);
        if ind2>h_ind1 then ind2 := -1;
        
        var ind3 := ind2;
        if ind3=-1 then ind3 := l.IndexOf(':',ind1);
        if ind3=-1 then ind3 := l.IndexOf(';',ind1);
        if ind3=-1 then ind3 := l.Length;
        var m_name := l.Substring(ind1, ind3-ind1).Trim(' ', ':');
        
        var pars := ind2=-1 ? '' : GetParams(
          l.Substring(ind2+1,l.Substring(0,h_ind1).LastIndexOf(')',h_ind1-1,h_ind1-ind2)-ind2-1)
        );
        
        res.Length -= 1;
        Result.Add( $'{last_type}.{m_name}({pars})', res.ToString );
        res := nil;
        
        continue;
      end;
      ind := l.IndexOf('constructor');
      if ind<>-1 then
      begin
        if res=nil then continue;
        
        var ind2 := l.IndexOf('(',ind);
        if ind2>h_ind1 then ind2 := -1;
        
        var pars := ind2=-1 ? '' : GetParams(
          l.Substring(ind2+1,l.Substring(0,h_ind1).LastIndexOf(')',h_ind1-1,h_ind1-ind2)-ind2-1)
        );
        
        res.Length -= 1;
        Result.Add( $'{last_type}.({pars})', res.ToString );
        res := nil;
        
        continue;
      end;
      ind := l.IndexOf('property');
      if ind<>-1 then
      begin
        if res=nil then continue;
        
        var ind1 := l.IndexOf(' ',ind);
        var ind2 := l.IndexOf(':',ind1);
        var p_name := l.Substring(ind1,ind2-ind1).Trim(' ');
        
        res.Length -= 1;
        Result.Add( $'{last_type}.{p_name}', res.ToString );
        res := nil;
        
        continue;
      end;
      
      if block_lvl>0 then continue;
      ind := Max(Max( l.IndexOf('record'), l.Replace('class;','cvass;').IndexOf('class') ), l.IndexOf('interface') );
      if ind<>-1 then
      begin
        var ind2 := l.LastIndexOf('=',ind)-1;
        while l[ind2-1]=' ' do ind2 -= 1;
        var ind1 := l.LastIndexOf(' ',ind2-1)+1;
        
        last_type := l.Substring(ind1,ind2-ind1).TrimEnd(' ');
        if res<>nil then
        begin
          res.Length -= 1;
          Result.Add( last_type, res.ToString );
          res := nil;
        end;
        
        block_lvl += 1;
        continue;
      end;
      
    end;
  
end;

begin
  var lns := ReadLines(fname+'.pas');
  
  lns.Where(l->not l.TrimStart(' ').StartsWith('///')).WriteLines(fname+'.cleared.pas');
  var d := GetComments(lns);
  var lst := d.Values.Distinct.ToList;
  
  d.Keys.PrintLines;
  exit;
  
  System.IO.Directory.CreateDirectory(fname);
  
  var lnks := System.IO.File.CreateText(fname+'\lnks.dat');
  var vals := System.IO.File.CreateText(fname+'\vals.dat');
  
  lnks.WriteLine;
  vals.WriteLine;
  
  foreach var name in d.Keys do
  begin
    lnks.Write('# ');
    lnks.WriteLine(name);
    lnks.WriteLine($'%val{lst.IndexOf(d[name])}%');
    lnks.WriteLine;
  end;
  
  for var i := 0 to lst.Count-1 do
  begin
    vals.Write('# val');
    vals.WriteLine(i);
    vals.WriteLine(lst[i]);
  end;
  
  lnks.Close;
  vals.Close;
end.