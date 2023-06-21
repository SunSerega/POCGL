
{%..\..\Common\LicenseHeader.txt%}

/// Внутренний модуль POCGL для тестирования кодогенераторов
unit Dummy;

{$zerobasedstrings}

interface

uses System;
uses System.Runtime.InteropServices;
uses System.Runtime.CompilerServices;

type
  
  {$region Особые типы}
  
  EnumBase = UInt32;
  
  PlatformLoader = abstract class
    
    public function GetProcAddress(name: string): IntPtr; abstract;
    
  end;
  
  {$endregion Особые типы}
  
  {$region Вспомогательные типы}
  
  {%Types.Interface!Pack Essentials.pas%}
  
  {$endregion Вспомогательные типы}
  
  {$region Подпрограммы ядра}
  
  {%Feature.Interface!Pack Essentials.pas%}
  
  {$endregion Подпрограммы ядра}
  
  {$region Подпрограммы расширений}
  
  {%Extension.Interface!Pack Essentials.pas%}
  
  {$endregion Подпрограммы расширений}
  
implementation

{$region Вспомогательные типы}

{%Types.Implementation!Pack Essentials.pas%}

{$endregion Вспомогательные типы}

{$region Особые типы}

type
  api_with_loader = abstract class
    public loader: PlatformLoader;
    
    public constructor(loader: PlatformLoader) := self.loader := loader;
    private constructor := raise new NotSupportedException;
    
  end;
  
{$endregion Особые типы}

{$region Подпрограммы ядра}

{%Feature.Implementation!Pack Essentials.pas%}

{$endregion Подпрограммы ядра}

{$region Подпрограммы расширений}

{%Extension.Implementation!Pack Essentials.pas%}

{$endregion Подпрограммы расширений}

end.