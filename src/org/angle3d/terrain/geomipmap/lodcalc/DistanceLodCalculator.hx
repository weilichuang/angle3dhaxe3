package org.angle3d.terrain.geomipmap.lodcalc ;

import org.angle3d.utils.FastStringMap;
import org.angle3d.math.Vector3f;
import org.angle3d.terrain.geomipmap.TerrainPatch;
import org.angle3d.terrain.geomipmap.UpdatedTerrainPatch;

/**
 * Calculates the LOD of the terrain based on its distance from the
 * cameras. Taking the minimum distance from all cameras.
 *
 * @author bowens
 */
class DistanceLodCalculator implements LodCalculator
{

    private var size:Int; // size of a terrain patch
    private var lodMultiplier:Float = 2;
    private var _turnOffLod:Bool = false;
    
    public function new(patchSize:Int=20, multiplier:Float=2)
	{
        this.size = patchSize;
        this.lodMultiplier = multiplier;
    }
    
    public function calculateLod(terrainPatch:TerrainPatch, locations:Array<Vector3f>, updates:FastStringMap<UpdatedTerrainPatch>):Bool
	{
        if (locations == null || locations.length == 0)
            return false;// no camera yet
			
        var distance:Float = getCenterLocation(terrainPatch).distance(locations[0]);

        if (_turnOffLod)
		{
            // set to full detail
            var prevLOD:Int = terrainPatch.getLod();
            var utp:UpdatedTerrainPatch = updates.get(terrainPatch.name);
            if (utp == null) 
			{
                utp = new UpdatedTerrainPatch(terrainPatch);
                updates.set(utp.getName(), utp);
            }
            utp.setNewLod(0);
            utp.setPreviousLod(prevLOD);
            //utp.setReIndexNeeded(true);
            return true;
        }
        
        // go through each lod level to find the one we are in
        for (i in 0...(terrainPatch.getMaxLod() + 1))
		{
            if (distance < getLodDistanceThreshold() * (i + 1) * terrainPatch.getWorldScaleCached().x || i == terrainPatch.getMaxLod())
			{
                var reIndexNeeded:Bool = false;
                if (i != terrainPatch.getLod()) 
				{
                    reIndexNeeded = true;
                    //System.out.println("lod change: "+lod+" > "+i+"    dist: "+distance);
                }
                var prevLOD:Int = terrainPatch.getLod();
                
                var utp:UpdatedTerrainPatch = updates.get(terrainPatch.name);
                if (utp == null) 
				{
                    utp = new UpdatedTerrainPatch(terrainPatch);//save in here, do not update actual variables
                    updates.set(utp.getName(), utp);
                }
                utp.setNewLod(i);
                utp.setPreviousLod(prevLOD);
                //utp.setReIndexNeeded(reIndexNeeded);

                return reIndexNeeded;
            }
        }

        return false;
    }

    private function getCenterLocation(terrainPatch:TerrainPatch):Vector3f
	{
        var loc:Vector3f = terrainPatch.getWorldTranslationCached();
        loc.x += terrainPatch.getSize()*terrainPatch.getWorldScaleCached().x / 2;
        loc.z += terrainPatch.getSize()*terrainPatch.getWorldScaleCached().z / 2;
        return loc;
    }

    public function clone():LodCalculator
	{
        return new DistanceLodCalculator(size, lodMultiplier);
    }

    public function toString():String
	{
        return "DistanceLodCalculator " + size + "*" + lodMultiplier;
    }

    /**
     * Gets the camera distance where the LOD level will change
     */
    private function getLodDistanceThreshold():Float
	{
        return size*lodMultiplier;
    }
    
    /**
     * Does this calculator require the terrain to have the difference of 
     * LOD levels of neighbours to be more than 1.
     */
    public function usesVariableLod():Bool 
	{
        return false;
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

    public function turnOffLod():Void
	{
        _turnOffLod = true;
    }
    
    public function isLodOff():Bool 
	{
        return _turnOffLod;
    }
    
    public function turnOnLod():Void
	{
        _turnOffLod = false;
    }
    
}
