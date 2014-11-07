package org.angle3d.terrain.geomipmap.grid ;

import org.angle3d.math.Vector3f;
import org.angle3d.terrain.geomipmap.TerrainGridTileLoader;
import org.angle3d.terrain.geomipmap.TerrainQuad;
import org.angle3d.utils.Logger;

/**
 *
 * @author normenhansen
 */
class AssetTileLoader implements TerrainGridTileLoader
{
    private var assetPath:String;
    private var name:String;
    private var size:Int;
    private var patchSize:Int;
    private var quadSize:Int;
	private var loaded:Bool = false;

    public function new(name:String, assetPath:String)
	{
        this.name = name;
        this.assetPath = assetPath;
    }

    public function getTerrainQuadAt(location:Vector3f):TerrainQuad
	{
        var modelName:String = assetPath + "/" + name + "_" + Math.round(location.x) + "_" + Math.round(location.y) + "_" + Math.round(location.z) + ".j3o";
		
        Logger.log('Load terrain grid tile: ${modelName}');
		
        var quad:TerrainQuad = null;
		
		//quad = cast manager.loadModel(modelName);
        
        if (quad == null)
		{
            Logger.warn('Could not load terrain grid tile: ${modelName}');
            quad = createNewQuad(location);
        }
		else 
		{
            Logger.log('Loaded terrain grid tile: ${modelName}');
        }
        return quad;
    }

    public function getAssetPath():String
	{
        return assetPath;
    }

    public function getName():String
	{
        return name;
    }

    public function setPatchSize(patchSize:Int):Void
	{
        this.patchSize = patchSize;
    }

    public function setQuadSize(quadSize:Int):Void
	{
        this.quadSize = quadSize;
    }

    private function createNewQuad(location:Vector3f):TerrainQuad
	{
        var q:TerrainQuad = new TerrainQuad("Quad" + location);
		q.init2(patchSize, quadSize, new Vector3f(1, 1, 1), null);
        return q;
    }
}