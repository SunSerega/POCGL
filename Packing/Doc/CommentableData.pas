unit CommentableData;
{$string_nullbased+}

interface

procedure FindCommentable(lns: sequence of string; on_line: string->boolean; on_commentable: string->());

implementation

{$region Utils}

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
end)
.JoinIntoString(', ');

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

{$endregion Utils}

{$region MemberParsers}

function ParseType(l: string; ind: integer; var block_lvl: integer; var last_type: string): string;
begin
  var ind2 := l.LastIndexOf('=',ind)-1;
  while l[ind2-1]=' ' do ind2 -= 1;
  var ind1 := l.LastIndexOf(' ',ind2-1)+1;
  
  last_type := l.Substring(ind1,ind2-ind1).TrimEnd(' ');
  Result := last_type;
  
  block_lvl += 1;
end;

function ParseMethod(last_type, l: string; ind, h_ind1: integer): string;
begin
  var ind1 := l.IndexOf(' ',ind);
  var ind2 := l.IndexOf('(',ind);
  if ind2>h_ind1 then ind2 := -1;
  
  var ind3 := ind2;
  if ind3=-1 then ind3 := l.IndexOf(':',ind1);
  if ind3=-1 then ind3 := l.IndexOf(';',ind1);
  if ind3=-1 then ind3 := l.Length;
  var m_name := l.Substring(ind1, ind3-ind1).Trim(' ', ':');
  if m_name.StartsWith('operator') then exit;
  
  var pars := ind2=-1 ? '' : GetParams(
    l.Substring(ind2+1,l.Substring(0,h_ind1).LastIndexOf(')',h_ind1-1,h_ind1-ind2)-ind2-1)
  );
  
  Result := $'{last_type}.{m_name}({pars})';
end;

function ParseConstructor(last_type, l: string; ind, h_ind1: integer): string;
begin
  var ind2 := l.IndexOf('(',ind);
  if ind2>h_ind1 then ind2 := -1;
  
  var pars := ind2=-1 ? '' : GetParams(
    l.Substring(ind2+1,l.Substring(0,h_ind1).LastIndexOf(')',h_ind1-1,h_ind1-ind2)-ind2-1)
  );
  
  Result := $'{last_type}.({pars})';
end;

function ParseProp(last_type, l,_l: string; ind, h_ind1: integer): string;
begin
  var ind1 := l.IndexOf(' ',ind);
  var ind2 := l.IndexOf('[',ind);
  if ind2>h_ind1 then ind2 := -1;
  
  var io_ind := Arr('read','write').Select(s->l.IndexOf(s)).Where(ind-> ind<>-1 ).DefaultIfEmpty(l.Length).First;
  
  var ind3 := ind2;
  if ind3=-1 then ind3 := l.IndexOf(':',ind1);
  if ind3=-1 then raise new System.InvalidOperationException(_l);
  var p_name := l.Substring(ind1, ind3-ind1).Trim(' ', ':');
  
  if ind2=-1 then
    Result := $'{last_type}.{p_name}' else
  begin
    var pars := GetParams(
      l.Substring(ind2+1,l.Substring(0,io_ind).LastIndexOf(']',io_ind-1,io_ind-ind2)-ind2-1)
    );
    Result := $'{last_type}.{p_name}[{pars}]';
  end;
  
end;

function ParseEvent(last_type, l: string; ind: integer): string;
begin
  ind += 'event'.Length+1;
  var ind2 := l.IndexOf(':', ind);
  
  var e_name := l.SubString(ind,ind2-ind).Trim(' ');
  
  Result := $'{last_type}.{e_name}';
end;

{$endregion MemberParsers}

procedure FindCommentable(lns: sequence of string; on_line: string->boolean; on_commentable: string->());
begin
  
  var last_type := '';
  var block_lvl := 0; // 1 = class, 2+ = method body
  
  var start_checking := false;
  var end_checking := false;
  
  foreach var _l in lns do
  begin
    var l := _l;
    
    if not on_line(l) then continue;
    
    var ind := l.Replace('///','---').IndexOf('//');
    if ind<>-1 then l := l.Remove(ind);
    
    l := l.RemoveBlock('{','}').RemoveBlock('''','''').Trim(' ');
    
    if not start_checking and l.Contains('interface') then
    begin
      start_checking := true;
      continue;
    end;
    if l.Contains('implementation') then end_checking := true;
    if not start_checking or end_checking then continue;
    
//    $'{block_lvl,5}: {l}'.Println;
    
    var bl_p := block_open_kvds.Any(kvd->l.Contains(kvd));
    var bl_m := l.Contains('end');
    
    if bl_p then block_lvl += 1;
    if bl_m then block_lvl -= 1;
    if block_lvl=0 then last_type := '' else
    if block_lvl<0 then raise new Exception($'Лишний "end" на строчке "{l}"');
    if bl_p or bl_m then continue;
    
    case block_lvl of
      
      0:
      begin
        
        ind := Max(Max( l.IndexOf('record'), l.Replace('class;','cvass;').IndexOf('class') ), l.Replace('interface;','underface;').IndexOf('interface') );
        if ind<>-1 then
        begin
          on_commentable(ParseType(l,ind, block_lvl,last_type));
          continue;
        end;
        
        ind := Max( l.IndexOf('procedure'), l.IndexOf('function') );
        if ind<>-1 then
        begin
          var comm := ParseMethod(last_type,l, ind,l.Length);
          if not string.IsNullOrEmpty(comm) then on_commentable(comm);
          continue;
        end;
        
      end;
      
      1:
      begin
        var h_ind1 := GetFuncEndInd(l);
        if h_ind1=-1 then h_ind1 := l.Length;
        
        ind := Max( l.IndexOf('procedure'), l.IndexOf('function') );
        if ind<>-1 then
        begin
          var comm := ParseMethod(last_type,l, ind,h_ind1);
          if not string.IsNullOrEmpty(comm) then on_commentable(comm);
          continue;
        end;
        
        ind := l.IndexOf('constructor');
        if ind<>-1 then
        begin
          on_commentable(ParseConstructor(last_type,l, ind,h_ind1));
          continue;
        end;
        
        ind := l.IndexOf('property');
        if ind<>-1 then
        begin
          on_commentable(ParseProp(last_type,l,_l, ind,h_ind1));
          continue;
        end;
        
        ind := l.IndexOf(' event ');
        if ind<>-1 then
        begin
          on_commentable(ParseEvent(last_type,l, ind));
          continue;
        end;
        
      end;
      
    end;
    
  end;
  
end;

end.