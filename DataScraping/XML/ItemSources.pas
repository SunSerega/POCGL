﻿unit ItemSources;

interface

uses System;

uses ScrapUtils;

uses NamedItems;

type
  ItemSource<TSelf, TSourceName, TItem> = abstract class
  where TSelf: ItemSource<TSelf, TSourceName, TItem>;
  where TSourceName: class, IEquatable<TSourceName>;
  where TItem: class;
    private _name: TSourceName;
    private ready := default(TItem);
    private static all_sources := new Dictionary<TSourceName, TSelf>;
    
    public static procedure PrintAllNames := all_sources.Keys.PrintLines;
    
    //TODO #2842
    private static function constructor_hotfix: byte;
    private static aaaaa := constructor_hotfix;
//    static constructor;
    
    protected static function MakeName<TFullName>(api, s, api_beg: string; allow_nil: boolean; api_underscore_sep: boolean?; known_suffixes: HashSet<string>; params suffix_formats: array of string): TFullName;
      where TFullName: ApiVendorLName<TFullName>;
    begin
      Result := nil;
      var ctor := typeof(TFullName).GetConstructor(|
        typeof(string), typeof(string), typeof(string), typeof(Nullable<boolean>), typeof(Func<string, ValueTuple<string,string>>)
      |);
      if ctor=nil then
        raise new NotImplementedException(TypeToTypeName(typeof(TFullName)));
      
      if s=nil then
      begin
        if not allow_nil then
          raise nil;
        exit;
      end;
      
      if allow_nil then
      begin
        if not s.ToLower.StartsWith(api_beg) then exit;
        if api_underscore_sep = not s.Remove(0,api_beg.Length).StartsWith('_') then exit;
      end;
      
      var extract_suffix: Func<string, ValueTuple<string,string>> := l_name->
        TFullName.ParseSuffix(l_name, known_suffixes, suffix_formats);
      Result := TFullName(ctor.Invoke(new object[](api, s, api_beg, api_underscore_sep, extract_suffix)));
    end;
    
    protected constructor(name: TSourceName);
    begin
      aaaaa := aaaaa;
      self._name := name;
      if name in all_sources then
        raise new InvalidOperationException(self.ToString);
      all_sources.Add(name, TSelf(self));
    end;
    protected constructor := raise new System.InvalidOperationException;
    
    public property Name: TSourceName read _name;
    
    public static function FindOrMakeSource(name: TSourceName; make_source: TSourceName->TSelf): TSelf;
    begin
      Result := nil;
      if name=nil then exit;
      if all_sources.TryGetValue(name, Result) then exit;
      if make_source=nil then exit;
      Result := make_source(name);
    end;
    public static property Existing[name: TSourceName]: TSelf read FindOrMakeSource(name, nil); default;
    
    private static currently_constructing: Stack<TSourceName>;
    public function GetItem: TItem;
    begin
      Result := self.ready;
      if Result<>nil then exit;
      
      var outer_constr := currently_constructing=nil;
      if outer_constr then
        currently_constructing := new Stack<TSourceName> else
      if self.Name in currently_constructing then
        raise new System.InvalidOperationException($'{name} depended on itself');
      currently_constructing.Push(self.Name);
      
      Result := self.MakeNewItem;
      if Result=nil then
        raise new System.InvalidOperationException(self.ToString);
      self.ready := Result;
      
      var poped := currently_constructing.Pop;
      if poped <> self.Name then
        raise new System.InvalidOperationException;
      if outer_constr then
      begin
        if currently_constructing.Count<>0 then
          raise new InvalidOperationException;
        currently_constructing := nil;
      end;
      
    end;
    
    public static function FindOrMakeItem(name: TSourceName): TItem;
    begin
      Result := nil;
      if name=nil then exit;
      Result := all_sources.Get(name)?.GetItem;
    end;
    
    protected function MakeNewItem: TItem; abstract;
    
    public function ToString: string; override :=
      $'{TypeName(self).RemoveEnd(''Source'')} [{self.Name}]';
    
  end;
  
procedure CreateAll;

implementation

uses '../../POCGL_Utils';

var source_create_callbacks: Action;

//TODO #2842
static function ItemSource<TSelf,TSourceName,TItem>.constructor_hotfix: byte;
//static constructor ItemSource<TSelf,TSourceName,TItem>.Create;
begin
//  Println(TypeToTypeName(typeof(TSelf)));
  Result := 0;
  
  source_create_callbacks += ()->
    foreach var s in all_sources.Values do
      s.GetItem;
  
end;

procedure CreateAll;
begin
  Otp($'Constructing named items');
  source_create_callbacks();
end;

end.