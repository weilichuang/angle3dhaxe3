package org.angle3d.texture;

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

	public function new() {
	}
	
	public function getMinFilter():MinFilter{
		return minificationFilter;
	}
	
	public function setMinFilter(minificationFilter:MinFilter):Void{
		this.
	}
}

