package org.angle3d.texture;

import org.angle3d.math.FastMath;

/**
 *
 */
class Texture2D extends Texture {
	
	private var wrapS:WrapMode = WrapMode.EdgeClamp;
    private var wrapT:WrapMode = WrapMode.EdgeClamp;
	
	public function new(img:Image) {
		super();
		setImage(img);
		if (img.getData(0) == null) {
            setMagFilter(MagFilter.Nearest);
            setMinFilter(MinFilter.NearestNoMipMaps);
        }
	}

	override private function createTexture(context:Context3D):TextureBase {
		var isWidthPOT:Bool = FastMath.isPowerOfTwo(mWidth);
		var isHeightPOT:Bool = FastMath.isPowerOfTwo(mHeight);
		if (!isWidthPOT || !isHeightPOT) {
			if (Reflect.hasField(context,"createRectangleTexture"))
				return untyped context["createRectangleTexture"](mWidth, mHeight, getFormat(), optimizeForRenderToTexture);
			else
				throw "this flash version dont support RectangleTexture";
		} else
		{
			return context.createTexture(mWidth, mHeight, getFormat(), optimizeForRenderToTexture);
		}
	}

}