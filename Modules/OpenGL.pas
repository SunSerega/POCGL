
{%../../Common/LicenseHeader.txt%}

///
///Код переведён отсюда:
///   https://github.com/KhronosGroup/OpenGL-Registry/tree/master/xml
///
///Спецификации всех версий OpenGL:
///   https://www.khronos.org/registry/OpenGL/specs/gl/
///
///Если чего-либо не хватает, или найдена ошибка - писать сюда:
///   https://github.com/SunSerega/POCGL/issues
///
unit OpenGL;

{$zerobasedstrings}

interface

uses System;
uses System.Runtime.InteropServices;
uses System.Runtime.CompilerServices;

type
  DummyEnum = UInt32;
  DummyFlags = UInt32;
  
  {$region Вспомогательные типы}
  
  {%Types.Interface!Pack Essentials.pas%}
  
  {$endregion Вспомогательные типы}
  
  {$region Особые типы}
  
  {%!!}glErrorCode = record procedure RaiseIfError; end;{%}
  OpenGLException = sealed class(Exception)
    private ec: glErrorCode;
    public property Code: glErrorCode read ec;
    
    public constructor(ec: glErrorCode; message: string);
    begin
      inherited Create(message);
      self.ec := ec;
    end;
    
    public constructor(ec: glErrorCode) :=
      Create(ec, $'Ошибка OpenGL: {ec}');
    
  end;
  
  IGLPlatformLoader = abstract class
    
    public function GetProcAddress(name: string): IntPtr; abstract;
    
  end;
  
  {$endregion Особые типы}
  
  {$region Подпрограммы ядра}
  
  {%Feature.Interface!Pack Essentials.pas%}
  
  {$endregion Подпрограммы ядра}
  
  {$region Подпрограммы расширений}
  
  {%Extension.Interface!Pack Essentials.pas%}
  
  {$endregion Подпрограммы расширений}
  
  {$region Загрузчики известных платформ}
  
  glPlWin = sealed class(IGLPlatformLoader)
    
    private static function LoadLibrary(name: string): IntPtr;
    external 'kernel32.dll';
    private static lib := LoadLibrary('opengl32.dll');
    
    private static function GetProcAddress(lib: IntPtr; name: string): IntPtr;
    external 'kernel32.dll';
    public function GetProcAddress(name: string): IntPtr; override;
    begin
      {%>Result := wgl.GetProcAddress(name);%} if Result<>IntPtr.Zero then exit;
      Result := GetProcAddress(lib,name); if Result<>IntPtr.Zero then exit;
    end;
    
  end;
  
  glPlX = sealed class(IGLPlatformLoader)
    
    public function GetProcAddress(name: string): IntPtr; override;
    begin
      {%>Result := glx.GetProcAddress(name);%} if Result<>IntPtr.Zero then exit;
      //TODO Then try from 'libGL.so.1'
    end;
    
  end;
  
  {$endregion Загрузчики известных платформ}
  
implementation

{$region Вспомогательные типы}

{%Types.Implementation!Pack Essentials.pas%}

{$endregion Вспомогательные типы}

{$region Особые типы}

type
  api_with_loader = abstract class
    public loader: IGLPlatformLoader;
    
    public constructor(loader: IGLPlatformLoader) := self.loader := loader;
    private constructor := raise new NotSupportedException;
    
  end;
  
procedure glErrorCode.RaiseIfError :=
  {%>if IS_ERROR then%} raise new OpenGLException(self);

{$endregion Особые типы}

{$region Инициализаторы ядра}

{%Feature.Implementation!Pack Essentials.pas%}

{$endregion Инициализаторы ядра}

{$region Инициализаторы расширений}

{%Extension.Implementation!Pack Essentials.pas%}

{$endregion Инициализаторы расширений}

end.