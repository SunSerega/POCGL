unit Common;
//TODO Убрать из этой папки. Добавил временно для тестирования

//TODO Костыль чтобы получать одинаковые .exe при каждой компиляции
// - Сейчас компилятор загружает все перегрузки методов вроде gl.GetProgramInfoLog
// - Но только при первой компиляции (когда Common.pcu не существует)
// - Ему это нужно чтобы проверить, какая перегрузка подходит
// - Но эти перегрузки сразу добавляет в .exe, даже если они не подходят
{$savepcu false}

uses System;
uses OpenGL;

var gl: OpenGL.gl;

{$region Shader}

function InitShaderText(sources: array of string; source_name: string; st: glShaderType): gl_shader;
begin
  Result := gl.CreateShader(st);
  
  gl.ShaderSource(Result, 1, sources, nil);
  
  gl.CompileShader(Result);
  // Получаем состояние успешности компиляции
  // 1=успешно
  // 0=ошибка
  var comp_ok: integer;
  gl.GetShaderiv(Result, glShaderParameterName.COMPILE_STATUS, comp_ok);
  if comp_ok = 0 then
  begin
    
    // Узнаём нужную длинну строки
    var l: integer;
    gl.GetShaderiv(Result, glShaderParameterName.INFO_LOG_LENGTH, l);
    
    // Выделяем достаточно памяти чтоб сохранить строку
    var ptr := System.Runtime.InteropServices.Marshal.AllocHGlobal(l);
    
    // Получаем строку логов
    gl.GetShaderInfoLog(Result, l, IntPtr.Zero, ptr);
    
    // Преобразовываем в управляемую строку
    var log := System.Runtime.InteropServices.Marshal.PtrToStringAnsi(ptr);
    
    // И в конце обязательно освобождаем, чтобы не было утечек памяти
    // Вообще освобождать лучше бы или в finally, или в override метода Finalize
    // Но тут это только усложнит всё
    System.Runtime.InteropServices.Marshal.FreeHGlobal(ptr);
    gl.DeleteShader(Result);
    
    raise new System.ArgumentException($'{source_name}:{#10}{log}');
  end;
  
end;
function InitShaderFile(fname: string; st: glShaderType) := InitShaderText(|ReadAllText(fname)|, fname, st);
function InitShaderResource(sname: string; st: glShaderType) := InitShaderText(|
  System.IO.StreamReader.Create(
    System.Reflection.Assembly.GetCallingAssembly.GetManifestResourceStream(sname)
  ).ReadToEnd
|, sname, st);

{$endregion Shader}

{$region Program}

function InitProgram(params shaders: array of gl_shader): gl_program;
begin
  Result := gl.CreateProgram;
  
  foreach var sh in shaders do
    gl.AttachShader(Result, sh);
  
  gl.LinkProgram(Result);
  // Всё то же самое что и у шейдеров
  var link_ok: integer;
  gl.GetProgramiv(Result, glProgramProperty.LINK_STATUS, link_ok);
  if link_ok = 0 then
  begin
    
    var l: integer;
    gl.GetProgramiv(Result, glProgramProperty.INFO_LOG_LENGTH, l);
    var ptr := System.Runtime.InteropServices.Marshal.AllocHGlobal(l);
    
    gl.GetProgramInfoLog(Result, l, IntPtr.Zero, ptr);
    var log := System.Runtime.InteropServices.Marshal.PtrToStringAnsi(ptr);
    
    System.Runtime.InteropServices.Marshal.FreeHGlobal(ptr);
    gl.DeleteProgram(Result);
    
    raise new System.ArgumentException(log);
  end;
  
end;

{$endregion Program}

end.