package angle3d.texture;

import angle3d.math.FastMath;

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

	public function setImageData(width:Int, height:Int, format:ImageFormat):Void{
		var image = new Image();
		
		this.setImage(image);
	}

}