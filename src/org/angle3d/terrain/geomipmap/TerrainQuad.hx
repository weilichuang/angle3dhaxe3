package org.angle3d.terrain.geomipmap;
import flash.Vector;
import org.angle3d.material.Material;
import org.angle3d.terrain.ProgressMonitor;
import org.angle3d.math.Vector3f;

import org.angle3d.math.Vector2f;
import org.angle3d.scene.Node;

/**
 * <p>
 * TerrainQuad is a heightfield-based terrain system. Heightfield terrain is fast and can
 * render large areas, and allows for easy Level of Detail control. However it does not
 * permit caves easily.
 * TerrainQuad is a quad tree, meaning that the root quad has four children, and each of
 * those children have four children. All the way down until you reach the bottom, the actual
 * geometry, the TerrainPatches.
 * If you look at a TerrainQuad in wireframe mode with the TerrainLODControl attached, you will
 * see blocks that change their LOD level together; these are the TerrainPatches. The TerrainQuad
 * is just an organizational structure for the TerrainPatches so patches that are not in the
 * view frustum get culled quickly.
 * TerrainQuads size are a power of 2, plus 1. So 513x513, or 1025x1025 etc.
 * Each point in the terrain is one unit apart from its neighbour. So a 513x513 terrain
 * will be 513 units wide and 513 units long.
 * Patch size can be specified on the terrain. This sets how large each geometry (TerrainPatch)
 * is. It also must be a power of 2 plus 1 so the terrain can be subdivided equally.
 * </p>
 * <p>
 * The height of the terrain can be modified at runtime using setHeight()
 * </p>
 * <p>
 * A terrain quad is a node in the quad tree of the terrain system.
 * The root terrain quad will be the only one that receives the update() call every frame
 * and it will determine if there has been any LOD change.
 * </p><p>
 * The leaves of the terrain quad tree are Terrain Patches. These have the real geometry mesh.
 * </p><p>
 * Heightmap coordinates start from the bottom left of the world and work towards the
 * top right.
 * </p><pre>
 *  +x
 *  ^
 *  | ......N = length of heightmap
 *  | :     :
 *  | :     :
 *  | 0.....:
 *  +---------&gt; +z
 * (world coordinates)
 * </pre>
 * @author Brent Owens
 */
class TerrainQuad extends Node implements Terrain
{

	public function new(name:String) 
	{
		super(name);
		
	}
	
	/* INTERFACE org.angle3d.terrain.Terrain */
	
	public function getHeight(xz:Vector2f):Float 
	{
		return 0;
	}
	
	public function getNormal(xz:Vector2f):Vector3f 
	{
		return null;
	}
	
	public function getHeightmapHeight(xz:Vector2f):Float 
	{
		return 0;
	}
	
	public function setHeight(xzCoordinate:Vector2f, height:Float):Void 
	{
		
	}
	
	public function setHeights(xz:Vector<Vector2f>, height:Vector<Float>):Void 
	{
		
	}
	
	public function adjustHeight(xzCoordinate:Vector2f, delta:Float):Void 
	{
		
	}
	
	public function adjustHeights(xz:Vector<Vector2f>, height:Vector<Float>):Void 
	{
		
	}
	
	public function getHeightMap():Vector<Float> 
	{
		return null;
	}
	
	public function getMaxLod():Int 
	{
		return 0;
	}
	
	public function setLocked(locked:Bool):Void 
	{
		
	}
	
	public function generateEntropy(monitor:ProgressMonitor):Void 
	{
		
	}
	
	public function getMaterial():Material 
	{
		return null;
	}
	
	public function getMaterialAt(worldLocation:Vector3f):Material 
	{
		return null;
	}
	
	public function getTerrainSize():Int 
	{
		return 0;
	}
	
	public function getNumMajorSubdivisions():Int 
	{
		return 0;
	}
	
}