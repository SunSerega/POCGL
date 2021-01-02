
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

interface

uses System;
uses System.Runtime.InteropServices;
uses System.Runtime.CompilerServices;

type
  
  {$region Записи-имена}
  
  {%NameRecords!Pack NameRecords.pas!Stub=}Stub = class end;{%}
  
  {$endregion Записи-имена}
  
  {$region Перечисления}
  
  {%Groups!Pack Most.pas%}
  
  {$endregion Перечисления}
  
  {$region Делегаты}
  
  {%Static\Delegates%}
  
  {$endregion Делегаты}
  
  {$region Записи}
  
  {%VecTypes!Pack VecTypes.pas%}
  
  {%MtrTypes!Pack MtrTypes.pas%}
  
  {$region Misc}
  
  {%Structs!Pack Most.pas%}
  
  {$endregion Misc}
  
  {$endregion Записи}
  
  {$region Другие типы}
  
  {%Static\MiscTypes%}
  
  {$endregion Другие типы}
  
  {$region Внешние external перегрузки функций}
  
  {%FuncsNtv!Pack Most.pas%}
  
  {$endregion Внешние external перегрузки функций}
  
  {$region Функции}
  
  {%Funcs!Pack Most.pas%}
  
  {$endregion Функции}
  
  {$region Платформы}
  
  {%Static\Platforms%}
  
  {$endregion Платформы}
  
  {$region GDI}
  
  {%Static\GDIIntegration%}
  
  {$endregion GDI}
  
implementation

{%MtrExt!Pack MtrExt.pas%}

end.