


#Delegates
OpenGL.$delegate? = function(type: glShaderType): gl_shader
OpenGL.$delegate? = function: glErrorCode
OpenGL.$delegate? = function: gl_program
OpenGL.$delegate? = procedure
OpenGL.$delegate? = procedure(buffer: gl_buffer; offset: IntPtr; size: UIntPtr; data: IntPtr)
OpenGL.$delegate? = procedure(buffer: gl_buffer; offset: IntPtr; size: UIntPtr; data: Void*)
OpenGL.$delegate? = procedure(buffer: gl_buffer; offset: IntPtr; size: UIntPtr; var data: byte)
OpenGL.$delegate? = procedure(buffer: gl_buffer; offset: IntPtr; size: UIntPtr; var data: byte)
OpenGL.$delegate? = procedure(buffer: gl_buffer; size: UIntPtr; data: IntPtr; usage: glVertexBufferObjectUsage)
OpenGL.$delegate? = procedure(buffer: gl_buffer; size: UIntPtr; var data: byte; usage: glVertexBufferObjectUsage)
OpenGL.$delegate? = procedure(location: integer; count: integer; value: IntPtr)
OpenGL.$delegate? = procedure(location: integer; count: integer; value: IntPtr)
OpenGL.$delegate? = procedure(location: integer; count: integer; var value: Vec2d)
OpenGL.$delegate? = procedure(location: integer; count: integer; var value: Vec2i)
OpenGL.$delegate? = procedure(location: integer; count: integer; var value: integer)
OpenGL.$delegate? = procedure(location: integer; count: integer; var value: real)
OpenGL.$delegate? = procedure(location: integer; v0: integer)
OpenGL.$delegate? = procedure(location: integer; x: real)
OpenGL.$delegate? = procedure(mode: glPrimitiveType; first: integer; count: integer)
OpenGL.$delegate? = procedure(n: integer; buffers: IntPtr)
OpenGL.$delegate? = procedure(n: integer; var buffers: gl_buffer)
OpenGL.$delegate? = procedure(program: gl_program)
OpenGL.$delegate? = procedure(program: gl_program)
OpenGL.$delegate? = procedure(program: gl_program)
OpenGL.$delegate? = procedure(program: gl_program; bufSize: integer; length: IntPtr; infoLog: IntPtr)
OpenGL.$delegate? = procedure(program: gl_program; bufSize: integer; var length: integer; infoLog: IntPtr)
OpenGL.$delegate? = procedure(program: gl_program; pname: glProgramProperty; params: IntPtr)
OpenGL.$delegate? = procedure(program: gl_program; pname: glProgramProperty; var params: integer)
OpenGL.$delegate? = procedure(program: gl_program; shader: gl_shader)
OpenGL.$delegate? = procedure(shader: gl_shader)
OpenGL.$delegate? = procedure(shader: gl_shader)
OpenGL.$delegate? = procedure(shader: gl_shader; bufSize: integer; length: IntPtr; infoLog: IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; bufSize: integer; var length: integer; infoLog: IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; string: Void*; length: IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; string: Void*; var length: integer)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; var string: IntPtr; length: IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; var string: IntPtr; var length: integer)
OpenGL.$delegate? = procedure(shader: gl_shader; pname: glShaderParameterName; params: IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; pname: glShaderParameterName; var params: integer)
OpenGL.$delegate? = procedure(target: glBufferTarget; index: longword; buffer: gl_buffer)
OpenGL.$delegate? = procedure(x: integer; y: integer; width: integer; height: integer)
OpenGLABC.RedrawThreadProc = procedure(pl: IGLPlatformLoader; EndFrame: procedure)
Точки.$delegate? = function(<>X: integer; <>Y: integer): Vec2d
Точки.$delegate? = function(<>pos: Vec2d): integer
Точки.$delegate? = function(X: integer; Y: integer): Vec2d
Точки.$delegate? = function(pos: Vec2d): integer

#ReqModules
OpenGL+OpenGLABC


