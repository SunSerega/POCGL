unit NamedItemFixerBase;

uses System;

uses '..\..\..\POCGL_Utils';
uses '..\..\..\Utils\Fixers';

uses LLPackingUtils;
uses ItemNames;

uses NamedItemBase;

type
  
  {$region NamedItemFixer}
  
  NamedItemFixer<TSelf, TItem, TName> = abstract class(Fixer<TSelf, TItem, TName>)
  where TSelf: Fixer<TSelf, TItem, TName>; //TODO #2736: "TSelf: NamedItemFixer"
  where TItem: NamedItem<TItem, TName>;
  where TName: IEquatable<TName>, IComparable<TName>;
    
    static constructor;
    type Expression = System.Linq.Expressions.Expression;
    begin
      
      RegisterFixableNameExtractor(item->item.Name);
      begin
        var name_ctor := typeof(TItem).GetConstructor(|typeof(TName)|);
        if name_ctor<>nil then
          RegisterPreAdder(f->TItem(name_ctor.Invoke(new object[](f.Name))));
      end;
      
      TypeInitHelper.InitType(typeof(TSelf));
      TypeInitHelper.InitDirectImplementers(typeof(TSelf));
      
    end;
    
    private static loader_by_command := new Dictionary<string, Func<string, array of string, TSelf>>;
    protected static procedure RegisterLoader(command_name: string; load: Func<string, array of string, TSelf>);
    begin
      loader_by_command.Add(command_name, load);
    end;
    
    public static procedure LoadAll(dir: string) :=
      foreach var fname in EnumerateAllFiles(dir, '*.dat') do
        foreach var (item_name, item_lines) in FixerUtils.ReadBlocks(fname,true) do
          foreach var (command_name, command_lines) in FixerUtils.ReadBlocks(item_lines,'!',false) do
            if command_name=nil then
              Otp($'WARNING: {TItem.ItemSmallName} [{item_name}] fixer comments') else
            begin
              var loader: Func<string, array of string, TSelf>;
              if not loader_by_command.TryGetValue(command_name, loader) then
                raise new NotImplementedException($'{TItem.ItemSmallName}: #{item_name}!{command_name}');
              loader(item_name, command_lines);
            end;
    
    protected procedure WarnUnused(all_unused_for_name: List<TSelf>); override :=
      Otp($'WARNING: {all_unused_for_name.Count} fixers of {TItem.ItemSmallName} [{self.Name}] were not used. Fixer types: {all_unused_for_name.Cast&<object>.Select(TypeName).Distinct.JoinToString}');
    
  end;
  
  {$endregion NamedItemFixer}
  
  {$region NamedItemCommonFixer}
  
  NamedItemCommonFixer<TSelf, TItem> = abstract class(NamedItemFixer<TSelf, TItem, ApiVendorLName>)
  where TSelf: Fixer<TSelf, TItem, ApiVendorLName>; //TODO #2736: "TSelf: NamedItemCommonFixer"
  where TItem: NamedItem<TItem, ApiVendorLName>;
    
    protected static procedure RegisterLoader(command_name: string; load: Func<ApiVendorLName, array of string, TSelf>) :=
      inherited RegisterLoader(command_name,
        (name,lines)->load(ApiVendorLName.Parse(name), lines)
      );
    
  end;
  
  {$endregion NamedItemCommonFixer}
  
end.