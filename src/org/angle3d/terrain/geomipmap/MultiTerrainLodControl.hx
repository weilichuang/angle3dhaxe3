package org.angle3d.terrain.geomipmap ;
import haxe.ds.StringMap;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.terrain.geomipmap.lodcalc.DistanceLodCalculator;
import org.angle3d.terrain.geomipmap.lodcalc.LodCalculator;
import org.angle3d.terrain.geomipmap.TerrainLodControl.UpdateLOD;

/**
 * ...
 * @author weilichuang
 */
class MultiTerrainLodControl extends TerrainLodControl
{

	public var  terrains:Array<TerrainQuad> = new Array<TerrainQuad>();
    private var addedTerrains:Array<TerrainQuad> = new Array<TerrainQuad>();
    private var removedTerrains:Array<TerrainQuad> = new Array<TerrainQuad>();

    public function new(camera:Camera)
	{
		super(null, camera);
        lodCalculator = new DistanceLodCalculator(65, 2.7);
    }
    
    /**
     * Add a terrain that will have its LOD handled by this control.
     * It will be added next update run. You should only call this from
     * the render thread.
     */
    public function addTerrain(tq:TerrainQuad):Void
	{
        addedTerrains.push(tq);
    }
    
    /**
     * Add a terrain that will no longer have its LOD handled by this control.
     * It will be removed next update run. You should only call this from
     * the render thread.
     */
    public function removeTerrain(tq:TerrainQuad):Void 
	{
        removedTerrains.push(tq);
    }
	
	override function getLodThread(locations:Array<Vector3f>, lodCalculator:LodCalculator):UpdateLOD 
	{
		return new UpdateMultiLOD(this,locations, lodCalculator);
	}
    
    override private function prepareTerrain():Void 
	{
		if (addedTerrains.length != 0)
		{
            for (t in addedTerrains)
			{
                if (terrains.indexOf(t) == -1)
                    terrains.push(t);
            }
            addedTerrains = [];
        }
        
        if (removedTerrains.length != 0) 
		{
			for (i in 0...removedTerrains.length)
			{
				var index:Int = terrains.indexOf(removedTerrains[i]);
				if (index > -1)
				{
					terrains.splice(index, 1);
				}
			}
            removedTerrains = [];
        }
        
        for (terrain in terrains)
            terrain.cacheTerrainTransforms();// cache the terrain's world transforms so they can be accessed on the separate thread safely
	}
}

/**
 * Overrides the parent UpdateLOD runnable to process
 * multiple terrains.
 */
class UpdateMultiLOD extends UpdateLOD
{
	
	public function new(control:MultiTerrainLodControl, camLocations:Array<Vector3f>, lodCalculator:LodCalculator)
	{
		super(control,camLocations, lodCalculator);
	}
	
	override public function call():StringMap<UpdatedTerrainPatch>
	{
		control.setLodCalcRunning(true);

		var terrains:Array<TerrainQuad> =  cast(control, MultiTerrainLodControl).terrains;
		
		var updated:StringMap<UpdatedTerrainPatch> = new StringMap<UpdatedTerrainPatch>();
		
		for (terrainQuad in terrains) 
		{
			// go through each patch and calculate its LOD based on camera distance
			terrainQuad.calculateLod(camLocations, updated, lodCalculator); // 'updated' gets populated here
		}
		
		for (terrainQuad in terrains) 
		{
			// then calculate the neighbour LOD values for seaming
			terrainQuad.findNeighboursLod(updated);
		}
		
		for (terrainQuad in terrains) 
		{
			// check neighbour quads that need their edges seamed
			terrainQuad.fixEdges(updated);
		}
		
		for (terrainQuad in terrains) 
		{
			// perform the edge seaming, if it requires it
			terrainQuad.reIndexPages(updated, lodCalculator.usesVariableLod());
		}
		
		//setUpdateQuadLODs(updated); // set back to main ogl thread
		control.setLodCalcRunning(false);
		
		return updated;
	}
}