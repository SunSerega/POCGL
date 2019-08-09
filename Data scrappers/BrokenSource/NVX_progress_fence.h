
uint glCreateProgressFenceNVX();
void glSignalSemaphoreui64NVX(uint signalGpu, sizei fenceObjectCount, const uint *semaphoreArray, const uint64 *fenceValueArray);
void glWaitSemaphoreui64NVX(uint waitGpu, sizei fenceObjectCount, const uint *semaphoreArray, const uint64 *fenceValueArray);
void glClientWaitSemaphoreui64NVX(sizei fenceObjectCount, const uint *semaphoreArray, const uint64 *fenceValueArray);
