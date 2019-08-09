
uint glAsyncCopyImageSubDataNVX( sizei waitSemaphoreCount, const uint *waitSemaphoreArray, const uint64 *waitValueArray, uint srcGpu, GLbitfield dstGpuMask, uint srcName, GLenum srcTarget, int srcLevel, int srcX, int srcY, int srcZ, uint dstName, GLenum dstTarget, int dstLevel, int dstX, int dstY, int dstZ,  sizei srcWidth, sizei srcHeight, sizei srcDepth, sizei signalSemaphoreCount, const uint *signalSemaphoreArray, const uint64 *signalValueArray);
sync glAsyncCopyBufferSubDataNVX( sizei waitSemaphoreCount, const uint *waitSemaphoreArray, const uint64 *fenceValueArray, uint readGpu, GLbitfield writeGpuMask, uint readBuffer, uint writeBuffer, GLintptr readOffset, GLintptr writeOffset, sizeiptr size, sizei signalSemaphoreCount, const uint *signalSemaphoreArray, const uint64 *signalValueArray);
void glUploadGpuMaskNVX(bitfield mask);
void glMulticastViewportArrayvNVX(uint gpu, uint first, sizei count, const float *v);
void glMulticastScissorArrayvNVX(uint gpu, uint first, sizei count, const int *v);
void glMulticastViewportPositionWScaleNVX(uint gpu, uint index, float xcoeff, float ycoeff);
