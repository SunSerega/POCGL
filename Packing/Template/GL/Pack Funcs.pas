uses FuncData;
uses MiscUtils in '..\..\..\Utils\MiscUtils.pas';

procedure AddGetFPtr(sb: StringBuilder);
begin
  sb += '    public static function GetFuncAdr([MarshalAs(UnmanagedType.LPStr)] lpszProc: string): IntPtr;'#10;
  sb += '    external ''opengl32.dll'' name ''wglGetProcAddress'';'#10;
  sb += '    public static function GetFuncOrNil<T>(fadr: IntPtr) :='#10;
  sb += '    fadr=IntPtr.Zero ? default(T) :'#10;
  sb += '    Marshal.GetDelegateForFunctionPointer&<T>(fadr);'#10;
end;

begin
  try
    InitLog(log, '..\Log\Funcs.log');
    InitLog(func_ovrs_log, '..\Log\FinalFuncOverloads.log');
    var res := new StringBuilder;
    
    loop 3 do func_ovrs_log.WriteLine;
    
    Otp($'Reading .bin');
    var br := new System.IO.BinaryReader(System.IO.File.OpenRead('DataScraping\XML\GL\funcs.bin'));
    var grs :=        ArrGen(br.ReadInt32, i->new Group(br)).ToList;
    var funcs :=      ArrGen(br.ReadInt32, i->new Func(br,grs)).ToList;
    var features :=   ArrGen(br.ReadInt32, i->new Feature(br,funcs)).ToList;
    var extensions := ArrGen(br.ReadInt32, i->new Extension(br,funcs)).ToList;
    if br.BaseStream.Position<>br.BaseStream.Length then raise new System.FormatException;
    
    Otp($'Fixing all');
    GroupFixer.ApplyAll(grs);
    FuncFixer.ApplyAll(funcs);
    
    Otp($'Constructing new code');
    res += '  '#10;
    res += '  '#10;
    res += '  '#10;
    foreach var api in Feature.ByApi.Keys do
    begin
      // func - addition version
      var all_funcs := new Dictionary<Func, string>;
      // func - deprecation version
      var deprecated := new Dictionary<Func, string>;
      
      foreach var ftr in Feature.ByApi[api].AsEnumerable.Reverse do
      begin
        foreach var f in ftr.rem do
          if not all_funcs.Remove(f) then // glGetPointerv было добавлено, убрано и ещё раз добавлено
            deprecated.Add(f, ftr.version);
        foreach var f in ftr.add do
          if all_funcs.ContainsKey(f) then
            Otp($'WARNING: Func [{f.name}] was added in versions [{all_funcs[f]}] and [{ftr.version}]') else
            all_funcs[f] := ftr.version;
      end;
      
      res += $'  {api} = sealed class'+#10;
      if api='gl' then AddGetFPtr(res);
      res += $'    '+#10;
      
      foreach var f in all_funcs.Keys.Where(f->not deprecated.ContainsKey(f)).OrderBy(f->f.name) do
      begin
        res += $'    // added in {api}{all_funcs[f]}'+#10;
        f.Write(res, api, all_funcs[f]);
      end;
      
      res += $'  end;'+#10;
      res += $'  '+#10;
      
      if not deprecated.Any then continue;
      res += $'  {api}D = sealed class'+#10;
      if api='gl' then AddGetFPtr(res);
      res += $'    '+#10;
      
      foreach var f in all_funcs.Keys.Where(f->deprecated.ContainsKey(f)).OrderBy(f->f.name) do
      begin
        res += $'    // added in {api}{all_funcs[f]}, deprecated in {api}{deprecated[f]}'+#10;
        f.Write(res, api, all_funcs[f]);
      end;
      
      res += $'  end;'+#10;
      res += $'  '+#10;
    end;
    res += '  '#10;
    res += '  ';
    
    var ToDo := 0; //ToDo extensions
    
    GroupFixer.WarnAllUnused;
    FuncOrgParam.WarnUnusedTypeTable;
    FuncFixer.WarnAllUnused;
    
    loop 1 do func_ovrs_log.WriteLine;
    
    log.Close;
    func_ovrs_log.Close;
    WriteAllText(GetFullPath('..\Funcs.template', GetEXEFileName), res.ToString);
    if CommandLineArgs.Contains('SecondaryProc') then ReadString('done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.