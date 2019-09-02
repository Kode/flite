#version 450

in vec2 vTextureCoord;
in float vTextureId;
in vec4 vColorMultiplier;
in vec4 vColorOffset;
in float vPremultipliedAlpha;

uniform sampler2D uSamplers[32];

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
				else if (textureId == 7.0) color = texture(uSamplers[7], vTextureCoord);
				else if (textureId == 8.0) color = texture(uSamplers[8], vTextureCoord);
				else if (textureId == 9.0) color = texture(uSamplers[9], vTextureCoord);
				else if (textureId == 10.0) color = texture(uSamplers[10], vTextureCoord);
				else if (textureId == 11.0) color = texture(uSamplers[11], vTextureCoord);
				else if (textureId == 12.0) color = texture(uSamplers[12], vTextureCoord);
				else if (textureId == 13.0) color = texture(uSamplers[13], vTextureCoord);
				else if (textureId == 14.0) color = texture(uSamplers[14], vTextureCoord);
				else if (textureId == 15.0) color = texture(uSamplers[15], vTextureCoord);
				else if (textureId == 16.0) color = texture(uSamplers[16], vTextureCoord);
				else if (textureId == 17.0) color = texture(uSamplers[17], vTextureCoord);
				else if (textureId == 18.0) color = texture(uSamplers[18], vTextureCoord);
				else if (textureId == 19.0) color = texture(uSamplers[19], vTextureCoord);
				else if (textureId == 20.0) color = texture(uSamplers[20], vTextureCoord);
				else if (textureId == 21.0) color = texture(uSamplers[21], vTextureCoord);
				else if (textureId == 22.0) color = texture(uSamplers[22], vTextureCoord);
				else if (textureId == 23.0) color = texture(uSamplers[23], vTextureCoord);
				else if (textureId == 24.0) color = texture(uSamplers[24], vTextureCoord);
				else if (textureId == 25.0) color = texture(uSamplers[25], vTextureCoord);
				else if (textureId == 26.0) color = texture(uSamplers[26], vTextureCoord);
				else if (textureId == 27.0) color = texture(uSamplers[27], vTextureCoord);
				else if (textureId == 28.0) color = texture(uSamplers[28], vTextureCoord);
				else if (textureId == 29.0) color = texture(uSamplers[29], vTextureCoord);
				else if (textureId == 30.0) color = texture(uSamplers[30], vTextureCoord);
				else color = texture(uSamplers[31], vTextureCoord);;

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
