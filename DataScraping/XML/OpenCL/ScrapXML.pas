uses System;

uses '../../../Utils/ThoroughXML';
uses '../../../Utils/AOtp';

uses '../../../POCGL_Utils';

uses '../ScrapUtils';
//
uses '../XMLItems';
uses '../ItemSources';

const api='cl';

type
  LogCache = static class
    static missing_type_def  := new HashSet<string>;
  end;
  
  {$region VendorSuffix}
  
  VendorSuffixSource = sealed class(ItemSource<VendorSuffixSource, string, VendorSuffix>)
    private static known_suffixes := new HashSet<string>(StringComparer.OrdinalIgnoreCase);
    
    private static known_names := new HashSet<string>;
    public static procedure RequireName(name: string);
    begin
      if name=nil then exit;
      if name in known_names then exit;
      raise new InvalidOperationException(name);
    end;
    
    public static procedure InitAll :=
      foreach var l in ReadLines(GetFullPathRTA('vendors.dat'), enc) do
      begin
        if string.IsNullOrWhiteSpace(l) then continue;
        
        var spl := l.Split('=').ConvertAll(s->s.Trim);
        if spl.Length<>2 then raise new FormatException(l);
        var (name, suffix) := spl;
        
        if (name<>'') and not known_names.Add(name) then
          raise new InvalidOperationException(name);
        
        if suffix<>'' then
        begin
          new VendorSuffixSource(suffix);
          known_suffixes += suffix;
        end;
      end;
    
    protected function MakeNewItem: VendorSuffix; override;
    
  end;
  
  {$endregion VendorSuffix}
  
  {$region Enum}
  
  EnumSource = sealed class(ItemSource<EnumSource, EnumName, Enum>)
    private is_bitpos: boolean;
    private val_s: string;
    
    public static function MakeName(s: string; allow_nil, skip_invalid: boolean) :=
      ItemSourceHelpers.MakeName&<EnumName>(api, s, api, allow_nil, skip_invalid, true, VendorSuffixSource.known_suffixes, '*_E');
    
    /// CL_FLT_MAX and stuff
    private static external_enum_names := new HashSet<string>;
    
    private constructor(allow_bitpos: boolean; n: XmlNode);
    begin
      inherited Create(MakeName(n['name'], false, false));
      n.TryDiscardAttrib('comment');
//      self.allow_bitpos := allow_bitpos;
      
      var val_s := n['value'];
      var bitpos_s := n['bitpos'];
      if (val_s<>nil) = (bitpos_s<>nil) then
        raise new System.InvalidOperationException;
      if (bitpos_s<>nil) and not allow_bitpos then
        raise new System.InvalidOperationException;
      
      self.is_bitpos := bitpos_s<>nil;
      self.val_s := val_s ?? bitpos_s;
    end;
    
    public static procedure InitAll(enums_ns: sequence of XmlNode);
    begin
      
      foreach var enums_n in enums_ns do
      begin
        enums_n.TryDiscardAttrib('start');
        enums_n.TryDiscardAttrib('end');
        enums_n.TryDiscardSubNodes('comment');
        
        foreach var unused_n in enums_n.SubNodes['unused'] do
        begin
          unused_n.TryDiscardAttrib('comment');
          unused_n.DiscardAttrib('start');
          unused_n.TryDiscardAttrib('end');
        end;
        
        if enums_n['vendor'] is string(var vendor) then
          VendorSuffixSource.RequireName(vendor);
        
        if enums_n['comment'] = 'Miscellaneous API constants, in cl_platform.h' then
        begin
          if enums_n['name'] <> 'Constants' then raise new System.InvalidOperationException;
          
          foreach var enum_n in enums_n.SubNodes['enum'] do
          begin
            enum_n.DiscardAttrib('value');
            if not external_enum_names.Add(enum_n['name']) then
              raise new System.InvalidOperationException;
          end;
          
        end else
        begin
          enums_n.DiscardAttrib('name');
          
          var allow_bitpos := false;
          if enums_n['type'] is string(var enums_type) then
          case enums_type of
            'bitmask': allow_bitpos := true;
            else Otp($'WARNING: Unknown enums type [{enums_type}]');
          end;
          
          foreach var enum_n in enums_n.SubNodes['enum'] do
            new EnumSource(allow_bitpos, enum_n);
        end;
        
      end;
      
    end;
    
    private group_is_throw_away := default(boolean?);
    public procedure MarkUsedFromGroup(throw_away_group: boolean);
    begin
      if group_is_throw_away = not throw_away_group then
        raise new InvalidOperationException;
      group_is_throw_away := throw_away_group;
    end;
    
    protected function MakeNewItem: Enum; override;
    
  end;
  
  {$endregion Enum}
  
  {$region BasicType}
  
  BasicTypeSource = sealed class(ItemSource<BasicTypeSource, string, BasicType>)
    
    public static redefined := new Dictionary<string, string>;
    public static enum_abusing_type_tag := new HashSet<string>;
    
    public constructor(name: string) :=
      inherited Create(name);
    
    public static function FromName(tname: string): BasicTypeSource;
    begin
      while true do
      begin
        var base: string;
        if not redefined.TryGetValue(tname, base) then break;
        tname := base;
      end;
      Result := Existing[tname];
    end;
    
    protected function MakeNewItem: BasicType; override :=
      new BasicType(self.name);
    
  end;
  
  {$endregion BasicType}
  
  {$region Group}
  
  GroupSource = sealed class(ItemSource<GroupSource, GroupName, Group>)
    private org_name, etype: string;
    private definitions := new List<XmlNode>;
    
    public static function MakeName(s: string; allow_nil, skip_invalid: boolean) :=
      ItemSourceHelpers.MakeName&<GroupName>(api, s, api, allow_nil, skip_invalid, true, VendorSuffixSource.known_suffixes, '*_e');
    
    private constructor(gr_name: GroupName; org_name, etype: string);
    begin
      inherited Create(gr_name);
      self.org_name := org_name;
      self.etype := etype;
    end;
    
    private static group_nodes := new HashSet<XmlNode>;
    public static procedure Register(gr_name: GroupName; org_name, etype: string; n: XmlNode);
    begin
      if not group_nodes.Add(n) then
        raise new InvalidOperationException;
      
      var throw_away := false;
      case etype of
        
        'constants', 'OpenCL-C only':
        begin
          if gr_name<>nil then raise new System.InvalidOperationException;
          throw_away := true;
        end;
        
        'enum', 'bitfield': ;
        'obj info', 'property list': ;
        
        else raise new System.NotImplementedException(etype);
      end;
      
      foreach var enum_n in n.SubNodes['enum'] do
      begin
        var ename := EnumSource.MakeName(enum_n['name'], false, false);
        var esource := EnumSource.FindOrMakeSource(ename, nil);
        if esource=nil then
        begin
          if etype='constants' then
            continue;
          raise new InvalidOperationException(ename.ToString);
        end;
        esource.MarkUsedFromGroup(throw_away);
      end;
      if throw_away then exit;
      
      var gr_s := FindOrMakeSource(gr_name, nil);
      if gr_s<>nil then
      begin
        if gr_s.org_name <> org_name then raise new InvalidOperationException;
        if gr_s.etype <> etype then raise new InvalidOperationException;
      end else
        gr_s := new GroupSource(gr_name, org_name, etype);
      
      gr_s.definitions += n;
    end;
    
    public static procedure InitAll(rns: sequence of XmlNode) :=
      foreach var rn in rns do
      begin
        var etype := rn['etype'];
        var gr_name := rn['group'];
        if (etype=nil) and (gr_name=nil) then continue;
        if (etype=nil) and (gr_name<>nil) then
        begin
          if 'flags' in gr_name then
            Otp($'{gr_name}: Maybe etype="bitfield"');
          if 'info' in gr_name then
            Otp($'{gr_name}: Maybe etype="obj info"');
          if 'propert' in gr_name then
            Otp($'{gr_name}: Maybe etype="property list"');
        end;
        Register(MakeName(gr_name, true, false), gr_name, etype??'enum', rn);
      end;
    
    protected function MakeNewItem: Group; override;
    
  end;
  
  {$endregion Group}
  
  {$region IdClass}
  
  IdClassSource = sealed class(ItemSource<IdClassSource, IdClassName, IdClass>)
    private base_t: string;
    private is_ptr_hungry: boolean;
    
    public static function MakeName(s: string; allow_nil, skip_invalid: boolean) :=
      ItemSourceHelpers.MakeName&<IdClassName>(api, s, api, allow_nil, skip_invalid, nil, VendorSuffixSource.known_suffixes, '*_e','*E');
    
    public constructor(name: IdClassName; base_t: string; is_ptr_hungry: boolean);
    begin
      inherited Create(name);
      self.base_t := base_t;
      self.is_ptr_hungry := is_ptr_hungry
    end;
    
    protected function MakeNewItem: IdClass; override;
    
  end;
  
  {$endregion IdClass}
  
  {$region Struct}
  
  StructSource = sealed class(ItemSource<StructSource, StructName, Struct>)
    private member_ns: array of XmlNode;
    
    public static function MakeName(s: string; allow_nil, skip_invalid: boolean) :=
      ItemSourceHelpers.MakeName&<StructName>(api, s, api, allow_nil, skip_invalid, true, VendorSuffixSource.known_suffixes, '*_e');
    
    public constructor(n: XmlNode);
    begin
      inherited Create(MakeName(n['name'], false, false));
      self.member_ns := n.SubNodes['member'].ToArray;
    end;
    
    protected function MakeNewItem: Struct; override;
    
  end;
  
  {$endregion Struct}
  
  {$region Delegate}
  
  DelegateSource = sealed class(ItemSource<DelegateSource, DelegateName, Delegate>)
    private par_ns: array of XmlNode;
    
    public static function MakeName(s: string; allow_nil, skip_invalid: boolean) :=
      ItemSourceHelpers.MakeName&<DelegateName>(api, s, api, allow_nil, skip_invalid, true, VendorSuffixSource.known_suffixes);
    
    public constructor(n: XmlNode);
    begin
      inherited Create(MakeName(n['name'], false, false));
      self.par_ns := (
        n.SubNodes['proto'].Single +
        n.SubNodes['param']
      ).ToArray;
    end;
    
    protected function MakeNewItem: Delegate; override;
    
  end;
  
  {$endregion Delegate}
  
  {$region Func}
  
  FuncSource = sealed class(ItemSource<FuncSource, FuncName, Func>)
    private entry_point_name: string;
    private par_ns: array of XmlNode;
    
    public static function MakeName(s: string; allow_nil, skip_invalid: boolean) :=
      ItemSourceHelpers.MakeName&<FuncName>(api, s, api, allow_nil, skip_invalid, false, VendorSuffixSource.known_suffixes, '*E');
    
    public constructor(name: FuncName; entry_point_name: string; par_ns: sequence of XmlNode);
    begin
      inherited Create(name);
      self.entry_point_name := entry_point_name;
      self.par_ns := par_ns.ToArray;
    end;
    
    public static procedure InitAll(commands_n: XmlNode);
    begin
      
      foreach var command_n in commands_n.SubNodes['command'] do
      begin
        command_n.TryDiscardAttrib('comment');
        command_n.TryDiscardAttrib('prefix');
        command_n.TryDiscardAttrib('suffix');
        var name := command_n.SubNodes['proto'].Single.SubNodes['name'].Single.Text;
        
        new FuncSource(MakeName(name, false, false), name,
          command_n.SubNodes['proto'] +
          command_n.SubNodes['param']
        );
        
      end;
      
    end;
    
    protected function MakeNewItem: Func; override;
    
  end;
  
  {$endregion Func}
  
  {$region Feature}
  
  FeatureSource = sealed class(ItemSource<FeatureSource, FeatureName, Feature>)
    private rns: sequence of XmlNode;
    
    public static function MakeName(s: string; allow_nil, skip_invalid: boolean): FeatureName;
    begin
      Result := nil;
      
      if s=nil then
      begin
        if not allow_nil then
          raise nil;
        exit;
      end;
      
      var m := Regex.Match(s, '^CL_VERSION_(\d+)_(\d+)$');
      if not m.Success then
      begin
        if not skip_invalid then
          raise new System.FormatException(s);
        exit;
      end;
      
      Result := new FeatureName(api, m.Groups[1].Value.ToInteger, m.Groups[2].Value.ToInteger);
    end;
    
    public constructor(name: FeatureName; rns: sequence of XmlNode);
    begin
      inherited Create(name);
      self.rns := rns;
    end;
    
    public static procedure InitAll(feature_ns: sequence of XmlNode) :=
      foreach var feature_n in feature_ns do
      begin
        if feature_n['api'] <> 'opencl' then raise new System.NotImplementedException;
        if feature_n['comment'] <> 'OpenCL core API interface definitions' then raise new System.InvalidOperationException;
        
        var name := MakeName(feature_n['name'], false, false);
        
        var number_name := FeatureName.Parse(api, feature_n['number']);
        if number_name <> name then
          raise new System.InvalidOperationException;
        
        new FeatureSource(name, feature_n.SubNodes['require']);
      end;
    
    protected function MakeNewItem: Feature; override;
    
  end;
  
  {$endregion Feature}
  
  {$region Extension}
  
  ExtensionHelpers = static class
    
    public static function MakeName(s: string; allow_nil, skip_invalid: boolean) :=
      ItemSourceHelpers.MakeName&<ExtensionName>(api, s, api, allow_nil, skip_invalid, true, VendorSuffixSource.known_suffixes, 'e_*','E_*');
    
    private static function MakeFeatureOrExtensionName(s: string): (FeatureName, ExtensionName);
    begin
      var f := FeatureSource.MakeName(s, true, true);
      Result := (f, if f<>nil then nil else ExtensionHelpers.MakeName(s, true, true));
    end;
    
  end;
  
  ExtensionDepOptionSource = sealed class
    private core_dep: FeatureName;
    private ext_deps: array of ExtensionName;
    
    public constructor(deps_s: string);
    begin
      self.core_dep := nil;
      var ext_deps_l := new List<ExtensionName>;
      
      foreach var dep_s in deps_s.Split('+') do
      begin
        var (f,e) := ExtensionHelpers.MakeFeatureOrExtensionName(dep_s);
        
        if f<>nil then
        begin
          if core_dep<>nil then
            raise new System.NotImplementedException;
          core_dep := f;
        end;
        
        if e<>nil then
          ext_deps_l += e;
        
      end;
      
      self.ext_deps := ext_deps_l.ToArray;
    end;
    
  end;
  
  ExtensionSource = sealed class(ItemSource<ExtensionSource, ExtensionName, Extension>)
    private ext_str: string;
    private rns: sequence of XmlNode;
    
    private revision: string;
    private provisional: boolean;
    
    private dep_options: array of ExtensionDepOptionSource;
    
    private obsolete_by: (FeatureName, ExtensionName);
    private promoted_to: (FeatureName, ExtensionName);
    
    public static function MakeName(s: string; allow_nil, skip_invalid: boolean) := ExtensionHelpers.MakeName(s, allow_nil, skip_invalid);
    
    public constructor(name: ExtensionName; ext_str: string; rns: sequence of XmlNode; revision, provisional, deps, obsolete_by, promoted_to: string);
    begin
      inherited Create(name);
      if name.VendorSuffix=nil then
        log.Otp($'{self}: No suffix');
      self.ext_str := ext_str;
      self.rns := rns;
      
      self.revision := revision;
      if provisional=nil then
        self.provisional := false else
      begin
        if provisional<>'true' then
          raise new NotImplementedException(provisional);
        self.provisional := true;
      end;
      
      if string.IsNullOrEmpty(deps) then
        self.dep_options := System.Array.Empty&<ExtensionDepOptionSource> else
      begin
        if '()'.Any(ch->deps.Contains(ch)) then
          // Need more complex parsing
          // Prob. convert to DNF after parsing, when it becomes needed
          raise new NotImplementedException;
        self.dep_options := deps.Split(',').ConvertAll(deps_opt->new ExtensionDepOptionSource(deps_opt));
      end;
      
      self.obsolete_by := ExtensionHelpers.MakeFeatureOrExtensionName(obsolete_by);
      self.promoted_to := ExtensionHelpers.MakeFeatureOrExtensionName(promoted_to);
      
    end;
    
    public static procedure InitAll(extensions_n: XmlNode) :=
      foreach var extension_n in extensions_n.SubNodes['extension'] do
      begin
        var name := extension_n['name'];
        
        extension_n.TryDiscardAttrib('comment');
        if extension_n['supported'] <> 'opencl' then raise new System.NotImplementedException;
        
        // Info for implementers:
        // https://github.com/KhronosGroup/OpenCL-Docs/pull/950#issuecomment-2015066665
        if extension_n['ratified'] is string(var ratified_s) then
        begin
          if ratified_s <> 'opencl' then raise new System.NotImplementedException;
        end;
        
        new ExtensionSource(MakeName(name, false, false),
          name, extension_n.SubNodes['require'],
          extension_n['revision'], extension_n['provisional'],
          extension_n['depends'],
          extension_n['obsoletedby'],
          extension_n['promotedto']
        );
      end;
    
    protected function MakeNewItem: Extension; override;
    
  end;
  
  {$endregion Extension}
  
{$region MakeNewItem}

{$region VendorSuffix}

function VendorSuffixSource.MakeNewItem :=
  new VendorSuffix(self.Name);

{$endregion VendorSuffix}

{$region Enum}

function EnumSource.MakeNewItem: Enum;
begin
  
  if is_bitpos then
  begin
    var val := int64(1) shl val_s.ToInteger;
    if val=0 then raise new System.InvalidOperationException;
    Result := new Enum(self.Name, val, false);
    exit;
  end;
  
  var val_str := self.val_s;
  
  if val_str.StartsWith('(') and val_str.EndsWith(')') then
    val_str := val_str.Substring(1, val_str.Length-2);
  
  var shift := 0;
  if '<<' in val_str then
  begin
    var a := val_str.Split(|'<<'|,2,System.StringSplitOptions.None);
    val_str := a[0].Trim;
    shift := a[1].ToInteger;
  end;
  
  var val: int64;
  try
    val := if val_str.StartsWith('0x') then
      System.Convert.ToInt64(val_str, 16) else
      System.Convert.ToInt64(val_str);
  except
    on System.FormatException do
      if val_str='SIZE_MAX' then
      begin
        val := uint64.MaxValue;
        if val<>-1 then raise new System.InvalidOperationException;
      end else
      if val_str.StartsWith('(') then
      begin
        var (tname, v) := val_str.Substring(1).Split(|')'|,2);
        if tname not in BasicTypeSource.redefined then
          Otp($'WARNING: Group [{tname}] did not have defined type of the same name');
        case v of
          '0': val := 0;
          '0 - 1': val := -1;
          else raise new System.NotImplementedException(v);
        end;
      end else
      if EnumSource.FindOrMakeItem(EnumSource.MakeName(val_str, true, false), true) is Enum(var old_e) then
        val := old_e.Value else
        raise new MessageException($'ERROR: Could not parse value [{val_str}] of {self}');
  end;
  
  Result := new Enum(self.Name, val shl shift, group_is_throw_away=true);
end;

{$endregion Enum}

{$region TypeHelper} type
  
  TypeHelper = static class
    
    public static function TypeRefFromName(tname: string; var ptr: integer): TypeRef;
    begin
      if tname=nil then raise nil;
      
      var bt := BasicTypeSource .FromName(tname);
      var gr := GroupSource     .FindOrMakeSource(GroupSource   .MakeName(tname, true, true), nil);
      var cl := IdClassSource   .FindOrMakeSource(IdClassSource .MakeName(tname, true, true), nil);
      var s :=  StructSource    .FindOrMakeSource(StructSource  .MakeName(tname, true, true), nil);
      var d :=  DelegateSource  .FindOrMakeSource(DelegateSource.MakeName(tname, true, true), nil);
      if gr<>nil then bt := nil;
      
      case Ord(bt<>nil)+Ord(gr<>nil)+Ord(cl<>nil)+Ord(s<>nil)+Ord(d<>nil) of
        0: raise new System.InvalidOperationException($'[{tname}] is not a defined type');
        1: ;
        else raise new System.NotImplementedException(tname);
      end;
      
      if (cl<>nil) and cl.is_ptr_hungry then
        ptr -= 1;
      
      if bt<>nil then Result := new TypeRef(bt.GetItem) else
      if gr<>nil then Result := new TypeRef(gr.GetItem) else
      if cl<>nil then Result := new TypeRef(cl.GetItem) else
      if s<>nil then Result := new TypeRef(s.GetItem) else
      if d<>nil then Result := new TypeRef(d.GetItem) else
        raise new System.InvalidOperationException;
      
    end;
    
    private static unreq_type_names := new HashSet<string>;
    public static procedure ReqType(tname: string);
    begin
      unreq_type_names -= tname;
      var ptr: integer;
      TypeHelper.TypeRefFromName(tname, ptr);
      // cl_icd_dispatch is ptr hungry, and it's ok
//      if ptr<>0 then raise new NotImplementedException(tname);
    end;
    public static procedure ReportAllUnreq :=
      foreach var tname in unreq_type_names do
        Otp($'WARNING: <type name="{tname}"/> was not required');
    
    public static function MakePar(name, tname, text: string; arr_size: ParArrSize): ParData;
    begin
      if arr_size <> ParArrSizeNotArray.Instance then
        text += '*';
      
      var (flat_t, ptr, readonly_lvls) := ParData.ParsePtrLvls(text);
      
      if tname not in |nil,flat_t| then
        raise new System.InvalidOperationException($'{tname}/{flat_t} ({text})');
      
      var t := TypeRefFromName(flat_t, ptr);
      
      Result := new ParData(name, t, ptr, readonly_lvls, arr_size, nil);
    end;
    
    public static procedure InitNode(type_n: XmlNode);
    begin
      type_n.TryDiscardAttrib('comment');
      var category := type_n['category'];
      
      case category of
        
        'include':
        begin
          var name := type_n['name'];
          
          if type_n.Text.StartsWith('#include ') then exit;
          if type_n.Text<>'' then
            raise new System.InvalidOperationException($'[{type_n.Text}]');
          type_n.TryDiscardAttrib('requires');
          
          new BasicTypeSource(name);
        end;
        
        'basetype':
        begin
          if type_n['requires'] <> 'CL/cl_platform.h' then
            raise new System.NotImplementedException(type_n['requires']);
          var tname := type_n['name'];
          unreq_type_names += tname;
          new BasicTypeSource(tname);
        end;
        
        'define':
        if type_n.Text.StartsWith('typedef ') then
        begin
          if 'const' in type_n.Text then
            raise new System.NotImplementedException(type_n.Text);
          
          var base_t := type_n.SubNodes['type'].SingleOrDefault?.Text;
          var name := type_n.SubNodes['name'].Single.Text;
          unreq_type_names += name;
          var base_ptr := type_n.Text.CountOf('*');
          
          if type_n.Text.StartsWith('typedef struct _') or (base_t='void') then
          begin
            var is_ptr_hungry: boolean;
            case base_ptr of
              1: is_ptr_hungry := false;
              0: is_ptr_hungry := true;
              else raise new System.InvalidOperationException;
            end;
            new IdClassSource(IdClassSource.MakeName(name, false, false), 'intptr_t', is_ptr_hungry);
          end else
          begin
            
            if base_ptr<>0 then
              raise new InvalidOperationException;
            if (type_n['requires'] <> nil) and (BasicTypeSource[base_t] = nil) then
              raise new InvalidOperationException($'{name}');
            
            BasicTypeSource.redefined.Add(name, base_t);
          end;
          
        end else
        if type_n.Text.StartsWith('#define ') then
        begin
          var tname := type_n.SubNodes['name'].Single.Text;
          unreq_type_names += tname;
          if not BasicTypeSource.enum_abusing_type_tag.Add(tname) then
            raise new System.InvalidOperationException;
        end else
          Otp($'WARNING: Cannot parse define: {type_n.Text}');
        
        'struct':
        begin
          unreq_type_names += type_n['name'];
          new StructSource(type_n);
        end;
        
        'function':
        begin
          unreq_type_names += type_n['name'];
          new DelegateSource(type_n);
        end;
        
        else Otp($'WARNING: Unexpected type category [{category}]');
      end;
      
    end;
    
    public static procedure InitAll(types_n: XmlNode);
    begin
      types_n.DiscardAttrib('comment');
      types_n.TryDiscardSubNodes('comment');
      
      foreach var type_n in types_n.SubNodes['type'] do
        InitNode(type_n);
      
    end;
    
  end;
  
{$endregion TypeHelper}

{$region Group}

function GroupSource.MakeNewItem: Group;
begin
  var node_by_enum := new Dictionary<Enum, XmlNode>;
  
  foreach var rn in self.definitions do
  begin
    var new_enums := new HashSet<Enum>;
    foreach var enum_n in rn.SubNodes['enum'] do
    begin
      var ename := enum_n['name'];
      if ename in EnumSource.external_enum_names then
        continue;
      var e := EnumSource.FindOrMakeItem(EnumSource.MakeName(ename,false,false), false);
      if not new_enums.Add(e) then
        Otp($'WARNING: {e} was added twice in the same RN') else
      if e not in node_by_enum then
        node_by_enum.Add(e, enum_n) else
      begin
        if node_by_enum[e]['input_type']  <> enum_n['input_type'] then raise new System.InvalidOperationException('1');
        if node_by_enum[e]['info_type']   <> enum_n['info_type'] then raise new System.InvalidOperationException('2');
        if node_by_enum[e]['terminate']   <> enum_n['terminate'] then raise new System.InvalidOperationException('3');
        if node_by_enum[e]['followed']    <> enum_n['followed'] then raise new System.InvalidOperationException('4');
      end;
    end;
  end;
  
  var make_enum_extra_type := function(t: string; sz: ParArrSize): ParData ->(
    if t=nil then nil else TypeHelper.MakePar(nil, t.TrimEnd('*'), t, sz)
  );
  
  var make_enum_simple_extra_type := function(t: string): ParData ->
    make_enum_extra_type(t, ParArrSizeNotArray.Instance);
  var make_enum_sized_extra_type := function(t: string; context: Enum): ParData ->
  begin
    Result := nil;
    if t=nil then exit;
    if t='char[]' then
      t := t;
    var sz := default(ParArrSize);
    if t.EndsWith(']') then
    begin
      var sz_s: string;
      (t, sz_s) := t.Remove(t.Length-1).Split(|'['|,2);
      if sz_s='' then
      begin
        if t='void' then
        begin
          log.Otp($'{context}: "void[]" extra type');
          exit; // No type info instead of "void[]"
        end;
        sz := ParArrSizeArbitrary.Instance;
      end else
      if sz_s.IsInteger then
        sz := new ParArrSizeConst(sz_s.ToInteger) else
      if EnumSource.FindOrMakeItem(EnumSource.MakeName(sz_s,true,false), true) is Enum(var old_e) then
        sz := new ParArrSizeConst(old_e.Value) else
        raise new System.FormatException(sz_s);
    end else
      sz := ParArrSizeNotArray.Instance;
    Result := make_enum_extra_type(t, sz);
  end;
  
  var enums := default(EnumsInGroup);
  case self.etype of
    
    'enum', 'bitfield':
      enums := new SimpleEnumsInGroup(self.etype='bitfield', node_by_enum.Keys.ToArray);
    
    'obj info':
    begin
      var r_lst := new List<EnumWithObjInfo>(node_by_enum.Count);
      foreach var e in node_by_enum.Keys do
      begin
        var n := node_by_enum[e];
        var inp_t := make_enum_sized_extra_type(n['input_type'], e);
        var otp_t := make_enum_sized_extra_type(n['info_type'], e);
        r_lst += new EnumWithObjInfo(e, inp_t, otp_t);
      end;
      enums := new ObjInfoEnumsInGroup(r_lst.ToArray);
    end;
    
    'property list':
    begin
      var raw_lst := new List<ValueTuple<Enum,ParData>>(node_by_enum.Count);
      var term_by := new Dictionary<Enum,Enum>(node_by_enum.Count div 2);
      var global_term := new List<Enum>;
      
      foreach var e in node_by_enum.Keys do
      begin
        var n := node_by_enum[e];
        var followed_s := n['followed'];
        var terminate_s := n['terminate'];
        
        if (terminate_s=nil) = (followed_s=nil) then
          raise new InvalidOperationException(e.ToString);
        
        match terminate_s with
          
          nil:
          begin
            var followed := make_enum_simple_extra_type(followed_s);
            raw_lst += ValueTuple.Create(e, followed);
          end;
          
          '': global_term += e;
          
          else
          begin
            var terminate_e := EnumSource.FindOrMakeItem(EnumSource.MakeName(terminate_s,false,false), false);
            term_by.Add(terminate_e, e);
          end;
        end;
        
      end;
      
      var r_lst := new List<EnumWithPropList>(raw_lst.Count);
      foreach var (e, t) in raw_lst do
        r_lst += new EnumWithPropList(e, t, term_by.Get(e));
      
      enums := new PropListEnumsInGroup(r_lst.ToArray, global_term.ToArray);
    end;
    
    else raise new NotImplementedException(etype);
  end;
  
  var val_type_s := BasicTypeSource.FromName(org_name);
  if val_type_s=nil then
    raise nil;
  var val_type := val_type_s.GetItem;
  
  var res_name := new GroupName(self.Name.ApiName, self.Name.VendorSuffix,
    self.Name.LocalName.Split('_').SelectMany(w->w.First.ToUpper+w.Skip(1)).JoinToString
  );
  Result := new Group(res_name, |val_type|, enums);
end;

{$endregion Group}

{$region IdClass}

function IdClassSource.MakeNewItem :=
  new IdClass(self.Name, |BasicTypeSource.FromName(self.base_t).GetItem|);

{$endregion IdClass}

{$region Struct}

function StructSource.MakeNewItem: Struct;
begin
  
  var fields := member_ns.ConvertAll(member_n->
  begin
    var text := member_n.Text;
    var name := member_n.SubNodes['name'].SingleOrDefault?.Text;
    var tname := member_n.SubNodes['type'].SingleOrDefault?.Text;
    
    if (name=nil) and (tname=nil) then
    begin
      if text.Split(#10).Select(l->l.Trim).SequenceEqual(|
        'union {',
          'cl_mem buffer;',
          'cl_mem mem_object;',
        '}'
      |) then
      begin
        Result := new ParData('mem_object', new TypeRef(IdClassSource[IdClassSource.MakeName('cl_mem',false,false)].GetItem), 0, new integer[0], ParArrSizeNotArray.Instance, nil);
        exit;
      end;
      raise new System.InvalidOperationException(self.ToString+text.Split(#10).Select(l->#10+l.Trim).JoinToString(''));
    end;
    
    var len := default(ParArrSize);
    if member_n.SubNodes['enum'].SingleOrDefault?.Text is string(var static_len_enum_name) then
    begin
      var text_end := $'[{static_len_enum_name}]';
      if not text.EndsWith(text_end) then raise new System.InvalidOperationException;
      text := text.RemoveEnd(text_end);
      len := new ParArrSizeConst(EnumSource.FindOrMakeItem(EnumSource.MakeName(static_len_enum_name, false, false), false).Value);
    end else
      len := ParArrSizeNotArray.Instance;
    
    if '[]'.Any(ch->ch in text) then
      raise new System.InvalidOperationException;
    
    Result := TypeHelper.MakePar(name, tname, text.RemoveEnd(name).TrimEnd, len);
  end);
  
  Result := new Struct(self.Name, fields);
end;

{$endregion Struct}

{$region Delegate}

function DelegateSource.MakeNewItem: Delegate;
begin
  
  var pars := par_ns.ConvertAll((par_n,par_i)->
  begin
    var par_name := if par_i=0 then nil else
      par_n.SubNodes['name'].Single.Text;
    var text := par_n.Text;
    
    var len := default(ParArrSize);
    var par_arr_str := '[]';
    if text.EndsWith(par_arr_str) then
    begin
      text := text.RemoveEnd(par_arr_str);
//      len := ParArrSizeArbitrary.Instance;
      len := ParArrSizeNotArray.Instance;
      text := text.RemoveEnd(par_name).TrimEnd+'*';
    end else
    begin
      len := ParArrSizeNotArray.Instance;
      if par_name<>nil then
        text := text.RemoveEnd(par_name).TrimEnd;
    end;
    
    Result := TypeHelper.MakePar(par_name, par_n.SubNodes['type'].Single.Text, text, len);
  end);
  
  var res_name := new DelegateName(self.Name.ApiName, self.Name.VendorSuffix,
    self.Name.LocalName.Split('_').SelectMany(w->w.First.ToUpper+w.Skip(1)).JoinToString
  );
  Result := new Delegate(res_name, pars);
end;

{$endregion Delegate}

{$region Func}

function FuncSource.MakeNewItem: Func;
begin
  
  var pars := par_ns.ConvertAll((par_n,par_i)->
  begin
    var par_name := par_n.SubNodes['name'].Single.Text;
    var text := par_n.Text;
    
    var len := default(ParArrSize);
    var par_arr_str := '[]';
    if text.EndsWith(par_arr_str) then
    begin
      len := ParArrSizeArbitrary.Instance;
      text := text.RemoveEnd(par_arr_str);
    end else
      len := ParArrSizeNotArray.Instance;
    
    text := text.RemoveEnd(par_name).TrimEnd;
    if par_i=0 then par_name := nil;
    Result := TypeHelper.MakePar(par_name, par_n.SubNodes['type'].Single.Text, text, len);
  end);
  
  Result := new Func(self.Name, self.entry_point_name, pars, nil);
  
  var need_err_ret_count: integer;
  if self.Name.LocalName.StartsWith('LogMessagesTo') and (self.Name.VendorSuffix='APPLE') then
    need_err_ret_count := 0 else
  if self.Name.LocalName.StartsWith('SVM') then
    need_err_ret_count := 0 else
  if self.Name.LocalName.StartsWith('GetExtensionFunctionAddress') then
    need_err_ret_count := 0 else
  if self.Name = FuncSource.MakeName('clCreateProgramWithBinary', false, false) then
    need_err_ret_count := 2 else
    need_err_ret_count := 1;
  
  var err_code_gr := GroupSource.FindOrMakeItem(GroupSource.MakeName('cl_error_code',false,false), false);
  var err_ret_count := pars.Count(par->par.ParType.TypeObj = err_code_gr);
  
  if err_ret_count<>need_err_ret_count then
    Otp($'WARNING: {Result} was expected to have {need_err_ret_count} err return parameters, but found {err_ret_count}');
  
end;

{$endregion Func}

{$region RequreNodeHelper} type
  
  RequreNodeHelper = static class
    
    public static function MakeRL(rns: sequence of XmlNode; debug_descr: ()->string): RequiredList;
    begin
      Result := new RequiredList;
      var used_type_names := new HashSet<string>;
      var req_type_names := new HashSet<string>;
      
      foreach var rn in rns do
      begin
        var processed_node_types := new HashSet<string>;
        
        {$region type}
        foreach var type_n in rn.SubNodes['type'] do
        begin
          processed_node_types += 'type';
          type_n.TryDiscardAttrib('comment');
          
          var name := type_n['name'];
          if name.EndsWith('.h') then continue;
          if name in BasicTypeSource.enum_abusing_type_tag then continue;
          
          TypeHelper.ReqType(name);
          if not req_type_names.Add(name) then
            raise new InvalidOperationException;
        end;
        {$endregion type}
        
        {$region enum}
        if rn['group'] is string(var group) then
          used_type_names += group;
        foreach var enum_n in rn.SubNodes['enum'] do
        begin
          processed_node_types += 'enum';
          enum_n.TryDiscardAttrib('comment');
          var ename := enum_n['name'];
          if ename in EnumSource.external_enum_names then
            continue;
          var esource := EnumSource.FindOrMakeSource(EnumSource.MakeName(ename, false, false), nil);
//          if esource.group_is_throw_away=true then continue;
          Result.enums += esource.GetItem;
          used_type_names += |enum_n['followed'],enum_n['info_type'],enum_n['input_type']|.Where(tname->tname<>nil).Select(tname->tname.TrimEnd('[]*'.ToCharArray));
        end;
        if ('enum' in processed_node_types) <> (rn in GroupSource.group_nodes) then
          raise new System.InvalidOperationException($'{rn in GroupSource.group_nodes}: '+rn.SubNodes['enum'].Select(n->n['name']).JoinToString);
        {$endregion enum}
        
        {$region func}
        foreach var func_n in rn.SubNodes['command'] do
        begin
          processed_node_types += 'func';
          func_n.TryDiscardAttrib('comment');
          func_n.TryDiscardAttrib('requires');
          
          var name := func_n['name'];
          Result.funcs += FuncSource.FindOrMakeItem(FuncSource.MakeName(name, false, false), false);
          
        end;
        {$endregion func}
        
        case processed_node_types.Count of
          0: raise new System.InvalidOperationException(rn['comment'] ?? rn.SubNodes['enum'].Select(n->n['name']).JoinToString ?? 'no comment');
          1: ;
          else raise new System.NotImplementedException(processed_node_types.JoinToString);
        end;
        
        rn.TryDiscardAttrib('depends'); //TODO Use this to display a comment in generated files
        rn.TryDiscardAttrib('comment');
        rn.TryDiscardAttrib('condition');
        rn.TryDiscardSubNodes('comment');
      end;
      
      //TODO Uncomment
      // types defined in cl1.0 don't need to be redefined in cl1.1
      // types like "char" don't need to be defined ever
//      foreach var tname in used_type_names do
//      begin
//        if tname in req_type_names then continue;
//        Otp($'WARNING: ({debug_descr}) Type [{tname}] was used, but not required');
//      end;
//      
//      foreach var tname in req_type_names do
//      begin
//        if tname in used_type_names then continue;
//        Otp($'WARNING: ({debug_descr}) Type [{tname}] was required, but not used');
//      end;
      
    end;
    
  end;
  
{$endregion RequreNodeHelper}

{$region Feature}

function FeatureSource.MakeNewItem :=
  new Feature(self.Name,
    RequreNodeHelper.MakeRL(self.rns, self.ToString),
    new RequiredList
  );

{$endregion Feature}

{$region Extension}

function ExtensionSource.MakeNewItem :=
  new Extension(self.Name, self.ext_str,
    RequreNodeHelper.MakeRL(self.rns, self.ToString),
    
    self.revision, self.provisional,
    
    self.dep_options.ConvertAll(dep_opt->new ExtensionDepOption(
      FeatureSource.FindOrMakeItem(dep_opt.core_dep, true),
      dep_opt.ext_deps.ConvertAll(name->ExtensionSource.FindOrMakeItem(name, false))
    )),
    
    (FeatureSource.FindOrMakeItem(self.obsolete_by[0], true), ExtensionSource.FindOrMakeItem(self.obsolete_by[1], true)),
    (FeatureSource.FindOrMakeItem(self.promoted_to[0], true), ExtensionSource.FindOrMakeItem(self.promoted_to[1], true))
    
  );

{$endregion Extension}

{$endregion MakeNewItem}

procedure ScrapXmlFile(api_name: string);
begin
  Otp($'Parsing "{api_name}"');
  var root := ScrapUtils.GetXml(api_name);
  root.TryDiscardSubNodes('comment');
  
  VendorSuffixSource.InitAll;
  
  EnumSource.InitAll(root.SubNodes['enums']);
  
  TypeHelper.InitAll(root.SubNodes['types'].Single);
  
  GroupSource.InitAll(
    (root.SubNodes['feature'] + root.SubNodes['extensions'].Single.SubNodes['extension'])
    .SelectMany(n->n.SubNodes['require'])
  );
  
  FuncSource.InitAll(root.SubNodes['commands'].Single);
  
  FeatureSource.InitAll(root.SubNodes['feature']);
  
  ExtensionSource.InitAll(root.SubNodes['extensions'].Single);
  
end;

begin
  try
    ScrapUtils.Init('OpenCL-Docs');
    
    ScrapXmlFile(api);
    
    ItemSources.CreateAll;
    
    XMLItems.SaveAll;
    //TODO Uncomment
//    TypeHelper.ReportAllUnreq;
    
    Otp($'Done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.