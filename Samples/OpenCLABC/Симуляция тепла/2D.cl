#pragma OPENCL EXTENSION cl_khr_fp64: enable



#define ValAt(B,X,Y) (B)[(X) + (Y)*W]

__kernel void CalcTick(__global double* B, __global double* BRes, int W)
{
	int X = get_global_id(0);
	int Y = get_global_id(1);
	
	int c = 1;
	double sum = ValAt(B, X,Y);
	
	if (X != 0)   { c++; sum += ValAt(B, X-1,Y-0); }
	if (Y != 0)   { c++; sum += ValAt(B, X-0,Y-1); }
	if (X != W-1) { c++; sum += ValAt(B, X+1,Y+0); }
	if (Y != W-1) { c++; sum += ValAt(B, X+0,Y+1); }
	
	ValAt(BRes, X,Y) = sum / c;
}


