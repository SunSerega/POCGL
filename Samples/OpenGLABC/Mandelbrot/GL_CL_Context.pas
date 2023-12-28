unit GL_CL_Context;

{$savepcu false} //TODO

uses System;

uses OpenGL;
uses OpenGLABC;

uses OpenCL;
uses OpenCLABC;

procedure Init(hdc: gdi_device_context);
begin
  
  {$ifdef DEBUG}
  if wgl.GetCurrentDC<>hdc then
    raise new InvalidOperationException;
  if wgl.GetCurrentContext<>RedrawHelper.CurrentThreadContext then
    raise new InvalidOperationException;
  {$endif DEBUG}
  
  var cl_c_props := |
    OpenCL.clContextProperties.GL_CONTEXT, new OpenCL.clContextProperties(RedrawHelper.CurrentThreadContext.val),
    OpenCL.clContextProperties.WGL_HDC, new OpenCL.clContextProperties(hdc.val),
//    OpenCL.clContextProperties.CONTEXT_PLATFORM, new OpenCL.clContextProperties(pl.Native.val),
    default(OpenCL.clContextProperties)
  |;
  
//  var pl := CLPlatform.All.First;
  var cl_dvcs: array of cl_device_id;
  //TODO Если не указать платформу в cl_c_props - тут получение устройств говорит что платформа неправильная
//  clGLSharingKHR.PlatformLess
////  clGLSharingKHR.Create(CLCOntext.Default.MainDevice.BaseCLPlatform.Native)
//  .GetGLContextInfoKHR_DEVICES_FOR_GL_CONTEXT(cl_c_props[0], cl_dvcs).RaiseIfError;
  cl_dvcs := |CLContext.Default.AllDevices.Single.Native|;
  
  var ec: clErrorCode;
  var cl_c := cl.CreateContext(cl_c_props, cl_dvcs.Length, cl_dvcs, nil, IntPtr.Zero, ec);
  ec.RaiseIfError;
  
  OpenCLABC.CLContext.Default := new CLContext(cl_c, false);
end;

procedure WrapBuffer<T>(gl_b: gl_buffer; var cl_a: CLArray<T>); where T: record;
begin
  
  var ec: clErrorCode;
  //TODO .PlatformLess может быть проблемой, но пока не проявилось...
  var cl_b := clGlSharingKHR.PlatformLess.CreateFromGLBuffer(CLContext.Default.Native, clMemFlags.MEM_READ_WRITE, gl_b.val, ec);
  ec.RaiseIfError;
  
  if cl_a<>nil then
    cl_a.Dispose;
  cl_a := new CLArray<T>(cl_b, false, false);
end;

end.