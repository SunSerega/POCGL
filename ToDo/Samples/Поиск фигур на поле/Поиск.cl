


typedef struct _Color {
	uint val;
	
} Color;

gentype f1(gentype x) {
	return x;
}

__kernel void FillWrite(__global Color* bitmap, int W, int H) {
	int cX = get_global_id(0);
	int cY = get_global_id(1);
	
	Color c = {12345};
	
	bitmap[cY*W + cX] = 0;
	
}


