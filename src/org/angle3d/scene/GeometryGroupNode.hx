package org.angle3d.scene;
import de.polygonal.ds.error.Assert;

/**
 * An abstract class for implementations that perform grouping of geometries
 * via instancing or batching.
 
 */
class GeometryGroupNode extends Node
{
	public static function getGeometryStartIndex(geom:Geometry):Int 
	{
		#if debug
		Assert.assert(geom.startIndex == -1);
		#end

        return geom.startIndex;
    }
    
    private static function setGeometryStartIndex(geom:Geometry, startIndex:Int):Void
	{
		#if debug
		Assert.assert(geom.startIndex < -1);
		#end

        geom.startIndex = startIndex;
    }

	public function new(name:String) 
	{
		super(name);
		
	}
	
	/**
     * Called by {Geometry geom} to specify that its world transform
     * has been changed.
     * 
     * @param geom The Geometry whose transform changed.
     */
    public function onTransformChange(geom:Geometry):Void
	{
		
	}
    
    /**
     * Called by {Geometry geom} to specify that its 
     * {Geometry#setMaterial(org.angle3d.material.Material) material}
     * has been changed.
     * 
     * @param geom The Geometry whose material changed.
     * 
     * @throws UnsupportedOperationException If this implementation does
     * not support dynamic material changes.
     */
    public function onMaterialChange(geom:Geometry):Void
	{
		
	}
    
    /**
     * Called by {Geometry geom} to specify that its 
     * {Geometry#setMesh(org.angle3d.scene.Mesh) mesh}
     * has been changed.
     * 
     * This is also called when the geometry's 
     * {Geometry#setLodLevel(int) lod level} changes.
     * 
     * @param geom The Geometry whose mesh changed.
     * 
     * @throws UnsupportedOperationException If this implementation does
     * not support dynamic mesh changes.
     */
    public function onMeshChange(geom:Geometry):Void
	{
		
	}
    
    /**
     * Called by {Geometry geom} to specify that it
     * has been unassociated from its `GeoemtryGroupNode`.
     * 
     * Unassociation occurs when the {Geometry} is 
     * {Spatial#removeFromParent() detached} from its parent
     * {Node}.
     * 
     * @param geom The Geometry which is being unassociated.
     */
    public function onGeoemtryUnassociated(geom:Geometry):Void
	{
		
	}
}