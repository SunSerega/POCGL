unit ScrapUtils;

interface

uses '../../Utils/ThoroughXML';
uses '../../Utils/AOtp';
uses '../../POCGL_Utils';

var log := new FileLogger(GetFullPathRTA('xml.log'));

procedure Init(repo_name: string);
function GetXml(name: string): XmlNode;

implementation

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

var all_xml_files: Dictionary<string, (string,XmlNode)>;
procedure Init(repo_name: string);
begin
  if all_xml_files<>nil then raise new System.InvalidOperationException;
  var path := System.IO.Path.GetFullPath(GetFullPathRTA($'../../Reps/{repo_name}/xml'));
  all_xml_files := EnumerateFiles(path, '*.xml')
    .Select(fname->fname.Replace('\','/'))
    .ToDictionary(System.IO.Path.GetFileNameWithoutExtension, fname->(fname,
      new XmlNode(ReadAllText(fname, enc).Replace(#13#10,#10))
    ));
end;
function GetXml(name: string): XmlNode;
begin
  Result := all_xml_files.Get(name)?.Item2;
  if Result=nil then
    raise new System.InvalidOperationException($'XML namespace [{name}] is not defined');
end;

procedure Finalize :=
try
  
  var max_xml_body_size := 250;
  var attrib_descr := function(a: XmlAttrib): string ->
    a.ToString;
  var node_descr := function(n: XmlNode): string ->
  begin
    
    var body := n.Text;
    if body.Length>max_xml_body_size then
      body := body.Remove(max_xml_body_size);
    body := body.Replace(#10,'\n');
    
    Result := n.FullPath
      + '< ' + n.GetAllAttribs.Select(kvp->$'{kvp.Key}="{kvp.Value.Data}"').JoinToString + ' >'
      + ': ' + body
  end;
  
  foreach var (fname, n) in all_xml_files.Values do
  begin
    if n.IsDiscarded then raise new System.NotImplementedException;
    if not n.WasUsed then
      log.Otp($'File [{fname}] wasn''t used') else
      n.ThoroughCheck(()->Otp($'=== {fname} ===')
        , a->Otp($'WARNING: Unused attribute                  | {attrib_descr(a)}')
        , a->Otp($'WARNING: Attribute was used and discarded  | {attrib_descr(a)}')
        , n->Otp($'WARNING: Unused node                       | {node_descr(n)}')
        , n->Otp($'WARNING: Node was used and discarded       | {node_descr(n)}')
      );
  end;
  
  log.Close;
except
  on e: Exception do ErrOtp(e);
end;

initialization
finalization
  Finalize;
end.