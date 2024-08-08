unit NamedItemBase;

uses System;

uses '../../../POCGL_Utils';
uses '../../../Utils/AOtp';
uses '../../../Utils/CodeGen';

uses LLPackingUtils;
uses BinUtils;

uses NamedItemHelpers;

type
  
  {$region NamedItem}
  
  NamedItem<TSelf, TName> = abstract class(INamedItem, IComparable<TSelf>)
  where TSelf: NamedItem<TSelf, TName>;
  where TName: IEquatable<TName>, IComparable<TName>;
    private _name: TName;
    private added_with_fixer := false;
    private static Defined := new Dictionary<TName, TSelf>;
    
    static constructor;
    begin
      if not typeof(NamedItem<TSelf, TName>).IsAssignableFrom(typeof(TSelf)) then
        raise new NotSupportedException($'NamedItem<{TypeToTypeName(typeof(TSelf))}, {TypeToTypeName(typeof(TName))}> | {TypeToTypeName(typeof(TSelf))}');
    end;
    
    protected constructor(name: TName; added_with_fixer: boolean);
    begin
      self._name := name;
      self.added_with_fixer := added_with_fixer;
      if name in Defined then
        raise new InvalidOperationException($'{self} was added twice');
      Defined.Add(name, TSelf(self));
      if all_sorted<>nil then
        all_sorted := nil;
    end;
    
    public property Name: TName read _name;
    function IComparable<TSelf>.CompareTo(other: TSelf) :=
      self.Name.CompareTo(other.Name);
    
    private static all_sorted: array of TSelf := nil;
    public static procedure ForEachDefined(p: TSelf->());
    begin
      if all_sorted=nil then
      begin
        all_sorted := Defined.Values.Distinct.ToArray;
        all_sorted.Sort;
      end;
      all_sorted.ForEach(p);
    end;
    
    public static procedure RemoveDefinedWhere(pred: TSelf->boolean) :=
      foreach var kvp in Defined.ToArray do
      begin
        if not pred(kvp.Value) then continue;
        if Defined.Remove(kvp.Key) then continue;
        raise new InvalidOperationException;
      end;
    
    public function ToString: string; override :=
      $'{TypeName(self)} [{self.Name}]';
    
    public static function ByName(name: TName) := Defined.Get(name);
    
    public procedure Rename(new_name: TName);
    begin
      if new_name in Defined then
        raise new InvalidOperationException($'{new_name} already exists');
      Defined.Add(new_name, TSelf(self));
      if all_sorted<>nil then raise new InvalidOperationException;
      self._name := new_name;
    end;
    
    public static function ItemSmallName := typeof(TSelf).Name;
    private referenced := false;
    private written := false;
    protected static written_c := 0;
    
    protected procedure LogContents(l: Logger); virtual :=
      raise new NotSupportedException(ItemSmallName);
    public static procedure LogAll;
    begin
      Otp($'Logging {ItemSmallName} items');
      var l := new FileLogger(GetFullPathRTA($'Log/All {ItemSmallName}''s.log'));
      loop 3 do l.Otp('');
      ForEachDefined(item->item.LogContents(l));
      loop 1 do l.Otp('');
      l.Close;
    end;
    
    public procedure MarkBodyReferenced; abstract;
    public procedure MarkReferenced;
    begin
      UnusedNamedItemHelper.TryRemoveReport(self);
      self.referenced := true;
      MarkBodyReferenced;
    end;
    
    private static NonWriteableButWriteRequested := new HashSet<string>;
    public procedure Use(need_write: boolean);
    begin
      
      var as_writable := self as IWritableNamedItem;
      if need_write and (as_writable=nil) then
      begin
        if NonWriteableButWriteRequested.Add(ItemSmallName) then
          log.Otp($'Requested write for {ItemSmallName}, but it is not writable');
        need_write := false;
      end;
      
      if need_write and written then
      begin
        if not referenced then
          raise new InvalidOperationException;
        exit;
      end;
      
      if not referenced then
        self.MarkReferenced;
      
      if need_write then
      begin
        self.written := true;
        written_c += 1;
        WritableNamedTypeHelper.AddWritable(as_writable);
      end;
      
    end;
    
    protected function MakeWasUnusedString: string; virtual := 'not referenced';
    public static procedure FinishPacking;
    begin
      
      begin
        var total_written_c := written_c - WritableNamedTypeHelper.UnwrittenCount&<TSelf>;
        if total_written_c<>0 then
        begin
          if total_written_c <> written_c then
            raise new InvalidOperationException; // Partially packed... How?
          Otp($'{ItemSmallName}: Packed {total_written_c} items');
        end;
      end;
      
      foreach var item in Defined.Values.Distinct do
      begin
        if item.referenced then continue;
        UnusedNamedItemHelper.AddReport(item, ()->
          if item.added_with_fixer then
            Otp($'WARNING: {item} was explicitly added, but then {item.MakeWasUnusedString}') else
            log_unused.Otp($'{item} was {item.MakeWasUnusedString}')
        );
      end;
      
    end;
    
  end;
  
  {$endregion NamedItem}
  
  {$region NamedLoadedItem}
  
  NamedLoadedItem<TSelf, TName> = abstract class(NamedItem<TSelf, TName>)
  where TSelf: NamedItem<TSelf, TName>; //TODO #2640: Доделать для классов, чтобы можно было указывать NamedLoadedItem
  where TName: IEquatable<TName>, IComparable<TName>;
    private static AllLoaded: array of TSelf;
    
    private static name_comp := default(IEqualityComparer<TName>);
    protected static procedure DefineNameComparer(comp: IEqualityComparer<TName>);
    begin
      if name_comp<>nil then raise new InvalidOperationException;
      name_comp := comp;
    end;
    
    private static load_new: BinReader->TSelf;
    protected static procedure RegisterLoader(loader: BinReader->TSelf);
    begin
      if load_new<>nil then
        raise new InvalidOperationException;
      load_new := loader;
    end;
    
    public static function ByIndex(ind: integer) := AllLoaded[ind];
    public static function MakeLazySeq(inds: array of integer) :=
      new LazyUniqueItemList<TSelf>(inds.Select(ByIndex));
    
    public static procedure LoadAll(br: BinReader);
    begin
      TypeInitHelper.InitType(typeof(TSelf));
      if load_new=nil then raise new NotImplementedException(ItemSmallName);
      
      var c := br.ReadInt32;
      if Defined.Count<>0 then raise new InvalidOperationException;
      AllLoaded := new TSelf[c];
      Defined := new Dictionary<TName, TSelf>(c, name_comp);
      
      for var i := 0 to c-1 do
      begin
        var item := load_new(br);
        if item=nil then
          raise new InvalidOperationException($'{ItemSmallName}#{i}');
        AllLoaded[i] := item;
//        Otp($'{ItemSmallName}: {item.Name}');
      end;
      
    end;
    
  end;
  
  {$endregion NamedLoadedItem}
  
end.