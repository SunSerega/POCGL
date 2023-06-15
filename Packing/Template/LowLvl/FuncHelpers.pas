unit FuncHelpers;

uses System;

uses '..\..\..\Utils\AOtp';
uses '..\..\..\Utils\CodeGen';

uses '..\..\..\DataScraping\BinCommon';
uses BinUtils;

uses TypeRefering;

type
  
  {$region FuncParamT}
  
  FuncParamTypeOrder = TypeRefering.FuncParamTypeOrder;
  FuncParamT = sealed class(System.IEquatable<FuncParamT>)
    public var_arg: boolean;
    public arr_lvl: integer;
    public tname: string;
    
    private raw_t: IDirectNamedType;
    
    public otp_data_const_sz := default(integer?);
    
    public constructor(var_arg: boolean; arr_lvl: integer; tname: string; raw_t: IDirectNamedType);
    begin
      self.var_arg  := var_arg;
      self.arr_lvl  := arr_lvl;
      self.tname    := tname;
      self.raw_t    := raw_t;
    end;
    public constructor(var_arg: boolean; arr_lvl: integer; raw_t: IDirectNamedType) :=
      Create(var_arg, arr_lvl, raw_t.MakeWriteableName, raw_t);
    private constructor := raise new InvalidOperationException;
    
    public function WithPtr(var_arg: boolean; arr_lvl: integer) :=
      new FuncParamT(var_arg, arr_lvl, tname, raw_t);
    
    public static function Parse(str: string): FuncParamT;
    const var_arg_s = 'var ';
    const array_arg_s = 'array of ';
    begin
      str := str.Trim;
      
      var var_arg := str.StartsWith(var_arg_s);
      if var_arg then str := str.Substring(var_arg_s.Length).Trim;
      
      var arr_lvl := 0;
      while str.StartsWith(array_arg_s) do
      begin
        arr_lvl += 1;
        str := str.Substring(array_arg_s.Length).Trim;
      end;
      
      Result := new FuncParamT(var_arg, arr_lvl, TypeLookup.FromNameString(str));
    end;
    
    public property TypeOrder: FuncParamTypeOrder read raw_t.GetTypeOrder;
    public procedure Use(need_write: boolean) := raw_t.Use(need_write);
    
    public property IsGeneric: boolean read tname.StartsWith('T') and tname.Skip(1).All(char.IsDigit);
    
    public function ToString(generate_code: boolean; with_var: boolean := false; raw_t_name: boolean := false): string;
    begin
      if generate_code then
      begin
        var res := new StringBuilder;
        if with_var and var_arg then res += 'var ';
        
        var rep_c_str := self.otp_data_const_sz?.ToString;
        
        if arr_lvl<>0 then
        begin
          res += 'array';
          if rep_c_str<>nil then
          begin
            res += '[';
            res += rep_c_str;
            res += ']';
            rep_c_str := nil;
          end;
          res += ' of ';
          loop arr_lvl-1 do res += 'array of ';
        end;
        if raw_t_name then
          res += self.raw_t.GetRawName.ToString else
          res += self.tname;
        if rep_c_str<>nil then
        begin
          if self.raw_t <> KnownDirectTypes.String then 
            raise new InvalidOperationException;
          res += '[';
          res += rep_c_str;
          res += ']';
          rep_c_str := nil;
        end;
        Result := res.ToString;
      end else
        Result := $'({var_arg}, {arr_lvl}, {tname})';
    end;
    public function ToString: string; override := ToString(false);
    
    public static function operator=(par1,par2: FuncParamT): boolean;
    begin
      var par1_nil := Object.ReferenceEquals(par1,nil);
      var par2_nil := Object.ReferenceEquals(par2,nil);
      Result :=
        if par1_nil then par2_nil else
        not par2_nil and
        (par1.var_arg = par2.var_arg) and
        (par1.arr_lvl = par2.arr_lvl) and
        (par1.tname   = par2.tname);
    end;
    public static function operator<>(par1,par2: FuncParamT) := not(par1=par2);
    
    public function Equals(other: FuncParamT) := self=other;
    public function Equals(o: object): boolean; override :=
      (o is FuncParamT(var other)) and (self=other);
    
  end;
  
  {$endregion FuncParamT}
  
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
  
  {$region FuncOverload}
  
  FuncOverload = sealed class(System.IEquatable<FuncOverload>)
    public pars: array of FuncParamT;
    
    public enum_to_type_bindings: array of EnumToTypeBindingInfo;
    public enum_to_type_gr := default(IDirectNamedType);
    public enum_to_type_enum_name := default(string);
    
    public constructor(pars: array of FuncParamT);
    begin
      self.pars := pars;
      self.enum_to_type_bindings := nil;
    end;
    public constructor(pars: array of FuncParamT; enum_to_type_bindings: array of EnumToTypeBindingInfo; enum_to_type_gr: IDirectNamedType; enum_to_type_enum_name: string);
    begin
      self.pars := pars;
      self.enum_to_type_bindings := enum_to_type_bindings;
      self.enum_to_type_gr := enum_to_type_gr;
      self.enum_to_type_enum_name := enum_to_type_enum_name;
    end;
    private constructor := raise new InvalidOperationException;
    
    public static function operator implicit(pars: array of FuncParamT): FuncOverload := new FuncOverload(pars);
    
    public static function operator=(ovr1, ovr2: FuncOverload): boolean;
    begin
      Result := false;
      begin
        var nil1 := ReferenceEquals(ovr1,nil);
        var nil2 := ReferenceEquals(ovr2,nil);
        if nil1<>nil2 then exit;
        Result := nil1;
        if Result then exit;
      end;
      if ovr1.enum_to_type_enum_name <> ovr2.enum_to_type_enum_name then exit;
      if not ReferenceEquals(ovr1.enum_to_type_bindings, ovr2.enum_to_type_bindings) then
        raise new InvalidOperationException;
      if ovr1.pars.Length<>ovr2.pars.Length then
        raise new System.InvalidOperationException;
      Result := ovr1.pars.SequenceEqual(ovr2.pars);
    end;
    
    public function Equals(other: FuncOverload) := self=other;
    public function GetHashCode: integer; override;
    begin
      Result := 0;
      if enum_to_type_enum_name<>nil then
        Result := enum_to_type_enum_name.GetHashCode;
      foreach var par in pars do
      begin
        if par=nil then continue;
        if par.tname=nil then
          raise nil;
        Result := Result xor par.tname.GetHashCode;
      end;
    end;
    
  end;
  
  {$endregion FuncOverload}
  
  {$region FuncParamMarshaler}
  
  FuncParamMarshaler = sealed class
    public par: FuncParamT;
    
    /// Changes to name of var with marshaled value
    public par_str := default(string);
    /// 'abc('#0')' will call abc() func on result
    public res_par_conv := default(string);
    
    public vars := new List<(string, string)>;
    public init := new StringBuilder;
    public fnls := new StringBuilder;
    
    public constructor(par: FuncParamT; par_str: string);
    begin
      self.par     := par;
      self.par_str := par_str;
    end;
    private constructor := raise new System.InvalidOperationException;
    
  end;
  
  {$endregion FuncParamMarshaler}
  
  {$region FuncOvrMarshalers}
  
  FuncOvrMarshalers = sealed class
    private marshalers: array of record
      lst := new List<FuncParamMarshaler>;
      ind := 0;
    end;
    
    public constructor(par_c: integer) := SetLength(marshalers, par_c);
    private constructor := raise new System.InvalidOperationException;
    
    public procedure AddMarshaler(par_i: integer; m: FuncParamMarshaler);
    begin
      marshalers[par_i].lst += m;
      marshalers[par_i].ind += 1;
    end;
    
    public procedure Seal :=
    for var i := 0 to marshalers.Length-1 do
      if marshalers[i].lst.Count=0 then
        marshalers[i].lst := nil else
      begin
        marshalers[i].lst.Capacity := marshalers[i].lst.Count;
        marshalers[i].lst.Reverse;
      end;
    
    public function MaxMarshalInd: integer;
    begin
      Result := -1; // Default "-1" if "marshalers.Length=0"
      for var par_i := 0 to marshalers.Length-1 do
        Result := Max(Result, marshalers[par_i].ind);
    end;
    
    public function GetCurrent(par_i: integer) :=
    marshalers[par_i].lst[marshalers[par_i].ind];
    
    public function GetPossible(par_i, max_ind: integer): (boolean,FuncParamMarshaler);
    begin
      var ind := marshalers[par_i].ind;
      var is_fast_forward := false;
      if ind<>0 then
      begin
        is_fast_forward := ind<=max_ind;
        ind -= 1;
        if not is_fast_forward then
          marshalers[par_i].ind := ind;
      end;
      Result := (is_fast_forward, marshalers[par_i].lst[ind]);
    end;
    public procedure ChosenFastForward(par_i: integer) :=
    marshalers[par_i].ind -= 1;
    
  end;
  
  {$endregion FuncOvrMarshalers}
  
  {$region MethodImplData}
  
  MethodImplData = sealed class
    public pars: array of FuncParamMarshaler;
    public name := default(string);
    public is_public := false;
    public call_by := new List<MethodImplData>;
    public call_to := default(MethodImplData); // "nil" if this is a native method
    
    public constructor(pars: array of FuncParamMarshaler) := self.pars := pars;
    
  end;
  
  {$endregion MethodImplData}
  
end.