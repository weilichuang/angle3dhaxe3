package org.angle3d.terrain.geomipmap.picking ;
import org.angle3d.collision.CollisionResult;
import org.angle3d.terrain.geomipmap.TerrainPatch;

/**
 * Pick result on a terrain patch with the intersection on the bounding box
 * of that terrain patch.
 */
class TerrainPickData
{
	public var targetPatch:TerrainPatch;
    public var cr:CollisionResult;

	public function new(patch:TerrainPatch,cr:CollisionResult) 
	{
		this.targetPatch = patch;
		this.cr = cr;
	}
	
	public function compareTo(other:TerrainPickData):Int
	{
		if (this.cr.distance < other.cr.distance)
			return -1;
		else if (this.cr.distance == other.cr.distance)
			return 0;
		else
			return 1;
	}
	
	public function equals(other:TerrainPickData):Bool
	{
		return compareTo(other) == 0;
	}
}