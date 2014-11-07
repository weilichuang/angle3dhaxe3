package org.angle3d.terrain.geomipmap.grid ;

import org.angle3d.math.Vector3f;
import org.angle3d.terrain.geomipmap.TerrainGridTileLoader;
import org.angle3d.terrain.geomipmap.TerrainQuad;
import org.angle3d.terrain.heightmap.*;
import org.angle3d.utils.Logger;

class ImageTileNamer implements Namer
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
 *
 * @author Anthyon, normenhansen
 */
class ImageTileLoader implements TerrainGridTileLoader
{
    private var namer:Namer;
    private var patchSize:Int;
    private var quadSize:Int;
    private var heightScale:Float = 1;
	
	public function new()
	{
		
	}
	
	public function initNamer(namer:Namer):Void
	{
		this.namer = namer;
	}
	
	public function initPath(textureBase:String, textureExt:String):Void
	{
		this.namer = new ImageTileNamer(textureBase, textureExt);
	}

    /**
     * Effects vertical scale of the height of the terrain when loaded.
     */
    public function setHeightScale(heightScale:Float):Void
	{
        this.heightScale = heightScale;
    }
    
    
    /**
     * Lets you specify the type of images that are being loaded. All images
     * must be the same type.
     * @param imageType eg. BufferedImage.TYPE_USHORT_GRAY
     */
    /*public void setImageType(int imageType) {
        this.imageType = imageType;
    }*/

    /**
     * The ImageHeightmap that will parse the image type that you 
     * specify with setImageType().
     * @param customImageHeightmap must extend AbstractHeightmap
     */
    /*public void setCustomImageHeightmap(ImageHeightmap customImageHeightmap) {
        if (!(customImageHeightmap instanceof AbstractHeightMap)) {
            throw new IllegalArgumentException("customImageHeightmap must be an AbstractHeightMap!");
        }
        this.customImageHeightmap = customImageHeightmap;
    }*/

    private function getHeightMapAt(location:Vector3f):HeightMap
	{
        // HEIGHTMAP image (for the terrain heightmap)
        var x:Int = Std.int(location.x);
        var z:Int = Std.int(location.z);
        
        var heightmap:AbstractHeightMap = null;
        //BufferedImage im = null;
        
        var name:String = null;

		name = namer.getName(x, z);
		
		Logger.log('Loading heightmap from file: ${name}');
		
		//var  texture:Texture = assetManager.loadTexture(new TextureKey(name));
		//heightmap = new ImageBasedHeightMap(texture.getImage());
		
		/*if (assetInfo != null){
			InputStream in = assetInfo.openStream();
			im = ImageIO.read(in);
		} else {
			im = new BufferedImage(patchSize, patchSize, imageType);
			logger.log(Level.WARNING, "File: {0} not found, loading zero heightmap instead", name);
		}*/
		// CREATE HEIGHTMAP
		/*if (imageType == BufferedImage.TYPE_USHORT_GRAY) {
			heightmap = new Grayscale16BitHeightMap(im);
		} else if (imageType == BufferedImage.TYPE_3BYTE_BGR) {
			heightmap = new ImageBasedHeightMap(im);
		} else if (customImageHeightmap != null && customImageHeightmap instanceof AbstractHeightMap) {
			// If it gets here, it means you have specified a different image type, and you must
			// then also supply a custom image heightmap class that can parse that image into
			// a heightmap.
			customImageHeightmap.setImage(im);
			heightmap = (AbstractHeightMap) customImageHeightmap;
		} else {
			// error, no supported image format and no custom image heightmap specified
			if (customImageHeightmap == null)
				logger.log(Level.SEVERE, "Custom image type specified [{0}] but no customImageHeightmap declared! Use setCustomImageHeightmap()",imageType);
			if (!(customImageHeightmap instanceof AbstractHeightMap))
				logger.severe("customImageHeightmap must be an AbstractHeightMap!");
			return null;
		}*/
		heightmap.setHeightScale(1);
		heightmap.load();

        return heightmap;
    }

    public function setSize(size:Int):Void
	{
        this.patchSize = size - 1;
    }

    public function getTerrainQuadAt( location:Vector3f):TerrainQuad
	{
        var heightMapAt:HeightMap = getHeightMapAt(location);
        var q:TerrainQuad = new TerrainQuad("Quad" + location);
		q.init2(patchSize, quadSize, new Vector3f(1, 1, 1), heightMapAt == null ? null : heightMapAt.getHeightMap());
        return q;
    }

    public function setPatchSize(patchSize:Int):Void
	{
        this.patchSize = patchSize;
    }

    public function setQuadSize(quadSize:Int):Void
	{
        this.quadSize = quadSize;
    }
}
