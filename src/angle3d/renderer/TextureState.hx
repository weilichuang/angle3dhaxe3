package angle3d.renderer;
import angle3d.texture.MipFilter;
import angle3d.texture.TextureFilter;
import angle3d.texture.WrapMode;

/**
 *
 */
class TextureState {
	public var mipFilter:MipFilter;
	public var textureFilter:TextureFilter;
	public var wrapMode:WrapMode;

	public inline function new() {
		mipFilter = MipFilter.MIPNONE;
		textureFilter = TextureFilter.NEAREST;
		wrapMode = WrapMode.CLAMP;
	}

	public function reset():Void {
		mipFilter = MipFilter.MIPNONE;
		textureFilter = TextureFilter.NEAREST;
		wrapMode = WrapMode.CLAMP;
	}
}