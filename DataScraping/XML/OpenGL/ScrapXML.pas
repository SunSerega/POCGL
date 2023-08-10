uses System;

uses '../../../Utils/AOtp';

uses '../../../POCGL_Utils';

uses '../ScrapUtils';
uses '../XMLUtils';
//
uses '../XMLItems';
uses '../ItemSources';

var log_missing_ptype := new FileLogger(GetFullPathRTA('missing_ptype.log'));
var log_naked_enums := new FileLogger(GetFullPathRTA('naked_enums.log'));

type
  LogCache = static class
    static missing_ptype                := new HashSet<string>;
    static naked_enums                  := new HashSet<string>;
    
    static kinds_undescribed            := new HashSet<string>;
    static kinds_unutilised             := new HashSet<string>;
    static invalid_type_for_group       := new HashSet<string>;
    static missing_group                := new HashSet<GroupName>;
    
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
        var (name, suffixes) := spl;
        
        if name<>'' then
        begin
          if not known_names.Add(name) then
            raise new InvalidOperationException(name);
        end;
        
        if suffixes='' then continue;
        foreach var suffix in suffixes.Split('/') do
        begin
          if suffix.Trim<>suffix then
            raise new FormatException(suffix);
          if (name<>'Oculus') and not suffix.StartsWith(name) then
            raise new InvalidOperationException((suffix,name).ToString);
          new VendorSuffixSource(suffix);
          known_suffixes += suffix;
        end;
        
      end;
    
    protected function MakeNewItem: VendorSuffix; override;
    
  end;
  
  {$endregion VendorSuffix}
  
  {$region Delegate}
  
  DelegateSource = sealed class(ItemSource<DelegateSource, DelegateName, Delegate>)
    private context_api, org_name, text: string;
    
    public static function MakeName(api, name: string; allow_nil: boolean): DelegateName;
    begin
      if name='__GLXextFuncPtr' then
        name := name.TrimStart('_');
      Result := inherited MakeName&<DelegateName>(api, name, api, allow_nil, false, VendorSuffixSource.known_suffixes, '*E','e*');
    end;
    
    public constructor(api, name, text: string);
    begin
      inherited Create(MakeName(api, name, false));
      self.context_api := api;
      self.org_name := name;
      self.text := text;
    end;
    
    protected function MakeNewItem: Delegate; override;
    
  end;
  
  {$endregion Delegate}
  
  {$region BasicType}
  
  BasicTypeSource = sealed class(ItemSource<BasicTypeSource, string, BasicType>)
    
    private static defined_per_file := new Dictionary<string, HashSet<string>>;
    public static function TryDefine(file_api, name: string): BasicTypeSource;
    begin
      
      var file_def: HashSet<string>;
      if not defined_per_file.TryGetValue(file_api, file_def) then
      begin
        file_def := new HashSet<string>;
        defined_per_file.Add(file_api, file_def);
      end;
      
      if not file_def.Add(name) then
        raise new InvalidOperationException;
      // types like GLbitfield are defined in multiple .xml files
      Result := FindOrMakeSource(name, name->new BasicTypeSource(name));
    end;
    
    static constructor;
    begin
      TryDefine('', 'void');
    end;
    
    protected function MakeNewItem: BasicType; override;
    
  end;
  
  {$endregion BasicType}
  
  {$region Kind}
  
  Kind = static class
    private static defined := new Dictionary<string, string>;
    private static mentioned := new HashSet<string>;
    
    public static procedure InitAll(kinds_n: XmlNode) :=
      foreach var kind_n in kinds_n.Nodes['kind'] do
      begin
        var name := kind_n['name'];
        var desc := kind_n['desc'];
        if string.IsNullOrWhiteSpace(desc) then
          raise new InvalidOperationException($'Kind [{name}] does not have description');
        if name not in defined then
          defined.Add(name, desc) else
        if desc <> defined[name] then
          Otp($'WARNING: Kind [{name}] is defined multiple times with different descriptions');
      end;
    
    public static procedure Require(name: string) :=
      if name in defined then
        mentioned += name else
      if LogCache.kinds_undescribed.Add(name) then
        log.Otp($'Using unsupported Kind [{name}]');
    
  end;
  
  {$endregion Kind}
  
  {$region Group}
  
  GroupSource = sealed class(ItemSource<GroupSource, GroupName, Group>)
    private enum_names := new Dictionary<EnumName, boolean>; // value = is_bitfield
    
    private castable_to_names := new HashSet<string>;
    
    public static function MakeName(api, name: string; for_lookup: boolean): GroupName;
    begin
      Result := nil;
      if name=nil then exit;
      
      var api_sep_ind := name.IndexOf('::');
      if api_sep_ind<>-1 then
      begin
        if not for_lookup and (api = name.Remove(api_sep_ind)) then
          raise new InvalidOperationException(name);
        api := name.Remove(api_sep_ind);
        name := name.Substring(api_sep_ind+2);
      end;
      
      Result := inherited MakeName&<GroupName>(api, name, '', false, false, VendorSuffixSource.known_suffixes, '*E');
    end;
    
    public static procedure Register(api,name: string; is_bitfield: boolean; ename: EnumName);
    begin
      var gr_s := FindOrMakeSource(MakeName(api, name, false), gr_name->new GroupSource(gr_name));
      
      if ename in gr_s.enum_names then
        Otp($'Enum [{ename}] had {gr_s} multiple times') else
        gr_s.enum_names.Add(ename, is_bitfield);
      
    end;
    
    public static function UseAs(name: GroupName; t: string): GroupSource;
    begin
      Result := FindOrMakeSource(name, nil);
      if name=nil then exit;
      if Result=nil then raise new InvalidOperationException($'Group [{name}] not defined');
      Result.castable_to_names += t;
    end;
    
    protected function MakeNewItem: Group; override;
    
  end;
  
  {$endregion Group}
  
  {$region Enum}
  
  EnumSource = sealed class(ItemSource<EnumSource, EnumName, Enum>)
    private val_s, alias_s: string;
    
    public static function MakeName(own_api, l_name, context_api: string; for_lookup: boolean): EnumName;
    begin
      own_api := own_api??context_api;
      if l_name='__GLX_NUMBER_EVENTS' then
        l_name := l_name.TrimStart('_');
      
      var api_beg := context_api;
      if (context_api='wgl') and l_name.StartsWith('ERROR') then
        api_beg := '';
      
      Result := inherited MakeName&<EnumName>(own_api, l_name, api_beg, for_lookup, api_beg<>'', VendorSuffixSource.known_suffixes, '*_E');
      if Result=nil then exit;
      
      if not for_lookup then exit;
      if FindOrMakeSource(Result, nil) <> nil then exit;
      
      if own_api in |'gles1', 'gles2', 'glsc2'| then
      begin
        Result := inherited MakeName&<EnumName>('gl', l_name, api_beg, for_lookup, api_beg<>'', VendorSuffixSource.known_suffixes, '*_E');
      end;
      
    end;
    
    public constructor(name: EnumName; val_s, alias_s: string);
    begin
      inherited Create(name);
      self.val_s := val_s;
      self.alias_s := alias_s;
    end;
    
    public static procedure InitAll(api: string; enums_ns: sequence of XmlNode) :=
      foreach var enums_n in enums_ns do
      begin
        enums_n.DiscardAttribute('namespace');
        enums_n.DiscardAttribute('comment');
        enums_n.DiscardAttribute('group');
        enums_n.DiscardAttribute('start');
        enums_n.DiscardAttribute('end');
        
        if enums_n['vendor'] is string(var vendors_s) then
          foreach var vendor_s in vendors_s.Split('/') do
            VendorSuffixSource.RequireName(vendor_s);
        
        foreach var unused_n in enums_n.Nodes['unused'] do
        begin
          unused_n.DiscardAttribute('comment');
          unused_n.DiscardAttribute('start');
          unused_n.DiscardAttribute('end');
          if unused_n['vendor'] is string(var vendor_s) then
            VendorSuffixSource.RequireName(vendor_s);
        end;
        
        var enums_are_bitfields := false;
        if enums_n['type'] is string(var etype) then
        case etype of
          'bitmask': enums_are_bitfields := true;
            else raise new System.NotImplementedException(etype);
          end;
          
        foreach var enum_n in enums_n.Nodes['enum'] do
        begin
          enum_n.DiscardAttribute('comment');
          
          var flat_ename := enum_n['name'];
          if flat_ename='GLX_EXTENSION_NAME' then
          begin
            enum_n.DiscardAttribute('value');
            continue; // #define GLX_EXTENSION_NAME "GLX"
          end;
          var ename := EnumSource.MakeName(enum_n['api'], flat_ename, api, false);
          
          // <enum value="0xFFFFFFFF" name="GL_INVALID_INDEX" type="u" comment="Tagged as uint" group="SpecialNumbers"/>
          // Only found in SpecialNumbers
          var forced_cast_type := enum_n['type'];
          
          if enum_n['group'] is string(var groups_s) then
            foreach var group_s in groups_s.Split(',') do
            begin
              if group_s='SpecialNumbers' then
              begin
                //TODO Use properly
                log.Otp($'Enum "{ename}" was in SpecialNumbers');
                continue;
              end;
              
              if forced_cast_type<>nil then
                raise new System.InvalidOperationException;
              
              GroupSource.Register(api, group_s, enums_are_bitfields, ename);
            end;
          
          new EnumSource(ename, enum_n['value'], enum_n['alias']);
        end;
        
      end;
    
    protected function MakeNewItem: Enum; override;
    
  end;
  
  {$endregion Enum}
  
  {$region IdClass}
  
  IdClassSource = sealed class(ItemSource<IdClassSource, IdClassName, IdClass>)
    private castable_to_names := new HashSet<string>;
    
    public static extra_defined := new HashSet<IdClassName>;
    
    public static function MakeName(api, name: string) := if (name=nil) or name.StartsWith('_') then nil else
      inherited MakeName&<IdClassName>(api, name, '', false, false, VendorSuffixSource.known_suffixes);
    
    public static function UseAs(name: IdClassName; t: string): IdClassSource;
    begin
      Result := FindOrMakeSource(name, name->new IdClassSource(name));
      if name=nil then exit; // Result=nil only if name=nil
      Result.castable_to_names += t;
    end;
    
    protected function MakeNewItem: IdClass; override;
    
  end;
  
  {$endregion IdClass}
  
  {$region FuncParam}
  
  FuncParamSource = sealed class
    private name: string;
    private context_api, func_descr: string;
    
    private tname: string;
    private ptr: integer;
    private readonly_lvls: array of integer;
    
    private gr_source: GroupSource;
    private cl_source: IdClassSource;
    private len_s: string;
    private kinds_s: string;
    
    public constructor(api, func_descr: string; n: XmlNode);
    begin
      self.name := n.Nodes['name'].Single.Text;
      self.context_api := api;
      self.func_descr := func_descr;
      
      if '[]'.Any(ch->ch in n.Text) then
        raise new NotSupportedException;
      
      (tname, ptr, readonly_lvls) := ParData.ParsePtrLvls(n.Text.RemoveEnd(name));
      
      if n.Nodes['ptype'].SingleOrDefault?.Text is string(var ptype) then
      begin
        if ptype <> tname then
          raise new System.InvalidOperationException;
      end else
      if tname<>'void' then
      begin
        var par_descr := $'{func_descr}: Param [{name}]';
        if LogCache.missing_ptype.Add(par_descr) then
          log_missing_ptype.Otp($'{par_descr} was missing <ptype> for Type [{tname}]');
        BasicTypeSource.FindOrMakeSource(tname, tname->BasicTypeSource.TryDefine(api,tname));
      end;
      
      self.gr_source := GroupSource.UseAs(GroupSource.MakeName(api, n['group'], true), tname);
      self.cl_source := IdClassSource.UseAs(IdClassSource.MakeName(api, n['class']), tname);
      self.len_s := n['len'];
      self.kinds_s := n['kind'];
      
    end;
    
    public function MakeNewItem(need_name: boolean; par_ind: string->integer): ParData;
    
  end;
  
  {$endregion FuncParam}
  
  {$region Func}
  
  FuncSource = sealed class(ItemSource<FuncSource, FuncName, Func>)
    private entry_point_name: string;
    private pars_source := new List<FuncParamSource>;
    private alias_name: FuncName;
    
    public static function MakeName(api, name: string; allow_nil: boolean): FuncName;
    begin
      Result := nil;
      if name=nil then
      begin
        if not allow_nil then
          raise nil;
        exit;
      end;
      
      var api_beg := api;
      if (api='wgl') and not name.ToLower.StartsWith(api) then
      begin
        api_beg := '';
        api := 'gdi';
      end;
      
      Result := inherited MakeName&<FuncName>(api, name, api_beg, false, false, VendorSuffixSource.known_suffixes, '*E');
    end;
    private constructor(api: string; n: XmlNode);
    begin
      inherited Create(MakeName(api, n.Nodes['proto'].Single.Nodes['name'].Single.Text, false));
      n.DiscardAttribute('comment');
      n.DiscardNodes('glx'); // GLX protocol
      
      self.entry_point_name := n.Nodes['proto'].Single.Nodes['name'].Single.Text;
      
      foreach var par_n in n.Nodes['proto']+n.Nodes['param'] do
        self.pars_source += new FuncParamSource(api, self.ToString, par_n);
      
      self.alias_name := MakeName(api, n.Nodes['alias'].SingleOrDefault?.Attribute['name'], true);
      
      var vec_equiv_n := n.Nodes['vecequiv'].SingleOrDefault;
      if vec_equiv_n<>nil then vec_equiv_n.Discard; // Not useful
      
    end;
    
    public static procedure InitAll(api: string; commands_n: XmlNode);
    begin
      if commands_n['namespace'] <> api.ToUpper then
        raise new InvalidOperationException;
      
      foreach var command_n in commands_n.Nodes['command'] do
        new FuncSource(api, command_n);
      
    end;
    
    public function MakeNewItem: Func; override;
    
  end;
  
  {$endregion Func}
  
  {$region RequiredList}
  
  RequiredListSource = record
    private enum_names := new List<EnumName>;
    private func_names := new List<FuncName>;
    
    public constructor(file_api: string; rns: sequence of XmlNode) :=
      foreach var rn in rns do
      begin
        
        match rn['profile'] with
          nil, 'core', 'compatibility': ;
          'common': ; //TODO Used only once... Prob should be core?
          else raise new InvalidOperationException(rn['profile']);
        end;
        
        foreach var type_n in rn.Nodes['type'] do
        begin
          var tname := type_n['name'];
          if BasicTypeSource.FindOrMakeSource(tname, nil) = nil then
            raise new InvalidOperationException(tname);
        end;
        
        foreach var enum_n in rn.Nodes['enum'] do
        begin
          var ename := enum_n['name'];
          // #define GLX_EXTENSION_NAME "GLX"
          if ename='GLX_EXTENSION_NAME' then continue;
          enum_names += EnumSource.MakeName(rn['api'], ename, file_api, true);
        end;
        
        foreach var func_n in rn.Nodes['command'] do
        begin
          var fname := func_n['name'];
          func_names += FuncSource.MakeName(file_api, fname, false);
        end;
        
      end;
    
    public function MakeNewItem: RequiredList;
    
  end;
  
  {$endregion RequiredList}
  
  {$region Feature}
  
  FeatureSource = sealed class(ItemSource<FeatureSource, FeatureName, Feature>)
    private add, rem: RequiredListSource;
    
    public static procedure InitAll(file_api: string; feature_ns: sequence of XmlNode) :=
      foreach var feature_n in feature_ns do
      begin
        var api := feature_n['api'];
        var name := FeatureName.Parse(api, feature_n['number']);
        
        var expected_verb_name := default(string);
        case api of
          'gl': expected_verb_name := $'GL_VERSION_{name.Major}_{name.Minor}';
          'wgl': expected_verb_name := $'WGL_VERSION_{name.Major}_{name.Minor}';
          'glx': expected_verb_name := $'GLX_VERSION_{name.Major}_{name.Minor}';
          'glsc2': expected_verb_name := $'GL_SC_VERSION_{name.Major}_{name.Minor}';
          'gles1': expected_verb_name := $'GL_VERSION_ES_CM_{name.Major}_{name.Minor}';
          'gles2': expected_verb_name := $'GL_ES_VERSION_{name.Major}_{name.Minor}';
          else raise new NotSupportedException(feature_n['api']);
        end;
        if feature_n['name'] <> expected_verb_name then
          raise new InvalidOperationException;
        
        var add_ns := feature_n.Nodes['require'];
        var rem_ns := feature_n.Nodes['remove'];
        
        foreach var rn in add_ns+rem_ns do
        begin
          rn.DiscardAttribute('comment');
          foreach var type_n in rn.Nodes['type']+rn.Nodes['enum'] do
            type_n.DiscardAttribute('comment');
        end;
        
        var f := new FeatureSource(name);
        f.add := new RequiredListSource(file_api, add_ns);
        f.rem := new RequiredListSource(file_api, rem_ns);
      end;
    
    protected function MakeNewItem: Feature; override;
    
  end;
  
  {$endregion Feature}
  
  {$region Extension}
  
  ExtensionSource = sealed class(ItemSource<ExtensionSource, ExtensionName, Extension>)
    private ext_str: string;
    private add: RequiredListSource;
    
    public static function MakeName(own_api, name, context_api: string; allow_nil: boolean) :=
      inherited MakeName&<ExtensionName>(own_api, name, context_api, allow_nil, true, VendorSuffixSource.known_suffixes, 'e_*','E_*');
    
    public static procedure InitAll(file_api: string; extensions_n: XmlNode) :=
      foreach var extension_n in extensions_n.Nodes['extension'] do
      begin
        extension_n.DiscardAttribute('comment');
        extension_n.DiscardAttribute('protect');
        var name := extension_n['name'];
        
        var add_ns := extension_n.Nodes['require'];
        
        foreach var rn in add_ns do
        begin
          rn.DiscardAttribute('comment');
          foreach var type_n in rn.Nodes['command']+rn.Nodes['enum'] do
            type_n.DiscardAttribute('comment');
        end;
        
        var apis := extension_n['supported'].ToWords('|').ToList;
        if apis.SequenceEqual(|'disabled'|) then
        begin
          extension_n.DiscardNodes('require');
          continue;
        end;
        if apis.Remove('glcore') and ('gl' not in apis) then
          raise new System.InvalidOperationException(name);
        if apis.Count=0 then raise new System.InvalidOperationException(name);
        
        foreach var api in apis do
        begin
          var ext := new ExtensionSource(MakeName(api, name, file_api, false));
          ext.ext_str := name;
          ext.add := new RequiredListSource(file_api, add_ns.Where(rn->rn['api'] in |nil,api|));
        end;
        
      end;
    
    protected function MakeNewItem: Extension; override;
    
  end;
  
  {$endregion Extension}
  
{$region MakeNewItem}

{$region VendorSuffix}

function VendorSuffixSource.MakeNewItem :=
  new VendorSuffix(self.Name);

{$endregion VendorSuffix}

{$region TypeHelper} type
  
  TypeHelper = static class
    
    public static procedure InitAll(api: string; types_n: XmlNode) :=
      foreach var type_n in types_n.Nodes['type'] do
        if type_n['name'] is string(var tname) then
        begin
          if type_n.Text.StartsWith('#include') then continue;
          if type_n.Text.StartsWith('#ifndef GLEXT_64_TYPES_DEFINED') then
          begin
            type_n.Discard;
            continue;
          end;
          type_n.DiscardAttribute('comment');
          type_n.DiscardAttribute('requires');
          BasicTypeSource.TryDefine(api, tname);
        end else
        begin
          type_n.DiscardAttribute('comment');
          type_n.DiscardAttribute('requires');
          var tname := type_n.Nodes['name'].Single.Text;
          
          //TODO Struct and IdClass
          // - Use IdClassSource.extra_defined, for MakeTypeRef type lookup
          
          case type_n.Nodes['apientry'].Count - Ord(tname='__GLXextFuncPtr') of
            0: BasicTypeSource.TryDefine(api, tname);
            1: new DelegateSource(api, tname, type_n.Text);
            else raise new NotSupportedException;
          end;
          
        end;
    
    public static function MakeTypeRef(api, tname: string): TypeRef;
    begin
      
      var bt := default(BasicType);
      var cl := IdClassSource.FindOrMakeItem(IdClassSource.MakeName(api, tname));
      var d := DelegateSource.FindOrMakeItem(DelegateSource.MakeName(api, tname, true));
      
      if (cl<>nil) and (cl.Name not in IdClassSource.extra_defined) then
        raise new InvalidOperationException;
      
      case Ord(cl<>nil)+Ord(d<>nil) of
        0: bt := BasicTypeSource.FindOrMakeItem(tname);
      end;
      
      if bt<>nil then Result := new TypeRef(bt) else
      if cl<>nil then Result := new TypeRef(cl) else
      if d<>nil then Result := new TypeRef(d) else
        raise new InvalidOperationException($'{api}: {tname}');
      
    end;
    
  end;
  
{$endregion TypeHelper}

{$region Delegate}

function DelegateSource.MakeNewItem: Delegate;
begin
  var params_s := self.text
    .RemoveBeg('typedef void ( *')
    .RemoveBeg(self.org_name)
    .RemoveBeg(')(')
    .RemoveEnd(');')
    .Trim
  ;
  
  var pars := |new ParData(nil, new TypeRef(BasicTypeSource.FindOrMakeItem('void')), 0, System.Array.Empty&<integer>, ParArrSizeNotArray.Instance, nil)|;
  
  if params_s in |'','void'| then
  begin
    Result := new Delegate(self.Name, pars);
    exit;
  end;
  
  pars := pars + params_s.Split(',')
    .ConvertAll(par_s->
    begin
      par_s := par_s.Trim;
      
      var par_name := par_s.Reverse.TakeWhile(ch->ch.IsDigit or ch.IsLetter or (ch in $'_')).Reverse.JoinToString('');
      if par_name='' then
        raise new InvalidOperationException(par_s);
      if par_name.First.IsDigit then
        raise new InvalidOperationException;
      
      var (tname,ptr,readonly_lvls) := ParData.ParsePtrLvls(par_s.RemoveEnd(par_name));
      
      Result := new ParData(par_name, TypeHelper.MakeTypeRef(self.context_api, tname), ptr, readonly_lvls, ParArrSizeNotArray.Instance, nil);
    end);
  
  Result := new Delegate(self.Name, pars);
end;

{$endregion Delegate}

{$region BasicType}

function BasicTypeSource.MakeNewItem :=
  new BasicType(self.name);

{$endregion BasicType}

{$region Group}

function GroupSource.MakeNewItem: Group;
begin
  var castable_to := new List<BasicType>(castable_to_names.Count);
  foreach var tname in castable_to_names do
    castable_to += BasicTypeSource.FindOrMakeItem(tname);
  
  var possible_bitfield := new HashSet<boolean>;
  var enums := new List<Enum>(enum_names.Count);
  foreach var ename in enum_names.Keys do
  begin
    var e := EnumSource.FindOrMakeItem(ename);
    
    if e.Value<>0 then
      possible_bitfield += enum_names[ename];
    
    enums += e;
  end;
  if enums.Count <> enum_names.Count then
    raise new InvalidOperationException;
  
  if enums.Count=0 then
    raise new NotImplementedException else
  case possible_bitfield.Count of
    0: log.Otp($'{self} had no non-zero enums'); //TODO Maybe check 'GLbitfield' in castable_to_names
    1: ;
    else raise new System.InvalidOperationException(self.ToString);
  end;
  
  var is_bitfield := possible_bitfield.DefaultIfEmpty(false).Single;
  
  Result := new Group(self.Name, castable_to.ToArray, new SimpleEnumsInGroup(is_bitfield, enums.ToArray()));
end;

{$endregion Group}

{$region Enum}

function EnumSource.MakeNewItem: Enum;
begin
  
  var val: int64;
  try
    val := if val_s.StartsWith('0x') then
      System.Convert.ToInt64(val_s, 16) else
      System.Convert.ToInt64(val_s);
  except
    on FormatException do
      raise new FormatException($'Could not parse value [{val_s}] of {self}');
  end;
  
  if alias_s<>nil then
  begin
    var old_e := EnumSource.FindOrMakeItem(EnumSource.MakeName(nil, alias_s, self.Name.ApiName, true));
    if old_e=nil then
      raise nil;
    if old_e.Value <> val then
      raise new InvalidOperationException;
    var TODO := 0; //TODO Use enum name end to extract VendorName
  end;
  
  Result := new XMLItems.Enum(self.Name, val, false);
end;

{$endregion Enum}

{$region IdClass}

function IdClassSource.MakeNewItem: IdClass;
begin
  
  var castable_to := new List<BasicType>(castable_to_names.Count);
  foreach var tname in self.castable_to_names do
    castable_to += BasicTypeSource.FindOrMakeItem(tname);
  
  Result := new IdClass(name, castable_to.ToArray);
end;

{$endregion IdClass}

{$region FuncParam}

function MakeParArrSize(len_s: string; par_ind: string->integer): ParArrSize;
begin
  
  if len_s=nil then
  begin
    Result := ParArrSizeNotArray.Instance;
    exit;
  end;
  
  if len_s.StartsWith('COMPSIZE(') and len_s.EndsWith(')') then
  begin
    //TODO Replace with proper expr in xml
    Result := ParArrSizeArbitrary.Instance;
    exit;
  end;
  
  if |$'*',$'/'|.Find(ch->ch in len_s) is string(var spl_t) then
  begin
    var sub_lens := len_s.Split(spl_t.Single)
      .Select(sub_len_s->
      begin
        Result := MakeParArrSize(sub_len_s.Trim, par_ind);
      end)
      .Where(sz->sz<>ParArrSizeNotArray.Instance)
      .ToArray;
    case spl_t of
      '*': Result := new ParArrSizeMlt(sub_lens);
      '/': Result := new ParArrSizeDiv(sub_lens);
      else raise new NotImplementedException;
    end;
    exit;
  end;
  
  if len_s.FirstOrDefault.IsDigit then
  begin
    if not len_s.All(char.IsDigit) then
      raise new FormatException(len_s);
    if len_s='0' then
      Result := ParArrSizeNotArray.Instance else //TODO Actually it means parameter is unused
    if len_s='1' then
      Result := ParArrSizeNotArray.Instance else
      Result := new ParArrSizeConst(len_s.ToInteger);
    exit;
  end;
  
  if (par_ind(len_s) is integer(var ind)) and (ind<>-1) then
  begin
    Result := new ParArrSizeParRef(ind);
    exit;
  end;
  
  raise new NotImplementedException(len_s);
end;

function FuncParamSource.MakeNewItem(need_name: boolean; par_ind: string->integer): ParData;
begin
  
  if (gr_source=nil) and (self.tname in |'GLenum','GLbitfield'|) then 
    if LogCache.naked_enums.Add(func_descr) then 
      log_naked_enums.Otp(func_descr); 
  
  var arr_size := MakeParArrSize(self.len_s, par_ind);
  
  var val_combo := default(ParValCombo);
  
  {$region Kind}
  if self.kinds_s<>nil then
  begin
    if self.context_api<>'gl' then
      raise new System.InvalidOperationException;
    
    var all_kinds := kinds_s.Split(',');
    foreach var kind_s in all_kinds do
    begin
      
      case kind_s of
        
        'String':
        begin
          if tname not in |'GLubyte','void'| then
            raise new MessageException($'ERROR: Kind [{kind_s}] was applied to type [{tname}] in {func_descr}');
          tname := 'GLchar';
        end;
        
        else
          if |'Vector', 'Matrix'|.Find(kind_s.StartsWith) is string(var combo_kind_s) then
          begin
            if self.ptr<>1 then raise new System.InvalidOperationException;
            
            var mlt := kind_s.RemoveBeg(combo_kind_s).Split('x').ConvertAll(s->s.ToInteger);
            case combo_kind_s of
              'Vector': val_combo := new ParValComboVector(mlt.Single);
              'Matrix': val_combo := new ParValComboMatrix(mlt);
              else raise new NotImplementedException;
            end;
            
            if val_combo.Size<>mlt.Product then
              raise new InvalidOperationException;
            
            if val_combo is ParValComboVector(var pvcv) then
            begin
              if not |'Color','Coord','Normal','Tangent','Binormal'|.Any(k->k in all_kinds) and
                 not |'Uniform','VertexAttrib'|.Any(s->s in self.func_descr) and
                 not Regex.Matches(self.func_descr, 'Program.*Parameter').Cast&<&Match>.Any
              then
                log.Otp($'{func_descr} par#{par_ind(self.name)} has vector param without further spec kind. other kinds: '+all_kinds.Except(|kind_s|).JoinToString);
              if pvcv.Size=1 then val_combo := nil;
              if tname in |'GLhalfNV','GLfixed'| then val_combo := nil;
            end;
            
          end else
          begin
            if (kind_s in Kind.defined) and LogCache.kinds_unutilised.Add(kind_s) then
              log.Otp($'Kind [{kind_s}] was not utilised');
            continue;
          end;
        
      end;
      
      Kind.Require(kind_s);
    end;
    
  end;
  {$endregion Kind}
  
  var type_ref := default(TypeRef);
  if (self.gr_source<>nil) and (self.cl_source<>nil) then
    raise new System.InvalidOperationException;
  if gr_source<>nil then
    type_ref := new TypeRef(gr_source.GetItem) else
  if cl_source<>nil then
    type_ref := new TypeRef(cl_source.GetItem) else
    type_ref := TypeHelper.MakeTypeRef(self.context_api, self.tname);
  
  Result := new ParData(if need_name then self.name else nil, type_ref, self.ptr, self.readonly_lvls, arr_size, val_combo);
end;

{$endregion FuncParam}

{$region Func}

function FuncSource.MakeNewItem: Func;
begin
  
  var pars := new ParData[pars_source.Count];
  for var i := 0 to pars.Length-1 do
    pars[i] := self.pars_source[i].MakeNewItem(i<>0, par_name->pars_source.FindIndex(par_s->par_s.name=par_name));
  
  foreach var par in pars do
  begin
    if par.ValCombo=nil then continue;
//    if par.PtrLvl = 0 then continue;
    var expected_len := par.ValCombo.Size;
    
    match par.ArrSize with
      
      ParArrSizeConst(var sz_const):
      begin
        if expected_len<>sz_const.Value then
          raise new InvalidOperationException;
      end;
      
      ParArrSizeParRef(var sz_par_ref):
      begin
        if expected_len<>1 then
          raise new InvalidOperationException;
        if pars[sz_par_ref.Index].ParName <> 'count' then
          raise new InvalidOperationException;
      end;
      
      ParArrSizeMlt(var sz_mlt):
      begin
        var ref_names := new List<string>;
        var len := 1;
        
        foreach var sub_size in sz_mlt.SubSizes do
        match sub_size with
          
          ParArrSizeConst(var sz_const):
            len *= sz_const.Value;
          
          ParArrSizeParRef(var sz_par_ref):
            ref_names += pars[sz_par_ref.Index].ParName;
          
          else raise new NotSupportedException(TypeName(sub_size));
        end;
        
        if ref_names.SingleOrDefault not in |nil,'count'| then
          raise new InvalidOperationException(ref_names.Single);
      end;
      
      else raise new NotSupportedException($'{self}: {TypeName(par.ArrSize)}');
    end;
    
  end;
  
  var alias := FuncSource.FindOrMakeItem(self.alias_name);
  if (alias_name<>nil) <> (alias<>nil) then
    raise new InvalidOperationException(self.ToString);
  
  Result := new Func(self.Name, self.entry_point_name, pars, alias);
end;

{$endregion Func}

{$region RequiredList}

function RequiredListSource.MakeNewItem: RequiredList;
begin
  Result := new RequiredList;
  
  foreach var n in self.enum_names do
  begin
    var e := EnumSource.FindOrMakeItem(n);
    if e=nil then raise new InvalidOperationException(n.ToString);
    Result.enums += e;
  end;
  
  foreach var n in self.func_names do
  begin
    var f := FuncSource.FindOrMakeItem(n);
    if f=nil then raise new InvalidOperationException(n.ToString);
    Result.funcs += f;
  end;
  
end;

{$endregion RequiredList}

{$region Feature}

function FeatureSource.MakeNewItem: Feature;
begin
  var add := self.add.MakeNewItem;
  var rem := self.rem.MakeNewItem;
  
  if self.Name.ApiName='wgl' then
  begin
    var gdi_add := new RequiredList;
    var gdi_rem := new RequiredList;
    var gdi_api := 'gdi';
    
    add.enums.RemoveWhere(e->
    begin
      Result := e.Name.ApiName = gdi_api;
      if not Result then exit;
      gdi_add.enums.Add(e);
    end);
    add.funcs.RemoveWhere(f->
    begin
      Result := f.Name.ApiName = gdi_api;
      if not Result then exit;
      gdi_add.funcs.Add(f);
    end);
    
    if rem.enums.Any then raise new NotImplementedException;
    if rem.funcs.Any then raise new NotImplementedException;
    
    new Feature(new FeatureName(gdi_api, 1, 0), gdi_add, gdi_rem);
  end;
  
  Result := new Feature(self.Name, add, rem);
end;

{$endregion Feature}

{$region Extension}

function ExtensionSource.MakeNewItem :=
  new Extension(self.Name, self.ext_str, self.add.MakeNewItem, System.Array.Empty&<Extension>);

{$endregion Extension}

{$endregion MakeNewItem}

procedure ScrapXmlFiles(params api_names: array of string);
begin
  
  VendorSuffixSource.InitAll;
  
  foreach var api in api_names do
  begin
    Otp($'Parsing "{api}"');
    var root := new XmlNode(GetFullPathRTA($'../../Reps/OpenGL-Registry/xml/{api}.xml'));
    root.Nodes['comment'].Single.Discard;
    
    TypeHelper.InitAll(api, root.Nodes['types'].Single);
    
    if root.Nodes['kinds'].SingleOrDefault is XmlNode(var kinds_n) then
      Kind.InitAll(kinds_n);
    
    EnumSource.InitAll(api, root.Nodes['enums']);
    
    FuncSource.InitAll(api, root.Nodes['commands'].Single);
    
    FeatureSource.InitAll(api, root.Nodes['feature']);
    
    ExtensionSource.InitAll(api, root.Nodes['extensions'].Single);
    
  end;
  
end;

begin
  try
    XMLUtils.Init('OpenGL-Registry');
    
    ScrapXmlFiles('gl', 'wgl', 'glx');
    
    ItemSources.CreateAll;
    
    XMLItems.SaveAll;
    
    Otp($'Done');
    log_missing_ptype.Close;
    log_naked_enums.Close;
  except
    on e: Exception do ErrOtp(e);
  end;
end.