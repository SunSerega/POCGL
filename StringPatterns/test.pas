## uses
  StringPatterns in '../StringPatterns',
  ColoredStrings in '../ColoredStrings';

//var p1 := new StringPattern('ab@[2..3*c]de');
//var p2 := new StringPattern('axb@[3..4*c]de');

//var p1 := new StringPattern('ABA');
//var p2 := new StringPattern('B');

//Randomize(0);
//var p1 := new StringPattern(ArrGen(5000,i->Random('A','F')).JoinToString); Writeln(p1);
//var p2 := new StringPattern(ArrGen(5001,i->Random('A','F')).JoinToString); Writeln(p2);

var p := EnumerateFiles('G:\0Prog\AutoMaximize\Classes\1 What')
.Select(System.IO.Path.GetFileName)
.Where(fname->fname.StartsWith('HwndWrapper'))
.Select(fname->new StringPattern(fname))
.Aggregate((p1,p2)->p1*p2);

//exit;

//var sw := Stopwatch.StartNew;
//var p := p1*p2;
//Writeln(sw.Elapsed);

(
  $'>>>{p}<<<'.Println =
  $'>>>{new StringPattern(p.ToString)}<<<'.Println
)
.Println
;
//p.Includes('abccde').Println;

var s := p.ToColoredString;
s.ForEach(p->
begin
  p.EnmrTowardsRoot.Reverse.Select(p->p.key).Print('.');
  Write(' | ');
  p.ToString.Println;
end);

//Readln
;