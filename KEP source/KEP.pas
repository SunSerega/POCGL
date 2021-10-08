unit KEP;
{$zerobasedstrings}

interface

uses System;

uses PathUtils  in {%>'..\..\PathUtils' !!}'..\PathUtils'{%};
uses Parsing    in {%>'..\..\Parsing'   !!}'..\Parsing'{%};

type
  ParseException = sealed class(Exception)
    
  end;
  
  KMP_input<TData> = record
    private data: TData;
    private sub_inputs: array of KMP_input<TData> := nil;
    
    public static function operator implicit(data: TData): KMP_input<TData>;
    begin
      Result.data := data;
    end;
    public static function operator implicit(sub_inputs: array of KMP_input<TData>): KMP_input<TData>;
    begin
      Result.sub_inputs := sub_inputs;
    end;
    
    public static function operator explicit(input: KMP_input<TData>): TData;
    begin
      if sub_inputs<>nil then raise new System.InvalidOperationException;
      Result := input.data;
    end;
    public property SubInput[ind: integer] read sub_inputs[ind];
    
  end;
  
  {$region Generated}
  
  {%interface%}
  
  {$endregion Generated}
  
implementation

{$region Generated}

{%implementation%}

{$endregion Generated}

end.