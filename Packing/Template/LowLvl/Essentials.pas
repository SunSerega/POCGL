unit Essentials;

interface

uses System;

uses '../../../POCGL_Utils';

uses LLPackingUtils;

uses NamedItemBase;
uses NamedItemFixerBase;

uses VendorSuffixItems;
uses EnumItems;
uses NamedTypeItems;
uses CodeContainerItems;

type
  ApiManager = LLPackingUtils.ApiManager;
  DynamicLoadInfo = LLPackingUtils.DynamicLoadInfo;
  
procedure SetMaxUnfixedOverloads(c: integer);

procedure AddFuncAutoFixersForAllOutParams;
procedure AddFuncAutoFixersForCL;
procedure ApplyFixers;

procedure PackAllItems;

implementation

uses '../../../Utils/CodeGen';

uses BinUtils;
uses NamedItemHelpers;
uses TypeRefering;
uses FuncHelpers;

uses EnumItems;
uses NamedTypeItems;

procedure SetMaxUnfixedOverloads(c: integer) :=
  Func.SetMaxUnfixedOverloads(c);

{$region ForEachDefaultNamedItem}

type
  NamedItemConsumer = abstract class(IDisposable)
    
    public procedure Use<TFixer, TItem, TName>; abstract;
      where TFixer: NamedItemFixer<TFixer, TItem, TName>;
      where TItem: NamedItem<TItem, TName>;
      where TName: IEquatable<TName>, IComparable<TName>;
    public procedure Use<TFixer, TItem, TName>(f: NamedItemFixer<TFixer, TItem,TName>);
      where TFixer: NamedItemFixer<TFixer, TItem, TName>;
      where TItem: NamedItem<TItem, TName>;
      where TName: IEquatable<TName>, IComparable<TName>;
    begin
      if f<>default(TFixer) then
        raise new InvalidOperationException;
      Use&<TFixer, TItem, TName>;
    end;
    
    public procedure Dispose; abstract;
    
  end;
  
procedure ForEachDefaultNamedItem(u: NamedItemConsumer);
begin
  
  u.Use(default(VendorSuffixFixer));
  
  u.Use(default(EnumFixer));
  
  u.Use(default(LoadedBasicTypeFixer));
  u.Use(default(PascalBasicTypeFixer));
  u.Use(default(GroupFixer));
  u.Use(default(IdClassFixer));
  u.Use(default(StructFixer));
  u.Use(default(DelegateFixer));
  
  u.Use(default(FuncFixer));
  
  u.Use(default(FeatureFixer));
  u.Use(default(ExtensionFixer));
  
  u.Dispose;
end;

{$endregion ForEachDefaultNamedItem}

{$region LoadAll}

type NamedItemLoader = sealed class(NamedItemConsumer)
  private br: BinReader;
  private fixer_dirs := new Dictionary<string, string>;
  
  public constructor(unit_name: string);
  begin
    self.br := new BinReader(System.IO.File.OpenRead(GetFullPathRTA($'../../../../DataScraping/XML/{unit_name}/funcs.bin')));
    
    foreach var item_dir in EnumerateDirectories(GetFullPathRTA('../Fixers')) do
    begin
      var item_t_name := System.IO.Path.GetFileName(item_dir);
      var item_unit_dir := GetFullPath(unit_name, item_dir);
      if System.IO.Directory.Exists(item_unit_dir) then
        fixer_dirs.Add(item_t_name, item_unit_dir) else
        // Already checked and reported to log below
//        Otp($'WARNING: Fixer folder missing for {item_t_name} in {unit_name}');
    end;
    
  end;
  private constructor := raise new InvalidOperationException;
  
  public procedure Use<TFixer,TItem,TName>; override;
    where TFixer: NamedItemFixer<TFixer, TItem, TName>;
    where TItem: NamedItem<TItem, TName>;
    where TName: IEquatable<TName>, IComparable<TName>;
  begin
    var item_t_name := TItem.ItemSmallName;
    
    try
      if not typeof(NamedLoadedItem<TItem, TName>).IsAssignableFrom(typeof(TItem)) then
        exit;
      
      Otp($'Loading {item_t_name} items');
      NamedLoadedItem&<TItem, TName>.LoadAll(self.br);
      
      var fixer_dir: string;
      if not fixer_dirs.TryGetValue(item_t_name, fixer_dir) then
        log.Otp($'Loading {item_t_name} fixers canceled: No folder') else
      begin
        Otp($'Loading {item_t_name} fixers');
        TFixer.LoadAll(fixer_dir);
        fixer_dirs.Remove(item_t_name);
      end;
      
    except
      on e: Exception do
      begin
        Otp($'ERROR while loading {item_t_name}');
        ErrOtp(e);
      end;
    end;
    
  end;
  
  public procedure Dispose; override;
  begin
    
    if br.BaseStream.Position <> br.BaseStream.Length then
      raise new InvalidProgramException;
    br.Close;
    
    foreach var item_t_name in fixer_dirs.Keys do
      Otp($'WARNING: Fixer for {item_t_name} does not have matching item type');
    
  end;
  
end;
procedure LoadAll(unit_name: string);
begin
  ForEachDefaultNamedItem(new NamedItemLoader(unit_name));
end;

{$endregion LoadAll}

{$region ApplyFixers}

procedure AddFuncAutoFixersForAllOutParams := Func.AddAutoFixersForAllOutParams;
procedure AddFuncAutoFixersForCL := Func.AddAutoFixersForCL;

type NamedItemFixApplier = sealed class(NamedItemConsumer)
  
  public procedure Use<TFixer,TItem,TName>; override;
    where TFixer: NamedItemFixer<TFixer, TItem, TName>;
    where TItem: NamedItem<TItem, TName>;
    where TName: IEquatable<TName>, IComparable<TName>;
  begin
    
    if TFixer.AnyExist then
    try
      Otp($'Fixing {TItem.ItemSmallName} items');
      TFixer.ApplyAll(nil, nil, TItem.RemoveDefinedWhere);
    except
      on e: Exception do
      begin
        Otp($'ERROR while applying fixes to {TItem.ItemSmallName}');
        ErrOtp(e);
      end;
    end;
    
  end;
  
  public procedure Dispose; override := exit;
  
end;
procedure ApplyFixers;
begin
  ForEachDefaultNamedItem(new NamedItemFixApplier);
end;

{$endregion ApplyFixers}

{$region PackAllItems}

type NamedItemPackFinisher = sealed class(NamedItemConsumer)
  
  public procedure Use<TFixer,TItem,TName>; override;
    where TFixer: NamedItemFixer<TFixer, TItem, TName>;
    where TItem: NamedItem<TItem, TName>;
    where TName: IEquatable<TName>, IComparable<TName>;
  begin
    TItem.FinishPacking;
  end;
  
  public procedure Dispose; override;
  begin
    UnusedNamedItemHelper.ExecuteAllReports;
    WritableNamedTypeHelper.FinishWriting;
  end;
  
end;
procedure PackAllItems;
begin
  
  Func.LogAllEnumToType;
  Group.LogAllPropLists;
  
  Feature.WriteAll;
  Extension.WriteAll;
  
  PascalBasicType.LogAll;
  TypeCombo.LogAll;
  Group.LogAll;
  IdClass.LogAll;
  Struct.LogAll;
  Delegate.LogAll;
  Func.LogAll;
  Extension.LogAll;
  
  begin
    var intr_wr := new FileWriter(GetFullPathRTA('Types.Interface.template'));
    var impl_wr := new FileWriter(GetFullPathRTA('Types.Implementation.template'));
    var wr := intr_wr*impl_wr;
    loop 3 do
    begin
      intr_wr += '  ';
      wr += #10;
    end;
    
    WritableNamedTypeHelper.DumpAllWritables(intr_wr, impl_wr, default(PascalBasicType));
    WritableNamedTypeHelper.DumpAllWritables(intr_wr, impl_wr, default(TypeCombo));
    WritableNamedTypeHelper.DumpAllWritables(intr_wr, impl_wr, default(Group));
    WritableNamedTypeHelper.DumpAllWritables(intr_wr, impl_wr, default(IdClass));
    WritableNamedTypeHelper.DumpAllWritables(intr_wr, impl_wr, default(Struct));
    WritableNamedTypeHelper.DumpAllWritables(intr_wr, impl_wr, default(Delegate));
    
    intr_wr += '  '#10'  ';
    impl_wr += #10;
    wr.Close;
  end;
  
  ForEachDefaultNamedItem(new NamedItemPackFinisher);
end;

{$endregion PackAllItems}

initialization
  try
    var unit_name := System.IO.Path.GetFileName(System.IO.Path.GetDirectoryName(GetEXEFileName));
    LoadAll(unit_name);
    LoadedBasicType.ReportAllUnusedTypeConverters;
  except
    on e: Exception do
      ErrOtp(e);
  end;
end.