
{%../../Common/LicenseHeader.txt%}

///
///Код переведён отсюда:
///   https://github.com/KhronosGroup/OpenCL-Docs/tree/master/xml
///
///Спецификации всех версий OpenCL:
///   https://www.khronos.org/registry/OpenCL/
///
///Если чего-либо не хватает, или найдена ошибка - писать сюда:
///   https://github.com/SunSerega/POCGL/issues
///
unit OpenCL;

{$zerobasedstrings}

interface

uses System;
uses System.Runtime.InteropServices;
uses System.Runtime.CompilerServices;

type
  
  {$region Вспомогательные типы}
  
  {%Types.Interface!Pack Essentials.pas%}
  
  {$endregion Вспомогательные типы}
  
  {$region Особые типы}
  {%!!}clErrorCode = record procedure RaiseIfError; end;{%}
  OpenCLException = sealed class(Exception)
    private ec: clErrorCode;
    public property Code: clErrorCode read ec;
    
    public constructor(ec: clErrorCode; message: string);
    begin
      inherited Create(message);
      self.ec := ec;
    end;
    
    public constructor(ec: clErrorCode) :=
      Create(ec, $'Ошибка OpenCL: {ec}');
    
  end;
  
  {$endregion Особые типы}
  
  {$region Подпрограммы ядра}
  
  {%Feature.Interface!Pack Essentials.pas%}
  
  {$endregion Подпрограммы ядра}
  
  {$region Подпрограммы расширений}
  
  {%Extension.Interface!Pack Essentials.pas%}
  
  {$endregion Подпрограммы расширений}
  
implementation

procedure clErrorCode.RaiseIfError :=
  {%>if IS_ERROR then%} raise new OpenCLException(self);

end.