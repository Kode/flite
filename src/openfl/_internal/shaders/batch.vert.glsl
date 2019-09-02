#version 450

in vec2 aVertexPosition;
in vec2 aTextureCoord;
in float aTextureId;
in vec4 aColorMultiplier;
in vec4 aColorOffset;
in float aPremultipliedAlpha;

uniform mat4 uProjMatrix;
uniform vec4 uPostionScale;

out vec2 vTextureCoord;
out float vTextureId;
out vec4 vColorMultiplier;
out vec4 vColorOffset;
out float vPremultipliedAlpha;

void main(void) {
	gl_Position = uProjMatrix * vec4(aVertexPosition, 0, 1) * uPostionScale;
	vTextureCoord = aTextureCoord;
	vTextureId = aTextureId;
	vColorMultiplier = aColorMultiplier;
	vColorOffset = aColorOffset;
	vPremultipliedAlpha = aPremultipliedAlpha;
}
