##

(**
uses '../Patterns';

var s1 := $'abada';
var s2 := $'acaea';
foreach var diff in BasicPattern.MinCombination&<BasicCharIterator>(s1, s2) do
begin
  var ss := BasicCharIterator.Between(diff.JumpF,diff.JumpT);
  $'s{diff.Index} added [{ss}] at {ss.range}'.Println;
end;
$'Done'.Println;

(*)

//Console.SetError( Console.Out );

uses
  'MergedStrings',
  '../ColoredStrings';

var escape_sym := '%';

{}
//var p := MergedString.Parse('a@[*0..z]a');

var count_minuses := function(s: MergedString): integer->
begin
  var c := 0;
  s.ToColoredString.ForEach(p->
    if p.Key='wild' then
      c += p.ToString.CountOf('-')
  );
  Result := c;
end;

var p: MergedString;
begin
  var ps := EnumerateFiles('G:/0Prog/AutoMaximize/Classes/1 What')
    .Select(System.IO.Path.GetFileName)
    .Where(fname->fname.StartsWith('HwndWrapper'))
    .Select(MergedString.Literal)
    .ToHashSet;
  while ps.Count.Println>1 do
  begin
//    ps.PrintLines;
//    ('='*30).Println;
    
    var best: (MergedString,MergedString,MergedString,integer) := nil;
    
    foreach var (p1,p2) in ps.Combinations(2).Select(a->a.AsEnumerable) do
    begin
      if p1 not in ps then continue;
      if p2 not in ps then continue;
      var res := MergedString.AllMerges(p1,p2).Select(pr->
      begin
        Result := (p1,p2,pr,count_minuses(pr));
      end).MinBy(t->t.Item4);
      if res.Item4=0 then
      begin
        ps.Remove(p1);
        ps.Remove(p2);
        ps += res.Item3;
        ps.Count.Println;
        
//        if res.Item3 in p1 then continue;
//        if res.Item3 in p2 then continue;
//        p1.Println;
//        p2.Println;
//        res.Item3.Println;
//        ('='*30).Println;
        
      end else
      if (best=nil) or (res.Item4<best.Item4) then
        best := res;
    end;
    
    var (p1,p2,pr,c) := best;
    if p1 not in ps then continue;
    if p2 not in ps then continue;
    ps.Remove(p1);
    ps.Remove(p2);
    ps += pr;
    
//    if pr in p1 then continue;
//    if pr in p2 then continue;
//    p1.Println;
//    p2.Println;
//    pr.Println;
//    ('='*30).Println;
    
  end;
  p := ps.Single;
end;

//var p := EnumerateFiles('G:/0Prog/AutoMaximize/Classes/1 What')
//.Select(System.IO.Path.GetFileName)
//.Where(fname->fname.StartsWith('HwndWrapper'))
//.Select(MergedString.Literal)
//.Aggregate((p1,p2)->
//begin
////  MergedString.AllMerges(p1,p2).Count.Println;
//  Result := p1*p2;
//  if Result in p1 then exit;
//  if Result in p2 then exit;
//  p1.Println;
//  p2.Println;
//  Result.Println;
//  ('='*30).Println;
//end);

{

var p1 := MergedString.Parse('_____');
var p2 := MergedString.Parse('_____');

try
  var p := p1*p2;
except
  on e: Exception do
  begin
    writeln(e);
    exit;
  end;
end;

//var p1 := MergedString($'ABD');
//var p2 := MergedString($'AC');

//Randomize(0);
//var p1 := MergedString(ArrGen(2,i->Random('A','F')).JoinToString); Writeln(p1);
//var p2 := MergedString(ArrGen(4,i->Random('A','F')).JoinToString); Writeln(p2);

//MergedString.AllMerges(p1,p2).PrintLines
//(s->
//begin
//  var c := 0;
//  s.ToColoredString.ForEach(p->
//    if p.Key='wild' then
//      c += p.ToString.CountOf('-')
//  );
//  Result := ;
//end)
//;
//exit;

var sw := Stopwatch.StartNew;
var p := p1*p2;
Writeln(sw.Elapsed);

{}

(
  $'{p}'.Println =
  $'{MergedString.Parse(p.ToString(escape_sym).Println, escape_sym)}'.Println
)
.Println
;
('abccccde' in p).Println;

var s := p.ToColoredString(escape_sym);
s.ForEach(p->
begin
  p.EnmrTowardsRoot.Reverse.Select(p->p.key).Print('.');
  Write(' | ');
  p.ToString.Println;
end);

(**)

if '[REDIRECTIOMODE]' not in System.Environment.GetCommandLineArgs then
  Readln;