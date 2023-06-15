unit LLPackingUtils;

uses System;

uses '..\..\..\POCGL_Utils';
uses '..\..\..\Utils\AOtp';

uses BinUtils;

var log := new FileLogger(GetFullPathRTA('Log\Essentials.log')) +
           new FileLogger(GetFullPathRTA('Log\Essentials (Timed).log'), true);
var log_unused      := new FileLogger(GetFullPathRTA('Log\Unused.log'));
var log_func_ovrs   := new FileLogger(GetFullPathRTA('Log\FinalFuncOverloads.log'));
var log_ext_bodies  := new FileLogger(GetFullPathRTA('Log\Extensions.log'));

type
  
  {$region TypeInitHelper}
  
  TypeInitHelper = static class
    
    public static procedure InitType(t: System.Type) :=
      foreach var base_t in SeqWhile(t, t->t.BaseType, t->t<>nil).Reverse do
        System.Runtime.CompilerServices.RuntimeHelpers.RunClassConstructor(base_t.TypeHandle);
    
    public static procedure InitDirectImplementers(base_t: System.Type);
    begin
      InitType(base_t);
      if base_t.IsGenericType then
        raise new InvalidOperationException(TypeToTypeName(base_t));
      foreach var t in base_t.Assembly.GetTypes do
      begin
        if t = base_t then continue;
        if not base_t.IsAssignableFrom(t) then continue;
        if t.IsAbstract then
          raise new InvalidOperationException(TypeToTypeName(t));
        if base_t <> t.BaseType then // RunClassConstructor Does not call base type ctor
          raise new NotImplementedException(TypeToTypeName(t));
        InitType(t);
      end;
    end;
    
  end;
  
  {$endregion TypeInitHelper}
  
  {$region MutiKindItem}
  
  MutiKindItem<TItemFork, TKind> = abstract class
  where TItemFork: MutiKindItem<TItemFork, TKind>;
  where TKind: System.Enum, record;
    
    private static Loaders := new Dictionary<TKind, BinReader->TItemFork>;
    protected static procedure DefineLoader(kind: TKind; load: BinReader->TItemFork);
    begin
      Loaders.Add(kind, load);
    end;
    
    static constructor;
    begin
      TypeInitHelper.InitDirectImplementers(typeof(TItemFork));
    end;
    
    public static function Load(br: BinReader): TItemFork;
    begin
      var kind := br.ReadEnum&<TKind>;
      var loader: BinReader->TItemFork;
      if Loaders.TryGetValue(kind, loader) then
        Result := loader(br) else
        raise new NotImplementedException($'{TypeName(kind)}[{kind}]');
    end;
    
  end;
  
  {$endregion MutiKindItem}
  
  {$region LazyUniqueItemList}
  
  LazyUniqueItemList<T> = sealed class
    private sources := new List<sequence of T>;
    
    public procedure Add(source: sequence of T);
    begin
      // CastableToList relies on this to never change
      if calculated<>nil then
        raise new InvalidOperationException;
      sources += source;
    end;
    public constructor(first_source: sequence of T) := Add(first_source);
    public constructor := exit;
    
    public static function operator implicit(seq: sequence of T): LazyUniqueItemList<T> :=
      new LazyUniqueItemList<T>(seq);
    public static function operator implicit(l: LazyUniqueItemList<T>): sequence of T;
    begin
      var res1 := l.sources?.SelectMany(seq->seq);
      var res2 := l.calculated;
      if (res1=nil) = (res2=nil) then
        raise new InvalidOperationException;
      Result := res1 ?? res2;
    end;
    
    private calculated: HashSet<T>;
    public function ToSeq: sequence of T;
    begin
      Result := calculated;
      if Result<>nil then exit;
      
      calculated := new HashSet<T>;
      foreach var source in sources do
        foreach var item in source do
          if not calculated.Add(item) then
            raise new InvalidOperationException(item.ToString);
      
      sources := nil;
      Result := calculated;
    end;
    
  end;
  
  {$endregion LazyUniqueItemList}
  
  {$region ApiManager}
  
  ApiManager = static class
    
    private static api_keep := new Dictionary<string, boolean>;
    public static procedure MarkKeep(api: string; keep: boolean);
    begin
      if api in api_keep then
        raise new InvalidOperationException(api);
      api_keep.Add(api, keep);
    end;
    public static function ShouldKeep(api: string): boolean;
    begin
      if api_keep.TryGetValue(api, Result) then exit;
      raise new NotSupportedException(api);
    end;
    
    private static ftr_dynamic := new Dictionary<string, boolean>;
    private static ext_dynamic := new Dictionary<string, boolean>;
    public static procedure MarkDynamic(api: string; in_ftr, in_ext: boolean?);
    begin
      if in_ftr<>nil then ftr_dynamic.Add(api, in_ftr.Value);
      if in_ext<>nil then ext_dynamic.Add(api, in_ext.Value);
    end;
    public static function NeedDynamicLoad(api: string; from_ext: boolean): boolean;
    begin
      var d := if from_ext then ext_dynamic else ftr_dynamic;
      if d.TryGetValue(api, Result) then exit;
      raise new NotSupportedException(api);
    end;
    
    private static api_lib := new Dictionary<string, string>;
    public static procedure AddApiLib(api, lib: string);
    begin
      if api in api_lib then
        raise new InvalidOperationException(api);
      api_lib.Add(api, lib);
    end;
    public static function LibForApi(api: string): string;
    begin
      if api_lib.TryGetValue(api, Result) then exit;
      raise new NotSupportedException(api);
    end;
    
  end;
  
  {$endregion ApiManager}
  
initialization
  try
    Logger.main += log;
    
    //TODO Это тоже можно с помощью Func.LogAll и Extension.LogAll
    // - И тогда сортировать будет по названию
    // - Неприменяемые api так тоже скипать можно будет
    foreach var l in |log_func_ovrs,log_ext_bodies| do
      loop 3 do l.Otp('');
    
  except
    on e: Exception do
      ErrOtp(e);
  end;
finalization
  try
    Otp('Cleanup');
    log.Close;
    log_unused.Close;
    
    foreach var l in |log_func_ovrs,log_ext_bodies| do
    begin
      loop 1 do l.Otp('');
      l.Close;
    end;
    
  except
    on e: Exception do
      ErrOtp(e);
  end;
end.