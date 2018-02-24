package angle3d.texture;

import angle3d.texture.image.ColorSpace;
import angle3d.texture.image.LastTextureState;
import angle3d.utils.NativeObject;

using angle3d.math.FastMath;

/**
 * `Image` defines a data format for a graphical image. The image
 * is defined by a format, a height and width, and the image data. The width and
 * height must be greater than 0. The data is contained in a byte buffer, and
 * should be packed before creation of the image object.
 */
class Image extends NativeObject {
	private var format:ImageFormat;
	private var width:Int;
	private var height:Int;
	private var depth:Int;

	private var mipMapSizes:Array<Int>;
	private var colorSpace:ColorSpace = null;
	private var multiSamples:Int = 1;

	//attributes relating to GL object
	private var mipsWereGenerated:Bool = false;
	private var needGeneratedMips:Bool = false;
	private var lastTextureState:LastTextureState = new LastTextureState();

	public function new() {

	}

	/**
	 * Internal use only.
	 * The renderer stores the texture state set from the last texture
	 * so it doesn't have to change it unless necessary.
	 *
	 * @return The image parameter state.
	 */
	public function getLastTextureState():LastTextureState {
		return lastTextureState;
	}

	/**
	 * Internal use only.
	 * The renderer marks which images have generated mipmaps in VRAM
	 * and which do not, so it can generate them as needed.
	 *
	 * @param generated If mipmaps were generated or not.
	 */
	public function setMipmapsGenerated(generated:Bool):Void {
		this.mipsWereGenerated = generated;
	}

	/**
	 * Internal use only.
	 * Check if the renderer has generated mipmaps for this image in VRAM
	 * or not.
	 *
	 * @return If mipmaps were generated already.
	 */
	public function isMipmapsGenerated():Bool {
		return mipsWereGenerated;
	}

	/**
	 * (Package private) Called by {@link Texture} when
	 * {@link #isMipmapsGenerated() } is false in order to generate
	 * mipmaps for this image.
	 */
	private function setNeedGeneratedMipmaps():Void {
		needGeneratedMips = true;
	}

	/**
	 * @return True if the image needs to have mipmaps generated
	 * for it (as requested by the texture). This stays true even
	 * after mipmaps have been generated.
	 */
	public function isGeneratedMipmapsRequired():Bool {
		return needGeneratedMips;
	}

	/**
	 * Sets the update needed flag, while also checking if mipmaps
	 * need to be regenerated.
	 */
	override public function setUpdateNeeded() {
		super.setUpdateNeeded();
		if (isGeneratedMipmapsRequired() && !hasMipmaps()) {
			// Mipmaps are no longer valid, since the image was changed.
			setMipmapsGenerated(false);
		}
	}

	/**
	 * Determine if the image is NPOT.
	 *
	 * @return if the image is a non-power-of-2 image, e.g. having dimensions
	 * that are not powers of 2.
	 */
	public function isNPOT() {
		return !width.isPowerOfTwo() || !height.isPowerOfTwo();
	}

}