#version 460 core

noperspective in vec2 logic_pos;

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

out vec3 color;

// All components are in the range [0…1], including hue.
vec3 hsv2rgb(float hue)
{
	vec3 c = {hue, 0.75, 0.5};
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

const int n_pts_avg = 5;

void main() {
	// logic_pos is -1..+1
	vec2 sheet_pos_f = (logic_pos+1f)/2f;
	
	sheet_pos_f *= vec2(1f-sheet_skip_x_frst-sheet_skip_x_last, 1f-sheet_skip_y_frst-sheet_skip_y_last);
	sheet_pos_f += vec2(sheet_skip_x_frst, sheet_skip_y_frst);
	
	sheet_pos_f *= sheet_size-n_pts_avg;
	ivec2 sheet_pos_i = ivec2(round(sheet_pos_f));
	
	float done = 0;
	float steps = 0;
	for (int dx = 0; dx<n_pts_avg; ++dx)
		for (int dy = 0; dy<n_pts_avg; ++dy) {
			point_state p = PointAt(sheet_pos_i + ivec2(dx,dy));
			done += int(p.done);
			steps += p.steps;
		}
	steps /= n_pts_avg*n_pts_avg;
	done /= n_pts_avg*n_pts_avg;
	
	if (done < 0.3) {
		color = vec3(1);
		return;
	}
	
	if (steps == 0) {
		color = vec3(0);
		return;
	}
	
	color = hsv2rgb(fract(steps * 0.013f));
	
}


