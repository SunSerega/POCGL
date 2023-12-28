


kernel void CopySheetRect(
	global uint* old_data, uint old_shift, uint old_row_len,
	global uint* new_data, uint new_shift, uint new_row_len
) {
	uint x = get_global_id(0);
	uint y = get_global_id(1);
	
	global uint* old_ptr = &old_data[old_shift + x + y*old_row_len];
	global uint* new_ptr = &new_data[new_shift + x + y*new_row_len];
	
	*new_ptr = *old_ptr;
}

// map multiple points of old_data to single point of new_data
// old_shift_x and old_shift_y count in new_data points
// old_row_len counts in old_data points
kernel void UpScaleSheet(
	global uint* old_data, uint old_shift_x, uint old_shift_y, uint old_row_len,
	global uint* new_data, uint new_shift, uint new_row_len,
	int scale_change
) {
	uint x = get_global_id(0);
	uint y = get_global_id(1);
	
	global uint* old_ptr = &old_data[((x+old_shift_x)>>scale_change) + ((y+old_shift_y)>>scale_change)*old_row_len];
	global uint* new_ptr = &new_data[new_shift + x + y*new_row_len];
	
	*new_ptr = *old_ptr;
}

// map multiple points of new_data to single point of old_data
// old_shift and old_row_len count in old_data points
kernel void DownScaleSheet(
	global uint* old_data, uint old_shift, uint old_row_len,
	global uint* new_data, uint new_shift, uint new_row_len,
	int scale_change
) {
	uint x = get_global_id(0);
	uint y = get_global_id(1);
	
	uint old_scale_shift = 1u << (scale_change-1);
	
	constant static uint SIGN_BIT_MASK = 1u << 31;
	constant static uint SIGN_BIT_ANTI_MASK = ~SIGN_BIT_MASK;
	constant static uint avg_c = 2;
	constant static uint avg_area = avg_c*avg_c;
	
	uint done_count = avg_area/2;
	uint steps_sum = avg_area/2;
	
	for (uint dy=0; dy<avg_c; ++dy)
		for (uint dx=0; dx<avg_c; ++dx) {
			//uint old_v = old_data[old_shift + ((x<<scale_change)+dx*old_scale_shift) + ((y<<scale_change)+dy*old_scale_shift)*old_row_len];
			uint old_v = old_data[old_shift + ((2*x+dx)<<(scale_change-1)) + ((2*y+dy)<<(scale_change-1))*old_row_len];
			done_count += old_v >> 31;
			steps_sum += old_v & SIGN_BIT_ANTI_MASK;
		}
	
	new_data[new_shift + x + y*new_row_len] = (done_count/avg_area*SIGN_BIT_MASK) ^ (steps_sum/avg_area);
}


