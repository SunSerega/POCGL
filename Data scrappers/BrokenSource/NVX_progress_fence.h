
uint CreateProgressFenceNVX();
void SignalSemaphoreui64NVX(uint signalGpu, sizei fenceObjectCount, const uint *semaphoreArray, const uint64 *fenceValueArray);
void WaitSemaphoreui64NVX(uint waitGpu, sizei fenceObjectCount, const uint *semaphoreArray, const uint64 *fenceValueArray);
void ClientWaitSemaphoreui64NVX(sizei fenceObjectCount, const uint *semaphoreArray, const uint64 *fenceValueArray);
