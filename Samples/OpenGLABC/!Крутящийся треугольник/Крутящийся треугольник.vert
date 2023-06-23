#version 460

in vec2 position;
in vec3 inp_color;
uniform float rot_k;

out vec3 vert_color;

void main()
{
	
	gl_Position.x = position.x*rot_k;
	gl_Position.y = position.y;
	gl_Position.z = 0.0f;
	gl_Position.w = 1.0f;
	
	vert_color.rgb = inp_color;
	
}
