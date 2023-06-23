unit Logic;

function ValRaise<T>(ex: Exception): T;
begin
  Result := default(T);
  raise ex;
end;

type
  EDEncoding = sealed class(System.Text.UTF8Encoding)
    private constructor := inherited Create(true);
    public static Instance := new EDEncoding;
  end;
  
end.