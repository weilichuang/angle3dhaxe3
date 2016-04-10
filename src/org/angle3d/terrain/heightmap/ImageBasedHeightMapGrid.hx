package org.angle3d.terrain.heightmap ;

import flash.display.BitmapData;
import org.angle3d.math.Vector3f;
import org.angle3d.utils.Logger;

class ImageBasedHeightMapNamer implements Namer
{
	public var textureBase:String;
	public var textureExt:String;
	
	public function new(textureBase:String, textureExt:String)
	{
		this.textureBase = textureBase;
		this.textureExt = textureExt;
	}
	
	public function getName(x:Int, y:Int):String
	{
		return textureBase + "_" + x + "_" + y + "." + textureExt;
	}
}

/**
 * Loads Terrain grid tiles with image heightmaps.
 * By default it expects a 16-bit grayscale image as the heightmap, but
 * you can also call setImageType(BufferedImage.TYPE_) to set it to be a different
 * image type. If you do this, you must also set a custom ImageHeightmap that will
 * understand and be able to parse the image. By default if you pass in an image of type
 * BufferedImage.TYPE_3BYTE_BGR, it will use the ImageBasedHeightMap for you.
 * 
, Brent Owens
 */
@Deprecated
/**
 * @Deprecated in favor of ImageTileLoader
 */
class ImageBasedHeightMapGrid implements HeightMapGrid
{
	private var namer:Namer;
    private var size:Int;

	public function new()
	{
		
	}
	
	public function initNamer(namer:Namer):Void
	{
		this.namer = namer;
	}
	
	public function initPath(textureBase:String, textureExt:String):Void
	{
		this.namer = new ImageBasedHeightMapNamer(textureBase, textureExt);
	}

    public function getHeightMapAt(location:Vector3f):HeightMap
	{
        // HEIGHTMAP image (for the terrain heightmap)
        var x:Int = Std.int(location.x);
        var z:Int = Std.int(location.z);
        
        var heightmap:AbstractHeightMap = null;
        //BufferedImage im = null;
        
		var name:String = namer.getName(x, z);
		Logger.log('Loading heightmap from file: ${name}');
		
		//final Texture texture = assetManager.loadTexture(new TextureKey(name));
		
		// CREATE HEIGHTMAP
		heightmap = new ImageBasedHeightMap(new BitmapData(400, 400));// texture.getImage());
		
		heightmap.setHeightScale(1);
		heightmap.load();

        return heightmap;
    }

    public function setSize(size:Int):Void
	{
        this.size = size - 1;
    }
}
