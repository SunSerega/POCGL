#version 460 core

noperspective in vec2 logic_pos;
in ivec2 gl_FragCoord;

layout(location = 0) uniform int point_count;
layout(binding = 0) buffer points_in {
	dvec2 data[];
} points;
const float point_r = 5;

layout(location = 1) uniform double camera_aspect_ratio;
layout(location = 2) uniform double camera_scale;
layout(location = 3) uniform dvec2 camera_pos;
layout(location = 4) uniform ivec2 mouse_pos;

layout(binding = 1) buffer point_data_buffer {
	double data[1];
} point_data;

out vec3 color;

void main() {
	dvec2 pos = { logic_pos.x*camera_aspect_ratio, logic_pos.y };
	pos *= camera_scale;
	pos += camera_pos;
	
	for (int i=0; i<point_count; ++i) {
		dvec2 dp = pos-points.data[i];
		if (dot(dp,dp)<point_r*point_r) {
			color = vec3(1,0,0);
			return;
		}
	}
	
	double x = pos.x;
	double y = pos.y;
	double r2 = x*x+y*y;
	double v = abs(x)*abs(y) + r2*r2/1000000 - 40000;
	
	if (gl_FragCoord == mouse_pos) {
		point_data.data[0] = v;
	}
	
	color = vec3( v<0 ? 255 : 0 );
}


