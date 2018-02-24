package angle3d.renderer;

import haxe.ds.Vector;
import angle3d.material.BlendMode;
import angle3d.material.FaceCullMode;
import angle3d.material.StencilOperation;
import angle3d.material.TestFunction;
import angle3d.shader.Shader;
import angle3d.texture.Texture;

/**
 * Represents the current state of the graphics library. This class is used
 * internally to reduce state changes.
 */
class RenderContext {
	/**
	 * If back-face culling is enabled.
	 */
	public var cullMode:FaceCullMode;

	/**
	 * If Depth testing is enabled.
	 */
	public var depthTestEnabled:Bool;

	public var depthWriteEnabled:Bool;

	public var depthFunc:TestFunction;

	public var colorWriteEnabled:Bool;

	public var clipRectEnabled:Bool;

	public var blendMode:BlendMode;

	/**
	 * Stencil Buffer state
	 */
	public var stencilTest:Bool;
	public var frontStencilStencilFailOperation:StencilOperation;
	public var frontStencilDepthFailOperation:StencilOperation;
	public var frontStencilDepthPassOperation:StencilOperation;
	public var backStencilStencilFailOperation:StencilOperation;
	public var backStencilDepthFailOperation:StencilOperation;
	public var backStencilDepthPassOperation:StencilOperation;
	public var frontStencilFunction:TestFunction;
	public var backStencilFunction:TestFunction;

	/**
	 * Current bound texture IDs for each texture unit.
	 *
	 * @see Renderer#setTexture(int, angle3d.texture.Texture)
	 */
	public var boundTextures:Array<Texture>;

	public var boundTextureStates:Array<TextureState>;

	public var maxBoundTextureUInt:Int =-1;

	public var boundShaderProgram:Int =-1;
	public var boundShader:Shader;

	public function new() {
		boundTextures = new Array<Texture>();
		boundTextureStates = new Array<TextureState>();
		for (i in 0...8) {
			boundTextures[i] = null;
			boundTextureStates[i] = new TextureState();
		}

		reset();
	}

	public function reset():Void {
		for (i in 0...8) {
			boundTextures[i] = null;
			boundTextureStates[i].reset();
		}

		cullMode = FaceCullMode.NONE;
		depthTestEnabled = true;
		depthWriteEnabled = true;
		depthFunc = TestFunction.LESS_EQUAL;
		colorWriteEnabled = false;
		clipRectEnabled = false;
		blendMode = BlendMode.Off;

		stencilTest = false;
		frontStencilStencilFailOperation = StencilOperation.KEEP;
		frontStencilDepthFailOperation = StencilOperation.KEEP;
		frontStencilDepthPassOperation = StencilOperation.KEEP;
		backStencilStencilFailOperation = StencilOperation.KEEP;
		backStencilDepthFailOperation = StencilOperation.KEEP;
		backStencilDepthPassOperation = StencilOperation.KEEP;
		frontStencilFunction = TestFunction.ALWAYS;
		backStencilFunction = TestFunction.ALWAYS;
	}
}

