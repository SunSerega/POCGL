unit NamedItems;

uses '../../Utils/AOtp';
uses '../../POCGL_Utils';

uses System;

uses ScrapUtils;

var log_merge_fails := new FileLogger(GetFullPathRTA('merge_fails.log'));
var log_missing_alias := new FileLogger(GetFullPathRTA('missing_alias.log'));

type
  BinWriter = System.IO.BinaryWriter;
  
  IBinSavable = interface
    
    procedure Save(bw: BinWriter);
    
  end;
  
  IBinIndexable = interface
    
    property BinIndex: integer read;
    
  end;
  
  IComplexName = interface
    
    property ApiName: string read;
    property VendorSuffix: string read;
    property LocalName: string read;
    
  end;
  
var named_types_save_proc := new Dictionary<string, BinWriter->()>;

type
  
  {$region ApiVendorLName}
  
  ApiVendorLName<TSelf> = abstract class(IEquatable<TSelf>, IComparable<TSelf>, IComplexName)
  where TSelf: ApiVendorLName<TSelf>;
    private api, vendor_suffix, name: string;
    
    public constructor(api, vendor_suffix, name: string);
    begin
      self.api := api; if api=nil then raise new InvalidOperationException('nil api');
      self.vendor_suffix := vendor_suffix;
      self.name := name; if name=nil then raise new InvalidOperationException('nil name');
    end;
    public constructor(api, l_name: string; api_beg: string; expected_underscore: boolean?; extract_vendor: string->ValueTuple<string,string>);
    begin
      
      if l_name.ToLower.StartsWith(api_beg) then
        l_name := l_name.RemoveBeg(api_beg, true) else
      begin
        log.Otp($'Name [{l_name}] defined in api [{api}] did not start with [{api_beg}]'+#10+Environment.StackTrace);
        expected_underscore := nil;
      end;
      
      if (expected_underscore = not l_name.StartsWith('_')) then
        raise new InvalidOperationException(l_name);
      if expected_underscore<>false then
        l_name := l_name.TrimStart('_');
      
      self.api := api;
      (self.vendor_suffix, self.name) := extract_vendor(l_name);
    end;
    private constructor := raise new InvalidOperationException;
    
    private static validated_suffix_formats := new HashSet<string>;
    /// formats: *_e, E*
    /// output: (suffix, name)
    public static function ParseSuffix(s: string; suffixes: HashSet<string>; params formats: array of string): ValueTuple<string, string>;
    begin
      
      foreach var format in formats do
      begin
        if format in validated_suffix_formats then continue;
        if format.Length not in 2..3 then
          raise new FormatException(format);
        if not format.All(ch->ch in '*_eE') then
          raise new FormatException(format);
        if format.ToLower.Distinct.Count<>format.Length then
          raise new FormatException(format);
        if '_' in |format.First,format.Last| then
          raise new FormatException(format);
        validated_suffix_formats += format;
      end;
      
      var max_suf_len := suffixes.Max(suf->suf.Length);
      var possible_sufs := new HashSet<string>;
      
      foreach var f in formats do
      begin
        var ext_need_upper := f.Single(ch->ch in 'eE').IsUpper;
        
        if '_' in f then
        begin
          if '_' not in s then continue;
          var try_ret := function(suf, name: string): ValueTuple<string,string> ->
          begin
            Result.Item1 := nil;
            var correct_suf: string;
            if not suffixes.TryGetValue(suf, correct_suf) then exit;
            possible_sufs += suf;
            if (correct_suf<>suf) and not suf.Where(char.IsLetter).All(ch->ch.IsUpper = ext_need_upper) then exit;
            Result := ValueTuple.Create(suf, name);
          end;
          
          if f.EndsWith('*') then
          begin
            var ind := s.IndexOf('_');
            Result := try_ret(s.Remove(ind), s.Substring(ind+1));
            if Result.Item1<>nil then exit;
          end else
          begin
            var ind := s.LastIndexOf('_');
            Result := try_ret(s.Substring(ind+1), s.Remove(ind));
            if Result.Item1<>nil then exit;
          end;
          
        end else
        begin
          var last_good_suf := default(string);
          var try_ret := function(suf, name: string): ValueTuple<string,string> ->
          begin
            Result.Item1 := nil;
            var correct_suf: string;
            if not suffixes.TryGetValue(suf, correct_suf) then exit;
            last_good_suf := suf;
            if (correct_suf<>suf) and not suf.Where(char.IsLetter).All(ch->ch.IsUpper = ext_need_upper) then exit;
            Result := ValueTuple.Create(suf, name);
          end;
          
          if f.EndsWith('*') then
          begin
            for var c := 1 to s.Length.ClampTop(max_suf_len) do
            begin
              Result := try_ret(s.Substring(0,c), s.Remove(0,c));
              if Result.Item1<>nil then exit;
            end;
            if last_good_suf<>nil then
              possible_sufs += last_good_suf;
          end else
          begin
            for var c := 1 to s.Length.ClampTop(max_suf_len) do
            begin
              Result := try_ret(s.Remove(0,s.Length-c), s.Substring(0,s.Length-c));
              if Result.Item1<>nil then exit;
            end;
            if last_good_suf<>nil then
              possible_sufs += last_good_suf;
          end;
          
        end;
        
      end;
      
//      if possible_sufs.Count<>0 then
//        log.Otp($'[{s}] did not have suffix, but could have: {possible_sufs.JoinToString}');
      
      Result := ValueTuple.Create(default(string), s);
    end;
    
    public property ApiName: string read api;
    public property VendorSuffix: string read vendor_suffix;
    public property LocalName: string read name;
    
    public function Equals(other: TSelf) :=
      not ReferenceEquals(other,nil) and (self.api=other.api) and (self.vendor_suffix=other.vendor_suffix) and (self.name=other.name);
    public static function operator=(n1,n2: ApiVendorLName<TSelf>) :=
      if ReferenceEquals(n1, nil) then
        ReferenceEquals(n2, nil) else
        n1.Equals(n2);
    public static function operator<>(n1,n2: ApiVendorLName<TSelf>) := not(n1=n2);
    public function Equals(obj: object): boolean; override :=
      (obj is TSelf(var other)) and (self=other);
    
    public static function Compare(n1,n2: TSelf): integer;
    begin
      
      Result := n1.api.Length - n2.api.Length;
      if Result<>0 then exit;
      
      Result := string.Compare(n1.api, n2.api);
      if Result<>0 then exit;
      
      Result := string.Compare(n1.vendor_suffix, n2.vendor_suffix);
      if Result<>0 then exit;
      
      Result := string.Compare(n1.name, n2.name);
      if Result<>0 then exit;
      
    end;
    public function CompareTo(other: TSelf) := Compare(TSelf(self), other);
    
    public function GetHashCode: integer; override :=
      ValueTuple.Create(api,vendor_suffix,name).GetHashCode;
    
    public function ToString: string; override :=
      $'{api}::{name} + {vendor_suffix??''/core\''}';
    
    protected procedure Save(bw: BinWriter; save_suffix: boolean?);
    begin
      bw.Write(api);
      
      if save_suffix=nil then
      begin
        bw.Write(vendor_suffix<>nil);
        if vendor_suffix<>nil then
          bw.Write(vendor_suffix);
      end else
      if save_suffix.Value then
        bw.Write(vendor_suffix) else
      if vendor_suffix<>nil then
        raise new InvalidOperationException(self.ToString);
      
      bw.Write(name);
    end;
    
  end;
  
  {$endregion ApiVendorLName}
  
  {$region NamedItem}
  
  //TODO #2849
  TODO_2849<T> = auto class
    first: T;
    can_be_alias: Func<T, T, Action<OtpLine>, boolean>; 
    
    function lambda(item: T) := not can_be_alias(item, first, log_merge_fails.Otp);
    
  end;
  
  NamedItem<TSelf, TName> = abstract class(IBinSavable, IBinIndexable, IComparable<TSelf>)
  where TSelf: NamedItem<TSelf, TName>;
  where TName: IEquatable<TName>, IComparable<TName>;
    private static Defined := new Dictionary<TName, TSelf>;
    private static save_ready: array of TSelf;
    private _name: TName;
    
    {$region constructor's}
    
    static constructor :=
      named_types_save_proc.Add(TypeToTypeName(typeof(TSelf)), SaveAll);
    
    public constructor(name: TName; multi_def_diag: TSelf->string);
    begin
      self._name := name;
      
      if save_ready<>nil then
        raise new InvalidOperationException($'{self} finished loading too late');
      
      if name in Defined then
        raise new InvalidOperationException($'{self} defined multiple times{multi_def_diag?.Invoke(Defined[name])}');
      Defined.Add(name, TSelf(self));
      
    end;
    protected constructor := raise new InvalidOperationException;
    
    {$endregion constructor's}
    
    {$region Naming}
    
    public property Name: TName read _name;
    function IComparable<TSelf>.CompareTo(other: TSelf) := self.Name.CompareTo(other.Name);
    
    public static function Require(name: TName): TSelf;
    begin
      if Defined.TryGetValue(name, Result) then exit;
      raise new InvalidOperationException($'{TypeToTypeName(typeof(TSelf))} [{name}] is not defined');
    end;
    public static property Existing[name: TName]: TSelf read if name=nil then nil else Require(name); default;
    public static property ExistingOrNil[name: TName]: TSelf read if name=nil then nil else Defined.Get(name);
    
    private procedure Rename(new_name: TName);
    begin
      Defined.Add(new_name, TSelf(self));
      self._name := new_name;
    end;
    
    public function ToString: string; override :=
      $'{TypeName(self)} [{self.Name}]';
    
    {$endregion Naming}
    
    {$region Pre-saving}
    
    protected function NameApi: string; virtual := IComplexName(self.Name).ApiName;
    protected function NameSuffix: string; virtual := IComplexName(self.Name).VendorSuffix;
    protected function NameLocal: string; virtual := IComplexName(self.Name).LocalName;
    
    protected function NameWithoutSuffix: TName; virtual;
    begin
      Result := default(TName);
      raise new NotImplementedException(TypeToTypeName(typeof(TSelf)));
    end;
    
    protected static can_be_alias: Func<TSelf, TSelf, Action<OtpLine>, boolean>; 
    protected static perform_merge: boolean?;
    protected static copy_without_suffix: Func<string, string, TSelf, TSelf>;
    
    protected function ShouldMerge: boolean; virtual := true;
    private merged_into := default(TSelf);
    public static procedure EnsureSaveReady;
    begin
      if save_ready<>nil then exit;
      
      {if false then{} if can_be_alias<>nil then
      begin
        var perform_merge := perform_merge.Value;
        
        var suffix_less_lookup := Defined.Values.Where(item->item.ShouldMerge).ToLookup(item->
        begin
          Result := ValueTuple.Create(item.NameApi, item.NameLocal);
        end);
        
        foreach var g in suffix_less_lookup do
        begin
          var (api, lname) := g.Key;
          var root := g.SingleOrDefault(item->(item as NamedItem<TSelf, TName>).NameSuffix=nil);
          
          if (root=nil) and perform_merge then
            if g.Count=1 then
              g.Single.Rename(g.Single.NameWithoutSuffix) else
            begin
              var cap := new TODO_2849<TSelf>(g.First, can_be_alias);
              if g.Skip(1).Any(cap.lambda) then
              begin
                log_merge_fails.Otp($'Unable to merge items: {g.JoinToString}');
                continue;
              end;
              if copy_without_suffix=nil then
                raise new NotImplementedException($'{TypeToTypeName(typeof(TSelf))} did not implement merge root creator, needed for: {g.JoinToString}');
              root := copy_without_suffix(api, lname, g.First);
              if root=nil then raise nil;
            end;
          
          if root<>nil then foreach var item in g do
          begin
            if item=root then continue;
            if not can_be_alias(item, root, log_merge_fails.Otp) then
              log_merge_fails.Otp($'Unable to merge {item} => {root}') else
            begin
              log_missing_alias.Otp($'{item} => {root}');
              if perform_merge then
                item.merged_into := root;
            end;
          end;
          
        end;
        
      end else
      if perform_merge<>false then
        raise new InvalidOperationException;
      
      save_ready := Defined.Values.Where(item->item.merged_into=nil).Distinct.ToArray;
      Sort(save_ready, item->item.Name);
      
      for var i := 0 to save_ready.Length-1 do
        save_ready[i].bin_index := i;
      
    end;
    
    {$endregion Pre-saving}
    
    {$region Saving}
    
    private bin_index := default(integer?);
    private function get_bin_index: integer;
    begin
      EnsureSaveReady;
      var ind :=
        if merged_into<>nil then
          merged_into.bin_index else
          self.bin_index;
      if ind=nil then raise new InvalidOperationException(self.ToString);
      Result := ind.Value;
    end;
    public property BinIndex: integer read get_bin_index;
    
    public function AfterMerges: TSelf;
    begin
      Result := self.merged_into ?? TSelf(self);
      {$ifdef DEBUG}
      if Result.merged_into<>nil then
        raise new InvalidOperationException;
      {$endif DEBUG}
    end;
    
    public static function DistillAllUnique<T>(inp: sequence of T; sel: T->TSelf; check_equ: (T,T)->()): List<T>;
    begin
      Result := new List<T>;
      var prev := new Dictionary<TSelf, T>;
      
      foreach var o in inp do
      begin
        var s := sel(o).AfterMerges;
        
        var old_o: T;
        if prev.TryGetValue(s, old_o) then
        begin
          if check_equ<>nil then
            check_equ(o, old_o);
          continue;
        end;
        
        prev.Add(s, o);
        Result += o;
      end;
      
    end;
    public static function DistillAllUnique(inp: sequence of TSelf) := DistillAllUnique(inp, o->o, nil).ConvertAll(o->o.AfterMerges);
    
    protected procedure SaveName(bw: BinWriter); virtual := IBinSavable(Name).Save(bw);
    protected procedure SaveBody(bw: BinWriter); abstract;
    private saved := false;
    public procedure Save(bw: BinWriter);
    begin
      if saved then raise new InvalidOperationException;
      saved := true;
      SaveName(bw);
      SaveBody(bw);
    end;
    public static procedure SaveAll(bw: BinWriter);
    begin
      EnsureSaveReady;
      Otp($'{TypeToTypeName(typeof(TSelf))}: Saved {save_ready.Length} items');
      bw.Write(save_ready.Length);
      
      foreach var item in save_ready do
        item.Save(bw);
      
    end;
    
    {$endregion Saving}
    
  end;
  
  {$endregion NamedItem}
  
  {$region MultiKindItem}
  
  MultiKindItem<TKind> = abstract class
  where TKind: System.Enum, record;
    
    protected function GetKind: TKind; abstract;
    
    public function EqualsMKI(other: MultiKindItem<TKind>; l_otp: OtpLine->()): boolean; abstract;
    public static function operator=(mk1,mk2: MultiKindItem<TKind>) :=
      ReferenceEquals(mk1,mk2) or (
        not ReferenceEquals(mk1, nil)
        and mk1.EqualsMKI(mk2, l->begin end)
      );
    public static function operator<>(mk1,mk2: MultiKindItem<TKind>) := not(mk1=mk2);
    public function Equals(obj: object): boolean; override :=
      (obj is MultiKindItem<TKind>(var other)) and (self=other);
    
    protected procedure SaveHead(bw: BinWriter); abstract;
    protected procedure SaveBody(bw: BinWriter); abstract;
    
    public procedure Save(bw: BinWriter);
    begin
      bw.Write(Convert.ToInt32(GetKind));
      SaveHead(bw);
      SaveBody(bw);
    end;
    
  end;
  
  {$endregion MultiKindItem}
  
procedure WriteNullable<T>(self: BinWriter; o: T; write: (BinWriter,T)->()); extensionmethod;
begin
  self.Write(o<>nil);
  if o=nil then exit;
  write(self,o);
end;

procedure WriteNullable<T>(self: BinWriter; o: T; write: T->()); extensionmethod;
begin
  self.Write(o<>nil);
  if o=nil then exit;
  write(o);
end;

procedure WriteBinIndexOrNil<T>(self: BinWriter; o: T); extensionmethod; where T: IBinIndexable;
begin
  self.Write(if o=nil then -1 else o.BinIndex);
end;

procedure WriteBinIndexArr<T>(self: BinWriter; l: IList<T>); extensionmethod; where T: IBinIndexable;
begin
  self.Write(l.Count);
  foreach var o in l.Order do
    self.Write(o.BinIndex);
end;

procedure WriteAnyBinIndexOrNil<T1,T2>(self: BinWriter; t: (T1,T2)); extensionmethod; where T1,T2: IBinIndexable;
begin
  var any_done := false;
  var type_ind := 0;
  var add := procedure(o: IBinIndexable)->
  begin
    type_ind += 1;
    if o=nil then exit;
    
    if any_done then raise new System.InvalidOperationException($'Multiple non-nil items in {ObjectToString(t)}');
    any_done := true;
    
    self.Write(type_ind);
    self.Write(o.BinIndex);
  end;
  add(t.Item1);
  add(t.Item2);
  if not any_done then
    self.Write(0);
end;

initialization
finalization
  try
    log_merge_fails.Close;
    log_missing_alias.Close;
  except
    on e: Exception do
      ErrOtp(e);
  end;
end.