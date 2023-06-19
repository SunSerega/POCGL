unit TypeRefering;

interface

uses System;

uses '..\..\..\DataScraping\BinCommon';
uses BinUtils;
uses ItemNames;

uses NamedItemHelpers;
uses NamedItemBase;

type
  
  FuncParamTypeOrder = (
    FPTO_Group,
    FPTO_IdClass,
    FPTO_Struct,
    FPTO_Delegate,
    FPTO_Combo,
    FPTO_Basic
  );
  
  IDirectNamedType = interface(IWritableNamedItem)
    
    function IsInternalOnly: boolean;
    
    function GetTypeOrder: FuncParamTypeOrder;
    
    function GetRawName: object;
    
    function MakeWriteableName: string;
    
  end;
  
  ILoadedNamedType = interface(INamedItem)
    
    function IsVoid: boolean;
    
    function FeedToTypeTable: System.ValueTuple<integer, array of integer, IDirectNamedType>;
    
  end;
  
  {$region TypeLookup}
  
  TypeLookup = static class
    
    private static deref_funcs := new Dictionary<TypeRefKind, integer->ILoadedNamedType>;
    public static procedure RegisterIndexDerefFunc<T>(kind: TypeRefKind; f: integer->T); where T: ILoadedNamedType;
    begin
      deref_funcs.Add(kind, Func&<integer, ILoadedNamedType>(f as object));
    end;
    public static function FromIndex(kind: TypeRefKind; ind: integer) := deref_funcs[kind](ind);
    
    public static procedure RegisterNameLookupFunc<TName>(f: TName->IDirectNamedType);
    public static function FromName<TName>(name: TName): IDirectNamedType;
    public static function FromNameString(name_str: string): IDirectNamedType;
    
  end;
  
  {$endregion TypeLookup}
  
  {$region KnownDirectTypes}
  
  KnownDirectTypes = static class
    
    public static Void :=     TypeLookup.FromName('void');
    public static NtvChar :=  TypeLookup.FromName('ntv_char');
    
    public static Byte :=     TypeLookup.FromName('Byte');
    public static UInt32 :=   TypeLookup.FromName('UInt32');
    public static Pointer :=  TypeLookup.FromName('pointer');
    public static IntPtr :=   TypeLookup.FromName('IntPtr');
    public static UIntPtr :=  TypeLookup.FromName('UIntPtr');
    public static String :=   TypeLookup.FromName('string');
    
    public static StubForGenericT := KnownDirectTypes.Byte;
    public static EnumToTypeDataCountT := KnownDirectTypes.UInt32;
    
    static constructor :=
      foreach var field in typeof(KnownDirectTypes).GetFields do
        IDirectNamedType(field.GetValue(nil)).MarkReferenced;
    
  end;
  
  {$endregion KnownDirectTypes}
  
  {$region TypeIndex}
  
  TypeIndex = sealed class
    private kind: TypeRefKind;
    private ind: integer;
    
    public constructor(br: BinReader);
    begin
      self.kind := br.ReadEnum&<TypeRefKind>;
      self.ind := br.ReadInt32;
    end;
    private constructor := raise new InvalidOperationException;
    
    public function Dereference := TypeLookup.FromIndex(self.kind, self.ind);
    
  end;
  
  {$endregion TypeIndex}
  
  {$region TypeRefOrIndex}
  
  TypeRefOrIndex = record
    private as_ind := default(TypeIndex);
    private as_ref := default(IDirectNamedType);
    
    public constructor(t: TypeIndex) := self.as_ind := t;
    public static function FromBR(br: BinReader) :=
      new TypeRefOrIndex(new TypeIndex(br));
    
    public constructor(t: IDirectNamedType) := self.as_ref := t;
    
    ///--
    public constructor := exit;
    
    public function IsVoid: boolean;
    begin
      if as_ref<>nil then
        Result := as_ref.MakeWriteableName='void' else
      if as_ind<>nil then
        Result := as_ind.Dereference.IsVoid else
        raise new InvalidOperationException;
    end;
    
    public function MakeSureTypeIsDirect(var ptr: integer; var readonly_lvls: array of integer): IDirectNamedType;
    begin
      Result := self.as_ref;
      if Result <> nil then exit;
      if as_ind=nil then
        raise new NullReferenceException($'Uninited type ref');
      
      var lt := as_ind.Dereference;
      if lt=nil then
        raise new InvalidOperationException(as_ind.ToString);
      var (d_ptr, additional_readonly_lvls, direct_t) := lt.FeedToTypeTable;
      
      var old_ptr := ptr;
      ptr += d_ptr;
      
      if ptr <> 0 then
      begin
        if direct_t=KnownDirectTypes.Void then
        begin
          direct_t := KnownDirectTypes.IntPtr;
          ptr -= 1;
        end else
        if direct_t=KnownDirectTypes.NtvChar then
        begin
          direct_t := KnownDirectTypes.String;
          ptr -= 1;
        end;
      end;
      
      if (d_ptr>0) <> (additional_readonly_lvls<>nil) then
        raise new InvalidOperationException;
      if d_ptr>0 then
      begin
        if additional_readonly_lvls.Length<>0 then
          readonly_lvls := additional_readonly_lvls.ConvertAll(lvl->lvl+old_ptr) + readonly_lvls;
      end else
      begin
        // No, these lvls are still useful
        // "const void *" => "IntPtr" needs to somehow
        // keep info about pointing to const memory
//        var n_readonly_lvls := new List<integer>(readonly_lvls.Length);
//        foreach var lvl in readonly_lvls do
//          {if lvl<=ptr then }n_readonly_lvls += lvl;
//        if n_readonly_lvls.Count<>readonly_lvls.Length then
//          readonly_lvls := n_readonly_lvls.ToArray;
      end;
      
      if ptr<0 then
        raise new InvalidOperationException;
      
      Result := direct_t;
      self.as_ref := direct_t;
    end;
    
    public property WriteableName: string read as_ref.MakeWriteableName;
    
  end;
  
  {$endregion TypeRefOrIndex}
  
  {$region EnumToTypeBindingInfo}
  
  EnumToTypeBindingInfo = sealed class
    public passed_size_par_ind: integer;
    public data_par_ind: integer;
    public returned_size_par_ind: integer?; // nil if input data
    
    public constructor(passed_size_par_ind: integer; data_par_ind: integer; returned_size_par_ind: integer?);
    begin
      self.passed_size_par_ind := passed_size_par_ind;
      self.data_par_ind := data_par_ind;
      self.returned_size_par_ind := returned_size_par_ind;
    end;
    private constructor := raise new InvalidOperationException;
    
    public property IsInputData: boolean read returned_size_par_ind=nil;
    
  end;
  
  {$endregion EnumToTypeBindingInfo}
  
implementation

uses LLPackingUtils;

type
  TypeNameLookupHelper<TName> = sealed class
    
    private constructor := raise new InvalidOperationException;
    
    public static funcs := new List<TName->IDirectNamedType>;
    
  end;
  
static procedure TypeLookup.RegisterNameLookupFunc<TName>(f: TName->IDirectNamedType) :=
  TypeNameLookupHelper&<TName>.funcs += f;

static function TypeLookup.FromName<TName>(name: TName): IDirectNamedType;
begin
  var lookup_funcs := TypeNameLookupHelper&<TName>.funcs;
  
  var res := new List<IDirectNamedType>(lookup_funcs.Count);
  foreach var f in lookup_funcs do
  begin
    var t := f(name);
    if t=nil then continue;
    res += t;
  end;
  
  case res.Count of
    0: raise new ArgumentException($'{name} was not found');
    1: Result := res.Single;
    else raise new InvalidOperationException;
  end;
  
end;

static function TypeLookup.FromNameString(name_str: string) :=
  if '::' in name_str then
    FromName(ApiVendorLName.Parse(name_str)) else
  if name_str.StartsWith('Vec') then
    FromName(TypeComboName.ParseVector(name_str)) else
    FromName(name_str);

end.