


#Delegates
OpenGL.$delegate? = procedure(program: gl_program; shader: gl_shader)
OpenGL.$delegate? = procedure(bindingindex: longword; buffer: gl_buffer; offset: System.IntPtr; stride: integer)
OpenGL.$delegate? = procedure(mask: ClearBufferMask)
OpenGL.$delegate? = procedure(shader: gl_shader)
OpenGL.$delegate? = procedure(n: integer; buffers: System.IntPtr)
OpenGL.$delegate? = procedure(n: integer; buffers: gl_buffer&)
OpenGL.$delegate? = function: gl_program
OpenGL.$delegate? = function(type: ShaderType): gl_shader
OpenGL.$delegate? = procedure(program: gl_program)
OpenGL.$delegate? = procedure(shader: gl_shader)
OpenGL.$delegate? = procedure(mode: PrimitiveType; first: integer; count: integer)
OpenGL.$delegate? = procedure(index: longword)
OpenGL.$delegate? = procedure
OpenGL.$delegate? = function(program: gl_program; name: System.IntPtr): integer
OpenGL.$delegate? = function: ErrorCode
OpenGL.$delegate? = procedure(program: gl_program; bufSize: integer; length: System.IntPtr; infoLog: System.IntPtr)
OpenGL.$delegate? = procedure(program: gl_program; bufSize: integer; length: Int32&; infoLog: System.IntPtr)
OpenGL.$delegate? = procedure(program: gl_program; pname: ProgramProperty; params: System.IntPtr)
OpenGL.$delegate? = procedure(program: gl_program; pname: ProgramProperty; params: Int32&)
OpenGL.$delegate? = procedure(shader: gl_shader; bufSize: integer; length: System.IntPtr; infoLog: System.IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; bufSize: integer; length: Int32&; infoLog: System.IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; pname: ShaderParameterName; params: System.IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; pname: ShaderParameterName; params: Int32&)
OpenGL.$delegate? = function(program: gl_program; name: System.IntPtr): integer
OpenGL.$delegate? = procedure(program: gl_program)
OpenGL.$delegate? = procedure(buffer: gl_buffer; size: System.UIntPtr; data: Void*; usage: VertexBufferObjectUsage)
OpenGL.$delegate? = procedure(buffer: gl_buffer; size: System.UIntPtr; data: Byte&; usage: VertexBufferObjectUsage)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; _string: Void*; length: System.IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; _string: Void*; length: Int32&)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; _string: IntPtr&; length: System.IntPtr)
OpenGL.$delegate? = procedure(shader: gl_shader; count: integer; _string: IntPtr&; length: Int32&)
OpenGL.$delegate? = procedure(location: integer; v0: single)
OpenGL.$delegate? = procedure(program: gl_program)
OpenGL.$delegate? = procedure(attribindex: longword; size: integer; type: VertexAttribType; normalized: boolean; relativeoffset: longword)
OpenGLABC.RedrawThreadProc = procedure(pl: PlatformLoader; EndFrame: procedure)

#ReqModules
OpenGL+OpenGLABC


