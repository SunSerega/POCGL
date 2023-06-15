
{%..\LicenseHeader%}

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
  
  {%Structs!Pack Most.pas%}
  
  {$endregion Записи}
  
  {$region Другие типы}
  
  {%Static\MiscTypes%}
  
  {$endregion Другие типы}
  
  {$region Функции}
  
  {%Funcs!Pack Most.pas%}
  
  {$endregion Функции}
  
implementation

{$region Misc}

{%Static\MiscImpl%}

{$endregion Misc}

end.