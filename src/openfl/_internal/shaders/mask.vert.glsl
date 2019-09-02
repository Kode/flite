#version 450

in vec2 aPosition;
in vec2 aTexCoord;
out vec2 vTexCoord;

uniform mat4 uMatrix;

void main(void) {
	vTexCoord = aTexCoord;
	gl_Position = uMatrix * vec4(aPosition, 0, 1.0);
}
