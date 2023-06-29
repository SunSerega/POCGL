unit PackingUtils;

interface

function pas_keywords: HashSet<string>;

implementation

uses '../../../POCGL_Utils';

var _pas_keywords: HashSet<string>;
function pas_keywords := _pas_keywords;

procedure Init :=
try
  
  _pas_keywords := ReadLines('Packing/Template/Common/pas_keywords.dat', enc)
    .Where(l->not string.IsNullOrWhiteSpace(l))
    .Select(l->l.Trim)
    .ToHashSet(System.StringComparer.OrdinalIgnoreCase);
  
except
  on e: Exception do
    ErrOtp(e);
end;

begin
  Init;
end.