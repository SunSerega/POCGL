unit PackingUtils;

interface

function pas_keywords: HashSet<string>;

implementation

uses POCGL_Utils in '..\..\POCGL_Utils';

var _pas_keywords: HashSet<string>;
function pas_keywords := _pas_keywords;

procedure Init;
begin
  
  _pas_keywords := ReadLines('Packing\Template\Utils\pas_keywords.dat')
  .Where(l->not string.IsNullOrWhiteSpace(l))
  .Select(l->l.Trim.ToLower)
  .ToHashSet;
  
end;

begin
  Init;
end.