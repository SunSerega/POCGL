## uses
  Patterns in '../Patterns';
//  StringPatterns in 'StringPatterns',
//  ColoredStrings in '../ColoredStrings';

Console.SetError( Console.Out );

var s1 := $'a';
var s2 := $'a';
foreach var diff in BasicPattern.MinCombination&<BasicCharIterator>(s1, s2) do
begin
  var ss := BasicCharIterator.Between(diff.JumpF,diff.JumpT);
  $'s{diff.Index} added [{ss}] at {ss.range}'.Println;
end;
$'Done'.Println;

////var p1 := new StringPattern('ab@[2..3*c]de');
////var p2 := new StringPattern('axb@[3..4*c]de');
//
////var p1 := new StringPattern('ABA');
////var p2 := new StringPattern('B');
//
////Randomize(0);
////var p1 := new StringPattern(ArrGen(5000,i->Random('A','F')).JoinToString); Writeln(p1);
////var p2 := new StringPattern(ArrGen(5001,i->Random('A','F')).JoinToString); Writeln(p2);
//
//var p := EnumerateFiles('G:\0Prog\AutoMaximize\Classes\1 What')
//.Select(System.IO.Path.GetFileName)
//.Where(fname->fname.StartsWith('HwndWrapper'))
//.Select(fname->StringPattern.Literal(fname))
//.Aggregate((p1,p2)->p1*p2);
//
////exit;
//
////var sw := Stopwatch.StartNew;
////var p := p1*p2;
////Writeln(sw.Elapsed);
//
//var escape_sym := '%';
//
//(
//  $'>>>{p}<<<'.Println =
//  $'>>>{StringPattern.Parse(p.ToString(escape_sym), escape_sym)}<<<'.Println
//)
//.Println
//;
////p.Includes('abccde').Println;
//
//var s := p.ToColoredString(escape_sym);
//s.ForEach(p->
//begin
//  p.EnmrTowardsRoot.Reverse.Select(p->p.key).Print('.');
//  Write(' | ');
//  p.ToString.Println;
//end);
//
////Readln
;