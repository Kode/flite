using StringTools;

class GenShaders {
	static function main() {
		var template = sys.io.File.getContent("src/openfl/_internal/shaders/batch.frag.glsl.template");
		var numTextures = 32;
		while (numTextures >= 1) {
			var fsSource = generateMultiTextureFragmentShaderSource(template, numTextures);
			sys.io.File.saveContent("src/openfl/_internal/shaders/batch_"+numTextures+".frag.glsl", fsSource);
			numTextures = numTextures >> 1;
		}
	}

	static function generateMultiTextureFragmentShaderSource(template:String, numTextures:Int):String {
		var select = [];
		for (i in 0...numTextures) {
			var cond = if (i > 0) "else " else "";
			if (i < numTextures - 1)
				cond += 'if (textureId == $i.0) ';
			select.push('\t\t\t\t${cond}color = texture(uSamplers[$i], vTextureCoord);');
		}
		return template.replace("$numTextures", Std.string(numTextures)).replace("$select", select.join("\n"));
	}

}