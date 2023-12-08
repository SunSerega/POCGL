unit MandelbrotSampling;

{$savepcu false} //TODO

interface

uses OpenCLABC;

function CompiledCode(word_c: cardinal; extra_code: string := nil): CLProgramCode;

type
  CLCodeExecutionError = (CCEE_OK=0
    , CCEE_OVERFLOW=1
    , CCEE_BAD_BIT_IND=2
  );
  
implementation

uses Settings;

{$resource MandelbrotSampling.cl}
var sampling_code_text := System.IO.StreamReader.Create(
  System.Reflection.Assembly.GetCallingAssembly.GetManifestResourceStream('MandelbrotSampling.cl')
).ReadToEnd;

var const_defines: array of (string, string);

function CompiledCode(word_c: cardinal; extra_code: string): CLProgramCode;
begin
  var prog_opt := new CLProgramCompOptions;
  prog_opt.Version := (2,0);
  prog_opt.Defines := Dict(const_defines);
  prog_opt.Defines.Add('POINT_COMPONENT_WORD_COUNT',  word_c.ToString);
  
  var code_text := sampling_code_text;
  if extra_code<>nil then
    code_text += #10+extra_code;
  
  Result := new CLProgramCode(code_text, prog_opt);
end;

begin
  var const_defines_l := new List<(string, string)>;
  const_defines_l += ('BLOCK_W',    Settings.block_w.ToString);
  const_defines_l += ('Z_INT_BITS', Settings.z_int_bits.ToString);
  foreach var e in System.Enum.GetValues(typeof(CLCodeExecutionError)).Cast&<CLCodeExecutionError> do
  begin
    var v := integer(e);
    const_defines_l += (e.ToString, v.ToString);
    if not sampling_code_text.IsMatch($'\W{e}\W') then
      $'WARNING: Error code [{e}={v}] was not used in .cl file'.Println;
  end;
  const_defines := const_defines_l.ToArray;
end.