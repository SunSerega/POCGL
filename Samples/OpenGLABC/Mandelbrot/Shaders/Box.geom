#version 460 core

uniform float view_skip_x_frst, view_skip_y_frst;
uniform float view_skip_x_last, view_skip_y_last;

layout(points) in;
layout(triangle_strip, max_vertices = 4) out;
out vec2 screen_pos;

void SendVertex(float coord1, float dx, float coord2, float dy) {
	screen_pos = vec2(coord1, coord2);
	gl_Position = vec4(coord1+dx, coord2+dy, 0, 1);
	EmitVertex();
}

void main() {
	SendVertex(-1,+view_skip_x_frst, -1,+view_skip_y_frst);
	SendVertex(-1,+view_skip_x_frst, +1,-view_skip_y_last);
	SendVertex(+1,-view_skip_x_last, -1,+view_skip_y_frst);
	SendVertex(+1,-view_skip_x_last, +1,-view_skip_y_last);
	EndPrimitive();
}
