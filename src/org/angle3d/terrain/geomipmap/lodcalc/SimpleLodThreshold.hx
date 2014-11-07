package org.angle3d.terrain.geomipmap.lodcalc ;

import org.angle3d.terrain.geomipmap.TerrainQuad;
import org.angle3d.terrain.Terrain;


/**
 * Just multiplies the terrain patch size by 2. So every two
 * patches away the camera is, the LOD changes.
 * 
 * Set it higher to have the LOD change less frequently.
 * 
 * @author bowens
 */
class SimpleLodThreshold implements LodThreshold
{
	
    private var size:Int; // size of a terrain patch
    private var lodMultiplier:Float = 2;

    public function new(terrain:Terrain)
	{
        if (Std.is(terrain,TerrainQuad))
            this.size = cast(terrain,TerrainQuad).getPatchSize();
    }

    public function init(patchSize:Int, lodMultiplier:Float):Void
	{
        this.size = patchSize;
    }

    public function getLodMultiplier():Float
	{
        return lodMultiplier;
    }

    public function setLodMultiplier(lodMultiplier:Float):Void
	{
        this.lodMultiplier = lodMultiplier;
    }

    public function getSize():Int
	{
        return size;
    }

    public function setSize(size:Int):Void
	{
        this.size = size;
    }
	

    public function getLodDistanceThreshold():Float 
	{
        return size*lodMultiplier;
    }

    public function clone():LodThreshold
	{
        var threshold:SimpleLodThreshold = new SimpleLodThreshold(null);
        threshold.size = size;
        threshold.lodMultiplier = lodMultiplier;
        
        return threshold;
    }

    public function toString():String
	{
        return "SimpleLodThreshold " + size + ", " + lodMultiplier;
    }
}
