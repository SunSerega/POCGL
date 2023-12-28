#pragma OPENCL EXTENSION cl_khr_byte_addressable_store: enable
#pragma OPENCL EXTENSION cl_khr_global_int32_base_atomics : enable



//TODO Попробовать менять x и y местами, для более эффективного доступа к памяти

//TODO Minimize code dupe, using this:
// - https://registry.khronos.org/OpenCL/specs/3.0-unified/html/OpenCL_C.html#declaring-and-using-a-block

constant uint SIGN_BIT_MASK = 1u << 31;
constant uint SIGN_BIT_ANTI_MASK = ~SIGN_BIT_MASK;



void err_cond(bool cond, uint err_if_cond, uint* err) {
	if (!cond) return;
	uint no_err = CCEE_OK;
	if (!atomic_compare_exchange_strong((global volatile atomic_uint*)err, &no_err, err_if_cond)) return;
	err[1] = get_global_id(0);
	err[2] = get_global_id(1);
}



// A fixed point number described as an array of uint-s
// The point is placed after Z_INT_BITS bits
// With first of the int bits being used as a the sign
typedef struct {
    uint words[POINT_COMPONENT_WORD_COUNT];
} point_component;

// x += a
void point_component_add(point_component* x, const point_component a, uint* err) {
	uint x_sign = x->words[0] & SIGN_BIT_MASK;
	uint a_sign = a.words[0] & SIGN_BIT_MASK;
	long a_mlt = x_sign == a_sign ? +1 : -1;
	
	// a_mlt = +1: 0 .. 2^33-1
	// a_mlt = -1: -(2^32-1) .. +(2^32-1)
	long carry = 0; // -(2^32-1) .. 2^33-1
	for (int i = POINT_COMPONENT_WORD_COUNT-1; i>0; --i) {
		carry += x->words[i];
		carry += a_mlt * (long)a.words[i];
		x->words[i] = carry;
		carry >>= 32;
	}
	x->words[0] += carry;
	x->words[0] += a_mlt * (long)(a.words[0] & SIGN_BIT_ANTI_MASK);
	
	if (x_sign != (x->words[0] & SIGN_BIT_MASK)) {
		if (x_sign == a_sign)
			err_cond(true, CCEE_OVERFLOW, err);
		else {
			bool compliment = true;
			for (int i = POINT_COMPONENT_WORD_COUNT-1; i>0; --i) {
				x->words[i] = ~x->words[i] + compliment;
				compliment = compliment && !x->words[i];
				// Need to flip the rest of words
				//if (!compliment) break;
			}
			x->words[0] = SIGN_BIT_MASK ^ ~x->words[0] + compliment;
		}
	}
	
}

// x = (x*m) << 1
// Or, in other words:
// x = (x*m) * 2
void point_component_mul_shl1(point_component* x, const point_component m, uint* err) {
	uint res[POINT_COMPONENT_WORD_COUNT*2] = {};
	
	constant static uint RES_EXTRA_SHIFT = 1;
	constant static uint RES_SHL = Z_INT_BITS + RES_EXTRA_SHIFT;
	constant static uint RES_SHR = 32u - RES_SHL;
	// 0.111|10
	// When cutting off last 2 bits, this needs to be rounded up to "1.000"
	// Add "0.000|10" to initial state to automatically achive that
	// "res[xi] = carry" will only override "res[0..POINT_COMPONENT_WORD_COUNT-1]"
	res[POINT_COMPONENT_WORD_COUNT] = 1 << (RES_SHR-1);
	
	uint x_sign = x->words[0] & SIGN_BIT_MASK;
	uint m_sign = m.words[0] & SIGN_BIT_MASK;
	
	ulong x_abs = x->words[0] & SIGN_BIT_ANTI_MASK;
	ulong m_abs = m.words[0] & SIGN_BIT_ANTI_MASK;
	
	for (int xi = POINT_COMPONENT_WORD_COUNT-1; xi>0; --xi) {
		ulong curr_x = x->words[xi];
		// max: carry + 2^32-1 + (2^32-1)^2
		// max: carry + 2^32-1 + 2^64 - 2*2^32 + 1
		// max: carry + 2^64 - 2^32
		ulong carry = 0; // 0 .. 2^64-1
		
		for (int mi = POINT_COMPONENT_WORD_COUNT-1; mi>0; --mi) {
			uint* el = &res[xi+mi+1];
			carry += *el;
			carry += curr_x * (ulong)m.words[mi];
			*el = carry;
			carry >>= 32;
		}
		
		{
			uint* el = &res[xi+1];
			carry += *el;
			carry += curr_x * m_abs;
			*el = carry;
			carry >>= 32;
		}
		
		res[xi] = carry;
	}
	
	{
		ulong curr_x = x_abs;
		// max: carry + 2^32-1 + (2^31-1)*(2^32-1)
		// max: carry + 2^32 - 1 + 2^63 - 2^31 - 2^32 + 1
		// max: carry + 2^63 - 2^31
		ulong carry = 0; // 0 .. 2^63-1, because x_abs is only 31 bits
		
		for (int mi = POINT_COMPONENT_WORD_COUNT-1; mi>0; --mi) {
			uint* el = &res[mi+1];
			carry += *el;
			carry += curr_x * (ulong)m.words[mi];
			*el = carry;
			carry >>= 32;
		}
		
		{
			uint* el = &res[1];
			carry += *el;
			carry += curr_x * m_abs;
			*el = carry;
			carry >>= 32;
		}
		
		res[0] = carry;
	}
	
	// In "res" decimal point is after Z_INT_BITS*2 bits
	// But when stored in "x" - first Z_INT_BITS must be empty
	// Then one more bit (the sign) should also not be overriden
	// And everything is shifted by 1 more bit (shl1 in function name), equivalent to implicit *= 2
	constant static uint RES_DUMMY_BITS = Z_INT_BITS + 1 + RES_EXTRA_SHIFT;
	err_cond(res[0] >> (32u-RES_DUMMY_BITS), CCEE_OVERFLOW, err);
	
	x->words[0] = (x_sign ^ m_sign) ^ (res[0] << RES_SHL) ^ (res[1] >> RES_SHR);
	for (int i = 1; i<POINT_COMPONENT_WORD_COUNT; ++i)
		x->words[i] = (res[i] << RES_SHL) ^ (res[i+1] >> RES_SHR);
	
}

// x = sqr(x)
void point_component_sqr(point_component* x, uint* err) {
	uint res[POINT_COMPONENT_WORD_COUNT*2] = {};
	
	constant static uint RES_SHL = Z_INT_BITS;
	constant static uint RES_SHR = 32u - RES_SHL;
	res[POINT_COMPONENT_WORD_COUNT] = 1 << (RES_SHR-1);
	
	//   123
	// x 123
	// =====
	//   369
	//  246
	// 123
	// =====
	// 15129
	
	// 3*3 is unique, but 3*2 is done twice, and so is every pair of different digits
	// So Sqr can be optimized to only do ~half of all digit multiplications
	// To minimize multi-pass, the order will be:
	
	//   123
	// x 123
	// =====
	//     9
	// -----
	//   46
	//    ^
	// -----
	// 123
	//  ^^
	// =====
	// 15129
	
	for (int i1 = POINT_COMPONENT_WORD_COUNT-1; i1>0; --i1) {
		ulong curr_x = x->words[i1];
		ulong carry = 0; // 0 .. 2^33-1
		
		for (int i2 = POINT_COMPONENT_WORD_COUNT-1; i2>i1; --i2) {
			uint* el = &res[i1+i2+1];
			
			ulong old_res = *el + carry; // 0 .. 3*2^32 - 2
			ulong mlt_res = curr_x * (ulong)x->words[i2]; // 0 .. 2^64 - 2^33 + 1
			// carry = old_res + 2*mlt_res; // 0 .. 2^65 - 2^32 // Doesn't work, need uint65
			
			*el = old_res + (mlt_res << 1);
			// Pre-move "old_res" 1 to the right, to not overflow
			// But pre-move here is minimal to not loose precision
			carry = ((old_res >> 1) + mlt_res) >> 31; // 0 .. 2^33-1
			
		}
		
		{
			uint* el = &res[i1*2+1];
			
			carry += *el; // 0 .. 2^33-2
			carry += curr_x*curr_x; // 0 .. 2^64 - 1
			
			*el = carry;
			carry >>= 32;
		}
		
		res[i1*2] = carry;
	}
	
	{
		// sign of x*x is always +
		ulong curr_x = x->words[0] & SIGN_BIT_ANTI_MASK;
		ulong carry = 0;
		
		for (int i2 = POINT_COMPONENT_WORD_COUNT-1; i2>0; --i2) {
			uint* el = &res[i2+1];
			
			ulong old_res = *el + carry;
			ulong mlt_res = curr_x * (ulong)x->words[i2];
			
			*el = old_res + (mlt_res << 1);
			carry = ((old_res >> 1) + mlt_res) >> 31;
			
		}
		
		{
			uint* el = &res[1];
			
			carry += *el;
			carry += curr_x*curr_x;
			
			*el = carry;
			carry >>= 32;
		}
		
		res[0] = carry;
	}
	
	constant static uint RES_DUMMY_BITS = Z_INT_BITS + 1;
	err_cond(res[0] >> (32u-RES_DUMMY_BITS), CCEE_OVERFLOW, err);
	
	x->words[0] = (res[0] << RES_SHL) ^ (res[1] >> RES_SHR);
	for (int i = 1; i<POINT_COMPONENT_WORD_COUNT; ++i)
		x->words[i] = (res[i] << RES_SHL) ^ (res[i+1] >> RES_SHR);
	
}

// Add bit at "bit_pos" to "x" multiple ("mlt"+0.5) times
// x += (1/2)^(bit_pos-Z_INT_BITS+1) * (mlt+0.5)
void point_component_add_bit_mlt(point_component* x, uint bit_pos, uint mlt, uint* err) {
	err_cond(mlt>=BLOCK_W, CCEE_OVERFLOW, err);
	
	// Add 0.5 to mlt
	bit_pos += 1;
	long l_mlt = (long)mlt*2+1;
	
	uint word_inner_pos = bit_pos % 32;
	uint word_ind = bit_pos / 32;
	err_cond(word_ind>=POINT_COMPONENT_WORD_COUNT, CCEE_BAD_BIT_IND, err);
	
	long carry = l_mlt << (31-word_inner_pos); // will not overflow, because mlt<BLOCK_W
	uint x_sign = x->words[0] & SIGN_BIT_MASK;
	if (x_sign) carry = -carry;
	
	for (int i = word_ind; i>0; --i) {
		carry += x->words[i];
		x->words[i] = carry;
		carry >>= 32;
	}
	
	{
		carry += x->words[0] & SIGN_BIT_ANTI_MASK;
		x->words[0] = carry ^ x_sign;
	}
	
	//if (x_sign) carry = -carry;
	err_cond(carry>>31, CCEE_OVERFLOW, err);
}



typedef struct {
	// Real and imaginary components of complex number
	point_component r, i;
} point_pos;

// x += a
void point_add(point_pos* x, const point_pos a, uint* err) {
    point_component_add(&x->r, a.r, err);
    point_component_add(&x->i, a.i, err);
}

// x = sqr(x)
void point_sqr(point_pos* x, uint* err) {
	// x*x =
	// = (x.r + x.i*i)*(x.r + x.i*i) =
	// = (sqr(x.r) - sqr(x.i)) + 2*(x.r*x.i)*i
	
	// x_i_sqr = sqr(x.i)
	point_component x_i_sqr = x->i;
	point_component_sqr(&x_i_sqr, err);
	
	// x.i = (x.r*x.i) << 1
	point_component_mul_shl1(&x->i, x->r, err);
	
	// x.r = sqr(x.r)
	point_component_sqr(&x->r, err);
	
	// x.r -= x_i_sqr
	x_i_sqr.words[0] ^= SIGN_BIT_MASK;
	point_component_add(&x->r, x_i_sqr, err);
	
}

// |x| >= 2
// sqr(x.r)+sqr(x.i) >= 4
bool point_too_big(const point_pos x, uint* err) {
	constant static uint Z_V_2 = (SIGN_BIT_MASK >> (Z_INT_BITS-2));
	constant static uint Z_V_4 = (SIGN_BIT_MASK >> (Z_INT_BITS-3));
	
	if ((x.r.words[0] & SIGN_BIT_ANTI_MASK) >= Z_V_2) return true;
	if ((x.i.words[0] & SIGN_BIT_ANTI_MASK) >= Z_V_2) return true;
	
	point_component r2 = x.r;
	point_component_sqr(&r2, err);
	if (r2.words[0] >= Z_V_4) return true;
	
	point_component i2 = x.i;
	point_component_sqr(&i2, err);
	if (i2.words[0] >= Z_V_4) return true;
	
	point_component_add(&r2, i2, err);
	// Should be >4 instead of >=4
	// But we don't account here for bits in lower words
	// And exactly =4 is a point, impossible to see in an image
	// While checking for =4 would require adding +1 to Z_INT_BITS
	if (r2.words[0] >= Z_V_4) return true;
	
	return false;
}



typedef struct {
    uint state; // 0 if need calculation, 1 if finished
    uint steps; // number of steps already taken
	point_pos last_z;
} point_info;

// block				- current block of BLOCK_W*BLOCK_W points
// pos00				- the "c" value of block[0,0] point
// point_size_bit_pos	- index of bit, which, when set alone, results in size of 1 point
// step_count			- number of steps to try at once
// update_count			- will add 1 every time next z value is computed
// err					- will set !0 if there was an error during calculation
kernel void MandelbrotBlockSteps(
	global point_info* block,
	constant point_pos* pos00,
	int point_size_bit_pos,
	int step_count,
	global volatile uint* update_count,
	global uint* err
) {
	uint x = get_global_id(0);
	uint y = get_global_id(1);
	
	uint point_ind = x + y*BLOCK_W;
	global point_info* point = &block[point_ind];
	if (point->state) return;
	point_pos z = point->last_z;
	
	point_pos c = *pos00;
	point_component_add_bit_mlt(&c.r, point_size_bit_pos, x, err);
	point_component_add_bit_mlt(&c.i, point_size_bit_pos, y, err);
	
	bool any_step_done = false;
	while (step_count > 0) {
		step_count -= 1;
		atomic_inc(update_count);
		
		point_sqr(&z, err);
		point_add(&z, c, err);
		
		if (point_too_big(z, err)) {
			point->state = 1;
			break;
		}
		
		point->steps += 1;
		any_step_done = true;
	}
	if (!any_step_done) return;
	point->last_z = z;
}



kernel void ExtractSteps(
	global point_info* block,
	global uint* result_data, uint result_shift, uint result_row_len,
	global volatile uint* extracted_count
) {
	uint x = get_global_id(0);
	uint y = get_global_id(1);
	
	bool new_done = block[x + y*BLOCK_W].state != 0;
	uint new_steps = block[x + y*BLOCK_W].steps & SIGN_BIT_ANTI_MASK;
	uint new_data = (new_done ? SIGN_BIT_MASK : 0) ^ new_steps;
	
	global uint* p_result_data = &result_data[result_shift + x + y*result_row_len];
	uint old_data = *p_result_data;
	bool old_done = old_data>>31;
	uint old_steps = old_data & SIGN_BIT_ANTI_MASK;
	
	// Попробовал быстрее избавится от артефактов на границе белой области, но pow значительно замедляет кадр
	//old_steps *= pow(0.9, frames_since_sheet_transfer);
	
	//if (new_data > old_data)
	if (new_done>=old_done || new_steps>=old_steps) {
		atomic_inc(extracted_count);
		*p_result_data = new_data;
	}
	
}


