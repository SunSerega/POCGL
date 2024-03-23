unit ParData;

interface

uses System;

uses '../../../DataScraping/BinCommon';

uses BinUtils;
uses LLPackingUtils;

uses TypeRefering;
uses FuncHelpers;

type
  
  {$region ParArrSize}
  
  ParArrSize = abstract class(MutiKindItem<ParArrSize, ParArrSizeKind>)
    
  end;
  
  [PCUAlwaysRestore]
  ParArrSizeNotArray = sealed class(ParArrSize)
    
    private constructor := exit;
    private static inst := new ParArrSizeNotArray;
    public static property Instance: ParArrSizeNotArray read inst;
    
    //TODO #3063: use Instance
    static constructor := DefineLoader(PASK_NotArray, br->inst);
    
  end;
  
  [PCUAlwaysRestore]
  ParArrSizeArbitrary = sealed class(ParArrSize)
    
    private constructor := exit;
    private static inst := new ParArrSizeArbitrary;
    public static property Instance: ParArrSizeArbitrary read inst;
    
    //TODO #3063: use Instance
    static constructor := DefineLoader(PASK_Arbitrary, br->inst);
    
  end;
  
  [PCUAlwaysRestore]
  ParArrSizeConst = sealed class(ParArrSize)
    
    private sz: integer;
    private constructor(sz: integer) := self.sz := sz;
    private constructor := raise new InvalidOperationException;
    static constructor := DefineLoader(PASK_Const,
      br->new ParArrSizeConst(br.ReadInt32)
    );
    
    public property Value: integer read sz;
    
  end;
  
  [PCUAlwaysRestore]
  ParArrSizeParRef = sealed class(ParArrSize)
    
    private ind: integer;
    private constructor(ind: integer) := self.ind := ind;
    private constructor := raise new InvalidOperationException;
    static constructor := DefineLoader(PASK_ParRef,
      br->new ParArrSizeParRef(br.ReadInt32)
    );
    
    public property Index: integer read ind;
    
  end;
  
  [PCUAlwaysRestore]
  ParArrSizeMlt = sealed class(ParArrSize)
    
    private sub_sizes: array of ParArrSize;
    private constructor(sub_sizes: array of ParArrSize) := self.sub_sizes := sub_sizes;
    private constructor := raise new InvalidOperationException;
    static constructor := DefineLoader(PASK_Mlt,
      br->new ParArrSizeMlt(br.ReadArr(ParArrSize.Load))
    );
    
    public function SubSizes := sub_sizes;
    
  end;
  
  [PCUAlwaysRestore]
  ParArrSizeDiv = sealed class(ParArrSize)
    
    private n, d: ParArrSize;
    private constructor(n, d: ParArrSize);
    begin
      self.n := n;
      self.d := d;
    end;
    private constructor := raise new InvalidOperationException;
    static constructor := DefineLoader(PASK_Div,
      br->new ParArrSizeDiv(ParArrSize.Load(br), ParArrSize.Load(br))
    );
    
    public property Numerator: ParArrSize read n;
    public property Denominator: ParArrSize read d;
    
  end;
  
  {$endregion ParArrSize}
  
  {$region ParValCombo}
  
  ParValCombo = abstract class(MutiKindItem<ParValCombo, ParValComboKind>)
    
  end;
  
  [PCUAlwaysRestore]
  ParValComboVector = sealed class(ParValCombo)
    
    private sz: integer;
    public constructor(sz: integer) := self.sz := sz;
    private constructor := raise new InvalidOperationException;
    static constructor := DefineLoader(PVCK_Vector,
      br->new ParValComboVector(br.ReadInt32)
    );
    
    public property Size: integer read sz;
    
  end;
  
  [PCUAlwaysRestore]
  ParValComboMatrix = sealed class(ParValCombo)
    
    private sz1, sz2: integer;
    public constructor(sz1, sz2: integer);
    begin
      self.sz1 := sz1;
      self.sz2 := sz2;
    end;
    private constructor := raise new InvalidOperationException;
    static constructor := DefineLoader(PVCK_Matrix,
      br->new ParValComboMatrix(br.ReadInt32, br.ReadInt32)
    );
    
    public property Size1: integer read sz1;
    public property Size2: integer read sz2;
    
  end;
  
  {$endregion ParValCombo}
  
  {$region LoadedParData}
  
  LoadedParData = record
    private _name := default(string);
    private raw_t: TypeRefOrIndex;
    
    // "const int * * const * v"
    // ptr = 3
    // Levels right to left: 1 and 3 are readonly, 0 and 2 are not
    private raw_ptr: integer;
    private raw_readonly_lvls: array of integer;
    
    // Apply to last ptr lvl, if not ParArrSizeNotArray
    private arr_size: ParArrSize;
    
    private val_combo: ParValCombo;
    
    public constructor(name: string; t: IDirectNamedType; arr_size: ParArrSize);
    begin
      self._name := name;
      self.raw_t := new TypeRefOrIndex(t);
      
      self.raw_ptr := 0;
      self.raw_readonly_lvls := System.Array.Empty&<integer>;
      
      self.arr_size := arr_size;
      
      self.val_combo := nil;
      
    end;
    public constructor := exit;
    
    public static function Load(br: BinReader; expect_name: boolean?): LoadedParData;
    begin
      
      if expect_name=nil then
        expect_name := br.ReadBoolean;
      Result._name := if expect_name.Value then
        br.ReadString else nil;
      Result.raw_t := TypeRefOrIndex.FromBR(br);
      
      Result.raw_ptr := br.ReadInt32;
      Result.raw_readonly_lvls := br.ReadInt32Arr;
      
      Result.arr_size := ParArrSize.Load(br);
      
      Result.val_combo := if br.ReadBoolean then
        ParValCombo.Load(br) else nil;
      
    end;
    
    private function UnwrapT<T>(make_res: LoadedParData->T): T;
    begin
      raw_t.MakeSureTypeIsDirect(self.raw_ptr, self.raw_readonly_lvls);
      Result := make_res(self);
    end;
    
    public property Name: string read _name;
    
    public property CalculatedDirectType: IDirectNamedType read raw_t.MakeSureTypeIsDirect(self.raw_ptr, self.raw_readonly_lvls);
    public property CalculatedPtr: integer read UnwrapT(p->p.raw_ptr);
    public property CalculatedReadonlyLvls: array of integer read UnwrapT(p->p.raw_readonly_lvls);
    
    public property ArrSize: ParArrSize read arr_size;
    public property ValCombo: ParValCombo read val_combo;
    
    public function IsNakedVoid: boolean;
    begin
      Result := false;
      if not raw_t.IsVoid then exit;
      if raw_ptr<>0 then exit;
      Result := true;
    end;
    
    public function MakePPT(context_descr: ()->string; is_res_par, is_enum_to_type_data: boolean): List<FuncParamT>;
    
    public procedure MarkReferenced := CalculatedDirectType.Use(false);
    
    public function ToString(expect_name: boolean?): string;
    begin
      var sb := new StringBuilder;
      
      if expect_name = (self.name=nil) then
        raise new InvalidOperationException;
      
      if self.name<>nil then
      begin
        sb += self.name;
        sb += ': ';
      end;
      
      var ptr_prefix := 'array of ';
      var static_len := default(string);
      
      match self.ArrSize with
        
        ParArrSizeNotArray(var pasna): ptr_prefix := '^';
        
        ParArrSizeArbitrary(var pasa): ;
        
        ParArrSizeConst(var pasc): static_len := pasc.Value.ToString;
        
        ParArrSizeParRef(var paspr): static_len := '%par_ref%';
        ParArrSizeMlt(var pasm): static_len := '%mlt%';
        ParArrSizeDiv(var pasd): static_len := '%div%';
        
        else raise new NotImplementedException(_ObjectToString(ArrSize));
      end;
      
      var ptr := self.CalculatedPtr;
      if ptr<>0 then
      begin
        if static_len<>nil then
        begin
          sb += 'array[';
          sb += static_len;
          sb += '] of ';
          static_len := nil;
          ptr -= 1;
        end;
        loop ptr do sb += ptr_prefix;
      end;
      
      sb += self.CalculatedDirectType.MakeWriteableName;
      if static_len<>nil then
      begin
        sb += '[';
        sb += static_len;
        sb += ']';
        static_len := nil;
      end;
      
      Result := sb.ToString;
    end;
    public function ToString: string; override := ToString(nil);
    
  end;
  
  {$endregion LoadedParData}
  
implementation

uses '../../../POCGL_Utils';

uses ItemNames;

type KDT = KnownDirectTypes;

function LoadedParData.MakePPT(context_descr: ()->string; is_res_par, is_enum_to_type_data: boolean): List<FuncParamT>;
begin
  var ptr := self.CalculatedPtr;
  var ro_lvls := self.CalculatedReadonlyLvls;
  var raw_t := self.CalculatedDirectType;
  if raw_t.IsInternalOnly then
    raise new InvalidOperationException($'{context_descr}: {raw_t.GetRawName}');
  var tname := raw_t.MakeWriteableName;
  
  var is_string := raw_t=KDT.String;
  
  var is_const :=
    if raw_t=KDT.IntPtr then
      ((ptr in ro_lvls) or (ptr+1 in ro_lvls)) else
    if is_string then
      (ptr+1 in ro_lvls) else
      (ptr in ro_lvls);
  
  // Both cases exist... First in OpenGL (glGetUniformIndices), second in OpenCL (clCompileProgram)
//  if ro_lvls.Length <> Ord(is_const) then
//    raise new NotImplementedException;
//  if is_const and (1..ro_lvls.Max).Any(lvl->lvl not in ro_lvls) then
//    raise new InvalidOperationException;
  
  if (ptr=0) and not is_string then
  begin
    Result := Lst(new FuncParamT(is_const, false, 0, tname, raw_t));
    exit;
  end;
  
  if is_res_par then
  begin
    if (ptr<>0) and is_string then
      raise new MessageException($'ERROR: {context_descr()} returns pointer to string');
    if ptr<>0 then
    begin
      log.Otp($'{context_descr()} returns pointer');
      tname := '^'*ptr + tname;
    end;
    Result := Lst(new FuncParamT(is_const, false, 0, tname, raw_t));
    exit;
  end;
  
  var org_tname := tname;
  
  var need_var := ptr<>0;
  var need_arr := need_var and (tname<>'boolean');
  var need_plain := if is_string then ((ptr+1) in ro_lvls) or (ptr<>0) else true;
  var need_str_ptr := not is_res_par and is_string;
  var skip_last_arr := need_arr and ( (ptr>1) or is_string );
  var cap := ord(need_str_ptr) + ptr*ord(need_arr) + ord(self.val_combo<>nil) + ord(need_var) + Ord(need_plain) - ord(skip_last_arr);
  Result := new List<FuncParamT>(cap);
  
  if need_str_ptr and (ptr<>0) then
  begin
    Result += new FuncParamT(is_const, false, ptr, KDT.String);
    raw_t := KDT.IntPtr;
    tname := raw_t.MakeWriteableName;
  end;
  
  if need_arr then for var i := ptr downto 1 do
  begin
    if (i=1) and (tname<>org_tname) then break;
    Result += new FuncParamT(is_const, false, i, tname, raw_t);
    if i>1 then
    begin
      raw_t := KDT.IntPtr;
      tname := raw_t.MakeWriteableName;
    end;
  end;
  
  if self.val_combo<>nil then
  begin
    if ptr<>1 then raise new System.InvalidOperationException;
    
    var tcn: TypeComboName;
    match self.val_combo with
      
      ParValComboVector(var pvcv):
        tcn := TypeComboName.Vector(org_tname, pvcv.Size);
      
      ParValComboMatrix(var pvcm):
        tcn := TypeComboName.Matrix(org_tname, pvcm.Size1, pvcm.Size2);
      
      else raise new NotSupportedException(TypeName(self.val_combo));
    end;
    
    Result += new FuncParamT(is_const, true, 0, TypeLookup.FromName(tcn));
  end;
  
  if ptr>0 then
  begin
    var par := new FuncParamT(is_const, true, 0, tname, raw_t);
    Result += par;
    raw_t := if is_enum_to_type_data or par.IsGeneric or (raw_t=KnownDirectTypes.IntPtr) then KDT.Pointer else KDT.IntPtr;
    tname := raw_t.MakeWriteableName;
  end;
  
  if need_plain then
    Result += new FuncParamT(is_const, false, 0, tname, raw_t);
  
  if need_str_ptr and (ptr=0) then
    Result += new FuncParamT(is_const, false, 0, KDT.IntPtr);
  
  if Result.Count<>cap then
    raise new System.InvalidOperationException($'{context_descr()}');
end;

end.