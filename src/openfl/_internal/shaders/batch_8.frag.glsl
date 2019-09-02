#version 450

in vec2 vTextureCoord;
in float vTextureId;
in vec4 vColorMultiplier;
in vec4 vColorOffset;
in float vPremultipliedAlpha;

uniform sampler2D uSamplers[8];

out vec4 FragColor;

void main(void) {
	float textureId = floor(vTextureId+0.5);
	vec4 color;

					if (textureId == 0.0) color = texture(uSamplers[0], vTextureCoord);
				else if (textureId == 1.0) color = texture(uSamplers[1], vTextureCoord);
				else if (textureId == 2.0) color = texture(uSamplers[2], vTextureCoord);
				else if (textureId == 3.0) color = texture(uSamplers[3], vTextureCoord);
				else if (textureId == 4.0) color = texture(uSamplers[4], vTextureCoord);
				else if (textureId == 5.0) color = texture(uSamplers[5], vTextureCoord);
				else if (textureId == 6.0) color = texture(uSamplers[6], vTextureCoord);
				else color = texture(uSamplers[7], vTextureCoord);;

	if (color.a == 0.0) {
		FragColor = vec4(0.0, 0.0, 0.0, 0.0);
	} else {
		/** mix is a linear interpolation function that interpolates between first and second
		*   parameter, controlled by the third one. The function looks like this:
		*
		*   mix (x, y, a) = x * (1.0 - a) + y * a
		*
		*  As vPremultipliedAlpha is 0.0 or 1.0 we basically switch on/off first or the second paramter
		*  respectively
		*/
		color = vec4(color.rgb / mix (1.0, color.a, vPremultipliedAlpha), color.a);
		color = vColorOffset + (color * vColorMultiplier);
		FragColor = vec4(color.rgb * mix (1.0, color.a, vPremultipliedAlpha), color.a);
	}
}
