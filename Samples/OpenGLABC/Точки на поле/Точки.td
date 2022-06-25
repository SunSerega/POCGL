


#Delegates
OpenGL.$delegate? = procedure(program: gl_program; shader: gl_shader)
OpenGL.$delegate? = procedure(target: BufferTarget; index: longword; buffer: gl_buffer)
OpenGL.$delegate? = procedure(shader: gl_shader)
OpenGL.$delegate? = procedure(n: integer; buffers: System.IntPtr)
OpenGL.$delegate? = procedure(n: integer; var buffers: gl_buffer)
OpenGL.$delegate? = function: gl_program
OpenGL.$delegate? = function(type: ShaderType): gl_shader
OpenGL.$delegate? = procedure(program: gl_program)
OpenGL.$delegate? = procedure(shader: gl_shader)
OpenGL.$delegate? = procedure(mode: PrimitiveType; first: integer; count: integer)
OpenGL.$delegate? = procedure
OpenGL.$delegate? = function: ErrorCode
OpenGL.$delegate? = procedure(program: gl_program; bufSize: integer; length: System.IntPtr; infoLog: System.IntPtr)
OpenGL.$delegate? = procedure(program: gl_program; bufSize: integer; var length: integer; infoLog: System.IntPtr)
OpenGL.$delegate? = procedure(program: gl_program; pname: ProgramProperty; params: System.IntPtr)
OpenGL.$delegate? = procedure(program: gl_program; pname: ProgramProperty; var params: integer)
OpenGL.$delegate? = procedure(shader: gl_shader; bufSize: integer; length: System.IntPtr; infoLog: System.IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; bufSize: integer; var length: integer; infoLog: System.IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; pname: ShaderParameterName; params: System.IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; pname: ShaderParameterName; var params: integer)
OpenGL.$delegate? = procedure(program: gl_program)
OpenGL.$delegate? = procedure(buffer: gl_buffer; size: System.UIntPtr; data: Void*; usage: VertexBufferObjectUsage)
OpenGL.$delegate? = procedure(buffer: gl_buffer; size: System.UIntPtr; var data: byte; usage: VertexBufferObjectUsage)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; _string: Void*; length: System.IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; _string: Void*; var length: integer)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; var _string: System.IntPtr; length: System.IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; var _string: System.IntPtr; var length: integer)
OpenGL.$delegate? = procedure(location: integer; x: real)
OpenGL.$delegate? = procedure(location: integer; v0: integer)
OpenGL.$delegate? = procedure(location: integer; count: integer; value: System.IntPtr)
OpenGL.$delegate? = procedure(location: integer; count: integer; var value: real)
OpenGL.$delegate? = procedure(location: integer; count: integer; var value: Vec2d)
OpenGL.$delegate? = procedure(program: gl_program)
OpenGL.$delegate? = procedure(x: integer; y: integer; width: integer; height: integer)
OpenGLABC.RedrawThreadProc = procedure(pl: PlatformLoader; EndFrame: procedure)
Точки.$delegate? = function(X: integer; Y: integer): Vec2d
Точки.$delegate? = function(pos: Vec2d): integer
Точки.$delegate? = function(<>X: integer; <>Y: integer): Vec2d
Точки.$delegate? = function(<>pos: Vec2d): integer

#ReqModules
OpenGL+OpenGLABC


