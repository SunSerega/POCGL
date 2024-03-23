#version 460 core

noperspective in vec2 logic_pos;
in ivec2 gl_FragCoord;

layout(location = 0) uniform int point_count;
layout(binding = 0) buffer points_in {
	dvec2 data[];
} points;

layout(location = 1) uniform double camera_aspect_ratio;
layout(location = 2) uniform double camera_scale;
layout(location = 3) uniform dvec2 camera_pos;
layout(location = 4) uniform ivec2 mouse_pos;

layout(binding = 1) buffer point_data_buffer {
	double data[1];
} point_data;

out vec3 color;

// Радиус красной точки
const float point_r = 5;
// Скорость затемнения при отдалении от точки
const float fall_speed = 0.6;

void main() {
	
	// Считаем в фрагментном шейдере, потому что интерполяция
	// 64-битного logic_pos (с типом dvec2) в OpenGL запрещена
	dvec2 pos = { logic_pos.x*camera_aspect_ratio, logic_pos.y };
	pos *= camera_scale;
	pos += camera_pos;
	
	for (int i=0; i<point_count; ++i) {
		dvec2 dp = pos-points.data[i];
		if (dot(dp,dp)<point_r*point_r) {
			color = vec3(0.7, 0, 0);
			return;
		}
	}
	
	double res = 0;
	for (int i=0; i<point_count; ++i) {
		double curr = distance(pos, points.data[i]) / 10;
		curr = fract(curr);
		res += curr;
	}
	res /= point_count;
	//res = fract(res);
	
	if (gl_FragCoord == mouse_pos) {
		point_data.data[0] = res;
	}
	
	color = vec3( res );
}


