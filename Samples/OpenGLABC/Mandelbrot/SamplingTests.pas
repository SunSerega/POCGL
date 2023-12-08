uses OpenCLABC, Settings, MandelbrotSampling;
{$zerobasedstrings}

// word_count => call => test_func_name
var test_func_names := new Dictionary<integer, Dictionary<string, string>>;
function TestFuncNameForCall(word_c: integer; call: string): string;
begin
  var names_per_wc := test_func_names.Get(word_c);
  if names_per_wc=nil then
  begin
    names_per_wc := new Dictionary<string, string>;
    test_func_names.Add(word_c, names_per_wc);
  end;
  if names_per_wc.TryGetValue(call, Result) then exit;
  Result := $'Test{names_per_wc.Count}';
  names_per_wc.Add(call, Result);
end;

type
  TestInfo = sealed class
    word_c: integer;
    func_name: string;
    act: CLKernel->();
    
    constructor(word_c: integer; call: string; act: CLKernel->());
    begin
      self.word_c := word_c;
      self.func_name := TestFuncNameForCall(word_c, call);
      self.act := act;
    end;
    
  end;
var all_tests := new List<TestInfo>;

var g_call := default(string);
procedure AddTest(inp_s, res_s: array of string; expected_ccee: CLCodeExecutionError);
begin
  var word_c := inp_s.First.CountOf('|')+1;
  var call := g_call;
  
  all_tests += new TestInfo(word_c, call, k->
  begin
    var bit_to_sign := |'+','-'|;
    
    var s_to_bin := procedure(bin: array of cardinal; ni: integer; s: string) ->
    begin
      
      if s[z_int_bits]<>'.' then
        raise new System.FormatException($'Expected period after {z_int_bits} first bits: {s}');
      s := s.Remove(z_int_bits, 1);
      
      var first_bit := bit_to_sign.IndexOf(s.First);
      if first_bit not in 0..1 then
        raise new System.FormatException($'Expected sign instead of first bit: {s}');
      s[0] := first_bit.ToString.Single;
      
      var words_s := s.Split('|');
      if words_s.Length <> word_c then
        raise new System.FormatException($'Expected {word_c} words: {s}');
      
      for var wi := 0 to word_c-1 do
      begin
        if words_s[wi].Length<>32 then
          raise new System.FormatException($'Expected 32 bits in word [{words_s[wi]}], found {words_s[wi].Length}: {s}');
        bin[ni*word_c + wi] := System.Convert.ToUInt32(words_s[wi], 2);
      end;
      
    end;
    
    var inp := new cardinal[inp_s.Length * word_c];
    for var i := 0 to inp_s.Length-1 do
      s_to_bin(inp, i, inp_s[i]);
    
    var res := new cardinal[inp.Length];
    for var i := 0 to res_s.Length-1 do
      s_to_bin(res, i, res_s[i]);
    for var i := res_s.Length*word_c to res.Length-1 do
      res[i] := inp[i];
    
    var A_Data := new CLArray<cardinal>(inp);
    var V_Err := new CLValue<integer>(integer(CCEE_OK));
    var ccee := CLContext.Default.SyncInvoke(
      k.MakeCCQ.ThenExec1(1, A_Data, V_Err) +
      A_Data.MakeCCQ.ThenReadArray(inp) +
      V_Err.MakeCCQ.ThenGetValue.ThenConvert(v->CLCodeExecutionError(v), false)
    );
    V_Err.Dispose;
    A_Data.Dispose;
    
    $'Calling: {call}'.Println;
    $'Input:'.Println;
    foreach var s in inp_s do
      s.Println;
    $'Expected:'.Println;
    foreach var s in res_s+inp_s.Skip(res_s.Length) do
      s.Println;
    
    $'Calculated:'.Println;
    foreach var n in inp.Batch(word_c) do
    begin
      var first_word := true;
      foreach var w in n do
      begin
        if not first_word then
          Write('|');
        for var bi := 31 downto 0 do
        begin
          var bit := w shr bi and 1;
          if first_word and (bi=31) then
            Write(bit_to_sign[bit]) else
            Write(bit);
          if first_word and (32-bi=z_int_bits) then
            Write('.');
        end;
        first_word := false;
      end;
      Writeln;
    end;
    
    $'CCEE: {ccee}'.Println;
    if ccee <> expected_ccee then
      raise new Exception($'Unexpected error [{ccee}]; expected [{expected_ccee}]');
    
    if inp.ZipTuple(res).Any(\(a,b)->a<>b) then
      raise new Exception($'Invalid result');
    
    Println('='*70);
  end);
  
end;

begin
  try
//    CLContext.Default := new CLContext(CLDevice.GetAllFor(CLPlatform.All[1], clDeviceType.DEVICE_TYPE_ALL).Single);
    
    var more_output := true;
    {$ifdef ForceMaxDebug}
    more_output := false;
    {$endif ForceMaxDebug}
    
    var sw := Stopwatch.StartNew;
    var empty_res := System.Array.Empty&<string>;
    
    {$region point_component}
    
    {$region add}
    
    //TODO NVidia implementation cannot parse whitespaces in defines
//    call := 'point_component_add(&x->r, x->i, err)';
    g_call := 'point_component_add(&x->r,x->i,err)';
    
    AddTest(|
      '+000.0000000000000000000000000000',
      '+000.0000000000000000000000000000'
    |, empty_res, CCEE_OK);
    
    AddTest(|
      '+000.0000000000000000000000000000|00000000000000000000000000000000',
      '+000.0000000000000000000000000000|00000000000000000000000000000000'
    |, empty_res, CCEE_OK);
    
    AddTest(|
      '+010.0000000000000000000000000000|00000000000000000000000000000000',
      '+010.0000000000100000000000000000|00000000000000000000000000000000'
    |, |
      '+100.0000000000100000000000000000|00000000000000000000000000000000'
    |, CCEE_OK);
    
    AddTest(|
      '+111.1000000000000000000000000000|00000000000000000000000000000000',
      '+010.1000000000000000000000000000|00000000000000000000000000000000'
    |, |
      '-010.0000000000000000000000000000|00000000000000000000000000000000'
    |, CCEE_OVERFLOW);
    
    AddTest(|
      '+000.0100000000000000000000000000|00000000000000000000000000000000',
      '-001.0000000000000000000000000000|00000000000000000000000000000000'
    |, |
      '-000.1100000000000000000000000000|00000000000000000000000000000000'
    |, CCEE_OK);
    
    AddTest(|
      '+000.1111111111111111111111111111|11111111111111110000000000000000',
      '+000.0000000000000000000000000000|00000000000000010000000000000000'
    |, |
      '+001.0000000000000000000000000000|00000000000000000000000000000000'
    |, CCEE_OK);
    
    AddTest(|
      '+000.0000000000000000000000000000|00000000000001000000000000000000',
      '-001.0000000000000000000000000000|00000000000000000000000000000000'
    |, |
      '-000.1111111111111111111111111111|11111111111111000000000000000000'
    |, CCEE_OK);
    
    AddTest(|
      '+011.1111111111111111111111111111|11111111111111111111111111111111',
      '+011.1111111111111111111111111111|11111111111111111111111111111111'
    |, |
      '+111.1111111111111111111111111111|11111111111111111111111111111110'
    |, CCEE_OK);
    
    AddTest(|
      '+011.1111111111111111111111111111',
      '+011.1111111111111111111111111111'
    |, |
      '+111.1111111111111111111111111110'
    |, CCEE_OK);
    
    {$endregion add}
    
    {$region mlt shl1}
    
    g_call := 'point_component_mul_shl1(&x->r,x->i,err)';
    
    AddTest(|
      '-000.0000000000000000000000000000|00000000000000000000000000000000',
      '+000.0000000000000000000000000000|00000000000000000000000000000000'
    |, empty_res, CCEE_OK);
    
    AddTest(|
      '+000.0000000000000000000000000000|00000000000000000000000000000000',
      '-000.0000000000000000000000000000|00000000000000000000000000000000'
    |, |
      '-000.0000000000000000000000000000|00000000000000000000000000000000'
    |, CCEE_OK);
    
    AddTest(|
      '-000.0000000000000000000000000000|00000000000000000000000000000000',
      '-000.0000000000000000000000000000|00000000000000000000000000000000'
    |, |
      '+000.0000000000000000000000000000|00000000000000000000000000000000'
    |, CCEE_OK);
    
    AddTest(|
      '+001.1000000000000000000000000000|00000000000000000000000000000000',
      '+000.1100000000000000000000000000|00000000000000000000000000000000'
    |, |
      '+010.0100000000000000000000000000|00000000000000000000000000000000'
    |, CCEE_OK);
    
    // Test round up after mlt
    AddTest(|
      '+000.0000000000000000000000000101',
      '+000.1100000000000000000000000000'
    |, |
      '+000.0000000000000000000000001000'
    |, CCEE_OK);
    AddTest(|
      '+000.0000000000000000000000000101',
      '+001.1000000000000000000000000000'
    |, |
      '+000.0000000000000000000000001111'
    |, CCEE_OK);
    
    {$endregion mlt shl1}
    
    {$region sqr}
    
    g_call := 'point_component_sqr(&x->r,err)';
    
    AddTest(|
      '-000.0000000000000000000000000000|00000000000000000000000000000000'
    |, |
      '+000.0000000000000000000000000000|00000000000000000000000000000000'
    |, CCEE_OK);
    
    AddTest(|
      '+000.0000000000000000000000000001|00000000000000000000000000000000'
    |, |
      '+000.0000000000000000000000000000|00000000000000000000000000010000'
    |, CCEE_OK);
    
    AddTest(|
      '-001.1000000000000000000000000000'
    |, |
      '+010.0100000000000000000000000000'
    |, CCEE_OK);
    
    {$endregion sqr}
    
    {$region add bit mlt}
    
    g_call := 'point_component_add_bit_mlt(&x->r,5,0,err)';
    
    AddTest(|
      '+000.0000000000000000000000000000'
    |, |
      '+000.0010000000000000000000000000'
    |, CCEE_OK);
    
    g_call := 'point_component_add_bit_mlt(&x->r,6,0b101,err)';
    
    AddTest(|
      '+001.0000000000000000000000000000'
    |, |
      '+001.1011000000000000000000000000'
    |, CCEE_OK);
    
    AddTest(|
      '-001.0000000000000000000000000000'
    |, |
      '-000.0101000000000000000000000000'
    |, CCEE_OK);
    
    {$endregion add bit mlt}
    
    {$endregion point_component}
    
    {$region point_pos}
    
    {$region add}
    
    g_call := 'point_add(x,x[1],err)';
    
    AddTest(|
      '+000.0000000000000000000000000000|00000000000000000000000000000000',
      '+000.0000000000000000000000000000|00000000000000000000000000000000',
      '+000.0000000000000000000000000000|00000000000000000000000000000000',
      '+000.0000000000000000000000000000|00000000000000000000000000000000'
    |, empty_res, CCEE_OK);
    
    AddTest(|
      '+000.0000000000000000000000000000|01000000000000000000000000000000',
      '-000.0000000000000000000000000000|01000000000000000000000000000000',
      '-001.0000000000000000000000000000|00000000000000000000000000000000',
      '+001.0000000000000000000000000000|00000000000000000000000000000000'
    |, |
      '-000.1111111111111111111111111111|11000000000000000000000000000000',
      '+000.1111111111111111111111111111|11000000000000000000000000000000'
    |, CCEE_OK);
    
    {$endregion add}
    
    {$region sqr}
    
    g_call := 'point_sqr(x,err)';
    
    AddTest(|
      '+000.0000000000000000000000000000|00000000000000000000000000000000',
      '-000.0000000000000000000000000000|00000000000000000000000000000000'
    |, empty_res, CCEE_OK);
    
    AddTest(|
      '+001.0000000000000000000000000000|00100000000000000000000000000000',
      '-001.0000000000000000000000000000|01000000000000000000000000000000'
    |, |
      '-000.0000000000000000000000000000|01000000000000000000000000000001',
      '-010.0000000000000000000000000000|11000000000000000000000000000001'
    |, CCEE_OK);
    
    {$endregion sqr}
    
    {$endregion point_pos}
    
    var complied := test_func_names.ToDictionary(kvp->kvp.Key, kvp->
    begin
      var word_c := kvp.Key;
      var names_per_wc := kvp.Value;
      Result := CompiledCode(word_c,
        names_per_wc
        .Select(kvp->$'kernel void {kvp.Value}(global point_pos * x, global uint * err) {{ {kvp.Key}; }}')
        .JoinToString(#10)
      );
    end);
//    System.IO.Directory.Delete($'{System.Environment.GetEnvironmentVariable(''APPDATA'')}\NVIDIA\ComputeCache', true); exit;
    
    foreach var t in all_tests do
      t.act(complied[t.word_c][t.func_name]);
    
    if more_output then
      $'Done testing in [{sw.Elapsed}]'.Println;
  except
    on e: Exception do
      Println(e);
  end;
  
  if '[REDIRECTIOMODE]' not in System.Environment.CommandLine then
  begin
    $'Press enter to exit'.Println;
    Readln;
  end;
end.