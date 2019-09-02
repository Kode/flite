package openfl._internal.renderer.opengl.batcher;

import haxe.ds.Vector;
import openfl._internal.renderer.opengl.MaskManager;
import openfl._internal.renderer.opengl.batcher.Quad;

class BatchRenderer {
	final maskManager:MaskManager;
	final maxQuads:Int;
	final indexBuffer:kha.graphics4.IndexBuffer;
	final vertexBuffer:kha.graphics4.VertexBuffer;
	final groups:Vector<RenderGroup>;
	final boundTextures:Vector<TextureData>;
	final emptyTexture:kha.Image;
	var vertexBufferData:kha.arrays.Float32Array;
	var currentBlendMode = BlendMode.NORMAL;
	var currentTexture:TextureData;
	var currentQuadIndex = 0;
	var currentGroup:RenderGroup;
	var currentGroupCount = 0;
	var tick = 0;
	var textureTick = 0;
	var positionScaleY:Float;

	public var projectionMatrix:kha.math.FastMatrix4;
	public var g4:kha.graphics4.Graphics;

	// x, y, u, v, texId, alpha, colorMult, colorOfs
	static inline final floatsPerVertex = 2 + 2 + 1 + 4 + 4 + 1;
	static inline final floatsPerQuad = floatsPerVertex * 4;

	public function new(maskManager:MaskManager, maxQuads:Int) {
		this.maskManager = maskManager;
		this.maxQuads = maxQuads;

		BlendMode.init();

		positionScaleY = 1.0;

		// a dummy texture to bind to unused texture units so webgl doesn't spam warnings
		emptyTexture = kha.Image.create(1, 1);
		emptyTexture.lock();
		emptyTexture.unlock();

		// a singleton vector we use to track texture binding when rendering
		boundTextures = new Vector(PipelineSetup.numTextures);

		// create the vertex buffer for further uploading
		vertexBuffer = new kha.graphics4.VertexBuffer(maxQuads * 4, PipelineSetup.vertexStructure, DynamicUsage);
		vertexBufferData = vertexBuffer.lock();

		// preallocate a static index buffer for rendering any number of quads
		indexBuffer = createIndicesForQuads(maxQuads);

		// preallocate render group objects for any number of quads (worst case - 1 group per quad)
		groups = new Vector(maxQuads);
		for (i in 0...maxQuads) {
			groups[i] = new RenderGroup();
		}

		startNextGroup();
	}

	inline function finishCurrentGroup() {
		currentGroup.size = currentQuadIndex - currentGroup.start;
	}

	inline function startNextGroup() {
		currentGroup = groups[currentGroupCount];
		currentGroup.textureCount = 0;
		currentGroup.start = currentQuadIndex;
		currentGroup.blendMode = currentBlendMode;
		// we always increase the tick when staring a new render group, so all textures become "disabled" and need to be processed
		tick++;
		currentGroupCount++;
	}

	public inline function flipVertical() {
		positionScaleY = -1;
	}

	public function unflipVertical() {
		positionScaleY = 1;
	}

	/** schedule quad for rendering **/
	public function render(quad:Quad) {
		if (currentQuadIndex >= maxQuads) {
			flush();
		}

		var maxTextures = PipelineSetup.numTextures;
		var nextTexture = quad.texture.data;

		if (currentBlendMode != quad.blendMode) {
			currentBlendMode = quad.blendMode;
			currentTexture = null;

			finishCurrentGroup();
			startNextGroup();
		}

		// if the texture was used in the current group (ticks are equal), but the smoothing mode has changed
		// we gotta break the batch, because we can't render the same texture with different smoothing in a single batch
		// TODO: we can in WebGL2 using Sampler objects
		if (nextTexture.enabledTick == tick && nextTexture.lastSmoothing != quad.smoothing) {
			currentTexture = null;

			finishCurrentGroup();
			startNextGroup();
		}

		// if the texture has changed - we need to either pack it into the current render group or create the next one
		// and since on the first iteration the `currentTexture` is null, it's always "changed"
		if (currentTexture != nextTexture) {
			currentTexture = nextTexture;

			// if the texture's tick and current tick are equal, that means
			// that the texture was already enabled in the current group
			// and we don't need to do anything, otherwise...
			if (currentTexture.enabledTick != tick) {
				// if the current group is already full of textures, finish it and start a new one
				if (currentGroup.textureCount == maxTextures) {
					finishCurrentGroup();
					startNextGroup();
				}

				// if the texture hasn't yet been bound to a texture unit this render, we need to choose one
				if (nextTexture.textureUnitId == -1) {
					// iterate over possible texture "slots"
					for (i in 0...maxTextures) {
						// we use "texture tick" for calculating texture unit,
						// so we always start checking with the next texture unit,
						// relative to previous binding
						var textureUnit = (i + textureTick) % maxTextures;

						// if there's no bound texture in this slot, or that texture
						// wasn't used in this group (ticks are different), we can use this slot!
						var boundTexture = boundTextures[textureUnit];
						if (boundTexture == null || boundTexture.enabledTick != tick) {
							// if there was a texture in this slot - unbind it, since we're replacing it
							if (boundTexture != null) {
								boundTexture.textureUnitId = -1;
							}

							// assign this texture to the texture unit
							nextTexture.textureUnitId = textureUnit;
							boundTextures[textureUnit] = nextTexture;

							// increase the tick so next time we'll start looking directly from the next texture unit
							textureTick++;

							// and we're done here
							break;
						}
					}
					if (nextTexture.textureUnitId == -1) {
						throw "Unable to find free texture unit for the batch render group! This should NOT happen!";
					}
				}

				// mark the texture as enabled in this group
				nextTexture.enabledTick = tick;
				nextTexture.lastSmoothing = quad.smoothing;
				// add the texture to the group textures array
				currentGroup.textures[currentGroup.textureCount] = nextTexture;
				// save the texture unit number separately as it can change when processing next group
				currentGroup.textureUnits[currentGroup.textureCount] = nextTexture.textureUnitId;
				currentGroup.textureSmoothing[currentGroup.textureCount] = quad.smoothing;
				currentGroup.textureCount++;
			}
		}

		// fill the vertex buffer with vertex and texture coordinates, as well as the texture id
		var vertexData = quad.vertexData;
		var uvs = quad.texture.uvs;
		var textureUnitId = nextTexture.textureUnitId;
		var alpha = quad.alpha;
		var pma = quad.texture.premultipliedAlpha;
		var colorTransform = quad.colorTransform;
		var currentVertexBufferIndex = currentQuadIndex * floatsPerQuad;

		// trace('Group $currentGroupCount uses texture $textureUnitId');

		inline function setVertex(i) {
			var offset = currentVertexBufferIndex + i * floatsPerVertex;
			vertexBufferData[offset + 0] = vertexData[i * 2 + 0];
			vertexBufferData[offset + 1] = vertexData[i * 2 + 1];

			vertexBufferData[offset + 2] = uvs[i * 2 + 0];
			vertexBufferData[offset + 3] = uvs[i * 2 + 1];

			vertexBufferData[offset + 4] = textureUnitId;

			if (colorTransform != null) {
				vertexBufferData[offset + 5] = colorTransform.redOffset / 255;
				vertexBufferData[offset + 6] = colorTransform.greenOffset / 255;
				vertexBufferData[offset + 7] = colorTransform.blueOffset / 255;
				vertexBufferData[offset + 8] = (colorTransform.alphaOffset / 255) * alpha;

				vertexBufferData[offset + 9] = colorTransform.redMultiplier;
				vertexBufferData[offset + 10] = colorTransform.greenMultiplier;
				vertexBufferData[offset + 11] = colorTransform.blueMultiplier;
				vertexBufferData[offset + 12] = colorTransform.alphaMultiplier * alpha;
			} else {
				vertexBufferData[offset + 5] = 0;
				vertexBufferData[offset + 6] = 0;
				vertexBufferData[offset + 7] = 0;
				vertexBufferData[offset + 8] = 0;

				vertexBufferData[offset + 9] = 1;
				vertexBufferData[offset + 10] = 1;
				vertexBufferData[offset + 11] = 1;
				vertexBufferData[offset + 12] = alpha;
			}

			vertexBufferData[offset + 13] = pma ? 1 : 0;
		}

		setVertex(0);
		setVertex(1);
		setVertex(2);
		setVertex(3);

		currentQuadIndex++;
	}

	/** render all the quads we collected **/
	public function flush() {
		if (currentQuadIndex == 0) {
			return;
		}

		// finish the current group
		finishCurrentGroup();

		// upload vertex data
		vertexBuffer.unlock();
		// // var subArray = vertexBufferData.subarray(0, currentQuadIndex * floatsPerQuad);
		// // gl.bufferSubData(GL.ARRAY_BUFFER, 0, subArray);

		// use local vars to save some field access
		var g4 = this.g4;
		var boundTextures = this.boundTextures;
		var groups = this.groups;
		var stencilReferenceValue = maskManager.stencilReference;
		var maxTextures = PipelineSetup.numTextures;

		var lastBlendMode = null;
		var textureUnits = null;

		// iterate over groups and render them
		for (i in 0...currentGroupCount) {
			var group = groups[i];
			if (group.size == 0) {
				// TODO: don't even create empty groups (can happen when staring drawing with a non-NORMAL blendmode)
				continue;
			}
			// trace('Rendering group ${i + 1} (${group.size})');

			if (lastBlendMode != group.blendMode) {
				lastBlendMode = group.blendMode;
				var p = lastBlendMode.setup(g4, stencilReferenceValue);
				g4.setFloat4(p.uPositionScale, 1, positionScaleY, 1, 1);
				g4.setMatrix(p.uProjMatrix, projectionMatrix);
				g4.setVertexBuffer(vertexBuffer);
				g4.setIndexBuffer(indexBuffer);
				for (unit in p.textureUnits) {
					g4.setTexture(unit, emptyTexture);
				}
				textureUnits = p.textureUnits;
			}

			// bind this group's textures
			for (i in 0...group.textureCount) {
				var currentTexture = group.textures[i];
				// trace('Activating texture at ${group.textureUnits[i]}: ${currentTexture.glTexture}');
				var textureUnit = textureUnits[group.textureUnits[i]];
				g4.setTexture(textureUnit, currentTexture.image);

				var filter:kha.graphics4.TextureFilter = if (group.textureSmoothing[i]) LinearFilter else PointFilter;
				g4.setTextureParameters(textureUnit, Clamp, Clamp, filter, filter, NoMipFilter);

				currentTexture.textureUnitId = -1; // clear the binding for subsequent flush calls
			}

			// draw this group's slice of vertices
			g4.drawIndexedVertices(group.start * 6, group.size * 6);
		}

		for (i in 0...maxTextures) {
			boundTextures[i] = null;
		}
		currentTexture = null;
		currentQuadIndex = 0;
		currentBlendMode = BlendMode.NORMAL;
		currentGroupCount = 0;
		vertexBufferData = vertexBuffer.lock();
		startNextGroup();
	}

	/** creates an pre-filled index buffer data for rendering triangles **/
	static function createIndicesForQuads(numQuads:Int):kha.graphics4.IndexBuffer {
		var totalIndices = numQuads * 3 * 2; // 2 triangles of 3 verties per quad
		var buffer = new kha.graphics4.IndexBuffer(totalIndices, StaticUsage);
		var indices = buffer.lock();
		var i = 0, j = 0;
		while (i < totalIndices) {
			indices[i + 0] = j + 0;
			indices[i + 1] = j + 1;
			indices[i + 2] = j + 2;
			indices[i + 3] = j + 0;
			indices[i + 4] = j + 2;
			indices[i + 5] = j + 3;
			i += 6;
			j += 4;
		}
		buffer.unlock();
		return buffer;
	}
}

@:structInit
private class PipelineData {
	public final pipeline:kha.graphics4.PipelineState;
	public final uProjMatrix:kha.graphics4.ConstantLocation;
	public final uPositionScale:kha.graphics4.ConstantLocation;
	public final textureUnits:Array<kha.graphics4.TextureUnit>;
}

private class RenderGroup {
	public var textures = new Array<TextureData>();
	public var textureUnits = new Array<Int>();
	public var textureSmoothing = new Array<Bool>();
	public var textureCount = 0;
	public var size = 0;
	public var start = 0;
	public var blendMode:BlendMode;

	public function new() {}
}
