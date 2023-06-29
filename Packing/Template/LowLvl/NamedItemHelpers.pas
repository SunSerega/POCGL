unit NamedItemHelpers;

uses System;

uses '../../../POCGL_Utils';
uses '../../../Utils/CodeGen';

uses LLPackingUtils;

type
  INamedItem = interface
    
    procedure Use(need_write: boolean);
    procedure MarkReferenced;
    procedure MarkBodyReferenced;
    
  end;
  NamedItemWriteProc = procedure(prev: sequence of INamedItem; intr_wr, impl_wr: Writer);
  IWritableNamedItem = interface(INamedItem)
    
    function MakeWriteProc: NamedItemWriteProc;
    
  end;
  
  {$region UnusedNamedItemHelper}
  
  UnusedNamedItemHelper = static class
    private static all_unused_reports := new Dictionary<INamedItem, Action>;
    
    public static procedure AddReport(item: INamedItem; report: Action);
    begin
      all_unused_reports.Add(item, report);
      {$ifdef DEBUG}
      if item not in all_unused_reports then
        raise new InvalidOperationException;
      {$endif DEBUG}
    end;
    
    public static procedure TryRemoveReport(item: INamedItem) :=
      all_unused_reports.Remove(item);
    
    public static procedure ExecuteAllReports;
    begin
      foreach var kvp in all_unused_reports.ToArray do
      begin
        if kvp.Key not in all_unused_reports then
          continue;
        kvp.Key.MarkBodyReferenced;
        if kvp.Key not in all_unused_reports then
          Otp($'WARNING: {kvp.Key} referenced itself');
      end;
      
      foreach var kvp in all_unused_reports do
        kvp.Value();
      //TODO #????: Почему то считает что значения тут INamedItem
//      foreach var rep: Action in all_unused_reports.Values do
//        rep.Invoke();
      all_unused_reports := nil;
    end;
    
  end;
  
  {$endregion UnusedNamedItemHelper}
  
  {$region WritableNamedTypeHelper}
  
  WritableNamedTypeHelper = static class
    
    private static item_info := new Dictionary<IWritableNamedItem, ValueTuple<NamedItemWriteProc, List<IWritableNamedItem>>>;
    private static dumped_items: HashSet<IWritableNamedItem>;
    
    private static curr_dep_lst := default(List<IWritableNamedItem>);
    public static procedure AddWritable(item: IWritableNamedItem);
    begin
      if item in item_info then exit;
      
      if curr_dep_lst<>nil then
        curr_dep_lst += item;
      var old_dep_lst := curr_dep_lst;
      
      curr_dep_lst := new List<IWritableNamedItem>;
      var wr_proc := item.MakeWriteProc;
      if wr_proc=nil then
        raise new InvalidOperationException(TypeName(item));
      item_info.Add(item, ValueTuple.Create(wr_proc, curr_dep_lst));
      
      curr_dep_lst := old_dep_lst;
    end;
    public static procedure UnordUse(use: Action);
    begin
      var old_dep_lst := curr_dep_lst;
      curr_dep_lst := nil;
      use;
      curr_dep_lst := old_dep_lst;
    end;
    
    private static prev_written: List<INamedItem>;
    private static procedure DumpItem(intr_wr, impl_wr: Writer; item: IWritableNamedItem);
    begin
      if item in dumped_items then exit;
//      if item not in item_info then exit;
      var (wr_proc, lst) := item_info[item];
      item_info.Remove(item);
      
      foreach var dep in lst do
        DumpItem(intr_wr, impl_wr, dep);
      wr_proc(prev_written.AsReadOnly, intr_wr, impl_wr);
      
      if not dumped_items.Add(item) then
        raise new InvalidOperationException;
      prev_written.Add( item );
    end;
    public static procedure DumpAllWritables<TItem>(intr_wr, impl_wr: Writer; item_sample: TItem := nil);
      where TItem: class, IWritableNamedItem;
    begin
      Otp($'Dumping {TypeToTypeName(typeof(TItem))} items');
      if curr_dep_lst<>nil then
        raise new InvalidOperationException;
      
      if dumped_items=nil then
      begin
        dumped_items := new HashSet<IWritableNamedItem>(item_info.Count);
        prev_written := new List<INamedItem>(item_info.Count)
      end else
      if prev_written.Capacity<>item_info.Count+dumped_items.Count then
        raise new InvalidOperationException;
      
      foreach var item in item_info.Keys.OfType&<TItem>.Order do
        DumpItem(intr_wr, impl_wr, item);
      
    end;
    
    public static function UnwrittenCount<TItem> :=
      item_info.Keys.OfType&<TItem>.Count;
    public static procedure FinishWriting;
    begin
      foreach var item_tname in item_info.Keys.Select(item->TypeName(item)).Distinct do
        log.Otp($'{item_tname} was sceduled but then never written');
      item_info := nil;
    end;
    
  end;
  
  {$endregion WritableNamedTypeHelper}
  
end.