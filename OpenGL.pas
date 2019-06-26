
//*****************************************************************************************************\\
// Copyright (©) Cergey Latchenko ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// This code is distributed under the Unlicense
// For details see LICENSE file or this:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\
// Copyright (©) Сергей Латченко ( github.com/SunSerega | forum.mmcs.sfedu.ru/u/sun_serega )
// Этот код распространяется под Unlicense
// Для деталей смотрите в файл LICENSE или это:
// https://github.com/SunSerega/POCGL/blob/master/LICENSE
//*****************************************************************************************************\\

///
/// Код переведён отсюда:
/// https://github.com/KhronosGroup/OpenGL-Registry
///
/// Спецификация (что то типа справки):
/// https://www.khronos.org/registry/OpenGL/specs/gl/glspec46.core.pdf
///
/// Если чего то не хватает - писать сюда:
/// https://github.com/SunSerega/POCGL/issues
///
unit OpenGL;

//ToDo в самом конце - сделать прогу чтоб посмотреть какие константы по 2 раза, а каких вообще нет

uses System;
uses System.Runtime.InteropServices;

{$region Основные типы}

type
  
  GLsync                        = IntPtr;
  GLeglImageOES                 = IntPtr;
  
  QueryName                     = UInt32;
  BufferName                    = UInt32;
  ShaderName                    = UInt32;
  ProgramName                   = UInt32;
  ProgramPipelineName           = UInt32;
  
  ShaderBinaryFormat            = UInt32;
  ProgramResourceIndex          = UInt32;
  ProgramBinaryFormat           = UInt32;
  
  HGLRC                         = UInt32; //ToDo вроде это что то для связки с GDI... если в конце окажется не нужно - удалить
  
  // типы для совместимости с OpenCL
  ///--
  cl_context                    = IntPtr;
  ///--
  cl_event                      = IntPtr;
  
type
  OpenGLException = class(Exception)
    
    constructor(text: string) :=
    inherited Create($'Ошибка OpenGL: "{text}"');
    
  end;
  
{$endregion Основные типы}

{$region Энумы} type
  
  {$region case Result of}
  
  //R
  ErrorCode = record
    public val: UInt32;
    
    public const NO_ERROR =                                 $0;
    public const INVALID_ENUM =                             $500;
    public const INVALID_VALUE =                            $501;
    public const INVALID_OPERATION =                        $502;
    public const STACK_OVERFLOW =                           $503;
    public const STACK_UNDERFLOW =                          $504;
    public const OUT_OF_MEMORY =                            $505;
    public const INVALID_FRAMEBUFFER_OPERATION =            $506;
    
    public function ToString: string; override;
    begin
      var res := typeof(ErrorCode).GetFields.Where(fi->fi.IsLiteral).FirstOrDefault(prop->integer(prop.GetValue(nil)) = self.val);
      Result := res=nil?
        $'ErrorCode[${self.val:X}]':
        res.Name.ToWords('_').Select(w->w[1].ToUpper+w.Substring(1).ToLower).JoinIntoString;
    end;
    
    public procedure RaiseIfError :=
    if val<>NO_ERROR then raise new OpenGLException(self.ToString);
    
  end;
  
  {$endregion case Result of}
  
  {$region 1 значение}
  
  {$region ...Mode}
  
  //S
  BeginMode = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property POINTS:          BeginMode read new BeginMode($0000);
    public static property LINES:           BeginMode read new BeginMode($0001);
    public static property LINE_LOOP:       BeginMode read new BeginMode($0002);
    public static property LINE_STRIP:      BeginMode read new BeginMode($0003);
    public static property TRIANGLES:       BeginMode read new BeginMode($0004);
    public static property TRIANGLE_STRIP:  BeginMode read new BeginMode($0005);
    public static property TRIANGLE_FAN:    BeginMode read new BeginMode($0006);
    
  end;
  
  //S
  ReservedTimeoutMode = record
    public val: uint64;
    public constructor(val: uint64) := self.val := val;
    
    public static property GL_TIMEOUT_IGNORED:  ReservedTimeoutMode read new ReservedTimeoutMode(uint64.MaxValue);
    
  end;
  
  {$endregion ...Mode}
  
  {$region ...InfoType}
  
  //S
  SyncObjInfoType = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property OBJECT_TYPE:     SyncObjInfoType read new SyncObjInfoType($9112);
    public static property SYNC_CONDITION:  SyncObjInfoType read new SyncObjInfoType($9113);
    public static property SYNC_STATUS:     SyncObjInfoType read new SyncObjInfoType($9114);
    public static property SYNC_FLAGS:      SyncObjInfoType read new SyncObjInfoType($9115);
    
  end;
  
  //S
  QueryInfoType = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property SAMPLES_PASSED:                        QueryInfoType read new QueryInfoType($8914);
    public static property ANY_SAMPLES_PASSED:                    QueryInfoType read new QueryInfoType($8C2F);
    public static property ANY_SAMPLES_PASSED_CONSERVATIVE:       QueryInfoType read new QueryInfoType($8D6A);
    public static property PRIMITIVES_GENERATED:                  QueryInfoType read new QueryInfoType($8C87);
    public static property TRANSFORM_FEEDBACK_PRIMITIVES_WRITTEN: QueryInfoType read new QueryInfoType($8C88);
    public static property TIME_ELAPSED:                          QueryInfoType read new QueryInfoType($88BF);
    public static property TIMESTAMP:                             QueryInfoType read new QueryInfoType($8E28);
    
  end;
  
  //S
  GetQueryInfoName = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property QUERY_COUNTER_BITS:  GetQueryInfoName read new GetQueryInfoName($8864);
    public static property CURRENT_QUERY:       GetQueryInfoName read new GetQueryInfoName($8865);
    
  end;
  
  //S
  GetQueryObjectInfoName = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property RESULT:            GetQueryObjectInfoName read new GetQueryObjectInfoName($8866);
    public static property RESULT_AVAILABLE:  GetQueryObjectInfoName read new GetQueryObjectInfoName($8867);
    
  end;
  
  //S
  BufferInfoType = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property SIZE:              BufferInfoType read new BufferInfoType($8764);
    public static property USAGE:             BufferInfoType read new BufferInfoType($8765);
    public static property ACCESS:            BufferInfoType read new BufferInfoType($88BB);
    public static property ACCESS_FLAGS:      BufferInfoType read new BufferInfoType($911F);
    public static property IMMUTABLE_STORAGE: BufferInfoType read new BufferInfoType($821F);
    public static property MAPPED:            BufferInfoType read new BufferInfoType($88BC);
    public static property MAP_LENGTH:        BufferInfoType read new BufferInfoType($9120);
    public static property MAP_OFFSET:        BufferInfoType read new BufferInfoType($9121);
    public static property STORAGE_FLAGS:     BufferInfoType read new BufferInfoType($8220);
    public static property MAP_POINTER:       BufferInfoType read new BufferInfoType($88BD);
    
  end;
  
  {$endregion ...InfoType}
  
  //S
  FenceCondition = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property GL_SYNC_GPU_COMMANDS_COMPLETE: FenceCondition read new FenceCondition($9117);
    
  end;
  
  //S
  BufferBindType = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property ARRAY_BUFFER:              BufferBindType read new BufferBindType($8892);
    public static property ATOMIC_COUNTER_BUFFER:     BufferBindType read new BufferBindType($92C0);
    public static property COPY_READ_BUFFER:          BufferBindType read new BufferBindType($8F36);
    public static property COPY_WRITE_BUFFER:         BufferBindType read new BufferBindType($8F37);
    public static property DISPATCH_INDIRECT_BUFFER:  BufferBindType read new BufferBindType($90EE);
    public static property DRAW_INDIRECT_BUFFER:      BufferBindType read new BufferBindType($8F3F);
    public static property ELEMENT_ARRAY_BUFFER:      BufferBindType read new BufferBindType($8893);
    public static property PIXEL_PACK_BUFFER:         BufferBindType read new BufferBindType($88EB);
    public static property PIXEL_UNPACK_BUFFER:       BufferBindType read new BufferBindType($88EC);
    public static property QUERY_BUFFER:              BufferBindType read new BufferBindType($9192);
    public static property SHADER_STORAGE_BUFFER:     BufferBindType read new BufferBindType($90D2);
    public static property TEXTURE_BUFFER:            BufferBindType read new BufferBindType($8C2A);
    public static property TRANSFORM_FEEDBACK_BUFFER: BufferBindType read new BufferBindType($8C8E);
    public static property UNIFORM_BUFFER:            BufferBindType read new BufferBindType($8A11);
    
  end;
  
  //S
  BufferDataUsage = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property STREAM_DRAW:   BufferDataUsage read new BufferDataUsage($88E0);
    public static property STREAM_READ:   BufferDataUsage read new BufferDataUsage($88E1);
    public static property STREAM_COPY:   BufferDataUsage read new BufferDataUsage($88E2);
    public static property STATIC_DRAW:   BufferDataUsage read new BufferDataUsage($88E4);
    public static property STATIC_READ:   BufferDataUsage read new BufferDataUsage($88E5);
    public static property STATIC_COPY:   BufferDataUsage read new BufferDataUsage($88E6);
    public static property DYNAMIC_DRAW:  BufferDataUsage read new BufferDataUsage($88E8);
    public static property DYNAMIC_READ:  BufferDataUsage read new BufferDataUsage($88E9);
    public static property DYNAMIC_COPY:  BufferDataUsage read new BufferDataUsage($88EA);
    
  end;
  
  //S
  InternalDataFormat = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property R8:        InternalDataFormat read new InternalDataFormat($8229);
    public static property R8I:       InternalDataFormat read new InternalDataFormat($8231);
    public static property R8UI:      InternalDataFormat read new InternalDataFormat($8232);
    public static property R16:       InternalDataFormat read new InternalDataFormat($822A);
    public static property R16I:      InternalDataFormat read new InternalDataFormat($8233);
    public static property R16UI:     InternalDataFormat read new InternalDataFormat($8234);
    public static property R16F:      InternalDataFormat read new InternalDataFormat($822D);
    public static property R32I:      InternalDataFormat read new InternalDataFormat($8235);
    public static property R32UI:     InternalDataFormat read new InternalDataFormat($8236);
    public static property R32F:      InternalDataFormat read new InternalDataFormat($822E);
    
    public static property RG8:       InternalDataFormat read new InternalDataFormat($822B);
    public static property RG8I:      InternalDataFormat read new InternalDataFormat($8237);
    public static property RG8UI:     InternalDataFormat read new InternalDataFormat($8238);
    public static property RG16:      InternalDataFormat read new InternalDataFormat($822C);
    public static property RG16I:     InternalDataFormat read new InternalDataFormat($8239);
    public static property RG16UI:    InternalDataFormat read new InternalDataFormat($823A);
    public static property RG16F:     InternalDataFormat read new InternalDataFormat($822F);
    public static property RG32I:     InternalDataFormat read new InternalDataFormat($823B);
    public static property RG32UI:    InternalDataFormat read new InternalDataFormat($823C);
    public static property RG32F:     InternalDataFormat read new InternalDataFormat($8230);
    
    public static property RGB8:      InternalDataFormat read new InternalDataFormat($8051);
    public static property RGB8I:     InternalDataFormat read new InternalDataFormat($8D8F);
    public static property RGB8UI:    InternalDataFormat read new InternalDataFormat($8D7D);
    public static property RGB16:     InternalDataFormat read new InternalDataFormat($8054);
    public static property RGB16I:    InternalDataFormat read new InternalDataFormat($8D89);
    public static property RGB16UI:   InternalDataFormat read new InternalDataFormat($8D77);
    public static property RGB16F:    InternalDataFormat read new InternalDataFormat($881B);
    public static property RGB32I:    InternalDataFormat read new InternalDataFormat($8D83);
    public static property RGB32UI:   InternalDataFormat read new InternalDataFormat($8D71);
    public static property RGB32F:    InternalDataFormat read new InternalDataFormat($8815);
    
    public static property RGBA8:     InternalDataFormat read new InternalDataFormat($8058);
    public static property RGBA16:    InternalDataFormat read new InternalDataFormat($805B);
    public static property RGBA16F:   InternalDataFormat read new InternalDataFormat($881A);
    public static property RGBA32F:   InternalDataFormat read new InternalDataFormat($8814);
    public static property RGBA8I:    InternalDataFormat read new InternalDataFormat($8D8E);
    public static property RGBA16I:   InternalDataFormat read new InternalDataFormat($8D88);
    public static property RGBA32I:   InternalDataFormat read new InternalDataFormat($8D82);
    public static property RGBA8UI:   InternalDataFormat read new InternalDataFormat($8D7C);
    public static property RGBA16UI:  InternalDataFormat read new InternalDataFormat($8D76);
    public static property RGBA32UI:  InternalDataFormat read new InternalDataFormat($8D70);
    
    public static property RGB4:      InternalDataFormat read new InternalDataFormat($804F);
    public static property RGB5:      InternalDataFormat read new InternalDataFormat($8050);
    public static property RGB10:     InternalDataFormat read new InternalDataFormat($8052);
    public static property RGB12:     InternalDataFormat read new InternalDataFormat($8053);
    public static property RGB5_A1:   InternalDataFormat read new InternalDataFormat($8057);
    public static property RGB10_A2:  InternalDataFormat read new InternalDataFormat($8059);
    
    public static property RGBA2:     InternalDataFormat read new InternalDataFormat($8055);
    public static property RGBA4:     InternalDataFormat read new InternalDataFormat($8056);
    public static property RGBA12:    InternalDataFormat read new InternalDataFormat($805A);
    
  end;
  
  //
  DataFormat = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property RED:             DataFormat read new DataFormat($1903);
    public static property GREEN:           DataFormat read new DataFormat($1904);
    public static property BLUE:            DataFormat read new DataFormat($1905);
    public static property RG:              DataFormat read new DataFormat($8227);
    public static property RGB:             DataFormat read new DataFormat($1907);
    public static property BGR:             DataFormat read new DataFormat($80E0);
    public static property RGBA:            DataFormat read new DataFormat($1908);
    public static property BGRA:            DataFormat read new DataFormat($80E1);
    public static property RED_INTEGER:     DataFormat read new DataFormat($8D94);
    public static property GREEN_INTEGER:   DataFormat read new DataFormat($8D95);
    public static property BLUE_INTEGER:    DataFormat read new DataFormat($8D96);
    public static property RGB_INTEGER:     DataFormat read new DataFormat($8D98);
    public static property RGBA_INTEGER:    DataFormat read new DataFormat($8D99);
    public static property BGR_INTEGER:     DataFormat read new DataFormat($8D9A);
    public static property BGRA_INTEGER:    DataFormat read new DataFormat($8D9B);
    public static property RG_INTEGER:      DataFormat read new DataFormat($8228);
    public static property STENCIL_INDEX:   DataFormat read new DataFormat($1901);
    public static property DEPTH_COMPONENT: DataFormat read new DataFormat($1902);
    public static property DEPTH_STENCIL:   DataFormat read new DataFormat($84F9);
    
  end;
  
  //S
  DataType = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property BYTE:                        DataType read new DataType($1400);
    public static property UNSIGNED_BYTE:               DataType read new DataType($1401);
    public static property SHORT:                       DataType read new DataType($1402);
    public static property UNSIGNED_SHORT:              DataType read new DataType($1403);
    public static property INT:                         DataType read new DataType($1404);
    public static property UNSIGNED_INT:                DataType read new DataType($1405);
    public static property FLOAT:                       DataType read new DataType($1406);
    public static property HALF_FLOAT:                  DataType read new DataType($140B);
    public static property UNSIGNED_BYTE_3_3_2:         DataType read new DataType($8032);
    public static property UNSIGNED_SHORT_5_6_5:        DataType read new DataType($8363);
    public static property UNSIGNED_SHORT_4_4_4_4:      DataType read new DataType($8033);
    public static property UNSIGNED_SHORT_5_5_5_1:      DataType read new DataType($8034);
    public static property UNSIGNED_INT_8_8_8_8:        DataType read new DataType($8035);
    public static property UNSIGNED_INT_10_10_10_2:     DataType read new DataType($8036);
    public static property UNSIGNED_BYTE_2_3_3_REV:     DataType read new DataType($8362);
    public static property UNSIGNED_SHORT_5_6_5_REV:    DataType read new DataType($8364);
    public static property UNSIGNED_SHORT_4_4_4_4_REV:  DataType read new DataType($8365);
    public static property UNSIGNED_SHORT_1_5_5_5_REV:  DataType read new DataType($8366);
    public static property UNSIGNED_INT_8_8_8_8_REV:    DataType read new DataType($8367);
    public static property UNSIGNED_INT_2_10_10_10_REV: DataType read new DataType($8368);
    
  end;
  
  //R
  ClientWaitSyncResult = record
    public val: UInt32;
    
    public property ALREADY_SIGNALED:    boolean read self.val = $911A;
    public property TIMEOUT_EXPIRED:     boolean read self.val = $911B;
    public property CONDITION_SATISFIED: boolean read self.val = $911C;
    public property WAIT_FAILED:         boolean read self.val = $911D;
    
    public function ToString: string; override;
    begin
      var res := typeof(ClientWaitSyncResult).GetProperties.Select(prop->(prop.Name,boolean(prop.GetValue(self)))).FirstOrDefault(t->t[1]);
      Result := res=nil?
        $'ClientWaitSyncResult[{self.val}]':
        res[0];
    end;
    
  end;
  
  {$endregion 1 значение}
  
  {$region Флаги}
  
  //S
  ReservedFlags = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property NONE: ReservedFlags read new ReservedFlags($0);
    
  end;
  
  //S
  CommandFlushingBehaviorFlags = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property SYNC_FLUSH_COMMANDS:  CommandFlushingBehaviorFlags read new CommandFlushingBehaviorFlags($00000001);
    
  end;
  
  //S
  BufferMapFlags = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property READ_BIT:              BufferMapFlags read new BufferMapFlags($0001);
    public static property WRITE_BIT:             BufferMapFlags read new BufferMapFlags($0002);
    public static property INVALIDATE_RANGE_BIT:  BufferMapFlags read new BufferMapFlags($0004);
    public static property INVALIDATE_BUFFER_BIT: BufferMapFlags read new BufferMapFlags($0008);
    public static property FLUSH_EXPLICIT_BIT:    BufferMapFlags read new BufferMapFlags($0010);
    public static property UNSYNCHRONIZED_BIT:    BufferMapFlags read new BufferMapFlags($0020);
    public static property PERSISTENT_BIT:        BufferMapFlags read new BufferMapFlags($0040);
    public static property COHERENT_BIT:          BufferMapFlags read new BufferMapFlags($0080);
    
  end;
  
  //S
  BufferStorageFlags = record
    public val: UInt32;
    public constructor(val: UInt32) := self.val := val;
    
    public static property DYNAMIC_STORAGE_BIT: BufferStorageFlags read new BufferStorageFlags($0100);
    public static property CLIENT_STORAGE_BIT:  BufferStorageFlags read new BufferStorageFlags($0200);
    
    public static function operator implicit(f: BufferMapFlags): BufferStorageFlags := new BufferStorageFlags(f.val);
    
  end;
  
  {$endregion Флаги}
  
{$endregion Энумы}

{$region Делегаты}

type
  [UnmanagedFunctionPointer(CallingConvention.StdCall)]
  GLDEBUGPROC = procedure(source, &type, id, severity: UInt32; length: Int32; message_text: IntPtr; userParam: pointer);
  
  [UnmanagedFunctionPointer(CallingConvention.StdCall)]
  GLVULKANPROCNV = procedure;
  
{$endregion Делегаты}

{$region Записи} type
  
  {$region Vec}
  
  {$region Vec1}
  
  Vec1b = record
    public val0: SByte;
    
    public constructor(val0: SByte);
    begin
      self.val0 := val0;
    end;
    
    private function GetValAt(i: integer): SByte;
    begin
      case i of
        0: Result := self.val0;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    private procedure SetValAt(i: integer; val: SByte);
    begin
      case i of
        0: self.val0 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    public property val[i: integer]: SByte read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec1b): Vec1b := new Vec1b(-v.val0);
    public static function operator*(v: Vec1b; k: SByte): Vec1b := new Vec1b(v.val0*k);
    public static function operator+(v1, v2: Vec1b): Vec1b := new Vec1b(v1.val0+v2.val0);
    public static function operator-(v1, v2: Vec1b): Vec1b := new Vec1b(v1.val0-v2.val0);
    
  end;
  
  Vec1ub = record
    public val0: Byte;
    
    public constructor(val0: Byte);
    begin
      self.val0 := val0;
    end;
    
    private function GetValAt(i: integer): Byte;
    begin
      case i of
        0: Result := self.val0;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    private procedure SetValAt(i: integer; val: Byte);
    begin
      case i of
        0: self.val0 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    public property val[i: integer]: Byte read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec1ub; k: Byte): Vec1ub := new Vec1ub(v.val0*k);
    public static function operator+(v1, v2: Vec1ub): Vec1ub := new Vec1ub(v1.val0+v2.val0);
    public static function operator-(v1, v2: Vec1ub): Vec1ub := new Vec1ub(v1.val0-v2.val0);
    
    public static function operator implicit(v: Vec1b): Vec1ub := new Vec1ub(v.val0);
    public static function operator implicit(v: Vec1ub): Vec1b := new Vec1b(v.val0);
    
  end;
  
  Vec1s = record
    public val0: Int16;
    
    public constructor(val0: Int16);
    begin
      self.val0 := val0;
    end;
    
    private function GetValAt(i: integer): Int16;
    begin
      case i of
        0: Result := self.val0;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int16);
    begin
      case i of
        0: self.val0 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    public property val[i: integer]: Int16 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec1s): Vec1s := new Vec1s(-v.val0);
    public static function operator*(v: Vec1s; k: Int16): Vec1s := new Vec1s(v.val0*k);
    public static function operator+(v1, v2: Vec1s): Vec1s := new Vec1s(v1.val0+v2.val0);
    public static function operator-(v1, v2: Vec1s): Vec1s := new Vec1s(v1.val0-v2.val0);
    
    public static function operator implicit(v: Vec1b): Vec1s := new Vec1s(v.val0);
    public static function operator implicit(v: Vec1s): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec1s := new Vec1s(v.val0);
    public static function operator implicit(v: Vec1s): Vec1ub := new Vec1ub(v.val0);
    
  end;
  
  Vec1us = record
    public val0: UInt16;
    
    public constructor(val0: UInt16);
    begin
      self.val0 := val0;
    end;
    
    private function GetValAt(i: integer): UInt16;
    begin
      case i of
        0: Result := self.val0;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt16);
    begin
      case i of
        0: self.val0 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    public property val[i: integer]: UInt16 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec1us; k: UInt16): Vec1us := new Vec1us(v.val0*k);
    public static function operator+(v1, v2: Vec1us): Vec1us := new Vec1us(v1.val0+v2.val0);
    public static function operator-(v1, v2: Vec1us): Vec1us := new Vec1us(v1.val0-v2.val0);
    
    public static function operator implicit(v: Vec1b): Vec1us := new Vec1us(v.val0);
    public static function operator implicit(v: Vec1us): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec1us := new Vec1us(v.val0);
    public static function operator implicit(v: Vec1us): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec1us := new Vec1us(v.val0);
    public static function operator implicit(v: Vec1us): Vec1s := new Vec1s(v.val0);
    
  end;
  
  Vec1i = record
    public val0: Int32;
    
    public constructor(val0: Int32);
    begin
      self.val0 := val0;
    end;
    
    private function GetValAt(i: integer): Int32;
    begin
      case i of
        0: Result := self.val0;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int32);
    begin
      case i of
        0: self.val0 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    public property val[i: integer]: Int32 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec1i): Vec1i := new Vec1i(-v.val0);
    public static function operator*(v: Vec1i; k: Int32): Vec1i := new Vec1i(v.val0*k);
    public static function operator+(v1, v2: Vec1i): Vec1i := new Vec1i(v1.val0+v2.val0);
    public static function operator-(v1, v2: Vec1i): Vec1i := new Vec1i(v1.val0-v2.val0);
    
    public static function operator implicit(v: Vec1b): Vec1i := new Vec1i(v.val0);
    public static function operator implicit(v: Vec1i): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec1i := new Vec1i(v.val0);
    public static function operator implicit(v: Vec1i): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec1i := new Vec1i(v.val0);
    public static function operator implicit(v: Vec1i): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec1i := new Vec1i(v.val0);
    public static function operator implicit(v: Vec1i): Vec1us := new Vec1us(v.val0);
    
  end;
  
  Vec1ui = record
    public val0: UInt32;
    
    public constructor(val0: UInt32);
    begin
      self.val0 := val0;
    end;
    
    private function GetValAt(i: integer): UInt32;
    begin
      case i of
        0: Result := self.val0;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt32);
    begin
      case i of
        0: self.val0 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    public property val[i: integer]: UInt32 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec1ui; k: UInt32): Vec1ui := new Vec1ui(v.val0*k);
    public static function operator+(v1, v2: Vec1ui): Vec1ui := new Vec1ui(v1.val0+v2.val0);
    public static function operator-(v1, v2: Vec1ui): Vec1ui := new Vec1ui(v1.val0-v2.val0);
    
    public static function operator implicit(v: Vec1b): Vec1ui := new Vec1ui(v.val0);
    public static function operator implicit(v: Vec1ui): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec1ui := new Vec1ui(v.val0);
    public static function operator implicit(v: Vec1ui): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec1ui := new Vec1ui(v.val0);
    public static function operator implicit(v: Vec1ui): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec1ui := new Vec1ui(v.val0);
    public static function operator implicit(v: Vec1ui): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec1ui := new Vec1ui(v.val0);
    public static function operator implicit(v: Vec1ui): Vec1i := new Vec1i(v.val0);
    
  end;
  
  Vec1i64 = record
    public val0: Int64;
    
    public constructor(val0: Int64);
    begin
      self.val0 := val0;
    end;
    
    private function GetValAt(i: integer): Int64;
    begin
      case i of
        0: Result := self.val0;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int64);
    begin
      case i of
        0: self.val0 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    public property val[i: integer]: Int64 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec1i64): Vec1i64 := new Vec1i64(-v.val0);
    public static function operator*(v: Vec1i64; k: Int64): Vec1i64 := new Vec1i64(v.val0*k);
    public static function operator+(v1, v2: Vec1i64): Vec1i64 := new Vec1i64(v1.val0+v2.val0);
    public static function operator-(v1, v2: Vec1i64): Vec1i64 := new Vec1i64(v1.val0-v2.val0);
    
    public static function operator implicit(v: Vec1b): Vec1i64 := new Vec1i64(v.val0);
    public static function operator implicit(v: Vec1i64): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec1i64 := new Vec1i64(v.val0);
    public static function operator implicit(v: Vec1i64): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec1i64 := new Vec1i64(v.val0);
    public static function operator implicit(v: Vec1i64): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec1i64 := new Vec1i64(v.val0);
    public static function operator implicit(v: Vec1i64): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec1i64 := new Vec1i64(v.val0);
    public static function operator implicit(v: Vec1i64): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec1i64 := new Vec1i64(v.val0);
    public static function operator implicit(v: Vec1i64): Vec1ui := new Vec1ui(v.val0);
    
  end;
  
  Vec1ui64 = record
    public val0: UInt64;
    
    public constructor(val0: UInt64);
    begin
      self.val0 := val0;
    end;
    
    private function GetValAt(i: integer): UInt64;
    begin
      case i of
        0: Result := self.val0;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt64);
    begin
      case i of
        0: self.val0 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    public property val[i: integer]: UInt64 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec1ui64; k: UInt64): Vec1ui64 := new Vec1ui64(v.val0*k);
    public static function operator+(v1, v2: Vec1ui64): Vec1ui64 := new Vec1ui64(v1.val0+v2.val0);
    public static function operator-(v1, v2: Vec1ui64): Vec1ui64 := new Vec1ui64(v1.val0-v2.val0);
    
    public static function operator implicit(v: Vec1b): Vec1ui64 := new Vec1ui64(v.val0);
    public static function operator implicit(v: Vec1ui64): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec1ui64 := new Vec1ui64(v.val0);
    public static function operator implicit(v: Vec1ui64): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec1ui64 := new Vec1ui64(v.val0);
    public static function operator implicit(v: Vec1ui64): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec1ui64 := new Vec1ui64(v.val0);
    public static function operator implicit(v: Vec1ui64): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec1ui64 := new Vec1ui64(v.val0);
    public static function operator implicit(v: Vec1ui64): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec1ui64 := new Vec1ui64(v.val0);
    public static function operator implicit(v: Vec1ui64): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec1ui64 := new Vec1ui64(v.val0);
    public static function operator implicit(v: Vec1ui64): Vec1i64 := new Vec1i64(v.val0);
    
  end;
  
  Vec1f = record
    public val0: single;
    
    public constructor(val0: single);
    begin
      self.val0 := val0;
    end;
    
    private function GetValAt(i: integer): single;
    begin
      case i of
        0: Result := self.val0;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    private procedure SetValAt(i: integer; val: single);
    begin
      case i of
        0: self.val0 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    public property val[i: integer]: single read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec1f): Vec1f := new Vec1f(-v.val0);
    public static function operator*(v: Vec1f; k: single): Vec1f := new Vec1f(v.val0*k);
    public static function operator+(v1, v2: Vec1f): Vec1f := new Vec1f(v1.val0+v2.val0);
    public static function operator-(v1, v2: Vec1f): Vec1f := new Vec1f(v1.val0-v2.val0);
    
    public static function operator implicit(v: Vec1b): Vec1f := new Vec1f(v.val0);
    public static function operator implicit(v: Vec1f): Vec1b := new Vec1b(Convert.ToSByte(v.val0));
    
    public static function operator implicit(v: Vec1ub): Vec1f := new Vec1f(v.val0);
    public static function operator implicit(v: Vec1f): Vec1ub := new Vec1ub(Convert.ToByte(v.val0));
    
    public static function operator implicit(v: Vec1s): Vec1f := new Vec1f(v.val0);
    public static function operator implicit(v: Vec1f): Vec1s := new Vec1s(Convert.ToInt16(v.val0));
    
    public static function operator implicit(v: Vec1us): Vec1f := new Vec1f(v.val0);
    public static function operator implicit(v: Vec1f): Vec1us := new Vec1us(Convert.ToUInt16(v.val0));
    
    public static function operator implicit(v: Vec1i): Vec1f := new Vec1f(v.val0);
    public static function operator implicit(v: Vec1f): Vec1i := new Vec1i(Convert.ToInt32(v.val0));
    
    public static function operator implicit(v: Vec1ui): Vec1f := new Vec1f(v.val0);
    public static function operator implicit(v: Vec1f): Vec1ui := new Vec1ui(Convert.ToUInt32(v.val0));
    
    public static function operator implicit(v: Vec1i64): Vec1f := new Vec1f(v.val0);
    public static function operator implicit(v: Vec1f): Vec1i64 := new Vec1i64(Convert.ToInt64(v.val0));
    
    public static function operator implicit(v: Vec1ui64): Vec1f := new Vec1f(v.val0);
    public static function operator implicit(v: Vec1f): Vec1ui64 := new Vec1ui64(Convert.ToUInt64(v.val0));
    
  end;
  
  Vec1d = record
    public val0: real;
    
    public constructor(val0: real);
    begin
      self.val0 := val0;
    end;
    
    private function GetValAt(i: integer): real;
    begin
      case i of
        0: Result := self.val0;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    private procedure SetValAt(i: integer; val: real);
    begin
      case i of
        0: self.val0 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..0');
      end;
    end;
    public property val[i: integer]: real read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec1d): Vec1d := new Vec1d(-v.val0);
    public static function operator*(v: Vec1d; k: real): Vec1d := new Vec1d(v.val0*k);
    public static function operator+(v1, v2: Vec1d): Vec1d := new Vec1d(v1.val0+v2.val0);
    public static function operator-(v1, v2: Vec1d): Vec1d := new Vec1d(v1.val0-v2.val0);
    
    public static function operator implicit(v: Vec1b): Vec1d := new Vec1d(v.val0);
    public static function operator implicit(v: Vec1d): Vec1b := new Vec1b(Convert.ToSByte(v.val0));
    
    public static function operator implicit(v: Vec1ub): Vec1d := new Vec1d(v.val0);
    public static function operator implicit(v: Vec1d): Vec1ub := new Vec1ub(Convert.ToByte(v.val0));
    
    public static function operator implicit(v: Vec1s): Vec1d := new Vec1d(v.val0);
    public static function operator implicit(v: Vec1d): Vec1s := new Vec1s(Convert.ToInt16(v.val0));
    
    public static function operator implicit(v: Vec1us): Vec1d := new Vec1d(v.val0);
    public static function operator implicit(v: Vec1d): Vec1us := new Vec1us(Convert.ToUInt16(v.val0));
    
    public static function operator implicit(v: Vec1i): Vec1d := new Vec1d(v.val0);
    public static function operator implicit(v: Vec1d): Vec1i := new Vec1i(Convert.ToInt32(v.val0));
    
    public static function operator implicit(v: Vec1ui): Vec1d := new Vec1d(v.val0);
    public static function operator implicit(v: Vec1d): Vec1ui := new Vec1ui(Convert.ToUInt32(v.val0));
    
    public static function operator implicit(v: Vec1i64): Vec1d := new Vec1d(v.val0);
    public static function operator implicit(v: Vec1d): Vec1i64 := new Vec1i64(Convert.ToInt64(v.val0));
    
    public static function operator implicit(v: Vec1ui64): Vec1d := new Vec1d(v.val0);
    public static function operator implicit(v: Vec1d): Vec1ui64 := new Vec1ui64(Convert.ToUInt64(v.val0));
    
    public static function operator implicit(v: Vec1f): Vec1d := new Vec1d(v.val0);
    public static function operator implicit(v: Vec1d): Vec1f := new Vec1f(v.val0);
    
  end;
  {$endregion Vec1}
  
  {$region Vec2}
  
  Vec2b = record
    public val0: SByte;
    public val1: SByte;
    
    public constructor(val0, val1: SByte);
    begin
      self.val0 := val0;
      self.val1 := val1;
    end;
    
    private function GetValAt(i: integer): SByte;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(i: integer; val: SByte);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    public property val[i: integer]: SByte read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec2b): Vec2b := new Vec2b(-v.val0, -v.val1);
    public static function operator*(v: Vec2b; k: SByte): Vec2b := new Vec2b(v.val0*k, v.val1*k);
    public static function operator+(v1, v2: Vec2b): Vec2b := new Vec2b(v1.val0+v2.val0, v1.val1+v2.val1);
    public static function operator-(v1, v2: Vec2b): Vec2b := new Vec2b(v1.val0-v2.val0, v1.val1-v2.val1);
    
    public static function operator implicit(v: Vec1b): Vec2b := new Vec2b(v.val0, 0);
    public static function operator implicit(v: Vec2b): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec2b := new Vec2b(v.val0, 0);
    public static function operator implicit(v: Vec2b): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec2b := new Vec2b(v.val0, 0);
    public static function operator implicit(v: Vec2b): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec2b := new Vec2b(v.val0, 0);
    public static function operator implicit(v: Vec2b): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec2b := new Vec2b(v.val0, 0);
    public static function operator implicit(v: Vec2b): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec2b := new Vec2b(v.val0, 0);
    public static function operator implicit(v: Vec2b): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec2b := new Vec2b(v.val0, 0);
    public static function operator implicit(v: Vec2b): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec2b := new Vec2b(v.val0, 0);
    public static function operator implicit(v: Vec2b): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec2b := new Vec2b(Convert.ToSByte(v.val0), 0);
    public static function operator implicit(v: Vec2b): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec2b := new Vec2b(Convert.ToSByte(v.val0), 0);
    public static function operator implicit(v: Vec2b): Vec1d := new Vec1d(v.val0);
    
  end;
  
  Vec2ub = record
    public val0: Byte;
    public val1: Byte;
    
    public constructor(val0, val1: Byte);
    begin
      self.val0 := val0;
      self.val1 := val1;
    end;
    
    private function GetValAt(i: integer): Byte;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(i: integer; val: Byte);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    public property val[i: integer]: Byte read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec2ub; k: Byte): Vec2ub := new Vec2ub(v.val0*k, v.val1*k);
    public static function operator+(v1, v2: Vec2ub): Vec2ub := new Vec2ub(v1.val0+v2.val0, v1.val1+v2.val1);
    public static function operator-(v1, v2: Vec2ub): Vec2ub := new Vec2ub(v1.val0-v2.val0, v1.val1-v2.val1);
    
    public static function operator implicit(v: Vec1b): Vec2ub := new Vec2ub(v.val0, 0);
    public static function operator implicit(v: Vec2ub): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec2ub := new Vec2ub(v.val0, 0);
    public static function operator implicit(v: Vec2ub): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec2ub := new Vec2ub(v.val0, 0);
    public static function operator implicit(v: Vec2ub): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec2ub := new Vec2ub(v.val0, 0);
    public static function operator implicit(v: Vec2ub): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec2ub := new Vec2ub(v.val0, 0);
    public static function operator implicit(v: Vec2ub): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec2ub := new Vec2ub(v.val0, 0);
    public static function operator implicit(v: Vec2ub): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec2ub := new Vec2ub(v.val0, 0);
    public static function operator implicit(v: Vec2ub): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec2ub := new Vec2ub(v.val0, 0);
    public static function operator implicit(v: Vec2ub): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec2ub := new Vec2ub(Convert.ToByte(v.val0), 0);
    public static function operator implicit(v: Vec2ub): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec2ub := new Vec2ub(Convert.ToByte(v.val0), 0);
    public static function operator implicit(v: Vec2ub): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec2ub := new Vec2ub(v.val0, v.val1);
    public static function operator implicit(v: Vec2ub): Vec2b := new Vec2b(v.val0, v.val1);
    
  end;
  
  Vec2s = record
    public val0: Int16;
    public val1: Int16;
    
    public constructor(val0, val1: Int16);
    begin
      self.val0 := val0;
      self.val1 := val1;
    end;
    
    private function GetValAt(i: integer): Int16;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int16);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    public property val[i: integer]: Int16 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec2s): Vec2s := new Vec2s(-v.val0, -v.val1);
    public static function operator*(v: Vec2s; k: Int16): Vec2s := new Vec2s(v.val0*k, v.val1*k);
    public static function operator+(v1, v2: Vec2s): Vec2s := new Vec2s(v1.val0+v2.val0, v1.val1+v2.val1);
    public static function operator-(v1, v2: Vec2s): Vec2s := new Vec2s(v1.val0-v2.val0, v1.val1-v2.val1);
    
    public static function operator implicit(v: Vec1b): Vec2s := new Vec2s(v.val0, 0);
    public static function operator implicit(v: Vec2s): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec2s := new Vec2s(v.val0, 0);
    public static function operator implicit(v: Vec2s): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec2s := new Vec2s(v.val0, 0);
    public static function operator implicit(v: Vec2s): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec2s := new Vec2s(v.val0, 0);
    public static function operator implicit(v: Vec2s): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec2s := new Vec2s(v.val0, 0);
    public static function operator implicit(v: Vec2s): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec2s := new Vec2s(v.val0, 0);
    public static function operator implicit(v: Vec2s): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec2s := new Vec2s(v.val0, 0);
    public static function operator implicit(v: Vec2s): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec2s := new Vec2s(v.val0, 0);
    public static function operator implicit(v: Vec2s): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec2s := new Vec2s(Convert.ToInt16(v.val0), 0);
    public static function operator implicit(v: Vec2s): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec2s := new Vec2s(Convert.ToInt16(v.val0), 0);
    public static function operator implicit(v: Vec2s): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec2s := new Vec2s(v.val0, v.val1);
    public static function operator implicit(v: Vec2s): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec2s := new Vec2s(v.val0, v.val1);
    public static function operator implicit(v: Vec2s): Vec2ub := new Vec2ub(v.val0, v.val1);
    
  end;
  
  Vec2us = record
    public val0: UInt16;
    public val1: UInt16;
    
    public constructor(val0, val1: UInt16);
    begin
      self.val0 := val0;
      self.val1 := val1;
    end;
    
    private function GetValAt(i: integer): UInt16;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt16);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    public property val[i: integer]: UInt16 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec2us; k: UInt16): Vec2us := new Vec2us(v.val0*k, v.val1*k);
    public static function operator+(v1, v2: Vec2us): Vec2us := new Vec2us(v1.val0+v2.val0, v1.val1+v2.val1);
    public static function operator-(v1, v2: Vec2us): Vec2us := new Vec2us(v1.val0-v2.val0, v1.val1-v2.val1);
    
    public static function operator implicit(v: Vec1b): Vec2us := new Vec2us(v.val0, 0);
    public static function operator implicit(v: Vec2us): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec2us := new Vec2us(v.val0, 0);
    public static function operator implicit(v: Vec2us): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec2us := new Vec2us(v.val0, 0);
    public static function operator implicit(v: Vec2us): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec2us := new Vec2us(v.val0, 0);
    public static function operator implicit(v: Vec2us): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec2us := new Vec2us(v.val0, 0);
    public static function operator implicit(v: Vec2us): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec2us := new Vec2us(v.val0, 0);
    public static function operator implicit(v: Vec2us): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec2us := new Vec2us(v.val0, 0);
    public static function operator implicit(v: Vec2us): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec2us := new Vec2us(v.val0, 0);
    public static function operator implicit(v: Vec2us): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec2us := new Vec2us(Convert.ToUInt16(v.val0), 0);
    public static function operator implicit(v: Vec2us): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec2us := new Vec2us(Convert.ToUInt16(v.val0), 0);
    public static function operator implicit(v: Vec2us): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec2us := new Vec2us(v.val0, v.val1);
    public static function operator implicit(v: Vec2us): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec2us := new Vec2us(v.val0, v.val1);
    public static function operator implicit(v: Vec2us): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec2us := new Vec2us(v.val0, v.val1);
    public static function operator implicit(v: Vec2us): Vec2s := new Vec2s(v.val0, v.val1);
    
  end;
  
  Vec2i = record
    public val0: Int32;
    public val1: Int32;
    
    public constructor(val0, val1: Int32);
    begin
      self.val0 := val0;
      self.val1 := val1;
    end;
    
    private function GetValAt(i: integer): Int32;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int32);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    public property val[i: integer]: Int32 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec2i): Vec2i := new Vec2i(-v.val0, -v.val1);
    public static function operator*(v: Vec2i; k: Int32): Vec2i := new Vec2i(v.val0*k, v.val1*k);
    public static function operator+(v1, v2: Vec2i): Vec2i := new Vec2i(v1.val0+v2.val0, v1.val1+v2.val1);
    public static function operator-(v1, v2: Vec2i): Vec2i := new Vec2i(v1.val0-v2.val0, v1.val1-v2.val1);
    
    public static function operator implicit(v: Vec1b): Vec2i := new Vec2i(v.val0, 0);
    public static function operator implicit(v: Vec2i): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec2i := new Vec2i(v.val0, 0);
    public static function operator implicit(v: Vec2i): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec2i := new Vec2i(v.val0, 0);
    public static function operator implicit(v: Vec2i): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec2i := new Vec2i(v.val0, 0);
    public static function operator implicit(v: Vec2i): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec2i := new Vec2i(v.val0, 0);
    public static function operator implicit(v: Vec2i): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec2i := new Vec2i(v.val0, 0);
    public static function operator implicit(v: Vec2i): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec2i := new Vec2i(v.val0, 0);
    public static function operator implicit(v: Vec2i): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec2i := new Vec2i(v.val0, 0);
    public static function operator implicit(v: Vec2i): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec2i := new Vec2i(Convert.ToInt32(v.val0), 0);
    public static function operator implicit(v: Vec2i): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec2i := new Vec2i(Convert.ToInt32(v.val0), 0);
    public static function operator implicit(v: Vec2i): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec2i := new Vec2i(v.val0, v.val1);
    public static function operator implicit(v: Vec2i): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec2i := new Vec2i(v.val0, v.val1);
    public static function operator implicit(v: Vec2i): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec2i := new Vec2i(v.val0, v.val1);
    public static function operator implicit(v: Vec2i): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec2i := new Vec2i(v.val0, v.val1);
    public static function operator implicit(v: Vec2i): Vec2us := new Vec2us(v.val0, v.val1);
    
  end;
  
  Vec2ui = record
    public val0: UInt32;
    public val1: UInt32;
    
    public constructor(val0, val1: UInt32);
    begin
      self.val0 := val0;
      self.val1 := val1;
    end;
    
    private function GetValAt(i: integer): UInt32;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt32);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    public property val[i: integer]: UInt32 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec2ui; k: UInt32): Vec2ui := new Vec2ui(v.val0*k, v.val1*k);
    public static function operator+(v1, v2: Vec2ui): Vec2ui := new Vec2ui(v1.val0+v2.val0, v1.val1+v2.val1);
    public static function operator-(v1, v2: Vec2ui): Vec2ui := new Vec2ui(v1.val0-v2.val0, v1.val1-v2.val1);
    
    public static function operator implicit(v: Vec1b): Vec2ui := new Vec2ui(v.val0, 0);
    public static function operator implicit(v: Vec2ui): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec2ui := new Vec2ui(v.val0, 0);
    public static function operator implicit(v: Vec2ui): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec2ui := new Vec2ui(v.val0, 0);
    public static function operator implicit(v: Vec2ui): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec2ui := new Vec2ui(v.val0, 0);
    public static function operator implicit(v: Vec2ui): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec2ui := new Vec2ui(v.val0, 0);
    public static function operator implicit(v: Vec2ui): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec2ui := new Vec2ui(v.val0, 0);
    public static function operator implicit(v: Vec2ui): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec2ui := new Vec2ui(v.val0, 0);
    public static function operator implicit(v: Vec2ui): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec2ui := new Vec2ui(v.val0, 0);
    public static function operator implicit(v: Vec2ui): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec2ui := new Vec2ui(Convert.ToUInt32(v.val0), 0);
    public static function operator implicit(v: Vec2ui): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec2ui := new Vec2ui(Convert.ToUInt32(v.val0), 0);
    public static function operator implicit(v: Vec2ui): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec2ui := new Vec2ui(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec2ui := new Vec2ui(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec2ui := new Vec2ui(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec2ui := new Vec2ui(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec2ui := new Vec2ui(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui): Vec2i := new Vec2i(v.val0, v.val1);
    
  end;
  
  Vec2i64 = record
    public val0: Int64;
    public val1: Int64;
    
    public constructor(val0, val1: Int64);
    begin
      self.val0 := val0;
      self.val1 := val1;
    end;
    
    private function GetValAt(i: integer): Int64;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int64);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    public property val[i: integer]: Int64 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec2i64): Vec2i64 := new Vec2i64(-v.val0, -v.val1);
    public static function operator*(v: Vec2i64; k: Int64): Vec2i64 := new Vec2i64(v.val0*k, v.val1*k);
    public static function operator+(v1, v2: Vec2i64): Vec2i64 := new Vec2i64(v1.val0+v2.val0, v1.val1+v2.val1);
    public static function operator-(v1, v2: Vec2i64): Vec2i64 := new Vec2i64(v1.val0-v2.val0, v1.val1-v2.val1);
    
    public static function operator implicit(v: Vec1b): Vec2i64 := new Vec2i64(v.val0, 0);
    public static function operator implicit(v: Vec2i64): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec2i64 := new Vec2i64(v.val0, 0);
    public static function operator implicit(v: Vec2i64): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec2i64 := new Vec2i64(v.val0, 0);
    public static function operator implicit(v: Vec2i64): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec2i64 := new Vec2i64(v.val0, 0);
    public static function operator implicit(v: Vec2i64): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec2i64 := new Vec2i64(v.val0, 0);
    public static function operator implicit(v: Vec2i64): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec2i64 := new Vec2i64(v.val0, 0);
    public static function operator implicit(v: Vec2i64): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec2i64 := new Vec2i64(v.val0, 0);
    public static function operator implicit(v: Vec2i64): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec2i64 := new Vec2i64(v.val0, 0);
    public static function operator implicit(v: Vec2i64): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec2i64 := new Vec2i64(Convert.ToInt64(v.val0), 0);
    public static function operator implicit(v: Vec2i64): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec2i64 := new Vec2i64(Convert.ToInt64(v.val0), 0);
    public static function operator implicit(v: Vec2i64): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec2i64 := new Vec2i64(v.val0, v.val1);
    public static function operator implicit(v: Vec2i64): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec2i64 := new Vec2i64(v.val0, v.val1);
    public static function operator implicit(v: Vec2i64): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec2i64 := new Vec2i64(v.val0, v.val1);
    public static function operator implicit(v: Vec2i64): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec2i64 := new Vec2i64(v.val0, v.val1);
    public static function operator implicit(v: Vec2i64): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec2i64 := new Vec2i64(v.val0, v.val1);
    public static function operator implicit(v: Vec2i64): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec2i64 := new Vec2i64(v.val0, v.val1);
    public static function operator implicit(v: Vec2i64): Vec2ui := new Vec2ui(v.val0, v.val1);
    
  end;
  
  Vec2ui64 = record
    public val0: UInt64;
    public val1: UInt64;
    
    public constructor(val0, val1: UInt64);
    begin
      self.val0 := val0;
      self.val1 := val1;
    end;
    
    private function GetValAt(i: integer): UInt64;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt64);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    public property val[i: integer]: UInt64 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec2ui64; k: UInt64): Vec2ui64 := new Vec2ui64(v.val0*k, v.val1*k);
    public static function operator+(v1, v2: Vec2ui64): Vec2ui64 := new Vec2ui64(v1.val0+v2.val0, v1.val1+v2.val1);
    public static function operator-(v1, v2: Vec2ui64): Vec2ui64 := new Vec2ui64(v1.val0-v2.val0, v1.val1-v2.val1);
    
    public static function operator implicit(v: Vec1b): Vec2ui64 := new Vec2ui64(v.val0, 0);
    public static function operator implicit(v: Vec2ui64): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec2ui64 := new Vec2ui64(v.val0, 0);
    public static function operator implicit(v: Vec2ui64): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec2ui64 := new Vec2ui64(v.val0, 0);
    public static function operator implicit(v: Vec2ui64): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec2ui64 := new Vec2ui64(v.val0, 0);
    public static function operator implicit(v: Vec2ui64): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec2ui64 := new Vec2ui64(v.val0, 0);
    public static function operator implicit(v: Vec2ui64): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec2ui64 := new Vec2ui64(v.val0, 0);
    public static function operator implicit(v: Vec2ui64): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec2ui64 := new Vec2ui64(v.val0, 0);
    public static function operator implicit(v: Vec2ui64): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec2ui64 := new Vec2ui64(v.val0, 0);
    public static function operator implicit(v: Vec2ui64): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec2ui64 := new Vec2ui64(Convert.ToUInt64(v.val0), 0);
    public static function operator implicit(v: Vec2ui64): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec2ui64 := new Vec2ui64(Convert.ToUInt64(v.val0), 0);
    public static function operator implicit(v: Vec2ui64): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui64): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui64): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui64): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui64): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui64): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui64): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    public static function operator implicit(v: Vec2ui64): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
  end;
  
  Vec2f = record
    public val0: single;
    public val1: single;
    
    public constructor(val0, val1: single);
    begin
      self.val0 := val0;
      self.val1 := val1;
    end;
    
    private function GetValAt(i: integer): single;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(i: integer; val: single);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    public property val[i: integer]: single read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec2f): Vec2f := new Vec2f(-v.val0, -v.val1);
    public static function operator*(v: Vec2f; k: single): Vec2f := new Vec2f(v.val0*k, v.val1*k);
    public static function operator+(v1, v2: Vec2f): Vec2f := new Vec2f(v1.val0+v2.val0, v1.val1+v2.val1);
    public static function operator-(v1, v2: Vec2f): Vec2f := new Vec2f(v1.val0-v2.val0, v1.val1-v2.val1);
    
    public static function operator implicit(v: Vec1b): Vec2f := new Vec2f(v.val0, 0);
    public static function operator implicit(v: Vec2f): Vec1b := new Vec1b(Convert.ToSByte(v.val0));
    
    public static function operator implicit(v: Vec1ub): Vec2f := new Vec2f(v.val0, 0);
    public static function operator implicit(v: Vec2f): Vec1ub := new Vec1ub(Convert.ToByte(v.val0));
    
    public static function operator implicit(v: Vec1s): Vec2f := new Vec2f(v.val0, 0);
    public static function operator implicit(v: Vec2f): Vec1s := new Vec1s(Convert.ToInt16(v.val0));
    
    public static function operator implicit(v: Vec1us): Vec2f := new Vec2f(v.val0, 0);
    public static function operator implicit(v: Vec2f): Vec1us := new Vec1us(Convert.ToUInt16(v.val0));
    
    public static function operator implicit(v: Vec1i): Vec2f := new Vec2f(v.val0, 0);
    public static function operator implicit(v: Vec2f): Vec1i := new Vec1i(Convert.ToInt32(v.val0));
    
    public static function operator implicit(v: Vec1ui): Vec2f := new Vec2f(v.val0, 0);
    public static function operator implicit(v: Vec2f): Vec1ui := new Vec1ui(Convert.ToUInt32(v.val0));
    
    public static function operator implicit(v: Vec1i64): Vec2f := new Vec2f(v.val0, 0);
    public static function operator implicit(v: Vec2f): Vec1i64 := new Vec1i64(Convert.ToInt64(v.val0));
    
    public static function operator implicit(v: Vec1ui64): Vec2f := new Vec2f(v.val0, 0);
    public static function operator implicit(v: Vec2f): Vec1ui64 := new Vec1ui64(Convert.ToUInt64(v.val0));
    
    public static function operator implicit(v: Vec1f): Vec2f := new Vec2f(v.val0, 0);
    public static function operator implicit(v: Vec2f): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec2f := new Vec2f(v.val0, 0);
    public static function operator implicit(v: Vec2f): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec2f := new Vec2f(v.val0, v.val1);
    public static function operator implicit(v: Vec2f): Vec2b := new Vec2b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1));
    
    public static function operator implicit(v: Vec2ub): Vec2f := new Vec2f(v.val0, v.val1);
    public static function operator implicit(v: Vec2f): Vec2ub := new Vec2ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1));
    
    public static function operator implicit(v: Vec2s): Vec2f := new Vec2f(v.val0, v.val1);
    public static function operator implicit(v: Vec2f): Vec2s := new Vec2s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1));
    
    public static function operator implicit(v: Vec2us): Vec2f := new Vec2f(v.val0, v.val1);
    public static function operator implicit(v: Vec2f): Vec2us := new Vec2us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1));
    
    public static function operator implicit(v: Vec2i): Vec2f := new Vec2f(v.val0, v.val1);
    public static function operator implicit(v: Vec2f): Vec2i := new Vec2i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1));
    
    public static function operator implicit(v: Vec2ui): Vec2f := new Vec2f(v.val0, v.val1);
    public static function operator implicit(v: Vec2f): Vec2ui := new Vec2ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1));
    
    public static function operator implicit(v: Vec2i64): Vec2f := new Vec2f(v.val0, v.val1);
    public static function operator implicit(v: Vec2f): Vec2i64 := new Vec2i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1));
    
    public static function operator implicit(v: Vec2ui64): Vec2f := new Vec2f(v.val0, v.val1);
    public static function operator implicit(v: Vec2f): Vec2ui64 := new Vec2ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1));
    
  end;
  
  Vec2d = record
    public val0: real;
    public val1: real;
    
    public constructor(val0, val1: real);
    begin
      self.val0 := val0;
      self.val1 := val1;
    end;
    
    private function GetValAt(i: integer): real;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(i: integer; val: real);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..1');
      end;
    end;
    public property val[i: integer]: real read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec2d): Vec2d := new Vec2d(-v.val0, -v.val1);
    public static function operator*(v: Vec2d; k: real): Vec2d := new Vec2d(v.val0*k, v.val1*k);
    public static function operator+(v1, v2: Vec2d): Vec2d := new Vec2d(v1.val0+v2.val0, v1.val1+v2.val1);
    public static function operator-(v1, v2: Vec2d): Vec2d := new Vec2d(v1.val0-v2.val0, v1.val1-v2.val1);
    
    public static function operator implicit(v: Vec1b): Vec2d := new Vec2d(v.val0, 0);
    public static function operator implicit(v: Vec2d): Vec1b := new Vec1b(Convert.ToSByte(v.val0));
    
    public static function operator implicit(v: Vec1ub): Vec2d := new Vec2d(v.val0, 0);
    public static function operator implicit(v: Vec2d): Vec1ub := new Vec1ub(Convert.ToByte(v.val0));
    
    public static function operator implicit(v: Vec1s): Vec2d := new Vec2d(v.val0, 0);
    public static function operator implicit(v: Vec2d): Vec1s := new Vec1s(Convert.ToInt16(v.val0));
    
    public static function operator implicit(v: Vec1us): Vec2d := new Vec2d(v.val0, 0);
    public static function operator implicit(v: Vec2d): Vec1us := new Vec1us(Convert.ToUInt16(v.val0));
    
    public static function operator implicit(v: Vec1i): Vec2d := new Vec2d(v.val0, 0);
    public static function operator implicit(v: Vec2d): Vec1i := new Vec1i(Convert.ToInt32(v.val0));
    
    public static function operator implicit(v: Vec1ui): Vec2d := new Vec2d(v.val0, 0);
    public static function operator implicit(v: Vec2d): Vec1ui := new Vec1ui(Convert.ToUInt32(v.val0));
    
    public static function operator implicit(v: Vec1i64): Vec2d := new Vec2d(v.val0, 0);
    public static function operator implicit(v: Vec2d): Vec1i64 := new Vec1i64(Convert.ToInt64(v.val0));
    
    public static function operator implicit(v: Vec1ui64): Vec2d := new Vec2d(v.val0, 0);
    public static function operator implicit(v: Vec2d): Vec1ui64 := new Vec1ui64(Convert.ToUInt64(v.val0));
    
    public static function operator implicit(v: Vec1f): Vec2d := new Vec2d(v.val0, 0);
    public static function operator implicit(v: Vec2d): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec2d := new Vec2d(v.val0, 0);
    public static function operator implicit(v: Vec2d): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec2d := new Vec2d(v.val0, v.val1);
    public static function operator implicit(v: Vec2d): Vec2b := new Vec2b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1));
    
    public static function operator implicit(v: Vec2ub): Vec2d := new Vec2d(v.val0, v.val1);
    public static function operator implicit(v: Vec2d): Vec2ub := new Vec2ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1));
    
    public static function operator implicit(v: Vec2s): Vec2d := new Vec2d(v.val0, v.val1);
    public static function operator implicit(v: Vec2d): Vec2s := new Vec2s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1));
    
    public static function operator implicit(v: Vec2us): Vec2d := new Vec2d(v.val0, v.val1);
    public static function operator implicit(v: Vec2d): Vec2us := new Vec2us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1));
    
    public static function operator implicit(v: Vec2i): Vec2d := new Vec2d(v.val0, v.val1);
    public static function operator implicit(v: Vec2d): Vec2i := new Vec2i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1));
    
    public static function operator implicit(v: Vec2ui): Vec2d := new Vec2d(v.val0, v.val1);
    public static function operator implicit(v: Vec2d): Vec2ui := new Vec2ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1));
    
    public static function operator implicit(v: Vec2i64): Vec2d := new Vec2d(v.val0, v.val1);
    public static function operator implicit(v: Vec2d): Vec2i64 := new Vec2i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1));
    
    public static function operator implicit(v: Vec2ui64): Vec2d := new Vec2d(v.val0, v.val1);
    public static function operator implicit(v: Vec2d): Vec2ui64 := new Vec2ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1));
    
    public static function operator implicit(v: Vec2f): Vec2d := new Vec2d(v.val0, v.val1);
    public static function operator implicit(v: Vec2d): Vec2f := new Vec2f(v.val0, v.val1);
    
  end;
  {$endregion Vec2}
  
  {$region Vec3}
  
  Vec3b = record
    public val0: SByte;
    public val1: SByte;
    public val2: SByte;
    
    public constructor(val0, val1, val2: SByte);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
    end;
    
    private function GetValAt(i: integer): SByte;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(i: integer; val: SByte);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    public property val[i: integer]: SByte read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec3b): Vec3b := new Vec3b(-v.val0, -v.val1, -v.val2);
    public static function operator*(v: Vec3b; k: SByte): Vec3b := new Vec3b(v.val0*k, v.val1*k, v.val2*k);
    public static function operator+(v1, v2: Vec3b): Vec3b := new Vec3b(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2);
    public static function operator-(v1, v2: Vec3b): Vec3b := new Vec3b(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2);
    
    public static function operator implicit(v: Vec1b): Vec3b := new Vec3b(v.val0, 0, 0);
    public static function operator implicit(v: Vec3b): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec3b := new Vec3b(v.val0, 0, 0);
    public static function operator implicit(v: Vec3b): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec3b := new Vec3b(v.val0, 0, 0);
    public static function operator implicit(v: Vec3b): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec3b := new Vec3b(v.val0, 0, 0);
    public static function operator implicit(v: Vec3b): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec3b := new Vec3b(v.val0, 0, 0);
    public static function operator implicit(v: Vec3b): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec3b := new Vec3b(v.val0, 0, 0);
    public static function operator implicit(v: Vec3b): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec3b := new Vec3b(v.val0, 0, 0);
    public static function operator implicit(v: Vec3b): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec3b := new Vec3b(v.val0, 0, 0);
    public static function operator implicit(v: Vec3b): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec3b := new Vec3b(Convert.ToSByte(v.val0), 0, 0);
    public static function operator implicit(v: Vec3b): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec3b := new Vec3b(Convert.ToSByte(v.val0), 0, 0);
    public static function operator implicit(v: Vec3b): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec3b := new Vec3b(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3b): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec3b := new Vec3b(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3b): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec3b := new Vec3b(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3b): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec3b := new Vec3b(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3b): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec3b := new Vec3b(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3b): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec3b := new Vec3b(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3b): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec3b := new Vec3b(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3b): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec3b := new Vec3b(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3b): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec3b := new Vec3b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), 0);
    public static function operator implicit(v: Vec3b): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec3b := new Vec3b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), 0);
    public static function operator implicit(v: Vec3b): Vec2d := new Vec2d(v.val0, v.val1);
    
  end;
  
  Vec3ub = record
    public val0: Byte;
    public val1: Byte;
    public val2: Byte;
    
    public constructor(val0, val1, val2: Byte);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
    end;
    
    private function GetValAt(i: integer): Byte;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(i: integer; val: Byte);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    public property val[i: integer]: Byte read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec3ub; k: Byte): Vec3ub := new Vec3ub(v.val0*k, v.val1*k, v.val2*k);
    public static function operator+(v1, v2: Vec3ub): Vec3ub := new Vec3ub(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2);
    public static function operator-(v1, v2: Vec3ub): Vec3ub := new Vec3ub(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2);
    
    public static function operator implicit(v: Vec1b): Vec3ub := new Vec3ub(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ub): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec3ub := new Vec3ub(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ub): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec3ub := new Vec3ub(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ub): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec3ub := new Vec3ub(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ub): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec3ub := new Vec3ub(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ub): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec3ub := new Vec3ub(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ub): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec3ub := new Vec3ub(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ub): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec3ub := new Vec3ub(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ub): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec3ub := new Vec3ub(Convert.ToByte(v.val0), 0, 0);
    public static function operator implicit(v: Vec3ub): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec3ub := new Vec3ub(Convert.ToByte(v.val0), 0, 0);
    public static function operator implicit(v: Vec3ub): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec3ub := new Vec3ub(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ub): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec3ub := new Vec3ub(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ub): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec3ub := new Vec3ub(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ub): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec3ub := new Vec3ub(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ub): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec3ub := new Vec3ub(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ub): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec3ub := new Vec3ub(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ub): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec3ub := new Vec3ub(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ub): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec3ub := new Vec3ub(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ub): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec3ub := new Vec3ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), 0);
    public static function operator implicit(v: Vec3ub): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec3ub := new Vec3ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), 0);
    public static function operator implicit(v: Vec3ub): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ub): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
  end;
  
  Vec3s = record
    public val0: Int16;
    public val1: Int16;
    public val2: Int16;
    
    public constructor(val0, val1, val2: Int16);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
    end;
    
    private function GetValAt(i: integer): Int16;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int16);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    public property val[i: integer]: Int16 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec3s): Vec3s := new Vec3s(-v.val0, -v.val1, -v.val2);
    public static function operator*(v: Vec3s; k: Int16): Vec3s := new Vec3s(v.val0*k, v.val1*k, v.val2*k);
    public static function operator+(v1, v2: Vec3s): Vec3s := new Vec3s(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2);
    public static function operator-(v1, v2: Vec3s): Vec3s := new Vec3s(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2);
    
    public static function operator implicit(v: Vec1b): Vec3s := new Vec3s(v.val0, 0, 0);
    public static function operator implicit(v: Vec3s): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec3s := new Vec3s(v.val0, 0, 0);
    public static function operator implicit(v: Vec3s): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec3s := new Vec3s(v.val0, 0, 0);
    public static function operator implicit(v: Vec3s): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec3s := new Vec3s(v.val0, 0, 0);
    public static function operator implicit(v: Vec3s): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec3s := new Vec3s(v.val0, 0, 0);
    public static function operator implicit(v: Vec3s): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec3s := new Vec3s(v.val0, 0, 0);
    public static function operator implicit(v: Vec3s): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec3s := new Vec3s(v.val0, 0, 0);
    public static function operator implicit(v: Vec3s): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec3s := new Vec3s(v.val0, 0, 0);
    public static function operator implicit(v: Vec3s): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec3s := new Vec3s(Convert.ToInt16(v.val0), 0, 0);
    public static function operator implicit(v: Vec3s): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec3s := new Vec3s(Convert.ToInt16(v.val0), 0, 0);
    public static function operator implicit(v: Vec3s): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec3s := new Vec3s(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3s): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec3s := new Vec3s(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3s): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec3s := new Vec3s(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3s): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec3s := new Vec3s(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3s): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec3s := new Vec3s(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3s): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec3s := new Vec3s(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3s): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec3s := new Vec3s(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3s): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec3s := new Vec3s(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3s): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec3s := new Vec3s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), 0);
    public static function operator implicit(v: Vec3s): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec3s := new Vec3s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), 0);
    public static function operator implicit(v: Vec3s): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3s): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3s): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
  end;
  
  Vec3us = record
    public val0: UInt16;
    public val1: UInt16;
    public val2: UInt16;
    
    public constructor(val0, val1, val2: UInt16);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
    end;
    
    private function GetValAt(i: integer): UInt16;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt16);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    public property val[i: integer]: UInt16 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec3us; k: UInt16): Vec3us := new Vec3us(v.val0*k, v.val1*k, v.val2*k);
    public static function operator+(v1, v2: Vec3us): Vec3us := new Vec3us(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2);
    public static function operator-(v1, v2: Vec3us): Vec3us := new Vec3us(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2);
    
    public static function operator implicit(v: Vec1b): Vec3us := new Vec3us(v.val0, 0, 0);
    public static function operator implicit(v: Vec3us): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec3us := new Vec3us(v.val0, 0, 0);
    public static function operator implicit(v: Vec3us): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec3us := new Vec3us(v.val0, 0, 0);
    public static function operator implicit(v: Vec3us): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec3us := new Vec3us(v.val0, 0, 0);
    public static function operator implicit(v: Vec3us): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec3us := new Vec3us(v.val0, 0, 0);
    public static function operator implicit(v: Vec3us): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec3us := new Vec3us(v.val0, 0, 0);
    public static function operator implicit(v: Vec3us): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec3us := new Vec3us(v.val0, 0, 0);
    public static function operator implicit(v: Vec3us): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec3us := new Vec3us(v.val0, 0, 0);
    public static function operator implicit(v: Vec3us): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec3us := new Vec3us(Convert.ToUInt16(v.val0), 0, 0);
    public static function operator implicit(v: Vec3us): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec3us := new Vec3us(Convert.ToUInt16(v.val0), 0, 0);
    public static function operator implicit(v: Vec3us): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec3us := new Vec3us(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3us): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec3us := new Vec3us(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3us): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec3us := new Vec3us(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3us): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec3us := new Vec3us(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3us): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec3us := new Vec3us(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3us): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec3us := new Vec3us(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3us): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec3us := new Vec3us(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3us): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec3us := new Vec3us(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3us): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec3us := new Vec3us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), 0);
    public static function operator implicit(v: Vec3us): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec3us := new Vec3us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), 0);
    public static function operator implicit(v: Vec3us): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3us): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3us): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3us): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
  end;
  
  Vec3i = record
    public val0: Int32;
    public val1: Int32;
    public val2: Int32;
    
    public constructor(val0, val1, val2: Int32);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
    end;
    
    private function GetValAt(i: integer): Int32;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int32);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    public property val[i: integer]: Int32 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec3i): Vec3i := new Vec3i(-v.val0, -v.val1, -v.val2);
    public static function operator*(v: Vec3i; k: Int32): Vec3i := new Vec3i(v.val0*k, v.val1*k, v.val2*k);
    public static function operator+(v1, v2: Vec3i): Vec3i := new Vec3i(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2);
    public static function operator-(v1, v2: Vec3i): Vec3i := new Vec3i(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2);
    
    public static function operator implicit(v: Vec1b): Vec3i := new Vec3i(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec3i := new Vec3i(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec3i := new Vec3i(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec3i := new Vec3i(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec3i := new Vec3i(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec3i := new Vec3i(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec3i := new Vec3i(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec3i := new Vec3i(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec3i := new Vec3i(Convert.ToInt32(v.val0), 0, 0);
    public static function operator implicit(v: Vec3i): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec3i := new Vec3i(Convert.ToInt32(v.val0), 0, 0);
    public static function operator implicit(v: Vec3i): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec3i := new Vec3i(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec3i := new Vec3i(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec3i := new Vec3i(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec3i := new Vec3i(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec3i := new Vec3i(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec3i := new Vec3i(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec3i := new Vec3i(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec3i := new Vec3i(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec3i := new Vec3i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), 0);
    public static function operator implicit(v: Vec3i): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec3i := new Vec3i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), 0);
    public static function operator implicit(v: Vec3i): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3i): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3i): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3i): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3i): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
  end;
  
  Vec3ui = record
    public val0: UInt32;
    public val1: UInt32;
    public val2: UInt32;
    
    public constructor(val0, val1, val2: UInt32);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
    end;
    
    private function GetValAt(i: integer): UInt32;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt32);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    public property val[i: integer]: UInt32 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec3ui; k: UInt32): Vec3ui := new Vec3ui(v.val0*k, v.val1*k, v.val2*k);
    public static function operator+(v1, v2: Vec3ui): Vec3ui := new Vec3ui(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2);
    public static function operator-(v1, v2: Vec3ui): Vec3ui := new Vec3ui(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2);
    
    public static function operator implicit(v: Vec1b): Vec3ui := new Vec3ui(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec3ui := new Vec3ui(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec3ui := new Vec3ui(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec3ui := new Vec3ui(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec3ui := new Vec3ui(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec3ui := new Vec3ui(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec3ui := new Vec3ui(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec3ui := new Vec3ui(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec3ui := new Vec3ui(Convert.ToUInt32(v.val0), 0, 0);
    public static function operator implicit(v: Vec3ui): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec3ui := new Vec3ui(Convert.ToUInt32(v.val0), 0, 0);
    public static function operator implicit(v: Vec3ui): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec3ui := new Vec3ui(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec3ui := new Vec3ui(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec3ui := new Vec3ui(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec3ui := new Vec3ui(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec3ui := new Vec3ui(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec3ui := new Vec3ui(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec3ui := new Vec3ui(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec3ui := new Vec3ui(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec3ui := new Vec3ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), 0);
    public static function operator implicit(v: Vec3ui): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec3ui := new Vec3ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), 0);
    public static function operator implicit(v: Vec3ui): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
  end;
  
  Vec3i64 = record
    public val0: Int64;
    public val1: Int64;
    public val2: Int64;
    
    public constructor(val0, val1, val2: Int64);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
    end;
    
    private function GetValAt(i: integer): Int64;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int64);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    public property val[i: integer]: Int64 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec3i64): Vec3i64 := new Vec3i64(-v.val0, -v.val1, -v.val2);
    public static function operator*(v: Vec3i64; k: Int64): Vec3i64 := new Vec3i64(v.val0*k, v.val1*k, v.val2*k);
    public static function operator+(v1, v2: Vec3i64): Vec3i64 := new Vec3i64(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2);
    public static function operator-(v1, v2: Vec3i64): Vec3i64 := new Vec3i64(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2);
    
    public static function operator implicit(v: Vec1b): Vec3i64 := new Vec3i64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i64): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec3i64 := new Vec3i64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i64): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec3i64 := new Vec3i64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i64): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec3i64 := new Vec3i64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i64): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec3i64 := new Vec3i64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i64): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec3i64 := new Vec3i64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i64): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec3i64 := new Vec3i64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i64): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec3i64 := new Vec3i64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3i64): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec3i64 := new Vec3i64(Convert.ToInt64(v.val0), 0, 0);
    public static function operator implicit(v: Vec3i64): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec3i64 := new Vec3i64(Convert.ToInt64(v.val0), 0, 0);
    public static function operator implicit(v: Vec3i64): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec3i64 := new Vec3i64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i64): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec3i64 := new Vec3i64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i64): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec3i64 := new Vec3i64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i64): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec3i64 := new Vec3i64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i64): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec3i64 := new Vec3i64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i64): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec3i64 := new Vec3i64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i64): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec3i64 := new Vec3i64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i64): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec3i64 := new Vec3i64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3i64): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec3i64 := new Vec3i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), 0);
    public static function operator implicit(v: Vec3i64): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec3i64 := new Vec3i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), 0);
    public static function operator implicit(v: Vec3i64): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3i64): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3i64): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3i64): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3i64): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3i64): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3i64): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    
  end;
  
  Vec3ui64 = record
    public val0: UInt64;
    public val1: UInt64;
    public val2: UInt64;
    
    public constructor(val0, val1, val2: UInt64);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
    end;
    
    private function GetValAt(i: integer): UInt64;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt64);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    public property val[i: integer]: UInt64 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec3ui64; k: UInt64): Vec3ui64 := new Vec3ui64(v.val0*k, v.val1*k, v.val2*k);
    public static function operator+(v1, v2: Vec3ui64): Vec3ui64 := new Vec3ui64(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2);
    public static function operator-(v1, v2: Vec3ui64): Vec3ui64 := new Vec3ui64(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2);
    
    public static function operator implicit(v: Vec1b): Vec3ui64 := new Vec3ui64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui64): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec3ui64 := new Vec3ui64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui64): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec3ui64 := new Vec3ui64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui64): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec3ui64 := new Vec3ui64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui64): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec3ui64 := new Vec3ui64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui64): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec3ui64 := new Vec3ui64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui64): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec3ui64 := new Vec3ui64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui64): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec3ui64 := new Vec3ui64(v.val0, 0, 0);
    public static function operator implicit(v: Vec3ui64): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec3ui64 := new Vec3ui64(Convert.ToUInt64(v.val0), 0, 0);
    public static function operator implicit(v: Vec3ui64): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec3ui64 := new Vec3ui64(Convert.ToUInt64(v.val0), 0, 0);
    public static function operator implicit(v: Vec3ui64): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec3ui64 := new Vec3ui64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui64): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec3ui64 := new Vec3ui64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui64): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec3ui64 := new Vec3ui64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui64): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec3ui64 := new Vec3ui64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui64): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec3ui64 := new Vec3ui64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui64): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec3ui64 := new Vec3ui64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui64): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec3ui64 := new Vec3ui64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui64): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec3ui64 := new Vec3ui64(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3ui64): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec3ui64 := new Vec3ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), 0);
    public static function operator implicit(v: Vec3ui64): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec3ui64 := new Vec3ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), 0);
    public static function operator implicit(v: Vec3ui64): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui64): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui64): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui64): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui64): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui64): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui64): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i64): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3ui64): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    
  end;
  
  Vec3f = record
    public val0: single;
    public val1: single;
    public val2: single;
    
    public constructor(val0, val1, val2: single);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
    end;
    
    private function GetValAt(i: integer): single;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(i: integer; val: single);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    public property val[i: integer]: single read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec3f): Vec3f := new Vec3f(-v.val0, -v.val1, -v.val2);
    public static function operator*(v: Vec3f; k: single): Vec3f := new Vec3f(v.val0*k, v.val1*k, v.val2*k);
    public static function operator+(v1, v2: Vec3f): Vec3f := new Vec3f(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2);
    public static function operator-(v1, v2: Vec3f): Vec3f := new Vec3f(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2);
    
    public static function operator implicit(v: Vec1b): Vec3f := new Vec3f(v.val0, 0, 0);
    public static function operator implicit(v: Vec3f): Vec1b := new Vec1b(Convert.ToSByte(v.val0));
    
    public static function operator implicit(v: Vec1ub): Vec3f := new Vec3f(v.val0, 0, 0);
    public static function operator implicit(v: Vec3f): Vec1ub := new Vec1ub(Convert.ToByte(v.val0));
    
    public static function operator implicit(v: Vec1s): Vec3f := new Vec3f(v.val0, 0, 0);
    public static function operator implicit(v: Vec3f): Vec1s := new Vec1s(Convert.ToInt16(v.val0));
    
    public static function operator implicit(v: Vec1us): Vec3f := new Vec3f(v.val0, 0, 0);
    public static function operator implicit(v: Vec3f): Vec1us := new Vec1us(Convert.ToUInt16(v.val0));
    
    public static function operator implicit(v: Vec1i): Vec3f := new Vec3f(v.val0, 0, 0);
    public static function operator implicit(v: Vec3f): Vec1i := new Vec1i(Convert.ToInt32(v.val0));
    
    public static function operator implicit(v: Vec1ui): Vec3f := new Vec3f(v.val0, 0, 0);
    public static function operator implicit(v: Vec3f): Vec1ui := new Vec1ui(Convert.ToUInt32(v.val0));
    
    public static function operator implicit(v: Vec1i64): Vec3f := new Vec3f(v.val0, 0, 0);
    public static function operator implicit(v: Vec3f): Vec1i64 := new Vec1i64(Convert.ToInt64(v.val0));
    
    public static function operator implicit(v: Vec1ui64): Vec3f := new Vec3f(v.val0, 0, 0);
    public static function operator implicit(v: Vec3f): Vec1ui64 := new Vec1ui64(Convert.ToUInt64(v.val0));
    
    public static function operator implicit(v: Vec1f): Vec3f := new Vec3f(v.val0, 0, 0);
    public static function operator implicit(v: Vec3f): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec3f := new Vec3f(v.val0, 0, 0);
    public static function operator implicit(v: Vec3f): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec3f := new Vec3f(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3f): Vec2b := new Vec2b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1));
    
    public static function operator implicit(v: Vec2ub): Vec3f := new Vec3f(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3f): Vec2ub := new Vec2ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1));
    
    public static function operator implicit(v: Vec2s): Vec3f := new Vec3f(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3f): Vec2s := new Vec2s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1));
    
    public static function operator implicit(v: Vec2us): Vec3f := new Vec3f(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3f): Vec2us := new Vec2us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1));
    
    public static function operator implicit(v: Vec2i): Vec3f := new Vec3f(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3f): Vec2i := new Vec2i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1));
    
    public static function operator implicit(v: Vec2ui): Vec3f := new Vec3f(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3f): Vec2ui := new Vec2ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1));
    
    public static function operator implicit(v: Vec2i64): Vec3f := new Vec3f(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3f): Vec2i64 := new Vec2i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1));
    
    public static function operator implicit(v: Vec2ui64): Vec3f := new Vec3f(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3f): Vec2ui64 := new Vec2ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1));
    
    public static function operator implicit(v: Vec2f): Vec3f := new Vec3f(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3f): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec3f := new Vec3f(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3f): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3f): Vec3b := new Vec3b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), Convert.ToSByte(v.val2));
    
    public static function operator implicit(v: Vec3ub): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3f): Vec3ub := new Vec3ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), Convert.ToByte(v.val2));
    
    public static function operator implicit(v: Vec3s): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3f): Vec3s := new Vec3s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), Convert.ToInt16(v.val2));
    
    public static function operator implicit(v: Vec3us): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3f): Vec3us := new Vec3us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), Convert.ToUInt16(v.val2));
    
    public static function operator implicit(v: Vec3i): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3f): Vec3i := new Vec3i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), Convert.ToInt32(v.val2));
    
    public static function operator implicit(v: Vec3ui): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3f): Vec3ui := new Vec3ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), Convert.ToUInt32(v.val2));
    
    public static function operator implicit(v: Vec3i64): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3f): Vec3i64 := new Vec3i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), Convert.ToInt64(v.val2));
    
    public static function operator implicit(v: Vec3ui64): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3f): Vec3ui64 := new Vec3ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), Convert.ToUInt64(v.val2));
    
  end;
  
  Vec3d = record
    public val0: real;
    public val1: real;
    public val2: real;
    
    public constructor(val0, val1, val2: real);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
    end;
    
    private function GetValAt(i: integer): real;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(i: integer; val: real);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..2');
      end;
    end;
    public property val[i: integer]: real read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec3d): Vec3d := new Vec3d(-v.val0, -v.val1, -v.val2);
    public static function operator*(v: Vec3d; k: real): Vec3d := new Vec3d(v.val0*k, v.val1*k, v.val2*k);
    public static function operator+(v1, v2: Vec3d): Vec3d := new Vec3d(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2);
    public static function operator-(v1, v2: Vec3d): Vec3d := new Vec3d(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2);
    
    public static function operator implicit(v: Vec1b): Vec3d := new Vec3d(v.val0, 0, 0);
    public static function operator implicit(v: Vec3d): Vec1b := new Vec1b(Convert.ToSByte(v.val0));
    
    public static function operator implicit(v: Vec1ub): Vec3d := new Vec3d(v.val0, 0, 0);
    public static function operator implicit(v: Vec3d): Vec1ub := new Vec1ub(Convert.ToByte(v.val0));
    
    public static function operator implicit(v: Vec1s): Vec3d := new Vec3d(v.val0, 0, 0);
    public static function operator implicit(v: Vec3d): Vec1s := new Vec1s(Convert.ToInt16(v.val0));
    
    public static function operator implicit(v: Vec1us): Vec3d := new Vec3d(v.val0, 0, 0);
    public static function operator implicit(v: Vec3d): Vec1us := new Vec1us(Convert.ToUInt16(v.val0));
    
    public static function operator implicit(v: Vec1i): Vec3d := new Vec3d(v.val0, 0, 0);
    public static function operator implicit(v: Vec3d): Vec1i := new Vec1i(Convert.ToInt32(v.val0));
    
    public static function operator implicit(v: Vec1ui): Vec3d := new Vec3d(v.val0, 0, 0);
    public static function operator implicit(v: Vec3d): Vec1ui := new Vec1ui(Convert.ToUInt32(v.val0));
    
    public static function operator implicit(v: Vec1i64): Vec3d := new Vec3d(v.val0, 0, 0);
    public static function operator implicit(v: Vec3d): Vec1i64 := new Vec1i64(Convert.ToInt64(v.val0));
    
    public static function operator implicit(v: Vec1ui64): Vec3d := new Vec3d(v.val0, 0, 0);
    public static function operator implicit(v: Vec3d): Vec1ui64 := new Vec1ui64(Convert.ToUInt64(v.val0));
    
    public static function operator implicit(v: Vec1f): Vec3d := new Vec3d(v.val0, 0, 0);
    public static function operator implicit(v: Vec3d): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec3d := new Vec3d(v.val0, 0, 0);
    public static function operator implicit(v: Vec3d): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec3d := new Vec3d(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3d): Vec2b := new Vec2b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1));
    
    public static function operator implicit(v: Vec2ub): Vec3d := new Vec3d(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3d): Vec2ub := new Vec2ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1));
    
    public static function operator implicit(v: Vec2s): Vec3d := new Vec3d(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3d): Vec2s := new Vec2s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1));
    
    public static function operator implicit(v: Vec2us): Vec3d := new Vec3d(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3d): Vec2us := new Vec2us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1));
    
    public static function operator implicit(v: Vec2i): Vec3d := new Vec3d(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3d): Vec2i := new Vec2i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1));
    
    public static function operator implicit(v: Vec2ui): Vec3d := new Vec3d(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3d): Vec2ui := new Vec2ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1));
    
    public static function operator implicit(v: Vec2i64): Vec3d := new Vec3d(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3d): Vec2i64 := new Vec2i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1));
    
    public static function operator implicit(v: Vec2ui64): Vec3d := new Vec3d(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3d): Vec2ui64 := new Vec2ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1));
    
    public static function operator implicit(v: Vec2f): Vec3d := new Vec3d(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3d): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec3d := new Vec3d(v.val0, v.val1, 0);
    public static function operator implicit(v: Vec3d): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3d): Vec3b := new Vec3b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), Convert.ToSByte(v.val2));
    
    public static function operator implicit(v: Vec3ub): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3d): Vec3ub := new Vec3ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), Convert.ToByte(v.val2));
    
    public static function operator implicit(v: Vec3s): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3d): Vec3s := new Vec3s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), Convert.ToInt16(v.val2));
    
    public static function operator implicit(v: Vec3us): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3d): Vec3us := new Vec3us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), Convert.ToUInt16(v.val2));
    
    public static function operator implicit(v: Vec3i): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3d): Vec3i := new Vec3i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), Convert.ToInt32(v.val2));
    
    public static function operator implicit(v: Vec3ui): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3d): Vec3ui := new Vec3ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), Convert.ToUInt32(v.val2));
    
    public static function operator implicit(v: Vec3i64): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3d): Vec3i64 := new Vec3i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), Convert.ToInt64(v.val2));
    
    public static function operator implicit(v: Vec3ui64): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3d): Vec3ui64 := new Vec3ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), Convert.ToUInt64(v.val2));
    
    public static function operator implicit(v: Vec3f): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    public static function operator implicit(v: Vec3d): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
  end;
  {$endregion Vec3}
  
  {$region Vec4}
  
  Vec4b = record
    public val0: SByte;
    public val1: SByte;
    public val2: SByte;
    public val3: SByte;
    
    public constructor(val0, val1, val2, val3: SByte);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
      self.val3 := val3;
    end;
    
    private function GetValAt(i: integer): SByte;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        3: Result := self.val3;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(i: integer; val: SByte);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        3: self.val3 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    public property val[i: integer]: SByte read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec4b): Vec4b := new Vec4b(-v.val0, -v.val1, -v.val2, -v.val3);
    public static function operator*(v: Vec4b; k: SByte): Vec4b := new Vec4b(v.val0*k, v.val1*k, v.val2*k, v.val3*k);
    public static function operator+(v1, v2: Vec4b): Vec4b := new Vec4b(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2, v1.val3+v2.val3);
    public static function operator-(v1, v2: Vec4b): Vec4b := new Vec4b(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2, v1.val3-v2.val3);
    
    public static function operator implicit(v: Vec1b): Vec4b := new Vec4b(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4b): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec4b := new Vec4b(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4b): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec4b := new Vec4b(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4b): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec4b := new Vec4b(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4b): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec4b := new Vec4b(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4b): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec4b := new Vec4b(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4b): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec4b := new Vec4b(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4b): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec4b := new Vec4b(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4b): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec4b := new Vec4b(Convert.ToSByte(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4b): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec4b := new Vec4b(Convert.ToSByte(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4b): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec4b := new Vec4b(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4b): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec4b := new Vec4b(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4b): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec4b := new Vec4b(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4b): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec4b := new Vec4b(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4b): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec4b := new Vec4b(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4b): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec4b := new Vec4b(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4b): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec4b := new Vec4b(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4b): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec4b := new Vec4b(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4b): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec4b := new Vec4b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), 0, 0);
    public static function operator implicit(v: Vec4b): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec4b := new Vec4b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), 0, 0);
    public static function operator implicit(v: Vec4b): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec4b := new Vec4b(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4b): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec4b := new Vec4b(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4b): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec4b := new Vec4b(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4b): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec4b := new Vec4b(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4b): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec4b := new Vec4b(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4b): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui): Vec4b := new Vec4b(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4b): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i64): Vec4b := new Vec4b(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4b): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui64): Vec4b := new Vec4b(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4b): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3f): Vec4b := new Vec4b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), Convert.ToSByte(v.val2), 0);
    public static function operator implicit(v: Vec4b): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3d): Vec4b := new Vec4b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), Convert.ToSByte(v.val2), 0);
    public static function operator implicit(v: Vec4b): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    
  end;
  
  Vec4ub = record
    public val0: Byte;
    public val1: Byte;
    public val2: Byte;
    public val3: Byte;
    
    public constructor(val0, val1, val2, val3: Byte);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
      self.val3 := val3;
    end;
    
    private function GetValAt(i: integer): Byte;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        3: Result := self.val3;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(i: integer; val: Byte);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        3: self.val3 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    public property val[i: integer]: Byte read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec4ub; k: Byte): Vec4ub := new Vec4ub(v.val0*k, v.val1*k, v.val2*k, v.val3*k);
    public static function operator+(v1, v2: Vec4ub): Vec4ub := new Vec4ub(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2, v1.val3+v2.val3);
    public static function operator-(v1, v2: Vec4ub): Vec4ub := new Vec4ub(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2, v1.val3-v2.val3);
    
    public static function operator implicit(v: Vec1b): Vec4ub := new Vec4ub(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec4ub := new Vec4ub(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec4ub := new Vec4ub(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec4ub := new Vec4ub(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec4ub := new Vec4ub(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec4ub := new Vec4ub(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec4ub := new Vec4ub(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec4ub := new Vec4ub(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec4ub := new Vec4ub(Convert.ToByte(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec4ub := new Vec4ub(Convert.ToByte(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec4ub := new Vec4ub(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec4ub := new Vec4ub(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec4ub := new Vec4ub(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec4ub := new Vec4ub(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec4ub := new Vec4ub(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec4ub := new Vec4ub(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec4ub := new Vec4ub(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec4ub := new Vec4ub(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ub): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec4ub := new Vec4ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), 0, 0);
    public static function operator implicit(v: Vec4ub): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec4ub := new Vec4ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), 0, 0);
    public static function operator implicit(v: Vec4ub): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ub): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ub): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ub): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ub): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ub): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ub): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i64): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ub): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui64): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ub): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3f): Vec4ub := new Vec4ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), Convert.ToByte(v.val2), 0);
    public static function operator implicit(v: Vec4ub): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3d): Vec4ub := new Vec4ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), Convert.ToByte(v.val2), 0);
    public static function operator implicit(v: Vec4ub): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec4b): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ub): Vec4b := new Vec4b(v.val0, v.val1, v.val2, v.val3);
    
  end;
  
  Vec4s = record
    public val0: Int16;
    public val1: Int16;
    public val2: Int16;
    public val3: Int16;
    
    public constructor(val0, val1, val2, val3: Int16);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
      self.val3 := val3;
    end;
    
    private function GetValAt(i: integer): Int16;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        3: Result := self.val3;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int16);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        3: self.val3 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    public property val[i: integer]: Int16 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec4s): Vec4s := new Vec4s(-v.val0, -v.val1, -v.val2, -v.val3);
    public static function operator*(v: Vec4s; k: Int16): Vec4s := new Vec4s(v.val0*k, v.val1*k, v.val2*k, v.val3*k);
    public static function operator+(v1, v2: Vec4s): Vec4s := new Vec4s(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2, v1.val3+v2.val3);
    public static function operator-(v1, v2: Vec4s): Vec4s := new Vec4s(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2, v1.val3-v2.val3);
    
    public static function operator implicit(v: Vec1b): Vec4s := new Vec4s(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4s): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec4s := new Vec4s(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4s): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec4s := new Vec4s(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4s): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec4s := new Vec4s(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4s): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec4s := new Vec4s(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4s): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec4s := new Vec4s(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4s): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec4s := new Vec4s(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4s): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec4s := new Vec4s(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4s): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec4s := new Vec4s(Convert.ToInt16(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4s): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec4s := new Vec4s(Convert.ToInt16(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4s): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec4s := new Vec4s(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4s): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec4s := new Vec4s(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4s): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec4s := new Vec4s(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4s): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec4s := new Vec4s(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4s): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec4s := new Vec4s(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4s): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec4s := new Vec4s(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4s): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec4s := new Vec4s(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4s): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec4s := new Vec4s(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4s): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec4s := new Vec4s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), 0, 0);
    public static function operator implicit(v: Vec4s): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec4s := new Vec4s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), 0, 0);
    public static function operator implicit(v: Vec4s): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec4s := new Vec4s(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4s): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec4s := new Vec4s(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4s): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec4s := new Vec4s(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4s): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec4s := new Vec4s(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4s): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec4s := new Vec4s(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4s): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui): Vec4s := new Vec4s(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4s): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i64): Vec4s := new Vec4s(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4s): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui64): Vec4s := new Vec4s(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4s): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3f): Vec4s := new Vec4s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), Convert.ToInt16(v.val2), 0);
    public static function operator implicit(v: Vec4s): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3d): Vec4s := new Vec4s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), Convert.ToInt16(v.val2), 0);
    public static function operator implicit(v: Vec4s): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec4b): Vec4s := new Vec4s(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4s): Vec4b := new Vec4b(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4ub): Vec4s := new Vec4s(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4s): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, v.val3);
    
  end;
  
  Vec4us = record
    public val0: UInt16;
    public val1: UInt16;
    public val2: UInt16;
    public val3: UInt16;
    
    public constructor(val0, val1, val2, val3: UInt16);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
      self.val3 := val3;
    end;
    
    private function GetValAt(i: integer): UInt16;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        3: Result := self.val3;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt16);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        3: self.val3 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    public property val[i: integer]: UInt16 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec4us; k: UInt16): Vec4us := new Vec4us(v.val0*k, v.val1*k, v.val2*k, v.val3*k);
    public static function operator+(v1, v2: Vec4us): Vec4us := new Vec4us(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2, v1.val3+v2.val3);
    public static function operator-(v1, v2: Vec4us): Vec4us := new Vec4us(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2, v1.val3-v2.val3);
    
    public static function operator implicit(v: Vec1b): Vec4us := new Vec4us(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4us): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec4us := new Vec4us(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4us): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec4us := new Vec4us(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4us): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec4us := new Vec4us(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4us): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec4us := new Vec4us(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4us): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec4us := new Vec4us(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4us): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec4us := new Vec4us(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4us): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec4us := new Vec4us(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4us): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec4us := new Vec4us(Convert.ToUInt16(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4us): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec4us := new Vec4us(Convert.ToUInt16(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4us): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec4us := new Vec4us(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4us): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec4us := new Vec4us(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4us): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec4us := new Vec4us(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4us): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec4us := new Vec4us(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4us): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec4us := new Vec4us(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4us): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec4us := new Vec4us(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4us): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec4us := new Vec4us(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4us): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec4us := new Vec4us(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4us): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec4us := new Vec4us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), 0, 0);
    public static function operator implicit(v: Vec4us): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec4us := new Vec4us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), 0, 0);
    public static function operator implicit(v: Vec4us): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec4us := new Vec4us(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4us): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec4us := new Vec4us(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4us): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec4us := new Vec4us(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4us): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec4us := new Vec4us(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4us): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec4us := new Vec4us(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4us): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui): Vec4us := new Vec4us(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4us): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i64): Vec4us := new Vec4us(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4us): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui64): Vec4us := new Vec4us(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4us): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3f): Vec4us := new Vec4us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), Convert.ToUInt16(v.val2), 0);
    public static function operator implicit(v: Vec4us): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3d): Vec4us := new Vec4us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), Convert.ToUInt16(v.val2), 0);
    public static function operator implicit(v: Vec4us): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec4b): Vec4us := new Vec4us(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4us): Vec4b := new Vec4b(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4ub): Vec4us := new Vec4us(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4us): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4s): Vec4us := new Vec4us(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4us): Vec4s := new Vec4s(v.val0, v.val1, v.val2, v.val3);
    
  end;
  
  Vec4i = record
    public val0: Int32;
    public val1: Int32;
    public val2: Int32;
    public val3: Int32;
    
    public constructor(val0, val1, val2, val3: Int32);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
      self.val3 := val3;
    end;
    
    private function GetValAt(i: integer): Int32;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        3: Result := self.val3;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int32);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        3: self.val3 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    public property val[i: integer]: Int32 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec4i): Vec4i := new Vec4i(-v.val0, -v.val1, -v.val2, -v.val3);
    public static function operator*(v: Vec4i; k: Int32): Vec4i := new Vec4i(v.val0*k, v.val1*k, v.val2*k, v.val3*k);
    public static function operator+(v1, v2: Vec4i): Vec4i := new Vec4i(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2, v1.val3+v2.val3);
    public static function operator-(v1, v2: Vec4i): Vec4i := new Vec4i(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2, v1.val3-v2.val3);
    
    public static function operator implicit(v: Vec1b): Vec4i := new Vec4i(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec4i := new Vec4i(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec4i := new Vec4i(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec4i := new Vec4i(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec4i := new Vec4i(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec4i := new Vec4i(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec4i := new Vec4i(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec4i := new Vec4i(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec4i := new Vec4i(Convert.ToInt32(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4i): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec4i := new Vec4i(Convert.ToInt32(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4i): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec4i := new Vec4i(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec4i := new Vec4i(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec4i := new Vec4i(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec4i := new Vec4i(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec4i := new Vec4i(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec4i := new Vec4i(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec4i := new Vec4i(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec4i := new Vec4i(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec4i := new Vec4i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), 0, 0);
    public static function operator implicit(v: Vec4i): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec4i := new Vec4i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), 0, 0);
    public static function operator implicit(v: Vec4i): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec4i := new Vec4i(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec4i := new Vec4i(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec4i := new Vec4i(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec4i := new Vec4i(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec4i := new Vec4i(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui): Vec4i := new Vec4i(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i64): Vec4i := new Vec4i(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui64): Vec4i := new Vec4i(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3f): Vec4i := new Vec4i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), Convert.ToInt32(v.val2), 0);
    public static function operator implicit(v: Vec4i): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3d): Vec4i := new Vec4i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), Convert.ToInt32(v.val2), 0);
    public static function operator implicit(v: Vec4i): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec4b): Vec4i := new Vec4i(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4i): Vec4b := new Vec4b(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4ub): Vec4i := new Vec4i(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4i): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4s): Vec4i := new Vec4i(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4i): Vec4s := new Vec4s(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4us): Vec4i := new Vec4i(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4i): Vec4us := new Vec4us(v.val0, v.val1, v.val2, v.val3);
    
  end;
  
  Vec4ui = record
    public val0: UInt32;
    public val1: UInt32;
    public val2: UInt32;
    public val3: UInt32;
    
    public constructor(val0, val1, val2, val3: UInt32);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
      self.val3 := val3;
    end;
    
    private function GetValAt(i: integer): UInt32;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        3: Result := self.val3;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt32);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        3: self.val3 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    public property val[i: integer]: UInt32 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec4ui; k: UInt32): Vec4ui := new Vec4ui(v.val0*k, v.val1*k, v.val2*k, v.val3*k);
    public static function operator+(v1, v2: Vec4ui): Vec4ui := new Vec4ui(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2, v1.val3+v2.val3);
    public static function operator-(v1, v2: Vec4ui): Vec4ui := new Vec4ui(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2, v1.val3-v2.val3);
    
    public static function operator implicit(v: Vec1b): Vec4ui := new Vec4ui(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec4ui := new Vec4ui(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec4ui := new Vec4ui(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec4ui := new Vec4ui(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec4ui := new Vec4ui(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec4ui := new Vec4ui(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec4ui := new Vec4ui(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec4ui := new Vec4ui(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec4ui := new Vec4ui(Convert.ToUInt32(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec4ui := new Vec4ui(Convert.ToUInt32(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec4ui := new Vec4ui(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec4ui := new Vec4ui(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec4ui := new Vec4ui(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec4ui := new Vec4ui(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec4ui := new Vec4ui(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec4ui := new Vec4ui(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec4ui := new Vec4ui(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec4ui := new Vec4ui(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec4ui := new Vec4ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), 0, 0);
    public static function operator implicit(v: Vec4ui): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec4ui := new Vec4ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), 0, 0);
    public static function operator implicit(v: Vec4ui): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i64): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui64): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3f): Vec4ui := new Vec4ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), Convert.ToUInt32(v.val2), 0);
    public static function operator implicit(v: Vec4ui): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3d): Vec4ui := new Vec4ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), Convert.ToUInt32(v.val2), 0);
    public static function operator implicit(v: Vec4ui): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec4b): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui): Vec4b := new Vec4b(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4ub): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4s): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui): Vec4s := new Vec4s(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4us): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui): Vec4us := new Vec4us(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4i): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui): Vec4i := new Vec4i(v.val0, v.val1, v.val2, v.val3);
    
  end;
  
  Vec4i64 = record
    public val0: Int64;
    public val1: Int64;
    public val2: Int64;
    public val3: Int64;
    
    public constructor(val0, val1, val2, val3: Int64);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
      self.val3 := val3;
    end;
    
    private function GetValAt(i: integer): Int64;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        3: Result := self.val3;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(i: integer; val: Int64);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        3: self.val3 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    public property val[i: integer]: Int64 read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec4i64): Vec4i64 := new Vec4i64(-v.val0, -v.val1, -v.val2, -v.val3);
    public static function operator*(v: Vec4i64; k: Int64): Vec4i64 := new Vec4i64(v.val0*k, v.val1*k, v.val2*k, v.val3*k);
    public static function operator+(v1, v2: Vec4i64): Vec4i64 := new Vec4i64(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2, v1.val3+v2.val3);
    public static function operator-(v1, v2: Vec4i64): Vec4i64 := new Vec4i64(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2, v1.val3-v2.val3);
    
    public static function operator implicit(v: Vec1b): Vec4i64 := new Vec4i64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec4i64 := new Vec4i64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec4i64 := new Vec4i64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec4i64 := new Vec4i64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec4i64 := new Vec4i64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec4i64 := new Vec4i64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec4i64 := new Vec4i64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec4i64 := new Vec4i64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec4i64 := new Vec4i64(Convert.ToInt64(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec4i64 := new Vec4i64(Convert.ToInt64(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec4i64 := new Vec4i64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec4i64 := new Vec4i64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec4i64 := new Vec4i64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec4i64 := new Vec4i64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec4i64 := new Vec4i64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec4i64 := new Vec4i64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec4i64 := new Vec4i64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec4i64 := new Vec4i64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4i64): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec4i64 := new Vec4i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), 0, 0);
    public static function operator implicit(v: Vec4i64): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec4i64 := new Vec4i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), 0, 0);
    public static function operator implicit(v: Vec4i64): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i64): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i64): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i64): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i64): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i64): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i64): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i64): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i64): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui64): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4i64): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3f): Vec4i64 := new Vec4i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), Convert.ToInt64(v.val2), 0);
    public static function operator implicit(v: Vec4i64): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3d): Vec4i64 := new Vec4i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), Convert.ToInt64(v.val2), 0);
    public static function operator implicit(v: Vec4i64): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec4b): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4i64): Vec4b := new Vec4b(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4ub): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4i64): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4s): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4i64): Vec4s := new Vec4s(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4us): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4i64): Vec4us := new Vec4us(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4i): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4i64): Vec4i := new Vec4i(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4ui): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4i64): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, v.val3);
    
  end;
  
  Vec4ui64 = record
    public val0: UInt64;
    public val1: UInt64;
    public val2: UInt64;
    public val3: UInt64;
    
    public constructor(val0, val1, val2, val3: UInt64);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
      self.val3 := val3;
    end;
    
    private function GetValAt(i: integer): UInt64;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        3: Result := self.val3;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(i: integer; val: UInt64);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        3: self.val3 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    public property val[i: integer]: UInt64 read GetValAt write SetValAt; default;
    
    public static function operator*(v: Vec4ui64; k: UInt64): Vec4ui64 := new Vec4ui64(v.val0*k, v.val1*k, v.val2*k, v.val3*k);
    public static function operator+(v1, v2: Vec4ui64): Vec4ui64 := new Vec4ui64(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2, v1.val3+v2.val3);
    public static function operator-(v1, v2: Vec4ui64): Vec4ui64 := new Vec4ui64(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2, v1.val3-v2.val3);
    
    public static function operator implicit(v: Vec1b): Vec4ui64 := new Vec4ui64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec1b := new Vec1b(v.val0);
    
    public static function operator implicit(v: Vec1ub): Vec4ui64 := new Vec4ui64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec1ub := new Vec1ub(v.val0);
    
    public static function operator implicit(v: Vec1s): Vec4ui64 := new Vec4ui64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec1s := new Vec1s(v.val0);
    
    public static function operator implicit(v: Vec1us): Vec4ui64 := new Vec4ui64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec1us := new Vec1us(v.val0);
    
    public static function operator implicit(v: Vec1i): Vec4ui64 := new Vec4ui64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec1i := new Vec1i(v.val0);
    
    public static function operator implicit(v: Vec1ui): Vec4ui64 := new Vec4ui64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec1ui := new Vec1ui(v.val0);
    
    public static function operator implicit(v: Vec1i64): Vec4ui64 := new Vec4ui64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec1i64 := new Vec1i64(v.val0);
    
    public static function operator implicit(v: Vec1ui64): Vec4ui64 := new Vec4ui64(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec1ui64 := new Vec1ui64(v.val0);
    
    public static function operator implicit(v: Vec1f): Vec4ui64 := new Vec4ui64(Convert.ToUInt64(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec4ui64 := new Vec4ui64(Convert.ToUInt64(v.val0), 0, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec4ui64 := new Vec4ui64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec2b := new Vec2b(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ub): Vec4ui64 := new Vec4ui64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec2ub := new Vec2ub(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2s): Vec4ui64 := new Vec4ui64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec2s := new Vec2s(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2us): Vec4ui64 := new Vec4ui64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec2us := new Vec2us(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i): Vec4ui64 := new Vec4ui64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec2i := new Vec2i(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui): Vec4ui64 := new Vec4ui64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec2ui := new Vec2ui(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2i64): Vec4ui64 := new Vec4ui64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec2i64 := new Vec2i64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2ui64): Vec4ui64 := new Vec4ui64(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec2ui64 := new Vec2ui64(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2f): Vec4ui64 := new Vec4ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec4ui64 := new Vec4ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), 0, 0);
    public static function operator implicit(v: Vec4ui64): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui64): Vec3b := new Vec3b(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ub): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui64): Vec3ub := new Vec3ub(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3s): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui64): Vec3s := new Vec3s(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3us): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui64): Vec3us := new Vec3us(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui64): Vec3i := new Vec3i(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui64): Vec3ui := new Vec3ui(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3i64): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui64): Vec3i64 := new Vec3i64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3ui64): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4ui64): Vec3ui64 := new Vec3ui64(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3f): Vec4ui64 := new Vec4ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), Convert.ToUInt64(v.val2), 0);
    public static function operator implicit(v: Vec4ui64): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3d): Vec4ui64 := new Vec4ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), Convert.ToUInt64(v.val2), 0);
    public static function operator implicit(v: Vec4ui64): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec4b): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui64): Vec4b := new Vec4b(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4ub): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui64): Vec4ub := new Vec4ub(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4s): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui64): Vec4s := new Vec4s(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4us): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui64): Vec4us := new Vec4us(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4i): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui64): Vec4i := new Vec4i(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4ui): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui64): Vec4ui := new Vec4ui(v.val0, v.val1, v.val2, v.val3);
    
    public static function operator implicit(v: Vec4i64): Vec4ui64 := new Vec4ui64(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4ui64): Vec4i64 := new Vec4i64(v.val0, v.val1, v.val2, v.val3);
    
  end;
  
  Vec4f = record
    public val0: single;
    public val1: single;
    public val2: single;
    public val3: single;
    
    public constructor(val0, val1, val2, val3: single);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
      self.val3 := val3;
    end;
    
    private function GetValAt(i: integer): single;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        3: Result := self.val3;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(i: integer; val: single);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        3: self.val3 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    public property val[i: integer]: single read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec4f): Vec4f := new Vec4f(-v.val0, -v.val1, -v.val2, -v.val3);
    public static function operator*(v: Vec4f; k: single): Vec4f := new Vec4f(v.val0*k, v.val1*k, v.val2*k, v.val3*k);
    public static function operator+(v1, v2: Vec4f): Vec4f := new Vec4f(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2, v1.val3+v2.val3);
    public static function operator-(v1, v2: Vec4f): Vec4f := new Vec4f(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2, v1.val3-v2.val3);
    
    public static function operator implicit(v: Vec1b): Vec4f := new Vec4f(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4f): Vec1b := new Vec1b(Convert.ToSByte(v.val0));
    
    public static function operator implicit(v: Vec1ub): Vec4f := new Vec4f(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4f): Vec1ub := new Vec1ub(Convert.ToByte(v.val0));
    
    public static function operator implicit(v: Vec1s): Vec4f := new Vec4f(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4f): Vec1s := new Vec1s(Convert.ToInt16(v.val0));
    
    public static function operator implicit(v: Vec1us): Vec4f := new Vec4f(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4f): Vec1us := new Vec1us(Convert.ToUInt16(v.val0));
    
    public static function operator implicit(v: Vec1i): Vec4f := new Vec4f(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4f): Vec1i := new Vec1i(Convert.ToInt32(v.val0));
    
    public static function operator implicit(v: Vec1ui): Vec4f := new Vec4f(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4f): Vec1ui := new Vec1ui(Convert.ToUInt32(v.val0));
    
    public static function operator implicit(v: Vec1i64): Vec4f := new Vec4f(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4f): Vec1i64 := new Vec1i64(Convert.ToInt64(v.val0));
    
    public static function operator implicit(v: Vec1ui64): Vec4f := new Vec4f(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4f): Vec1ui64 := new Vec1ui64(Convert.ToUInt64(v.val0));
    
    public static function operator implicit(v: Vec1f): Vec4f := new Vec4f(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4f): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec4f := new Vec4f(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4f): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec4f := new Vec4f(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4f): Vec2b := new Vec2b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1));
    
    public static function operator implicit(v: Vec2ub): Vec4f := new Vec4f(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4f): Vec2ub := new Vec2ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1));
    
    public static function operator implicit(v: Vec2s): Vec4f := new Vec4f(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4f): Vec2s := new Vec2s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1));
    
    public static function operator implicit(v: Vec2us): Vec4f := new Vec4f(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4f): Vec2us := new Vec2us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1));
    
    public static function operator implicit(v: Vec2i): Vec4f := new Vec4f(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4f): Vec2i := new Vec2i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1));
    
    public static function operator implicit(v: Vec2ui): Vec4f := new Vec4f(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4f): Vec2ui := new Vec2ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1));
    
    public static function operator implicit(v: Vec2i64): Vec4f := new Vec4f(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4f): Vec2i64 := new Vec2i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1));
    
    public static function operator implicit(v: Vec2ui64): Vec4f := new Vec4f(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4f): Vec2ui64 := new Vec2ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1));
    
    public static function operator implicit(v: Vec2f): Vec4f := new Vec4f(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4f): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec4f := new Vec4f(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4f): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec4f := new Vec4f(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4f): Vec3b := new Vec3b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), Convert.ToSByte(v.val2));
    
    public static function operator implicit(v: Vec3ub): Vec4f := new Vec4f(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4f): Vec3ub := new Vec3ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), Convert.ToByte(v.val2));
    
    public static function operator implicit(v: Vec3s): Vec4f := new Vec4f(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4f): Vec3s := new Vec3s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), Convert.ToInt16(v.val2));
    
    public static function operator implicit(v: Vec3us): Vec4f := new Vec4f(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4f): Vec3us := new Vec3us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), Convert.ToUInt16(v.val2));
    
    public static function operator implicit(v: Vec3i): Vec4f := new Vec4f(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4f): Vec3i := new Vec3i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), Convert.ToInt32(v.val2));
    
    public static function operator implicit(v: Vec3ui): Vec4f := new Vec4f(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4f): Vec3ui := new Vec3ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), Convert.ToUInt32(v.val2));
    
    public static function operator implicit(v: Vec3i64): Vec4f := new Vec4f(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4f): Vec3i64 := new Vec3i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), Convert.ToInt64(v.val2));
    
    public static function operator implicit(v: Vec3ui64): Vec4f := new Vec4f(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4f): Vec3ui64 := new Vec3ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), Convert.ToUInt64(v.val2));
    
    public static function operator implicit(v: Vec3f): Vec4f := new Vec4f(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4f): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3d): Vec4f := new Vec4f(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4f): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec4b): Vec4f := new Vec4f(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4f): Vec4b := new Vec4b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), Convert.ToSByte(v.val2), Convert.ToSByte(v.val3));
    
    public static function operator implicit(v: Vec4ub): Vec4f := new Vec4f(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4f): Vec4ub := new Vec4ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), Convert.ToByte(v.val2), Convert.ToByte(v.val3));
    
    public static function operator implicit(v: Vec4s): Vec4f := new Vec4f(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4f): Vec4s := new Vec4s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), Convert.ToInt16(v.val2), Convert.ToInt16(v.val3));
    
    public static function operator implicit(v: Vec4us): Vec4f := new Vec4f(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4f): Vec4us := new Vec4us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), Convert.ToUInt16(v.val2), Convert.ToUInt16(v.val3));
    
    public static function operator implicit(v: Vec4i): Vec4f := new Vec4f(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4f): Vec4i := new Vec4i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), Convert.ToInt32(v.val2), Convert.ToInt32(v.val3));
    
    public static function operator implicit(v: Vec4ui): Vec4f := new Vec4f(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4f): Vec4ui := new Vec4ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), Convert.ToUInt32(v.val2), Convert.ToUInt32(v.val3));
    
    public static function operator implicit(v: Vec4i64): Vec4f := new Vec4f(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4f): Vec4i64 := new Vec4i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), Convert.ToInt64(v.val2), Convert.ToInt64(v.val3));
    
    public static function operator implicit(v: Vec4ui64): Vec4f := new Vec4f(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4f): Vec4ui64 := new Vec4ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), Convert.ToUInt64(v.val2), Convert.ToUInt64(v.val3));
    
  end;
  
  Vec4d = record
    public val0: real;
    public val1: real;
    public val2: real;
    public val3: real;
    
    public constructor(val0, val1, val2, val3: real);
    begin
      self.val0 := val0;
      self.val1 := val1;
      self.val2 := val2;
      self.val3 := val3;
    end;
    
    private function GetValAt(i: integer): real;
    begin
      case i of
        0: Result := self.val0;
        1: Result := self.val1;
        2: Result := self.val2;
        3: Result := self.val3;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(i: integer; val: real);
    begin
      case i of
        0: self.val0 := val;
        1: self.val1 := val;
        2: self.val2 := val;
        3: self.val3 := val;
        else raise new IndexOutOfRangeException('Индекс должен иметь значение 0..3');
      end;
    end;
    public property val[i: integer]: real read GetValAt write SetValAt; default;
    
    public static function operator-(v: Vec4d): Vec4d := new Vec4d(-v.val0, -v.val1, -v.val2, -v.val3);
    public static function operator*(v: Vec4d; k: real): Vec4d := new Vec4d(v.val0*k, v.val1*k, v.val2*k, v.val3*k);
    public static function operator+(v1, v2: Vec4d): Vec4d := new Vec4d(v1.val0+v2.val0, v1.val1+v2.val1, v1.val2+v2.val2, v1.val3+v2.val3);
    public static function operator-(v1, v2: Vec4d): Vec4d := new Vec4d(v1.val0-v2.val0, v1.val1-v2.val1, v1.val2-v2.val2, v1.val3-v2.val3);
    
    public static function operator implicit(v: Vec1b): Vec4d := new Vec4d(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4d): Vec1b := new Vec1b(Convert.ToSByte(v.val0));
    
    public static function operator implicit(v: Vec1ub): Vec4d := new Vec4d(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4d): Vec1ub := new Vec1ub(Convert.ToByte(v.val0));
    
    public static function operator implicit(v: Vec1s): Vec4d := new Vec4d(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4d): Vec1s := new Vec1s(Convert.ToInt16(v.val0));
    
    public static function operator implicit(v: Vec1us): Vec4d := new Vec4d(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4d): Vec1us := new Vec1us(Convert.ToUInt16(v.val0));
    
    public static function operator implicit(v: Vec1i): Vec4d := new Vec4d(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4d): Vec1i := new Vec1i(Convert.ToInt32(v.val0));
    
    public static function operator implicit(v: Vec1ui): Vec4d := new Vec4d(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4d): Vec1ui := new Vec1ui(Convert.ToUInt32(v.val0));
    
    public static function operator implicit(v: Vec1i64): Vec4d := new Vec4d(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4d): Vec1i64 := new Vec1i64(Convert.ToInt64(v.val0));
    
    public static function operator implicit(v: Vec1ui64): Vec4d := new Vec4d(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4d): Vec1ui64 := new Vec1ui64(Convert.ToUInt64(v.val0));
    
    public static function operator implicit(v: Vec1f): Vec4d := new Vec4d(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4d): Vec1f := new Vec1f(v.val0);
    
    public static function operator implicit(v: Vec1d): Vec4d := new Vec4d(v.val0, 0, 0, 0);
    public static function operator implicit(v: Vec4d): Vec1d := new Vec1d(v.val0);
    
    public static function operator implicit(v: Vec2b): Vec4d := new Vec4d(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4d): Vec2b := new Vec2b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1));
    
    public static function operator implicit(v: Vec2ub): Vec4d := new Vec4d(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4d): Vec2ub := new Vec2ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1));
    
    public static function operator implicit(v: Vec2s): Vec4d := new Vec4d(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4d): Vec2s := new Vec2s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1));
    
    public static function operator implicit(v: Vec2us): Vec4d := new Vec4d(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4d): Vec2us := new Vec2us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1));
    
    public static function operator implicit(v: Vec2i): Vec4d := new Vec4d(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4d): Vec2i := new Vec2i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1));
    
    public static function operator implicit(v: Vec2ui): Vec4d := new Vec4d(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4d): Vec2ui := new Vec2ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1));
    
    public static function operator implicit(v: Vec2i64): Vec4d := new Vec4d(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4d): Vec2i64 := new Vec2i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1));
    
    public static function operator implicit(v: Vec2ui64): Vec4d := new Vec4d(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4d): Vec2ui64 := new Vec2ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1));
    
    public static function operator implicit(v: Vec2f): Vec4d := new Vec4d(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4d): Vec2f := new Vec2f(v.val0, v.val1);
    
    public static function operator implicit(v: Vec2d): Vec4d := new Vec4d(v.val0, v.val1, 0, 0);
    public static function operator implicit(v: Vec4d): Vec2d := new Vec2d(v.val0, v.val1);
    
    public static function operator implicit(v: Vec3b): Vec4d := new Vec4d(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4d): Vec3b := new Vec3b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), Convert.ToSByte(v.val2));
    
    public static function operator implicit(v: Vec3ub): Vec4d := new Vec4d(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4d): Vec3ub := new Vec3ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), Convert.ToByte(v.val2));
    
    public static function operator implicit(v: Vec3s): Vec4d := new Vec4d(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4d): Vec3s := new Vec3s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), Convert.ToInt16(v.val2));
    
    public static function operator implicit(v: Vec3us): Vec4d := new Vec4d(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4d): Vec3us := new Vec3us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), Convert.ToUInt16(v.val2));
    
    public static function operator implicit(v: Vec3i): Vec4d := new Vec4d(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4d): Vec3i := new Vec3i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), Convert.ToInt32(v.val2));
    
    public static function operator implicit(v: Vec3ui): Vec4d := new Vec4d(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4d): Vec3ui := new Vec3ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), Convert.ToUInt32(v.val2));
    
    public static function operator implicit(v: Vec3i64): Vec4d := new Vec4d(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4d): Vec3i64 := new Vec3i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), Convert.ToInt64(v.val2));
    
    public static function operator implicit(v: Vec3ui64): Vec4d := new Vec4d(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4d): Vec3ui64 := new Vec3ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), Convert.ToUInt64(v.val2));
    
    public static function operator implicit(v: Vec3f): Vec4d := new Vec4d(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4d): Vec3f := new Vec3f(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec3d): Vec4d := new Vec4d(v.val0, v.val1, v.val2, 0);
    public static function operator implicit(v: Vec4d): Vec3d := new Vec3d(v.val0, v.val1, v.val2);
    
    public static function operator implicit(v: Vec4b): Vec4d := new Vec4d(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4d): Vec4b := new Vec4b(Convert.ToSByte(v.val0), Convert.ToSByte(v.val1), Convert.ToSByte(v.val2), Convert.ToSByte(v.val3));
    
    public static function operator implicit(v: Vec4ub): Vec4d := new Vec4d(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4d): Vec4ub := new Vec4ub(Convert.ToByte(v.val0), Convert.ToByte(v.val1), Convert.ToByte(v.val2), Convert.ToByte(v.val3));
    
    public static function operator implicit(v: Vec4s): Vec4d := new Vec4d(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4d): Vec4s := new Vec4s(Convert.ToInt16(v.val0), Convert.ToInt16(v.val1), Convert.ToInt16(v.val2), Convert.ToInt16(v.val3));
    
    public static function operator implicit(v: Vec4us): Vec4d := new Vec4d(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4d): Vec4us := new Vec4us(Convert.ToUInt16(v.val0), Convert.ToUInt16(v.val1), Convert.ToUInt16(v.val2), Convert.ToUInt16(v.val3));
    
    public static function operator implicit(v: Vec4i): Vec4d := new Vec4d(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4d): Vec4i := new Vec4i(Convert.ToInt32(v.val0), Convert.ToInt32(v.val1), Convert.ToInt32(v.val2), Convert.ToInt32(v.val3));
    
    public static function operator implicit(v: Vec4ui): Vec4d := new Vec4d(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4d): Vec4ui := new Vec4ui(Convert.ToUInt32(v.val0), Convert.ToUInt32(v.val1), Convert.ToUInt32(v.val2), Convert.ToUInt32(v.val3));
    
    public static function operator implicit(v: Vec4i64): Vec4d := new Vec4d(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4d): Vec4i64 := new Vec4i64(Convert.ToInt64(v.val0), Convert.ToInt64(v.val1), Convert.ToInt64(v.val2), Convert.ToInt64(v.val3));
    
    public static function operator implicit(v: Vec4ui64): Vec4d := new Vec4d(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4d): Vec4ui64 := new Vec4ui64(Convert.ToUInt64(v.val0), Convert.ToUInt64(v.val1), Convert.ToUInt64(v.val2), Convert.ToUInt64(v.val3));
    
    public static function operator implicit(v: Vec4f): Vec4d := new Vec4d(v.val0, v.val1, v.val2, v.val3);
    public static function operator implicit(v: Vec4d): Vec4f := new Vec4f(v.val0, v.val1, v.val2, v.val3);
    
  end;
  
  {$endregion Vec4}
  
  {$endregion Vec}
  
  {$region Mtr}
  
  Mtr2x2f = record
    public val00, val01: single;
    public val10, val11: single;
    
    public constructor(val00, val01, val10, val11: single);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val10 := val10;
      self.val11 := val11;
    end;
    
    private function GetValAt(y,x: integer): single;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: single);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    public property val[y,x: integer]: single read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr2x2f read new Mtr2x2f(1.0, 0.0, 0.0, 1.0);
    
    public property Row0: Vec2f read new Vec2f(self.val00, self.val01) write begin self.val00 := value.val0; self.val01 := value.val1; end;
    public property Row1: Vec2f read new Vec2f(self.val10, self.val11) write begin self.val10 := value.val0; self.val11 := value.val1; end;
    public property Row[y: integer]: Vec2f read y=0?Row0:y=1?Row1:Arr&<Vec2f>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..1');
    end;
    
    public property Col0: Vec2f read new Vec2f(self.val00, self.val10) write begin self.val00 := value.val0; self.val10 := value.val1; end;
    public property Col1: Vec2f read new Vec2f(self.val01, self.val11) write begin self.val01 := value.val0; self.val11 := value.val1; end;
    public property Col[x: integer]: Vec2f read x=0?Col0:x=1?Col1:Arr&<Vec2f>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..1');
    end;
    
    public property RowPtr0: ^Vec2f read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec2f read pointer(IntPtr(pointer(@self)) + 8);
    public property RowPtr[x: integer]: ^Vec2f read pointer(IntPtr(pointer(@self)) + x*8);
    
    public static function operator*(m1: Mtr2x2f; m2: Mtr2x2f): Mtr2x2f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11;
    end;
    
    public static function operator*(m: Mtr2x2f; v: Vec2f): Vec2f := new Vec2f(m.val00*v.val0+m.val01*v.val1, m.val10*v.val0+m.val11*v.val1);
    public static function operator*(v: Vec2f; m: Mtr2x2f): Vec2f := new Vec2f(m.val00*v.val0+m.val10*v.val1, m.val01*v.val0+m.val11*v.val1);
    
  end;
  Mtr2f = Mtr2x2f;
  
  Mtr3x3f = record
    public val00, val01, val02: single;
    public val10, val11, val12: single;
    public val20, val21, val22: single;
    
    public constructor(val00, val01, val02, val10, val11, val12, val20, val21, val22: single);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
      self.val20 := val20;
      self.val21 := val21;
      self.val22 := val22;
    end;
    
    private function GetValAt(y,x: integer): single;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          2: Result := self.val22;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: single);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          2: self.val22 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    public property val[y,x: integer]: single read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr3x3f read new Mtr3x3f(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
    
    public property Row0: Vec3f read new Vec3f(self.val00, self.val01, self.val02) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; end;
    public property Row1: Vec3f read new Vec3f(self.val10, self.val11, self.val12) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; end;
    public property Row2: Vec3f read new Vec3f(self.val20, self.val21, self.val22) write begin self.val20 := value.val0; self.val21 := value.val1; self.val22 := value.val2; end;
    public property Row[y: integer]: Vec3f read y=0?Row0:y=1?Row1:y=2?Row2:Arr&<Vec3f>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..2');
    end;
    
    public property Col0: Vec3f read new Vec3f(self.val00, self.val10, self.val20) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; end;
    public property Col1: Vec3f read new Vec3f(self.val01, self.val11, self.val21) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; end;
    public property Col2: Vec3f read new Vec3f(self.val02, self.val12, self.val22) write begin self.val02 := value.val0; self.val12 := value.val1; self.val22 := value.val2; end;
    public property Col[x: integer]: Vec3f read x=0?Col0:x=1?Col1:x=2?Col2:Arr&<Vec3f>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..2');
    end;
    
    public property RowPtr0: ^Vec3f read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec3f read pointer(IntPtr(pointer(@self)) + 12);
    public property RowPtr2: ^Vec3f read pointer(IntPtr(pointer(@self)) + 24);
    public property RowPtr[x: integer]: ^Vec3f read pointer(IntPtr(pointer(@self)) + x*12);
    
    public static function operator*(m1: Mtr3x3f; m2: Mtr3x3f): Mtr3x3f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12 + m1.val22*m2.val22;
    end;
    
    public static function operator*(m: Mtr3x3f; v: Vec3f): Vec3f := new Vec3f(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2, m.val20*v.val0+m.val21*v.val1+m.val22*v.val2);
    public static function operator*(v: Vec3f; m: Mtr3x3f): Vec3f := new Vec3f(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2, m.val02*v.val0+m.val12*v.val1+m.val22*v.val2);
    
    public static function operator implicit(m: Mtr2x2f): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x3f): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
  end;
  Mtr3f = Mtr3x3f;
  
  Mtr4x4f = record
    public val00, val01, val02, val03: single;
    public val10, val11, val12, val13: single;
    public val20, val21, val22, val23: single;
    public val30, val31, val32, val33: single;
    
    public constructor(val00, val01, val02, val03, val10, val11, val12, val13, val20, val21, val22, val23, val30, val31, val32, val33: single);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val03 := val03;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
      self.val13 := val13;
      self.val20 := val20;
      self.val21 := val21;
      self.val22 := val22;
      self.val23 := val23;
      self.val30 := val30;
      self.val31 := val31;
      self.val32 := val32;
      self.val33 := val33;
    end;
    
    private function GetValAt(y,x: integer): single;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          3: Result := self.val03;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          3: Result := self.val13;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          2: Result := self.val22;
          3: Result := self.val23;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        3:
        case x of
          0: Result := self.val30;
          1: Result := self.val31;
          2: Result := self.val32;
          3: Result := self.val33;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: single);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          3: self.val03 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          3: self.val13 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          2: self.val22 := val;
          3: self.val23 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        3:
        case x of
          0: self.val30 := val;
          1: self.val31 := val;
          2: self.val32 := val;
          3: self.val33 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    public property val[y,x: integer]: single read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr4x4f read new Mtr4x4f(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
    
    public property Row0: Vec4f read new Vec4f(self.val00, self.val01, self.val02, self.val03) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; self.val03 := value.val3; end;
    public property Row1: Vec4f read new Vec4f(self.val10, self.val11, self.val12, self.val13) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; self.val13 := value.val3; end;
    public property Row2: Vec4f read new Vec4f(self.val20, self.val21, self.val22, self.val23) write begin self.val20 := value.val0; self.val21 := value.val1; self.val22 := value.val2; self.val23 := value.val3; end;
    public property Row3: Vec4f read new Vec4f(self.val30, self.val31, self.val32, self.val33) write begin self.val30 := value.val0; self.val31 := value.val1; self.val32 := value.val2; self.val33 := value.val3; end;
    public property Row[y: integer]: Vec4f read y=0?Row0:y=1?Row1:y=2?Row2:y=3?Row3:Arr&<Vec4f>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      3: Row3 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..3');
    end;
    
    public property Col0: Vec4f read new Vec4f(self.val00, self.val10, self.val20, self.val30) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; self.val30 := value.val3; end;
    public property Col1: Vec4f read new Vec4f(self.val01, self.val11, self.val21, self.val31) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; self.val31 := value.val3; end;
    public property Col2: Vec4f read new Vec4f(self.val02, self.val12, self.val22, self.val32) write begin self.val02 := value.val0; self.val12 := value.val1; self.val22 := value.val2; self.val32 := value.val3; end;
    public property Col3: Vec4f read new Vec4f(self.val03, self.val13, self.val23, self.val33) write begin self.val03 := value.val0; self.val13 := value.val1; self.val23 := value.val2; self.val33 := value.val3; end;
    public property Col[x: integer]: Vec4f read x=0?Col0:x=1?Col1:x=2?Col2:x=3?Col3:Arr&<Vec4f>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      3: Col3 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..3');
    end;
    
    public property RowPtr0: ^Vec4f read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec4f read pointer(IntPtr(pointer(@self)) + 16);
    public property RowPtr2: ^Vec4f read pointer(IntPtr(pointer(@self)) + 32);
    public property RowPtr3: ^Vec4f read pointer(IntPtr(pointer(@self)) + 48);
    public property RowPtr[x: integer]: ^Vec4f read pointer(IntPtr(pointer(@self)) + x*16);
    
    public static function operator*(m1: Mtr4x4f; m2: Mtr4x4f): Mtr4x4f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20 + m1.val03*m2.val30;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21 + m1.val03*m2.val31;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22 + m1.val03*m2.val32;
      Result.val03 := m1.val00*m2.val03 + m1.val01*m2.val13 + m1.val02*m2.val23 + m1.val03*m2.val33;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20 + m1.val13*m2.val30;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21 + m1.val13*m2.val31;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22 + m1.val13*m2.val32;
      Result.val13 := m1.val10*m2.val03 + m1.val11*m2.val13 + m1.val12*m2.val23 + m1.val13*m2.val33;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20 + m1.val23*m2.val30;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21 + m1.val23*m2.val31;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12 + m1.val22*m2.val22 + m1.val23*m2.val32;
      Result.val23 := m1.val20*m2.val03 + m1.val21*m2.val13 + m1.val22*m2.val23 + m1.val23*m2.val33;
      Result.val30 := m1.val30*m2.val00 + m1.val31*m2.val10 + m1.val32*m2.val20 + m1.val33*m2.val30;
      Result.val31 := m1.val30*m2.val01 + m1.val31*m2.val11 + m1.val32*m2.val21 + m1.val33*m2.val31;
      Result.val32 := m1.val30*m2.val02 + m1.val31*m2.val12 + m1.val32*m2.val22 + m1.val33*m2.val32;
      Result.val33 := m1.val30*m2.val03 + m1.val31*m2.val13 + m1.val32*m2.val23 + m1.val33*m2.val33;
    end;
    
    public static function operator*(m: Mtr4x4f; v: Vec4f): Vec4f := new Vec4f(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2+m.val03*v.val3, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2+m.val13*v.val3, m.val20*v.val0+m.val21*v.val1+m.val22*v.val2+m.val23*v.val3, m.val30*v.val0+m.val31*v.val1+m.val32*v.val2+m.val33*v.val3);
    public static function operator*(v: Vec4f; m: Mtr4x4f): Vec4f := new Vec4f(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2+m.val30*v.val3, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2+m.val31*v.val3, m.val02*v.val0+m.val12*v.val1+m.val22*v.val2+m.val32*v.val3, m.val03*v.val0+m.val13*v.val1+m.val23*v.val2+m.val33*v.val3);
    
    public static function operator implicit(m: Mtr2x2f): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4f): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4f): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    
  end;
  Mtr4f = Mtr4x4f;
  
  Mtr2x3f = record
    public val00, val01, val02: single;
    public val10, val11, val12: single;
    
    public constructor(val00, val01, val02, val10, val11, val12: single);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
    end;
    
    private function GetValAt(y,x: integer): single;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: single);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    public property val[y,x: integer]: single read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr2x3f read new Mtr2x3f(1.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    
    public property Row0: Vec3f read new Vec3f(self.val00, self.val01, self.val02) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; end;
    public property Row1: Vec3f read new Vec3f(self.val10, self.val11, self.val12) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; end;
    public property Row[y: integer]: Vec3f read y=0?Row0:y=1?Row1:Arr&<Vec3f>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..1');
    end;
    
    public property Col0: Vec2f read new Vec2f(self.val00, self.val10) write begin self.val00 := value.val0; self.val10 := value.val1; end;
    public property Col1: Vec2f read new Vec2f(self.val01, self.val11) write begin self.val01 := value.val0; self.val11 := value.val1; end;
    public property Col2: Vec2f read new Vec2f(self.val02, self.val12) write begin self.val02 := value.val0; self.val12 := value.val1; end;
    public property Col[x: integer]: Vec2f read x=0?Col0:x=1?Col1:x=2?Col2:Arr&<Vec2f>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..2');
    end;
    
    public property RowPtr0: ^Vec3f read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec3f read pointer(IntPtr(pointer(@self)) + 12);
    public property RowPtr2: ^Vec3f read pointer(IntPtr(pointer(@self)) + 24);
    public property RowPtr[x: integer]: ^Vec3f read pointer(IntPtr(pointer(@self)) + x*12);
    
    public static function operator*(m: Mtr2x3f; v: Vec3f): Vec2f := new Vec2f(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2);
    public static function operator*(v: Vec2f; m: Mtr2x3f): Vec3f := new Vec3f(m.val00*v.val0+m.val10*v.val1, m.val01*v.val0+m.val11*v.val1, m.val02*v.val0+m.val12*v.val1);
    
    public static function operator implicit(m: Mtr2x2f): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    public static function operator implicit(m: Mtr2x3f): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    public static function operator implicit(m: Mtr2x3f): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x4f): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    public static function operator implicit(m: Mtr2x3f): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
  end;
  
  Mtr3x2f = record
    public val00, val01: single;
    public val10, val11: single;
    public val20, val21: single;
    
    public constructor(val00, val01, val10, val11, val20, val21: single);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val10 := val10;
      self.val11 := val11;
      self.val20 := val20;
      self.val21 := val21;
    end;
    
    private function GetValAt(y,x: integer): single;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: single);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    public property val[y,x: integer]: single read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr3x2f read new Mtr3x2f(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    
    public property Row0: Vec2f read new Vec2f(self.val00, self.val01) write begin self.val00 := value.val0; self.val01 := value.val1; end;
    public property Row1: Vec2f read new Vec2f(self.val10, self.val11) write begin self.val10 := value.val0; self.val11 := value.val1; end;
    public property Row2: Vec2f read new Vec2f(self.val20, self.val21) write begin self.val20 := value.val0; self.val21 := value.val1; end;
    public property Row[y: integer]: Vec2f read y=0?Row0:y=1?Row1:y=2?Row2:Arr&<Vec2f>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..2');
    end;
    
    public property Col0: Vec3f read new Vec3f(self.val00, self.val10, self.val20) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; end;
    public property Col1: Vec3f read new Vec3f(self.val01, self.val11, self.val21) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; end;
    public property Col[x: integer]: Vec3f read x=0?Col0:x=1?Col1:Arr&<Vec3f>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..1');
    end;
    
    public property RowPtr0: ^Vec2f read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec2f read pointer(IntPtr(pointer(@self)) + 8);
    public property RowPtr[x: integer]: ^Vec2f read pointer(IntPtr(pointer(@self)) + x*8);
    
    public static function operator*(m1: Mtr3x2f; m2: Mtr2x3f): Mtr3x3f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12;
    end;
    
    public static function operator*(m1: Mtr2x3f; m2: Mtr3x2f): Mtr2x2f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21;
    end;
    
    public static function operator*(m: Mtr3x2f; v: Vec2f): Vec3f := new Vec3f(m.val00*v.val0+m.val01*v.val1, m.val10*v.val0+m.val11*v.val1, m.val20*v.val0+m.val21*v.val1);
    public static function operator*(v: Vec3f; m: Mtr3x2f): Vec2f := new Vec2f(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2);
    
    public static function operator implicit(m: Mtr2x2f): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x2f): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    public static function operator implicit(m: Mtr3x2f): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0);
    
    public static function operator implicit(m: Mtr4x4f): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    public static function operator implicit(m: Mtr3x2f): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x2f): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    
  end;
  
  Mtr2x4f = record
    public val00, val01, val02, val03: single;
    public val10, val11, val12, val13: single;
    
    public constructor(val00, val01, val02, val03, val10, val11, val12, val13: single);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val03 := val03;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
      self.val13 := val13;
    end;
    
    private function GetValAt(y,x: integer): single;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          3: Result := self.val03;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          3: Result := self.val13;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: single);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          3: self.val03 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          3: self.val13 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    public property val[y,x: integer]: single read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr2x4f read new Mtr2x4f(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    
    public property Row0: Vec4f read new Vec4f(self.val00, self.val01, self.val02, self.val03) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; self.val03 := value.val3; end;
    public property Row1: Vec4f read new Vec4f(self.val10, self.val11, self.val12, self.val13) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; self.val13 := value.val3; end;
    public property Row[y: integer]: Vec4f read y=0?Row0:y=1?Row1:Arr&<Vec4f>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..1');
    end;
    
    public property Col0: Vec2f read new Vec2f(self.val00, self.val10) write begin self.val00 := value.val0; self.val10 := value.val1; end;
    public property Col1: Vec2f read new Vec2f(self.val01, self.val11) write begin self.val01 := value.val0; self.val11 := value.val1; end;
    public property Col2: Vec2f read new Vec2f(self.val02, self.val12) write begin self.val02 := value.val0; self.val12 := value.val1; end;
    public property Col3: Vec2f read new Vec2f(self.val03, self.val13) write begin self.val03 := value.val0; self.val13 := value.val1; end;
    public property Col[x: integer]: Vec2f read x=0?Col0:x=1?Col1:x=2?Col2:x=3?Col3:Arr&<Vec2f>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      3: Col3 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..3');
    end;
    
    public property RowPtr0: ^Vec4f read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec4f read pointer(IntPtr(pointer(@self)) + 16);
    public property RowPtr2: ^Vec4f read pointer(IntPtr(pointer(@self)) + 32);
    public property RowPtr3: ^Vec4f read pointer(IntPtr(pointer(@self)) + 48);
    public property RowPtr[x: integer]: ^Vec4f read pointer(IntPtr(pointer(@self)) + x*16);
    
    public static function operator*(m: Mtr2x4f; v: Vec4f): Vec2f := new Vec2f(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2+m.val03*v.val3, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2+m.val13*v.val3);
    public static function operator*(v: Vec2f; m: Mtr2x4f): Vec4f := new Vec4f(m.val00*v.val0+m.val10*v.val1, m.val01*v.val0+m.val11*v.val1, m.val02*v.val0+m.val12*v.val1, m.val03*v.val0+m.val13*v.val1);
    
    public static function operator implicit(m: Mtr2x2f): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr2x4f): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    public static function operator implicit(m: Mtr2x4f): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x4f): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13);
    public static function operator implicit(m: Mtr2x4f): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    public static function operator implicit(m: Mtr2x4f): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2f): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr2x4f): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    
  end;
  
  Mtr4x2f = record
    public val00, val01: single;
    public val10, val11: single;
    public val20, val21: single;
    public val30, val31: single;
    
    public constructor(val00, val01, val10, val11, val20, val21, val30, val31: single);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val10 := val10;
      self.val11 := val11;
      self.val20 := val20;
      self.val21 := val21;
      self.val30 := val30;
      self.val31 := val31;
    end;
    
    private function GetValAt(y,x: integer): single;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        3:
        case x of
          0: Result := self.val30;
          1: Result := self.val31;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: single);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        3:
        case x of
          0: self.val30 := val;
          1: self.val31 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    public property val[y,x: integer]: single read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr4x2f read new Mtr4x2f(1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0);
    
    public property Row0: Vec2f read new Vec2f(self.val00, self.val01) write begin self.val00 := value.val0; self.val01 := value.val1; end;
    public property Row1: Vec2f read new Vec2f(self.val10, self.val11) write begin self.val10 := value.val0; self.val11 := value.val1; end;
    public property Row2: Vec2f read new Vec2f(self.val20, self.val21) write begin self.val20 := value.val0; self.val21 := value.val1; end;
    public property Row3: Vec2f read new Vec2f(self.val30, self.val31) write begin self.val30 := value.val0; self.val31 := value.val1; end;
    public property Row[y: integer]: Vec2f read y=0?Row0:y=1?Row1:y=2?Row2:y=3?Row3:Arr&<Vec2f>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      3: Row3 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..3');
    end;
    
    public property Col0: Vec4f read new Vec4f(self.val00, self.val10, self.val20, self.val30) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; self.val30 := value.val3; end;
    public property Col1: Vec4f read new Vec4f(self.val01, self.val11, self.val21, self.val31) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; self.val31 := value.val3; end;
    public property Col[x: integer]: Vec4f read x=0?Col0:x=1?Col1:Arr&<Vec4f>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..1');
    end;
    
    public property RowPtr0: ^Vec2f read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec2f read pointer(IntPtr(pointer(@self)) + 8);
    public property RowPtr[x: integer]: ^Vec2f read pointer(IntPtr(pointer(@self)) + x*8);
    
    public static function operator*(m1: Mtr4x2f; m2: Mtr2x4f): Mtr4x4f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12;
      Result.val03 := m1.val00*m2.val03 + m1.val01*m2.val13;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12;
      Result.val13 := m1.val10*m2.val03 + m1.val11*m2.val13;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12;
      Result.val23 := m1.val20*m2.val03 + m1.val21*m2.val13;
      Result.val30 := m1.val30*m2.val00 + m1.val31*m2.val10;
      Result.val31 := m1.val30*m2.val01 + m1.val31*m2.val11;
      Result.val32 := m1.val30*m2.val02 + m1.val31*m2.val12;
      Result.val33 := m1.val30*m2.val03 + m1.val31*m2.val13;
    end;
    
    public static function operator*(m1: Mtr2x4f; m2: Mtr4x2f): Mtr2x2f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20 + m1.val03*m2.val30;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21 + m1.val03*m2.val31;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20 + m1.val13*m2.val30;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21 + m1.val13*m2.val31;
    end;
    
    public static function operator*(m: Mtr4x2f; v: Vec2f): Vec4f := new Vec4f(m.val00*v.val0+m.val01*v.val1, m.val10*v.val0+m.val11*v.val1, m.val20*v.val0+m.val21*v.val1, m.val30*v.val0+m.val31*v.val1);
    public static function operator*(v: Vec4f; m: Mtr4x2f): Vec2f := new Vec2f(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2+m.val30*v.val3, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2+m.val31*v.val3);
    
    public static function operator implicit(m: Mtr2x2f): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2f): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2f): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0);
    
    public static function operator implicit(m: Mtr4x4f): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, m.val30, m.val31);
    public static function operator implicit(m: Mtr4x2f): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0, m.val30, m.val31, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2f): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    
    public static function operator implicit(m: Mtr3x2f): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2f): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4f): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2f): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    
  end;
  
  Mtr3x4f = record
    public val00, val01, val02, val03: single;
    public val10, val11, val12, val13: single;
    public val20, val21, val22, val23: single;
    
    public constructor(val00, val01, val02, val03, val10, val11, val12, val13, val20, val21, val22, val23: single);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val03 := val03;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
      self.val13 := val13;
      self.val20 := val20;
      self.val21 := val21;
      self.val22 := val22;
      self.val23 := val23;
    end;
    
    private function GetValAt(y,x: integer): single;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          3: Result := self.val03;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          3: Result := self.val13;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          2: Result := self.val22;
          3: Result := self.val23;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: single);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          3: self.val03 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          3: self.val13 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          2: self.val22 := val;
          3: self.val23 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    public property val[y,x: integer]: single read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr3x4f read new Mtr3x4f(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    
    public property Row0: Vec4f read new Vec4f(self.val00, self.val01, self.val02, self.val03) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; self.val03 := value.val3; end;
    public property Row1: Vec4f read new Vec4f(self.val10, self.val11, self.val12, self.val13) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; self.val13 := value.val3; end;
    public property Row2: Vec4f read new Vec4f(self.val20, self.val21, self.val22, self.val23) write begin self.val20 := value.val0; self.val21 := value.val1; self.val22 := value.val2; self.val23 := value.val3; end;
    public property Row[y: integer]: Vec4f read y=0?Row0:y=1?Row1:y=2?Row2:Arr&<Vec4f>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..2');
    end;
    
    public property Col0: Vec3f read new Vec3f(self.val00, self.val10, self.val20) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; end;
    public property Col1: Vec3f read new Vec3f(self.val01, self.val11, self.val21) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; end;
    public property Col2: Vec3f read new Vec3f(self.val02, self.val12, self.val22) write begin self.val02 := value.val0; self.val12 := value.val1; self.val22 := value.val2; end;
    public property Col3: Vec3f read new Vec3f(self.val03, self.val13, self.val23) write begin self.val03 := value.val0; self.val13 := value.val1; self.val23 := value.val2; end;
    public property Col[x: integer]: Vec3f read x=0?Col0:x=1?Col1:x=2?Col2:x=3?Col3:Arr&<Vec3f>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      3: Col3 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..3');
    end;
    
    public property RowPtr0: ^Vec4f read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec4f read pointer(IntPtr(pointer(@self)) + 16);
    public property RowPtr2: ^Vec4f read pointer(IntPtr(pointer(@self)) + 32);
    public property RowPtr3: ^Vec4f read pointer(IntPtr(pointer(@self)) + 48);
    public property RowPtr[x: integer]: ^Vec4f read pointer(IntPtr(pointer(@self)) + x*16);
    
    public static function operator*(m1: Mtr3x4f; m2: Mtr4x2f): Mtr3x2f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20 + m1.val03*m2.val30;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21 + m1.val03*m2.val31;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20 + m1.val13*m2.val30;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21 + m1.val13*m2.val31;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20 + m1.val23*m2.val30;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21 + m1.val23*m2.val31;
    end;
    
    public static function operator*(m1: Mtr2x3f; m2: Mtr3x4f): Mtr2x4f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22;
      Result.val03 := m1.val00*m2.val03 + m1.val01*m2.val13 + m1.val02*m2.val23;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22;
      Result.val13 := m1.val10*m2.val03 + m1.val11*m2.val13 + m1.val12*m2.val23;
    end;
    
    public static function operator*(m: Mtr3x4f; v: Vec4f): Vec3f := new Vec3f(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2+m.val03*v.val3, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2+m.val13*v.val3, m.val20*v.val0+m.val21*v.val1+m.val22*v.val2+m.val23*v.val3);
    public static function operator*(v: Vec3f; m: Mtr3x4f): Vec4f := new Vec4f(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2, m.val02*v.val0+m.val12*v.val1+m.val22*v.val2, m.val03*v.val0+m.val13*v.val1+m.val23*v.val2);
    
    public static function operator implicit(m: Mtr2x2f): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4f): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0);
    public static function operator implicit(m: Mtr3x4f): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    
    public static function operator implicit(m: Mtr4x4f): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23);
    public static function operator implicit(m: Mtr3x4f): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4f): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2f): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4f): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4f): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4f): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13);
    
    public static function operator implicit(m: Mtr4x2f): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4f): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    
  end;
  
  Mtr4x3f = record
    public val00, val01, val02: single;
    public val10, val11, val12: single;
    public val20, val21, val22: single;
    public val30, val31, val32: single;
    
    public constructor(val00, val01, val02, val10, val11, val12, val20, val21, val22, val30, val31, val32: single);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
      self.val20 := val20;
      self.val21 := val21;
      self.val22 := val22;
      self.val30 := val30;
      self.val31 := val31;
      self.val32 := val32;
    end;
    
    private function GetValAt(y,x: integer): single;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          2: Result := self.val22;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        3:
        case x of
          0: Result := self.val30;
          1: Result := self.val31;
          2: Result := self.val32;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: single);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          2: self.val22 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        3:
        case x of
          0: self.val30 := val;
          1: self.val31 := val;
          2: self.val32 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    public property val[y,x: integer]: single read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr4x3f read new Mtr4x3f(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0);
    
    public property Row0: Vec3f read new Vec3f(self.val00, self.val01, self.val02) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; end;
    public property Row1: Vec3f read new Vec3f(self.val10, self.val11, self.val12) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; end;
    public property Row2: Vec3f read new Vec3f(self.val20, self.val21, self.val22) write begin self.val20 := value.val0; self.val21 := value.val1; self.val22 := value.val2; end;
    public property Row3: Vec3f read new Vec3f(self.val30, self.val31, self.val32) write begin self.val30 := value.val0; self.val31 := value.val1; self.val32 := value.val2; end;
    public property Row[y: integer]: Vec3f read y=0?Row0:y=1?Row1:y=2?Row2:y=3?Row3:Arr&<Vec3f>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      3: Row3 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..3');
    end;
    
    public property Col0: Vec4f read new Vec4f(self.val00, self.val10, self.val20, self.val30) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; self.val30 := value.val3; end;
    public property Col1: Vec4f read new Vec4f(self.val01, self.val11, self.val21, self.val31) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; self.val31 := value.val3; end;
    public property Col2: Vec4f read new Vec4f(self.val02, self.val12, self.val22, self.val32) write begin self.val02 := value.val0; self.val12 := value.val1; self.val22 := value.val2; self.val32 := value.val3; end;
    public property Col[x: integer]: Vec4f read x=0?Col0:x=1?Col1:x=2?Col2:Arr&<Vec4f>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..2');
    end;
    
    public property RowPtr0: ^Vec3f read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec3f read pointer(IntPtr(pointer(@self)) + 12);
    public property RowPtr2: ^Vec3f read pointer(IntPtr(pointer(@self)) + 24);
    public property RowPtr[x: integer]: ^Vec3f read pointer(IntPtr(pointer(@self)) + x*12);
    
    public static function operator*(m1: Mtr4x3f; m2: Mtr3x2f): Mtr4x2f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21;
      Result.val30 := m1.val30*m2.val00 + m1.val31*m2.val10 + m1.val32*m2.val20;
      Result.val31 := m1.val30*m2.val01 + m1.val31*m2.val11 + m1.val32*m2.val21;
    end;
    
    public static function operator*(m1: Mtr4x3f; m2: Mtr3x4f): Mtr4x4f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22;
      Result.val03 := m1.val00*m2.val03 + m1.val01*m2.val13 + m1.val02*m2.val23;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22;
      Result.val13 := m1.val10*m2.val03 + m1.val11*m2.val13 + m1.val12*m2.val23;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12 + m1.val22*m2.val22;
      Result.val23 := m1.val20*m2.val03 + m1.val21*m2.val13 + m1.val22*m2.val23;
      Result.val30 := m1.val30*m2.val00 + m1.val31*m2.val10 + m1.val32*m2.val20;
      Result.val31 := m1.val30*m2.val01 + m1.val31*m2.val11 + m1.val32*m2.val21;
      Result.val32 := m1.val30*m2.val02 + m1.val31*m2.val12 + m1.val32*m2.val22;
      Result.val33 := m1.val30*m2.val03 + m1.val31*m2.val13 + m1.val32*m2.val23;
    end;
    
    public static function operator*(m1: Mtr2x4f; m2: Mtr4x3f): Mtr2x3f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20 + m1.val03*m2.val30;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21 + m1.val03*m2.val31;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22 + m1.val03*m2.val32;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20 + m1.val13*m2.val30;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21 + m1.val13*m2.val31;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22 + m1.val13*m2.val32;
    end;
    
    public static function operator*(m1: Mtr3x4f; m2: Mtr4x3f): Mtr3x3f;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20 + m1.val03*m2.val30;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21 + m1.val03*m2.val31;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22 + m1.val03*m2.val32;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20 + m1.val13*m2.val30;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21 + m1.val13*m2.val31;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22 + m1.val13*m2.val32;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20 + m1.val23*m2.val30;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21 + m1.val23*m2.val31;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12 + m1.val22*m2.val22 + m1.val23*m2.val32;
    end;
    
    public static function operator*(m: Mtr4x3f; v: Vec3f): Vec4f := new Vec4f(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2, m.val20*v.val0+m.val21*v.val1+m.val22*v.val2, m.val30*v.val0+m.val31*v.val1+m.val32*v.val2);
    public static function operator*(v: Vec4f; m: Mtr4x3f): Vec3f := new Vec3f(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2+m.val30*v.val3, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2+m.val31*v.val3, m.val02*v.val0+m.val12*v.val1+m.val22*v.val2+m.val32*v.val3);
    
    public static function operator implicit(m: Mtr2x2f): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3f): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3f): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    
    public static function operator implicit(m: Mtr4x4f): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, m.val30, m.val31, m.val32);
    public static function operator implicit(m: Mtr4x3f): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0, m.val30, m.val31, m.val32, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3f): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2f): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3f): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4f): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3f): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    
    public static function operator implicit(m: Mtr4x2f): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0, m.val30, m.val31, 0.0);
    public static function operator implicit(m: Mtr4x3f): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, m.val30, m.val31);
    
    public static function operator implicit(m: Mtr3x4f): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3f): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0);
    
  end;
  
  Mtr2x2d = record
    public val00, val01: real;
    public val10, val11: real;
    
    public constructor(val00, val01, val10, val11: real);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val10 := val10;
      self.val11 := val11;
    end;
    
    private function GetValAt(y,x: integer): real;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: real);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    public property val[y,x: integer]: real read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr2x2d read new Mtr2x2d(1.0, 0.0, 0.0, 1.0);
    
    public property Row0: Vec2d read new Vec2d(self.val00, self.val01) write begin self.val00 := value.val0; self.val01 := value.val1; end;
    public property Row1: Vec2d read new Vec2d(self.val10, self.val11) write begin self.val10 := value.val0; self.val11 := value.val1; end;
    public property Row[y: integer]: Vec2d read y=0?Row0:y=1?Row1:Arr&<Vec2d>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..1');
    end;
    
    public property Col0: Vec2d read new Vec2d(self.val00, self.val10) write begin self.val00 := value.val0; self.val10 := value.val1; end;
    public property Col1: Vec2d read new Vec2d(self.val01, self.val11) write begin self.val01 := value.val0; self.val11 := value.val1; end;
    public property Col[x: integer]: Vec2d read x=0?Col0:x=1?Col1:Arr&<Vec2d>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..1');
    end;
    
    public property RowPtr0: ^Vec2d read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec2d read pointer(IntPtr(pointer(@self)) + 16);
    public property RowPtr[x: integer]: ^Vec2d read pointer(IntPtr(pointer(@self)) + x*16);
    
    public static function operator*(m1: Mtr2x2d; m2: Mtr2x2d): Mtr2x2d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11;
    end;
    
    public static function operator*(m: Mtr2x2d; v: Vec2d): Vec2d := new Vec2d(m.val00*v.val0+m.val01*v.val1, m.val10*v.val0+m.val11*v.val1);
    public static function operator*(v: Vec2d; m: Mtr2x2d): Vec2d := new Vec2d(m.val00*v.val0+m.val10*v.val1, m.val01*v.val0+m.val11*v.val1);
    
    public static function operator implicit(m: Mtr2x2f): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    public static function operator implicit(m: Mtr2x2d): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    public static function operator implicit(m: Mtr2x2d): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x4f): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    public static function operator implicit(m: Mtr2x2d): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    public static function operator implicit(m: Mtr2x2d): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    
    public static function operator implicit(m: Mtr3x2f): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    public static function operator implicit(m: Mtr2x2d): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x4f): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    public static function operator implicit(m: Mtr2x2d): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x2f): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    public static function operator implicit(m: Mtr2x2d): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr3x4f): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    public static function operator implicit(m: Mtr2x2d): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x3f): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    public static function operator implicit(m: Mtr2x2d): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
  end;
  Mtr2d = Mtr2x2d;
  
  Mtr3x3d = record
    public val00, val01, val02: real;
    public val10, val11, val12: real;
    public val20, val21, val22: real;
    
    public constructor(val00, val01, val02, val10, val11, val12, val20, val21, val22: real);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
      self.val20 := val20;
      self.val21 := val21;
      self.val22 := val22;
    end;
    
    private function GetValAt(y,x: integer): real;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          2: Result := self.val22;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: real);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          2: self.val22 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    public property val[y,x: integer]: real read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr3x3d read new Mtr3x3d(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0);
    
    public property Row0: Vec3d read new Vec3d(self.val00, self.val01, self.val02) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; end;
    public property Row1: Vec3d read new Vec3d(self.val10, self.val11, self.val12) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; end;
    public property Row2: Vec3d read new Vec3d(self.val20, self.val21, self.val22) write begin self.val20 := value.val0; self.val21 := value.val1; self.val22 := value.val2; end;
    public property Row[y: integer]: Vec3d read y=0?Row0:y=1?Row1:y=2?Row2:Arr&<Vec3d>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..2');
    end;
    
    public property Col0: Vec3d read new Vec3d(self.val00, self.val10, self.val20) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; end;
    public property Col1: Vec3d read new Vec3d(self.val01, self.val11, self.val21) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; end;
    public property Col2: Vec3d read new Vec3d(self.val02, self.val12, self.val22) write begin self.val02 := value.val0; self.val12 := value.val1; self.val22 := value.val2; end;
    public property Col[x: integer]: Vec3d read x=0?Col0:x=1?Col1:x=2?Col2:Arr&<Vec3d>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..2');
    end;
    
    public property RowPtr0: ^Vec3d read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec3d read pointer(IntPtr(pointer(@self)) + 24);
    public property RowPtr2: ^Vec3d read pointer(IntPtr(pointer(@self)) + 48);
    public property RowPtr[x: integer]: ^Vec3d read pointer(IntPtr(pointer(@self)) + x*24);
    
    public static function operator*(m1: Mtr3x3d; m2: Mtr3x3d): Mtr3x3d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12 + m1.val22*m2.val22;
    end;
    
    public static function operator*(m: Mtr3x3d; v: Vec3d): Vec3d := new Vec3d(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2, m.val20*v.val0+m.val21*v.val1+m.val22*v.val2);
    public static function operator*(v: Vec3d; m: Mtr3x3d): Vec3d := new Vec3d(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2, m.val02*v.val0+m.val12*v.val1+m.val22*v.val2);
    
    public static function operator implicit(m: Mtr2x2f): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x3d): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    public static function operator implicit(m: Mtr3x3d): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    
    public static function operator implicit(m: Mtr4x4f): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    public static function operator implicit(m: Mtr3x3d): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x3d): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2f): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0);
    public static function operator implicit(m: Mtr3x3d): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4f): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x3d): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    
    public static function operator implicit(m: Mtr4x2f): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0);
    public static function operator implicit(m: Mtr3x3d): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr3x4f): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    public static function operator implicit(m: Mtr3x3d): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0);
    
    public static function operator implicit(m: Mtr4x3f): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    public static function operator implicit(m: Mtr3x3d): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x2d): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x3d): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    
  end;
  Mtr3d = Mtr3x3d;
  
  Mtr4x4d = record
    public val00, val01, val02, val03: real;
    public val10, val11, val12, val13: real;
    public val20, val21, val22, val23: real;
    public val30, val31, val32, val33: real;
    
    public constructor(val00, val01, val02, val03, val10, val11, val12, val13, val20, val21, val22, val23, val30, val31, val32, val33: real);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val03 := val03;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
      self.val13 := val13;
      self.val20 := val20;
      self.val21 := val21;
      self.val22 := val22;
      self.val23 := val23;
      self.val30 := val30;
      self.val31 := val31;
      self.val32 := val32;
      self.val33 := val33;
    end;
    
    private function GetValAt(y,x: integer): real;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          3: Result := self.val03;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          3: Result := self.val13;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          2: Result := self.val22;
          3: Result := self.val23;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        3:
        case x of
          0: Result := self.val30;
          1: Result := self.val31;
          2: Result := self.val32;
          3: Result := self.val33;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: real);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          3: self.val03 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          3: self.val13 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          2: self.val22 := val;
          3: self.val23 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        3:
        case x of
          0: self.val30 := val;
          1: self.val31 := val;
          2: self.val32 := val;
          3: self.val33 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    public property val[y,x: integer]: real read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr4x4d read new Mtr4x4d(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0);
    
    public property Row0: Vec4d read new Vec4d(self.val00, self.val01, self.val02, self.val03) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; self.val03 := value.val3; end;
    public property Row1: Vec4d read new Vec4d(self.val10, self.val11, self.val12, self.val13) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; self.val13 := value.val3; end;
    public property Row2: Vec4d read new Vec4d(self.val20, self.val21, self.val22, self.val23) write begin self.val20 := value.val0; self.val21 := value.val1; self.val22 := value.val2; self.val23 := value.val3; end;
    public property Row3: Vec4d read new Vec4d(self.val30, self.val31, self.val32, self.val33) write begin self.val30 := value.val0; self.val31 := value.val1; self.val32 := value.val2; self.val33 := value.val3; end;
    public property Row[y: integer]: Vec4d read y=0?Row0:y=1?Row1:y=2?Row2:y=3?Row3:Arr&<Vec4d>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      3: Row3 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..3');
    end;
    
    public property Col0: Vec4d read new Vec4d(self.val00, self.val10, self.val20, self.val30) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; self.val30 := value.val3; end;
    public property Col1: Vec4d read new Vec4d(self.val01, self.val11, self.val21, self.val31) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; self.val31 := value.val3; end;
    public property Col2: Vec4d read new Vec4d(self.val02, self.val12, self.val22, self.val32) write begin self.val02 := value.val0; self.val12 := value.val1; self.val22 := value.val2; self.val32 := value.val3; end;
    public property Col3: Vec4d read new Vec4d(self.val03, self.val13, self.val23, self.val33) write begin self.val03 := value.val0; self.val13 := value.val1; self.val23 := value.val2; self.val33 := value.val3; end;
    public property Col[x: integer]: Vec4d read x=0?Col0:x=1?Col1:x=2?Col2:x=3?Col3:Arr&<Vec4d>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      3: Col3 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..3');
    end;
    
    public property RowPtr0: ^Vec4d read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec4d read pointer(IntPtr(pointer(@self)) + 32);
    public property RowPtr2: ^Vec4d read pointer(IntPtr(pointer(@self)) + 64);
    public property RowPtr3: ^Vec4d read pointer(IntPtr(pointer(@self)) + 96);
    public property RowPtr[x: integer]: ^Vec4d read pointer(IntPtr(pointer(@self)) + x*32);
    
    public static function operator*(m1: Mtr4x4d; m2: Mtr4x4d): Mtr4x4d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20 + m1.val03*m2.val30;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21 + m1.val03*m2.val31;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22 + m1.val03*m2.val32;
      Result.val03 := m1.val00*m2.val03 + m1.val01*m2.val13 + m1.val02*m2.val23 + m1.val03*m2.val33;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20 + m1.val13*m2.val30;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21 + m1.val13*m2.val31;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22 + m1.val13*m2.val32;
      Result.val13 := m1.val10*m2.val03 + m1.val11*m2.val13 + m1.val12*m2.val23 + m1.val13*m2.val33;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20 + m1.val23*m2.val30;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21 + m1.val23*m2.val31;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12 + m1.val22*m2.val22 + m1.val23*m2.val32;
      Result.val23 := m1.val20*m2.val03 + m1.val21*m2.val13 + m1.val22*m2.val23 + m1.val23*m2.val33;
      Result.val30 := m1.val30*m2.val00 + m1.val31*m2.val10 + m1.val32*m2.val20 + m1.val33*m2.val30;
      Result.val31 := m1.val30*m2.val01 + m1.val31*m2.val11 + m1.val32*m2.val21 + m1.val33*m2.val31;
      Result.val32 := m1.val30*m2.val02 + m1.val31*m2.val12 + m1.val32*m2.val22 + m1.val33*m2.val32;
      Result.val33 := m1.val30*m2.val03 + m1.val31*m2.val13 + m1.val32*m2.val23 + m1.val33*m2.val33;
    end;
    
    public static function operator*(m: Mtr4x4d; v: Vec4d): Vec4d := new Vec4d(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2+m.val03*v.val3, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2+m.val13*v.val3, m.val20*v.val0+m.val21*v.val1+m.val22*v.val2+m.val23*v.val3, m.val30*v.val0+m.val31*v.val1+m.val32*v.val2+m.val33*v.val3);
    public static function operator*(v: Vec4d; m: Mtr4x4d): Vec4d := new Vec4d(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2+m.val30*v.val3, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2+m.val31*v.val3, m.val02*v.val0+m.val12*v.val1+m.val22*v.val2+m.val32*v.val3, m.val03*v.val0+m.val13*v.val1+m.val23*v.val2+m.val33*v.val3);
    
    public static function operator implicit(m: Mtr2x2f): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4d): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4d): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    
    public static function operator implicit(m: Mtr4x4f): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23, m.val30, m.val31, m.val32, m.val33);
    public static function operator implicit(m: Mtr4x4d): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23, m.val30, m.val31, m.val32, m.val33);
    
    public static function operator implicit(m: Mtr2x3f): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4d): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2f): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4d): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4f): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4d): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13);
    
    public static function operator implicit(m: Mtr4x2f): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0, m.val30, m.val31, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4d): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, m.val30, m.val31);
    
    public static function operator implicit(m: Mtr3x4f): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4d): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23);
    
    public static function operator implicit(m: Mtr4x3f): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0, m.val30, m.val31, m.val32, 0.0);
    public static function operator implicit(m: Mtr4x4d): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, m.val30, m.val31, m.val32);
    
    public static function operator implicit(m: Mtr2x2d): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4d): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3d): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x4d): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    
  end;
  Mtr4d = Mtr4x4d;
  
  Mtr2x3d = record
    public val00, val01, val02: real;
    public val10, val11, val12: real;
    
    public constructor(val00, val01, val02, val10, val11, val12: real);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
    end;
    
    private function GetValAt(y,x: integer): real;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: real);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    public property val[y,x: integer]: real read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr2x3d read new Mtr2x3d(1.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    
    public property Row0: Vec3d read new Vec3d(self.val00, self.val01, self.val02) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; end;
    public property Row1: Vec3d read new Vec3d(self.val10, self.val11, self.val12) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; end;
    public property Row[y: integer]: Vec3d read y=0?Row0:y=1?Row1:Arr&<Vec3d>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..1');
    end;
    
    public property Col0: Vec2d read new Vec2d(self.val00, self.val10) write begin self.val00 := value.val0; self.val10 := value.val1; end;
    public property Col1: Vec2d read new Vec2d(self.val01, self.val11) write begin self.val01 := value.val0; self.val11 := value.val1; end;
    public property Col2: Vec2d read new Vec2d(self.val02, self.val12) write begin self.val02 := value.val0; self.val12 := value.val1; end;
    public property Col[x: integer]: Vec2d read x=0?Col0:x=1?Col1:x=2?Col2:Arr&<Vec2d>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..2');
    end;
    
    public property RowPtr0: ^Vec3d read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec3d read pointer(IntPtr(pointer(@self)) + 24);
    public property RowPtr2: ^Vec3d read pointer(IntPtr(pointer(@self)) + 48);
    public property RowPtr[x: integer]: ^Vec3d read pointer(IntPtr(pointer(@self)) + x*24);
    
    public static function operator*(m: Mtr2x3d; v: Vec3d): Vec2d := new Vec2d(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2);
    public static function operator*(v: Vec2d; m: Mtr2x3d): Vec3d := new Vec3d(m.val00*v.val0+m.val10*v.val1, m.val01*v.val0+m.val11*v.val1, m.val02*v.val0+m.val12*v.val1);
    
    public static function operator implicit(m: Mtr2x2f): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    public static function operator implicit(m: Mtr2x3d): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    public static function operator implicit(m: Mtr2x3d): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x4f): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    public static function operator implicit(m: Mtr2x3d): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    public static function operator implicit(m: Mtr2x3d): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2f): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    public static function operator implicit(m: Mtr2x3d): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x4f): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    public static function operator implicit(m: Mtr2x3d): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    
    public static function operator implicit(m: Mtr4x2f): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    public static function operator implicit(m: Mtr2x3d): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr3x4f): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    public static function operator implicit(m: Mtr2x3d): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x3f): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    public static function operator implicit(m: Mtr2x3d): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x2d): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    public static function operator implicit(m: Mtr2x3d): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3d): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    public static function operator implicit(m: Mtr2x3d): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x4d): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    public static function operator implicit(m: Mtr2x3d): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
  end;
  
  Mtr3x2d = record
    public val00, val01: real;
    public val10, val11: real;
    public val20, val21: real;
    
    public constructor(val00, val01, val10, val11, val20, val21: real);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val10 := val10;
      self.val11 := val11;
      self.val20 := val20;
      self.val21 := val21;
    end;
    
    private function GetValAt(y,x: integer): real;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: real);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    public property val[y,x: integer]: real read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr3x2d read new Mtr3x2d(1.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    
    public property Row0: Vec2d read new Vec2d(self.val00, self.val01) write begin self.val00 := value.val0; self.val01 := value.val1; end;
    public property Row1: Vec2d read new Vec2d(self.val10, self.val11) write begin self.val10 := value.val0; self.val11 := value.val1; end;
    public property Row2: Vec2d read new Vec2d(self.val20, self.val21) write begin self.val20 := value.val0; self.val21 := value.val1; end;
    public property Row[y: integer]: Vec2d read y=0?Row0:y=1?Row1:y=2?Row2:Arr&<Vec2d>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..2');
    end;
    
    public property Col0: Vec3d read new Vec3d(self.val00, self.val10, self.val20) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; end;
    public property Col1: Vec3d read new Vec3d(self.val01, self.val11, self.val21) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; end;
    public property Col[x: integer]: Vec3d read x=0?Col0:x=1?Col1:Arr&<Vec3d>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..1');
    end;
    
    public property RowPtr0: ^Vec2d read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec2d read pointer(IntPtr(pointer(@self)) + 16);
    public property RowPtr[x: integer]: ^Vec2d read pointer(IntPtr(pointer(@self)) + x*16);
    
    public static function operator*(m1: Mtr3x2d; m2: Mtr2x3d): Mtr3x3d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12;
    end;
    
    public static function operator*(m1: Mtr2x3d; m2: Mtr3x2d): Mtr2x2d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21;
    end;
    
    public static function operator*(m: Mtr3x2d; v: Vec2d): Vec3d := new Vec3d(m.val00*v.val0+m.val01*v.val1, m.val10*v.val0+m.val11*v.val1, m.val20*v.val0+m.val21*v.val1);
    public static function operator*(v: Vec3d; m: Mtr3x2d): Vec2d := new Vec2d(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2);
    
    public static function operator implicit(m: Mtr2x2f): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x2d): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    public static function operator implicit(m: Mtr3x2d): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0);
    
    public static function operator implicit(m: Mtr4x4f): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    public static function operator implicit(m: Mtr3x2d): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x2d): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    
    public static function operator implicit(m: Mtr3x2f): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    public static function operator implicit(m: Mtr3x2d): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4f): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x2d): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x2f): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    public static function operator implicit(m: Mtr3x2d): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr3x4f): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    public static function operator implicit(m: Mtr3x2d): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x3f): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    public static function operator implicit(m: Mtr3x2d): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x2d): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x2d): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3d): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    public static function operator implicit(m: Mtr3x2d): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0);
    
    public static function operator implicit(m: Mtr4x4d): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    public static function operator implicit(m: Mtr3x2d): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3d): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x2d): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    
  end;
  
  Mtr2x4d = record
    public val00, val01, val02, val03: real;
    public val10, val11, val12, val13: real;
    
    public constructor(val00, val01, val02, val03, val10, val11, val12, val13: real);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val03 := val03;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
      self.val13 := val13;
    end;
    
    private function GetValAt(y,x: integer): real;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          3: Result := self.val03;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          3: Result := self.val13;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: real);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          3: self.val03 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          3: self.val13 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..1');
      end;
    end;
    public property val[y,x: integer]: real read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr2x4d read new Mtr2x4d(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0);
    
    public property Row0: Vec4d read new Vec4d(self.val00, self.val01, self.val02, self.val03) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; self.val03 := value.val3; end;
    public property Row1: Vec4d read new Vec4d(self.val10, self.val11, self.val12, self.val13) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; self.val13 := value.val3; end;
    public property Row[y: integer]: Vec4d read y=0?Row0:y=1?Row1:Arr&<Vec4d>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..1');
    end;
    
    public property Col0: Vec2d read new Vec2d(self.val00, self.val10) write begin self.val00 := value.val0; self.val10 := value.val1; end;
    public property Col1: Vec2d read new Vec2d(self.val01, self.val11) write begin self.val01 := value.val0; self.val11 := value.val1; end;
    public property Col2: Vec2d read new Vec2d(self.val02, self.val12) write begin self.val02 := value.val0; self.val12 := value.val1; end;
    public property Col3: Vec2d read new Vec2d(self.val03, self.val13) write begin self.val03 := value.val0; self.val13 := value.val1; end;
    public property Col[x: integer]: Vec2d read x=0?Col0:x=1?Col1:x=2?Col2:x=3?Col3:Arr&<Vec2d>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      3: Col3 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..3');
    end;
    
    public property RowPtr0: ^Vec4d read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec4d read pointer(IntPtr(pointer(@self)) + 32);
    public property RowPtr2: ^Vec4d read pointer(IntPtr(pointer(@self)) + 64);
    public property RowPtr3: ^Vec4d read pointer(IntPtr(pointer(@self)) + 96);
    public property RowPtr[x: integer]: ^Vec4d read pointer(IntPtr(pointer(@self)) + x*32);
    
    public static function operator*(m: Mtr2x4d; v: Vec4d): Vec2d := new Vec2d(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2+m.val03*v.val3, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2+m.val13*v.val3);
    public static function operator*(v: Vec2d; m: Mtr2x4d): Vec4d := new Vec4d(m.val00*v.val0+m.val10*v.val1, m.val01*v.val0+m.val11*v.val1, m.val02*v.val0+m.val12*v.val1, m.val03*v.val0+m.val13*v.val1);
    
    public static function operator implicit(m: Mtr2x2f): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr2x4d): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    public static function operator implicit(m: Mtr2x4d): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x4f): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13);
    public static function operator implicit(m: Mtr2x4d): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    public static function operator implicit(m: Mtr2x4d): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2f): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr2x4d): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x4f): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13);
    public static function operator implicit(m: Mtr2x4d): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13);
    
    public static function operator implicit(m: Mtr4x2f): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr2x4d): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr3x4f): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13);
    public static function operator implicit(m: Mtr2x4d): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x3f): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    public static function operator implicit(m: Mtr2x4d): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x2d): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr2x4d): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3d): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    public static function operator implicit(m: Mtr2x4d): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x4d): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13);
    public static function operator implicit(m: Mtr2x4d): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3d): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    public static function operator implicit(m: Mtr2x4d): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2d): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    public static function operator implicit(m: Mtr2x4d): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0);
    
  end;
  
  Mtr4x2d = record
    public val00, val01: real;
    public val10, val11: real;
    public val20, val21: real;
    public val30, val31: real;
    
    public constructor(val00, val01, val10, val11, val20, val21, val30, val31: real);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val10 := val10;
      self.val11 := val11;
      self.val20 := val20;
      self.val21 := val21;
      self.val30 := val30;
      self.val31 := val31;
    end;
    
    private function GetValAt(y,x: integer): real;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        3:
        case x of
          0: Result := self.val30;
          1: Result := self.val31;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: real);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        3:
        case x of
          0: self.val30 := val;
          1: self.val31 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..1');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    public property val[y,x: integer]: real read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr4x2d read new Mtr4x2d(1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0);
    
    public property Row0: Vec2d read new Vec2d(self.val00, self.val01) write begin self.val00 := value.val0; self.val01 := value.val1; end;
    public property Row1: Vec2d read new Vec2d(self.val10, self.val11) write begin self.val10 := value.val0; self.val11 := value.val1; end;
    public property Row2: Vec2d read new Vec2d(self.val20, self.val21) write begin self.val20 := value.val0; self.val21 := value.val1; end;
    public property Row3: Vec2d read new Vec2d(self.val30, self.val31) write begin self.val30 := value.val0; self.val31 := value.val1; end;
    public property Row[y: integer]: Vec2d read y=0?Row0:y=1?Row1:y=2?Row2:y=3?Row3:Arr&<Vec2d>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      3: Row3 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..3');
    end;
    
    public property Col0: Vec4d read new Vec4d(self.val00, self.val10, self.val20, self.val30) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; self.val30 := value.val3; end;
    public property Col1: Vec4d read new Vec4d(self.val01, self.val11, self.val21, self.val31) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; self.val31 := value.val3; end;
    public property Col[x: integer]: Vec4d read x=0?Col0:x=1?Col1:Arr&<Vec4d>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..1');
    end;
    
    public property RowPtr0: ^Vec2d read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec2d read pointer(IntPtr(pointer(@self)) + 16);
    public property RowPtr[x: integer]: ^Vec2d read pointer(IntPtr(pointer(@self)) + x*16);
    
    public static function operator*(m1: Mtr4x2d; m2: Mtr2x4d): Mtr4x4d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12;
      Result.val03 := m1.val00*m2.val03 + m1.val01*m2.val13;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12;
      Result.val13 := m1.val10*m2.val03 + m1.val11*m2.val13;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12;
      Result.val23 := m1.val20*m2.val03 + m1.val21*m2.val13;
      Result.val30 := m1.val30*m2.val00 + m1.val31*m2.val10;
      Result.val31 := m1.val30*m2.val01 + m1.val31*m2.val11;
      Result.val32 := m1.val30*m2.val02 + m1.val31*m2.val12;
      Result.val33 := m1.val30*m2.val03 + m1.val31*m2.val13;
    end;
    
    public static function operator*(m1: Mtr2x4d; m2: Mtr4x2d): Mtr2x2d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20 + m1.val03*m2.val30;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21 + m1.val03*m2.val31;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20 + m1.val13*m2.val30;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21 + m1.val13*m2.val31;
    end;
    
    public static function operator*(m: Mtr4x2d; v: Vec2d): Vec4d := new Vec4d(m.val00*v.val0+m.val01*v.val1, m.val10*v.val0+m.val11*v.val1, m.val20*v.val0+m.val21*v.val1, m.val30*v.val0+m.val31*v.val1);
    public static function operator*(v: Vec4d; m: Mtr4x2d): Vec2d := new Vec2d(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2+m.val30*v.val3, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2+m.val31*v.val3);
    
    public static function operator implicit(m: Mtr2x2f): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0);
    
    public static function operator implicit(m: Mtr4x4f): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, m.val30, m.val31);
    public static function operator implicit(m: Mtr4x2d): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0, m.val30, m.val31, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    
    public static function operator implicit(m: Mtr3x2f): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4f): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x2f): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, m.val30, m.val31);
    public static function operator implicit(m: Mtr4x2d): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, m.val30, m.val31);
    
    public static function operator implicit(m: Mtr3x4f): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr4x3f): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, m.val30, m.val31);
    public static function operator implicit(m: Mtr4x2d): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0, m.val30, m.val31, 0.0);
    
    public static function operator implicit(m: Mtr2x2d): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3d): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0);
    
    public static function operator implicit(m: Mtr4x4d): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, m.val30, m.val31);
    public static function operator implicit(m: Mtr4x2d): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0, m.val30, m.val31, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3d): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0);
    
    public static function operator implicit(m: Mtr3x2d): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4d): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x2d): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0);
    
  end;
  
  Mtr3x4d = record
    public val00, val01, val02, val03: real;
    public val10, val11, val12, val13: real;
    public val20, val21, val22, val23: real;
    
    public constructor(val00, val01, val02, val03, val10, val11, val12, val13, val20, val21, val22, val23: real);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val03 := val03;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
      self.val13 := val13;
      self.val20 := val20;
      self.val21 := val21;
      self.val22 := val22;
      self.val23 := val23;
    end;
    
    private function GetValAt(y,x: integer): real;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          3: Result := self.val03;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          3: Result := self.val13;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          2: Result := self.val22;
          3: Result := self.val23;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: real);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          3: self.val03 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          3: self.val13 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          2: self.val22 := val;
          3: self.val23 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..3');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..2');
      end;
    end;
    public property val[y,x: integer]: real read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr3x4d read new Mtr3x4d(1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 0.0);
    
    public property Row0: Vec4d read new Vec4d(self.val00, self.val01, self.val02, self.val03) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; self.val03 := value.val3; end;
    public property Row1: Vec4d read new Vec4d(self.val10, self.val11, self.val12, self.val13) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; self.val13 := value.val3; end;
    public property Row2: Vec4d read new Vec4d(self.val20, self.val21, self.val22, self.val23) write begin self.val20 := value.val0; self.val21 := value.val1; self.val22 := value.val2; self.val23 := value.val3; end;
    public property Row[y: integer]: Vec4d read y=0?Row0:y=1?Row1:y=2?Row2:Arr&<Vec4d>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..2');
    end;
    
    public property Col0: Vec3d read new Vec3d(self.val00, self.val10, self.val20) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; end;
    public property Col1: Vec3d read new Vec3d(self.val01, self.val11, self.val21) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; end;
    public property Col2: Vec3d read new Vec3d(self.val02, self.val12, self.val22) write begin self.val02 := value.val0; self.val12 := value.val1; self.val22 := value.val2; end;
    public property Col3: Vec3d read new Vec3d(self.val03, self.val13, self.val23) write begin self.val03 := value.val0; self.val13 := value.val1; self.val23 := value.val2; end;
    public property Col[x: integer]: Vec3d read x=0?Col0:x=1?Col1:x=2?Col2:x=3?Col3:Arr&<Vec3d>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      3: Col3 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..3');
    end;
    
    public property RowPtr0: ^Vec4d read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec4d read pointer(IntPtr(pointer(@self)) + 32);
    public property RowPtr2: ^Vec4d read pointer(IntPtr(pointer(@self)) + 64);
    public property RowPtr3: ^Vec4d read pointer(IntPtr(pointer(@self)) + 96);
    public property RowPtr[x: integer]: ^Vec4d read pointer(IntPtr(pointer(@self)) + x*32);
    
    public static function operator*(m1: Mtr3x4d; m2: Mtr4x2d): Mtr3x2d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20 + m1.val03*m2.val30;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21 + m1.val03*m2.val31;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20 + m1.val13*m2.val30;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21 + m1.val13*m2.val31;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20 + m1.val23*m2.val30;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21 + m1.val23*m2.val31;
    end;
    
    public static function operator*(m1: Mtr2x3d; m2: Mtr3x4d): Mtr2x4d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22;
      Result.val03 := m1.val00*m2.val03 + m1.val01*m2.val13 + m1.val02*m2.val23;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22;
      Result.val13 := m1.val10*m2.val03 + m1.val11*m2.val13 + m1.val12*m2.val23;
    end;
    
    public static function operator*(m: Mtr3x4d; v: Vec4d): Vec3d := new Vec3d(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2+m.val03*v.val3, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2+m.val13*v.val3, m.val20*v.val0+m.val21*v.val1+m.val22*v.val2+m.val23*v.val3);
    public static function operator*(v: Vec3d; m: Mtr3x4d): Vec4d := new Vec4d(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2, m.val02*v.val0+m.val12*v.val1+m.val22*v.val2, m.val03*v.val0+m.val13*v.val1+m.val23*v.val2);
    
    public static function operator implicit(m: Mtr2x2f): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    
    public static function operator implicit(m: Mtr4x4f): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23);
    public static function operator implicit(m: Mtr3x4d): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2f): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4f): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13);
    
    public static function operator implicit(m: Mtr4x2f): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr3x4f): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23);
    public static function operator implicit(m: Mtr3x4d): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23);
    
    public static function operator implicit(m: Mtr4x3f): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x2d): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3d): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    
    public static function operator implicit(m: Mtr4x4d): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23);
    public static function operator implicit(m: Mtr3x4d): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, m.val20, m.val21, m.val22, m.val23, 0.0, 0.0, 0.0, 0.0);
    
    public static function operator implicit(m: Mtr2x3d): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2d): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4d): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, m.val03, m.val10, m.val11, m.val12, m.val13);
    
    public static function operator implicit(m: Mtr4x2d): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, 0.0, 0.0, m.val10, m.val11, 0.0, 0.0, m.val20, m.val21, 0.0, 0.0);
    public static function operator implicit(m: Mtr3x4d): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, 0.0, 0.0);
    
  end;
  
  Mtr4x3d = record
    public val00, val01, val02: real;
    public val10, val11, val12: real;
    public val20, val21, val22: real;
    public val30, val31, val32: real;
    
    public constructor(val00, val01, val02, val10, val11, val12, val20, val21, val22, val30, val31, val32: real);
    begin
      self.val00 := val00;
      self.val01 := val01;
      self.val02 := val02;
      self.val10 := val10;
      self.val11 := val11;
      self.val12 := val12;
      self.val20 := val20;
      self.val21 := val21;
      self.val22 := val22;
      self.val30 := val30;
      self.val31 := val31;
      self.val32 := val32;
    end;
    
    private function GetValAt(y,x: integer): real;
    begin
      case y of
        0:
        case x of
          0: Result := self.val00;
          1: Result := self.val01;
          2: Result := self.val02;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: Result := self.val10;
          1: Result := self.val11;
          2: Result := self.val12;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        2:
        case x of
          0: Result := self.val20;
          1: Result := self.val21;
          2: Result := self.val22;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        3:
        case x of
          0: Result := self.val30;
          1: Result := self.val31;
          2: Result := self.val32;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    private procedure SetValAt(y,x: integer; val: real);
    begin
      case y of
        0:
        case x of
          0: self.val00 := val;
          1: self.val01 := val;
          2: self.val02 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        1:
        case x of
          0: self.val10 := val;
          1: self.val11 := val;
          2: self.val12 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        2:
        case x of
          0: self.val20 := val;
          1: self.val21 := val;
          2: self.val22 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        3:
        case x of
          0: self.val30 := val;
          1: self.val31 := val;
          2: self.val32 := val;
          else raise new IndexOutOfRangeException('Индекс "X" должен иметь значение 0..2');
        end;
        else raise new IndexOutOfRangeException('Индекс "Y" должен иметь значение 0..3');
      end;
    end;
    public property val[y,x: integer]: real read GetValAt write SetValAt; default;
    
    public static property Identity: Mtr4x3d read new Mtr4x3d(1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0, 1.0, 0.0, 0.0, 0.0);
    
    public property Row0: Vec3d read new Vec3d(self.val00, self.val01, self.val02) write begin self.val00 := value.val0; self.val01 := value.val1; self.val02 := value.val2; end;
    public property Row1: Vec3d read new Vec3d(self.val10, self.val11, self.val12) write begin self.val10 := value.val0; self.val11 := value.val1; self.val12 := value.val2; end;
    public property Row2: Vec3d read new Vec3d(self.val20, self.val21, self.val22) write begin self.val20 := value.val0; self.val21 := value.val1; self.val22 := value.val2; end;
    public property Row3: Vec3d read new Vec3d(self.val30, self.val31, self.val32) write begin self.val30 := value.val0; self.val31 := value.val1; self.val32 := value.val2; end;
    public property Row[y: integer]: Vec3d read y=0?Row0:y=1?Row1:y=2?Row2:y=3?Row3:Arr&<Vec3d>[y] write
    case y of
      0: Row0 := value;
      1: Row1 := value;
      2: Row2 := value;
      3: Row3 := value;
      else raise new IndexOutOfRangeException('Номер строчки должен иметь значение 0..3');
    end;
    
    public property Col0: Vec4d read new Vec4d(self.val00, self.val10, self.val20, self.val30) write begin self.val00 := value.val0; self.val10 := value.val1; self.val20 := value.val2; self.val30 := value.val3; end;
    public property Col1: Vec4d read new Vec4d(self.val01, self.val11, self.val21, self.val31) write begin self.val01 := value.val0; self.val11 := value.val1; self.val21 := value.val2; self.val31 := value.val3; end;
    public property Col2: Vec4d read new Vec4d(self.val02, self.val12, self.val22, self.val32) write begin self.val02 := value.val0; self.val12 := value.val1; self.val22 := value.val2; self.val32 := value.val3; end;
    public property Col[x: integer]: Vec4d read x=0?Col0:x=1?Col1:x=2?Col2:Arr&<Vec4d>[x] write
    case x of
      0: Col0 := value;
      1: Col1 := value;
      2: Col2 := value;
      else raise new IndexOutOfRangeException('Номер столбца должен иметь значение 0..2');
    end;
    
    public property RowPtr0: ^Vec3d read pointer(IntPtr(pointer(@self)) + 0);
    public property RowPtr1: ^Vec3d read pointer(IntPtr(pointer(@self)) + 24);
    public property RowPtr2: ^Vec3d read pointer(IntPtr(pointer(@self)) + 48);
    public property RowPtr[x: integer]: ^Vec3d read pointer(IntPtr(pointer(@self)) + x*24);
    
    public static function operator*(m1: Mtr4x3d; m2: Mtr3x2d): Mtr4x2d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21;
      Result.val30 := m1.val30*m2.val00 + m1.val31*m2.val10 + m1.val32*m2.val20;
      Result.val31 := m1.val30*m2.val01 + m1.val31*m2.val11 + m1.val32*m2.val21;
    end;
    
    public static function operator*(m1: Mtr4x3d; m2: Mtr3x4d): Mtr4x4d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22;
      Result.val03 := m1.val00*m2.val03 + m1.val01*m2.val13 + m1.val02*m2.val23;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22;
      Result.val13 := m1.val10*m2.val03 + m1.val11*m2.val13 + m1.val12*m2.val23;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12 + m1.val22*m2.val22;
      Result.val23 := m1.val20*m2.val03 + m1.val21*m2.val13 + m1.val22*m2.val23;
      Result.val30 := m1.val30*m2.val00 + m1.val31*m2.val10 + m1.val32*m2.val20;
      Result.val31 := m1.val30*m2.val01 + m1.val31*m2.val11 + m1.val32*m2.val21;
      Result.val32 := m1.val30*m2.val02 + m1.val31*m2.val12 + m1.val32*m2.val22;
      Result.val33 := m1.val30*m2.val03 + m1.val31*m2.val13 + m1.val32*m2.val23;
    end;
    
    public static function operator*(m1: Mtr2x4d; m2: Mtr4x3d): Mtr2x3d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20 + m1.val03*m2.val30;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21 + m1.val03*m2.val31;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22 + m1.val03*m2.val32;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20 + m1.val13*m2.val30;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21 + m1.val13*m2.val31;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22 + m1.val13*m2.val32;
    end;
    
    public static function operator*(m1: Mtr3x4d; m2: Mtr4x3d): Mtr3x3d;
    begin
      Result.val00 := m1.val00*m2.val00 + m1.val01*m2.val10 + m1.val02*m2.val20 + m1.val03*m2.val30;
      Result.val01 := m1.val00*m2.val01 + m1.val01*m2.val11 + m1.val02*m2.val21 + m1.val03*m2.val31;
      Result.val02 := m1.val00*m2.val02 + m1.val01*m2.val12 + m1.val02*m2.val22 + m1.val03*m2.val32;
      Result.val10 := m1.val10*m2.val00 + m1.val11*m2.val10 + m1.val12*m2.val20 + m1.val13*m2.val30;
      Result.val11 := m1.val10*m2.val01 + m1.val11*m2.val11 + m1.val12*m2.val21 + m1.val13*m2.val31;
      Result.val12 := m1.val10*m2.val02 + m1.val11*m2.val12 + m1.val12*m2.val22 + m1.val13*m2.val32;
      Result.val20 := m1.val20*m2.val00 + m1.val21*m2.val10 + m1.val22*m2.val20 + m1.val23*m2.val30;
      Result.val21 := m1.val20*m2.val01 + m1.val21*m2.val11 + m1.val22*m2.val21 + m1.val23*m2.val31;
      Result.val22 := m1.val20*m2.val02 + m1.val21*m2.val12 + m1.val22*m2.val22 + m1.val23*m2.val32;
    end;
    
    public static function operator*(m: Mtr4x3d; v: Vec3d): Vec4d := new Vec4d(m.val00*v.val0+m.val01*v.val1+m.val02*v.val2, m.val10*v.val0+m.val11*v.val1+m.val12*v.val2, m.val20*v.val0+m.val21*v.val1+m.val22*v.val2, m.val30*v.val0+m.val31*v.val1+m.val32*v.val2);
    public static function operator*(v: Vec4d; m: Mtr4x3d): Vec3d := new Vec3d(m.val00*v.val0+m.val10*v.val1+m.val20*v.val2+m.val30*v.val3, m.val01*v.val0+m.val11*v.val1+m.val21*v.val2+m.val31*v.val3, m.val02*v.val0+m.val12*v.val1+m.val22*v.val2+m.val32*v.val3);
    
    public static function operator implicit(m: Mtr2x2f): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr2x2f := new Mtr2x2f(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3f): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr3x3f := new Mtr3x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    
    public static function operator implicit(m: Mtr4x4f): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, m.val30, m.val31, m.val32);
    public static function operator implicit(m: Mtr4x3d): Mtr4x4f := new Mtr4x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0, m.val30, m.val31, m.val32, 0.0);
    
    public static function operator implicit(m: Mtr2x3f): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr2x3f := new Mtr2x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2f): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr3x2f := new Mtr3x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4f): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr2x4f := new Mtr2x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    
    public static function operator implicit(m: Mtr4x2f): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0, m.val30, m.val31, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr4x2f := new Mtr4x2f(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, m.val30, m.val31);
    
    public static function operator implicit(m: Mtr3x4f): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr3x4f := new Mtr3x4f(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0);
    
    public static function operator implicit(m: Mtr4x3f): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, m.val30, m.val31, m.val32);
    public static function operator implicit(m: Mtr4x3d): Mtr4x3f := new Mtr4x3f(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, m.val30, m.val31, m.val32);
    
    public static function operator implicit(m: Mtr2x2d): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr2x2d := new Mtr2x2d(m.val00, m.val01, m.val10, m.val11);
    
    public static function operator implicit(m: Mtr3x3d): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr3x3d := new Mtr3x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22);
    
    public static function operator implicit(m: Mtr4x4d): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, m.val30, m.val31, m.val32);
    public static function operator implicit(m: Mtr4x3d): Mtr4x4d := new Mtr4x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0, m.val30, m.val31, m.val32, 0.0);
    
    public static function operator implicit(m: Mtr2x3d): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr2x3d := new Mtr2x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12);
    
    public static function operator implicit(m: Mtr3x2d): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr3x2d := new Mtr3x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21);
    
    public static function operator implicit(m: Mtr2x4d): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, 0.0, 0.0, 0.0, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr2x4d := new Mtr2x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0);
    
    public static function operator implicit(m: Mtr4x2d): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, 0.0, m.val10, m.val11, 0.0, m.val20, m.val21, 0.0, m.val30, m.val31, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr4x2d := new Mtr4x2d(m.val00, m.val01, m.val10, m.val11, m.val20, m.val21, m.val30, m.val31);
    
    public static function operator implicit(m: Mtr3x4d): Mtr4x3d := new Mtr4x3d(m.val00, m.val01, m.val02, m.val10, m.val11, m.val12, m.val20, m.val21, m.val22, 0.0, 0.0, 0.0);
    public static function operator implicit(m: Mtr4x3d): Mtr3x4d := new Mtr3x4d(m.val00, m.val01, m.val02, 0.0, m.val10, m.val11, m.val12, 0.0, m.val20, m.val21, m.val22, 0.0);
    
  end;
  
  {$endregion Mtr}
  
  {$region MtrTranspose}
  
  function Transpose(self: Mtr2x3f); extensionmethod :=
  new Mtr3x2f(self.val00, self.val10, self.val01, self.val11, self.val02, self.val12);
  function Transpose(self: Mtr3x2f); extensionmethod :=
  new Mtr2x3f(self.val00, self.val10, self.val20, self.val01, self.val11, self.val21);
  
  function Transpose(self: Mtr2x4f); extensionmethod :=
  new Mtr4x2f(self.val00, self.val10, self.val01, self.val11, self.val02, self.val12, self.val03, self.val13);
  function Transpose(self: Mtr4x2f); extensionmethod :=
  new Mtr2x4f(self.val00, self.val10, self.val20, self.val30, self.val01, self.val11, self.val21, self.val31);
  
  function Transpose(self: Mtr3x4f); extensionmethod :=
  new Mtr4x3f(self.val00, self.val10, self.val20, self.val01, self.val11, self.val21, self.val02, self.val12, self.val22, self.val03, self.val13, self.val23);
  function Transpose(self: Mtr4x3f); extensionmethod :=
  new Mtr3x4f(self.val00, self.val10, self.val20, self.val30, self.val01, self.val11, self.val21, self.val31, self.val02, self.val12, self.val22, self.val32);
  
  function Transpose(self: Mtr2x3d); extensionmethod :=
  new Mtr3x2d(self.val00, self.val10, self.val01, self.val11, self.val02, self.val12);
  function Transpose(self: Mtr3x2d); extensionmethod :=
  new Mtr2x3d(self.val00, self.val10, self.val20, self.val01, self.val11, self.val21);
  
  function Transpose(self: Mtr2x4d); extensionmethod :=
  new Mtr4x2d(self.val00, self.val10, self.val01, self.val11, self.val02, self.val12, self.val03, self.val13);
  function Transpose(self: Mtr4x2d); extensionmethod :=
  new Mtr2x4d(self.val00, self.val10, self.val20, self.val30, self.val01, self.val11, self.val21, self.val31);
  
  function Transpose(self: Mtr3x4d); extensionmethod :=
  new Mtr4x3d(self.val00, self.val10, self.val20, self.val01, self.val11, self.val21, self.val02, self.val12, self.val22, self.val03, self.val13, self.val23);
  function Transpose(self: Mtr4x3d); extensionmethod :=
  new Mtr3x4d(self.val00, self.val10, self.val20, self.val30, self.val01, self.val11, self.val21, self.val31, self.val02, self.val12, self.val22, self.val32);
  
  {$endregion MtrTranspose}
  
{$endregion Записи}

type
  gl = static class
    
    {$region Разное}
    
    public static function GetError: ErrorCode;
    external 'opengl32.dll' name 'glGetError';
    
    {$endregion Разное}
    
    {$region Get[Type]}
    
    static procedure GetIntegerv(pname: UInt32; data: pointer);
    external 'opengl32.dll' name 'glGetIntegerv';
    static procedure GetIntegerv(pname: UInt32; var data: Int32);
    external 'opengl32.dll' name 'glGetIntegerv';
    static procedure GetIntegerv(pname: QueryInfoType; var data: Int32);
    external 'opengl32.dll' name 'glGetIntegerv';
    static procedure GetIntegerv(pname: UniformComponentInfoType; var data: Int32);
    external 'opengl32.dll' name 'glGetIntegerv';
    
    static procedure GetInteger64v(pname: UInt32; data: pointer);
    external 'opengl32.dll' name 'glGetInteger64v';
    static procedure GetInteger64v(pname: UInt32; var data: Int64);
    external 'opengl32.dll' name 'glGetInteger64v';
    static procedure GetInteger64v(pname: QueryInfoType; var data: Int64);
    external 'opengl32.dll' name 'glGetInteger64v';
    
    static procedure GetIntegeri_v(target: UInt32; index: UInt32; data: pointer);
    external 'opengl32.dll' name 'glGetIntegeri_v';
    static procedure GetIntegeri_v(target: UInt32; index: UInt32; var data: Int32);
    external 'opengl32.dll' name 'glGetIntegeri_v';
    static procedure GetIntegeri_v(target: BufferBindType; index: UInt32; var data: BufferName);
    external 'opengl32.dll' name 'glGetIntegeri_v';
    
    static procedure GetInteger64i_v(target: UInt32; index: UInt32; data: pointer);
    external 'opengl32.dll' name 'glGetInteger64i_v';
    static procedure GetInteger64i_v(target: UInt32; index: UInt32; var data: Int64);
    external 'opengl32.dll' name 'glGetInteger64i_v';
    static procedure GetInteger64i_v(target: BufferBindType; index: UInt32; var data: Vec2i64);
    external 'opengl32.dll' name 'glGetInteger64i_v';
    
    {$endregion Get[Type]}
    
    {$region 4.0 - Event Model}
    
    {$region 4.1 - Sync Objects and Fences}
    
    static function FenceSync(condition: FenceCondition; flags: ReservedFlags): GLsync;
    external 'opengl32.dll' name 'glFenceSync';
    
    static procedure DeleteSync(sync: GLsync);
    external 'opengl32.dll' name 'glDeleteSync';
    
    // 4.1.1
    
    static function ClientWaitSync(sync: GLsync; flags: CommandFlushingBehaviorFlags; timeout: UInt64): ClientWaitSyncResult;
    external 'opengl32.dll' name 'glClientWaitSync';
    
    static procedure WaitSync(sync: GLsync; flags: ReservedFlags; timeout: ReservedTimeoutMode);
    external 'opengl32.dll' name 'glWaitSync';
    
    // 4.1.3
    
    static procedure GetSynciv(sync: GLsync; pname: SyncObjInfoType; bufSize: Int32; var length: Int32; values: pointer);
    external 'opengl32.dll' name 'glGetSynciv';
    static procedure GetSynciv(sync: GLsync; pname: SyncObjInfoType; bufSize: Int32; length: ^Int32; values: pointer);
    external 'opengl32.dll' name 'glGetSynciv';
    
    static function IsSync(sync: GLsync): boolean;
    external 'opengl32.dll' name 'glIsSync';
    
    {$endregion 4.1 - Sync Objects and Fences}
    
    {$region 4.2 - Query Objects and Asynchronous Queries}
    
    // 4.2.2
    
    static procedure GenQueries(n: Int32; [MarshalAs(UnmanagedType.LPArray)] ids: array of QueryName);
    external 'opengl32.dll' name 'glGenQueries';
    static procedure GenQueries(n: Int32; var ids: QueryName);
    external 'opengl32.dll' name 'glGenQueries';
    static procedure GenQueries(n: Int32; ids: pointer);
    external 'opengl32.dll' name 'glGenQueries';
    
    static procedure CreateQueries(target: QueryInfoType; n: Int32; [MarshalAs(UnmanagedType.LPArray)] ids: array of QueryName);
    external 'opengl32.dll' name 'glCreateQueries';
    static procedure CreateQueries(target: QueryInfoType; n: Int32; ids: ^QueryName);
    external 'opengl32.dll' name 'glCreateQueries';
    
    static procedure DeleteQueries(n: Int32; [MarshalAs(UnmanagedType.LPArray)] ids: array of QueryName);
    external 'opengl32.dll' name 'glDeleteQueries';
    static procedure DeleteQueries(n: Int32; ids: ^QueryName);
    external 'opengl32.dll' name 'glDeleteQueries';
    
    static procedure BeginQueryIndexed(target: QueryInfoType; index: UInt32; id: QueryName);
    external 'opengl32.dll' name 'glBeginQueryIndexed';
    static procedure BeginQuery(target: QueryInfoType; id: QueryName);
    external 'opengl32.dll' name 'glBeginQuery';
    
    static procedure EndQueryIndexed(target: QueryInfoType; index: UInt32);
    external 'opengl32.dll' name 'glEndQueryIndexed';
    static procedure EndQuery(target: QueryInfoType);
    external 'opengl32.dll' name 'glEndQuery';
    
    // 4.2.3
    
    static function IsQuery(id: QueryName): boolean;
    external 'opengl32.dll' name 'glIsQuery';
    
    static procedure GetQueryIndexediv(target: QueryInfoType; index: UInt32; pname: GetQueryInfoName; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int32);
    external 'opengl32.dll' name 'glGetQueryIndexediv';
    static procedure GetQueryIndexediv(target: QueryInfoType; index: UInt32; pname: GetQueryInfoName; var &params: Int32);
    external 'opengl32.dll' name 'glGetQueryIndexediv';
    static procedure GetQueryIndexediv(target: QueryInfoType; index: UInt32; pname: GetQueryInfoName; &params: pointer);
    external 'opengl32.dll' name 'glGetQueryIndexediv';
    
    static procedure GetQueryiv(target: QueryInfoType; pname: GetQueryInfoName; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int32);
    external 'opengl32.dll' name 'glGetQueryiv';
    static procedure GetQueryiv(target: QueryInfoType; pname: GetQueryInfoName; var &params: Int32);
    external 'opengl32.dll' name 'glGetQueryiv';
    static procedure GetQueryiv(target: QueryInfoType; pname: GetQueryInfoName; &params: pointer);
    external 'opengl32.dll' name 'glGetQueryiv';
    
    static procedure GetQueryObjectiv(id: QueryName; pname: GetQueryObjectInfoName; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int32);
    external 'opengl32.dll' name 'glGetQueryObjectiv';
    static procedure GetQueryObjectiv(id: QueryName; pname: GetQueryObjectInfoName; var &params: Int32);
    external 'opengl32.dll' name 'glGetQueryObjectiv';
    static procedure GetQueryObjectiv(id: QueryName; pname: GetQueryObjectInfoName; &params: pointer);
    external 'opengl32.dll' name 'glGetQueryObjectiv';
    
    static procedure GetQueryObjectuiv(id: QueryName; pname: GetQueryObjectInfoName; [MarshalAs(UnmanagedType.LPArray)] &params: array of UInt32);
    external 'opengl32.dll' name 'glGetQueryObjectuiv';
    static procedure GetQueryObjectuiv(id: QueryName; pname: GetQueryObjectInfoName; var &params: UInt32);
    external 'opengl32.dll' name 'glGetQueryObjectuiv';
    static procedure GetQueryObjectuiv(id: QueryName; pname: GetQueryObjectInfoName; &params: pointer);
    external 'opengl32.dll' name 'glGetQueryObjectuiv';
    
    static procedure GetQueryObjecti64v(id: QueryName; pname: GetQueryObjectInfoName; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int64);
    external 'opengl32.dll' name 'glGetQueryObjecti64v';
    static procedure GetQueryObjecti64v(id: QueryName; pname: GetQueryObjectInfoName; var &params: Int64);
    external 'opengl32.dll' name 'glGetQueryObjecti64v';
    static procedure GetQueryObjecti64v(id: QueryName; pname: GetQueryObjectInfoName; &params: pointer);
    external 'opengl32.dll' name 'glGetQueryObjecti64v';
    
    static procedure GetQueryObjectui64v(id: QueryName; pname: GetQueryObjectInfoName; [MarshalAs(UnmanagedType.LPArray)] &params: array of UInt64);
    external 'opengl32.dll' name 'glGetQueryObjectui64v';
    static procedure GetQueryObjectui64v(id: QueryName; pname: GetQueryObjectInfoName; var &params: UInt64);
    external 'opengl32.dll' name 'glGetQueryObjectui64v';
    static procedure GetQueryObjectui64v(id: QueryName; pname: GetQueryObjectInfoName; &params: pointer);
    external 'opengl32.dll' name 'glGetQueryObjectui64v';
    
    static procedure GetQueryBufferObjectiv(id: QueryName; buffer: BufferName; pname: GetQueryObjectInfoName; offset: IntPtr);
    external 'opengl32.dll' name 'glGetQueryBufferObjectiv';
    
    static procedure GetQueryBufferObjectuiv(id: QueryName; buffer: BufferName; pname: GetQueryObjectInfoName; offset: IntPtr);
    external 'opengl32.dll' name 'glGetQueryBufferObjectuiv';
    
    static procedure GetQueryBufferObjecti64v(id: QueryName; buffer: BufferName; pname: GetQueryObjectInfoName; offset: IntPtr);
    external 'opengl32.dll' name 'glGetQueryBufferObjecti64v';
    
    static procedure GetQueryBufferObjectui64v(id: QueryName; buffer: BufferName; pname: GetQueryObjectInfoName; offset: IntPtr);
    external 'opengl32.dll' name 'glGetQueryBufferObjectui64v';
    
    {$endregion 4.2 - Query Objects and Asynchronous Queries}
    
    {$region 4.3 - Time Queries}
    
    static procedure QueryCounter(id: QueryName; target: QueryInfoType);
    external 'opengl32.dll' name 'glQueryCounter';
    
    {$endregion 4.3 - Time Queries}
    
    {$endregion 4.0 - Event Model}
    
    {$region 6.0 - Buffer Objects}
    
    static procedure GenBuffers(n: Int32; [MarshalAs(UnmanagedType.LPArray)] buffers: array of BufferName);
    external 'opengl32.dll' name 'glGenBuffers';
    static procedure GenBuffers(n: Int32; var buffers: BufferName);
    external 'opengl32.dll' name 'glGenBuffers';
    static procedure GenBuffers(n: Int32; buffers: pointer);
    external 'opengl32.dll' name 'glGenBuffers';
    
    static procedure CreateBuffers(n: Int32; [MarshalAs(UnmanagedType.LPArray)] buffers: array of BufferName);
    external 'opengl32.dll' name 'glCreateBuffers';
    static procedure CreateBuffers(n: Int32; buffers: ^UInt32);
    external 'opengl32.dll' name 'glCreateBuffers';
    
    static procedure DeleteBuffers(n: Int32; [MarshalAs(UnmanagedType.LPArray)] buffers: array of BufferName);
    external 'opengl32.dll' name 'glDeleteBuffers';
    static procedure DeleteBuffers(n: Int32; buffers: ^BufferName);
    external 'opengl32.dll' name 'glDeleteBuffers';
    
    static function IsBuffer(buffer: BufferName): boolean;
    external 'opengl32.dll' name 'glIsBuffer';
    
    {$region 6.1 - Creating and Binding Buffer Objects}
    
    static procedure BindBuffer(target: BufferBindType; buffer: BufferName);
    external 'opengl32.dll' name 'glBindBuffer';
    
    // 6.1.1
    
    static procedure BindBufferRange(target: BufferBindType; index: UInt32; buffer: BufferName; offset: IntPtr; size: UIntPtr);
    external 'opengl32.dll' name 'glBindBufferRange';
    
    static procedure BindBufferBase(target: BufferBindType; index: UInt32; buffer: BufferName);
    external 'opengl32.dll' name 'glBindBufferBase';
    
    static procedure BindBuffersBase(target: BufferBindType; first: UInt32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] buffers: array of BufferName);
    external 'opengl32.dll' name 'glBindBuffersBase';
    static procedure BindBuffersBase(target: BufferBindType; first: UInt32; count: Int32; buffers: ^BufferName);
    external 'opengl32.dll' name 'glBindBuffersBase';
    
    static procedure BindBuffersRange(target: BufferBindType; first: UInt32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] buffers: array of BufferName; [MarshalAs(UnmanagedType.LPArray)] offsets: array of IntPtr; [MarshalAs(UnmanagedType.LPArray)] sizes: array of UIntPtr);
    external 'opengl32.dll' name 'glBindBuffersRange';
    static procedure BindBuffersRange(target: BufferBindType; first: UInt32; count: Int32; buffers: ^BufferName; offsets: ^IntPtr; sizes: ^UIntPtr);
    external 'opengl32.dll' name 'glBindBuffersRange';
    
    {$endregion 6.1 - Creating and Binding Buffer Objects}
    
    {$region 6.2 - Creating and Modifying Buffer Object Data Stores}
    
    // BufferMapFlags автоматически преобразовывается в BufferStorageFlags
    static procedure BufferStorage(target: BufferBindType; size: UIntPtr; data: IntPtr; flags: BufferStorageFlags);
    external 'opengl32.dll' name 'glBufferStorage';
    static procedure BufferStorage(target: BufferBindType; size: UIntPtr; data: pointer; flags: BufferStorageFlags);
    external 'opengl32.dll' name 'glBufferStorage';
    
    static procedure NamedBufferStorage(buffer: BufferName; size: UIntPtr; data: IntPtr; flags: BufferStorageFlags);
    external 'opengl32.dll' name 'glNamedBufferStorage';
    static procedure NamedBufferStorage(buffer: BufferName; size: UIntPtr; data: pointer; flags: BufferStorageFlags);
    external 'opengl32.dll' name 'glNamedBufferStorage';
    
    static procedure BufferData(target: BufferBindType; size: UIntPtr; data: IntPtr; usage: BufferDataUsage);
    external 'opengl32.dll' name 'glBufferData';
    static procedure BufferData(target: BufferBindType; size: UIntPtr; data: pointer; usage: BufferDataUsage);
    external 'opengl32.dll' name 'glBufferData';
    
    static procedure NamedBufferData(buffer: BufferName; size: UIntPtr; data: IntPtr; usage: UInt32);
    external 'opengl32.dll' name 'glNamedBufferData';
    static procedure NamedBufferData(buffer: BufferName; size: UIntPtr; data: pointer; usage: UInt32);
    external 'opengl32.dll' name 'glNamedBufferData';
    
    static procedure BufferSubData(target: BufferBindType; offset: IntPtr; size: UIntPtr; data: IntPtr);
    external 'opengl32.dll' name 'glBufferSubData';
    static procedure BufferSubData(target: BufferBindType; offset: IntPtr; size: UIntPtr; data: pointer);
    external 'opengl32.dll' name 'glBufferSubData';
    
    static procedure NamedBufferSubData(buffer: BufferName; offset: IntPtr; size: UIntPtr; data: IntPtr);
    external 'opengl32.dll' name 'glNamedBufferSubData';
    static procedure NamedBufferSubData(buffer: BufferName; offset: IntPtr; size: UIntPtr; data: pointer);
    external 'opengl32.dll' name 'glNamedBufferSubData';
    
    static procedure ClearBufferSubData(target: BufferBindType; internalformat: InternalDataFormat; offset: IntPtr; size: UIntPtr; format: DataFormat; &type: DataType; data: IntPtr);
    external 'opengl32.dll' name 'glClearBufferSubData';
    static procedure ClearBufferSubData(target: BufferBindType; internalformat: InternalDataFormat; offset: IntPtr; size: UIntPtr; format: DataFormat; &type: DataType; data: pointer);
    external 'opengl32.dll' name 'glClearBufferSubData';
    
    static procedure ClearNamedBufferSubData(buffer: BufferName; internalformat: InternalDataFormat; offset: IntPtr; size: UIntPtr; format: DataFormat; &type: DataType; data: IntPtr);
    external 'opengl32.dll' name 'glClearNamedBufferSubData';
    static procedure ClearNamedBufferSubData(buffer: BufferName; internalformat: InternalDataFormat; offset: IntPtr; size: UIntPtr; format: DataFormat; &type: DataType; data: pointer);
    external 'opengl32.dll' name 'glClearNamedBufferSubData';
    
    static procedure ClearBufferData(target: BufferBindType; internalformat: InternalDataFormat; format: DataFormat; &type: DataType; data: IntPtr);
    external 'opengl32.dll' name 'glClearBufferData';
    static procedure ClearBufferData(target: BufferBindType; internalformat: InternalDataFormat; format: DataFormat; &type: DataType; data: pointer);
    external 'opengl32.dll' name 'glClearBufferData';
    
    static procedure ClearNamedBufferData(buffer: BufferName; internalformat: InternalDataFormat; format: DataFormat; &type: DataType; data: IntPtr);
    external 'opengl32.dll' name 'glClearNamedBufferData';
    static procedure ClearNamedBufferData(buffer: BufferName; internalformat: InternalDataFormat; format: DataFormat; &type: DataType; data: pointer);
    external 'opengl32.dll' name 'glClearNamedBufferData';
    
    {$endregion 6.2 - Creating and Modifying Buffer Object Data Stores}
    
    {$region 6.3 - Mapping and Unmapping Buffer Data}
    
    static function MapBufferRange(target: BufferBindType; offset: IntPtr; length: UIntPtr; access: BufferMapFlags): IntPtr;
    external 'opengl32.dll' name 'glMapBufferRange';
    static function MapNamedBufferRange(buffer: BufferName; offset: IntPtr; length: UIntPtr; access: BufferMapFlags): IntPtr;
    external 'opengl32.dll' name 'glMapNamedBufferRange';
    
    static function MapBuffer(target: BufferBindType; access: BufferMapFlags): IntPtr;
    external 'opengl32.dll' name 'glMapBuffer';
    static function MapNamedBuffer(buffer: BufferName; access: BufferMapFlags): IntPtr;
    external 'opengl32.dll' name 'glMapNamedBuffer';
    
    static procedure FlushMappedBufferRange(target: BufferBindType; offset: IntPtr; length: UIntPtr);
    external 'opengl32.dll' name 'glFlushMappedBufferRange';
    static procedure FlushMappedNamedBufferRange(buffer: BufferName; offset: IntPtr; length: UIntPtr);
    external 'opengl32.dll' name 'glFlushMappedNamedBufferRange';
    
    // 6.3.1
    
    static function UnmapBuffer(target: BufferBindType): boolean;
    external 'opengl32.dll' name 'glUnmapBuffer';
    static function UnmapNamedBuffer(buffer: BufferName): boolean;
    external 'opengl32.dll' name 'glUnmapNamedBuffer';
    
    {$endregion 6.3 - Mapping and Unmapping Buffer Data}
    
    {$region 6.5 - Invalidating Buffer Data}
    
    static procedure InvalidateBufferSubData(buffer: BufferName; offset: IntPtr; length: UIntPtr);
    external 'opengl32.dll' name 'glInvalidateBufferSubData';
    
    static procedure InvalidateBufferData(buffer: BufferName);
    external 'opengl32.dll' name 'glInvalidateBufferData';
    
    {$endregion 6.5 - Invalidating Buffer Data}
    
    {$region 6.6 - Copying Between Buffers}
    
    static procedure CopyBufferSubData(readTarget, writeTarget: BufferBindType; readOffset, writeOffset: IntPtr; size: UIntPtr);
    external 'opengl32.dll' name 'glCopyBufferSubData';
    static procedure CopyNamedBufferSubData(readBuffer, writeBuffer: BufferName; readOffset, writeOffset: IntPtr; size: UIntPtr);
    external 'opengl32.dll' name 'glCopyNamedBufferSubData';
    
    {$endregion 6.6 - Copying Between Buffers}
    
    {$region 6.7 - Buffer Object Queries}
    
    static procedure GetBufferParameteriv(target: BufferBindType; pname: BufferInfoType; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int32);
    external 'opengl32.dll' name 'glGetBufferParameteriv';
    static procedure GetBufferParameteriv(target: BufferBindType; pname: BufferInfoType; var &params: Int32);
    external 'opengl32.dll' name 'glGetBufferParameteriv';
    static procedure GetBufferParameteriv(target: BufferBindType; pname: BufferInfoType; &params: pointer);
    external 'opengl32.dll' name 'glGetBufferParameteriv';
    
    static procedure GetBufferParameteri64v(target: BufferBindType; pname: BufferInfoType; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int64);
    external 'opengl32.dll' name 'glGetBufferParameteri64v';
    static procedure GetBufferParameteri64v(target: BufferBindType; pname: BufferInfoType; var &params: Int64);
    external 'opengl32.dll' name 'glGetBufferParameteri64v';
    static procedure GetBufferParameteri64v(target: BufferBindType; pname: BufferInfoType; &params: pointer);
    external 'opengl32.dll' name 'glGetBufferParameteri64v';
    
    static procedure GetNamedBufferParameteriv(target: BufferName; pname: BufferInfoType; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int32);
    external 'opengl32.dll' name 'glGetNamedBufferParameteriv';
    static procedure GetNamedBufferParameteriv(target: BufferName; pname: BufferInfoType; var &params: Int32);
    external 'opengl32.dll' name 'glGetNamedBufferParameteriv';
    static procedure GetNamedBufferParameteriv(target: BufferName; pname: BufferInfoType; &params: pointer);
    external 'opengl32.dll' name 'glGetNamedBufferParameteriv';
    
    static procedure GetNamedBufferParameteri64v(target: BufferName; pname: BufferInfoType; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int64);
    external 'opengl32.dll' name 'glGetNamedBufferParameteri64v';
    static procedure GetNamedBufferParameteri64v(target: BufferName; pname: BufferInfoType; var &params: Int64);
    external 'opengl32.dll' name 'glGetNamedBufferParameteri64v';
    static procedure GetNamedBufferParameteri64v(target: BufferName; pname: BufferInfoType; &params: pointer);
    external 'opengl32.dll' name 'glGetNamedBufferParameteri64v';
    
    static procedure GetBufferSubData(target: BufferBindType; offset: IntPtr; size: UIntPtr; data: IntPtr);
    external 'opengl32.dll' name 'glGetBufferSubData';
    static procedure GetBufferSubData(target: BufferBindType; offset: IntPtr; size: UIntPtr; data: pointer);
    external 'opengl32.dll' name 'glGetBufferSubData';
    
    static procedure GetNamedBufferSubData(buffer: BufferName; offset: IntPtr; size: UIntPtr; data: IntPtr);
    external 'opengl32.dll' name 'glGetNamedBufferSubData';
    static procedure GetNamedBufferSubData(buffer: BufferName; offset: IntPtr; size: UIntPtr; data: pointer);
    external 'opengl32.dll' name 'glGetNamedBufferSubData';
    
    static procedure GetBufferPointerv(target: BufferBindType; pname: BufferInfoType; var &params: IntPtr);
    external 'opengl32.dll' name 'glGetBufferPointerv';
    static procedure GetBufferPointerv(target: BufferBindType; pname: BufferInfoType; &params: ^IntPtr);
    external 'opengl32.dll' name 'glGetBufferPointerv';
    static procedure GetBufferPointerv(target: BufferBindType; pname: BufferInfoType; var &params: pointer);
    external 'opengl32.dll' name 'glGetBufferPointerv';
    static procedure GetBufferPointerv(target: BufferBindType; pname: BufferInfoType; &params: ^pointer);
    external 'opengl32.dll' name 'glGetBufferPointerv';
    
    static procedure GetNamedBufferPointerv(buffer: BufferName; pname: BufferInfoType; var &params: IntPtr);
    external 'opengl32.dll' name 'glGetNamedBufferPointerv';
    static procedure GetNamedBufferPointerv(buffer: BufferName; pname: BufferInfoType; &params: ^IntPtr);
    external 'opengl32.dll' name 'glGetNamedBufferPointerv';
    static procedure GetNamedBufferPointerv(buffer: BufferName; pname: BufferInfoType; var &params: pointer);
    external 'opengl32.dll' name 'glGetNamedBufferPointerv';
    static procedure GetNamedBufferPointerv(buffer: BufferName; pname: BufferInfoType; &params: ^pointer);
    external 'opengl32.dll' name 'glGetNamedBufferPointerv';
    
    {$endregion 6.7 - Buffer Object Queries}
    
    {$endregion 6.0 - Buffer Objects}
    
    {$region }
    
    {$endregion }
    
    {$region 7.0 - Programs and Shaders}
    
    {$region 7.1 - Shader Objects}
    
    static function CreateShader(&type: ShaderType): ShaderName;
    external 'opengl32.dll' name 'glCreateShader';
    
    static procedure ShaderSource(shader: ShaderName; count: Int32; [MarshalAs(UnmanagedType.LPArray, ArraySubType = UnmanagedType.LPStr)] strings: array of string; [MarshalAs(UnmanagedType.LPArray)] lengths: array of Int32);
    external 'opengl32.dll' name 'glShaderSource';
    static procedure ShaderSource(shader: ShaderName; count: Int32; strings: ^IntPtr; lengths: ^Int32);
    external 'opengl32.dll' name 'glShaderSource';
    
    static procedure CompileShader(shader: ShaderName);
    external 'opengl32.dll' name 'glCompileShader';
    
    static procedure ReleaseShaderCompiler;
    external 'opengl32.dll' name 'glReleaseShaderCompiler';
    
    static procedure DeleteShader(shader: ShaderName);
    external 'opengl32.dll' name 'glDeleteShader';
    
    static function IsShader(shader: ShaderName): boolean;
    external 'opengl32.dll' name 'glIsShader';
    
    {$endregion 7.1 - Shader Objects}
    
    {$region 7.2 - Shader Binaries}
    
    // для получения binaryformat
    // надо вызвать gl.Get... с параметрами:
    // glGetQueries.NUM_SHADER_BINARY_FORMATS
    // glGetQueries.SHADER_BINARY_FORMATS
    static procedure ShaderBinary(count: Int32; [MarshalAs(UnmanagedType.LPArray)] shaders: array of ShaderName; binaryformat: ShaderBinaryFormat; [MarshalAs(UnmanagedType.LPArray)] binary: array of byte; length: Int32);
    external 'opengl32.dll' name 'glShaderBinary';
    static procedure ShaderBinary(count: Int32; [MarshalAs(UnmanagedType.LPArray)] shaders: array of ShaderName; binaryformat: ShaderBinaryFormat; binary: IntPtr; length: Int32);
    external 'opengl32.dll' name 'glShaderBinary';
    static procedure ShaderBinary(count: Int32; shaders: ^ShaderName; binaryformat: ShaderBinaryFormat; [MarshalAs(UnmanagedType.LPArray)] binary: array of byte; length: Int32);
    external 'opengl32.dll' name 'glShaderBinary';
    static procedure ShaderBinary(count: Int32; shaders: ^ShaderName; binaryformat: ShaderBinaryFormat; binary: IntPtr; length: Int32);
    external 'opengl32.dll' name 'glShaderBinary';
    
    // 7.2.1
    
    static procedure SpecializeShader(shader: ShaderName; [MarshalAs(UnmanagedType.LPStr)] pEntryPoint: string; numSpecializationConstants: UInt32; [MarshalAs(UnmanagedType.LPArray)] pConstantIndex: array of UInt32; [MarshalAs(UnmanagedType.LPArray)] pConstantValue: array of SPIR_V_ConstantValue);
    external 'opengl32.dll' name 'glSpecializeShader';
    static procedure SpecializeShader(shader: ShaderName; [MarshalAs(UnmanagedType.LPStr)] pEntryPoint: string; numSpecializationConstants: UInt32; pConstantIndex: ^UInt32; pConstantValue: ^SPIR_V_ConstantValue);
    external 'opengl32.dll' name 'glSpecializeShader';
    static procedure SpecializeShader(shader: ShaderName; pEntryPoint: IntPtr; numSpecializationConstants: UInt32; [MarshalAs(UnmanagedType.LPArray)] pConstantIndex: array of UInt32; [MarshalAs(UnmanagedType.LPArray)] pConstantValue: array of SPIR_V_ConstantValue);
    external 'opengl32.dll' name 'glSpecializeShader';
    static procedure SpecializeShader(shader: ShaderName; pEntryPoint: IntPtr; numSpecializationConstants: UInt32; pConstantIndex: ^UInt32; pConstantValue: ^SPIR_V_ConstantValue);
    external 'opengl32.dll' name 'glSpecializeShader';
    
    {$endregion 7.2 - Shader Binaries}
    
    {$region 7.3 - Program Objects}
    
    static function CreateProgram: ProgramName;
    external 'opengl32.dll' name 'glCreateProgram';
    
    static procedure AttachShader(&program: ProgramName; shader: ShaderName);
    external 'opengl32.dll' name 'glAttachShader';
    
    static procedure DetachShader(&program: ProgramName; shader: ShaderName);
    external 'opengl32.dll' name 'glDetachShader';
    
    static procedure LinkProgram(&program: ProgramName);
    external 'opengl32.dll' name 'glLinkProgram';
    
    static procedure UseProgram(&program: ProgramName);
    external 'opengl32.dll' name 'glUseProgram';
    
    static procedure ProgramParameteri(&program: ProgramName; pname: ProgramParameterType; value: Int32);
    external 'opengl32.dll' name 'glProgramParameteri';
    
    static procedure DeleteProgram(&program: ProgramName);
    external 'opengl32.dll' name 'glDeleteProgram';
    
    static function IsProgram(&program: ProgramName): boolean;
    external 'opengl32.dll' name 'glIsProgram';
    
    static function CreateShaderProgramv(&type: ShaderType; count: Int32; [MarshalAs(UnmanagedType.LPArray, ArraySubType = UnmanagedType.LPStr)] strings: array of string): ProgramName;
    external 'opengl32.dll' name 'glCreateShaderProgramv';
    static function CreateShaderProgramv(&type: ShaderType; count: Int32; strings: ^IntPtr): ProgramName;
    external 'opengl32.dll' name 'glCreateShaderProgramv';
    
    // 7.3.1
    
    // 7.3.1.1
    
    static procedure GetProgramInterfaceiv(&program: ProgramName; programInterface: ProgramInterfaceType; pname: ProgramInterfaceInfoType; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int32);
    external 'opengl32.dll' name 'glGetProgramInterfaceiv';
    static procedure GetProgramInterfaceiv(&program: ProgramName; programInterface: ProgramInterfaceType; pname: ProgramInterfaceInfoType; var &params: Int32);
    external 'opengl32.dll' name 'glGetProgramInterfaceiv';
    static procedure GetProgramInterfaceiv(&program: ProgramName; programInterface: ProgramInterfaceType; pname: ProgramInterfaceInfoType; &params: pointer);
    external 'opengl32.dll' name 'glGetProgramInterfaceiv';
    
    static function GetProgramResourceIndex(&program: ProgramName; programInterface: ProgramInterfaceType; [MarshalAs(UnmanagedType.LPStr)] name: string): ProgramResourceIndex;
    external 'opengl32.dll' name 'glGetProgramResourceIndex';
    static function GetProgramResourceIndex(&program: ProgramName; programInterface: ProgramInterfaceType; name: IntPtr): ProgramResourceIndex;
    external 'opengl32.dll' name 'glGetProgramResourceIndex';
    
    static procedure GetProgramResourceName(&program: ProgramName; programInterface: ProgramInterfaceType; index: ProgramResourceIndex; bufSize: Int32; var length: Int32; [MarshalAs(UnmanagedType.LPStr)] name: string);
    external 'opengl32.dll' name 'glGetProgramResourceName';
    static procedure GetProgramResourceName(&program: ProgramName; programInterface: ProgramInterfaceType; index: ProgramResourceIndex; bufSize: Int32; var length: Int32; name: IntPtr);
    external 'opengl32.dll' name 'glGetProgramResourceName';
    static procedure GetProgramResourceName(&program: ProgramName; programInterface: ProgramInterfaceType; index: ProgramResourceIndex; bufSize: Int32; length: ^Int32; [MarshalAs(UnmanagedType.LPStr)] name: string);
    external 'opengl32.dll' name 'glGetProgramResourceName';
    static procedure GetProgramResourceName(&program: ProgramName; programInterface: ProgramInterfaceType; index: ProgramResourceIndex; bufSize: Int32; length: ^Int32; name: IntPtr);
    external 'opengl32.dll' name 'glGetProgramResourceName';
    
    // если ProgramInterfaceProperty.Type - вывод через ShadingLanguageTypeToken
    static procedure GetProgramResourceiv(&program: ProgramName; programInterface: ProgramInterfaceType; index: ProgramResourceIndex; propCount: Int32; [MarshalAs(UnmanagedType.LPArray)] props: array of ProgramInterfaceProperty; bufSize: Int32; var length: Int32; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int32);
    external 'opengl32.dll' name 'glGetProgramResourceiv';
    static procedure GetProgramResourceiv(&program: ProgramName; programInterface: ProgramInterfaceType; index: ProgramResourceIndex; propCount: Int32; props: ^ProgramInterfaceProperty; bufSize: Int32; length: ^Int32; var &params: Int32);
    external 'opengl32.dll' name 'glGetProgramResourceiv';
    static procedure GetProgramResourceiv(&program: ProgramName; programInterface: ProgramInterfaceType; index: ProgramResourceIndex; propCount: Int32; props: ^ProgramInterfaceProperty; bufSize: Int32; length: ^Int32; &params: pointer);
    external 'opengl32.dll' name 'glGetProgramResourceiv';
    
    static function GetProgramResourceLocation(&program: ProgramName; programInterface: ProgramInterfaceType; [MarshalAs(UnmanagedType.LPStr)] name: string): Int32;
    external 'opengl32.dll' name 'glGetProgramResourceLocation';
    static function GetProgramResourceLocation(&program: ProgramName; programInterface: ProgramInterfaceType; name: IntPtr): Int32;
    external 'opengl32.dll' name 'glGetProgramResourceLocation';
    
    static function GetProgramResourceLocationIndex(&program: ProgramName; programInterface: ProgramInterfaceType; [MarshalAs(UnmanagedType.LPStr)] name: string): Int32;
    external 'opengl32.dll' name 'glGetProgramResourceLocationIndex';
    static function GetProgramResourceLocationIndex(&program: ProgramName; programInterface: ProgramInterfaceType; name: IntPtr): Int32;
    external 'opengl32.dll' name 'glGetProgramResourceLocationIndex';
    
    {$endregion 7.3 - Program Objects}
    
    {$region 7.4 - Program Pipeline Objects}
    
    static procedure GenProgramPipelines(n: Int32; [MarshalAs(UnmanagedType.LPArray)] pipelines: array of ProgramPipelineName);
    external 'opengl32.dll' name 'glGenProgramPipelines';
    static procedure GenProgramPipelines(n: Int32; var pipelines: ProgramPipelineName);
    external 'opengl32.dll' name 'glGenProgramPipelines';
    static procedure GenProgramPipelines(n: Int32; pipelines: pointer);
    external 'opengl32.dll' name 'glGenProgramPipelines';
    
    static procedure DeleteProgramPipelines(n: Int32; [MarshalAs(UnmanagedType.LPArray)] pipelines: array of ProgramPipelineName);
    external 'opengl32.dll' name 'glDeleteProgramPipelines';
    static procedure DeleteProgramPipelines(n: Int32; var pipelines: ProgramPipelineName);
    external 'opengl32.dll' name 'glDeleteProgramPipelines';
    static procedure DeleteProgramPipelines(n: Int32; pipelines: pointer);
    external 'opengl32.dll' name 'glDeleteProgramPipelines';
    
    static function IsProgramPipeline(pipeline: ProgramPipelineName): boolean;
    external 'opengl32.dll' name 'glIsProgramPipeline';
    
    static procedure BindProgramPipeline(pipeline: ProgramPipelineName);
    external 'opengl32.dll' name 'glBindProgramPipeline';
    
    static procedure CreateProgramPipelines(n: Int32; [MarshalAs(UnmanagedType.LPArray)] pipelines: array of ProgramPipelineName);
    external 'opengl32.dll' name 'glCreateProgramPipelines';
    static procedure CreateProgramPipelines(n: Int32; var pipelines: ProgramPipelineName);
    external 'opengl32.dll' name 'glCreateProgramPipelines';
    static procedure CreateProgramPipelines(n: Int32; pipelines: pointer);
    external 'opengl32.dll' name 'glCreateProgramPipelines';
    
    static procedure UseProgramStages(pipeline: ProgramPipelineName; stages: ProgramStagesFlags; &program: ProgramName);
    external 'opengl32.dll' name 'glUseProgramStages';
    
    static procedure ActiveShaderProgram(pipeline: ProgramPipelineName; &program: ProgramName);
    external 'opengl32.dll' name 'glActiveShaderProgram';
    
    {$endregion 7.4 - Program Pipeline Objects}
    
    {$region 7.5 - Program Binaries}
    
    static procedure GetProgramBinary(&program: ProgramName; bufSize: Int32; var length: Int32; var binaryFormat: ProgramBinaryFormat; [MarshalAs(UnmanagedType.LPArray)] binary: array of byte);
    external 'opengl32.dll' name 'glGetProgramBinary';
    static procedure GetProgramBinary(&program: ProgramName; bufSize: Int32; var length: Int32; var binaryFormat: ProgramBinaryFormat; binary: IntPtr);
    external 'opengl32.dll' name 'glGetProgramBinary';
    static procedure GetProgramBinary(&program: ProgramName; bufSize: Int32; length: ^Int32; binaryFormat: ^ProgramBinaryFormat; [MarshalAs(UnmanagedType.LPArray)] binary: array of byte);
    external 'opengl32.dll' name 'glGetProgramBinary';
    static procedure GetProgramBinary(&program: ProgramName; bufSize: Int32; length: ^Int32; binaryFormat: ^ProgramBinaryFormat; binary: IntPtr);
    external 'opengl32.dll' name 'glGetProgramBinary';
    
    static procedure ProgramBinary(&program: ProgramName; binaryFormat: ProgramBinaryFormat; [MarshalAs(UnmanagedType.LPArray)] binary: array of byte; length: Int32);
    external 'opengl32.dll' name 'glProgramBinary';
    static procedure ProgramBinary(&program: ProgramName; binaryFormat: ProgramBinaryFormat; binary: IntPtr; length: Int32);
    external 'opengl32.dll' name 'glProgramBinary';
    
    {$endregion 7.5 - Program Binaries}
    
    {$region 7.6 - Uniform Variables}
    
    static function GetUniformLocation(&program: ProgramName; [MarshalAs(UnmanagedType.LPStr)] name: string): Int32;
    external 'opengl32.dll' name 'glGetUniformLocation';
    static function GetUniformLocation(&program: ProgramName; name: IntPtr): Int32;
    external 'opengl32.dll' name 'glGetUniformLocation';
    
    static procedure GetActiveUniformName(&program: ProgramName; uniformIndex: UInt32; bufSize: Int32; var length: Int32; [MarshalAs(UnmanagedType.LPStr)] uniformName: string);
    external 'opengl32.dll' name 'glGetActiveUniformName';
    static procedure GetActiveUniformName(&program: ProgramName; uniformIndex: UInt32; bufSize: Int32; var length: Int32; uniformName: IntPtr);
    external 'opengl32.dll' name 'glGetActiveUniformName';
    static procedure GetActiveUniformName(&program: ProgramName; uniformIndex: UInt32; bufSize: Int32; length: ^Int32; [MarshalAs(UnmanagedType.LPStr)] uniformName: string);
    external 'opengl32.dll' name 'glGetActiveUniformName';
    static procedure GetActiveUniformName(&program: ProgramName; uniformIndex: UInt32; bufSize: Int32; length: ^Int32; uniformName: IntPtr);
    external 'opengl32.dll' name 'glGetActiveUniformName';
    
    static procedure GetUniformIndices(&program: ProgramName; uniformCount: Int32; [MarshalAs(UnmanagedType.LPArray, ArraySubType = UnmanagedType.LPStr)] uniformNames: array of string; [MarshalAs(UnmanagedType.LPArray)] uniformIndices: array of UInt32);
    external 'opengl32.dll' name 'glGetUniformIndices';
    static procedure GetUniformIndices(&program: ProgramName; uniformCount: Int32; [MarshalAs(UnmanagedType.LPArray, ArraySubType = UnmanagedType.LPStr)] uniformNames: array of string; uniformIndices: ^UInt32);
    external 'opengl32.dll' name 'glGetUniformIndices';
    static procedure GetUniformIndices(&program: ProgramName; uniformCount: Int32; uniformNames: ^IntPtr; [MarshalAs(UnmanagedType.LPArray)] uniformIndices: array of UInt32);
    external 'opengl32.dll' name 'glGetUniformIndices';
    static procedure GetUniformIndices(&program: ProgramName; uniformCount: Int32; uniformNames: ^IntPtr; uniformIndices: ^UInt32);
    external 'opengl32.dll' name 'glGetUniformIndices';
    
    static procedure GetActiveUniform(&program: ProgramName; index: UInt32; bufSize: Int32; var length: Int32; var size: Int32; &type: ^ShadingLanguageTypeToken; [MarshalAs(UnmanagedType.LPStr)] name: string);
    external 'opengl32.dll' name 'glGetActiveUniform';
    static procedure GetActiveUniform(&program: ProgramName; index: UInt32; bufSize: Int32; var length: Int32; var size: Int32; &type: ^ShadingLanguageTypeToken; name: IntPtr);
    external 'opengl32.dll' name 'glGetActiveUniform';
    static procedure GetActiveUniform(&program: ProgramName; index: UInt32; bufSize: Int32; length: ^Int32; size: ^Int32; &type: ^ShadingLanguageTypeToken; [MarshalAs(UnmanagedType.LPStr)] name: string);
    external 'opengl32.dll' name 'glGetActiveUniform';
    static procedure GetActiveUniform(&program: ProgramName; index: UInt32; bufSize: Int32; length: ^Int32; size: ^Int32; &type: ^ShadingLanguageTypeToken; name: IntPtr);
    external 'opengl32.dll' name 'glGetActiveUniform';
    
    static procedure GetActiveUniformsiv(&program: ProgramName; uniformCount: Int32; [MarshalAs(UnmanagedType.LPArray)] uniformIndices: array of UInt32; pname: ProgramInterfaceProperty; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int32);
    external 'opengl32.dll' name 'glGetActiveUniformsiv';
    static procedure GetActiveUniformsiv(&program: ProgramName; uniformCount: Int32; uniformIndices: ^UInt32; pname: ProgramInterfaceProperty; &params: ^Int32);
    external 'opengl32.dll' name 'glGetActiveUniformsiv';
    
    static function GetUniformBlockIndex(&program: ProgramName; [MarshalAs(UnmanagedType.LPStr)] uniformBlockName: string): UInt32;
    external 'opengl32.dll' name 'glGetUniformBlockIndex';
    static function GetUniformBlockIndex(&program: ProgramName; uniformBlockName: IntPtr): UInt32;
    external 'opengl32.dll' name 'glGetUniformBlockIndex';
    
    static procedure GetActiveUniformBlockName(&program: ProgramName; uniformBlockIndex: UInt32; bufSize: Int32; var length: Int32; [MarshalAs(UnmanagedType.LPStr)] uniformBlockName: string);
    external 'opengl32.dll' name 'glGetActiveUniformBlockName';
    static procedure GetActiveUniformBlockName(&program: ProgramName; uniformBlockIndex: UInt32; bufSize: Int32; length: ^Int32; uniformBlockName: IntPtr);
    external 'opengl32.dll' name 'glGetActiveUniformBlockName';
    
    static procedure GetActiveUniformBlockiv(&program: ProgramName; uniformBlockIndex: UInt32; pname: ProgramInterfaceProperty; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int32);
    external 'opengl32.dll' name 'glGetActiveUniformBlockiv';
    static procedure GetActiveUniformBlockiv(&program: ProgramName; uniformBlockIndex: UInt32; pname: ProgramInterfaceProperty; var &params: Int32);
    external 'opengl32.dll' name 'glGetActiveUniformBlockiv';
    static procedure GetActiveUniformBlockiv(&program: ProgramName; uniformBlockIndex: UInt32; pname: ProgramInterfaceProperty; &params: ^Int32);
    external 'opengl32.dll' name 'glGetActiveUniformBlockiv';
    
    static procedure GetActiveAtomicCounterBufferiv(&program: ProgramName; bufferIndex: UInt32; pname: ProgramInterfaceProperty; [MarshalAs(UnmanagedType.LPArray)] &params: array of Int32);
    external 'opengl32.dll' name 'glGetActiveAtomicCounterBufferiv';
    static procedure GetActiveAtomicCounterBufferiv(&program: ProgramName; bufferIndex: UInt32; pname: ProgramInterfaceProperty; var &params: Int32);
    external 'opengl32.dll' name 'glGetActiveAtomicCounterBufferiv';
    static procedure GetActiveAtomicCounterBufferiv(&program: ProgramName; bufferIndex: UInt32; pname: ProgramInterfaceProperty; &params: ^Int32);
    external 'opengl32.dll' name 'glGetActiveAtomicCounterBufferiv';
    
    // 7.6.1
    
    {$region Uniform[1,2,3,4][i,f,d,ui]}
    
    static procedure Uniform1i(location: Int32; v0: Int32);
    external 'opengl32.dll' name 'glUniform1i';
    
    static procedure Uniform2i(location: Int32; v0: Int32; v1: Int32);
    external 'opengl32.dll' name 'glUniform2i';
    
    static procedure Uniform3i(location: Int32; v0: Int32; v1: Int32; v2: Int32);
    external 'opengl32.dll' name 'glUniform3i';
    
    static procedure Uniform4i(location: Int32; v0: Int32; v1: Int32; v2: Int32; v3: Int32);
    external 'opengl32.dll' name 'glUniform4i';
    
    static procedure Uniform1f(location: Int32; v0: single);
    external 'opengl32.dll' name 'glUniform1f';
    
    static procedure Uniform2f(location: Int32; v0: single; v1: single);
    external 'opengl32.dll' name 'glUniform2f';
    
    static procedure Uniform3f(location: Int32; v0: single; v1: single; v2: single);
    external 'opengl32.dll' name 'glUniform3f';
    
    static procedure Uniform4f(location: Int32; v0: single; v1: single; v2: single; v3: single);
    external 'opengl32.dll' name 'glUniform4f';
    
    static procedure Uniform1d(location: Int32; x: real);
    external 'opengl32.dll' name 'glUniform1d';
    
    static procedure Uniform2d(location: Int32; x: real; y: real);
    external 'opengl32.dll' name 'glUniform2d';
    
    static procedure Uniform3d(location: Int32; x: real; y: real; z: real);
    external 'opengl32.dll' name 'glUniform3d';
    
    static procedure Uniform4d(location: Int32; x: real; y: real; z: real; w: real);
    external 'opengl32.dll' name 'glUniform4d';
    
    static procedure Uniform1ui(location: Int32; v0: UInt32);
    external 'opengl32.dll' name 'glUniform1ui';
    
    static procedure Uniform2ui(location: Int32; v0: UInt32; v1: UInt32);
    external 'opengl32.dll' name 'glUniform2ui';
    
    static procedure Uniform3ui(location: Int32; v0: UInt32; v1: UInt32; v2: UInt32);
    external 'opengl32.dll' name 'glUniform3ui';
    
    static procedure Uniform4ui(location: Int32; v0: UInt32; v1: UInt32; v2: UInt32; v3: UInt32);
    external 'opengl32.dll' name 'glUniform4ui';
    
    {$endregion Uniform[1,2,3,4][i,f,d,ui]}
    
    {$region Uniform[1,2,3,4][i,f,d,ui]v}
    
    static procedure Uniform1iv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of Int32);
    external 'opengl32.dll' name 'glUniform1iv';
    static procedure Uniform1iv(location: Int32; count: Int32; var value: Int32);
    external 'opengl32.dll' name 'glUniform1iv';
    static procedure Uniform1iv(location: Int32; count: Int32; var value: Vec1i);
    external 'opengl32.dll' name 'glUniform1iv';
    static procedure Uniform1iv(location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glUniform1iv';
    
    static procedure Uniform2iv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of Int32);
    external 'opengl32.dll' name 'glUniform2iv';
    static procedure Uniform2iv(location: Int32; count: Int32; var value: Int32);
    external 'opengl32.dll' name 'glUniform2iv';
    static procedure Uniform2iv(location: Int32; count: Int32; var value: Vec2i);
    external 'opengl32.dll' name 'glUniform2iv';
    static procedure Uniform2iv(location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glUniform2iv';
    
    static procedure Uniform3iv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of Int32);
    external 'opengl32.dll' name 'glUniform3iv';
    static procedure Uniform3iv(location: Int32; count: Int32; var value: Int32);
    external 'opengl32.dll' name 'glUniform3iv';
    static procedure Uniform3iv(location: Int32; count: Int32; var value: Vec3i);
    external 'opengl32.dll' name 'glUniform3iv';
    static procedure Uniform3iv(location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glUniform3iv';
    
    static procedure Uniform4iv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of Int32);
    external 'opengl32.dll' name 'glUniform4iv';
    static procedure Uniform4iv(location: Int32; count: Int32; var value: Int32);
    external 'opengl32.dll' name 'glUniform4iv';
    static procedure Uniform4iv(location: Int32; count: Int32; var value: Vec4i);
    external 'opengl32.dll' name 'glUniform4iv';
    static procedure Uniform4iv(location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glUniform4iv';
    
    static procedure Uniform1fv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniform1fv';
    static procedure Uniform1fv(location: Int32; count: Int32; var value: single);
    external 'opengl32.dll' name 'glUniform1fv';
    static procedure Uniform1fv(location: Int32; count: Int32; var value: Vec1f);
    external 'opengl32.dll' name 'glUniform1fv';
    static procedure Uniform1fv(location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glUniform1fv';
    
    static procedure Uniform2fv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniform2fv';
    static procedure Uniform2fv(location: Int32; count: Int32; var value: single);
    external 'opengl32.dll' name 'glUniform2fv';
    static procedure Uniform2fv(location: Int32; count: Int32; var value: Vec2f);
    external 'opengl32.dll' name 'glUniform2fv';
    static procedure Uniform2fv(location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glUniform2fv';
    
    static procedure Uniform3fv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniform3fv';
    static procedure Uniform3fv(location: Int32; count: Int32; var value: single);
    external 'opengl32.dll' name 'glUniform3fv';
    static procedure Uniform3fv(location: Int32; count: Int32; var value: Vec3f);
    external 'opengl32.dll' name 'glUniform3fv';
    static procedure Uniform3fv(location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glUniform3fv';
    
    static procedure Uniform4fv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniform4fv';
    static procedure Uniform4fv(location: Int32; count: Int32; var value: single);
    external 'opengl32.dll' name 'glUniform4fv';
    static procedure Uniform4fv(location: Int32; count: Int32; var value: Vec4f);
    external 'opengl32.dll' name 'glUniform4fv';
    static procedure Uniform4fv(location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glUniform4fv';
    
    static procedure Uniform1dv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniform1dv';
    static procedure Uniform1dv(location: Int32; count: Int32; var value: real);
    external 'opengl32.dll' name 'glUniform1dv';
    static procedure Uniform1dv(location: Int32; count: Int32; var value: Vec1d);
    external 'opengl32.dll' name 'glUniform1dv';
    static procedure Uniform1dv(location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glUniform1dv';
    
    static procedure Uniform2dv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniform2dv';
    static procedure Uniform2dv(location: Int32; count: Int32; var value: real);
    external 'opengl32.dll' name 'glUniform2dv';
    static procedure Uniform2dv(location: Int32; count: Int32; var value: Vec2d);
    external 'opengl32.dll' name 'glUniform2dv';
    static procedure Uniform2dv(location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glUniform2dv';
    
    static procedure Uniform3dv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniform3dv';
    static procedure Uniform3dv(location: Int32; count: Int32; var value: real);
    external 'opengl32.dll' name 'glUniform3dv';
    static procedure Uniform3dv(location: Int32; count: Int32; var value: Vec3d);
    external 'opengl32.dll' name 'glUniform3dv';
    static procedure Uniform3dv(location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glUniform3dv';
    
    static procedure Uniform4dv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniform4dv';
    static procedure Uniform4dv(location: Int32; count: Int32; var value: real);
    external 'opengl32.dll' name 'glUniform4dv';
    static procedure Uniform4dv(location: Int32; count: Int32; var value: Vec4d);
    external 'opengl32.dll' name 'glUniform4dv';
    static procedure Uniform4dv(location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glUniform4dv';
    
    static procedure Uniform1uiv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of UInt32);
    external 'opengl32.dll' name 'glUniform1uiv';
    static procedure Uniform1uiv(location: Int32; count: Int32; var value: UInt32);
    external 'opengl32.dll' name 'glUniform1uiv';
    static procedure Uniform1uiv(location: Int32; count: Int32; var value: Vec1ui);
    external 'opengl32.dll' name 'glUniform1uiv';
    static procedure Uniform1uiv(location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glUniform1uiv';
    
    static procedure Uniform2uiv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of UInt32);
    external 'opengl32.dll' name 'glUniform2uiv';
    static procedure Uniform2uiv(location: Int32; count: Int32; var value: UInt32);
    external 'opengl32.dll' name 'glUniform2uiv';
    static procedure Uniform2uiv(location: Int32; count: Int32; var value: Vec2ui);
    external 'opengl32.dll' name 'glUniform2uiv';
    static procedure Uniform2uiv(location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glUniform2uiv';
    
    static procedure Uniform3uiv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of UInt32);
    external 'opengl32.dll' name 'glUniform3uiv';
    static procedure Uniform3uiv(location: Int32; count: Int32; var value: UInt32);
    external 'opengl32.dll' name 'glUniform3uiv';
    static procedure Uniform3uiv(location: Int32; count: Int32; var value: Vec3ui);
    external 'opengl32.dll' name 'glUniform3uiv';
    static procedure Uniform3uiv(location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glUniform3uiv';
    
    static procedure Uniform4uiv(location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of UInt32);
    external 'opengl32.dll' name 'glUniform4uiv';
    static procedure Uniform4uiv(location: Int32; count: Int32; var value: UInt32);
    external 'opengl32.dll' name 'glUniform4uiv';
    static procedure Uniform4uiv(location: Int32; count: Int32; var value: Vec4ui);
    external 'opengl32.dll' name 'glUniform4uiv';
    static procedure Uniform4uiv(location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glUniform4uiv';
    
    {$endregion Uniform[1,2,3,4][i,f,d,ui]v}
    
    {$region UniformMatrix[2,3,4][f,d]v}
    
    static procedure UniformMatrix2fv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniformMatrix2fv';
    static procedure UniformMatrix2fv(location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glUniformMatrix2fv';
    static procedure UniformMatrix2fv(location: Int32; count: Int32; transpose: boolean; var value: Mtr2f);
    external 'opengl32.dll' name 'glUniformMatrix2fv';
    static procedure UniformMatrix2fv(location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glUniformMatrix2fv';
    
    static procedure UniformMatrix3fv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniformMatrix3fv';
    static procedure UniformMatrix3fv(location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glUniformMatrix3fv';
    static procedure UniformMatrix3fv(location: Int32; count: Int32; transpose: boolean; var value: Mtr3f);
    external 'opengl32.dll' name 'glUniformMatrix3fv';
    static procedure UniformMatrix3fv(location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glUniformMatrix3fv';
    
    static procedure UniformMatrix4fv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniformMatrix4fv';
    static procedure UniformMatrix4fv(location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glUniformMatrix4fv';
    static procedure UniformMatrix4fv(location: Int32; count: Int32; transpose: boolean; var value: Mtr4f);
    external 'opengl32.dll' name 'glUniformMatrix4fv';
    static procedure UniformMatrix4fv(location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glUniformMatrix4fv';
    
    static procedure UniformMatrix2dv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniformMatrix2dv';
    static procedure UniformMatrix2dv(location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glUniformMatrix2dv';
    static procedure UniformMatrix2dv(location: Int32; count: Int32; transpose: boolean; var value: Mtr2d);
    external 'opengl32.dll' name 'glUniformMatrix2dv';
    static procedure UniformMatrix2dv(location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glUniformMatrix2dv';
    
    static procedure UniformMatrix3dv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniformMatrix3dv';
    static procedure UniformMatrix3dv(location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glUniformMatrix3dv';
    static procedure UniformMatrix3dv(location: Int32; count: Int32; transpose: boolean; var value: Mtr3d);
    external 'opengl32.dll' name 'glUniformMatrix3dv';
    static procedure UniformMatrix3dv(location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glUniformMatrix3dv';
    
    static procedure UniformMatrix4dv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniformMatrix4dv';
    static procedure UniformMatrix4dv(location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glUniformMatrix4dv';
    static procedure UniformMatrix4dv(location: Int32; count: Int32; transpose: boolean; var value: Mtr4d);
    external 'opengl32.dll' name 'glUniformMatrix4dv';
    static procedure UniformMatrix4dv(location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glUniformMatrix4dv';
    
    {$endregion UniformMatrix[2,3,4][f,d]v}
    
    {$region UniformMatrix[2x3,3x2,2x4,4x2,3x4,4x3][f,d]v}
    
    static procedure UniformMatrix2x3fv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniformMatrix2x3fv';
    static procedure UniformMatrix2x3fv(location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glUniformMatrix2x3fv';
    static procedure UniformMatrix2x3fv(location: Int32; count: Int32; transpose: boolean; var value: Mtr2x3f);
    external 'opengl32.dll' name 'glUniformMatrix2x3fv';
    static procedure UniformMatrix2x3fv(location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glUniformMatrix2x3fv';
    
    static procedure UniformMatrix3x2fv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniformMatrix3x2fv';
    static procedure UniformMatrix3x2fv(location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glUniformMatrix3x2fv';
    static procedure UniformMatrix3x2fv(location: Int32; count: Int32; transpose: boolean; var value: Mtr3x2f);
    external 'opengl32.dll' name 'glUniformMatrix3x2fv';
    static procedure UniformMatrix3x2fv(location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glUniformMatrix3x2fv';
    
    static procedure UniformMatrix2x4fv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniformMatrix2x4fv';
    static procedure UniformMatrix2x4fv(location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glUniformMatrix2x4fv';
    static procedure UniformMatrix2x4fv(location: Int32; count: Int32; transpose: boolean; var value: Mtr2x4f);
    external 'opengl32.dll' name 'glUniformMatrix2x4fv';
    static procedure UniformMatrix2x4fv(location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glUniformMatrix2x4fv';
    
    static procedure UniformMatrix4x2fv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniformMatrix4x2fv';
    static procedure UniformMatrix4x2fv(location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glUniformMatrix4x2fv';
    static procedure UniformMatrix4x2fv(location: Int32; count: Int32; transpose: boolean; var value: Mtr4x2f);
    external 'opengl32.dll' name 'glUniformMatrix4x2fv';
    static procedure UniformMatrix4x2fv(location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glUniformMatrix4x2fv';
    
    static procedure UniformMatrix3x4fv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniformMatrix3x4fv';
    static procedure UniformMatrix3x4fv(location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glUniformMatrix3x4fv';
    static procedure UniformMatrix3x4fv(location: Int32; count: Int32; transpose: boolean; var value: Mtr3x4f);
    external 'opengl32.dll' name 'glUniformMatrix3x4fv';
    static procedure UniformMatrix3x4fv(location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glUniformMatrix3x4fv';
    
    static procedure UniformMatrix4x3fv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glUniformMatrix4x3fv';
    static procedure UniformMatrix4x3fv(location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glUniformMatrix4x3fv';
    static procedure UniformMatrix4x3fv(location: Int32; count: Int32; transpose: boolean; var value: Mtr4x3f);
    external 'opengl32.dll' name 'glUniformMatrix4x3fv';
    static procedure UniformMatrix4x3fv(location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glUniformMatrix4x3fv';
    
    static procedure UniformMatrix2x3dv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniformMatrix2x3dv';
    static procedure UniformMatrix2x3dv(location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glUniformMatrix2x3dv';
    static procedure UniformMatrix2x3dv(location: Int32; count: Int32; transpose: boolean; var value: Mtr2x3d);
    external 'opengl32.dll' name 'glUniformMatrix2x3dv';
    static procedure UniformMatrix2x3dv(location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glUniformMatrix2x3dv';
    
    static procedure UniformMatrix3x2dv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniformMatrix3x2dv';
    static procedure UniformMatrix3x2dv(location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glUniformMatrix3x2dv';
    static procedure UniformMatrix3x2dv(location: Int32; count: Int32; transpose: boolean; var value: Mtr3x2d);
    external 'opengl32.dll' name 'glUniformMatrix3x2dv';
    static procedure UniformMatrix3x2dv(location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glUniformMatrix3x2dv';
    
    static procedure UniformMatrix2x4dv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniformMatrix2x4dv';
    static procedure UniformMatrix2x4dv(location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glUniformMatrix2x4dv';
    static procedure UniformMatrix2x4dv(location: Int32; count: Int32; transpose: boolean; var value: Mtr2x4d);
    external 'opengl32.dll' name 'glUniformMatrix2x4dv';
    static procedure UniformMatrix2x4dv(location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glUniformMatrix2x4dv';
    
    static procedure UniformMatrix4x2dv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniformMatrix4x2dv';
    static procedure UniformMatrix4x2dv(location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glUniformMatrix4x2dv';
    static procedure UniformMatrix4x2dv(location: Int32; count: Int32; transpose: boolean; var value: Mtr4x2d);
    external 'opengl32.dll' name 'glUniformMatrix4x2dv';
    static procedure UniformMatrix4x2dv(location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glUniformMatrix4x2dv';
    
    static procedure UniformMatrix3x4dv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniformMatrix3x4dv';
    static procedure UniformMatrix3x4dv(location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glUniformMatrix3x4dv';
    static procedure UniformMatrix3x4dv(location: Int32; count: Int32; transpose: boolean; var value: Mtr3x4d);
    external 'opengl32.dll' name 'glUniformMatrix3x4dv';
    static procedure UniformMatrix3x4dv(location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glUniformMatrix3x4dv';
    
    static procedure UniformMatrix4x3dv(location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glUniformMatrix4x3dv';
    static procedure UniformMatrix4x3dv(location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glUniformMatrix4x3dv';
    static procedure UniformMatrix4x3dv(location: Int32; count: Int32; transpose: boolean; var value: Mtr4x3d);
    external 'opengl32.dll' name 'glUniformMatrix4x3dv';
    static procedure UniformMatrix4x3dv(location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glUniformMatrix4x3dv';
    
    {$endregion UniformMatrix[2x3,3x2,2x4,4x2,3x4,4x3][f,d]v}
    
    {$region ProgramUniform[1,2,3,4][i,f,d,ui]}
    
    static procedure ProgramUniform1i(&program: ProgramName; location: Int32; v0: Int32);
    external 'opengl32.dll' name 'glProgramUniform1i';
    
    static procedure ProgramUniform2i(&program: ProgramName; location: Int32; v0: Int32; v1: Int32);
    external 'opengl32.dll' name 'glProgramUniform2i';
    
    static procedure ProgramUniform3i(&program: ProgramName; location: Int32; v0: Int32; v1: Int32; v2: Int32);
    external 'opengl32.dll' name 'glProgramUniform3i';
    
    static procedure ProgramUniform4i(&program: ProgramName; location: Int32; v0: Int32; v1: Int32; v2: Int32; v3: Int32);
    external 'opengl32.dll' name 'glProgramUniform4i';
    
    static procedure ProgramUniform1f(&program: ProgramName; location: Int32; v0: single);
    external 'opengl32.dll' name 'glProgramUniform1f';
    
    static procedure ProgramUniform2f(&program: ProgramName; location: Int32; v0: single; v1: single);
    external 'opengl32.dll' name 'glProgramUniform2f';
    
    static procedure ProgramUniform3f(&program: ProgramName; location: Int32; v0: single; v1: single; v2: single);
    external 'opengl32.dll' name 'glProgramUniform3f';
    
    static procedure ProgramUniform4f(&program: ProgramName; location: Int32; v0: single; v1: single; v2: single; v3: single);
    external 'opengl32.dll' name 'glProgramUniform4f';
    
    static procedure ProgramUniform1d(&program: ProgramName; location: Int32; x: real);
    external 'opengl32.dll' name 'glProgramUniform1d';
    
    static procedure ProgramUniform2d(&program: ProgramName; location: Int32; x: real; y: real);
    external 'opengl32.dll' name 'glProgramUniform2d';
    
    static procedure ProgramUniform3d(&program: ProgramName; location: Int32; x: real; y: real; z: real);
    external 'opengl32.dll' name 'glProgramUniform3d';
    
    static procedure ProgramUniform4d(&program: ProgramName; location: Int32; x: real; y: real; z: real; w: real);
    external 'opengl32.dll' name 'glProgramUniform4d';
    
    static procedure ProgramUniform1ui(&program: ProgramName; location: Int32; v0: UInt32);
    external 'opengl32.dll' name 'glProgramUniform1ui';
    
    static procedure ProgramUniform2ui(&program: ProgramName; location: Int32; v0: UInt32; v1: UInt32);
    external 'opengl32.dll' name 'glProgramUniform2ui';
    
    static procedure ProgramUniform3ui(&program: ProgramName; location: Int32; v0: UInt32; v1: UInt32; v2: UInt32);
    external 'opengl32.dll' name 'glProgramUniform3ui';
    
    static procedure ProgramUniform4ui(&program: ProgramName; location: Int32; v0: UInt32; v1: UInt32; v2: UInt32; v3: UInt32);
    external 'opengl32.dll' name 'glProgramUniform4ui';
    
    {$endregion ProgramUniform[1,2,3,4][i,f,d,ui]}
    
    {$region ProgramUniform[1,2,3,4][i,f,d,ui]v}
    
    static procedure ProgramUniform1iv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of Int32);
    external 'opengl32.dll' name 'glProgramUniform1iv';
    static procedure ProgramUniform1iv(&program: ProgramName; location: Int32; count: Int32; var value: Int32);
    external 'opengl32.dll' name 'glProgramUniform1iv';
    static procedure ProgramUniform1iv(&program: ProgramName; location: Int32; count: Int32; var value: Vec1i);
    external 'opengl32.dll' name 'glProgramUniform1iv';
    static procedure ProgramUniform1iv(&program: ProgramName; location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glProgramUniform1iv';
    
    static procedure ProgramUniform2iv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of Int32);
    external 'opengl32.dll' name 'glProgramUniform2iv';
    static procedure ProgramUniform2iv(&program: ProgramName; location: Int32; count: Int32; var value: Int32);
    external 'opengl32.dll' name 'glProgramUniform2iv';
    static procedure ProgramUniform2iv(&program: ProgramName; location: Int32; count: Int32; var value: Vec2i);
    external 'opengl32.dll' name 'glProgramUniform2iv';
    static procedure ProgramUniform2iv(&program: ProgramName; location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glProgramUniform2iv';
    
    static procedure ProgramUniform3iv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of Int32);
    external 'opengl32.dll' name 'glProgramUniform3iv';
    static procedure ProgramUniform3iv(&program: ProgramName; location: Int32; count: Int32; var value: Int32);
    external 'opengl32.dll' name 'glProgramUniform3iv';
    static procedure ProgramUniform3iv(&program: ProgramName; location: Int32; count: Int32; var value: Vec3i);
    external 'opengl32.dll' name 'glProgramUniform3iv';
    static procedure ProgramUniform3iv(&program: ProgramName; location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glProgramUniform3iv';
    
    static procedure ProgramUniform4iv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of Int32);
    external 'opengl32.dll' name 'glProgramUniform4iv';
    static procedure ProgramUniform4iv(&program: ProgramName; location: Int32; count: Int32; var value: Int32);
    external 'opengl32.dll' name 'glProgramUniform4iv';
    static procedure ProgramUniform4iv(&program: ProgramName; location: Int32; count: Int32; var value: Vec4i);
    external 'opengl32.dll' name 'glProgramUniform4iv';
    static procedure ProgramUniform4iv(&program: ProgramName; location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glProgramUniform4iv';
    
    static procedure ProgramUniform1fv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniform1fv';
    static procedure ProgramUniform1fv(&program: ProgramName; location: Int32; count: Int32; var value: single);
    external 'opengl32.dll' name 'glProgramUniform1fv';
    static procedure ProgramUniform1fv(&program: ProgramName; location: Int32; count: Int32; var value: Vec1f);
    external 'opengl32.dll' name 'glProgramUniform1fv';
    static procedure ProgramUniform1fv(&program: ProgramName; location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glProgramUniform1fv';
    
    static procedure ProgramUniform2fv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniform2fv';
    static procedure ProgramUniform2fv(&program: ProgramName; location: Int32; count: Int32; var value: single);
    external 'opengl32.dll' name 'glProgramUniform2fv';
    static procedure ProgramUniform2fv(&program: ProgramName; location: Int32; count: Int32; var value: Vec2f);
    external 'opengl32.dll' name 'glProgramUniform2fv';
    static procedure ProgramUniform2fv(&program: ProgramName; location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glProgramUniform2fv';
    
    static procedure ProgramUniform3fv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniform3fv';
    static procedure ProgramUniform3fv(&program: ProgramName; location: Int32; count: Int32; var value: single);
    external 'opengl32.dll' name 'glProgramUniform3fv';
    static procedure ProgramUniform3fv(&program: ProgramName; location: Int32; count: Int32; var value: Vec3f);
    external 'opengl32.dll' name 'glProgramUniform3fv';
    static procedure ProgramUniform3fv(&program: ProgramName; location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glProgramUniform3fv';
    
    static procedure ProgramUniform4fv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniform4fv';
    static procedure ProgramUniform4fv(&program: ProgramName; location: Int32; count: Int32; var value: single);
    external 'opengl32.dll' name 'glProgramUniform4fv';
    static procedure ProgramUniform4fv(&program: ProgramName; location: Int32; count: Int32; var value: Vec4f);
    external 'opengl32.dll' name 'glProgramUniform4fv';
    static procedure ProgramUniform4fv(&program: ProgramName; location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glProgramUniform4fv';
    
    static procedure ProgramUniform1dv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniform1dv';
    static procedure ProgramUniform1dv(&program: ProgramName; location: Int32; count: Int32; var value: real);
    external 'opengl32.dll' name 'glProgramUniform1dv';
    static procedure ProgramUniform1dv(&program: ProgramName; location: Int32; count: Int32; var value: Vec1d);
    external 'opengl32.dll' name 'glProgramUniform1dv';
    static procedure ProgramUniform1dv(&program: ProgramName; location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glProgramUniform1dv';
    
    static procedure ProgramUniform2dv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniform2dv';
    static procedure ProgramUniform2dv(&program: ProgramName; location: Int32; count: Int32; var value: real);
    external 'opengl32.dll' name 'glProgramUniform2dv';
    static procedure ProgramUniform2dv(&program: ProgramName; location: Int32; count: Int32; var value: Vec2d);
    external 'opengl32.dll' name 'glProgramUniform2dv';
    static procedure ProgramUniform2dv(&program: ProgramName; location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glProgramUniform2dv';
    
    static procedure ProgramUniform3dv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniform3dv';
    static procedure ProgramUniform3dv(&program: ProgramName; location: Int32; count: Int32; var value: real);
    external 'opengl32.dll' name 'glProgramUniform3dv';
    static procedure ProgramUniform3dv(&program: ProgramName; location: Int32; count: Int32; var value: Vec3d);
    external 'opengl32.dll' name 'glProgramUniform3dv';
    static procedure ProgramUniform3dv(&program: ProgramName; location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glProgramUniform3dv';
    
    static procedure ProgramUniform4dv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniform4dv';
    static procedure ProgramUniform4dv(&program: ProgramName; location: Int32; count: Int32; var value: real);
    external 'opengl32.dll' name 'glProgramUniform4dv';
    static procedure ProgramUniform4dv(&program: ProgramName; location: Int32; count: Int32; var value: Vec4d);
    external 'opengl32.dll' name 'glProgramUniform4dv';
    static procedure ProgramUniform4dv(&program: ProgramName; location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glProgramUniform4dv';
    
    static procedure ProgramUniform1uiv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of UInt32);
    external 'opengl32.dll' name 'glProgramUniform1uiv';
    static procedure ProgramUniform1uiv(&program: ProgramName; location: Int32; count: Int32; var value: UInt32);
    external 'opengl32.dll' name 'glProgramUniform1uiv';
    static procedure ProgramUniform1uiv(&program: ProgramName; location: Int32; count: Int32; var value: Vec1ui);
    external 'opengl32.dll' name 'glProgramUniform1uiv';
    static procedure ProgramUniform1uiv(&program: ProgramName; location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glProgramUniform1uiv';
    
    static procedure ProgramUniform2uiv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of UInt32);
    external 'opengl32.dll' name 'glProgramUniform2uiv';
    static procedure ProgramUniform2uiv(&program: ProgramName; location: Int32; count: Int32; var value: UInt32);
    external 'opengl32.dll' name 'glProgramUniform2uiv';
    static procedure ProgramUniform2uiv(&program: ProgramName; location: Int32; count: Int32; var value: Vec2ui);
    external 'opengl32.dll' name 'glProgramUniform2uiv';
    static procedure ProgramUniform2uiv(&program: ProgramName; location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glProgramUniform2uiv';
    
    static procedure ProgramUniform3uiv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of UInt32);
    external 'opengl32.dll' name 'glProgramUniform3uiv';
    static procedure ProgramUniform3uiv(&program: ProgramName; location: Int32; count: Int32; var value: UInt32);
    external 'opengl32.dll' name 'glProgramUniform3uiv';
    static procedure ProgramUniform3uiv(&program: ProgramName; location: Int32; count: Int32; var value: Vec3ui);
    external 'opengl32.dll' name 'glProgramUniform3uiv';
    static procedure ProgramUniform3uiv(&program: ProgramName; location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glProgramUniform3uiv';
    
    static procedure ProgramUniform4uiv(&program: ProgramName; location: Int32; count: Int32; [MarshalAs(UnmanagedType.LPArray)] value: array of UInt32);
    external 'opengl32.dll' name 'glProgramUniform4uiv';
    static procedure ProgramUniform4uiv(&program: ProgramName; location: Int32; count: Int32; var value: UInt32);
    external 'opengl32.dll' name 'glProgramUniform4uiv';
    static procedure ProgramUniform4uiv(&program: ProgramName; location: Int32; count: Int32; var value: Vec4ui);
    external 'opengl32.dll' name 'glProgramUniform4uiv';
    static procedure ProgramUniform4uiv(&program: ProgramName; location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glProgramUniform4uiv';
    
    {$endregion ProgramUniform[1,2,3,4][i,f,d,ui]v}
    
    {$region ProgramUniformMatrix[2,3,4][f,d]v}
    
    static procedure ProgramUniformMatrix2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2fv';
    static procedure ProgramUniformMatrix2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2fv';
    static procedure ProgramUniformMatrix2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr2f);
    external 'opengl32.dll' name 'glProgramUniformMatrix2fv';
    static procedure ProgramUniformMatrix2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2fv';
    
    static procedure ProgramUniformMatrix3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3fv';
    static procedure ProgramUniformMatrix3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3fv';
    static procedure ProgramUniformMatrix3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr3f);
    external 'opengl32.dll' name 'glProgramUniformMatrix3fv';
    static procedure ProgramUniformMatrix3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3fv';
    
    static procedure ProgramUniformMatrix4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4fv';
    static procedure ProgramUniformMatrix4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4fv';
    static procedure ProgramUniformMatrix4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr4f);
    external 'opengl32.dll' name 'glProgramUniformMatrix4fv';
    static procedure ProgramUniformMatrix4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4fv';
    
    static procedure ProgramUniformMatrix2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2dv';
    static procedure ProgramUniformMatrix2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2dv';
    static procedure ProgramUniformMatrix2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr2d);
    external 'opengl32.dll' name 'glProgramUniformMatrix2dv';
    static procedure ProgramUniformMatrix2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2dv';
    
    static procedure ProgramUniformMatrix3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3dv';
    static procedure ProgramUniformMatrix3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3dv';
    static procedure ProgramUniformMatrix3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr3d);
    external 'opengl32.dll' name 'glProgramUniformMatrix3dv';
    static procedure ProgramUniformMatrix3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3dv';
    
    static procedure ProgramUniformMatrix4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4dv';
    static procedure ProgramUniformMatrix4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4dv';
    static procedure ProgramUniformMatrix4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr4d);
    external 'opengl32.dll' name 'glProgramUniformMatrix4dv';
    static procedure ProgramUniformMatrix4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4dv';
    
    {$endregion ProgramUniformMatrix[2,3,4][f,d]v}
    
    {$region ProgramUniformMatrix[2x3,3x2,2x4,4x2,3x4,4x3][f,d]v}
    
    static procedure ProgramUniformMatrix2x3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x3fv';
    static procedure ProgramUniformMatrix2x3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x3fv';
    static procedure ProgramUniformMatrix2x3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr2x3f);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x3fv';
    static procedure ProgramUniformMatrix2x3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x3fv';
    
    static procedure ProgramUniformMatrix3x2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x2fv';
    static procedure ProgramUniformMatrix3x2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x2fv';
    static procedure ProgramUniformMatrix3x2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr3x2f);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x2fv';
    static procedure ProgramUniformMatrix3x2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x2fv';
    
    static procedure ProgramUniformMatrix2x4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x4fv';
    static procedure ProgramUniformMatrix2x4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x4fv';
    static procedure ProgramUniformMatrix2x4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr2x4f);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x4fv';
    static procedure ProgramUniformMatrix2x4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x4fv';
    
    static procedure ProgramUniformMatrix4x2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x2fv';
    static procedure ProgramUniformMatrix4x2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x2fv';
    static procedure ProgramUniformMatrix4x2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr4x2f);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x2fv';
    static procedure ProgramUniformMatrix4x2fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x2fv';
    
    static procedure ProgramUniformMatrix3x4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x4fv';
    static procedure ProgramUniformMatrix3x4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x4fv';
    static procedure ProgramUniformMatrix3x4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr3x4f);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x4fv';
    static procedure ProgramUniformMatrix3x4fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x4fv';
    
    static procedure ProgramUniformMatrix4x3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x3fv';
    static procedure ProgramUniformMatrix4x3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x3fv';
    static procedure ProgramUniformMatrix4x3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr4x3f);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x3fv';
    static procedure ProgramUniformMatrix4x3fv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x3fv';
    
    static procedure ProgramUniformMatrix2x3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x3dv';
    static procedure ProgramUniformMatrix2x3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x3dv';
    static procedure ProgramUniformMatrix2x3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr2x3d);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x3dv';
    static procedure ProgramUniformMatrix2x3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x3dv';
    
    static procedure ProgramUniformMatrix3x2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x2dv';
    static procedure ProgramUniformMatrix3x2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x2dv';
    static procedure ProgramUniformMatrix3x2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr3x2d);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x2dv';
    static procedure ProgramUniformMatrix3x2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x2dv';
    
    static procedure ProgramUniformMatrix2x4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x4dv';
    static procedure ProgramUniformMatrix2x4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x4dv';
    static procedure ProgramUniformMatrix2x4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr2x4d);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x4dv';
    static procedure ProgramUniformMatrix2x4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x4dv';
    
    static procedure ProgramUniformMatrix4x2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x2dv';
    static procedure ProgramUniformMatrix4x2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x2dv';
    static procedure ProgramUniformMatrix4x2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr4x2d);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x2dv';
    static procedure ProgramUniformMatrix4x2dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x2dv';
    
    static procedure ProgramUniformMatrix3x4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x4dv';
    static procedure ProgramUniformMatrix3x4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x4dv';
    static procedure ProgramUniformMatrix3x4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr3x4d);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x4dv';
    static procedure ProgramUniformMatrix3x4dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x4dv';
    
    static procedure ProgramUniformMatrix4x3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; [MarshalAs(UnmanagedType.LPArray)] value: array of real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x3dv';
    static procedure ProgramUniformMatrix4x3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x3dv';
    static procedure ProgramUniformMatrix4x3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; var value: Mtr4x3d);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x3dv';
    static procedure ProgramUniformMatrix4x3dv(&program: ProgramName; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x3dv';
    
    {$endregion ProgramUniformMatrix[2x3,3x2,2x4,4x2,3x4,4x3][f,d]v}
    
    // 7.6.3
    
    static procedure UniformBlockBinding(&program: ProgramName; uniformBlockIndex: UInt32; uniformBlockBinding: UInt32);
    external 'opengl32.dll' name 'glUniformBlockBinding';
    
    {$endregion 7.6 - Uniform Variables}
    
    {$region 7.8 - Shader Buffer Variables and Shader Storage Blocks}
    
    static procedure ShaderStorageBlockBinding(&program: ProgramName; storageBlockIndex: UInt32; storageBlockBinding: UInt32);
    external 'opengl32.dll' name 'glShaderStorageBlockBinding';
    
    {$endregion 7.8 - Shader Buffer Variables and Shader Storage Blocks}
    
    {$region 7.10 - Subroutine Uniform Variables}
    
    
    
    {$endregion 7.10 - Subroutine Uniform Variables}
    
    
    
    {$region unsorted}
    
    static function GetSubroutineIndex(&program: ProgramName; shadertype: UInt32; name: ^SByte): UInt32;
    external 'opengl32.dll' name 'glGetSubroutineIndex';
    
    static procedure GetActiveSubroutineName(&program: ProgramName; shadertype: UInt32; index: UInt32; bufsize: Int32; length: ^Int32; name: ^SByte);
    external 'opengl32.dll' name 'glGetActiveSubroutineName';
    
    static function GetSubroutineUniformLocation(&program: ProgramName; shadertype: UInt32; name: ^SByte): Int32;
    external 'opengl32.dll' name 'glGetSubroutineUniformLocation';
    
    static procedure GetActiveSubroutineUniformName(&program: ProgramName; shadertype: UInt32; index: UInt32; bufsize: Int32; length: ^Int32; name: ^SByte);
    external 'opengl32.dll' name 'glGetActiveSubroutineUniformName';
    
    static procedure GetActiveSubroutineUniformiv(&program: ProgramName; shadertype: UInt32; index: UInt32; pname: UInt32; values: ^Int32);
    external 'opengl32.dll' name 'glGetActiveSubroutineUniformiv';
    
    static procedure UniformSubroutinesuiv(shadertype: UInt32; count: Int32; indices: ^UInt32);
    external 'opengl32.dll' name 'glUniformSubroutinesuiv';
    
    static procedure MemoryBarrier(barriers: UInt32);
    external 'opengl32.dll' name 'glMemoryBarrier';
    
    static procedure MemoryBarrierByRegion(barriers: UInt32);
    external 'opengl32.dll' name 'glMemoryBarrierByRegion';
    
    static procedure GetShaderiv(shader: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetShaderiv';
    
    static procedure GetProgramiv(&program: ProgramName; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetProgramiv';
    
    static procedure GetProgramPipelineiv(pipeline: ProgramPipelineName; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetProgramPipelineiv';
    
    static procedure GetAttachedShaders(&program: ProgramName; maxCount: Int32; count: ^Int32; shaders: ^UInt32);
    external 'opengl32.dll' name 'glGetAttachedShaders';
    
    static procedure GetShaderInfoLog(shader: UInt32; bufSize: Int32; length: ^Int32; infoLog: ^SByte);
    external 'opengl32.dll' name 'glGetShaderInfoLog';
    
    static procedure GetProgramInfoLog(&program: ProgramName; bufSize: Int32; length: ^Int32; infoLog: ^SByte);
    external 'opengl32.dll' name 'glGetProgramInfoLog';
    
    static procedure GetProgramPipelineInfoLog(pipeline: ProgramPipelineName; bufSize: Int32; length: ^Int32; infoLog: ^SByte);
    external 'opengl32.dll' name 'glGetProgramPipelineInfoLog';
    
    static procedure GetShaderSource(shader: UInt32; bufSize: Int32; length: ^Int32; source: ^SByte);
    external 'opengl32.dll' name 'glGetShaderSource';
    
    static procedure GetShaderPrecisionFormat(shadertype: UInt32; precisiontype: UInt32; range: ^Int32; precision: ^Int32);
    external 'opengl32.dll' name 'glGetShaderPrecisionFormat';
    
    static procedure GetUniformfv(&program: ProgramName; location: Int32; &params: ^single);
    external 'opengl32.dll' name 'glGetUniformfv';
    
    static procedure GetUniformdv(&program: ProgramName; location: Int32; &params: ^real);
    external 'opengl32.dll' name 'glGetUniformdv';
    
    static procedure GetUniformiv(&program: ProgramName; location: Int32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetUniformiv';
    
    static procedure GetUniformuiv(&program: ProgramName; location: Int32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetUniformuiv';
    
    static procedure GetnUniformfv(&program: ProgramName; location: Int32; bufSize: Int32; &params: ^single);
    external 'opengl32.dll' name 'glGetnUniformfv';
    
    static procedure GetnUniformdv(&program: ProgramName; location: Int32; bufSize: Int32; &params: ^real);
    external 'opengl32.dll' name 'glGetnUniformdv';
    
    static procedure GetnUniformiv(&program: ProgramName; location: Int32; bufSize: Int32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetnUniformiv';
    
    static procedure GetnUniformuiv(&program: ProgramName; location: Int32; bufSize: Int32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetnUniformuiv';
    
    static procedure GetUniformSubroutineuiv(shadertype: UInt32; location: Int32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetUniformSubroutineuiv';
    
    static procedure GetProgramStageiv(&program: ProgramName; shadertype: UInt32; pname: UInt32; values: ^Int32);
    external 'opengl32.dll' name 'glGetProgramStageiv';
    
    {$endregion unsorted}
    
    {$endregion 7.0 - Programs and Shaders}
    
    
    
    {$region }
    
    {$endregion }
    
    {$region unsorted}
    
    static procedure ValidateProgram(&program: UInt32);
    external 'opengl32.dll' name 'glValidateProgram';
    
    static procedure ValidateProgramPipeline(pipeline: UInt32);
    external 'opengl32.dll' name 'glValidateProgramPipeline';
    
    static procedure Hint(target: UInt32; mode: UInt32);
    external 'opengl32.dll' name 'glHint';
    
    static procedure CullFace(mode: UInt32);
    external 'opengl32.dll' name 'glCullFace';
    
    static procedure FrontFace(mode: UInt32);
    external 'opengl32.dll' name 'glFrontFace';
    
    static procedure LineWidth(width: single);
    external 'opengl32.dll' name 'glLineWidth';
    
    static procedure PointSize(size: single);
    external 'opengl32.dll' name 'glPointSize';
    
    static procedure PolygonMode(face: UInt32; mode: UInt32);
    external 'opengl32.dll' name 'glPolygonMode';
    
    static procedure Scissor(x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glScissor';
    
    static procedure TexParameterf(target: UInt32; pname: UInt32; param: single);
    external 'opengl32.dll' name 'glTexParameterf';
    
    static procedure TexParameterfv(target: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glTexParameterfv';
    
    static procedure TexParameteri(target: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glTexParameteri';
    
    static procedure TexParameteriv(target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glTexParameteriv';
    
    static procedure TexImage1D(target: UInt32; level: Int32; internalformat: Int32; width: Int32; border: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTexImage1D';
    
    static procedure TexImage2D(target: UInt32; level: Int32; internalformat: Int32; width: Int32; height: Int32; border: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTexImage2D';
    
    static procedure DrawBuffer(buf: UInt32);
    external 'opengl32.dll' name 'glDrawBuffer';
    
    static procedure Clear(mask: UInt32);
    external 'opengl32.dll' name 'glClear';
    
    static procedure ClearColor(red: single; green: single; blue: single; alpha: single);
    external 'opengl32.dll' name 'glClearColor';
    
    static procedure ClearStencil(s: Int32);
    external 'opengl32.dll' name 'glClearStencil';
    
    static procedure ClearDepth(depth: real);
    external 'opengl32.dll' name 'glClearDepth';
    
    static procedure StencilMask(mask: UInt32);
    external 'opengl32.dll' name 'glStencilMask';
    
    static procedure ColorMask(red: boolean; green: boolean; blue: boolean; alpha: boolean);
    external 'opengl32.dll' name 'glColorMask';
    
    static procedure DepthMask(flag: boolean);
    external 'opengl32.dll' name 'glDepthMask';
    
    static procedure Disable(cap: UInt32);
    external 'opengl32.dll' name 'glDisable';
    
    static procedure Enable(cap: UInt32);
    external 'opengl32.dll' name 'glEnable';
    
    static procedure Finish;
    external 'opengl32.dll' name 'glFinish';
    
    static procedure Flush;
    external 'opengl32.dll' name 'glFlush';
    
    static procedure BlendFunc(sfactor: UInt32; dfactor: UInt32);
    external 'opengl32.dll' name 'glBlendFunc';
    
    static procedure LogicOp(opcode: UInt32);
    external 'opengl32.dll' name 'glLogicOp';
    
    static procedure StencilFunc(func: UInt32; ref: Int32; mask: UInt32);
    external 'opengl32.dll' name 'glStencilFunc';
    
    static procedure StencilOp(fail: UInt32; zfail: UInt32; zpass: UInt32);
    external 'opengl32.dll' name 'glStencilOp';
    
    static procedure DepthFunc(func: UInt32);
    external 'opengl32.dll' name 'glDepthFunc';
    
    static procedure PixelStoref(pname: UInt32; param: single);
    external 'opengl32.dll' name 'glPixelStoref';
    
    static procedure PixelStorei(pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glPixelStorei';
    
    static procedure ReadBuffer(src: UInt32);
    external 'opengl32.dll' name 'glReadBuffer';
    
    static procedure ReadPixels(x: Int32; y: Int32; width: Int32; height: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glReadPixels';
    
    static procedure GetBooleanv(pname: UInt32; data: ^boolean);
    external 'opengl32.dll' name 'glGetBooleanv';
    
    static procedure GetDoublev(pname: UInt32; data: ^real);
    external 'opengl32.dll' name 'glGetDoublev';
    
    static procedure GetFloatv(pname: UInt32; data: ^single);
    external 'opengl32.dll' name 'glGetFloatv';
    
    static function GetString(name: UInt32): ^Byte;
    external 'opengl32.dll' name 'glGetString';
    
    static procedure GetTexImage(target: UInt32; level: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glGetTexImage';
    
    static procedure GetTexParameterfv(target: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetTexParameterfv';
    
    static procedure GetTexParameteriv(target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetTexParameteriv';
    
    static procedure GetTexLevelParameterfv(target: UInt32; level: Int32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetTexLevelParameterfv';
    
    static procedure GetTexLevelParameteriv(target: UInt32; level: Int32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetTexLevelParameteriv';
    
    static function IsEnabled(cap: UInt32): boolean;
    external 'opengl32.dll' name 'glIsEnabled';
    
    static procedure DepthRange(n: real; f: real);
    external 'opengl32.dll' name 'glDepthRange';
    
    static procedure Viewport(x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glViewport';
    
    static procedure DrawArrays(mode: UInt32; first: Int32; count: Int32);
    external 'opengl32.dll' name 'glDrawArrays';
    
    static procedure DrawElements(mode: UInt32; count: Int32; &type: UInt32; indices: pointer);
    external 'opengl32.dll' name 'glDrawElements';
    
    static procedure GetPointerv(pname: UInt32; &params: ^IntPtr);
    external 'opengl32.dll' name 'glGetPointerv';
    
    static procedure PolygonOffset(factor: single; units: single);
    external 'opengl32.dll' name 'glPolygonOffset';
    
    static procedure CopyTexImage1D(target: UInt32; level: Int32; internalformat: UInt32; x: Int32; y: Int32; width: Int32; border: Int32);
    external 'opengl32.dll' name 'glCopyTexImage1D';
    
    static procedure CopyTexImage2D(target: UInt32; level: Int32; internalformat: UInt32; x: Int32; y: Int32; width: Int32; height: Int32; border: Int32);
    external 'opengl32.dll' name 'glCopyTexImage2D';
    
    static procedure CopyTexSubImage1D(target: UInt32; level: Int32; xoffset: Int32; x: Int32; y: Int32; width: Int32);
    external 'opengl32.dll' name 'glCopyTexSubImage1D';
    
    static procedure CopyTexSubImage2D(target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glCopyTexSubImage2D';
    
    static procedure TexSubImage1D(target: UInt32; level: Int32; xoffset: Int32; width: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTexSubImage1D';
    
    static procedure TexSubImage2D(target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; width: Int32; height: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTexSubImage2D';
    
    static procedure BindTexture(target: UInt32; texture: UInt32);
    external 'opengl32.dll' name 'glBindTexture';
    
    static procedure DeleteTextures(n: Int32; textures: ^UInt32);
    external 'opengl32.dll' name 'glDeleteTextures';
    
    static procedure GenTextures(n: Int32; textures: ^UInt32);
    external 'opengl32.dll' name 'glGenTextures';
    
    static function IsTexture(texture: UInt32): boolean;
    external 'opengl32.dll' name 'glIsTexture';
    
    static procedure DrawRangeElements(mode: UInt32; start: UInt32; &end: UInt32; count: Int32; &type: UInt32; indices: pointer);
    external 'opengl32.dll' name 'glDrawRangeElements';
    
    static procedure TexImage3D(target: UInt32; level: Int32; internalformat: Int32; width: Int32; height: Int32; depth: Int32; border: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTexImage3D';
    
    static procedure TexSubImage3D(target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTexSubImage3D';
    
    static procedure CopyTexSubImage3D(target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glCopyTexSubImage3D';
    
    static procedure ActiveTexture(texture: UInt32);
    external 'opengl32.dll' name 'glActiveTexture';
    
    static procedure SampleCoverage(value: single; invert: boolean);
    external 'opengl32.dll' name 'glSampleCoverage';
    
    static procedure CompressedTexImage3D(target: UInt32; level: Int32; internalformat: UInt32; width: Int32; height: Int32; depth: Int32; border: Int32; imageSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glCompressedTexImage3D';
    
    static procedure CompressedTexImage2D(target: UInt32; level: Int32; internalformat: UInt32; width: Int32; height: Int32; border: Int32; imageSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glCompressedTexImage2D';
    
    static procedure CompressedTexImage1D(target: UInt32; level: Int32; internalformat: UInt32; width: Int32; border: Int32; imageSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glCompressedTexImage1D';
    
    static procedure CompressedTexSubImage3D(target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; format: UInt32; imageSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glCompressedTexSubImage3D';
    
    static procedure CompressedTexSubImage2D(target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; width: Int32; height: Int32; format: UInt32; imageSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glCompressedTexSubImage2D';
    
    static procedure CompressedTexSubImage1D(target: UInt32; level: Int32; xoffset: Int32; width: Int32; format: UInt32; imageSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glCompressedTexSubImage1D';
    
    static procedure GetCompressedTexImage(target: UInt32; level: Int32; img: pointer);
    external 'opengl32.dll' name 'glGetCompressedTexImage';
    
    static procedure BlendFuncSeparate(sfactorRGB: UInt32; dfactorRGB: UInt32; sfactorAlpha: UInt32; dfactorAlpha: UInt32);
    external 'opengl32.dll' name 'glBlendFuncSeparate';
    
    static procedure MultiDrawArrays(mode: UInt32; first: ^Int32; count: ^Int32; drawcount: Int32);
    external 'opengl32.dll' name 'glMultiDrawArrays';
    
    static procedure MultiDrawElements(mode: UInt32; count: ^Int32; &type: UInt32; indices: ^IntPtr; drawcount: Int32);
    external 'opengl32.dll' name 'glMultiDrawElements';
    
    static procedure PointParameterf(pname: UInt32; param: single);
    external 'opengl32.dll' name 'glPointParameterf';
    
    static procedure PointParameterfv(pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glPointParameterfv';
    
    static procedure PointParameteri(pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glPointParameteri';
    
    static procedure PointParameteriv(pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glPointParameteriv';
    
    static procedure BlendColor(red: single; green: single; blue: single; alpha: single);
    external 'opengl32.dll' name 'glBlendColor';
    
    static procedure BlendEquation(mode: UInt32);
    external 'opengl32.dll' name 'glBlendEquation';
    
    static procedure BlendEquationSeparate(modeRGB: UInt32; modeAlpha: UInt32);
    external 'opengl32.dll' name 'glBlendEquationSeparate';
    
    static procedure DrawBuffers(n: Int32; bufs: ^UInt32);
    external 'opengl32.dll' name 'glDrawBuffers';
    
    static procedure StencilOpSeparate(face: UInt32; sfail: UInt32; dpfail: UInt32; dppass: UInt32);
    external 'opengl32.dll' name 'glStencilOpSeparate';
    
    static procedure StencilFuncSeparate(face: UInt32; func: UInt32; ref: Int32; mask: UInt32);
    external 'opengl32.dll' name 'glStencilFuncSeparate';
    
    static procedure StencilMaskSeparate(face: UInt32; mask: UInt32);
    external 'opengl32.dll' name 'glStencilMaskSeparate';
    
    static procedure BindAttribLocation(&program: UInt32; index: UInt32; name: ^SByte);
    external 'opengl32.dll' name 'glBindAttribLocation';
    
    static procedure DisableVertexAttribArray(index: UInt32);
    external 'opengl32.dll' name 'glDisableVertexAttribArray';
    
    static procedure EnableVertexAttribArray(index: UInt32);
    external 'opengl32.dll' name 'glEnableVertexAttribArray';
    
    static procedure GetActiveAttrib(&program: UInt32; index: UInt32; bufSize: Int32; length: ^Int32; size: ^Int32; &type: ^UInt32; name: ^SByte);
    external 'opengl32.dll' name 'glGetActiveAttrib';
    
    static function GetAttribLocation(&program: UInt32; name: ^SByte): Int32;
    external 'opengl32.dll' name 'glGetAttribLocation';
    
    static procedure GetVertexAttribdv(index: UInt32; pname: UInt32; &params: ^real);
    external 'opengl32.dll' name 'glGetVertexAttribdv';
    
    static procedure GetVertexAttribfv(index: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetVertexAttribfv';
    
    static procedure GetVertexAttribiv(index: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetVertexAttribiv';
    
    static procedure GetVertexAttribPointerv(index: UInt32; pname: UInt32; pointer: ^IntPtr);
    external 'opengl32.dll' name 'glGetVertexAttribPointerv';
    
    static procedure VertexAttrib1d(index: UInt32; x: real);
    external 'opengl32.dll' name 'glVertexAttrib1d';
    
    static procedure VertexAttrib1dv(index: UInt32; v: ^real);
    external 'opengl32.dll' name 'glVertexAttrib1dv';
    
    static procedure VertexAttrib1f(index: UInt32; x: single);
    external 'opengl32.dll' name 'glVertexAttrib1f';
    
    static procedure VertexAttrib1fv(index: UInt32; v: ^single);
    external 'opengl32.dll' name 'glVertexAttrib1fv';
    
    static procedure VertexAttrib1s(index: UInt32; x: Int16);
    external 'opengl32.dll' name 'glVertexAttrib1s';
    
    static procedure VertexAttrib1sv(index: UInt32; v: ^Int16);
    external 'opengl32.dll' name 'glVertexAttrib1sv';
    
    static procedure VertexAttrib2d(index: UInt32; x: real; y: real);
    external 'opengl32.dll' name 'glVertexAttrib2d';
    
    static procedure VertexAttrib2dv(index: UInt32; v: ^real);
    external 'opengl32.dll' name 'glVertexAttrib2dv';
    
    static procedure VertexAttrib2f(index: UInt32; x: single; y: single);
    external 'opengl32.dll' name 'glVertexAttrib2f';
    
    static procedure VertexAttrib2fv(index: UInt32; v: ^single);
    external 'opengl32.dll' name 'glVertexAttrib2fv';
    
    static procedure VertexAttrib2s(index: UInt32; x: Int16; y: Int16);
    external 'opengl32.dll' name 'glVertexAttrib2s';
    
    static procedure VertexAttrib2sv(index: UInt32; v: ^Int16);
    external 'opengl32.dll' name 'glVertexAttrib2sv';
    
    static procedure VertexAttrib3d(index: UInt32; x: real; y: real; z: real);
    external 'opengl32.dll' name 'glVertexAttrib3d';
    
    static procedure VertexAttrib3dv(index: UInt32; v: ^real);
    external 'opengl32.dll' name 'glVertexAttrib3dv';
    
    static procedure VertexAttrib3f(index: UInt32; x: single; y: single; z: single);
    external 'opengl32.dll' name 'glVertexAttrib3f';
    
    static procedure VertexAttrib3fv(index: UInt32; v: ^single);
    external 'opengl32.dll' name 'glVertexAttrib3fv';
    
    static procedure VertexAttrib3s(index: UInt32; x: Int16; y: Int16; z: Int16);
    external 'opengl32.dll' name 'glVertexAttrib3s';
    
    static procedure VertexAttrib3sv(index: UInt32; v: ^Int16);
    external 'opengl32.dll' name 'glVertexAttrib3sv';
    
    static procedure VertexAttrib4Nbv(index: UInt32; v: ^SByte);
    external 'opengl32.dll' name 'glVertexAttrib4Nbv';
    
    static procedure VertexAttrib4Niv(index: UInt32; v: ^Int32);
    external 'opengl32.dll' name 'glVertexAttrib4Niv';
    
    static procedure VertexAttrib4Nsv(index: UInt32; v: ^Int16);
    external 'opengl32.dll' name 'glVertexAttrib4Nsv';
    
    static procedure VertexAttrib4Nub(index: UInt32; x: Byte; y: Byte; z: Byte; w: Byte);
    external 'opengl32.dll' name 'glVertexAttrib4Nub';
    
    static procedure VertexAttrib4Nubv(index: UInt32; v: ^Byte);
    external 'opengl32.dll' name 'glVertexAttrib4Nubv';
    
    static procedure VertexAttrib4Nuiv(index: UInt32; v: ^UInt32);
    external 'opengl32.dll' name 'glVertexAttrib4Nuiv';
    
    static procedure VertexAttrib4Nusv(index: UInt32; v: ^UInt16);
    external 'opengl32.dll' name 'glVertexAttrib4Nusv';
    
    static procedure VertexAttrib4bv(index: UInt32; v: ^SByte);
    external 'opengl32.dll' name 'glVertexAttrib4bv';
    
    static procedure VertexAttrib4d(index: UInt32; x: real; y: real; z: real; w: real);
    external 'opengl32.dll' name 'glVertexAttrib4d';
    
    static procedure VertexAttrib4dv(index: UInt32; v: ^real);
    external 'opengl32.dll' name 'glVertexAttrib4dv';
    
    static procedure VertexAttrib4f(index: UInt32; x: single; y: single; z: single; w: single);
    external 'opengl32.dll' name 'glVertexAttrib4f';
    
    static procedure VertexAttrib4fv(index: UInt32; v: ^single);
    external 'opengl32.dll' name 'glVertexAttrib4fv';
    
    static procedure VertexAttrib4iv(index: UInt32; v: ^Int32);
    external 'opengl32.dll' name 'glVertexAttrib4iv';
    
    static procedure VertexAttrib4s(index: UInt32; x: Int16; y: Int16; z: Int16; w: Int16);
    external 'opengl32.dll' name 'glVertexAttrib4s';
    
    static procedure VertexAttrib4sv(index: UInt32; v: ^Int16);
    external 'opengl32.dll' name 'glVertexAttrib4sv';
    
    static procedure VertexAttrib4ubv(index: UInt32; v: ^Byte);
    external 'opengl32.dll' name 'glVertexAttrib4ubv';
    
    static procedure VertexAttrib4uiv(index: UInt32; v: ^UInt32);
    external 'opengl32.dll' name 'glVertexAttrib4uiv';
    
    static procedure VertexAttrib4usv(index: UInt32; v: ^UInt16);
    external 'opengl32.dll' name 'glVertexAttrib4usv';
    
    static procedure VertexAttribPointer(index: UInt32; size: Int32; &type: UInt32; normalized: boolean; stride: Int32; _pointer: pointer);
    external 'opengl32.dll' name 'glVertexAttribPointer';
    
    static procedure ColorMaski(index: UInt32; r: boolean; g: boolean; b: boolean; a: boolean);
    external 'opengl32.dll' name 'glColorMaski';
    
    static procedure GetBooleani_v(target: UInt32; index: UInt32; data: ^boolean);
    external 'opengl32.dll' name 'glGetBooleani_v';
    
    static procedure Enablei(target: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glEnablei';
    
    static procedure Disablei(target: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glDisablei';
    
    static function IsEnabledi(target: UInt32; index: UInt32): boolean;
    external 'opengl32.dll' name 'glIsEnabledi';
    
    static procedure BeginTransformFeedback(primitiveMode: UInt32);
    external 'opengl32.dll' name 'glBeginTransformFeedback';
    
    static procedure EndTransformFeedback;
    external 'opengl32.dll' name 'glEndTransformFeedback';
    
    static procedure TransformFeedbackVaryings(&program: UInt32; count: Int32; varyings: ^^SByte; bufferMode: UInt32);
    external 'opengl32.dll' name 'glTransformFeedbackVaryings';
    
    static procedure GetTransformFeedbackVarying(&program: UInt32; index: UInt32; bufSize: Int32; length: ^Int32; size: ^Int32; &type: ^UInt32; name: ^SByte);
    external 'opengl32.dll' name 'glGetTransformFeedbackVarying';
    
    static procedure ClampColor(target: UInt32; clamp: UInt32);
    external 'opengl32.dll' name 'glClampColor';
    
    static procedure BeginConditionalRender(id: UInt32; mode: UInt32);
    external 'opengl32.dll' name 'glBeginConditionalRender';
    
    static procedure EndConditionalRender;
    external 'opengl32.dll' name 'glEndConditionalRender';
    
    static procedure VertexAttribIPointer(index: UInt32; size: Int32; &type: UInt32; stride: Int32; _pointer: pointer);
    external 'opengl32.dll' name 'glVertexAttribIPointer';
    
    static procedure GetVertexAttribIiv(index: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetVertexAttribIiv';
    
    static procedure GetVertexAttribIuiv(index: UInt32; pname: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetVertexAttribIuiv';
    
    static procedure VertexAttribI1i(index: UInt32; x: Int32);
    external 'opengl32.dll' name 'glVertexAttribI1i';
    
    static procedure VertexAttribI2i(index: UInt32; x: Int32; y: Int32);
    external 'opengl32.dll' name 'glVertexAttribI2i';
    
    static procedure VertexAttribI3i(index: UInt32; x: Int32; y: Int32; z: Int32);
    external 'opengl32.dll' name 'glVertexAttribI3i';
    
    static procedure VertexAttribI4i(index: UInt32; x: Int32; y: Int32; z: Int32; w: Int32);
    external 'opengl32.dll' name 'glVertexAttribI4i';
    
    static procedure VertexAttribI1ui(index: UInt32; x: UInt32);
    external 'opengl32.dll' name 'glVertexAttribI1ui';
    
    static procedure VertexAttribI2ui(index: UInt32; x: UInt32; y: UInt32);
    external 'opengl32.dll' name 'glVertexAttribI2ui';
    
    static procedure VertexAttribI3ui(index: UInt32; x: UInt32; y: UInt32; z: UInt32);
    external 'opengl32.dll' name 'glVertexAttribI3ui';
    
    static procedure VertexAttribI4ui(index: UInt32; x: UInt32; y: UInt32; z: UInt32; w: UInt32);
    external 'opengl32.dll' name 'glVertexAttribI4ui';
    
    static procedure VertexAttribI1iv(index: UInt32; v: ^Int32);
    external 'opengl32.dll' name 'glVertexAttribI1iv';
    
    static procedure VertexAttribI2iv(index: UInt32; v: ^Int32);
    external 'opengl32.dll' name 'glVertexAttribI2iv';
    
    static procedure VertexAttribI3iv(index: UInt32; v: ^Int32);
    external 'opengl32.dll' name 'glVertexAttribI3iv';
    
    static procedure VertexAttribI4iv(index: UInt32; v: ^Int32);
    external 'opengl32.dll' name 'glVertexAttribI4iv';
    
    static procedure VertexAttribI1uiv(index: UInt32; v: ^UInt32);
    external 'opengl32.dll' name 'glVertexAttribI1uiv';
    
    static procedure VertexAttribI2uiv(index: UInt32; v: ^UInt32);
    external 'opengl32.dll' name 'glVertexAttribI2uiv';
    
    static procedure VertexAttribI3uiv(index: UInt32; v: ^UInt32);
    external 'opengl32.dll' name 'glVertexAttribI3uiv';
    
    static procedure VertexAttribI4uiv(index: UInt32; v: ^UInt32);
    external 'opengl32.dll' name 'glVertexAttribI4uiv';
    
    static procedure VertexAttribI4bv(index: UInt32; v: ^SByte);
    external 'opengl32.dll' name 'glVertexAttribI4bv';
    
    static procedure VertexAttribI4sv(index: UInt32; v: ^Int16);
    external 'opengl32.dll' name 'glVertexAttribI4sv';
    
    static procedure VertexAttribI4ubv(index: UInt32; v: ^Byte);
    external 'opengl32.dll' name 'glVertexAttribI4ubv';
    
    static procedure VertexAttribI4usv(index: UInt32; v: ^UInt16);
    external 'opengl32.dll' name 'glVertexAttribI4usv';
    
    static procedure BindFragDataLocation(&program: UInt32; color: UInt32; name: ^SByte);
    external 'opengl32.dll' name 'glBindFragDataLocation';
    
    static function GetFragDataLocation(&program: UInt32; name: ^SByte): Int32;
    external 'opengl32.dll' name 'glGetFragDataLocation';
    
    static procedure TexParameterIiv(target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glTexParameterIiv';
    
    static procedure TexParameterIuiv(target: UInt32; pname: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glTexParameterIuiv';
    
    static procedure GetTexParameterIiv(target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetTexParameterIiv';
    
    static procedure GetTexParameterIuiv(target: UInt32; pname: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetTexParameterIuiv';
    
    static procedure ClearBufferiv(buffer: UInt32; drawbuffer: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glClearBufferiv';
    
    static procedure ClearBufferuiv(buffer: UInt32; drawbuffer: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glClearBufferuiv';
    
    static procedure ClearBufferfv(buffer: UInt32; drawbuffer: Int32; value: ^single);
    external 'opengl32.dll' name 'glClearBufferfv';
    
    static procedure ClearBufferfi(buffer: UInt32; drawbuffer: Int32; depth: single; stencil: Int32);
    external 'opengl32.dll' name 'glClearBufferfi';
    
    static function GetStringi(name: UInt32; index: UInt32): ^Byte;
    external 'opengl32.dll' name 'glGetStringi';
    
    static function IsRenderbuffer(renderbuffer: UInt32): boolean;
    external 'opengl32.dll' name 'glIsRenderbuffer';
    
    static procedure BindRenderbuffer(target: UInt32; renderbuffer: UInt32);
    external 'opengl32.dll' name 'glBindRenderbuffer';
    
    static procedure DeleteRenderbuffers(n: Int32; renderbuffers: ^UInt32);
    external 'opengl32.dll' name 'glDeleteRenderbuffers';
    
    static procedure GenRenderbuffers(n: Int32; renderbuffers: ^UInt32);
    external 'opengl32.dll' name 'glGenRenderbuffers';
    
    static procedure RenderbufferStorage(target: UInt32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glRenderbufferStorage';
    
    static procedure GetRenderbufferParameteriv(target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetRenderbufferParameteriv';
    
    static function IsFramebuffer(framebuffer: UInt32): boolean;
    external 'opengl32.dll' name 'glIsFramebuffer';
    
    static procedure BindFramebuffer(target: UInt32; framebuffer: UInt32);
    external 'opengl32.dll' name 'glBindFramebuffer';
    
    static procedure DeleteFramebuffers(n: Int32; framebuffers: ^UInt32);
    external 'opengl32.dll' name 'glDeleteFramebuffers';
    
    static procedure GenFramebuffers(n: Int32; framebuffers: ^UInt32);
    external 'opengl32.dll' name 'glGenFramebuffers';
    
    static function CheckFramebufferStatus(target: UInt32): UInt32;
    external 'opengl32.dll' name 'glCheckFramebufferStatus';
    
    static procedure FramebufferTexture1D(target: UInt32; attachment: UInt32; textarget: UInt32; texture: UInt32; level: Int32);
    external 'opengl32.dll' name 'glFramebufferTexture1D';
    
    static procedure FramebufferTexture2D(target: UInt32; attachment: UInt32; textarget: UInt32; texture: UInt32; level: Int32);
    external 'opengl32.dll' name 'glFramebufferTexture2D';
    
    static procedure FramebufferTexture3D(target: UInt32; attachment: UInt32; textarget: UInt32; texture: UInt32; level: Int32; zoffset: Int32);
    external 'opengl32.dll' name 'glFramebufferTexture3D';
    
    static procedure FramebufferRenderbuffer(target: UInt32; attachment: UInt32; renderbuffertarget: UInt32; renderbuffer: UInt32);
    external 'opengl32.dll' name 'glFramebufferRenderbuffer';
    
    static procedure GetFramebufferAttachmentParameteriv(target: UInt32; attachment: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetFramebufferAttachmentParameteriv';
    
    static procedure GenerateMipmap(target: UInt32);
    external 'opengl32.dll' name 'glGenerateMipmap';
    
    static procedure BlitFramebuffer(srcX0: Int32; srcY0: Int32; srcX1: Int32; srcY1: Int32; dstX0: Int32; dstY0: Int32; dstX1: Int32; dstY1: Int32; mask: UInt32; filter: UInt32);
    external 'opengl32.dll' name 'glBlitFramebuffer';
    
    static procedure RenderbufferStorageMultisample(target: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glRenderbufferStorageMultisample';
    
    static procedure FramebufferTextureLayer(target: UInt32; attachment: UInt32; texture: UInt32; level: Int32; layer: Int32);
    external 'opengl32.dll' name 'glFramebufferTextureLayer';
    
    static procedure BindVertexArray(&array: UInt32);
    external 'opengl32.dll' name 'glBindVertexArray';
    
    static procedure DeleteVertexArrays(n: Int32; arrays: ^UInt32);
    external 'opengl32.dll' name 'glDeleteVertexArrays';
    
    static procedure GenVertexArrays(n: Int32; arrays: ^UInt32);
    external 'opengl32.dll' name 'glGenVertexArrays';
    
    static function IsVertexArray(&array: UInt32): boolean;
    external 'opengl32.dll' name 'glIsVertexArray';
    
    static procedure DrawArraysInstanced(mode: UInt32; first: Int32; count: Int32; instancecount: Int32);
    external 'opengl32.dll' name 'glDrawArraysInstanced';
    
    static procedure DrawElementsInstanced(mode: UInt32; count: Int32; &type: UInt32; indices: pointer; instancecount: Int32);
    external 'opengl32.dll' name 'glDrawElementsInstanced';
    
    static procedure TexBuffer(target: UInt32; internalformat: UInt32; buffer: UInt32);
    external 'opengl32.dll' name 'glTexBuffer';
    
    static procedure PrimitiveRestartIndex(index: UInt32);
    external 'opengl32.dll' name 'glPrimitiveRestartIndex';
    
    static procedure DrawElementsBaseVertex(mode: UInt32; count: Int32; &type: UInt32; indices: pointer; basevertex: Int32);
    external 'opengl32.dll' name 'glDrawElementsBaseVertex';
    
    static procedure DrawRangeElementsBaseVertex(mode: UInt32; start: UInt32; &end: UInt32; count: Int32; &type: UInt32; indices: pointer; basevertex: Int32);
    external 'opengl32.dll' name 'glDrawRangeElementsBaseVertex';
    
    static procedure DrawElementsInstancedBaseVertex(mode: UInt32; count: Int32; &type: UInt32; indices: pointer; instancecount: Int32; basevertex: Int32);
    external 'opengl32.dll' name 'glDrawElementsInstancedBaseVertex';
    
    static procedure MultiDrawElementsBaseVertex(mode: UInt32; count: ^Int32; &type: UInt32; indices: ^IntPtr; drawcount: Int32; basevertex: ^Int32);
    external 'opengl32.dll' name 'glMultiDrawElementsBaseVertex';
    
    static procedure ProvokingVertex(mode: UInt32);
    external 'opengl32.dll' name 'glProvokingVertex';
    
    static procedure FramebufferTexture(target: UInt32; attachment: UInt32; texture: UInt32; level: Int32);
    external 'opengl32.dll' name 'glFramebufferTexture';
    
    static procedure TexImage2DMultisample(target: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32; fixedsamplelocations: boolean);
    external 'opengl32.dll' name 'glTexImage2DMultisample';
    
    static procedure TexImage3DMultisample(target: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32; depth: Int32; fixedsamplelocations: boolean);
    external 'opengl32.dll' name 'glTexImage3DMultisample';
    
    static procedure GetMultisamplefv(pname: UInt32; index: UInt32; val: ^single);
    external 'opengl32.dll' name 'glGetMultisamplefv';
    
    static procedure SampleMaski(maskNumber: UInt32; mask: UInt32);
    external 'opengl32.dll' name 'glSampleMaski';
    
    static procedure BindFragDataLocationIndexed(&program: UInt32; colorNumber: UInt32; index: UInt32; name: ^SByte);
    external 'opengl32.dll' name 'glBindFragDataLocationIndexed';
    
    static function GetFragDataIndex(&program: UInt32; name: ^SByte): Int32;
    external 'opengl32.dll' name 'glGetFragDataIndex';
    
    static procedure GenSamplers(count: Int32; samplers: ^UInt32);
    external 'opengl32.dll' name 'glGenSamplers';
    
    static procedure DeleteSamplers(count: Int32; samplers: ^UInt32);
    external 'opengl32.dll' name 'glDeleteSamplers';
    
    static function IsSampler(sampler: UInt32): boolean;
    external 'opengl32.dll' name 'glIsSampler';
    
    static procedure BindSampler(&unit: UInt32; sampler: UInt32);
    external 'opengl32.dll' name 'glBindSampler';
    
    static procedure SamplerParameteri(sampler: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glSamplerParameteri';
    
    static procedure SamplerParameteriv(sampler: UInt32; pname: UInt32; param: ^Int32);
    external 'opengl32.dll' name 'glSamplerParameteriv';
    
    static procedure SamplerParameterf(sampler: UInt32; pname: UInt32; param: single);
    external 'opengl32.dll' name 'glSamplerParameterf';
    
    static procedure SamplerParameterfv(sampler: UInt32; pname: UInt32; param: ^single);
    external 'opengl32.dll' name 'glSamplerParameterfv';
    
    static procedure SamplerParameterIiv(sampler: UInt32; pname: UInt32; param: ^Int32);
    external 'opengl32.dll' name 'glSamplerParameterIiv';
    
    static procedure SamplerParameterIuiv(sampler: UInt32; pname: UInt32; param: ^UInt32);
    external 'opengl32.dll' name 'glSamplerParameterIuiv';
    
    static procedure GetSamplerParameteriv(sampler: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetSamplerParameteriv';
    
    static procedure GetSamplerParameterIiv(sampler: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetSamplerParameterIiv';
    
    static procedure GetSamplerParameterfv(sampler: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetSamplerParameterfv';
    
    static procedure GetSamplerParameterIuiv(sampler: UInt32; pname: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetSamplerParameterIuiv';
    
    static procedure VertexAttribDivisor(index: UInt32; divisor: UInt32);
    external 'opengl32.dll' name 'glVertexAttribDivisor';
    
    static procedure VertexAttribP1ui(index: UInt32; &type: UInt32; normalized: boolean; value: UInt32);
    external 'opengl32.dll' name 'glVertexAttribP1ui';
    
    static procedure VertexAttribP1uiv(index: UInt32; &type: UInt32; normalized: boolean; value: ^UInt32);
    external 'opengl32.dll' name 'glVertexAttribP1uiv';
    
    static procedure VertexAttribP2ui(index: UInt32; &type: UInt32; normalized: boolean; value: UInt32);
    external 'opengl32.dll' name 'glVertexAttribP2ui';
    
    static procedure VertexAttribP2uiv(index: UInt32; &type: UInt32; normalized: boolean; value: ^UInt32);
    external 'opengl32.dll' name 'glVertexAttribP2uiv';
    
    static procedure VertexAttribP3ui(index: UInt32; &type: UInt32; normalized: boolean; value: UInt32);
    external 'opengl32.dll' name 'glVertexAttribP3ui';
    
    static procedure VertexAttribP3uiv(index: UInt32; &type: UInt32; normalized: boolean; value: ^UInt32);
    external 'opengl32.dll' name 'glVertexAttribP3uiv';
    
    static procedure VertexAttribP4ui(index: UInt32; &type: UInt32; normalized: boolean; value: UInt32);
    external 'opengl32.dll' name 'glVertexAttribP4ui';
    
    static procedure VertexAttribP4uiv(index: UInt32; &type: UInt32; normalized: boolean; value: ^UInt32);
    external 'opengl32.dll' name 'glVertexAttribP4uiv';
    
    static procedure MinSampleShading(value: single);
    external 'opengl32.dll' name 'glMinSampleShading';
    
    static procedure BlendEquationi(buf: UInt32; mode: UInt32);
    external 'opengl32.dll' name 'glBlendEquationi';
    
    static procedure BlendEquationSeparatei(buf: UInt32; modeRGB: UInt32; modeAlpha: UInt32);
    external 'opengl32.dll' name 'glBlendEquationSeparatei';
    
    static procedure BlendFunci(buf: UInt32; src: UInt32; dst: UInt32);
    external 'opengl32.dll' name 'glBlendFunci';
    
    static procedure BlendFuncSeparatei(buf: UInt32; srcRGB: UInt32; dstRGB: UInt32; srcAlpha: UInt32; dstAlpha: UInt32);
    external 'opengl32.dll' name 'glBlendFuncSeparatei';
    
    static procedure DrawArraysIndirect(mode: UInt32; indirect: pointer);
    external 'opengl32.dll' name 'glDrawArraysIndirect';
    
    static procedure DrawElementsIndirect(mode: UInt32; &type: UInt32; indirect: pointer);
    external 'opengl32.dll' name 'glDrawElementsIndirect';
    
    static procedure PatchParameteri(pname: UInt32; value: Int32);
    external 'opengl32.dll' name 'glPatchParameteri';
    
    static procedure PatchParameterfv(pname: UInt32; values: ^single);
    external 'opengl32.dll' name 'glPatchParameterfv';
    
    static procedure BindTransformFeedback(target: UInt32; id: UInt32);
    external 'opengl32.dll' name 'glBindTransformFeedback';
    
    static procedure DeleteTransformFeedbacks(n: Int32; ids: ^UInt32);
    external 'opengl32.dll' name 'glDeleteTransformFeedbacks';
    
    static procedure GenTransformFeedbacks(n: Int32; ids: ^UInt32);
    external 'opengl32.dll' name 'glGenTransformFeedbacks';
    
    static function IsTransformFeedback(id: UInt32): boolean;
    external 'opengl32.dll' name 'glIsTransformFeedback';
    
    static procedure PauseTransformFeedback;
    external 'opengl32.dll' name 'glPauseTransformFeedback';
    
    static procedure ResumeTransformFeedback;
    external 'opengl32.dll' name 'glResumeTransformFeedback';
    
    static procedure DrawTransformFeedback(mode: UInt32; id: UInt32);
    external 'opengl32.dll' name 'glDrawTransformFeedback';
    
    static procedure DrawTransformFeedbackStream(mode: UInt32; id: UInt32; stream: UInt32);
    external 'opengl32.dll' name 'glDrawTransformFeedbackStream';
    
    static procedure DepthRangef(n: single; f: single);
    external 'opengl32.dll' name 'glDepthRangef';
    
    static procedure ClearDepthf(d: single);
    external 'opengl32.dll' name 'glClearDepthf';
    
    static procedure VertexAttribL1d(index: UInt32; x: real);
    external 'opengl32.dll' name 'glVertexAttribL1d';
    
    static procedure VertexAttribL2d(index: UInt32; x: real; y: real);
    external 'opengl32.dll' name 'glVertexAttribL2d';
    
    static procedure VertexAttribL3d(index: UInt32; x: real; y: real; z: real);
    external 'opengl32.dll' name 'glVertexAttribL3d';
    
    static procedure VertexAttribL4d(index: UInt32; x: real; y: real; z: real; w: real);
    external 'opengl32.dll' name 'glVertexAttribL4d';
    
    static procedure VertexAttribL1dv(index: UInt32; v: ^real);
    external 'opengl32.dll' name 'glVertexAttribL1dv';
    
    static procedure VertexAttribL2dv(index: UInt32; v: ^real);
    external 'opengl32.dll' name 'glVertexAttribL2dv';
    
    static procedure VertexAttribL3dv(index: UInt32; v: ^real);
    external 'opengl32.dll' name 'glVertexAttribL3dv';
    
    static procedure VertexAttribL4dv(index: UInt32; v: ^real);
    external 'opengl32.dll' name 'glVertexAttribL4dv';
    
    static procedure VertexAttribLPointer(index: UInt32; size: Int32; &type: UInt32; stride: Int32; _pointer: pointer);
    external 'opengl32.dll' name 'glVertexAttribLPointer';
    
    static procedure GetVertexAttribLdv(index: UInt32; pname: UInt32; &params: ^real);
    external 'opengl32.dll' name 'glGetVertexAttribLdv';
    
    static procedure ViewportArrayv(first: UInt32; count: Int32; v: ^single);
    external 'opengl32.dll' name 'glViewportArrayv';
    
    static procedure ViewportIndexedf(index: UInt32; x: single; y: single; w: single; h: single);
    external 'opengl32.dll' name 'glViewportIndexedf';
    
    static procedure ViewportIndexedfv(index: UInt32; v: ^single);
    external 'opengl32.dll' name 'glViewportIndexedfv';
    
    static procedure ScissorArrayv(first: UInt32; count: Int32; v: ^Int32);
    external 'opengl32.dll' name 'glScissorArrayv';
    
    static procedure ScissorIndexed(index: UInt32; left: Int32; bottom: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glScissorIndexed';
    
    static procedure ScissorIndexedv(index: UInt32; v: ^Int32);
    external 'opengl32.dll' name 'glScissorIndexedv';
    
    static procedure DepthRangeArrayv(first: UInt32; count: Int32; v: ^real);
    external 'opengl32.dll' name 'glDepthRangeArrayv';
    
    static procedure DepthRangeIndexed(index: UInt32; n: real; f: real);
    external 'opengl32.dll' name 'glDepthRangeIndexed';
    
    static procedure GetFloati_v(target: UInt32; index: UInt32; data: ^single);
    external 'opengl32.dll' name 'glGetFloati_v';
    
    static procedure GetDoublei_v(target: UInt32; index: UInt32; data: ^real);
    external 'opengl32.dll' name 'glGetDoublei_v';
    
    static procedure DrawArraysInstancedBaseInstance(mode: UInt32; first: Int32; count: Int32; instancecount: Int32; baseinstance: UInt32);
    external 'opengl32.dll' name 'glDrawArraysInstancedBaseInstance';
    
    static procedure DrawElementsInstancedBaseInstance(mode: UInt32; count: Int32; &type: UInt32; indices: pointer; instancecount: Int32; baseinstance: UInt32);
    external 'opengl32.dll' name 'glDrawElementsInstancedBaseInstance';
    
    static procedure DrawElementsInstancedBaseVertexBaseInstance(mode: UInt32; count: Int32; &type: UInt32; indices: pointer; instancecount: Int32; basevertex: Int32; baseinstance: UInt32);
    external 'opengl32.dll' name 'glDrawElementsInstancedBaseVertexBaseInstance';
    
    static procedure GetInternalformativ(target: UInt32; internalformat: UInt32; pname: UInt32; bufSize: Int32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetInternalformativ';
    
    static procedure BindImageTexture(&unit: UInt32; texture: UInt32; level: Int32; layered: boolean; layer: Int32; access: UInt32; format: UInt32);
    external 'opengl32.dll' name 'glBindImageTexture';
    
    static procedure TexStorage1D(target: UInt32; levels: Int32; internalformat: UInt32; width: Int32);
    external 'opengl32.dll' name 'glTexStorage1D';
    
    static procedure TexStorage2D(target: UInt32; levels: Int32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glTexStorage2D';
    
    static procedure TexStorage3D(target: UInt32; levels: Int32; internalformat: UInt32; width: Int32; height: Int32; depth: Int32);
    external 'opengl32.dll' name 'glTexStorage3D';
    
    static procedure DrawTransformFeedbackInstanced(mode: UInt32; id: UInt32; instancecount: Int32);
    external 'opengl32.dll' name 'glDrawTransformFeedbackInstanced';
    
    static procedure DrawTransformFeedbackStreamInstanced(mode: UInt32; id: UInt32; stream: UInt32; instancecount: Int32);
    external 'opengl32.dll' name 'glDrawTransformFeedbackStreamInstanced';
    
    static procedure DispatchCompute(num_groups_x: UInt32; num_groups_y: UInt32; num_groups_z: UInt32);
    external 'opengl32.dll' name 'glDispatchCompute';
    
    static procedure DispatchComputeIndirect(indirect: IntPtr);
    external 'opengl32.dll' name 'glDispatchComputeIndirect';
    
    static procedure CopyImageSubData(srcName: UInt32; srcTarget: UInt32; srcLevel: Int32; srcX: Int32; srcY: Int32; srcZ: Int32; dstName: UInt32; dstTarget: UInt32; dstLevel: Int32; dstX: Int32; dstY: Int32; dstZ: Int32; srcWidth: Int32; srcHeight: Int32; srcDepth: Int32);
    external 'opengl32.dll' name 'glCopyImageSubData';
    
    static procedure FramebufferParameteri(target: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glFramebufferParameteri';
    
    static procedure GetFramebufferParameteriv(target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetFramebufferParameteriv';
    
    static procedure GetInternalformati64v(target: UInt32; internalformat: UInt32; pname: UInt32; bufSize: Int32; &params: ^Int64);
    external 'opengl32.dll' name 'glGetInternalformati64v';
    
    static procedure InvalidateTexSubImage(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32);
    external 'opengl32.dll' name 'glInvalidateTexSubImage';
    
    static procedure InvalidateTexImage(texture: UInt32; level: Int32);
    external 'opengl32.dll' name 'glInvalidateTexImage';
    
    static procedure InvalidateFramebuffer(target: UInt32; numAttachments: Int32; attachments: ^UInt32);
    external 'opengl32.dll' name 'glInvalidateFramebuffer';
    
    static procedure InvalidateSubFramebuffer(target: UInt32; numAttachments: Int32; attachments: ^UInt32; x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glInvalidateSubFramebuffer';
    
    static procedure MultiDrawArraysIndirect(mode: UInt32; indirect: pointer; drawcount: Int32; stride: Int32);
    external 'opengl32.dll' name 'glMultiDrawArraysIndirect';
    
    static procedure MultiDrawElementsIndirect(mode: UInt32; &type: UInt32; indirect: pointer; drawcount: Int32; stride: Int32);
    external 'opengl32.dll' name 'glMultiDrawElementsIndirect';
    
    static procedure TexBufferRange(target: UInt32; internalformat: UInt32; buffer: UInt32; offset: IntPtr; size: UIntPtr);
    external 'opengl32.dll' name 'glTexBufferRange';
    
    static procedure TexStorage2DMultisample(target: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32; fixedsamplelocations: boolean);
    external 'opengl32.dll' name 'glTexStorage2DMultisample';
    
    static procedure TexStorage3DMultisample(target: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32; depth: Int32; fixedsamplelocations: boolean);
    external 'opengl32.dll' name 'glTexStorage3DMultisample';
    
    static procedure TextureView(texture: UInt32; target: UInt32; origtexture: UInt32; internalformat: UInt32; minlevel: UInt32; numlevels: UInt32; minlayer: UInt32; numlayers: UInt32);
    external 'opengl32.dll' name 'glTextureView';
    
    static procedure BindVertexBuffer(bindingindex: UInt32; buffer: UInt32; offset: IntPtr; stride: Int32);
    external 'opengl32.dll' name 'glBindVertexBuffer';
    
    static procedure VertexAttribFormat(attribindex: UInt32; size: Int32; &type: UInt32; normalized: boolean; relativeoffset: UInt32);
    external 'opengl32.dll' name 'glVertexAttribFormat';
    
    static procedure VertexAttribIFormat(attribindex: UInt32; size: Int32; &type: UInt32; relativeoffset: UInt32);
    external 'opengl32.dll' name 'glVertexAttribIFormat';
    
    static procedure VertexAttribLFormat(attribindex: UInt32; size: Int32; &type: UInt32; relativeoffset: UInt32);
    external 'opengl32.dll' name 'glVertexAttribLFormat';
    
    static procedure VertexAttribBinding(attribindex: UInt32; bindingindex: UInt32);
    external 'opengl32.dll' name 'glVertexAttribBinding';
    
    static procedure VertexBindingDivisor(bindingindex: UInt32; divisor: UInt32);
    external 'opengl32.dll' name 'glVertexBindingDivisor';
    
    static procedure DebugMessageControl(source: UInt32; &type: UInt32; severity: UInt32; count: Int32; ids: ^UInt32; enabled: boolean);
    external 'opengl32.dll' name 'glDebugMessageControl';
    
    static procedure DebugMessageInsert(source: UInt32; &type: UInt32; id: UInt32; severity: UInt32; length: Int32; buf: ^SByte);
    external 'opengl32.dll' name 'glDebugMessageInsert';
    
    static procedure DebugMessageCallback(callback: GLDEBUGPROC; userParam: pointer);
    external 'opengl32.dll' name 'glDebugMessageCallback';
    
    static function GetDebugMessageLog(count: UInt32; bufSize: Int32; sources: ^UInt32; types: ^UInt32; ids: ^UInt32; severities: ^UInt32; lengths: ^Int32; messageLog: ^SByte): UInt32;
    external 'opengl32.dll' name 'glGetDebugMessageLog';
    
    static procedure PushDebugGroup(source: UInt32; id: UInt32; length: Int32; message: ^SByte);
    external 'opengl32.dll' name 'glPushDebugGroup';
    
    static procedure PopDebugGroup;
    external 'opengl32.dll' name 'glPopDebugGroup';
    
    static procedure ObjectLabel(identifier: UInt32; name: UInt32; length: Int32; &label: ^SByte);
    external 'opengl32.dll' name 'glObjectLabel';
    
    static procedure GetObjectLabel(identifier: UInt32; name: UInt32; bufSize: Int32; length: ^Int32; &label: ^SByte);
    external 'opengl32.dll' name 'glGetObjectLabel';
    
    static procedure ObjectPtrLabel(ptr: pointer; length: Int32; &label: ^SByte);
    external 'opengl32.dll' name 'glObjectPtrLabel';
    
    static procedure GetObjectPtrLabel(ptr: pointer; bufSize: Int32; length: ^Int32; &label: ^SByte);
    external 'opengl32.dll' name 'glGetObjectPtrLabel';
    
    static procedure ClearTexImage(texture: UInt32; level: Int32; format: UInt32; &type: UInt32; data: pointer);
    external 'opengl32.dll' name 'glClearTexImage';
    
    static procedure ClearTexSubImage(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; format: UInt32; &type: UInt32; data: pointer);
    external 'opengl32.dll' name 'glClearTexSubImage';
    
    static procedure BindTextures(first: UInt32; count: Int32; textures: ^UInt32);
    external 'opengl32.dll' name 'glBindTextures';
    
    static procedure BindSamplers(first: UInt32; count: Int32; samplers: ^UInt32);
    external 'opengl32.dll' name 'glBindSamplers';
    
    static procedure BindImageTextures(first: UInt32; count: Int32; textures: ^UInt32);
    external 'opengl32.dll' name 'glBindImageTextures';
    
    static procedure BindVertexBuffers(first: UInt32; count: Int32; buffers: ^UInt32; offsets: ^IntPtr; strides: ^Int32);
    external 'opengl32.dll' name 'glBindVertexBuffers';
    
    static procedure ClipControl(origin: UInt32; depth: UInt32);
    external 'opengl32.dll' name 'glClipControl';
    
    static procedure CreateTransformFeedbacks(n: Int32; ids: ^UInt32);
    external 'opengl32.dll' name 'glCreateTransformFeedbacks';
    
    static procedure TransformFeedbackBufferBase(xfb: UInt32; index: UInt32; buffer: UInt32);
    external 'opengl32.dll' name 'glTransformFeedbackBufferBase';
    
    static procedure TransformFeedbackBufferRange(xfb: UInt32; index: UInt32; buffer: UInt32; offset: IntPtr; size: UIntPtr);
    external 'opengl32.dll' name 'glTransformFeedbackBufferRange';
    
    static procedure GetTransformFeedbackiv(xfb: UInt32; pname: UInt32; param: ^Int32);
    external 'opengl32.dll' name 'glGetTransformFeedbackiv';
    
    static procedure GetTransformFeedbacki_v(xfb: UInt32; pname: UInt32; index: UInt32; param: ^Int32);
    external 'opengl32.dll' name 'glGetTransformFeedbacki_v';
    
    static procedure GetTransformFeedbacki64_v(xfb: UInt32; pname: UInt32; index: UInt32; param: ^Int64);
    external 'opengl32.dll' name 'glGetTransformFeedbacki64_v';
    
    static procedure CreateFramebuffers(n: Int32; framebuffers: ^UInt32);
    external 'opengl32.dll' name 'glCreateFramebuffers';
    
    static procedure NamedFramebufferRenderbuffer(framebuffer: UInt32; attachment: UInt32; renderbuffertarget: UInt32; renderbuffer: UInt32);
    external 'opengl32.dll' name 'glNamedFramebufferRenderbuffer';
    
    static procedure NamedFramebufferParameteri(framebuffer: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glNamedFramebufferParameteri';
    
    static procedure NamedFramebufferTexture(framebuffer: UInt32; attachment: UInt32; texture: UInt32; level: Int32);
    external 'opengl32.dll' name 'glNamedFramebufferTexture';
    
    static procedure NamedFramebufferTextureLayer(framebuffer: UInt32; attachment: UInt32; texture: UInt32; level: Int32; layer: Int32);
    external 'opengl32.dll' name 'glNamedFramebufferTextureLayer';
    
    static procedure NamedFramebufferDrawBuffer(framebuffer: UInt32; buf: UInt32);
    external 'opengl32.dll' name 'glNamedFramebufferDrawBuffer';
    
    static procedure NamedFramebufferDrawBuffers(framebuffer: UInt32; n: Int32; bufs: ^UInt32);
    external 'opengl32.dll' name 'glNamedFramebufferDrawBuffers';
    
    static procedure NamedFramebufferReadBuffer(framebuffer: UInt32; src: UInt32);
    external 'opengl32.dll' name 'glNamedFramebufferReadBuffer';
    
    static procedure InvalidateNamedFramebufferData(framebuffer: UInt32; numAttachments: Int32; attachments: ^UInt32);
    external 'opengl32.dll' name 'glInvalidateNamedFramebufferData';
    
    static procedure InvalidateNamedFramebufferSubData(framebuffer: UInt32; numAttachments: Int32; attachments: ^UInt32; x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glInvalidateNamedFramebufferSubData';
    
    static procedure ClearNamedFramebufferiv(framebuffer: UInt32; buffer: UInt32; drawbuffer: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glClearNamedFramebufferiv';
    
    static procedure ClearNamedFramebufferuiv(framebuffer: UInt32; buffer: UInt32; drawbuffer: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glClearNamedFramebufferuiv';
    
    static procedure ClearNamedFramebufferfv(framebuffer: UInt32; buffer: UInt32; drawbuffer: Int32; value: ^single);
    external 'opengl32.dll' name 'glClearNamedFramebufferfv';
    
    static procedure ClearNamedFramebufferfi(framebuffer: UInt32; buffer: UInt32; drawbuffer: Int32; depth: single; stencil: Int32);
    external 'opengl32.dll' name 'glClearNamedFramebufferfi';
    
    static procedure BlitNamedFramebuffer(readFramebuffer: UInt32; drawFramebuffer: UInt32; srcX0: Int32; srcY0: Int32; srcX1: Int32; srcY1: Int32; dstX0: Int32; dstY0: Int32; dstX1: Int32; dstY1: Int32; mask: UInt32; filter: UInt32);
    external 'opengl32.dll' name 'glBlitNamedFramebuffer';
    
    static function CheckNamedFramebufferStatus(framebuffer: UInt32; target: UInt32): UInt32;
    external 'opengl32.dll' name 'glCheckNamedFramebufferStatus';
    
    static procedure GetNamedFramebufferParameteriv(framebuffer: UInt32; pname: UInt32; param: ^Int32);
    external 'opengl32.dll' name 'glGetNamedFramebufferParameteriv';
    
    static procedure GetNamedFramebufferAttachmentParameteriv(framebuffer: UInt32; attachment: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetNamedFramebufferAttachmentParameteriv';
    
    static procedure CreateRenderbuffers(n: Int32; renderbuffers: ^UInt32);
    external 'opengl32.dll' name 'glCreateRenderbuffers';
    
    static procedure NamedRenderbufferStorage(renderbuffer: UInt32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glNamedRenderbufferStorage';
    
    static procedure NamedRenderbufferStorageMultisample(renderbuffer: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glNamedRenderbufferStorageMultisample';
    
    static procedure GetNamedRenderbufferParameteriv(renderbuffer: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetNamedRenderbufferParameteriv';
    
    static procedure CreateTextures(target: UInt32; n: Int32; textures: ^UInt32);
    external 'opengl32.dll' name 'glCreateTextures';
    
    static procedure TextureBuffer(texture: UInt32; internalformat: UInt32; buffer: UInt32);
    external 'opengl32.dll' name 'glTextureBuffer';
    
    static procedure TextureBufferRange(texture: UInt32; internalformat: UInt32; buffer: UInt32; offset: IntPtr; size: UIntPtr);
    external 'opengl32.dll' name 'glTextureBufferRange';
    
    static procedure TextureStorage1D(texture: UInt32; levels: Int32; internalformat: UInt32; width: Int32);
    external 'opengl32.dll' name 'glTextureStorage1D';
    
    static procedure TextureStorage2D(texture: UInt32; levels: Int32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glTextureStorage2D';
    
    static procedure TextureStorage3D(texture: UInt32; levels: Int32; internalformat: UInt32; width: Int32; height: Int32; depth: Int32);
    external 'opengl32.dll' name 'glTextureStorage3D';
    
    static procedure TextureStorage2DMultisample(texture: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32; fixedsamplelocations: boolean);
    external 'opengl32.dll' name 'glTextureStorage2DMultisample';
    
    static procedure TextureStorage3DMultisample(texture: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32; depth: Int32; fixedsamplelocations: boolean);
    external 'opengl32.dll' name 'glTextureStorage3DMultisample';
    
    static procedure TextureSubImage1D(texture: UInt32; level: Int32; xoffset: Int32; width: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTextureSubImage1D';
    
    static procedure TextureSubImage2D(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; width: Int32; height: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTextureSubImage2D';
    
    static procedure TextureSubImage3D(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTextureSubImage3D';
    
    static procedure CompressedTextureSubImage1D(texture: UInt32; level: Int32; xoffset: Int32; width: Int32; format: UInt32; imageSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glCompressedTextureSubImage1D';
    
    static procedure CompressedTextureSubImage2D(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; width: Int32; height: Int32; format: UInt32; imageSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glCompressedTextureSubImage2D';
    
    static procedure CompressedTextureSubImage3D(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; format: UInt32; imageSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glCompressedTextureSubImage3D';
    
    static procedure CopyTextureSubImage1D(texture: UInt32; level: Int32; xoffset: Int32; x: Int32; y: Int32; width: Int32);
    external 'opengl32.dll' name 'glCopyTextureSubImage1D';
    
    static procedure CopyTextureSubImage2D(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glCopyTextureSubImage2D';
    
    static procedure CopyTextureSubImage3D(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glCopyTextureSubImage3D';
    
    static procedure TextureParameterf(texture: UInt32; pname: UInt32; param: single);
    external 'opengl32.dll' name 'glTextureParameterf';
    
    static procedure TextureParameterfv(texture: UInt32; pname: UInt32; param: ^single);
    external 'opengl32.dll' name 'glTextureParameterfv';
    
    static procedure TextureParameteri(texture: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glTextureParameteri';
    
    static procedure TextureParameterIiv(texture: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glTextureParameterIiv';
    
    static procedure TextureParameterIuiv(texture: UInt32; pname: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glTextureParameterIuiv';
    
    static procedure TextureParameteriv(texture: UInt32; pname: UInt32; param: ^Int32);
    external 'opengl32.dll' name 'glTextureParameteriv';
    
    static procedure GenerateTextureMipmap(texture: UInt32);
    external 'opengl32.dll' name 'glGenerateTextureMipmap';
    
    static procedure BindTextureUnit(&unit: UInt32; texture: UInt32);
    external 'opengl32.dll' name 'glBindTextureUnit';
    
    static procedure GetTextureImage(texture: UInt32; level: Int32; format: UInt32; &type: UInt32; bufSize: Int32; pixels: pointer);
    external 'opengl32.dll' name 'glGetTextureImage';
    
    static procedure GetCompressedTextureImage(texture: UInt32; level: Int32; bufSize: Int32; pixels: pointer);
    external 'opengl32.dll' name 'glGetCompressedTextureImage';
    
    static procedure GetTextureLevelParameterfv(texture: UInt32; level: Int32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetTextureLevelParameterfv';
    
    static procedure GetTextureLevelParameteriv(texture: UInt32; level: Int32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetTextureLevelParameteriv';
    
    static procedure GetTextureParameterfv(texture: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetTextureParameterfv';
    
    static procedure GetTextureParameterIiv(texture: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetTextureParameterIiv';
    
    static procedure GetTextureParameterIuiv(texture: UInt32; pname: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetTextureParameterIuiv';
    
    static procedure GetTextureParameteriv(texture: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetTextureParameteriv';
    
    static procedure CreateVertexArrays(n: Int32; arrays: ^UInt32);
    external 'opengl32.dll' name 'glCreateVertexArrays';
    
    static procedure DisableVertexArrayAttrib(vaobj: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glDisableVertexArrayAttrib';
    
    static procedure EnableVertexArrayAttrib(vaobj: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glEnableVertexArrayAttrib';
    
    static procedure VertexArrayElementBuffer(vaobj: UInt32; buffer: UInt32);
    external 'opengl32.dll' name 'glVertexArrayElementBuffer';
    
    static procedure VertexArrayVertexBuffer(vaobj: UInt32; bindingindex: UInt32; buffer: UInt32; offset: IntPtr; stride: Int32);
    external 'opengl32.dll' name 'glVertexArrayVertexBuffer';
    
    static procedure VertexArrayVertexBuffers(vaobj: UInt32; first: UInt32; count: Int32; buffers: ^UInt32; offsets: ^IntPtr; strides: ^Int32);
    external 'opengl32.dll' name 'glVertexArrayVertexBuffers';
    
    static procedure VertexArrayAttribBinding(vaobj: UInt32; attribindex: UInt32; bindingindex: UInt32);
    external 'opengl32.dll' name 'glVertexArrayAttribBinding';
    
    static procedure VertexArrayAttribFormat(vaobj: UInt32; attribindex: UInt32; size: Int32; &type: UInt32; normalized: boolean; relativeoffset: UInt32);
    external 'opengl32.dll' name 'glVertexArrayAttribFormat';
    
    static procedure VertexArrayAttribIFormat(vaobj: UInt32; attribindex: UInt32; size: Int32; &type: UInt32; relativeoffset: UInt32);
    external 'opengl32.dll' name 'glVertexArrayAttribIFormat';
    
    static procedure VertexArrayAttribLFormat(vaobj: UInt32; attribindex: UInt32; size: Int32; &type: UInt32; relativeoffset: UInt32);
    external 'opengl32.dll' name 'glVertexArrayAttribLFormat';
    
    static procedure VertexArrayBindingDivisor(vaobj: UInt32; bindingindex: UInt32; divisor: UInt32);
    external 'opengl32.dll' name 'glVertexArrayBindingDivisor';
    
    static procedure GetVertexArrayiv(vaobj: UInt32; pname: UInt32; param: ^Int32);
    external 'opengl32.dll' name 'glGetVertexArrayiv';
    
    static procedure GetVertexArrayIndexediv(vaobj: UInt32; index: UInt32; pname: UInt32; param: ^Int32);
    external 'opengl32.dll' name 'glGetVertexArrayIndexediv';
    
    static procedure GetVertexArrayIndexed64iv(vaobj: UInt32; index: UInt32; pname: UInt32; param: ^Int64);
    external 'opengl32.dll' name 'glGetVertexArrayIndexed64iv';
    
    static procedure CreateSamplers(n: Int32; samplers: ^UInt32);
    external 'opengl32.dll' name 'glCreateSamplers';
    
    static procedure GetTextureSubImage(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; format: UInt32; &type: UInt32; bufSize: Int32; pixels: pointer);
    external 'opengl32.dll' name 'glGetTextureSubImage';
    
    static procedure GetCompressedTextureSubImage(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; bufSize: Int32; pixels: pointer);
    external 'opengl32.dll' name 'glGetCompressedTextureSubImage';
    
    static function GetGraphicsResetStatus: UInt32;
    external 'opengl32.dll' name 'glGetGraphicsResetStatus';
    
    static procedure GetnCompressedTexImage(target: UInt32; lod: Int32; bufSize: Int32; pixels: pointer);
    external 'opengl32.dll' name 'glGetnCompressedTexImage';
    
    static procedure GetnTexImage(target: UInt32; level: Int32; format: UInt32; &type: UInt32; bufSize: Int32; pixels: pointer);
    external 'opengl32.dll' name 'glGetnTexImage';
    
    static procedure ReadnPixels(x: Int32; y: Int32; width: Int32; height: Int32; format: UInt32; &type: UInt32; bufSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glReadnPixels';
    
    static procedure TextureBarrier;
    external 'opengl32.dll' name 'glTextureBarrier';
    
    static procedure MultiDrawArraysIndirectCount(mode: UInt32; indirect: pointer; drawcount: IntPtr; maxdrawcount: Int32; stride: Int32);
    external 'opengl32.dll' name 'glMultiDrawArraysIndirectCount';
    
    static procedure MultiDrawElementsIndirectCount(mode: UInt32; &type: UInt32; indirect: pointer; drawcount: IntPtr; maxdrawcount: Int32; stride: Int32);
    external 'opengl32.dll' name 'glMultiDrawElementsIndirectCount';
    
    static procedure PolygonOffsetClamp(factor: single; units: single; clamp: single);
    external 'opengl32.dll' name 'glPolygonOffsetClamp';
    
    static procedure PrimitiveBoundingBoxARB(minX: single; minY: single; minZ: single; minW: single; maxX: single; maxY: single; maxZ: single; maxW: single);
    external 'opengl32.dll' name 'glPrimitiveBoundingBoxARB';
    
    static function GetTextureHandleARB(texture: UInt32): UInt64;
    external 'opengl32.dll' name 'glGetTextureHandleARB';
    
    static function GetTextureSamplerHandleARB(texture: UInt32; sampler: UInt32): UInt64;
    external 'opengl32.dll' name 'glGetTextureSamplerHandleARB';
    
    static procedure MakeTextureHandleResidentARB(handle: UInt64);
    external 'opengl32.dll' name 'glMakeTextureHandleResidentARB';
    
    static procedure MakeTextureHandleNonResidentARB(handle: UInt64);
    external 'opengl32.dll' name 'glMakeTextureHandleNonResidentARB';
    
    static function GetImageHandleARB(texture: UInt32; level: Int32; layered: boolean; layer: Int32; format: UInt32): UInt64;
    external 'opengl32.dll' name 'glGetImageHandleARB';
    
    static procedure MakeImageHandleResidentARB(handle: UInt64; access: UInt32);
    external 'opengl32.dll' name 'glMakeImageHandleResidentARB';
    
    static procedure MakeImageHandleNonResidentARB(handle: UInt64);
    external 'opengl32.dll' name 'glMakeImageHandleNonResidentARB';
    
    static procedure UniformHandleui64ARB(location: Int32; value: UInt64);
    external 'opengl32.dll' name 'glUniformHandleui64ARB';
    
    static procedure UniformHandleui64vARB(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniformHandleui64vARB';
    
    static procedure ProgramUniformHandleui64ARB(&program: UInt32; location: Int32; value: UInt64);
    external 'opengl32.dll' name 'glProgramUniformHandleui64ARB';
    
    static procedure ProgramUniformHandleui64vARB(&program: UInt32; location: Int32; count: Int32; values: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniformHandleui64vARB';
    
    static function IsTextureHandleResidentARB(handle: UInt64): boolean;
    external 'opengl32.dll' name 'glIsTextureHandleResidentARB';
    
    static function IsImageHandleResidentARB(handle: UInt64): boolean;
    external 'opengl32.dll' name 'glIsImageHandleResidentARB';
    
    static procedure VertexAttribL1ui64ARB(index: UInt32; x: UInt64);
    external 'opengl32.dll' name 'glVertexAttribL1ui64ARB';
    
    static procedure VertexAttribL1ui64vARB(index: UInt32; v: ^UInt64);
    external 'opengl32.dll' name 'glVertexAttribL1ui64vARB';
    
    static procedure GetVertexAttribLui64vARB(index: UInt32; pname: UInt32; &params: ^UInt64);
    external 'opengl32.dll' name 'glGetVertexAttribLui64vARB';
    
    static function CreateSyncFromCLeventARB(context: cl_context; &event: cl_event; flags: UInt32): GLsync;
    external 'opengl32.dll' name 'glCreateSyncFromCLeventARB';
    
    static procedure DispatchComputeGroupSizeARB(num_groups_x: UInt32; num_groups_y: UInt32; num_groups_z: UInt32; group_size_x: UInt32; group_size_y: UInt32; group_size_z: UInt32);
    external 'opengl32.dll' name 'glDispatchComputeGroupSizeARB';
    
    static procedure DebugMessageControlARB(source: UInt32; &type: UInt32; severity: UInt32; count: Int32; ids: ^UInt32; enabled: boolean);
    external 'opengl32.dll' name 'glDebugMessageControlARB';
    
    static procedure DebugMessageInsertARB(source: UInt32; &type: UInt32; id: UInt32; severity: UInt32; length: Int32; buf: ^SByte);
    external 'opengl32.dll' name 'glDebugMessageInsertARB';
    
    static procedure DebugMessageCallbackARB(callback: GLDEBUGPROC; userParam: pointer);
    external 'opengl32.dll' name 'glDebugMessageCallbackARB';
    
    static function GetDebugMessageLogARB(count: UInt32; bufSize: Int32; sources: ^UInt32; types: ^UInt32; ids: ^UInt32; severities: ^UInt32; lengths: ^Int32; messageLog: ^SByte): UInt32;
    external 'opengl32.dll' name 'glGetDebugMessageLogARB';
    
    static procedure BlendEquationiARB(buf: UInt32; mode: UInt32);
    external 'opengl32.dll' name 'glBlendEquationiARB';
    
    static procedure BlendEquationSeparateiARB(buf: UInt32; modeRGB: UInt32; modeAlpha: UInt32);
    external 'opengl32.dll' name 'glBlendEquationSeparateiARB';
    
    static procedure BlendFunciARB(buf: UInt32; src: UInt32; dst: UInt32);
    external 'opengl32.dll' name 'glBlendFunciARB';
    
    static procedure BlendFuncSeparateiARB(buf: UInt32; srcRGB: UInt32; dstRGB: UInt32; srcAlpha: UInt32; dstAlpha: UInt32);
    external 'opengl32.dll' name 'glBlendFuncSeparateiARB';
    
    static procedure DrawArraysInstancedARB(mode: UInt32; first: Int32; count: Int32; primcount: Int32);
    external 'opengl32.dll' name 'glDrawArraysInstancedARB';
    
    static procedure DrawElementsInstancedARB(mode: UInt32; count: Int32; &type: UInt32; indices: pointer; primcount: Int32);
    external 'opengl32.dll' name 'glDrawElementsInstancedARB';
    
    static procedure ProgramParameteriARB(&program: UInt32; pname: UInt32; value: Int32);
    external 'opengl32.dll' name 'glProgramParameteriARB';
    
    static procedure FramebufferTextureARB(target: UInt32; attachment: UInt32; texture: UInt32; level: Int32);
    external 'opengl32.dll' name 'glFramebufferTextureARB';
    
    static procedure FramebufferTextureLayerARB(target: UInt32; attachment: UInt32; texture: UInt32; level: Int32; layer: Int32);
    external 'opengl32.dll' name 'glFramebufferTextureLayerARB';
    
    static procedure FramebufferTextureFaceARB(target: UInt32; attachment: UInt32; texture: UInt32; level: Int32; face: UInt32);
    external 'opengl32.dll' name 'glFramebufferTextureFaceARB';
    
    static procedure SpecializeShaderARB(shader: UInt32; pEntryPoint: ^SByte; numSpecializationConstants: UInt32; pConstantIndex: ^UInt32; pConstantValue: ^UInt32);
    external 'opengl32.dll' name 'glSpecializeShaderARB';
    
    static procedure Uniform1i64ARB(location: Int32; x: Int64);
    external 'opengl32.dll' name 'glUniform1i64ARB';
    
    static procedure Uniform2i64ARB(location: Int32; x: Int64; y: Int64);
    external 'opengl32.dll' name 'glUniform2i64ARB';
    
    static procedure Uniform3i64ARB(location: Int32; x: Int64; y: Int64; z: Int64);
    external 'opengl32.dll' name 'glUniform3i64ARB';
    
    static procedure Uniform4i64ARB(location: Int32; x: Int64; y: Int64; z: Int64; w: Int64);
    external 'opengl32.dll' name 'glUniform4i64ARB';
    
    static procedure Uniform1i64vARB(location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glUniform1i64vARB';
    
    static procedure Uniform2i64vARB(location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glUniform2i64vARB';
    
    static procedure Uniform3i64vARB(location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glUniform3i64vARB';
    
    static procedure Uniform4i64vARB(location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glUniform4i64vARB';
    
    static procedure Uniform1ui64ARB(location: Int32; x: UInt64);
    external 'opengl32.dll' name 'glUniform1ui64ARB';
    
    static procedure Uniform2ui64ARB(location: Int32; x: UInt64; y: UInt64);
    external 'opengl32.dll' name 'glUniform2ui64ARB';
    
    static procedure Uniform3ui64ARB(location: Int32; x: UInt64; y: UInt64; z: UInt64);
    external 'opengl32.dll' name 'glUniform3ui64ARB';
    
    static procedure Uniform4ui64ARB(location: Int32; x: UInt64; y: UInt64; z: UInt64; w: UInt64);
    external 'opengl32.dll' name 'glUniform4ui64ARB';
    
    static procedure Uniform1ui64vARB(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniform1ui64vARB';
    
    static procedure Uniform2ui64vARB(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniform2ui64vARB';
    
    static procedure Uniform3ui64vARB(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniform3ui64vARB';
    
    static procedure Uniform4ui64vARB(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniform4ui64vARB';
    
    static procedure GetUniformi64vARB(&program: UInt32; location: Int32; &params: ^Int64);
    external 'opengl32.dll' name 'glGetUniformi64vARB';
    
    static procedure GetUniformui64vARB(&program: UInt32; location: Int32; &params: ^UInt64);
    external 'opengl32.dll' name 'glGetUniformui64vARB';
    
    static procedure GetnUniformi64vARB(&program: UInt32; location: Int32; bufSize: Int32; &params: ^Int64);
    external 'opengl32.dll' name 'glGetnUniformi64vARB';
    
    static procedure GetnUniformui64vARB(&program: UInt32; location: Int32; bufSize: Int32; &params: ^UInt64);
    external 'opengl32.dll' name 'glGetnUniformui64vARB';
    
    static procedure ProgramUniform1i64ARB(&program: UInt32; location: Int32; x: Int64);
    external 'opengl32.dll' name 'glProgramUniform1i64ARB';
    
    static procedure ProgramUniform2i64ARB(&program: UInt32; location: Int32; x: Int64; y: Int64);
    external 'opengl32.dll' name 'glProgramUniform2i64ARB';
    
    static procedure ProgramUniform3i64ARB(&program: UInt32; location: Int32; x: Int64; y: Int64; z: Int64);
    external 'opengl32.dll' name 'glProgramUniform3i64ARB';
    
    static procedure ProgramUniform4i64ARB(&program: UInt32; location: Int32; x: Int64; y: Int64; z: Int64; w: Int64);
    external 'opengl32.dll' name 'glProgramUniform4i64ARB';
    
    static procedure ProgramUniform1i64vARB(&program: UInt32; location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glProgramUniform1i64vARB';
    
    static procedure ProgramUniform2i64vARB(&program: UInt32; location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glProgramUniform2i64vARB';
    
    static procedure ProgramUniform3i64vARB(&program: UInt32; location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glProgramUniform3i64vARB';
    
    static procedure ProgramUniform4i64vARB(&program: UInt32; location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glProgramUniform4i64vARB';
    
    static procedure ProgramUniform1ui64ARB(&program: UInt32; location: Int32; x: UInt64);
    external 'opengl32.dll' name 'glProgramUniform1ui64ARB';
    
    static procedure ProgramUniform2ui64ARB(&program: UInt32; location: Int32; x: UInt64; y: UInt64);
    external 'opengl32.dll' name 'glProgramUniform2ui64ARB';
    
    static procedure ProgramUniform3ui64ARB(&program: UInt32; location: Int32; x: UInt64; y: UInt64; z: UInt64);
    external 'opengl32.dll' name 'glProgramUniform3ui64ARB';
    
    static procedure ProgramUniform4ui64ARB(&program: UInt32; location: Int32; x: UInt64; y: UInt64; z: UInt64; w: UInt64);
    external 'opengl32.dll' name 'glProgramUniform4ui64ARB';
    
    static procedure ProgramUniform1ui64vARB(&program: UInt32; location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniform1ui64vARB';
    
    static procedure ProgramUniform2ui64vARB(&program: UInt32; location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniform2ui64vARB';
    
    static procedure ProgramUniform3ui64vARB(&program: UInt32; location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniform3ui64vARB';
    
    static procedure ProgramUniform4ui64vARB(&program: UInt32; location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniform4ui64vARB';
    
    static procedure MultiDrawArraysIndirectCountARB(mode: UInt32; indirect: pointer; drawcount: IntPtr; maxdrawcount: Int32; stride: Int32);
    external 'opengl32.dll' name 'glMultiDrawArraysIndirectCountARB';
    
    static procedure MultiDrawElementsIndirectCountARB(mode: UInt32; &type: UInt32; indirect: pointer; drawcount: IntPtr; maxdrawcount: Int32; stride: Int32);
    external 'opengl32.dll' name 'glMultiDrawElementsIndirectCountARB';
    
    static procedure VertexAttribDivisorARB(index: UInt32; divisor: UInt32);
    external 'opengl32.dll' name 'glVertexAttribDivisorARB';
    
    static procedure MaxShaderCompilerThreadsARB(count: UInt32);
    external 'opengl32.dll' name 'glMaxShaderCompilerThreadsARB';
    
    static function GetGraphicsResetStatusARB: UInt32;
    external 'opengl32.dll' name 'glGetGraphicsResetStatusARB';
    
    static procedure GetnTexImageARB(target: UInt32; level: Int32; format: UInt32; &type: UInt32; bufSize: Int32; img: pointer);
    external 'opengl32.dll' name 'glGetnTexImageARB';
    
    static procedure ReadnPixelsARB(x: Int32; y: Int32; width: Int32; height: Int32; format: UInt32; &type: UInt32; bufSize: Int32; data: pointer);
    external 'opengl32.dll' name 'glReadnPixelsARB';
    
    static procedure GetnCompressedTexImageARB(target: UInt32; lod: Int32; bufSize: Int32; img: pointer);
    external 'opengl32.dll' name 'glGetnCompressedTexImageARB';
    
    static procedure GetnUniformfvARB(&program: UInt32; location: Int32; bufSize: Int32; &params: ^single);
    external 'opengl32.dll' name 'glGetnUniformfvARB';
    
    static procedure GetnUniformivARB(&program: UInt32; location: Int32; bufSize: Int32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetnUniformivARB';
    
    static procedure GetnUniformuivARB(&program: UInt32; location: Int32; bufSize: Int32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetnUniformuivARB';
    
    static procedure GetnUniformdvARB(&program: UInt32; location: Int32; bufSize: Int32; &params: ^real);
    external 'opengl32.dll' name 'glGetnUniformdvARB';
    
    static procedure FramebufferSampleLocationsfvARB(target: UInt32; start: UInt32; count: Int32; v: ^single);
    external 'opengl32.dll' name 'glFramebufferSampleLocationsfvARB';
    
    static procedure NamedFramebufferSampleLocationsfvARB(framebuffer: UInt32; start: UInt32; count: Int32; v: ^single);
    external 'opengl32.dll' name 'glNamedFramebufferSampleLocationsfvARB';
    
    static procedure EvaluateDepthValuesARB;
    external 'opengl32.dll' name 'glEvaluateDepthValuesARB';
    
    static procedure MinSampleShadingARB(value: single);
    external 'opengl32.dll' name 'glMinSampleShadingARB';
    
    static procedure NamedStringARB(&type: UInt32; namelen: Int32; name: ^SByte; stringlen: Int32; string: ^SByte);
    external 'opengl32.dll' name 'glNamedStringARB';
    
    static procedure DeleteNamedStringARB(namelen: Int32; name: ^SByte);
    external 'opengl32.dll' name 'glDeleteNamedStringARB';
    
    static procedure CompileShaderIncludeARB(shader: UInt32; count: Int32; path: ^IntPtr; length: ^Int32);
    external 'opengl32.dll' name 'glCompileShaderIncludeARB';
    
    static function IsNamedStringARB(namelen: Int32; name: ^SByte): boolean;
    external 'opengl32.dll' name 'glIsNamedStringARB';
    
    static procedure GetNamedStringARB(namelen: Int32; name: ^SByte; bufSize: Int32; stringlen: ^Int32; string: ^SByte);
    external 'opengl32.dll' name 'glGetNamedStringARB';
    
    static procedure GetNamedStringivARB(namelen: Int32; name: ^SByte; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetNamedStringivARB';
    
    static procedure BufferPageCommitmentARB(target: UInt32; offset: IntPtr; size: UIntPtr; commit: boolean);
    external 'opengl32.dll' name 'glBufferPageCommitmentARB';
    
    static procedure NamedBufferPageCommitmentEXT(buffer: UInt32; offset: IntPtr; size: UIntPtr; commit: boolean);
    external 'opengl32.dll' name 'glNamedBufferPageCommitmentEXT';
    
    static procedure NamedBufferPageCommitmentARB(buffer: UInt32; offset: IntPtr; size: UIntPtr; commit: boolean);
    external 'opengl32.dll' name 'glNamedBufferPageCommitmentARB';
    
    static procedure TexPageCommitmentARB(target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; commit: boolean);
    external 'opengl32.dll' name 'glTexPageCommitmentARB';
    
    static procedure TexBufferARB(target: UInt32; internalformat: UInt32; buffer: UInt32);
    external 'opengl32.dll' name 'glTexBufferARB';
    
    static procedure BlendBarrierKHR;
    external 'opengl32.dll' name 'glBlendBarrierKHR';
    
    static procedure MaxShaderCompilerThreadsKHR(count: UInt32);
    external 'opengl32.dll' name 'glMaxShaderCompilerThreadsKHR';
    
    static procedure RenderbufferStorageMultisampleAdvancedAMD(target: UInt32; samples: Int32; storageSamples: Int32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glRenderbufferStorageMultisampleAdvancedAMD';
    
    static procedure NamedRenderbufferStorageMultisampleAdvancedAMD(renderbuffer: UInt32; samples: Int32; storageSamples: Int32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glNamedRenderbufferStorageMultisampleAdvancedAMD';
    
    static procedure GetPerfMonitorGroupsAMD(numGroups: ^Int32; groupsSize: Int32; groups: ^UInt32);
    external 'opengl32.dll' name 'glGetPerfMonitorGroupsAMD';
    
    static procedure GetPerfMonitorCountersAMD(group: UInt32; numCounters: ^Int32; maxActiveCounters: ^Int32; counterSize: Int32; counters: ^UInt32);
    external 'opengl32.dll' name 'glGetPerfMonitorCountersAMD';
    
    static procedure GetPerfMonitorGroupStringAMD(group: UInt32; bufSize: Int32; length: ^Int32; groupString: ^SByte);
    external 'opengl32.dll' name 'glGetPerfMonitorGroupStringAMD';
    
    static procedure GetPerfMonitorCounterStringAMD(group: UInt32; counter: UInt32; bufSize: Int32; length: ^Int32; counterString: ^SByte);
    external 'opengl32.dll' name 'glGetPerfMonitorCounterStringAMD';
    
    static procedure GetPerfMonitorCounterInfoAMD(group: UInt32; counter: UInt32; pname: UInt32; data: pointer);
    external 'opengl32.dll' name 'glGetPerfMonitorCounterInfoAMD';
    
    static procedure GenPerfMonitorsAMD(n: Int32; monitors: ^UInt32);
    external 'opengl32.dll' name 'glGenPerfMonitorsAMD';
    
    static procedure DeletePerfMonitorsAMD(n: Int32; monitors: ^UInt32);
    external 'opengl32.dll' name 'glDeletePerfMonitorsAMD';
    
    static procedure SelectPerfMonitorCountersAMD(monitor: UInt32; enable: boolean; group: UInt32; numCounters: Int32; counterList: ^UInt32);
    external 'opengl32.dll' name 'glSelectPerfMonitorCountersAMD';
    
    static procedure BeginPerfMonitorAMD(monitor: UInt32);
    external 'opengl32.dll' name 'glBeginPerfMonitorAMD';
    
    static procedure EndPerfMonitorAMD(monitor: UInt32);
    external 'opengl32.dll' name 'glEndPerfMonitorAMD';
    
    static procedure GetPerfMonitorCounterDataAMD(monitor: UInt32; pname: UInt32; dataSize: Int32; data: ^UInt32; bytesWritten: ^Int32);
    external 'opengl32.dll' name 'glGetPerfMonitorCounterDataAMD';
    
    static procedure EGLImageTargetTexStorageEXT(target: UInt32; image: GLeglImageOES; attrib_list: ^Int32);
    external 'opengl32.dll' name 'glEGLImageTargetTexStorageEXT';
    
    static procedure EGLImageTargetTextureStorageEXT(texture: UInt32; image: GLeglImageOES; attrib_list: ^Int32);
    external 'opengl32.dll' name 'glEGLImageTargetTextureStorageEXT';
    
    static procedure LabelObjectEXT(&type: UInt32; object: UInt32; length: Int32; &label: ^SByte);
    external 'opengl32.dll' name 'glLabelObjectEXT';
    
    static procedure GetObjectLabelEXT(&type: UInt32; object: UInt32; bufSize: Int32; length: ^Int32; &label: ^SByte);
    external 'opengl32.dll' name 'glGetObjectLabelEXT';
    
    static procedure InsertEventMarkerEXT(length: Int32; marker: ^SByte);
    external 'opengl32.dll' name 'glInsertEventMarkerEXT';
    
    static procedure PushGroupMarkerEXT(length: Int32; marker: ^SByte);
    external 'opengl32.dll' name 'glPushGroupMarkerEXT';
    
    static procedure PopGroupMarkerEXT;
    external 'opengl32.dll' name 'glPopGroupMarkerEXT';
    
    static procedure MatrixLoadfEXT(mode: UInt32; m: ^single);
    external 'opengl32.dll' name 'glMatrixLoadfEXT';
    
    static procedure MatrixLoaddEXT(mode: UInt32; m: ^real);
    external 'opengl32.dll' name 'glMatrixLoaddEXT';
    
    static procedure MatrixMultfEXT(mode: UInt32; m: ^single);
    external 'opengl32.dll' name 'glMatrixMultfEXT';
    
    static procedure MatrixMultdEXT(mode: UInt32; m: ^real);
    external 'opengl32.dll' name 'glMatrixMultdEXT';
    
    static procedure MatrixLoadIdentityEXT(mode: UInt32);
    external 'opengl32.dll' name 'glMatrixLoadIdentityEXT';
    
    static procedure MatrixRotatefEXT(mode: UInt32; angle: single; x: single; y: single; z: single);
    external 'opengl32.dll' name 'glMatrixRotatefEXT';
    
    static procedure MatrixRotatedEXT(mode: UInt32; angle: real; x: real; y: real; z: real);
    external 'opengl32.dll' name 'glMatrixRotatedEXT';
    
    static procedure MatrixScalefEXT(mode: UInt32; x: single; y: single; z: single);
    external 'opengl32.dll' name 'glMatrixScalefEXT';
    
    static procedure MatrixScaledEXT(mode: UInt32; x: real; y: real; z: real);
    external 'opengl32.dll' name 'glMatrixScaledEXT';
    
    static procedure MatrixTranslatefEXT(mode: UInt32; x: single; y: single; z: single);
    external 'opengl32.dll' name 'glMatrixTranslatefEXT';
    
    static procedure MatrixTranslatedEXT(mode: UInt32; x: real; y: real; z: real);
    external 'opengl32.dll' name 'glMatrixTranslatedEXT';
    
    static procedure MatrixFrustumEXT(mode: UInt32; left: real; right: real; bottom: real; top: real; zNear: real; zFar: real);
    external 'opengl32.dll' name 'glMatrixFrustumEXT';
    
    static procedure MatrixOrthoEXT(mode: UInt32; left: real; right: real; bottom: real; top: real; zNear: real; zFar: real);
    external 'opengl32.dll' name 'glMatrixOrthoEXT';
    
    static procedure MatrixPopEXT(mode: UInt32);
    external 'opengl32.dll' name 'glMatrixPopEXT';
    
    static procedure MatrixPushEXT(mode: UInt32);
    external 'opengl32.dll' name 'glMatrixPushEXT';
    
    static procedure ClientAttribDefaultEXT(mask: UInt32);
    external 'opengl32.dll' name 'glClientAttribDefaultEXT';
    
    static procedure PushClientAttribDefaultEXT(mask: UInt32);
    external 'opengl32.dll' name 'glPushClientAttribDefaultEXT';
    
    static procedure TextureParameterfEXT(texture: UInt32; target: UInt32; pname: UInt32; param: single);
    external 'opengl32.dll' name 'glTextureParameterfEXT';
    
    static procedure TextureParameterfvEXT(texture: UInt32; target: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glTextureParameterfvEXT';
    
    static procedure TextureParameteriEXT(texture: UInt32; target: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glTextureParameteriEXT';
    
    static procedure TextureParameterivEXT(texture: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glTextureParameterivEXT';
    
    static procedure TextureImage1DEXT(texture: UInt32; target: UInt32; level: Int32; internalformat: Int32; width: Int32; border: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTextureImage1DEXT';
    
    static procedure TextureImage2DEXT(texture: UInt32; target: UInt32; level: Int32; internalformat: Int32; width: Int32; height: Int32; border: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTextureImage2DEXT';
    
    static procedure TextureSubImage1DEXT(texture: UInt32; target: UInt32; level: Int32; xoffset: Int32; width: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTextureSubImage1DEXT';
    
    static procedure TextureSubImage2DEXT(texture: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; width: Int32; height: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTextureSubImage2DEXT';
    
    static procedure CopyTextureImage1DEXT(texture: UInt32; target: UInt32; level: Int32; internalformat: UInt32; x: Int32; y: Int32; width: Int32; border: Int32);
    external 'opengl32.dll' name 'glCopyTextureImage1DEXT';
    
    static procedure CopyTextureImage2DEXT(texture: UInt32; target: UInt32; level: Int32; internalformat: UInt32; x: Int32; y: Int32; width: Int32; height: Int32; border: Int32);
    external 'opengl32.dll' name 'glCopyTextureImage2DEXT';
    
    static procedure CopyTextureSubImage1DEXT(texture: UInt32; target: UInt32; level: Int32; xoffset: Int32; x: Int32; y: Int32; width: Int32);
    external 'opengl32.dll' name 'glCopyTextureSubImage1DEXT';
    
    static procedure CopyTextureSubImage2DEXT(texture: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glCopyTextureSubImage2DEXT';
    
    static procedure GetTextureImageEXT(texture: UInt32; target: UInt32; level: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glGetTextureImageEXT';
    
    static procedure GetTextureParameterfvEXT(texture: UInt32; target: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetTextureParameterfvEXT';
    
    static procedure GetTextureParameterivEXT(texture: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetTextureParameterivEXT';
    
    static procedure GetTextureLevelParameterfvEXT(texture: UInt32; target: UInt32; level: Int32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetTextureLevelParameterfvEXT';
    
    static procedure GetTextureLevelParameterivEXT(texture: UInt32; target: UInt32; level: Int32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetTextureLevelParameterivEXT';
    
    static procedure TextureImage3DEXT(texture: UInt32; target: UInt32; level: Int32; internalformat: Int32; width: Int32; height: Int32; depth: Int32; border: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTextureImage3DEXT';
    
    static procedure TextureSubImage3DEXT(texture: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glTextureSubImage3DEXT';
    
    static procedure CopyTextureSubImage3DEXT(texture: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glCopyTextureSubImage3DEXT';
    
    static procedure BindMultiTextureEXT(texunit: UInt32; target: UInt32; texture: UInt32);
    external 'opengl32.dll' name 'glBindMultiTextureEXT';
    
    static procedure MultiTexCoordPointerEXT(texunit: UInt32; size: Int32; &type: UInt32; stride: Int32; _pointer: pointer);
    external 'opengl32.dll' name 'glMultiTexCoordPointerEXT';
    
    static procedure MultiTexEnvfEXT(texunit: UInt32; target: UInt32; pname: UInt32; param: single);
    external 'opengl32.dll' name 'glMultiTexEnvfEXT';
    
    static procedure MultiTexEnvfvEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glMultiTexEnvfvEXT';
    
    static procedure MultiTexEnviEXT(texunit: UInt32; target: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glMultiTexEnviEXT';
    
    static procedure MultiTexEnvivEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glMultiTexEnvivEXT';
    
    static procedure MultiTexGendEXT(texunit: UInt32; coord: UInt32; pname: UInt32; param: real);
    external 'opengl32.dll' name 'glMultiTexGendEXT';
    
    static procedure MultiTexGendvEXT(texunit: UInt32; coord: UInt32; pname: UInt32; &params: ^real);
    external 'opengl32.dll' name 'glMultiTexGendvEXT';
    
    static procedure MultiTexGenfEXT(texunit: UInt32; coord: UInt32; pname: UInt32; param: single);
    external 'opengl32.dll' name 'glMultiTexGenfEXT';
    
    static procedure MultiTexGenfvEXT(texunit: UInt32; coord: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glMultiTexGenfvEXT';
    
    static procedure MultiTexGeniEXT(texunit: UInt32; coord: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glMultiTexGeniEXT';
    
    static procedure MultiTexGenivEXT(texunit: UInt32; coord: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glMultiTexGenivEXT';
    
    static procedure GetMultiTexEnvfvEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetMultiTexEnvfvEXT';
    
    static procedure GetMultiTexEnvivEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetMultiTexEnvivEXT';
    
    static procedure GetMultiTexGendvEXT(texunit: UInt32; coord: UInt32; pname: UInt32; &params: ^real);
    external 'opengl32.dll' name 'glGetMultiTexGendvEXT';
    
    static procedure GetMultiTexGenfvEXT(texunit: UInt32; coord: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetMultiTexGenfvEXT';
    
    static procedure GetMultiTexGenivEXT(texunit: UInt32; coord: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetMultiTexGenivEXT';
    
    static procedure MultiTexParameteriEXT(texunit: UInt32; target: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glMultiTexParameteriEXT';
    
    static procedure MultiTexParameterivEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glMultiTexParameterivEXT';
    
    static procedure MultiTexParameterfEXT(texunit: UInt32; target: UInt32; pname: UInt32; param: single);
    external 'opengl32.dll' name 'glMultiTexParameterfEXT';
    
    static procedure MultiTexParameterfvEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glMultiTexParameterfvEXT';
    
    static procedure MultiTexImage1DEXT(texunit: UInt32; target: UInt32; level: Int32; internalformat: Int32; width: Int32; border: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glMultiTexImage1DEXT';
    
    static procedure MultiTexImage2DEXT(texunit: UInt32; target: UInt32; level: Int32; internalformat: Int32; width: Int32; height: Int32; border: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glMultiTexImage2DEXT';
    
    static procedure MultiTexSubImage1DEXT(texunit: UInt32; target: UInt32; level: Int32; xoffset: Int32; width: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glMultiTexSubImage1DEXT';
    
    static procedure MultiTexSubImage2DEXT(texunit: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; width: Int32; height: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glMultiTexSubImage2DEXT';
    
    static procedure CopyMultiTexImage1DEXT(texunit: UInt32; target: UInt32; level: Int32; internalformat: UInt32; x: Int32; y: Int32; width: Int32; border: Int32);
    external 'opengl32.dll' name 'glCopyMultiTexImage1DEXT';
    
    static procedure CopyMultiTexImage2DEXT(texunit: UInt32; target: UInt32; level: Int32; internalformat: UInt32; x: Int32; y: Int32; width: Int32; height: Int32; border: Int32);
    external 'opengl32.dll' name 'glCopyMultiTexImage2DEXT';
    
    static procedure CopyMultiTexSubImage1DEXT(texunit: UInt32; target: UInt32; level: Int32; xoffset: Int32; x: Int32; y: Int32; width: Int32);
    external 'opengl32.dll' name 'glCopyMultiTexSubImage1DEXT';
    
    static procedure CopyMultiTexSubImage2DEXT(texunit: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glCopyMultiTexSubImage2DEXT';
    
    static procedure GetMultiTexImageEXT(texunit: UInt32; target: UInt32; level: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glGetMultiTexImageEXT';
    
    static procedure GetMultiTexParameterfvEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetMultiTexParameterfvEXT';
    
    static procedure GetMultiTexParameterivEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetMultiTexParameterivEXT';
    
    static procedure GetMultiTexLevelParameterfvEXT(texunit: UInt32; target: UInt32; level: Int32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetMultiTexLevelParameterfvEXT';
    
    static procedure GetMultiTexLevelParameterivEXT(texunit: UInt32; target: UInt32; level: Int32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetMultiTexLevelParameterivEXT';
    
    static procedure MultiTexImage3DEXT(texunit: UInt32; target: UInt32; level: Int32; internalformat: Int32; width: Int32; height: Int32; depth: Int32; border: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glMultiTexImage3DEXT';
    
    static procedure MultiTexSubImage3DEXT(texunit: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glMultiTexSubImage3DEXT';
    
    static procedure CopyMultiTexSubImage3DEXT(texunit: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glCopyMultiTexSubImage3DEXT';
    
    static procedure EnableClientStateIndexedEXT(&array: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glEnableClientStateIndexedEXT';
    
    static procedure DisableClientStateIndexedEXT(&array: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glDisableClientStateIndexedEXT';
    
    static procedure GetFloatIndexedvEXT(target: UInt32; index: UInt32; data: ^single);
    external 'opengl32.dll' name 'glGetFloatIndexedvEXT';
    
    static procedure GetDoubleIndexedvEXT(target: UInt32; index: UInt32; data: ^real);
    external 'opengl32.dll' name 'glGetDoubleIndexedvEXT';
    
    static procedure GetPointerIndexedvEXT(target: UInt32; index: UInt32; data: ^IntPtr);
    external 'opengl32.dll' name 'glGetPointerIndexedvEXT';
    
    static procedure EnableIndexedEXT(target: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glEnableIndexedEXT';
    
    static procedure DisableIndexedEXT(target: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glDisableIndexedEXT';
    
    static function IsEnabledIndexedEXT(target: UInt32; index: UInt32): boolean;
    external 'opengl32.dll' name 'glIsEnabledIndexedEXT';
    
    static procedure GetIntegerIndexedvEXT(target: UInt32; index: UInt32; data: ^Int32);
    external 'opengl32.dll' name 'glGetIntegerIndexedvEXT';
    
    static procedure GetBooleanIndexedvEXT(target: UInt32; index: UInt32; data: ^boolean);
    external 'opengl32.dll' name 'glGetBooleanIndexedvEXT';
    
    static procedure CompressedTextureImage3DEXT(texture: UInt32; target: UInt32; level: Int32; internalformat: UInt32; width: Int32; height: Int32; depth: Int32; border: Int32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedTextureImage3DEXT';
    
    static procedure CompressedTextureImage2DEXT(texture: UInt32; target: UInt32; level: Int32; internalformat: UInt32; width: Int32; height: Int32; border: Int32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedTextureImage2DEXT';
    
    static procedure CompressedTextureImage1DEXT(texture: UInt32; target: UInt32; level: Int32; internalformat: UInt32; width: Int32; border: Int32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedTextureImage1DEXT';
    
    static procedure CompressedTextureSubImage3DEXT(texture: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; format: UInt32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedTextureSubImage3DEXT';
    
    static procedure CompressedTextureSubImage2DEXT(texture: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; width: Int32; height: Int32; format: UInt32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedTextureSubImage2DEXT';
    
    static procedure CompressedTextureSubImage1DEXT(texture: UInt32; target: UInt32; level: Int32; xoffset: Int32; width: Int32; format: UInt32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedTextureSubImage1DEXT';
    
    static procedure GetCompressedTextureImageEXT(texture: UInt32; target: UInt32; lod: Int32; img: pointer);
    external 'opengl32.dll' name 'glGetCompressedTextureImageEXT';
    
    static procedure CompressedMultiTexImage3DEXT(texunit: UInt32; target: UInt32; level: Int32; internalformat: UInt32; width: Int32; height: Int32; depth: Int32; border: Int32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedMultiTexImage3DEXT';
    
    static procedure CompressedMultiTexImage2DEXT(texunit: UInt32; target: UInt32; level: Int32; internalformat: UInt32; width: Int32; height: Int32; border: Int32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedMultiTexImage2DEXT';
    
    static procedure CompressedMultiTexImage1DEXT(texunit: UInt32; target: UInt32; level: Int32; internalformat: UInt32; width: Int32; border: Int32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedMultiTexImage1DEXT';
    
    static procedure CompressedMultiTexSubImage3DEXT(texunit: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; format: UInt32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedMultiTexSubImage3DEXT';
    
    static procedure CompressedMultiTexSubImage2DEXT(texunit: UInt32; target: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; width: Int32; height: Int32; format: UInt32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedMultiTexSubImage2DEXT';
    
    static procedure CompressedMultiTexSubImage1DEXT(texunit: UInt32; target: UInt32; level: Int32; xoffset: Int32; width: Int32; format: UInt32; imageSize: Int32; bits: pointer);
    external 'opengl32.dll' name 'glCompressedMultiTexSubImage1DEXT';
    
    static procedure GetCompressedMultiTexImageEXT(texunit: UInt32; target: UInt32; lod: Int32; img: pointer);
    external 'opengl32.dll' name 'glGetCompressedMultiTexImageEXT';
    
    static procedure MatrixLoadTransposefEXT(mode: UInt32; m: ^single);
    external 'opengl32.dll' name 'glMatrixLoadTransposefEXT';
    
    static procedure MatrixLoadTransposedEXT(mode: UInt32; m: ^real);
    external 'opengl32.dll' name 'glMatrixLoadTransposedEXT';
    
    static procedure MatrixMultTransposefEXT(mode: UInt32; m: ^single);
    external 'opengl32.dll' name 'glMatrixMultTransposefEXT';
    
    static procedure MatrixMultTransposedEXT(mode: UInt32; m: ^real);
    external 'opengl32.dll' name 'glMatrixMultTransposedEXT';
    
    static procedure NamedBufferDataEXT(buffer: UInt32; size: UIntPtr; data: pointer; usage: UInt32);
    external 'opengl32.dll' name 'glNamedBufferDataEXT';
    
    static procedure NamedBufferSubDataEXT(buffer: UInt32; offset: IntPtr; size: UIntPtr; data: pointer);
    external 'opengl32.dll' name 'glNamedBufferSubDataEXT';
    
    static function MapNamedBufferEXT(buffer: UInt32; access: UInt32): pointer;
    external 'opengl32.dll' name 'glMapNamedBufferEXT';
    
    static function UnmapNamedBufferEXT(buffer: UInt32): boolean;
    external 'opengl32.dll' name 'glUnmapNamedBufferEXT';
    
    static procedure GetNamedBufferParameterivEXT(buffer: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetNamedBufferParameterivEXT';
    
    static procedure GetNamedBufferPointervEXT(buffer: UInt32; pname: UInt32; &params: ^IntPtr);
    external 'opengl32.dll' name 'glGetNamedBufferPointervEXT';
    
    static procedure GetNamedBufferSubDataEXT(buffer: UInt32; offset: IntPtr; size: UIntPtr; data: pointer);
    external 'opengl32.dll' name 'glGetNamedBufferSubDataEXT';
    
    static procedure ProgramUniform1fEXT(&program: UInt32; location: Int32; v0: single);
    external 'opengl32.dll' name 'glProgramUniform1fEXT';
    
    static procedure ProgramUniform2fEXT(&program: UInt32; location: Int32; v0: single; v1: single);
    external 'opengl32.dll' name 'glProgramUniform2fEXT';
    
    static procedure ProgramUniform3fEXT(&program: UInt32; location: Int32; v0: single; v1: single; v2: single);
    external 'opengl32.dll' name 'glProgramUniform3fEXT';
    
    static procedure ProgramUniform4fEXT(&program: UInt32; location: Int32; v0: single; v1: single; v2: single; v3: single);
    external 'opengl32.dll' name 'glProgramUniform4fEXT';
    
    static procedure ProgramUniform1iEXT(&program: UInt32; location: Int32; v0: Int32);
    external 'opengl32.dll' name 'glProgramUniform1iEXT';
    
    static procedure ProgramUniform2iEXT(&program: UInt32; location: Int32; v0: Int32; v1: Int32);
    external 'opengl32.dll' name 'glProgramUniform2iEXT';
    
    static procedure ProgramUniform3iEXT(&program: UInt32; location: Int32; v0: Int32; v1: Int32; v2: Int32);
    external 'opengl32.dll' name 'glProgramUniform3iEXT';
    
    static procedure ProgramUniform4iEXT(&program: UInt32; location: Int32; v0: Int32; v1: Int32; v2: Int32; v3: Int32);
    external 'opengl32.dll' name 'glProgramUniform4iEXT';
    
    static procedure ProgramUniform1fvEXT(&program: UInt32; location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glProgramUniform1fvEXT';
    
    static procedure ProgramUniform2fvEXT(&program: UInt32; location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glProgramUniform2fvEXT';
    
    static procedure ProgramUniform3fvEXT(&program: UInt32; location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glProgramUniform3fvEXT';
    
    static procedure ProgramUniform4fvEXT(&program: UInt32; location: Int32; count: Int32; value: ^single);
    external 'opengl32.dll' name 'glProgramUniform4fvEXT';
    
    static procedure ProgramUniform1ivEXT(&program: UInt32; location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glProgramUniform1ivEXT';
    
    static procedure ProgramUniform2ivEXT(&program: UInt32; location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glProgramUniform2ivEXT';
    
    static procedure ProgramUniform3ivEXT(&program: UInt32; location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glProgramUniform3ivEXT';
    
    static procedure ProgramUniform4ivEXT(&program: UInt32; location: Int32; count: Int32; value: ^Int32);
    external 'opengl32.dll' name 'glProgramUniform4ivEXT';
    
    static procedure ProgramUniformMatrix2fvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2fvEXT';
    
    static procedure ProgramUniformMatrix3fvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3fvEXT';
    
    static procedure ProgramUniformMatrix4fvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4fvEXT';
    
    static procedure ProgramUniformMatrix2x3fvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x3fvEXT';
    
    static procedure ProgramUniformMatrix3x2fvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x2fvEXT';
    
    static procedure ProgramUniformMatrix2x4fvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x4fvEXT';
    
    static procedure ProgramUniformMatrix4x2fvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x2fvEXT';
    
    static procedure ProgramUniformMatrix3x4fvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x4fvEXT';
    
    static procedure ProgramUniformMatrix4x3fvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^single);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x3fvEXT';
    
    static procedure TextureBufferEXT(texture: UInt32; target: UInt32; internalformat: UInt32; buffer: UInt32);
    external 'opengl32.dll' name 'glTextureBufferEXT';
    
    static procedure MultiTexBufferEXT(texunit: UInt32; target: UInt32; internalformat: UInt32; buffer: UInt32);
    external 'opengl32.dll' name 'glMultiTexBufferEXT';
    
    static procedure TextureParameterIivEXT(texture: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glTextureParameterIivEXT';
    
    static procedure TextureParameterIuivEXT(texture: UInt32; target: UInt32; pname: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glTextureParameterIuivEXT';
    
    static procedure GetTextureParameterIivEXT(texture: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetTextureParameterIivEXT';
    
    static procedure GetTextureParameterIuivEXT(texture: UInt32; target: UInt32; pname: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetTextureParameterIuivEXT';
    
    static procedure MultiTexParameterIivEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glMultiTexParameterIivEXT';
    
    static procedure MultiTexParameterIuivEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glMultiTexParameterIuivEXT';
    
    static procedure GetMultiTexParameterIivEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetMultiTexParameterIivEXT';
    
    static procedure GetMultiTexParameterIuivEXT(texunit: UInt32; target: UInt32; pname: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetMultiTexParameterIuivEXT';
    
    static procedure ProgramUniform1uiEXT(&program: UInt32; location: Int32; v0: UInt32);
    external 'opengl32.dll' name 'glProgramUniform1uiEXT';
    
    static procedure ProgramUniform2uiEXT(&program: UInt32; location: Int32; v0: UInt32; v1: UInt32);
    external 'opengl32.dll' name 'glProgramUniform2uiEXT';
    
    static procedure ProgramUniform3uiEXT(&program: UInt32; location: Int32; v0: UInt32; v1: UInt32; v2: UInt32);
    external 'opengl32.dll' name 'glProgramUniform3uiEXT';
    
    static procedure ProgramUniform4uiEXT(&program: UInt32; location: Int32; v0: UInt32; v1: UInt32; v2: UInt32; v3: UInt32);
    external 'opengl32.dll' name 'glProgramUniform4uiEXT';
    
    static procedure ProgramUniform1uivEXT(&program: UInt32; location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glProgramUniform1uivEXT';
    
    static procedure ProgramUniform2uivEXT(&program: UInt32; location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glProgramUniform2uivEXT';
    
    static procedure ProgramUniform3uivEXT(&program: UInt32; location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glProgramUniform3uivEXT';
    
    static procedure ProgramUniform4uivEXT(&program: UInt32; location: Int32; count: Int32; value: ^UInt32);
    external 'opengl32.dll' name 'glProgramUniform4uivEXT';
    
    static procedure NamedProgramLocalParameters4fvEXT(&program: UInt32; target: UInt32; index: UInt32; count: Int32; &params: ^single);
    external 'opengl32.dll' name 'glNamedProgramLocalParameters4fvEXT';
    
    static procedure NamedProgramLocalParameterI4iEXT(&program: UInt32; target: UInt32; index: UInt32; x: Int32; y: Int32; z: Int32; w: Int32);
    external 'opengl32.dll' name 'glNamedProgramLocalParameterI4iEXT';
    
    static procedure NamedProgramLocalParameterI4ivEXT(&program: UInt32; target: UInt32; index: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glNamedProgramLocalParameterI4ivEXT';
    
    static procedure NamedProgramLocalParametersI4ivEXT(&program: UInt32; target: UInt32; index: UInt32; count: Int32; &params: ^Int32);
    external 'opengl32.dll' name 'glNamedProgramLocalParametersI4ivEXT';
    
    static procedure NamedProgramLocalParameterI4uiEXT(&program: UInt32; target: UInt32; index: UInt32; x: UInt32; y: UInt32; z: UInt32; w: UInt32);
    external 'opengl32.dll' name 'glNamedProgramLocalParameterI4uiEXT';
    
    static procedure NamedProgramLocalParameterI4uivEXT(&program: UInt32; target: UInt32; index: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glNamedProgramLocalParameterI4uivEXT';
    
    static procedure NamedProgramLocalParametersI4uivEXT(&program: UInt32; target: UInt32; index: UInt32; count: Int32; &params: ^UInt32);
    external 'opengl32.dll' name 'glNamedProgramLocalParametersI4uivEXT';
    
    static procedure GetNamedProgramLocalParameterIivEXT(&program: UInt32; target: UInt32; index: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetNamedProgramLocalParameterIivEXT';
    
    static procedure GetNamedProgramLocalParameterIuivEXT(&program: UInt32; target: UInt32; index: UInt32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetNamedProgramLocalParameterIuivEXT';
    
    static procedure EnableClientStateiEXT(&array: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glEnableClientStateiEXT';
    
    static procedure DisableClientStateiEXT(&array: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glDisableClientStateiEXT';
    
    static procedure GetFloati_vEXT(pname: UInt32; index: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetFloati_vEXT';
    
    static procedure GetDoublei_vEXT(pname: UInt32; index: UInt32; &params: ^real);
    external 'opengl32.dll' name 'glGetDoublei_vEXT';
    
    static procedure GetPointeri_vEXT(pname: UInt32; index: UInt32; &params: ^IntPtr);
    external 'opengl32.dll' name 'glGetPointeri_vEXT';
    
    static procedure NamedProgramStringEXT(&program: UInt32; target: UInt32; format: UInt32; len: Int32; string: pointer);
    external 'opengl32.dll' name 'glNamedProgramStringEXT';
    
    static procedure NamedProgramLocalParameter4dEXT(&program: UInt32; target: UInt32; index: UInt32; x: real; y: real; z: real; w: real);
    external 'opengl32.dll' name 'glNamedProgramLocalParameter4dEXT';
    
    static procedure NamedProgramLocalParameter4dvEXT(&program: UInt32; target: UInt32; index: UInt32; &params: ^real);
    external 'opengl32.dll' name 'glNamedProgramLocalParameter4dvEXT';
    
    static procedure NamedProgramLocalParameter4fEXT(&program: UInt32; target: UInt32; index: UInt32; x: single; y: single; z: single; w: single);
    external 'opengl32.dll' name 'glNamedProgramLocalParameter4fEXT';
    
    static procedure NamedProgramLocalParameter4fvEXT(&program: UInt32; target: UInt32; index: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glNamedProgramLocalParameter4fvEXT';
    
    static procedure GetNamedProgramLocalParameterdvEXT(&program: UInt32; target: UInt32; index: UInt32; &params: ^real);
    external 'opengl32.dll' name 'glGetNamedProgramLocalParameterdvEXT';
    
    static procedure GetNamedProgramLocalParameterfvEXT(&program: UInt32; target: UInt32; index: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetNamedProgramLocalParameterfvEXT';
    
    static procedure GetNamedProgramivEXT(&program: UInt32; target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetNamedProgramivEXT';
    
    static procedure GetNamedProgramStringEXT(&program: UInt32; target: UInt32; pname: UInt32; string: pointer);
    external 'opengl32.dll' name 'glGetNamedProgramStringEXT';
    
    static procedure NamedRenderbufferStorageEXT(renderbuffer: UInt32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glNamedRenderbufferStorageEXT';
    
    static procedure GetNamedRenderbufferParameterivEXT(renderbuffer: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetNamedRenderbufferParameterivEXT';
    
    static procedure NamedRenderbufferStorageMultisampleEXT(renderbuffer: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glNamedRenderbufferStorageMultisampleEXT';
    
    static procedure NamedRenderbufferStorageMultisampleCoverageEXT(renderbuffer: UInt32; coverageSamples: Int32; colorSamples: Int32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glNamedRenderbufferStorageMultisampleCoverageEXT';
    
    static function CheckNamedFramebufferStatusEXT(framebuffer: UInt32; target: UInt32): UInt32;
    external 'opengl32.dll' name 'glCheckNamedFramebufferStatusEXT';
    
    static procedure NamedFramebufferTexture1DEXT(framebuffer: UInt32; attachment: UInt32; textarget: UInt32; texture: UInt32; level: Int32);
    external 'opengl32.dll' name 'glNamedFramebufferTexture1DEXT';
    
    static procedure NamedFramebufferTexture2DEXT(framebuffer: UInt32; attachment: UInt32; textarget: UInt32; texture: UInt32; level: Int32);
    external 'opengl32.dll' name 'glNamedFramebufferTexture2DEXT';
    
    static procedure NamedFramebufferTexture3DEXT(framebuffer: UInt32; attachment: UInt32; textarget: UInt32; texture: UInt32; level: Int32; zoffset: Int32);
    external 'opengl32.dll' name 'glNamedFramebufferTexture3DEXT';
    
    static procedure NamedFramebufferRenderbufferEXT(framebuffer: UInt32; attachment: UInt32; renderbuffertarget: UInt32; renderbuffer: UInt32);
    external 'opengl32.dll' name 'glNamedFramebufferRenderbufferEXT';
    
    static procedure GetNamedFramebufferAttachmentParameterivEXT(framebuffer: UInt32; attachment: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetNamedFramebufferAttachmentParameterivEXT';
    
    static procedure GenerateTextureMipmapEXT(texture: UInt32; target: UInt32);
    external 'opengl32.dll' name 'glGenerateTextureMipmapEXT';
    
    static procedure GenerateMultiTexMipmapEXT(texunit: UInt32; target: UInt32);
    external 'opengl32.dll' name 'glGenerateMultiTexMipmapEXT';
    
    static procedure FramebufferDrawBufferEXT(framebuffer: UInt32; mode: UInt32);
    external 'opengl32.dll' name 'glFramebufferDrawBufferEXT';
    
    static procedure FramebufferDrawBuffersEXT(framebuffer: UInt32; n: Int32; bufs: ^UInt32);
    external 'opengl32.dll' name 'glFramebufferDrawBuffersEXT';
    
    static procedure FramebufferReadBufferEXT(framebuffer: UInt32; mode: UInt32);
    external 'opengl32.dll' name 'glFramebufferReadBufferEXT';
    
    static procedure GetFramebufferParameterivEXT(framebuffer: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetFramebufferParameterivEXT';
    
    static procedure NamedCopyBufferSubDataEXT(readBuffer: UInt32; writeBuffer: UInt32; readOffset: IntPtr; writeOffset: IntPtr; size: UIntPtr);
    external 'opengl32.dll' name 'glNamedCopyBufferSubDataEXT';
    
    static procedure NamedFramebufferTextureEXT(framebuffer: UInt32; attachment: UInt32; texture: UInt32; level: Int32);
    external 'opengl32.dll' name 'glNamedFramebufferTextureEXT';
    
    static procedure NamedFramebufferTextureLayerEXT(framebuffer: UInt32; attachment: UInt32; texture: UInt32; level: Int32; layer: Int32);
    external 'opengl32.dll' name 'glNamedFramebufferTextureLayerEXT';
    
    static procedure NamedFramebufferTextureFaceEXT(framebuffer: UInt32; attachment: UInt32; texture: UInt32; level: Int32; face: UInt32);
    external 'opengl32.dll' name 'glNamedFramebufferTextureFaceEXT';
    
    static procedure TextureRenderbufferEXT(texture: UInt32; target: UInt32; renderbuffer: UInt32);
    external 'opengl32.dll' name 'glTextureRenderbufferEXT';
    
    static procedure MultiTexRenderbufferEXT(texunit: UInt32; target: UInt32; renderbuffer: UInt32);
    external 'opengl32.dll' name 'glMultiTexRenderbufferEXT';
    
    static procedure VertexArrayVertexOffsetEXT(vaobj: UInt32; buffer: UInt32; size: Int32; &type: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayVertexOffsetEXT';
    
    static procedure VertexArrayColorOffsetEXT(vaobj: UInt32; buffer: UInt32; size: Int32; &type: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayColorOffsetEXT';
    
    static procedure VertexArrayEdgeFlagOffsetEXT(vaobj: UInt32; buffer: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayEdgeFlagOffsetEXT';
    
    static procedure VertexArrayIndexOffsetEXT(vaobj: UInt32; buffer: UInt32; &type: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayIndexOffsetEXT';
    
    static procedure VertexArrayNormalOffsetEXT(vaobj: UInt32; buffer: UInt32; &type: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayNormalOffsetEXT';
    
    static procedure VertexArrayTexCoordOffsetEXT(vaobj: UInt32; buffer: UInt32; size: Int32; &type: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayTexCoordOffsetEXT';
    
    static procedure VertexArrayMultiTexCoordOffsetEXT(vaobj: UInt32; buffer: UInt32; texunit: UInt32; size: Int32; &type: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayMultiTexCoordOffsetEXT';
    
    static procedure VertexArrayFogCoordOffsetEXT(vaobj: UInt32; buffer: UInt32; &type: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayFogCoordOffsetEXT';
    
    static procedure VertexArraySecondaryColorOffsetEXT(vaobj: UInt32; buffer: UInt32; size: Int32; &type: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArraySecondaryColorOffsetEXT';
    
    static procedure VertexArrayVertexAttribOffsetEXT(vaobj: UInt32; buffer: UInt32; index: UInt32; size: Int32; &type: UInt32; normalized: boolean; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayVertexAttribOffsetEXT';
    
    static procedure VertexArrayVertexAttribIOffsetEXT(vaobj: UInt32; buffer: UInt32; index: UInt32; size: Int32; &type: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayVertexAttribIOffsetEXT';
    
    static procedure EnableVertexArrayEXT(vaobj: UInt32; &array: UInt32);
    external 'opengl32.dll' name 'glEnableVertexArrayEXT';
    
    static procedure DisableVertexArrayEXT(vaobj: UInt32; &array: UInt32);
    external 'opengl32.dll' name 'glDisableVertexArrayEXT';
    
    static procedure EnableVertexArrayAttribEXT(vaobj: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glEnableVertexArrayAttribEXT';
    
    static procedure DisableVertexArrayAttribEXT(vaobj: UInt32; index: UInt32);
    external 'opengl32.dll' name 'glDisableVertexArrayAttribEXT';
    
    static procedure GetVertexArrayIntegervEXT(vaobj: UInt32; pname: UInt32; param: ^Int32);
    external 'opengl32.dll' name 'glGetVertexArrayIntegervEXT';
    
    static procedure GetVertexArrayPointervEXT(vaobj: UInt32; pname: UInt32; param: ^IntPtr);
    external 'opengl32.dll' name 'glGetVertexArrayPointervEXT';
    
    static procedure GetVertexArrayIntegeri_vEXT(vaobj: UInt32; index: UInt32; pname: UInt32; param: ^Int32);
    external 'opengl32.dll' name 'glGetVertexArrayIntegeri_vEXT';
    
    static procedure GetVertexArrayPointeri_vEXT(vaobj: UInt32; index: UInt32; pname: UInt32; param: ^IntPtr);
    external 'opengl32.dll' name 'glGetVertexArrayPointeri_vEXT';
    
    static function MapNamedBufferRangeEXT(buffer: UInt32; offset: IntPtr; length: UIntPtr; access: UInt32): pointer;
    external 'opengl32.dll' name 'glMapNamedBufferRangeEXT';
    
    static procedure FlushMappedNamedBufferRangeEXT(buffer: UInt32; offset: IntPtr; length: UIntPtr);
    external 'opengl32.dll' name 'glFlushMappedNamedBufferRangeEXT';
    
    static procedure NamedBufferStorageEXT(buffer: UInt32; size: UIntPtr; data: pointer; flags: UInt32);
    external 'opengl32.dll' name 'glNamedBufferStorageEXT';
    
    static procedure ClearNamedBufferDataEXT(buffer: UInt32; internalformat: UInt32; format: UInt32; &type: UInt32; data: pointer);
    external 'opengl32.dll' name 'glClearNamedBufferDataEXT';
    
    static procedure ClearNamedBufferSubDataEXT(buffer: UInt32; internalformat: UInt32; offset: UIntPtr; size: UIntPtr; format: UInt32; &type: UInt32; data: pointer);
    external 'opengl32.dll' name 'glClearNamedBufferSubDataEXT';
    
    static procedure NamedFramebufferParameteriEXT(framebuffer: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glNamedFramebufferParameteriEXT';
    
    static procedure GetNamedFramebufferParameterivEXT(framebuffer: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetNamedFramebufferParameterivEXT';
    
    static procedure ProgramUniform1dEXT(&program: UInt32; location: Int32; x: real);
    external 'opengl32.dll' name 'glProgramUniform1dEXT';
    
    static procedure ProgramUniform2dEXT(&program: UInt32; location: Int32; x: real; y: real);
    external 'opengl32.dll' name 'glProgramUniform2dEXT';
    
    static procedure ProgramUniform3dEXT(&program: UInt32; location: Int32; x: real; y: real; z: real);
    external 'opengl32.dll' name 'glProgramUniform3dEXT';
    
    static procedure ProgramUniform4dEXT(&program: UInt32; location: Int32; x: real; y: real; z: real; w: real);
    external 'opengl32.dll' name 'glProgramUniform4dEXT';
    
    static procedure ProgramUniform1dvEXT(&program: UInt32; location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glProgramUniform1dvEXT';
    
    static procedure ProgramUniform2dvEXT(&program: UInt32; location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glProgramUniform2dvEXT';
    
    static procedure ProgramUniform3dvEXT(&program: UInt32; location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glProgramUniform3dvEXT';
    
    static procedure ProgramUniform4dvEXT(&program: UInt32; location: Int32; count: Int32; value: ^real);
    external 'opengl32.dll' name 'glProgramUniform4dvEXT';
    
    static procedure ProgramUniformMatrix2dvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2dvEXT';
    
    static procedure ProgramUniformMatrix3dvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3dvEXT';
    
    static procedure ProgramUniformMatrix4dvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4dvEXT';
    
    static procedure ProgramUniformMatrix2x3dvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x3dvEXT';
    
    static procedure ProgramUniformMatrix2x4dvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix2x4dvEXT';
    
    static procedure ProgramUniformMatrix3x2dvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x2dvEXT';
    
    static procedure ProgramUniformMatrix3x4dvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix3x4dvEXT';
    
    static procedure ProgramUniformMatrix4x2dvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x2dvEXT';
    
    static procedure ProgramUniformMatrix4x3dvEXT(&program: UInt32; location: Int32; count: Int32; transpose: boolean; value: ^real);
    external 'opengl32.dll' name 'glProgramUniformMatrix4x3dvEXT';
    
    static procedure TextureBufferRangeEXT(texture: UInt32; target: UInt32; internalformat: UInt32; buffer: UInt32; offset: IntPtr; size: UIntPtr);
    external 'opengl32.dll' name 'glTextureBufferRangeEXT';
    
    static procedure TextureStorage1DEXT(texture: UInt32; target: UInt32; levels: Int32; internalformat: UInt32; width: Int32);
    external 'opengl32.dll' name 'glTextureStorage1DEXT';
    
    static procedure TextureStorage2DEXT(texture: UInt32; target: UInt32; levels: Int32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glTextureStorage2DEXT';
    
    static procedure TextureStorage3DEXT(texture: UInt32; target: UInt32; levels: Int32; internalformat: UInt32; width: Int32; height: Int32; depth: Int32);
    external 'opengl32.dll' name 'glTextureStorage3DEXT';
    
    static procedure TextureStorage2DMultisampleEXT(texture: UInt32; target: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32; fixedsamplelocations: boolean);
    external 'opengl32.dll' name 'glTextureStorage2DMultisampleEXT';
    
    static procedure TextureStorage3DMultisampleEXT(texture: UInt32; target: UInt32; samples: Int32; internalformat: UInt32; width: Int32; height: Int32; depth: Int32; fixedsamplelocations: boolean);
    external 'opengl32.dll' name 'glTextureStorage3DMultisampleEXT';
    
    static procedure VertexArrayBindVertexBufferEXT(vaobj: UInt32; bindingindex: UInt32; buffer: UInt32; offset: IntPtr; stride: Int32);
    external 'opengl32.dll' name 'glVertexArrayBindVertexBufferEXT';
    
    static procedure VertexArrayVertexAttribFormatEXT(vaobj: UInt32; attribindex: UInt32; size: Int32; &type: UInt32; normalized: boolean; relativeoffset: UInt32);
    external 'opengl32.dll' name 'glVertexArrayVertexAttribFormatEXT';
    
    static procedure VertexArrayVertexAttribIFormatEXT(vaobj: UInt32; attribindex: UInt32; size: Int32; &type: UInt32; relativeoffset: UInt32);
    external 'opengl32.dll' name 'glVertexArrayVertexAttribIFormatEXT';
    
    static procedure VertexArrayVertexAttribLFormatEXT(vaobj: UInt32; attribindex: UInt32; size: Int32; &type: UInt32; relativeoffset: UInt32);
    external 'opengl32.dll' name 'glVertexArrayVertexAttribLFormatEXT';
    
    static procedure VertexArrayVertexAttribBindingEXT(vaobj: UInt32; attribindex: UInt32; bindingindex: UInt32);
    external 'opengl32.dll' name 'glVertexArrayVertexAttribBindingEXT';
    
    static procedure VertexArrayVertexBindingDivisorEXT(vaobj: UInt32; bindingindex: UInt32; divisor: UInt32);
    external 'opengl32.dll' name 'glVertexArrayVertexBindingDivisorEXT';
    
    static procedure VertexArrayVertexAttribLOffsetEXT(vaobj: UInt32; buffer: UInt32; index: UInt32; size: Int32; &type: UInt32; stride: Int32; offset: IntPtr);
    external 'opengl32.dll' name 'glVertexArrayVertexAttribLOffsetEXT';
    
    static procedure TexturePageCommitmentEXT(texture: UInt32; level: Int32; xoffset: Int32; yoffset: Int32; zoffset: Int32; width: Int32; height: Int32; depth: Int32; commit: boolean);
    external 'opengl32.dll' name 'glTexturePageCommitmentEXT';
    
    static procedure VertexArrayVertexAttribDivisorEXT(vaobj: UInt32; index: UInt32; divisor: UInt32);
    external 'opengl32.dll' name 'glVertexArrayVertexAttribDivisorEXT';
    
    static procedure DrawArraysInstancedEXT(mode: UInt32; start: Int32; count: Int32; primcount: Int32);
    external 'opengl32.dll' name 'glDrawArraysInstancedEXT';
    
    static procedure DrawElementsInstancedEXT(mode: UInt32; count: Int32; &type: UInt32; indices: pointer; primcount: Int32);
    external 'opengl32.dll' name 'glDrawElementsInstancedEXT';
    
    static procedure PolygonOffsetClampEXT(factor: single; units: single; clamp: single);
    external 'opengl32.dll' name 'glPolygonOffsetClampEXT';
    
    static procedure RasterSamplesEXT(samples: UInt32; fixedsamplelocations: boolean);
    external 'opengl32.dll' name 'glRasterSamplesEXT';
    
    static procedure UseShaderProgramEXT(&type: UInt32; &program: UInt32);
    external 'opengl32.dll' name 'glUseShaderProgramEXT';
    
    static procedure ActiveProgramEXT(&program: UInt32);
    external 'opengl32.dll' name 'glActiveProgramEXT';
    
    static function CreateShaderProgramEXT(&type: UInt32; string: ^SByte): UInt32;
    external 'opengl32.dll' name 'glCreateShaderProgramEXT';
    
    static procedure FramebufferFetchBarrierEXT;
    external 'opengl32.dll' name 'glFramebufferFetchBarrierEXT';
    
    static procedure WindowRectanglesEXT(mode: UInt32; count: Int32; box: ^Int32);
    external 'opengl32.dll' name 'glWindowRectanglesEXT';
    
    static procedure ApplyFramebufferAttachmentCMAAINTEL;
    external 'opengl32.dll' name 'glApplyFramebufferAttachmentCMAAINTEL';
    
    static procedure BeginPerfQueryINTEL(queryHandle: UInt32);
    external 'opengl32.dll' name 'glBeginPerfQueryINTEL';
    
    static procedure CreatePerfQueryINTEL(queryId: UInt32; queryHandle: ^UInt32);
    external 'opengl32.dll' name 'glCreatePerfQueryINTEL';
    
    static procedure DeletePerfQueryINTEL(queryHandle: UInt32);
    external 'opengl32.dll' name 'glDeletePerfQueryINTEL';
    
    static procedure EndPerfQueryINTEL(queryHandle: UInt32);
    external 'opengl32.dll' name 'glEndPerfQueryINTEL';
    
    static procedure GetFirstPerfQueryIdINTEL(queryId: ^UInt32);
    external 'opengl32.dll' name 'glGetFirstPerfQueryIdINTEL';
    
    static procedure GetNextPerfQueryIdINTEL(queryId: UInt32; nextQueryId: ^UInt32);
    external 'opengl32.dll' name 'glGetNextPerfQueryIdINTEL';
    
    static procedure GetPerfCounterInfoINTEL(queryId: UInt32; counterId: UInt32; counterNameLength: UInt32; counterName: ^SByte; counterDescLength: UInt32; counterDesc: ^SByte; counterOffset: ^UInt32; counterDataSize: ^UInt32; counterTypeEnum: ^UInt32; counterDataTypeEnum: ^UInt32; rawCounterMaxValue: ^UInt64);
    external 'opengl32.dll' name 'glGetPerfCounterInfoINTEL';
    
    static procedure GetPerfQueryDataINTEL(queryHandle: UInt32; flags: UInt32; dataSize: Int32; data: pointer; bytesWritten: ^UInt32);
    external 'opengl32.dll' name 'glGetPerfQueryDataINTEL';
    
    static procedure GetPerfQueryIdByNameINTEL(queryName: ^SByte; queryId: ^UInt32);
    external 'opengl32.dll' name 'glGetPerfQueryIdByNameINTEL';
    
    static procedure GetPerfQueryInfoINTEL(queryId: UInt32; queryNameLength: UInt32; queryName: ^SByte; dataSize: ^UInt32; noCounters: ^UInt32; noInstances: ^UInt32; capsMask: ^UInt32);
    external 'opengl32.dll' name 'glGetPerfQueryInfoINTEL';
    
    static procedure MultiDrawArraysIndirectBindlessNV(mode: UInt32; indirect: pointer; drawCount: Int32; stride: Int32; vertexBufferCount: Int32);
    external 'opengl32.dll' name 'glMultiDrawArraysIndirectBindlessNV';
    
    static procedure MultiDrawElementsIndirectBindlessNV(mode: UInt32; &type: UInt32; indirect: pointer; drawCount: Int32; stride: Int32; vertexBufferCount: Int32);
    external 'opengl32.dll' name 'glMultiDrawElementsIndirectBindlessNV';
    
    static procedure MultiDrawArraysIndirectBindlessCountNV(mode: UInt32; indirect: pointer; drawCount: Int32; maxDrawCount: Int32; stride: Int32; vertexBufferCount: Int32);
    external 'opengl32.dll' name 'glMultiDrawArraysIndirectBindlessCountNV';
    
    static procedure MultiDrawElementsIndirectBindlessCountNV(mode: UInt32; &type: UInt32; indirect: pointer; drawCount: Int32; maxDrawCount: Int32; stride: Int32; vertexBufferCount: Int32);
    external 'opengl32.dll' name 'glMultiDrawElementsIndirectBindlessCountNV';
    
    static function GetTextureHandleNV(texture: UInt32): UInt64;
    external 'opengl32.dll' name 'glGetTextureHandleNV';
    
    static function GetTextureSamplerHandleNV(texture: UInt32; sampler: UInt32): UInt64;
    external 'opengl32.dll' name 'glGetTextureSamplerHandleNV';
    
    static procedure MakeTextureHandleResidentNV(handle: UInt64);
    external 'opengl32.dll' name 'glMakeTextureHandleResidentNV';
    
    static procedure MakeTextureHandleNonResidentNV(handle: UInt64);
    external 'opengl32.dll' name 'glMakeTextureHandleNonResidentNV';
    
    static function GetImageHandleNV(texture: UInt32; level: Int32; layered: boolean; layer: Int32; format: UInt32): UInt64;
    external 'opengl32.dll' name 'glGetImageHandleNV';
    
    static procedure MakeImageHandleResidentNV(handle: UInt64; access: UInt32);
    external 'opengl32.dll' name 'glMakeImageHandleResidentNV';
    
    static procedure MakeImageHandleNonResidentNV(handle: UInt64);
    external 'opengl32.dll' name 'glMakeImageHandleNonResidentNV';
    
    static procedure UniformHandleui64NV(location: Int32; value: UInt64);
    external 'opengl32.dll' name 'glUniformHandleui64NV';
    
    static procedure UniformHandleui64vNV(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniformHandleui64vNV';
    
    static procedure ProgramUniformHandleui64NV(&program: UInt32; location: Int32; value: UInt64);
    external 'opengl32.dll' name 'glProgramUniformHandleui64NV';
    
    static procedure ProgramUniformHandleui64vNV(&program: UInt32; location: Int32; count: Int32; values: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniformHandleui64vNV';
    
    static function IsTextureHandleResidentNV(handle: UInt64): boolean;
    external 'opengl32.dll' name 'glIsTextureHandleResidentNV';
    
    static function IsImageHandleResidentNV(handle: UInt64): boolean;
    external 'opengl32.dll' name 'glIsImageHandleResidentNV';
    
    static procedure BlendParameteriNV(pname: UInt32; value: Int32);
    external 'opengl32.dll' name 'glBlendParameteriNV';
    
    static procedure BlendBarrierNV;
    external 'opengl32.dll' name 'glBlendBarrierNV';
    
    static procedure ViewportPositionWScaleNV(index: UInt32; xcoeff: single; ycoeff: single);
    external 'opengl32.dll' name 'glViewportPositionWScaleNV';
    
    static procedure CreateStatesNV(n: Int32; states: ^UInt32);
    external 'opengl32.dll' name 'glCreateStatesNV';
    
    static procedure DeleteStatesNV(n: Int32; states: ^UInt32);
    external 'opengl32.dll' name 'glDeleteStatesNV';
    
    static function IsStateNV(state: UInt32): boolean;
    external 'opengl32.dll' name 'glIsStateNV';
    
    static procedure StateCaptureNV(state: UInt32; mode: UInt32);
    external 'opengl32.dll' name 'glStateCaptureNV';
    
    static function GetCommandHeaderNV(tokenID: UInt32; size: UInt32): UInt32;
    external 'opengl32.dll' name 'glGetCommandHeaderNV';
    
    static function GetStageIndexNV(shadertype: UInt32): UInt16;
    external 'opengl32.dll' name 'glGetStageIndexNV';
    
    static procedure DrawCommandsNV(primitiveMode: UInt32; buffer: UInt32; indirects: ^IntPtr; sizes: ^Int32; count: UInt32);
    external 'opengl32.dll' name 'glDrawCommandsNV';
    
    static procedure DrawCommandsAddressNV(primitiveMode: UInt32; indirects: ^UInt64; sizes: ^Int32; count: UInt32);
    external 'opengl32.dll' name 'glDrawCommandsAddressNV';
    
    static procedure DrawCommandsStatesNV(buffer: UInt32; indirects: ^IntPtr; sizes: ^Int32; states: ^UInt32; fbos: ^UInt32; count: UInt32);
    external 'opengl32.dll' name 'glDrawCommandsStatesNV';
    
    static procedure DrawCommandsStatesAddressNV(indirects: ^UInt64; sizes: ^Int32; states: ^UInt32; fbos: ^UInt32; count: UInt32);
    external 'opengl32.dll' name 'glDrawCommandsStatesAddressNV';
    
    static procedure CreateCommandListsNV(n: Int32; lists: ^UInt32);
    external 'opengl32.dll' name 'glCreateCommandListsNV';
    
    static procedure DeleteCommandListsNV(n: Int32; lists: ^UInt32);
    external 'opengl32.dll' name 'glDeleteCommandListsNV';
    
    static function IsCommandListNV(list: UInt32): boolean;
    external 'opengl32.dll' name 'glIsCommandListNV';
    
    static procedure ListDrawCommandsStatesClientNV(list: UInt32; segment: UInt32; indirects: ^IntPtr; sizes: ^Int32; states: ^UInt32; fbos: ^UInt32; count: UInt32);
    external 'opengl32.dll' name 'glListDrawCommandsStatesClientNV';
    
    static procedure CommandListSegmentsNV(list: UInt32; segments: UInt32);
    external 'opengl32.dll' name 'glCommandListSegmentsNV';
    
    static procedure CompileCommandListNV(list: UInt32);
    external 'opengl32.dll' name 'glCompileCommandListNV';
    
    static procedure CallCommandListNV(list: UInt32);
    external 'opengl32.dll' name 'glCallCommandListNV';
    
    static procedure BeginConditionalRenderNV(id: UInt32; mode: UInt32);
    external 'opengl32.dll' name 'glBeginConditionalRenderNV';
    
    static procedure EndConditionalRenderNV;
    external 'opengl32.dll' name 'glEndConditionalRenderNV';
    
    static procedure SubpixelPrecisionBiasNV(xbits: UInt32; ybits: UInt32);
    external 'opengl32.dll' name 'glSubpixelPrecisionBiasNV';
    
    static procedure ConservativeRasterParameterfNV(pname: UInt32; value: single);
    external 'opengl32.dll' name 'glConservativeRasterParameterfNV';
    
    static procedure ConservativeRasterParameteriNV(pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glConservativeRasterParameteriNV';
    
    static procedure DrawVkImageNV(vkImage: UInt64; sampler: UInt32; x0: single; y0: single; x1: single; y1: single; z: single; s0: single; t0: single; s1: single; t1: single);
    external 'opengl32.dll' name 'glDrawVkImageNV';
    
    static function GetVkProcAddrNV(name: ^SByte): GLVULKANPROCNV;
    external 'opengl32.dll' name 'glGetVkProcAddrNV';
    
    static procedure WaitVkSemaphoreNV(vkSemaphore: UInt64);
    external 'opengl32.dll' name 'glWaitVkSemaphoreNV';
    
    static procedure SignalVkSemaphoreNV(vkSemaphore: UInt64);
    external 'opengl32.dll' name 'glSignalVkSemaphoreNV';
    
    static procedure SignalVkFenceNV(vkFence: UInt64);
    external 'opengl32.dll' name 'glSignalVkFenceNV';
    
    static procedure FragmentCoverageColorNV(color: UInt32);
    external 'opengl32.dll' name 'glFragmentCoverageColorNV';
    
    static procedure CoverageModulationTableNV(n: Int32; v: ^single);
    external 'opengl32.dll' name 'glCoverageModulationTableNV';
    
    static procedure GetCoverageModulationTableNV(bufsize: Int32; v: ^single);
    external 'opengl32.dll' name 'glGetCoverageModulationTableNV';
    
    static procedure CoverageModulationNV(components: UInt32);
    external 'opengl32.dll' name 'glCoverageModulationNV';
    
    static procedure RenderbufferStorageMultisampleCoverageNV(target: UInt32; coverageSamples: Int32; colorSamples: Int32; internalformat: UInt32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glRenderbufferStorageMultisampleCoverageNV';
    
    static procedure Uniform1i64NV(location: Int32; x: Int64);
    external 'opengl32.dll' name 'glUniform1i64NV';
    
    static procedure Uniform2i64NV(location: Int32; x: Int64; y: Int64);
    external 'opengl32.dll' name 'glUniform2i64NV';
    
    static procedure Uniform3i64NV(location: Int32; x: Int64; y: Int64; z: Int64);
    external 'opengl32.dll' name 'glUniform3i64NV';
    
    static procedure Uniform4i64NV(location: Int32; x: Int64; y: Int64; z: Int64; w: Int64);
    external 'opengl32.dll' name 'glUniform4i64NV';
    
    static procedure Uniform1i64vNV(location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glUniform1i64vNV';
    
    static procedure Uniform2i64vNV(location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glUniform2i64vNV';
    
    static procedure Uniform3i64vNV(location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glUniform3i64vNV';
    
    static procedure Uniform4i64vNV(location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glUniform4i64vNV';
    
    static procedure Uniform1ui64NV(location: Int32; x: UInt64);
    external 'opengl32.dll' name 'glUniform1ui64NV';
    
    static procedure Uniform2ui64NV(location: Int32; x: UInt64; y: UInt64);
    external 'opengl32.dll' name 'glUniform2ui64NV';
    
    static procedure Uniform3ui64NV(location: Int32; x: UInt64; y: UInt64; z: UInt64);
    external 'opengl32.dll' name 'glUniform3ui64NV';
    
    static procedure Uniform4ui64NV(location: Int32; x: UInt64; y: UInt64; z: UInt64; w: UInt64);
    external 'opengl32.dll' name 'glUniform4ui64NV';
    
    static procedure Uniform1ui64vNV(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniform1ui64vNV';
    
    static procedure Uniform2ui64vNV(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniform2ui64vNV';
    
    static procedure Uniform3ui64vNV(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniform3ui64vNV';
    
    static procedure Uniform4ui64vNV(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniform4ui64vNV';
    
    static procedure GetUniformi64vNV(&program: UInt32; location: Int32; &params: ^Int64);
    external 'opengl32.dll' name 'glGetUniformi64vNV';
    
    static procedure ProgramUniform1i64NV(&program: UInt32; location: Int32; x: Int64);
    external 'opengl32.dll' name 'glProgramUniform1i64NV';
    
    static procedure ProgramUniform2i64NV(&program: UInt32; location: Int32; x: Int64; y: Int64);
    external 'opengl32.dll' name 'glProgramUniform2i64NV';
    
    static procedure ProgramUniform3i64NV(&program: UInt32; location: Int32; x: Int64; y: Int64; z: Int64);
    external 'opengl32.dll' name 'glProgramUniform3i64NV';
    
    static procedure ProgramUniform4i64NV(&program: UInt32; location: Int32; x: Int64; y: Int64; z: Int64; w: Int64);
    external 'opengl32.dll' name 'glProgramUniform4i64NV';
    
    static procedure ProgramUniform1i64vNV(&program: UInt32; location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glProgramUniform1i64vNV';
    
    static procedure ProgramUniform2i64vNV(&program: UInt32; location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glProgramUniform2i64vNV';
    
    static procedure ProgramUniform3i64vNV(&program: UInt32; location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glProgramUniform3i64vNV';
    
    static procedure ProgramUniform4i64vNV(&program: UInt32; location: Int32; count: Int32; value: ^Int64);
    external 'opengl32.dll' name 'glProgramUniform4i64vNV';
    
    static procedure ProgramUniform1ui64NV(&program: UInt32; location: Int32; x: UInt64);
    external 'opengl32.dll' name 'glProgramUniform1ui64NV';
    
    static procedure ProgramUniform2ui64NV(&program: UInt32; location: Int32; x: UInt64; y: UInt64);
    external 'opengl32.dll' name 'glProgramUniform2ui64NV';
    
    static procedure ProgramUniform3ui64NV(&program: UInt32; location: Int32; x: UInt64; y: UInt64; z: UInt64);
    external 'opengl32.dll' name 'glProgramUniform3ui64NV';
    
    static procedure ProgramUniform4ui64NV(&program: UInt32; location: Int32; x: UInt64; y: UInt64; z: UInt64; w: UInt64);
    external 'opengl32.dll' name 'glProgramUniform4ui64NV';
    
    static procedure ProgramUniform1ui64vNV(&program: UInt32; location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniform1ui64vNV';
    
    static procedure ProgramUniform2ui64vNV(&program: UInt32; location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniform2ui64vNV';
    
    static procedure ProgramUniform3ui64vNV(&program: UInt32; location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniform3ui64vNV';
    
    static procedure ProgramUniform4ui64vNV(&program: UInt32; location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniform4ui64vNV';
    
    static procedure GetInternalformatSampleivNV(target: UInt32; internalformat: UInt32; samples: Int32; pname: UInt32; bufSize: Int32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetInternalformatSampleivNV';
    
    static procedure GetMemoryObjectDetachedResourcesuivNV(memory: UInt32; pname: UInt32; first: Int32; count: Int32; &params: ^UInt32);
    external 'opengl32.dll' name 'glGetMemoryObjectDetachedResourcesuivNV';
    
    static procedure ResetMemoryObjectParameterNV(memory: UInt32; pname: UInt32);
    external 'opengl32.dll' name 'glResetMemoryObjectParameterNV';
    
    static procedure TexAttachMemoryNV(target: UInt32; memory: UInt32; offset: UInt64);
    external 'opengl32.dll' name 'glTexAttachMemoryNV';
    
    static procedure BufferAttachMemoryNV(target: UInt32; memory: UInt32; offset: UInt64);
    external 'opengl32.dll' name 'glBufferAttachMemoryNV';
    
    static procedure TextureAttachMemoryNV(texture: UInt32; memory: UInt32; offset: UInt64);
    external 'opengl32.dll' name 'glTextureAttachMemoryNV';
    
    static procedure NamedBufferAttachMemoryNV(buffer: UInt32; memory: UInt32; offset: UInt64);
    external 'opengl32.dll' name 'glNamedBufferAttachMemoryNV';
    
    static procedure DrawMeshTasksNV(first: UInt32; count: UInt32);
    external 'opengl32.dll' name 'glDrawMeshTasksNV';
    
    static procedure DrawMeshTasksIndirectNV(indirect: IntPtr);
    external 'opengl32.dll' name 'glDrawMeshTasksIndirectNV';
    
    static procedure MultiDrawMeshTasksIndirectNV(indirect: IntPtr; drawcount: Int32; stride: Int32);
    external 'opengl32.dll' name 'glMultiDrawMeshTasksIndirectNV';
    
    static procedure MultiDrawMeshTasksIndirectCountNV(indirect: IntPtr; drawcount: IntPtr; maxdrawcount: Int32; stride: Int32);
    external 'opengl32.dll' name 'glMultiDrawMeshTasksIndirectCountNV';
    
    static function GenPathsNV(range: Int32): UInt32;
    external 'opengl32.dll' name 'glGenPathsNV';
    
    static procedure DeletePathsNV(path: UInt32; range: Int32);
    external 'opengl32.dll' name 'glDeletePathsNV';
    
    static function IsPathNV(path: UInt32): boolean;
    external 'opengl32.dll' name 'glIsPathNV';
    
    static procedure PathCommandsNV(path: UInt32; numCommands: Int32; commands: ^Byte; numCoords: Int32; coordType: UInt32; coords: pointer);
    external 'opengl32.dll' name 'glPathCommandsNV';
    
    static procedure PathCoordsNV(path: UInt32; numCoords: Int32; coordType: UInt32; coords: pointer);
    external 'opengl32.dll' name 'glPathCoordsNV';
    
    static procedure PathSubCommandsNV(path: UInt32; commandStart: Int32; commandsToDelete: Int32; numCommands: Int32; commands: ^Byte; numCoords: Int32; coordType: UInt32; coords: pointer);
    external 'opengl32.dll' name 'glPathSubCommandsNV';
    
    static procedure PathSubCoordsNV(path: UInt32; coordStart: Int32; numCoords: Int32; coordType: UInt32; coords: pointer);
    external 'opengl32.dll' name 'glPathSubCoordsNV';
    
    static procedure PathStringNV(path: UInt32; format: UInt32; length: Int32; pathString: pointer);
    external 'opengl32.dll' name 'glPathStringNV';
    
    static procedure PathGlyphsNV(firstPathName: UInt32; fontTarget: UInt32; fontName: pointer; fontStyle: UInt32; numGlyphs: Int32; &type: UInt32; charcodes: pointer; handleMissingGlyphs: UInt32; pathParameterTemplate: UInt32; emScale: single);
    external 'opengl32.dll' name 'glPathGlyphsNV';
    
    static procedure PathGlyphRangeNV(firstPathName: UInt32; fontTarget: UInt32; fontName: pointer; fontStyle: UInt32; firstGlyph: UInt32; numGlyphs: Int32; handleMissingGlyphs: UInt32; pathParameterTemplate: UInt32; emScale: single);
    external 'opengl32.dll' name 'glPathGlyphRangeNV';
    
    static procedure WeightPathsNV(resultPath: UInt32; numPaths: Int32; paths: ^UInt32; weights: ^single);
    external 'opengl32.dll' name 'glWeightPathsNV';
    
    static procedure CopyPathNV(resultPath: UInt32; srcPath: UInt32);
    external 'opengl32.dll' name 'glCopyPathNV';
    
    static procedure InterpolatePathsNV(resultPath: UInt32; pathA: UInt32; pathB: UInt32; weight: single);
    external 'opengl32.dll' name 'glInterpolatePathsNV';
    
    static procedure TransformPathNV(resultPath: UInt32; srcPath: UInt32; transformType: UInt32; transformValues: ^single);
    external 'opengl32.dll' name 'glTransformPathNV';
    
    static procedure PathParameterivNV(path: UInt32; pname: UInt32; value: ^Int32);
    external 'opengl32.dll' name 'glPathParameterivNV';
    
    static procedure PathParameteriNV(path: UInt32; pname: UInt32; value: Int32);
    external 'opengl32.dll' name 'glPathParameteriNV';
    
    static procedure PathParameterfvNV(path: UInt32; pname: UInt32; value: ^single);
    external 'opengl32.dll' name 'glPathParameterfvNV';
    
    static procedure PathParameterfNV(path: UInt32; pname: UInt32; value: single);
    external 'opengl32.dll' name 'glPathParameterfNV';
    
    static procedure PathDashArrayNV(path: UInt32; dashCount: Int32; dashArray: ^single);
    external 'opengl32.dll' name 'glPathDashArrayNV';
    
    static procedure PathStencilFuncNV(func: UInt32; ref: Int32; mask: UInt32);
    external 'opengl32.dll' name 'glPathStencilFuncNV';
    
    static procedure PathStencilDepthOffsetNV(factor: single; units: single);
    external 'opengl32.dll' name 'glPathStencilDepthOffsetNV';
    
    static procedure StencilFillPathNV(path: UInt32; fillMode: UInt32; mask: UInt32);
    external 'opengl32.dll' name 'glStencilFillPathNV';
    
    static procedure StencilStrokePathNV(path: UInt32; reference: Int32; mask: UInt32);
    external 'opengl32.dll' name 'glStencilStrokePathNV';
    
    static procedure StencilFillPathInstancedNV(numPaths: Int32; pathNameType: UInt32; paths: pointer; pathBase: UInt32; fillMode: UInt32; mask: UInt32; transformType: UInt32; transformValues: ^single);
    external 'opengl32.dll' name 'glStencilFillPathInstancedNV';
    
    static procedure StencilStrokePathInstancedNV(numPaths: Int32; pathNameType: UInt32; paths: pointer; pathBase: UInt32; reference: Int32; mask: UInt32; transformType: UInt32; transformValues: ^single);
    external 'opengl32.dll' name 'glStencilStrokePathInstancedNV';
    
    static procedure PathCoverDepthFuncNV(func: UInt32);
    external 'opengl32.dll' name 'glPathCoverDepthFuncNV';
    
    static procedure CoverFillPathNV(path: UInt32; coverMode: UInt32);
    external 'opengl32.dll' name 'glCoverFillPathNV';
    
    static procedure CoverStrokePathNV(path: UInt32; coverMode: UInt32);
    external 'opengl32.dll' name 'glCoverStrokePathNV';
    
    static procedure CoverFillPathInstancedNV(numPaths: Int32; pathNameType: UInt32; paths: pointer; pathBase: UInt32; coverMode: UInt32; transformType: UInt32; transformValues: ^single);
    external 'opengl32.dll' name 'glCoverFillPathInstancedNV';
    
    static procedure CoverStrokePathInstancedNV(numPaths: Int32; pathNameType: UInt32; paths: pointer; pathBase: UInt32; coverMode: UInt32; transformType: UInt32; transformValues: ^single);
    external 'opengl32.dll' name 'glCoverStrokePathInstancedNV';
    
    static procedure GetPathParameterivNV(path: UInt32; pname: UInt32; value: ^Int32);
    external 'opengl32.dll' name 'glGetPathParameterivNV';
    
    static procedure GetPathParameterfvNV(path: UInt32; pname: UInt32; value: ^single);
    external 'opengl32.dll' name 'glGetPathParameterfvNV';
    
    static procedure GetPathCommandsNV(path: UInt32; commands: ^Byte);
    external 'opengl32.dll' name 'glGetPathCommandsNV';
    
    static procedure GetPathCoordsNV(path: UInt32; coords: ^single);
    external 'opengl32.dll' name 'glGetPathCoordsNV';
    
    static procedure GetPathDashArrayNV(path: UInt32; dashArray: ^single);
    external 'opengl32.dll' name 'glGetPathDashArrayNV';
    
    static procedure GetPathMetricsNV(metricQueryMask: UInt32; numPaths: Int32; pathNameType: UInt32; paths: pointer; pathBase: UInt32; stride: Int32; metrics: ^single);
    external 'opengl32.dll' name 'glGetPathMetricsNV';
    
    static procedure GetPathMetricRangeNV(metricQueryMask: UInt32; firstPathName: UInt32; numPaths: Int32; stride: Int32; metrics: ^single);
    external 'opengl32.dll' name 'glGetPathMetricRangeNV';
    
    static procedure GetPathSpacingNV(pathListMode: UInt32; numPaths: Int32; pathNameType: UInt32; paths: pointer; pathBase: UInt32; advanceScale: single; kerningScale: single; transformType: UInt32; returnedSpacing: ^single);
    external 'opengl32.dll' name 'glGetPathSpacingNV';
    
    static function IsPointInFillPathNV(path: UInt32; mask: UInt32; x: single; y: single): boolean;
    external 'opengl32.dll' name 'glIsPointInFillPathNV';
    
    static function IsPointInStrokePathNV(path: UInt32; x: single; y: single): boolean;
    external 'opengl32.dll' name 'glIsPointInStrokePathNV';
    
    static function GetPathLengthNV(path: UInt32; startSegment: Int32; numSegments: Int32): single;
    external 'opengl32.dll' name 'glGetPathLengthNV';
    
    static function PointAlongPathNV(path: UInt32; startSegment: Int32; numSegments: Int32; distance: single; x: ^single; y: ^single; tangentX: ^single; tangentY: ^single): boolean;
    external 'opengl32.dll' name 'glPointAlongPathNV';
    
    static procedure MatrixLoad3x2fNV(matrixMode: UInt32; m: ^single);
    external 'opengl32.dll' name 'glMatrixLoad3x2fNV';
    
    static procedure MatrixLoad3x3fNV(matrixMode: UInt32; m: ^single);
    external 'opengl32.dll' name 'glMatrixLoad3x3fNV';
    
    static procedure MatrixLoadTranspose3x3fNV(matrixMode: UInt32; m: ^single);
    external 'opengl32.dll' name 'glMatrixLoadTranspose3x3fNV';
    
    static procedure MatrixMult3x2fNV(matrixMode: UInt32; m: ^single);
    external 'opengl32.dll' name 'glMatrixMult3x2fNV';
    
    static procedure MatrixMult3x3fNV(matrixMode: UInt32; m: ^single);
    external 'opengl32.dll' name 'glMatrixMult3x3fNV';
    
    static procedure MatrixMultTranspose3x3fNV(matrixMode: UInt32; m: ^single);
    external 'opengl32.dll' name 'glMatrixMultTranspose3x3fNV';
    
    static procedure StencilThenCoverFillPathNV(path: UInt32; fillMode: UInt32; mask: UInt32; coverMode: UInt32);
    external 'opengl32.dll' name 'glStencilThenCoverFillPathNV';
    
    static procedure StencilThenCoverStrokePathNV(path: UInt32; reference: Int32; mask: UInt32; coverMode: UInt32);
    external 'opengl32.dll' name 'glStencilThenCoverStrokePathNV';
    
    static procedure StencilThenCoverFillPathInstancedNV(numPaths: Int32; pathNameType: UInt32; paths: pointer; pathBase: UInt32; fillMode: UInt32; mask: UInt32; coverMode: UInt32; transformType: UInt32; transformValues: ^single);
    external 'opengl32.dll' name 'glStencilThenCoverFillPathInstancedNV';
    
    static procedure StencilThenCoverStrokePathInstancedNV(numPaths: Int32; pathNameType: UInt32; paths: pointer; pathBase: UInt32; reference: Int32; mask: UInt32; coverMode: UInt32; transformType: UInt32; transformValues: ^single);
    external 'opengl32.dll' name 'glStencilThenCoverStrokePathInstancedNV';
    
    static function PathGlyphIndexRangeNV(fontTarget: UInt32; fontName: pointer; fontStyle: UInt32; pathParameterTemplate: UInt32; emScale: single; baseAndCount: ^Vec2ui): UInt32;
    external 'opengl32.dll' name 'glPathGlyphIndexRangeNV';
    
    static function PathGlyphIndexArrayNV(firstPathName: UInt32; fontTarget: UInt32; fontName: pointer; fontStyle: UInt32; firstGlyphIndex: UInt32; numGlyphs: Int32; pathParameterTemplate: UInt32; emScale: single): UInt32;
    external 'opengl32.dll' name 'glPathGlyphIndexArrayNV';
    
    static function PathMemoryGlyphIndexArrayNV(firstPathName: UInt32; fontTarget: UInt32; fontSize: UIntPtr; fontData: pointer; faceIndex: Int32; firstGlyphIndex: UInt32; numGlyphs: Int32; pathParameterTemplate: UInt32; emScale: single): UInt32;
    external 'opengl32.dll' name 'glPathMemoryGlyphIndexArrayNV';
    
    static procedure ProgramPathFragmentInputGenNV(&program: UInt32; location: Int32; genMode: UInt32; components: Int32; coeffs: ^single);
    external 'opengl32.dll' name 'glProgramPathFragmentInputGenNV';
    
    static procedure GetProgramResourcefvNV(&program: UInt32; programInterface: UInt32; index: UInt32; propCount: Int32; props: ^UInt32; bufSize: Int32; length: ^Int32; &params: ^single);
    external 'opengl32.dll' name 'glGetProgramResourcefvNV';
    
    static procedure FramebufferSampleLocationsfvNV(target: UInt32; start: UInt32; count: Int32; v: ^single);
    external 'opengl32.dll' name 'glFramebufferSampleLocationsfvNV';
    
    static procedure NamedFramebufferSampleLocationsfvNV(framebuffer: UInt32; start: UInt32; count: Int32; v: ^single);
    external 'opengl32.dll' name 'glNamedFramebufferSampleLocationsfvNV';
    
    static procedure ResolveDepthValuesNV;
    external 'opengl32.dll' name 'glResolveDepthValuesNV';
    
    static procedure ScissorExclusiveNV(x: Int32; y: Int32; width: Int32; height: Int32);
    external 'opengl32.dll' name 'glScissorExclusiveNV';
    
    static procedure ScissorExclusiveArrayvNV(first: UInt32; count: Int32; v: ^Int32);
    external 'opengl32.dll' name 'glScissorExclusiveArrayvNV';
    
    static procedure MakeBufferResidentNV(target: UInt32; access: UInt32);
    external 'opengl32.dll' name 'glMakeBufferResidentNV';
    
    static procedure MakeBufferNonResidentNV(target: UInt32);
    external 'opengl32.dll' name 'glMakeBufferNonResidentNV';
    
    static function IsBufferResidentNV(target: UInt32): boolean;
    external 'opengl32.dll' name 'glIsBufferResidentNV';
    
    static procedure MakeNamedBufferResidentNV(buffer: UInt32; access: UInt32);
    external 'opengl32.dll' name 'glMakeNamedBufferResidentNV';
    
    static procedure MakeNamedBufferNonResidentNV(buffer: UInt32);
    external 'opengl32.dll' name 'glMakeNamedBufferNonResidentNV';
    
    static function IsNamedBufferResidentNV(buffer: UInt32): boolean;
    external 'opengl32.dll' name 'glIsNamedBufferResidentNV';
    
    static procedure GetBufferParameterui64vNV(target: UInt32; pname: UInt32; &params: ^UInt64);
    external 'opengl32.dll' name 'glGetBufferParameterui64vNV';
    
    static procedure GetNamedBufferParameterui64vNV(buffer: UInt32; pname: UInt32; &params: ^UInt64);
    external 'opengl32.dll' name 'glGetNamedBufferParameterui64vNV';
    
    static procedure GetIntegerui64vNV(value: UInt32; result: ^UInt64);
    external 'opengl32.dll' name 'glGetIntegerui64vNV';
    
    static procedure Uniformui64NV(location: Int32; value: UInt64);
    external 'opengl32.dll' name 'glUniformui64NV';
    
    static procedure Uniformui64vNV(location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glUniformui64vNV';
    
    static procedure GetUniformui64vNV(&program: UInt32; location: Int32; &params: ^UInt64);
    external 'opengl32.dll' name 'glGetUniformui64vNV';
    
    static procedure ProgramUniformui64NV(&program: UInt32; location: Int32; value: UInt64);
    external 'opengl32.dll' name 'glProgramUniformui64NV';
    
    static procedure ProgramUniformui64vNV(&program: UInt32; location: Int32; count: Int32; value: ^UInt64);
    external 'opengl32.dll' name 'glProgramUniformui64vNV';
    
    static procedure BindShadingRateImageNV(texture: UInt32);
    external 'opengl32.dll' name 'glBindShadingRateImageNV';
    
    static procedure GetShadingRateImagePaletteNV(viewport: UInt32; entry: UInt32; rate: ^UInt32);
    external 'opengl32.dll' name 'glGetShadingRateImagePaletteNV';
    
    static procedure GetShadingRateSampleLocationivNV(rate: UInt32; samples: UInt32; index: UInt32; location: ^Int32);
    external 'opengl32.dll' name 'glGetShadingRateSampleLocationivNV';
    
    static procedure ShadingRateImageBarrierNV(synchronize: boolean);
    external 'opengl32.dll' name 'glShadingRateImageBarrierNV';
    
    static procedure ShadingRateImagePaletteNV(viewport: UInt32; first: UInt32; count: Int32; rates: ^UInt32);
    external 'opengl32.dll' name 'glShadingRateImagePaletteNV';
    
    static procedure ShadingRateSampleOrderNV(order: UInt32);
    external 'opengl32.dll' name 'glShadingRateSampleOrderNV';
    
    static procedure ShadingRateSampleOrderCustomNV(rate: UInt32; samples: UInt32; locations: ^Int32);
    external 'opengl32.dll' name 'glShadingRateSampleOrderCustomNV';
    
    static procedure TextureBarrierNV;
    external 'opengl32.dll' name 'glTextureBarrierNV';
    
    static procedure VertexAttribL1i64NV(index: UInt32; x: Int64);
    external 'opengl32.dll' name 'glVertexAttribL1i64NV';
    
    static procedure VertexAttribL2i64NV(index: UInt32; x: Int64; y: Int64);
    external 'opengl32.dll' name 'glVertexAttribL2i64NV';
    
    static procedure VertexAttribL3i64NV(index: UInt32; x: Int64; y: Int64; z: Int64);
    external 'opengl32.dll' name 'glVertexAttribL3i64NV';
    
    static procedure VertexAttribL4i64NV(index: UInt32; x: Int64; y: Int64; z: Int64; w: Int64);
    external 'opengl32.dll' name 'glVertexAttribL4i64NV';
    
    static procedure VertexAttribL1i64vNV(index: UInt32; v: ^Int64);
    external 'opengl32.dll' name 'glVertexAttribL1i64vNV';
    
    static procedure VertexAttribL2i64vNV(index: UInt32; v: ^Int64);
    external 'opengl32.dll' name 'glVertexAttribL2i64vNV';
    
    static procedure VertexAttribL3i64vNV(index: UInt32; v: ^Int64);
    external 'opengl32.dll' name 'glVertexAttribL3i64vNV';
    
    static procedure VertexAttribL4i64vNV(index: UInt32; v: ^Int64);
    external 'opengl32.dll' name 'glVertexAttribL4i64vNV';
    
    static procedure VertexAttribL1ui64NV(index: UInt32; x: UInt64);
    external 'opengl32.dll' name 'glVertexAttribL1ui64NV';
    
    static procedure VertexAttribL2ui64NV(index: UInt32; x: UInt64; y: UInt64);
    external 'opengl32.dll' name 'glVertexAttribL2ui64NV';
    
    static procedure VertexAttribL3ui64NV(index: UInt32; x: UInt64; y: UInt64; z: UInt64);
    external 'opengl32.dll' name 'glVertexAttribL3ui64NV';
    
    static procedure VertexAttribL4ui64NV(index: UInt32; x: UInt64; y: UInt64; z: UInt64; w: UInt64);
    external 'opengl32.dll' name 'glVertexAttribL4ui64NV';
    
    static procedure VertexAttribL1ui64vNV(index: UInt32; v: ^UInt64);
    external 'opengl32.dll' name 'glVertexAttribL1ui64vNV';
    
    static procedure VertexAttribL2ui64vNV(index: UInt32; v: ^UInt64);
    external 'opengl32.dll' name 'glVertexAttribL2ui64vNV';
    
    static procedure VertexAttribL3ui64vNV(index: UInt32; v: ^UInt64);
    external 'opengl32.dll' name 'glVertexAttribL3ui64vNV';
    
    static procedure VertexAttribL4ui64vNV(index: UInt32; v: ^UInt64);
    external 'opengl32.dll' name 'glVertexAttribL4ui64vNV';
    
    static procedure GetVertexAttribLi64vNV(index: UInt32; pname: UInt32; &params: ^Int64);
    external 'opengl32.dll' name 'glGetVertexAttribLi64vNV';
    
    static procedure GetVertexAttribLui64vNV(index: UInt32; pname: UInt32; &params: ^UInt64);
    external 'opengl32.dll' name 'glGetVertexAttribLui64vNV';
    
    static procedure VertexAttribLFormatNV(index: UInt32; size: Int32; &type: UInt32; stride: Int32);
    external 'opengl32.dll' name 'glVertexAttribLFormatNV';
    
    static procedure BufferAddressRangeNV(pname: UInt32; index: UInt32; address: UInt64; length: UIntPtr);
    external 'opengl32.dll' name 'glBufferAddressRangeNV';
    
    static procedure VertexFormatNV(size: Int32; &type: UInt32; stride: Int32);
    external 'opengl32.dll' name 'glVertexFormatNV';
    
    static procedure NormalFormatNV(&type: UInt32; stride: Int32);
    external 'opengl32.dll' name 'glNormalFormatNV';
    
    static procedure ColorFormatNV(size: Int32; &type: UInt32; stride: Int32);
    external 'opengl32.dll' name 'glColorFormatNV';
    
    static procedure IndexFormatNV(&type: UInt32; stride: Int32);
    external 'opengl32.dll' name 'glIndexFormatNV';
    
    static procedure TexCoordFormatNV(size: Int32; &type: UInt32; stride: Int32);
    external 'opengl32.dll' name 'glTexCoordFormatNV';
    
    static procedure EdgeFlagFormatNV(stride: Int32);
    external 'opengl32.dll' name 'glEdgeFlagFormatNV';
    
    static procedure SecondaryColorFormatNV(size: Int32; &type: UInt32; stride: Int32);
    external 'opengl32.dll' name 'glSecondaryColorFormatNV';
    
    static procedure FogCoordFormatNV(&type: UInt32; stride: Int32);
    external 'opengl32.dll' name 'glFogCoordFormatNV';
    
    static procedure VertexAttribFormatNV(index: UInt32; size: Int32; &type: UInt32; normalized: boolean; stride: Int32);
    external 'opengl32.dll' name 'glVertexAttribFormatNV';
    
    static procedure VertexAttribIFormatNV(index: UInt32; size: Int32; &type: UInt32; stride: Int32);
    external 'opengl32.dll' name 'glVertexAttribIFormatNV';
    
    static procedure GetIntegerui64i_vNV(value: UInt32; index: UInt32; result: ^UInt64);
    external 'opengl32.dll' name 'glGetIntegerui64i_vNV';
    
    static procedure ViewportSwizzleNV(index: UInt32; swizzlex: UInt32; swizzley: UInt32; swizzlez: UInt32; swizzlew: UInt32);
    external 'opengl32.dll' name 'glViewportSwizzleNV';
    
    static procedure FramebufferTextureMultiviewOVR(target: UInt32; attachment: UInt32; texture: UInt32; level: Int32; baseViewIndex: Int32; numViews: Int32);
    external 'opengl32.dll' name 'glFramebufferTextureMultiviewOVR';
    
    static procedure AlphaFunc(func: UInt32; ref: single);
    external 'opengl32.dll' name 'glAlphaFunc';
    
    static procedure &Begin(mode: UInt32);
    external 'opengl32.dll' name 'glBegin';
    
    static procedure Bitmap(width: Int32; height: Int32; xorig: single; yorig: single; xmove: single; ymove: single; bitmap: ^Byte);
    external 'opengl32.dll' name 'glBitmap';
    
    static procedure CallLists(n: Int32; &type: UInt32; lists: pointer);
    external 'opengl32.dll' name 'glCallLists';
    
    static procedure ClientActiveTexture(texture: UInt32);
    external 'opengl32.dll' name 'glClientActiveTexture';
    
    static procedure Color4f(red: single; green: single; blue: single; alpha: single);
    external 'opengl32.dll' name 'glColor4f';
    
    static procedure Color4fv(v: ^single);
    external 'opengl32.dll' name 'glColor4fv';
    
    static procedure Color4ub(red: Byte; green: Byte; blue: Byte; alpha: Byte);
    external 'opengl32.dll' name 'glColor4ub';
    
    static procedure ColorMask(red: Byte; green: Byte; blue: Byte; alpha: Byte);
    external 'opengl32.dll' name 'glColorMask';
    
    static procedure ColorPointer(size: Int32; &type: UInt32; stride: Int32; _pointer: pointer);
    external 'opengl32.dll' name 'glColorPointer';
    
    static procedure ColorSubTableEXT(target: UInt32; start: Int32; count: Int32; format: UInt32; &type: UInt32; table: pointer);
    external 'opengl32.dll' name 'glColorSubTableEXT';
    
    static procedure ColorTableEXT(target: UInt32; internalformat: UInt32; width: Int32; format: UInt32; &type: UInt32; table: pointer);
    external 'opengl32.dll' name 'glColorTableEXT';
    
    static procedure CopyPixels(x: Int32; y: Int32; width: Int32; height: Int32; &type: UInt32);
    external 'opengl32.dll' name 'glCopyPixels';
    
    static procedure DepthMask(flag: Byte);
    external 'opengl32.dll' name 'glDepthMask';
    
    static procedure DisableClientState(&array: UInt32);
    external 'opengl32.dll' name 'glDisableClientState';
    
    static procedure DrawPixels(width: Int32; height: Int32; format: UInt32; &type: UInt32; pixels: pointer);
    external 'opengl32.dll' name 'glDrawPixels';
    
    static procedure EnableClientState(&array: UInt32);
    external 'opengl32.dll' name 'glEnableClientState';
    
    static procedure &End;
    external 'opengl32.dll' name 'glEnd';
    
    static procedure EndList;
    external 'opengl32.dll' name 'glEndList';
    
    static procedure Frustumf(left: single; right: single; bottom: single; top: single; zNear: single; zFar: single);
    external 'opengl32.dll' name 'glFrustumf';
    
    static function GenLists(range: Int32): UInt32;
    external 'opengl32.dll' name 'glGenLists';
    
    static procedure GetBooleanv(pname: UInt32; &params: ^Byte);
    external 'opengl32.dll' name 'glGetBooleanv';
    
    static procedure GetColorTableEXT(target: UInt32; format: UInt32; &type: UInt32; table: pointer);
    external 'opengl32.dll' name 'glGetColorTableEXT';
    
    static procedure GetColorTableParameterivEXT(target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetColorTableParameterivEXT';
    
    static procedure GetLightfv(light: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetLightfv';
    
    static procedure GetMaterialfv(face: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetMaterialfv';
    
    static procedure GetPointerv(pname: UInt32; &params: ^pointer);
    external 'opengl32.dll' name 'glGetPointerv';
    
    static procedure GetPolygonStipple(mask: ^Byte);
    external 'opengl32.dll' name 'glGetPolygonStipple';
    
    static procedure GetTexEnvfv(target: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glGetTexEnvfv';
    
    static procedure GetTexEnviv(target: UInt32; pname: UInt32; &params: ^Int32);
    external 'opengl32.dll' name 'glGetTexEnviv';
    
    static procedure Lightfv(light: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glLightfv';
    
    static procedure LightModelfv(pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glLightModelfv';
    
    static procedure LineStipple(factor: Int32; pattern: UInt16);
    external 'opengl32.dll' name 'glLineStipple';
    
    static procedure ListBase(base: UInt32);
    external 'opengl32.dll' name 'glListBase';
    
    static procedure LoadIdentity;
    external 'opengl32.dll' name 'glLoadIdentity';
    
    static procedure LoadMatrixf(m: ^single);
    external 'opengl32.dll' name 'glLoadMatrixf';
    
    static procedure Materialf(face: UInt32; pname: UInt32; param: single);
    external 'opengl32.dll' name 'glMaterialf';
    
    static procedure Materialfv(face: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glMaterialfv';
    
    static procedure MatrixMode(mode: UInt32);
    external 'opengl32.dll' name 'glMatrixMode';
    
    static procedure MultMatrixf(m: ^single);
    external 'opengl32.dll' name 'glMultMatrixf';
    
    static procedure MultiTexCoord2f(target: UInt32; s: single; t: single);
    external 'opengl32.dll' name 'glMultiTexCoord2f';
    
    static procedure MultiTexCoord2fv(target: UInt32; v: ^single);
    external 'opengl32.dll' name 'glMultiTexCoord2fv';
    
    static procedure NewList(list: UInt32; mode: UInt32);
    external 'opengl32.dll' name 'glNewList';
    
    static procedure Normal3f(nx: single; ny: single; nz: single);
    external 'opengl32.dll' name 'glNormal3f';
    
    static procedure Normal3fv(v: ^single);
    external 'opengl32.dll' name 'glNormal3fv';
    
    static procedure NormalPointer(&type: UInt32; stride: Int32; _pointer: pointer);
    external 'opengl32.dll' name 'glNormalPointer';
    
    static procedure Orthof(left: single; right: single; bottom: single; top: single; zNear: single; zFar: single);
    external 'opengl32.dll' name 'glOrthof';
    
    static procedure PolygonStipple(mask: ^Byte);
    external 'opengl32.dll' name 'glPolygonStipple';
    
    static procedure PopMatrix;
    external 'opengl32.dll' name 'glPopMatrix';
    
    static procedure PushMatrix;
    external 'opengl32.dll' name 'glPushMatrix';
    
    static procedure RasterPos3f(x: single; y: single; z: single);
    external 'opengl32.dll' name 'glRasterPos3f';
    
    static procedure Rotatef(angle: single; x: single; y: single; z: single);
    external 'opengl32.dll' name 'glRotatef';
    
    static procedure Scalef(x: single; y: single; z: single);
    external 'opengl32.dll' name 'glScalef';
    
    static procedure ShadeModel(mode: UInt32);
    external 'opengl32.dll' name 'glShadeModel';
    
    static procedure TexCoordPointer(size: Int32; &type: UInt32; stride: Int32; _pointer: pointer);
    external 'opengl32.dll' name 'glTexCoordPointer';
    
    static procedure TexEnvfv(target: UInt32; pname: UInt32; &params: ^single);
    external 'opengl32.dll' name 'glTexEnvfv';
    
    static procedure TexEnvi(target: UInt32; pname: UInt32; param: Int32);
    external 'opengl32.dll' name 'glTexEnvi';
    
    static procedure Translatef(x: single; y: single; z: single);
    external 'opengl32.dll' name 'glTranslatef';
    
    static procedure Vertex2f(x: single; y: single);
    external 'opengl32.dll' name 'glVertex2f';
    
    static procedure Vertex2fv(v: ^single);
    external 'opengl32.dll' name 'glVertex2fv';
    
    static procedure Vertex3f(x: single; y: single; z: single);
    external 'opengl32.dll' name 'glVertex3f';
    
    static procedure Vertex3fv(v: ^single);
    external 'opengl32.dll' name 'glVertex3fv';
    
    static procedure VertexPointer(size: Int32; &type: UInt32; stride: Int32; _pointer: pointer);
    external 'opengl32.dll' name 'glVertexPointer';
    
    {$endregion unsorted}
    
  end;

end.