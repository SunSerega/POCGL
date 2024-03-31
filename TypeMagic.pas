unit TypeMagic;

interface

type
  
  {$region Convert}
  
  ConvertTo<T> = sealed class
    
    private constructor := raise new System.InvalidOperationException;
    
    public static function FromChecked<T2>(o: T2): T;
    public static function FromUnchecked<T2>(o: T2): T;
    public static function From<T2>(o: T2; checked: boolean := true) :=
      if checked then FromChecked(o) else FromUnchecked(o);
    
  end;
  
  {$endregion Convert}
  
implementation

uses System.Linq.Expressions;

{$region Convert}

type ConvertCache<T1,T2> = sealed class
  
  private constructor := raise new System.InvalidOperationException;
  
  public static checked, unchecked: T2->T1;
  private static function MakeFunc(conv: (Expression,System.Type)->Expression): T2->T1;
  begin
    try
      var p := Expression.Parameter(typeof(T2));
      var c := conv(p, typeof(T1));
      var l := Expression.Lambda&<Func<T2, T1>>(c, p);
      Result := l.Compile();
    except
      on e: Exception do
      begin
        Result := o->
        begin
          Result := default(T1);
          raise new System.InvalidCastException($'Failed to make [{TypeToTypeName(typeof(T2))}]=>[{TypeToTypeName(typeof(T1))}] conversion', e);
        end;
        exit;
      end;
    end;
    
  end;
  static constructor;
  begin
    checked := MakeFunc(Expression.ConvertChecked);
    unchecked := MakeFunc(Expression.Convert);
  end;
  
end;

static function ConvertTo<T>.FromChecked<T2>(o: T2) :=
  ConvertCache&<T,T2>.checked(o);
static function ConvertTo<T>.FromUnchecked<T2>(o: T2) :=
  ConvertCache&<T,T2>.unchecked(o);

{$endregion Convert}

end.