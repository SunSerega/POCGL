


__kernel void MatrMltVec(__global double* M, __global double* V1, __global double* V2, __global int* gV1W)
{
	int i = get_global_id(0);
	int V1W = *gV1W;
	
	double sum = 0.0;
	for (int j=0; j<V1W; j++)
		sum += M[j + i*V1W] * V1[j];
	
	V2[i] = sum;
}


