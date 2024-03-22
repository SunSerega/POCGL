unit XMLItems;

uses System;

uses '../../POCGL_Utils';

uses '../BinCommon';

uses ScrapUtils;
uses NamedItems;

type
  
  {$region VendorSuffix}
  
  VendorSuffix = sealed class(NamedItem<VendorSuffix, string>)
    
    static constructor;
    begin
      can_be_alias := nil;
      perform_merge := false;
    end;
    
    public constructor(name: string) :=
      inherited Create(name, nil);
    
    public static function operator implicit(vs: string): VendorSuffix :=
      VendorSuffix[vs];
    
    protected procedure SaveName(bw: BinWriter); override := bw.Write(self.Name);
    protected procedure SaveBody(bw: BinWriter); override := exit;
    
  end;
  
  {$endregion VendorSuffix}
  
  {$region Enum}
  
  EnumName = sealed class(ApiVendorLName<EnumName>, IBinSavable)
    
    public procedure Save(bw: BinWriter) :=
      inherited Save(bw, nil);
    
  end;
  
  Enum = sealed class(NamedItem<Enum, EnumName>, IComparable<Enum>)
    private val: int64;
    // Used from "constants" or "OpenCL-C only" group
    private explicitly_ungrouped: boolean;
    
    static constructor;
    begin
      can_be_alias := (e1,e2, l_otp) -> e1.val = e2.val;
      perform_merge := true;
      copy_without_suffix := (api, lname, sample)->new Enum(new EnumName(api,nil,lname), sample.val, false);
    end;
    
    public constructor(name: EnumName; val: int64; explicitly_ungrouped: boolean);
    begin
      inherited Create(name, nil);
      self.val := val;
      self.explicitly_ungrouped := explicitly_ungrouped;
    end;
    private constructor := raise new InvalidOperationException;
    public property Value: int64 read val;
    
    function IComparable<Enum>.CompareTo(other: Enum) := self.val.CompareTo(other.val);
    
    protected function NameWithoutSuffix: EnumName; override :=
      new EnumName(NameApi, nil, NameLocal);
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      bw.Write(val);
      bw.Write(explicitly_ungrouped);
    end;
    
  end;
  
  {$endregion Enum}
  
  {$region TypeRef}
  
  ITypeItem = interface(IBinIndexable)
    
  end;
  
  TypeRef = sealed class(IEquatable<TypeRef>)
    private kind := TRK_Invalid;
    private o: ITypeItem;
    
    public constructor(o: ITypeItem);
    begin
      self.o := o;
      case o.GetType.Name of
        'BasicType':  self.kind := TRK_Basic;
        'Group':      self.kind := TRK_Group;
        'IdClass':    self.kind := TRK_IdClass;
        'Struct':     self.kind := TRK_Struct;
        'Delegate':   self.kind := TRK_Delegate;
        else raise new NotImplementedException(o.GetType.Name);
      end;
    end;
    
    public property TypeObj: ITypeItem read o;
    
    public function Equals(other: TypeRef): boolean :=
      ReferenceEquals(self.o, other?.o);
    public static function operator=(t1,t2: TypeRef) :=
      ReferenceEquals(t1,t2) or (
        not ReferenceEquals(t1, nil)
        and t1.Equals(t2)
      );
    public static function operator<>(t1,t2: TypeRef) := not(t1=t2);
    public function Equals(obj: object): boolean; override :=
      (obj is TypeRef(var other)) and (self=other);
    
    public procedure Save(bw: BinWriter);
    begin
      if kind=TRK_Invalid then
        raise new InvalidOperationException;
      bw.Write(Convert.ToInt32(kind));
      bw.Write(o.BinIndex);
    end;
    
  end;
  
  {$endregion TypeRef}
  
  {$region ParArrSize}
  
  ParArrSize = abstract class(MultiKindItem<ParArrSizeKind>)
    
    public procedure SaveHead(bw: BinWriter); override := exit;
    
  end;
  
  ParArrSizeNotArray = sealed class(ParArrSize)
    
    private constructor := exit;
    private static inst := new ParArrSizeNotArray;
    public static property Instance: ParArrSizeNotArray read inst;
    
    protected function GetKind: ParArrSizeKind; override := PASK_NotArray;
    
    public function EqualsMKI(mki: MultiKindItem<ParArrSizeKind>; l_otp: OtpLine->()): boolean; override;
    begin
      Result := ReferenceEquals(mki, Instance);
      {$ifdef DEBUG}
      if Result <> (mki is ParArrSizeNotArray) then
        raise new InvalidOperationException
      {$endif DEBUG}
    end;
    
    protected procedure SaveBody(bw: BinWriter); override := exit;
    
  end;
  
  ParArrSizeArbitrary = sealed class(ParArrSize)
    
    private constructor := exit;
    private static inst := new ParArrSizeArbitrary;
    public static property Instance: ParArrSizeArbitrary read inst;
    
    protected function GetKind: ParArrSizeKind; override := PASK_Arbitrary;
    
    public function EqualsMKI(mki: MultiKindItem<ParArrSizeKind>; l_otp: OtpLine->()): boolean; override;
    begin
      Result := ReferenceEquals(mki, Instance);
      {$ifdef DEBUG}
      if Result <> (mki is ParArrSizeArbitrary) then
        raise new InvalidOperationException
      {$endif DEBUG}
    end;
    
    protected procedure SaveBody(bw: BinWriter); override := exit;
    
  end;
  
  ParArrSizeConst = sealed class(ParArrSize)
    
    protected function GetKind: ParArrSizeKind; override := PASK_Const;
    
    private sz: integer;
    public constructor(sz: integer);
    begin
      // 1 is NotArray
      // Also not useful in Mlt and cannot be in Div
      // If Plus is added, move check for "sz=1" to ParData ctor
      if sz<=1 then raise new System.InvalidOperationException(sz.ToString);
      self.sz := sz;
    end;
    
    public property Value: integer read sz;
    
    public function EqualsMKI(mki: MultiKindItem<ParArrSizeKind>; l_otp: OtpLine->()): boolean; override :=
      (mki is ParArrSizeConst(var other)) and (self.Value = other.Value);
    
    protected procedure SaveBody(bw: BinWriter); override :=
      bw.Write(sz);
    
  end;
  
  ParArrSizeParRef = sealed class(ParArrSize)
    
    protected function GetKind: ParArrSizeKind; override := PASK_ParRef;
    
    private par_i: integer; // 0-based
    public constructor(par_i: integer);
    begin
      if par_i<0 then raise new System.InvalidOperationException;
      self.par_i := par_i;
    end;
    
    public property Index: integer read par_i;
    
    public function EqualsMKI(mki: MultiKindItem<ParArrSizeKind>; l_otp: OtpLine->()): boolean; override :=
      (mki is ParArrSizeParRef(var other)) and (self.Index = other.Index);
    
    protected procedure SaveBody(bw: BinWriter); override :=
      bw.Write(par_i);
    
  end;
  
  ParArrSizeMlt = sealed class(ParArrSize)
    
    protected function GetKind: ParArrSizeKind; override := PASK_Mlt;
    
    private sub_sizes: array of ParArrSize;
    public constructor(sub_sizes: array of ParArrSize) :=
      self.sub_sizes := sub_sizes;
    
    public property SubSizes: array of ParArrSize read sub_sizes;
    
    public function EqualsMKI(mki: MultiKindItem<ParArrSizeKind>; l_otp: OtpLine->()): boolean; override :=
      (mki is ParArrSizeMlt(var other)) and self.SubSizes.SequenceEqual(other.SubSizes);
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      bw.Write(sub_sizes.Length);
      foreach var sz in sub_sizes do
        sz.Save(bw);
    end;
    
  end;
  
  ParArrSizeDiv = sealed class(ParArrSize)
    
    protected function GetKind: ParArrSizeKind; override := PASK_Div;
    
    private n,d: ParArrSize;
    public constructor(n,d: ParArrSize);
    begin
      self.n := n;
      self.d := d;
    end;
    public constructor(sub_sizes: array of ParArrSize) :=
      Create(sub_sizes[0],
        if sub_sizes.Length=2 then
          sub_sizes[1] as ParArrSize else
          new ParArrSizeMlt(sub_sizes[1:])
      );
    
    public function EqualsMKI(mki: MultiKindItem<ParArrSizeKind>; l_otp: OtpLine->()): boolean; override :=
      (mki is ParArrSizeDiv(var other)) and (self.n = other.n) and (self.d = other.d);
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      n.Save(bw);
      d.Save(bw);
    end;
    
  end;
  
  {$endregion ParArrSize}
  
  {$region ParValCombo}
  
  ParValCombo = abstract class(MultiKindItem<ParValComboKind>)
    
    public property Size: integer read; abstract;
    
    public procedure SaveHead(bw: BinWriter); override := exit;
    
  end;
  
  ParValComboVector = sealed class(ParValCombo)
    
    private sz: integer;
    public constructor(sz: integer);
    begin
      self.sz := sz;
      if sz not in 1..5 then raise new ArgumentException;
    end;
    
    public property Size: integer read sz; override;
    
    protected function GetKind: ParValComboKind; override := PVCK_Vector;
    
    public function EqualsMKI(mki: MultiKindItem<ParValComboKind>; l_otp: OtpLine->()): boolean; override :=
      (mki is ParValComboVector(var other)) and (self.sz = other.sz);
    
    protected procedure SaveBody(bw: BinWriter); override :=
      bw.Write(sz);
    
  end;
  
  ParValComboMatrix = sealed class(ParValCombo)
    
    private sz1, sz2: integer;
//    public constructor(sz1, sz2: integer);
//    begin
//      self.sz1 := sz1;
//      self.sz2 := sz2;
//    end;
    public constructor(szs: array of integer);
    begin
      if szs.Length<>2 then raise new InvalidOperationException;
      (sz1,sz2) := szs;
      if szs.Any(sz->sz not in 2..4) then raise new ArgumentException;
    end;
    
    public property Size: integer read sz1*sz2; override;
    
    protected function GetKind: ParValComboKind; override := PVCK_Matrix;
    
    public function EqualsMKI(mki: MultiKindItem<ParValComboKind>; l_otp: OtpLine->()): boolean; override :=
      (mki is ParValComboMatrix(var other)) and (self.sz1 = other.sz1) and (self.sz2 = other.sz2);
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      bw.Write(sz1);
      bw.Write(sz2);
    end;
    
  end;
  
  {$endregion ParValCombo}
  
  {$region ParData}
  
  ParData = sealed class(IEquatable<ParData>)
    private name: string;
    private t: TypeRef;
    
    // "const int * * const * v"
    // ptr = 3
    // Levels right to left: 1 and 3 are readonly, 0 and 2 are not
    private ptr: integer;
    private readonly_lvls: array of integer;
    
    // Apply to last ptr lvl, if not ParArrSizeNotArray
    private arr_size: ParArrSize;
    
    private val_combo: ParValCombo;
    
    public static function ParsePtrLvls(text: string): ValueTuple<string, integer, array of integer>;
    const const_s = 'const';
    begin
      var flat_t := default(string);
      var ptr := text.CountOf('*');
      var readonly_lvls := new List<integer>(ptr);
      
      foreach var s in text.Split('*').Reverse index i do
      begin
        var wds := s.ToWords;
        
        if const_s in wds then
        begin
          if i=0 then
            log.Otp($'ParData with type [{text}]: const in lvl0');
          
          if wds.First = const_s then
            wds := wds.Skip(1).ToArray else
          if wds.Last = const_s then
            wds := wds.SkipLast(1).ToArray else
            raise new NotSupportedException;
          
          readonly_lvls += i;
          if const_s in wds then
            raise new FormatException(text);
        end;
        
        var last_par := i=ptr;
        if last_par <> wds.Any then
          raise new FormatException(text);
        if last_par then
        begin
          flat_t := wds.JoinToString;
          if s.Remove(const_s).Trim <> flat_t then
            raise new FormatException(text);
        end;
        
      end;
      
      if flat_t=nil then
        raise new InvalidOperationException(text);
      
      Result := ValueTuple.Create(flat_t, ptr, readonly_lvls.ToArray);
    end;
    
    public constructor(name: string; t: TypeRef; ptr: integer; readonly_lvls: array of integer; arr_size: ParArrSize; val_combo: ParValCombo);
    begin
      self.name := name;
      self.t := t;
      self.ptr := ptr;
      self.readonly_lvls := readonly_lvls;
      self.arr_size := arr_size;
      self.val_combo := val_combo;
      
      if t=nil then raise nil;
      if readonly_lvls=nil then raise nil;
      if arr_size=nil then raise nil;
      
      if ptr<0 then raise new InvalidOperationException;
      
    end;
    private constructor := raise new InvalidOperationException;
    
    public property ParName: string read name;
    public property ParType: TypeRef read t;
    public property PtrLvl: integer read ptr;
    public property ArrSize: ParArrSize read arr_size;
    public property ValCombo: ParValCombo read val_combo;
    
    public function Equals(other: ParData) :=
      (other<>nil) and
//      (self.name=other.name) and
      (self.t = other.t) and
      (self.ptr = other.ptr) and
      (self.readonly_lvls.SequenceEqual(other.readonly_lvls)) and
      (self.arr_size = other.arr_size) and
      (self.val_combo = other.val_combo);
    public static function operator=(p1,p2: ParData) :=
    ReferenceEquals(p1,p2) or (
      not ReferenceEquals(p1, nil)
      and p1.Equals(p2)
    );
    public static function operator<>(p1,p2: ParData) := not(p1=p2);
    public function Equals(obj: object): boolean; override :=
      (obj is ParData(var other)) and (self=other);
    
    public procedure Save(bw: BinWriter; save_name: boolean?);
    begin
      if save_name=nil then
        bw.WriteNullable(name, bw.Write) else
      if save_name.Value then
        bw.Write(name) else
      if name<>nil then
        raise new InvalidOperationException(name);
      t.Save(bw);
      
      bw.Write(ptr);
      bw.Write(readonly_lvls.Count);
      foreach var lvl in readonly_lvls do
        bw.Write(lvl);
      
      arr_size.Save(bw);
      
      bw.WriteNullable(val_combo, (bw,val_combo)->val_combo.Save(bw));
      
    end;
    
  end;
  
  {$endregion ParData}
  
  {$region BasicType}
  
  BasicType = sealed class(NamedItem<BasicType, string>, ITypeItem)
    
    static constructor;
    begin
      can_be_alias := nil;
      perform_merge := false;
    end;
    
    public constructor(name: string) :=
      inherited Create(name, nil);
    private constructor := raise new InvalidOperationException;
    
    protected procedure SaveName(bw: BinWriter); override := bw.Write(self.Name);
    protected procedure SaveBody(bw: BinWriter); override := exit;
    
  end;
  
  {$endregion BasicType}
  
  {$region EnumsInGroup}
  
  EnumsInGroup = abstract class(MultiKindItem<GroupKind>)
    
    public procedure SaveHead(bw: BinWriter); override := exit;
    
  end;
  
  SimpleEnumsInGroup = sealed class(EnumsInGroup)
    private can_combine: boolean;
    private enums: array of Enum;
    
    public constructor(can_combine: boolean; enums: array of Enum);
    begin
      self.can_combine := can_combine;
      self.enums := enums;
      
      if enums.Distinct.Count<>enums.Length then
        raise new InvalidOperationException;
      
    end;
    
    protected function GetKind: GroupKind; override :=
      if can_combine then
        GK_Bitfield else
        GK_Enum;
    
    private function UniqueEnums := Enum.DistillAllUnique(self.enums);
    
    public function EqualsMKI(mki: MultiKindItem<GroupKind>; l_otp: OtpLine->()): boolean; override;
    begin
      Result := false;
      var other := mki as SimpleEnumsInGroup;
      if other=nil then
      begin
        l_otp($'Different etype: {TypeName(self)} vs {TypeName(mki)}');
        exit;
      end;
      if self.can_combine <> other.can_combine then
      begin
        l_otp($'Different can_combine: {self.can_combine} vs {other.can_combine}');
        exit;
      end;
      
      var enums := self.enums.Concat(other.enums).Select(e->e.AfterMerges).Distinct.ToArray;
      Result := enums.Length < self.enums.Length+other.enums.Length;
      if not Result then
      begin
        l_otp($'No enums in common');
        exit;
      end;
      
      self.enums := enums;
      other.enums := enums;
    end;
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      bw.WriteBinIndexArr( self.UniqueEnums );
    end;
    
  end;
  
  EnumWithObjInfo = record
    public e: Enum;
    public inp_t, otp_t: ParData;
    
    public constructor(e: Enum; inp_t, otp_t: ParData);
    begin
      self.e := e;
      self.inp_t := inp_t;
      self.otp_t := otp_t;
    end;
    
    public procedure Save(bw: BinWriter);
    begin
      bw.Write(e.BinIndex);
      bw.WriteNullable(inp_t, (bw,inp_t)->inp_t.Save(bw, false));
      bw.WriteNullable(otp_t, (bw,otp_t)->otp_t.Save(bw, false));
    end;
    
  end;
  ObjInfoEnumsInGroup = sealed class(EnumsInGroup)
    private enums: array of EnumWithObjInfo;
    
    protected function GetKind: GroupKind; override := GK_ObjInfo;
    
    public constructor(enums: array of EnumWithObjInfo);
    begin
      self.enums := enums;
      
      if enums.Select(r->r.e).Distinct.Count<>enums.Length then
        raise new InvalidOperationException;
      
    end;
    
    public function EqualsMKI(mki: MultiKindItem<GroupKind>; l_otp: OtpLine->()): boolean; override;
    begin
      Result := false;
      var other := mki as ObjInfoEnumsInGroup;
      if other=nil then
      begin
        l_otp($'Different etype: {TypeName(self)} vs {TypeName(mki)}');
        exit;
      end;
      
      Result := self.enums.Select(r->r.e.AfterMerges).Intersect(other.enums.Select(r->r.e.AfterMerges)).Any;
      if not Result then
      begin
        l_otp($'No enums in common');
        exit;
      end;
      
      var enums := new Dictionary<Enum, EnumWithObjInfo>(self.enums.Length+other.enums.Length);
      foreach var ewoi in self.enums.Concat(other.enums) do
      begin
        ewoi.e := ewoi.e.AfterMerges;
        var old_ewoi: EnumWithObjInfo;
        if enums.TryGetValue(ewoi.e, old_ewoi) then
        begin
          if ewoi <> old_ewoi then
            raise new InvalidOperationException(ewoi.e.ToString);
        end else
          enums.Add(ewoi.e, ewoi);
      end;
      
      self.enums := enums.Values.ToArray;
      other.enums := self.enums;
    end;
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      var enums := Enum.DistillAllUnique(self.enums, r->r.e, (r1,r2)->
      begin
        if r1.inp_t <> r2.inp_t then
          raise new InvalidOperationException($'{r1.e}: {r1.inp_t} | {r2.e}: {r2.inp_t}');
        if r1.otp_t <> r2.otp_t then
          raise new InvalidOperationException($'{r1.e}: {r1.otp_t} | {r2.e}: {r2.otp_t}');
      end);
      bw.Write(enums.Count);
      foreach var r in enums.OrderBy(r->r.e) do
        r.Save(bw);
    end;
    
  end;
  
  EnumWithPropList = record
    private e: Enum;
    public prop_t: ParData;
    public list_end: Enum; // if nil then not a list (single value)
    
    public constructor(e: Enum; prop_t: ParData; list_end: Enum);
    begin
      self.e := e;
      self.prop_t := prop_t;
      self.list_end := list_end;
    end;
    
    public procedure Save(bw: BinWriter);
    begin
      bw.Write(e.BinIndex);
      prop_t.Save(bw, false);
      bw.WriteBinIndexOrNil(list_end);
    end;
    
  end;
  PropListEnumsInGroup = sealed class(EnumsInGroup)
    private enums: array of EnumWithPropList;
    private global_list_ends: array of Enum;
    
    protected function GetKind: GroupKind; override := GK_PropList;
    
    public constructor(enums: array of EnumWithPropList; global_list_ends: array of Enum);
    begin
      self.enums := enums;
      self.global_list_ends := global_list_ends;
      
      var total_enums := new HashSet<Enum>;
      
      foreach var r in enums do
      begin
        if not total_enums.Add(r.e) then
          raise new InvalidOperationException;
        if (r.list_end<>nil) and not total_enums.Add(r.list_end) then
          raise new InvalidOperationException;
      end;
      
      foreach var e in global_list_ends do
        if not total_enums.Add(e) then
          raise new InvalidOperationException;
      
    end;
    
    public function EqualsMKI(mki: MultiKindItem<GroupKind>; l_otp: OtpLine->()): boolean; override;
    begin
      Result := false;
      var other := mki as PropListEnumsInGroup;
      if other=nil then
      begin
        l_otp($'Different etype: {TypeName(self)} vs {TypeName(mki)}');
        exit;
      end;
      
      Result := self.enums.Select(r->r.e.AfterMerges).Intersect(other.enums.Select(r->r.e.AfterMerges)).Any;
      if not Result then
      begin
        l_otp($'No enums in common');
        exit;
      end;
      
      var enums := new Dictionary<Enum, EnumWithPropList>(self.enums.Length+other.enums.Length);
      foreach var ewpl in self.enums.Concat(other.enums) do
      begin
        ewpl.e := ewpl.e.AfterMerges;
        ewpl.list_end := ewpl.list_end?.AfterMerges;
        var old_ewpl: EnumWithPropList;
        if enums.TryGetValue(ewpl.e, old_ewpl) then
        begin
          if ewpl <> old_ewpl then
            raise new InvalidOperationException(ewpl.e.ToString);
        end else
          enums.Add(ewpl.e, ewpl);
      end;
      self.enums := enums.Values.ToArray;
      other.enums := self.enums;
      
      var global_list_ends := self.global_list_ends.Concat(other.global_list_ends).Distinct.ToArray;
      self.global_list_ends := global_list_ends;
      other.global_list_ends := global_list_ends;
      
    end;
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      var enums := Enum.DistillAllUnique(self.enums, r->r.e, (r1,r2)->
      begin
        if r1.prop_t <> r2.prop_t then
          raise new InvalidOperationException($'{r1.e}: {r1.prop_t} | {r2.e}: {r2.prop_t}');
        if r1.list_end <> r2.list_end then
          raise new InvalidOperationException($'{r1.e}: {r1.list_end} | {r2.e}: {r2.list_end}');
      end);
      bw.Write(enums.Count);
      foreach var r in enums.OrderBy(r->r.e) do
        r.Save(bw);
      bw.WriteBinIndexArr( Enum.DistillAllUnique(self.global_list_ends) );
    end;
    
  end;
  
  {$endregion EnumsInGroup}
  
  {$region Group}
  
  GroupName = sealed class(ApiVendorLName<GroupName>, IBinSavable)
    
    public procedure Save(bw: BinWriter) :=
      inherited Save(bw, nil);
    
  end;
  
  Group = sealed class(NamedItem<Group, GroupName>, ITypeItem)
    private castable_to: array of BasicType;
    private enums: EnumsInGroup;
    
    static constructor;
    begin
      can_be_alias := (g1,g2,l_otp)->
      begin
        
        var castable_to := g1.castable_to.Concat(g2.castable_to).Select(bt->bt.AfterMerges).Distinct.ToArray;
        Result := castable_to.Length < g1.castable_to.Length+g2.castable_to.Length;
        if not Result then
        begin
          l_otp($'No castable_to in common: {_ObjectToString(g1.castable_to)} vs {_ObjectToString(g2.castable_to)}');
          exit;
        end;
        
        Result := g1.enums.EqualsMKI(g2.enums, l_otp);
        if not Result then exit;
        
        g1.castable_to := castable_to;
        g2.castable_to := castable_to;
      end;
      perform_merge := true;
      copy_without_suffix := nil;
    end;
    
    public constructor(name: GroupName; castable_to: array of BasicType; enums: EnumsInGroup);
    begin
      inherited Create(name, nil);
      self.castable_to := castable_to;
      self.enums := enums;
    end;
    private constructor := raise new InvalidOperationException;
    
    protected function NameWithoutSuffix: GroupName; override :=
      new GroupName(NameApi, nil, NameLocal);
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      bw.WriteBinIndexArr( BasicType.DistillAllUnique(self.castable_to) );
      enums.Save(bw);
    end;
    
  end;
  
  {$endregion Group}
  
  {$region IdClass}
  
  IdClassName = sealed class(ApiVendorLName<IdClassName>, IBinSavable)
    
    public procedure Save(bw: BinWriter) :=
      inherited Save(bw, nil);
    
  end;
  
  IdClass = sealed class(NamedItem<IdClass, IdClassName>, ITypeItem)
    private castable_to: array of BasicType;
    
    static constructor;
    begin
      can_be_alias := (cl1,cl2,l_otp)->
      begin
        Result := true;
        var castable_to := cl1.castable_to.Concat(cl2.castable_to).Distinct.ToArray;
        cl1.castable_to := castable_to;
        cl2.castable_to := castable_to;
      end;
      perform_merge := true;
      copy_without_suffix := (api,lname,sample)->new IdClass(new IdClassName(api, nil, lname), sample.castable_to);
    end;
    
    public constructor(name: IdClassName; castable_to: array of BasicType);
    begin
      inherited Create(name, nil);
      self.castable_to := castable_to;
      
      if castable_to.Any(t->t=nil) then
        raise nil;
      
    end;
    private constructor := raise new InvalidOperationException;
    
    protected function NameWithoutSuffix: IdClassName; override :=
      new IdClassName(NameApi, nil, NameLocal);
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      bw.WriteBinIndexArr( BasicType.DistillAllUnique(self.castable_to) );
    end;
    
  end;
  
  {$endregion IdClass}
  
  {$region Struct}
  
  StructName = sealed class(ApiVendorLName<StructName>, IBinSavable)
    
    public procedure Save(bw: BinWriter) :=
      inherited Save(bw, nil);
    
  end;
  
  Struct = sealed class(NamedItem<Struct, StructName>, ITypeItem)
    private fields: array of ParData;
    
    static constructor;
    begin
      can_be_alias := (s1,s2,l_otp)->
      begin
        Result := true;
        
        if s1.fields.Length <> s2.fields.Length then
        begin
          Result := false;
          l_otp($'Different field count: {s1.fields.Length} vs {s2.fields.Length}');
        end;
        if not Result then exit;
        
        for var i := 0 to s1.fields.Length-1 do
          if s1.fields[i] <> s2.fields[i] then
          begin
            Result := false;
            l_otp($'Different field#{i}');
          end;
        if not Result then exit;
        
      end;
      perform_merge := true;
      copy_without_suffix := (api,lname,sample)->new Struct(new StructName(api, nil, lname), sample.fields);
    end;
    
    public constructor(name: StructName; fields: array of ParData);
    begin
      inherited Create(name, nil);
      self.fields := fields;
    end;
    private constructor := raise new InvalidOperationException;
    
    protected function NameWithoutSuffix: StructName; override :=
      new StructName(NameApi, nil, NameLocal);
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      bw.Write(fields.Count);
      foreach var f in fields do
        f.Save(bw, true);
    end;
    
  end;
  
  {$endregion Struct}
  
  {$region Delegate}
  
  DelegateName = sealed class(ApiVendorLName<DelegateName>, IBinSavable)
    
    public procedure Save(bw: BinWriter) :=
      inherited Save(bw, nil);
    
  end;
  
  Delegate = sealed class(NamedItem<Delegate, DelegateName>, ITypeItem)
    private pars: array of ParData;
    
    static constructor;
    begin
      can_be_alias := nil;
      perform_merge := false;
    end;
    
    public constructor(name: DelegateName; pars: array of ParData);
    begin
      inherited Create(name, nil);
      self.pars := pars;
    end;
    private constructor := raise new InvalidOperationException;
    
    public property Parameters: array of ParData read pars;
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      bw.Write(pars.Count);
      foreach var p in pars index par_i do
        p.Save(bw, par_i<>0);
    end;
    
  end;
  
  {$endregion Delegate}
  
  {$region Func}
  
  FuncName = sealed class(ApiVendorLName<FuncName>, IBinSavable)
    
    public procedure Save(bw: BinWriter) :=
      inherited Save(bw, nil);
    
  end;
  
  Func = sealed class(NamedItem<Func, FuncName>, IComparable<Func>)
    private entry_point_name: string;
    private pars: array of ParData;
    private alias: Func;
    
    protected function ShouldMerge: boolean; override;
    begin
      Result := self.alias=nil;
//      if Result then exit;
//      if self.alias.NameSuffix<>nil then
//        log.Otp($'WARNING: {self} is alias to {self.alias}');
    end;
    static constructor;
    begin
      can_be_alias := (f1,f2,l_otp)->
      begin
        Result := true;
        
        foreach var (fr, fa) in |(f1,f2),(f2,f1)| do
        begin
          if fr.NameSuffix=nil then
          begin
            if fr.alias<>nil then
              raise new InvalidOperationException($'{fr} => {fr.alias}');
            continue;
          end;
          if fr.alias = nil then continue;
          if fr.alias <> fa then
            raise new InvalidOperationException($'{fr} => {fr.alias} <> {fa}');
          if not Result then
            raise new InvalidOperationException;
          Result := false;
        end;
        if not Result then exit;
        
        if f1.pars.Length <> f2.pars.Length then
        begin
          Result := false;
          l_otp($'Different param count: {f1.pars.Length} vs {f2.pars.Length}');
        end;
        if not Result then exit;
        
        for var i := 0 to f1.pars.Length-1 do
          if f1.pars[i] <> f2.pars[i] then
          begin
            Result := false;
            l_otp($'Different param#{i}');
          end;
        if not Result then exit;
        
      end;
      perform_merge := false;
    end;
    
    public constructor(name: FuncName; entry_point_name: string; pars: array of ParData; alias: Func);
    begin
      inherited Create(name, nil);
      self.entry_point_name := entry_point_name;
      self.pars := pars;
      self.alias := alias?.alias ?? alias;
      
      if pars[0].name<>nil then
        raise new InvalidOperationException(self.ToString);
      
    end;
    private constructor := raise new InvalidOperationException;
    
    // Avoid sorting extension functions
    public function IComparable<Func>.CompareTo(other: Func) := 0;
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      bw.Write(entry_point_name);
      bw.Write(pars.Count);
      foreach var p in pars index i do
        p.Save(bw, i<>0);
      bw.WriteBinIndexOrNil(alias);
    end;
    
  end;
  
  {$endregion Func}
  
  {$region RequiredList}
  
  RequiredList = record
    public enums := new HashSet<Enum>;
    public funcs := new HashSet<Func>;
    
    public procedure Save(bw: BinWriter);
    begin
      bw.WriteBinIndexArr( Enum.DistillAllUnique(self.enums) );
      bw.WriteBinIndexArr( Func.DistillAllUnique(self.funcs) );
    end;
    
  end;
  
  {$endregion RequiredList}
  
  {$region Feature}
  
  FeatureName = sealed class(IEquatable<FeatureName>, IComparable<FeatureName>, IBinSavable)
    private api: string;
    private ver_maj, ver_min: integer;
    
    public constructor(api: string; ver_maj, ver_min: integer);
    begin
      self.api := api;
      self.ver_maj := ver_maj;
      self.ver_min := ver_min;
    end;
    private constructor := raise new InvalidOperationException;
    
    public static function Parse(api, number: string): FeatureName;
    begin
      var ver := number.Split('.');
      if ver.Length<>2 then raise new InvalidOperationException;
      Result := new FeatureName(api,
        ver[0].ToInteger,
        ver[1].ToInteger
      );
    end;
    
    public property ApiName: string read api;
    public property Major: integer read ver_maj;
    public property Minor: integer read ver_min;
    
    public function Equals(other: FeatureName) :=
      not ReferenceEquals(other,nil) and (self.api=other.api) and (self.ver_maj=other.ver_maj) and (self.ver_min=other.ver_min);
    public static function operator=(n1,n2: FeatureName) :=
      if ReferenceEquals(n1, nil) then
        ReferenceEquals(n2, nil) else
        n1.Equals(n2);
    public static function operator<>(n1,n2: FeatureName) := not(n1=n2);
    public function Equals(obj: object): boolean; override :=
      (obj is FeatureName(var other)) and (self=other);
    
    public static function Compare(n1,n2: FeatureName): integer;
    begin
      
      Result := n1.api.Length - n2.api.Length;
      if Result<>0 then exit;
      
      Result := string.Compare(n1.api, n2.api);
      if Result<>0 then exit;
      
      Result := n1.ver_maj - n2.ver_maj;
      if Result<>0 then exit;
      
      Result := n1.ver_min - n2.ver_min;
      if Result<>0 then exit;
      
    end;
    public function CompareTo(other: FeatureName) := Compare(self, other);
    
    public function GetHashCode: integer; override :=
      ValueTuple.Create(api,ver_maj,ver_min).GetHashCode;
    
    public function ToString: string; override :=
      $'{TypeName(self)}[{api} {ver_maj}.{ver_min}]';
    
    public procedure Save(bw: BinWriter);
    begin
      bw.Write(api);
      bw.Write(ver_maj);
      bw.Write(ver_min);
    end;
    
  end;
  
  Feature = sealed class(NamedItem<Feature, FeatureName>)
    private add, rem: RequiredList;
    
    static constructor;
    begin
      can_be_alias := nil;
      perform_merge := false;
    end;
    
    public constructor(name: FeatureName; add, rem: RequiredList);
    begin
      inherited Create(name, nil);
      self.add := add;
      self.rem := rem;
    end;
    private constructor := raise new InvalidOperationException;
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      add.Save(bw);
      rem.Save(bw);
    end;
    
  end;
  
  {$endregion Feature}
  
  {$region Extension}
  
  ExtensionName = sealed class(ApiVendorLName<ExtensionName>, IBinSavable)
    
    public procedure Save(bw: BinWriter) :=
      inherited Save(bw, nil);
    
  end;
  
  Extension = sealed class(NamedItem<Extension, ExtensionName>)
    private ext_str: string;
    private add: RequiredList;
    
    private revision: string;
    private provisional: boolean;
    
    private core_dep: Feature;
    private ext_deps: array of Extension;
    
    private obsolete_by: (Feature, Extension);
    private promoted_to: (Feature, Extension);
    
    static constructor;
    begin
      can_be_alias := nil;
      perform_merge := false;
    end;
    
    public constructor(
      name: ExtensionName;
      ext_str: string; add: RequiredList;
      revision: string; provisional: boolean;
      core_dep: Feature;
      ext_deps: array of Extension;
      obsolete_by: (Feature, Extension);
      promoted_to: (Feature, Extension)
    );
    begin
      inherited Create(name, nil);
      self.ext_str := ext_str;
      self.add := add;
      self.revision := revision;
      self.provisional := provisional;
      self.core_dep := core_dep;
      self.ext_deps := ext_deps;
      self.obsolete_by := obsolete_by;
      self.promoted_to := promoted_to;
    end;
    private constructor := raise new InvalidOperationException;
    
    protected procedure SaveBody(bw: BinWriter); override;
    begin
      bw.Write(ext_str);
      
      add.Save(bw);
      
      bw.WriteNullable(self.revision, bw.Write);
      bw.Write(self.provisional);
      
      bw.WriteBinIndexOrNil(self.core_dep);
      bw.WriteBinIndexArr( Extension.DistillAllUnique(self.ext_deps) );
      
      bw.WriteAnyBinIndexOrNil(self.obsolete_by);
      bw.WriteAnyBinIndexOrNil(self.promoted_to);
      
    end;
    
  end;
  
  {$endregion Extension}
  
procedure SaveAll;
begin
  Otp($'Saving as binary');
  var bw := new BinWriter(System.IO.File.Create(GetFullPathRTA($'funcs.bin')));
  
  var save_classes := |
    'VendorSuffix',
    
    'Enum',
    
    'BasicType',
    'Group',
    'IdClass',
    'Struct',
    'Delegate',
    
    'Func',
    
    'Feature',
    'Extension'
    
  |;
  
  foreach var cl in named_types_save_proc.Keys.Except(save_classes) do
    log.Otp($'{cl} was named but not saved');
  
  foreach var cl in save_classes do
  begin
    var p: BinWriter->();
    if named_types_save_proc.TryGetValue(cl, p) then
      p(bw) else
    begin
      Log.Otp($'No {cl} to save'); //TODO Should only be Struct in GL - check
      bw.Write(0);
    end;
  end;
  
  bw.Close;
end;

end.