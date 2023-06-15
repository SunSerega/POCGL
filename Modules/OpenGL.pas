
{%..\LicenseHeader%}

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
  
  {$region Записи-имена}
  
  {%NameRecords!Pack NameRecords.pas%}
  
  {$endregion Записи-имена}
  
  {$region Перечисления}
  
  {%Groups!Pack Most.pas%}
  
  {$endregion Перечисления}
  
  {$region Делегаты}
  
//  [UnmanagedFunctionPointer(CallingConvention.StdCall)]
//  GL_DEBUG_PROC = procedure(source: DebugSource; &type: DebugType; id: UInt32; severity: DebugSeverity; length: Int32; message_text: IntPtr; userParam: pointer);
//  
//  [UnmanagedFunctionPointer(CallingConvention.StdCall)]
//  GL_VULKAN_PROC_NV = procedure;
  
  {$endregion Делегаты}
  
  {$region Записи}
  
  {%VecTypes!Pack VecTypes.pas%}
  
  {%MtrTypes!Pack MtrTypes.pas%}
  
  {$region Misc}
  
  {%Structs!Pack Most.pas%}
  
  {$endregion Misc}
  
  {$endregion Записи}
  
  {$region Другие типы}
  
  DummyEnum = UInt32;
  DummyFlags = UInt32;
  
  OpenGLException = sealed class(Exception)
    private ec: ErrorCode;
    public property Code: ErrorCode read ec;
    
    public constructor(ec: ErrorCode);
    begin
      inherited Create($'Ошибка OpenGL: "{ec}"');
      self.ec := ec;
    end;
    
  end;
  
  PlatformLoader = abstract class
    
    public function GetProcAddress(name: string): IntPtr; abstract;
    
  end;
  
  {$endregion Другие типы}
  
  {$region Функции}
  
  {%Funcs!Pack Most.pas%}
  
  {$endregion Функции}
  
  {$region Платформы}
  
  /// Платформа Windows
  PlWin = sealed class(PlatformLoader)
    private static lib := LoadLibrary('opengl32.dll');
    
    private static function LoadLibrary(name: string): IntPtr;
    external 'kernel32.dll';
    private static function GetProcAddress(lib: IntPtr; name: string): IntPtr;
    external 'kernel32.dll';
    
    public function GetProcAddress(name: string): IntPtr; override;
    begin
      Result := wgl.GetProcAddress(name); if Result<>IntPtr.Zero then exit;
      Result := GetProcAddress(lib,name); if Result<>IntPtr.Zero then exit;
    end;
    
  end;
  
  /// Платформа XWindow (используется в UNIX-подобных системах)
  PlX = sealed class(PlatformLoader)
    
    public function GetProcAddress(name: string): IntPtr; override;
    begin
      Result := glx.GetProcAddress(name); if Result<>IntPtr.Zero then exit;
      //TODO Then try from 'libGL.so.1'
    end;
    
  end;
  
  {$endregion Платформы}
  
implementation

{$region Платформо-зависимая реализация}

type
  api_with_loader = abstract class
    public loader: PlatformLoader;
    
    public constructor(loader: PlatformLoader) := self.loader := loader;
    private constructor := raise new NotSupportedException;
    
  end;
  
{%Funcs.Implementation!Pack Most.pas%}

{$endregion Платформо-зависимая реализация}

{%MtrExt!Pack MtrExt.pas%}

end.