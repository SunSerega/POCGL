unit ScrapUtils;

uses '../../Utils/AOtp';
uses '../../POCGL_Utils';

var log := new FileLogger(GetFullPathRTA('xml.log'));

function RemoveBeg(self, s: string; ignore_case: boolean := false): string; extensionmethod;
begin
  var comp := if ignore_case then
    System.StringComparison.OrdinalIgnoreCase else
    System.StringComparison.Ordinal;
  if not self.StartsWith(s, comp) then
    raise new System.InvalidOperationException($'[{self}]/[{s}]');
  Result := self.Remove(0,s.Length);
end;
function RemoveEnd(self, s: string): string; extensionmethod;
begin
  if not self.EndsWith(s) then
    raise new System.InvalidOperationException($'[{self}]/[{s}]');
  Result := self.SubString(0,self.Length-s.Length);
end;

end.