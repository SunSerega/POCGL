uses System;

uses '../../../POCGL_Utils';

uses '../ScrapUtils';
uses '../XMLUtils';
//
uses '../XMLItems';
uses '../ItemSources';

const api='cl';

type
  
  {$region BasicType}
  
  BasicTypeSource = sealed class(ItemSource<BasicTypeSource, string, BasicType>)
    
    public constructor(name: string) :=
      inherited Create(name);
    
    public static procedure InitAll(types_n: XmlNode) :=
      foreach var type_n in types_n.Nodes['type'] do
        new BasicTypeSource(type_n['name']);
    
    protected function MakeNewItem: BasicType; override :=
      new BasicType(self.name);
    
  end;
  
  {$endregion BasicType}
  
  {$region Group}
  
  GroupSource = sealed class(ItemSource<GroupSource, string, Group>)
    private etype: string;
    private enums: sequence of XmlNode;
    
    public static AllCreatedEnums := new List<Enum>;
    
    private constructor(name, etype: string; enums: sequence of XmlNode);
    begin
      inherited Create(name);
      self.etype := etype;
      self.enums := enums;
    end;
    
    public static procedure InitAll(groups_n: XmlNode) :=
      foreach var group_n in groups_n.Nodes['group'] do
        new GroupSource(group_n['name'], group_n['etype'], group_n.Nodes['enum']);
    
    protected function MakeNewItem: Group; override;
    
  end;
  
  {$endregion Group}
  
  {$region Func}
  
  FuncSource = sealed class(ItemSource<FuncSource, string, Func>)
    private par_ns: sequence of XmlNode;
    
    public static All := new List<FuncSource>;
    
    public constructor(name: string; par_ns: sequence of XmlNode);
    begin
      inherited Create(name);
      self.par_ns := par_ns;
      All += self;
    end;
    
    public static procedure InitAll(commands_n: XmlNode) :=
      foreach var command_n in commands_n.Nodes['command'] do
        new FuncSource(
          command_n.Nodes['proto'].Single.Nodes['name'].Single.Text,
          command_n.Nodes['proto'] + command_n.Nodes['param']
        );
    
    protected function MakeNewItem: Func; override;
    
  end;
  
  {$endregion Func}
  
  {$region Feature}
  
  FeatureSource = sealed class(ItemSource<FeatureSource, string, Feature>)
    
    public static procedure InitAll(features_n: XmlNode) :=
      foreach var feature_n in features_n.Nodes['feature'] do
        new FeatureSource(feature_n['name']);
    
    protected function MakeNewItem: Feature; override;
    
  end;
  
  {$endregion Feature}
  
{$region MakeNewItem}

{$region TypeHelper} type
  
  TypeHelper = static class
    
    public static function TypeRefFromName(tname: string; var ptr: integer): TypeRef;
    begin
      if tname=nil then raise nil;
      
      var gr := GroupSource.FindOrMakeItem(tname);
      if gr<>nil then
      begin
        Result := new TypeRef(gr);
        exit;
      end;
      
      var bt := BasicTypeSource.FindOrMakeItem(tname);
      if bt<>nil then
      begin
        Result := new TypeRef(bt);
        exit;
      end;
      
      raise new InvalidOperationException($'{tname} not defined');
    end;
    
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
    
    public static function MakeEnumToTypePar(t: string): ParData;
    begin
      Result := nil;
      if t=nil then exit;
      
      var sz := default(ParArrSize);
      if t.EndsWith(']') then
      begin
        var sz_s: string;
        (t, sz_s) := t.Remove(t.Length-1).Split(|'['|,2);
        if sz_s='' then
        begin
          if t='void' then raise new InvalidOperationException;
          sz := ParArrSizeArbitrary.Instance;
        end else
          sz := new ParArrSizeConst(sz_s.ToInteger);
      end else
        sz := ParArrSizeNotArray.Instance;
      
      Result := MakePar(nil, t.TrimEnd('*'), t, sz);
    end;
    
  end;
  
{$endregion TypeHelper}

{$region Group}

function GroupSource.MakeNewItem: Group;
begin
  
  if self.etype<>'obj info' then
    raise new NotImplementedException;
  
  var enums := new ObjInfoEnumsInGroup(self.enums
    .Select(enum_n->
    begin
      var e := new Enum(new EnumName('', nil, enum_n['name']), enum_n['val'].ToInteger, false);
      AllCreatedEnums += e;
      var inp_t := TypeHelper.MakeEnumToTypePar( enum_n['inp_t'] );
      var otp_t := TypeHelper.MakeEnumToTypePar( enum_n['otp_t'] );
      Result := new EnumWithObjInfo(e, inp_t, otp_t);
    end)
    .ToArray
  );
  
  Result := new Group(new GroupName('', nil, self.Name), |BasicTypeSource.FindOrMakeItem('enum_base')|, enums);
end;

{$endregion Group}

{$region Func}

function FuncSource.MakeNewItem: Func;
begin
  
  var pars := par_ns.Select((par_n,par_i)->
  begin
    var par_name := par_n.Nodes['name'].Single.Text;
    var text := par_n.Text;
    
    var sz := default(ParArrSize);
    var par_arr_str := '[]';
    if text.EndsWith(par_arr_str) then
    begin
      sz := ParArrSizeArbitrary.Instance;
      text := text.RemoveEnd(par_arr_str);
    end else
      sz := ParArrSizeNotArray.Instance;
    
    text := text.RemoveEnd(par_name).TrimEnd;
    if par_i=0 then par_name := nil;
    Result := TypeHelper.MakePar(par_name, par_n.Nodes['type'].Single.Text, text, sz);
  end).ToArray;
  
  Result := new Func(new FuncName('', nil, self.Name), self.Name, pars, nil);
end;

{$endregion Func}

{$region Feature}

function FeatureSource.MakeNewItem: Feature;
begin
  
  var add := new RequiredList;
  add.funcs.UnionWith( FuncSource.All.Select(s->s.GetItem) );
  add.enums.UnionWith( GroupSource.AllCreatedEnums );
  
  var rem := new RequiredList;
  
  Result := new Feature(new FeatureName(self.Name, 1, 0), add, rem);
end;

{$endregion Feature}

{$endregion MakeNewItem}

procedure ScrapXmlFile;
begin
  Otp($'Parsing XML');
  var root := new XmlNode(GetFullPathRTA('xml/Dummy.xml'));
  
  BasicTypeSource.InitAll(root.Nodes['types'].Single);
  
  GroupSource.InitAll(root.Nodes['groups'].Single);
  
  FuncSource.InitAll(root.Nodes['commands'].Single);
  
  FeatureSource.InitAll(root.Nodes['features'].Single);
  
end;

begin
  try
    XMLUtils.Init('../XML/Dummy');
    
    ScrapXmlFile;
    
    ItemSources.CreateAll;
    
    XMLItems.SaveAll;
    
    Otp($'Done');
  except
    on e: Exception do ErrOtp(e);
  end;
end.