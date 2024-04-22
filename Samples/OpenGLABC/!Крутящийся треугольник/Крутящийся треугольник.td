


#Delegates
OpenGL.$delegate? = function(program: gl_program; name: IntPtr): integer
OpenGL.$delegate? = function(program: gl_program; name: IntPtr): integer
OpenGL.$delegate? = function(type: glShaderType): gl_shader
OpenGL.$delegate? = function: glErrorCode
OpenGL.$delegate? = function: gl_program
OpenGL.$delegate? = procedure
OpenGL.$delegate? = procedure(attribindex: longword; size: integer; type: glVertexAttribType; normalized: glBool8; relativeoffset: longword)
OpenGL.$delegate? = procedure(bindingindex: longword; buffer: gl_buffer; offset: IntPtr; stride: integer)
OpenGL.$delegate? = procedure(buffer: gl_buffer; size: UIntPtr; data: IntPtr; usage: glVertexBufferObjectUsage)
OpenGL.$delegate? = procedure(buffer: gl_buffer; size: UIntPtr; var data: byte; usage: glVertexBufferObjectUsage)
OpenGL.$delegate? = procedure(index: longword)
OpenGL.$delegate? = procedure(location: integer; v0: single)
OpenGL.$delegate? = procedure(mask: glClearBufferMask)
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
OpenGLABC.RedrawThreadProc = procedure(pl: IGLPlatformLoader; EndFrame: procedure)

#ReqModules
OpenGL+OpenGLABC


