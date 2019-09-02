package openfl._internal.stage3D.atf;

enum abstract ATFGPUFormat(Int) {
	var DXT; // DXT1/DXT5 depending on alpha
	var PVRTC;
	var ETC1;
	var ETC2;
}
