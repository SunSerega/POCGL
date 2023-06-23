#version 460

in vec3 vert_color;

out vec3 frag_color;

void main()
{
	frag_color = vert_color;
}
