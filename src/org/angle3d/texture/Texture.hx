package org.angle3d.texture;
import org.angle3d.asset.AssetKey;
import org.angle3d.asset.TextureKey;
import org.angle3d.error.Assert;

/**
 * `Texture` defines a texture object to be used to display an
 * image on a piece of geometry. The image to be displayed is defined by the
 * `Image` class. All attributes required for texture mapping are
 * contained within this class. This includes mipmapping if desired,
 * magnificationFilter options, apply options and correction options. Default
 * values are as follows: minificationFilter - NearestNeighborNoMipMaps,
 * magnificationFilter - NearestNeighbor, wrap - EdgeClamp on S,T and R, apply -
 * Modulate, environment - None.
 *
 */
class Texture {
	/**
	 * The name of the texture (if loaded as a resource).
	 */
	private var name:String;

	/**
	 * The image stored in the texture
	 */
	private var image:Image;

	private var minificationFilter:MinFilter = MinFilter.BilinearNoMipMaps;
	private var magnificationFilter:MagFilter = MagFilter.Bilinear;
	private var shadowCompareMode:ShadowCompareMode = ShadowCompareMode.Off;
	private var anisotropicFilter:Int;

	private var key:TextureKey;

	public function new() {
	}

	public function getMinFilter():MinFilter {
		return minificationFilter;
	}

	public function setMinFilter(minificationFilter:MinFilter):Void {
		this.minificationFilter = minificationFilter;

	}

	public function getMagFilter():MagFilter {
		return magnificationFilter;
	}

	public function setMagFilter(magnificationFilter:MagFilter):Void {
		Assert.assert(magnificationFilter != null, "magnificationFilter can not be null.");
		this.magnificationFilter = magnificationFilter;
	}

	public function getShadowCompareMode():ShadowCompareMode {
		return shadowCompareMode;
	}

	public function setShadowCompareMode(compareMode:ShadowCompareMode):Void {
		Assert.assert(shadowCompareMode != null, "magnificationFilter can not be null.");
		this.shadowCompareMode = shadowCompareMode;
	}

	/**
	 * `setImage` sets the image object that defines the texture.
	 * @param	image
	 */
	public function setImage(image:Image):Void {
		this.image = image;
		// Test if mipmap generation required.
		setMinFilter(getMinFilter());
	}

	public function getImage():Image {
		return image;
	}

	public function setKey(key:AssetKey):Void {
		this.key = cast key;
	}

	public function getKey():AssetKey {
		return this.key;
	}

	public function setWrapAxis(axis:WrapAxis, mode:WrapMode):Void {

	}

	public function setWrap(mode:WrapMode):Void {

	}

	public function getWrap(axis:WrapAxis):WrapMode {
		return null;
	}

	public function getType():TextureType {
		return null;
	}

	public function getAnisotropicFilter():Int {
		return anisotropicFilter;
	}
	
	public function setAnisotropicFilter(level:Int):Void{
		anisotropicFilter = Math.max(0, level);
	}
}

