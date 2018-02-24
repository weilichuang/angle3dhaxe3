package angle3d.terrain.geomipmap ;


import angle3d.math.Vector3f;
import angle3d.renderer.Camera;
import angle3d.terrain.Terrain;
import angle3d.terrain.geomipmap.lodcalc.LodCalculator;
import angle3d.terrain.geomipmap.TerrainLodControl;

/**
 * Updates grid offsets and cell positions.
 * As well as updating LOD.
 */
class TerrainGridLodControl extends TerrainLodControl
{

	public function new(terrain:Terrain,camera:Camera) 
	{
		super(terrain, camera);
	}
	
	override private function updateLOD(locations:Array<Vector3f>, lodCalculator:LodCalculator):Void
	{
        var terrainGrid:TerrainGrid = cast getSpatial();
        
        // for now, only the first camera is handled.
        // to accept more, there are two ways:
        // 1: every camera has an associated grid, then the location is not enough to identify which camera location has changed
        // 2: grids are associated with locations, and no incremental update is done, we load new grids for new locations, and unload those that are not needed anymore
        var cam:Vector3f = locations.length == 0 ? new Vector3f(0,0,0) : locations[0];
        var camCell:Vector3f = terrainGrid.getCamCell(cam); // get the grid index value of where the camera is (ie. 2,1)
        if (terrainGrid.cellsLoaded > 1) // Check if cells are updated before updating gridoffset.
		{                  
            terrainGrid.gridOffset[0] = Math.round(camCell.x * (terrainGrid.size / 2));
            terrainGrid.gridOffset[1] = Math.round(camCell.z * (terrainGrid.size / 2));
            terrainGrid.cellsLoaded = 0;
        }
        if (camCell.x != terrainGrid.currentCamCell.x || camCell.z != terrainGrid.currentCamCell.z || !terrainGrid.runOnce)
		{
            // if the camera has moved into a new cell, load new terrain into the visible 4 center quads
            terrainGrid.updateChildren(camCell);
            for ( l in terrainGrid.listeners)
			{
                l.gridMoved(camCell);
            }
        }
        terrainGrid.runOnce = true;
        super.updateLOD(locations, lodCalculator);
    }
}