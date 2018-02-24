package angle3d.texture.image;
import angle3d.texture.MagFilter;
import angle3d.texture.MinFilter;
import angle3d.texture.ShadowCompareMode;
import angle3d.texture.WrapMode;

/**
 * Stores / caches texture state parameters so they don't have to be set
 * each time by the `Renderer`.
 *
 */
class LastTextureState {

	public var sWrap:WrapMode;
	public var tWrap:WrapMode;
	public var rWrap:WrapMode;

	public var magFilter:MagFilter;
	public var minFilter:MinFilter;
	public var anisoFilter:Int;
	public var shadowCompareMode:ShadowCompareMode;

	public function new() {
		reset();
	}

	public function reset():Void {
		sWrap = null;
		tWrap = null;
		rWrap = null;
		magFilter = null;
		minFilter = null;
		anisoFilter = 1;

		// The default in OpenGL is OFF, so we avoid setting this per texture
		// if its not used.
		shadowCompareMode = ShadowCompareMode.Off;
	}

}