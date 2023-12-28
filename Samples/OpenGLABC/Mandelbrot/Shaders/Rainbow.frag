#version 460 core

noperspective in vec2 screen_pos;

uniform float sheet_skip_x_frst, sheet_skip_y_frst;
uniform float sheet_skip_x_last, sheet_skip_y_last;

uniform ivec2 sheet_size;

buffer sheet_block {
	uint data[];
} sheet;

/**
layout(binding = 1) buffer temp_otp {
	dvec2 data[3];
} temp;
/**/



// All 3 components are in the [0…1) range
vec3 hsv2rgb(float hue, float saturation, float value)
{
	vec3 c = {hue, saturation, value};
    vec4 K = vec4(1.0, 2.0 / 3.0, 1.0 / 3.0, 3.0);
    vec3 p = abs(fract(c.xxx + K.xyz) * 6.0 - K.www);
    return c.z * mix(K.xxx, clamp(p - K.xxx, 0.0, 1.0), c.y);
}



struct point_state {
	bool done;
	uint steps;
};
point_state PointAt(ivec2 ind) {
	uint res = sheet.data[ind.x + ind.y*sheet_size.x];
	const uint SIGN_BIT_MASK = 1u << 31;
	const uint SIGN_BIT_ANTI_MASK = ~SIGN_BIT_MASK;
	return point_state(
		(res & SIGN_BIT_MASK) != 0,
		(res & SIGN_BIT_ANTI_MASK)
	);
}



out vec3 color_out;

const int n_pts_avg = 5;
const int avg_pts_count = n_pts_avg*n_pts_avg;

void main() {
	// screen_pos is -1..+1
	vec2 sheet_pos_f = (screen_pos+1f)/2f;
	
	sheet_pos_f *= vec2(1f-sheet_skip_x_frst-sheet_skip_x_last, 1f-sheet_skip_y_frst-sheet_skip_y_last);
	sheet_pos_f += vec2(sheet_skip_x_frst, sheet_skip_y_frst);
	
	sheet_pos_f *= sheet_size-n_pts_avg;
	ivec2 sheet_pos_i = ivec2(round(sheet_pos_f));
	
	//TODO More priority to points at the center?
	//TODO That can help, but still doesn't fix cases where colors change too quickly and turn into a mess
	// - First actually try how avg colors look, maybe it's not that bad...
	// - Well, now I avg all 3 options. Now it's an extreamly expensive anti-aliasing
	// - Much better to just draw +4 points in each coordinate and only then avg
	// - Find how it's usually done in OpenGL
	// - Or maybe make a pixel for every sheet point use that as a texture??? A waste otherwise
	
	//float done = 0;
	//float steps = 0;
	vec3 color = vec3(0);
	for (int dx = 0; dx<n_pts_avg; ++dx)
		for (int dy = 0; dy<n_pts_avg; ++dy) {
			point_state p = PointAt(sheet_pos_i + ivec2(dx,dy));
			//done += int(p.done);
			//steps += p.steps;
			
			if (!p.done) {
				color += vec3(1);
				continue;
			}
			if (p.steps==0)
				continue;
			
			color += hsv2rgb(fract(p.steps * 0.013f), 0.75, 0.5);
		}
	
	/**
	done /= avg_pts_count;
	if (done < 0.3) {
		color_out = vec3(1);
		return;
	}
	
	if (steps == 0) {
		color_out = vec3(0);
		return;
	}
	steps /= avg_pts_count;
	/**/
	
	//color_out = hsv2rgb(fract(steps * 0.013f));
	color_out = color / avg_pts_count;
	
}


