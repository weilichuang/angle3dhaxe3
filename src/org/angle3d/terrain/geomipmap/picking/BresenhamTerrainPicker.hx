package org.angle3d.terrain.geomipmap.picking;
import org.angle3d.collision.CollisionResults;
import org.angle3d.math.Ray;
import org.angle3d.math.Vector3f;
import org.angle3d.terrain.geomipmap.TerrainQuad;

/**
 * ...
 * @author weilichuang
 */
class BresenhamTerrainPicker implements TerrainPicker
{

	public function new(root:TerrainQuad) 
	{
		
	}
	
	/* INTERFACE org.angle3d.terrain.geomipmap.picking.TerrainPicker */
	
	public function getTerrainIntersection(worldPick:Ray, results:CollisionResults):Vector3f 
	{
		return null;
	}
	
}