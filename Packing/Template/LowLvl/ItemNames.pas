unit ItemNames;

{$zerobasedstrings}

uses System;

uses BinUtils;

type
  
  {$region TypeComboName}
  
  TypeComboName = record(IEquatable<TypeComboName>, IComparable<TypeComboName>)
    private org_tname := default(string);
    private tname_id := default(string);
    private sz1, sz2: integer;
    
    private static function AssertAndGet<T>(is_fine: boolean; get: ()->T): T;
    begin
      {$ifdef DEBUG}
      if not is_fine then
        raise new InvalidOperationException;
      {$endif DEBUG}
      Result := get();
    end;
    
    public function IsUnsigned := tname_id.StartsWith('u');
    
    public property OriginalType: string read org_tname;
    public function IsFloat: boolean;
    begin
      case tname_id of
        
        'b',    'ub':   Result := false;
        's',    'us':   Result := false;
        'i',    'ui':   Result := false;
        'i64',  'ui64': Result := false;
        'f',    'd':    Result := true;
        
        else raise new NotImplementedException(tname_id);
      end;
    end;
    
    public property IsVector: boolean read sz2=1;
    public function VectorSize := AssertAndGet(IsVector, ()->sz1);
    
    public property IsMatrix: boolean read sz2>1;
    public function MatrixSizes := AssertAndGet(IsMatrix, ()->ValueTuple.Create(sz1,sz2));
    
    public function TotalSize := sz1*sz2;
    
    public function MatrixTransposedTypeName: TypeComboName;
    begin
      if not IsMatrix then raise new InvalidOperationException;
      Result := new TypeComboName(self.org_tname, self.tname_id, self.sz2, self.sz1);
      if not Result.IsMatrix then raise new InvalidOperationException;
    end;
    public function MatrixColTypeName: TypeComboName;
    begin
      if not IsMatrix then raise new InvalidOperationException;
      Result := new TypeComboName(self.org_tname, self.tname_id, self.sz1, 1);
      if not Result.IsVector then raise new InvalidOperationException;
    end;
    public function MatrixRowTypeName: TypeComboName;
    begin
      if not IsMatrix then raise new InvalidOperationException;
      Result := new TypeComboName(self.org_tname, self.tname_id, self.sz2, 1);
      if not Result.IsVector then raise new InvalidOperationException;
    end;
    
    public function IsAnySizeBiggerThan(other: TypeComboName): boolean;
    begin
      {$ifdef DEBUG}
      if self.IsVector <> other.IsVector then
        raise new InvalidOperationException;
      {$endif DEBUG}
      if self.IsVector then
        Result := self.VectorSize > other.VectorSize else
      begin
        var (s_sz1, s_sz2) := self.MatrixSizes;
        var (o_sz1, o_sz2) := other.MatrixSizes;
        Result := (s_sz1 > o_sz1) or (s_sz2 > o_sz2);
      end;
    end;
    
    private static bt_use_proc: string->();
    public static procedure RegisterBTUseProc(p: string->());
    begin
      if bt_use_proc<>nil then
        raise new InvalidOperationException;
      bt_use_proc := p;
    end;
    
    private static function MakeTypeId(tname: string): string;
    begin
      case tname of
        
         'SByte': Result := 'b';
          'Byte': Result := 'ub';
        
         'Int16': Result := 's';
        'UInt16': Result := 'us';
        
         'Int32': Result := 'i';
        'UInt32': Result := 'ui';
        
         'Int64': Result := 'i64';
        'UInt64': Result := 'ui64';
        
        'single': Result := 'f';
        'double': Result := 'd';
        
        else raise new NotImplementedException($'Invalid vector val type [{tname}]');
      end;
    end;
    private constructor(org_tname, tname_id: string; sz1, sz2: integer);
    begin
      if org_tname<>nil then
        bt_use_proc(org_tname);
      self.org_tname := org_tname;
      self.tname_id := tname_id;
      self.sz1 := sz1;
      self.sz2 := sz2;
    end;
    
    public property IsLookupOnly: boolean read org_tname=nil;
    
    public static function Vector(basic_tname: string; sz: integer): TypeComboName;
    begin
      Result := new TypeComboName(basic_tname, MakeTypeId(basic_tname), sz, 1);
      if not Result.IsVector then
        raise new InvalidOperationException;
    end;
    public static function Matrix(basic_tname: string; sz1, sz2: integer): TypeComboName;
    begin
      Result := new TypeComboName(basic_tname, MakeTypeId(basic_tname), sz1, sz2);
      if not Result.IsMatrix then
        raise new InvalidOperationException;
    end;
    
    public static function ParseVector(s: string): TypeComboName;
    const vec_s = 'Vec';
    begin
      
      if not s.StartsWith(vec_s) then
        raise new FormatException(s);
      s := s.SubString(vec_s.Length);
      
      var sz := s.First.ToDigit;
      s := s.Substring(1);
      
      Result := new TypeComboName(nil, s, sz, 1);
      if not Result.IsVector then
        raise new InvalidOperationException;
    end;
    
    public function Equals(other: TypeComboName) :=
      (self.tname_id=other.tname_id) and (self.sz1=other.sz1) and (self.sz2=other.sz2);
    public static function operator=(n1,n2: TypeComboName) := n1.Equals(n2);
    public static function operator<>(n1,n2: TypeComboName) := not(n1=n2);
    public function Equals(obj: object): boolean; override :=
      (obj is TypeComboName(var other)) and (self=other);
    
    public static function Compare(n1,n2: TypeComboName): integer;
    begin
      
      Result := Ord(n1.IsMatrix)-Ord(n2.IsMatrix);
      if Result<>0 then exit;
      
      Result := Ord(n1.IsVector)-Ord(n2.IsVector);
      if Result<>0 then exit;
      
      Result := n1.sz1 - n2.sz1;
      if Result<>0 then exit;
      
      Result := n1.sz2 - n2.sz2;
      if Result<>0 then exit;
      
      Result := string.Compare(n1.tname_id, n2.tname_id);
      if Result<>0 then exit;
      
    end;
    public function CompareTo(other: TypeComboName) := Compare(self, other);
    
    public function GetHashCode: integer; override :=
      ValueTuple.Create(tname_id, sz1, sz2).GetHashCode;
    
    public function ToString(simplify: boolean?): string;
    begin
      var sb := new StringBuilder;
      
      if IsVector then
        sb += 'Vec' else
      if IsMatrix then
        sb += 'Mtr' else
        raise new InvalidOperationException;
      
      sb += sz1.ToString;
      if IsMatrix and (not simplify.Value or (sz2<>sz1)) then
      begin
        sb += 'x';
        sb += sz2.ToString;
      end;
      
      sb += tname_id;
      
      Result := sb.ToString;
    end;
    public function ToString: string; override :=
      $'TypeComboName[{sz1}x{sz2} of {org_tname} ({tname_id})]';
    
  end;
  
  {$endregion TypeComboName}
  
  {$region ApiVendorLName}
  
  ApiVendorLName = record(IEquatable<ApiVendorLName>, IComparable<ApiVendorLName>)
    public api            := default(string);
    public vendor_suffix  := default(string);
    public l_name         := default(string);
    
    private static suffix_use_proc: string->();
    public static procedure RegisterSuffixUseProc(p: string->());
    begin
      if suffix_use_proc<>nil then
        raise new InvalidOperationException;
      suffix_use_proc := p;
    end;
    
    public constructor(br: BinReader);
    begin
      self.api := br.ReadString;
      self.vendor_suffix := br.ReadOrNil(br->br.ReadString);
      self.l_name := br.ReadString;
      
      if vendor_suffix<>nil then
        suffix_use_proc(vendor_suffix);
      
    end;
    
    public static function Parse(name: string): ApiVendorLName;
    const api_sep = $'::';
    const suffix_sep = $'+';
    begin
      
      var api_sep_ind := name.IndexOf(api_sep);
      if api_sep_ind = -1 then raise new FormatException(name);
      
      Result.api := name.Remove(api_sep_ind).Trim;
      Result.l_name := name.SubString(api_sep_ind+api_sep.Length).Trim;
      
      var suffix_sep_ind := Result.l_name.IndexOf(suffix_sep);
      if suffix_sep_ind = -1 then
        Result.vendor_suffix := nil else
      begin
        Result.vendor_suffix := Result.l_name.SubString(suffix_sep_ind+suffix_sep.Length).Trim;
        Result.l_name := Result.l_name.Remove(suffix_sep_ind).Trim;
      end;
      
    end;
    
    public function Equals(other: ApiVendorLName): boolean :=
      (self.api=other.api) and (self.vendor_suffix?.ToUpper=other.vendor_suffix?.ToUpper) and (self.l_name=other.l_name);
    public static function operator=(n1,n2: ApiVendorLName) := n1.Equals(n2);
    public static function operator<>(n1,n2: ApiVendorLName) := not(n1=n2);
    public function Equals(obj: object): boolean; override :=
      (obj is ApiVendorLName(var other)) and (self=other);
    
    public static function Compare(n1,n2: ApiVendorLName): integer;
    begin
      
      Result := Ord(n1.api<>nil) - Ord(n2.api<>nil);
      if Result<>0 then exit;
      
      if n1.api <> nil then
      begin
        Result := n1.api.Length - n2.api.Length;
        if Result<>0 then exit;
        
        Result := string.Compare(n1.api, n2.api);
        if Result<>0 then exit;
      end;
      
      Result := string.Compare(n1.vendor_suffix?.ToUpper, n2.vendor_suffix?.ToUpper);
      if Result<>0 then exit;
      
      Result := string.Compare(n1.l_name, n2.l_name);
      if Result<>0 then exit;
      
    end;
    public function CompareTo(other: ApiVendorLName) := Compare(self, other);
    
    public function GetHashCode: integer; override :=
      ValueTuple.Create(api, vendor_suffix?.ToUpper, l_name).GetHashCode;
    
    public function SnakeToCamelCase: ApiVendorLName;
    begin
      Result.api := self.api;
      Result.l_name := self.l_name.Split('_').Select(w->
      begin
        if w.Length<>0 then w[0] := w[0].ToUpper else
          raise new System.InvalidOperationException(self.ToString);
        Result := w;
      end).JoinToString('');
      Result.vendor_suffix := self.vendor_suffix?.ToUpper;
    end;
    
    public function ToString(outer_api: string; add_core_suffix: boolean): string;
    begin
      var sb := new StringBuilder;
      if self.api <> outer_api then
      begin
        sb += self.api;
        sb += '::';
      end;
      sb += self.l_name;
      if (self.vendor_suffix<>nil) or add_core_suffix then
      begin
        sb += ' + ';
        sb += self.vendor_suffix ?? '/core\';
      end;
      Result := sb.ToString;
    end;
    public function ToString: string; override := ToString(nil, false);
    
  end;
  
  {$endregion ApiVendorLName}
  
  {$region FeatureName}
  
  FeatureName = record(IEquatable<FeatureName>, IComparable<FeatureName>)
    private api: string;
    private ver_maj, ver_min: integer;
    
    public constructor(br: BinReader);
    begin
      self.api := br.ReadString;
      self.ver_maj := br.ReadInt32;
      self.ver_min := br.ReadInt32;
    end;
    
    public property SourceAPI: string read api;
    
    public property Major: integer read ver_maj;
    public property Minor: integer read ver_min;
    
    public function Equals(other: FeatureName) :=
      (self.api=other.api) and (self.ver_maj=other.ver_maj) and (self.ver_min=other.ver_min);
    public static function operator=(n1,n2: FeatureName) := n1.Equals(n2);
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
    
  end;
  
  {$endregion FeatureName}
  
end.