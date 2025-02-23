
{%../../Common/LicenseHeader.txt%}

unit Dummy;

{%../Common/DebugHeader.pas%}

{$zerobasedstrings}

interface

uses System;
uses System.Runtime.InteropServices;
uses System.Runtime.CompilerServices;

{$ifdef ForceMaxDebug}
var gen_debug_otp: System.IO.TextWriter := Console.Out;
{$endif ForceMaxDebug}

type
  
  {$region DEBUG}
  
  {%../Common/DebugTypes.pas%}
  
  {$endregion DEBUG}
  
  {$region Вспомогательные типы}
  
  EnumBase = UInt32;
  
  {%Types.Interface!Pack Essentials.pas%}
  
  {$endregion Вспомогательные типы}
  
  {$region Особые типы}
  
  DummyLoader = abstract class
    
    public function GetProcAddress(name: string): IntPtr; abstract;
    
  end;
  
  {$endregion Особые типы}
  
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
    public loader: DummyLoader;
    
    public constructor(loader: DummyLoader) := self.loader := loader;
    private constructor := raise new NotSupportedException;
    
  end;
  
{$endregion Особые типы}

{$region Подпрограммы ядра}

{%Feature.Implementation!Pack Essentials.pas%}

{$endregion Подпрограммы ядра}

{$region Подпрограммы расширений}

{%Extension.Implementation!Pack Essentials.pas%}

{$endregion Подпрограммы расширений}

{$ifdef ForceMaxDebug}
type
  FinalDebugChecks = static class
    private static checked := false;
    public static procedure Check;
    begin
      if checked then exit;
      checked := true;
      
      {$ifdef CallDebug}
      CallDebug.FinallyReport;
      {$endif CallDebug}
      
      gen_debug_otp.Flush;
    end;
  end;
  
initialization
finalization
  FinalDebugChecks.Check;
{$endif ForceMaxDebug}
end.