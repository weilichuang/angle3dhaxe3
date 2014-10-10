package org.angle3d.scene;
import org.angle3d.utils.Assert;

/**
 * An abstract class for implementations that perform grouping of geometries
 * via instancing or batching.
 * @author weilichuang
 */
class GeometryGroupNode extends Node
{
	public static function getGeometryStartIndex(geom:Geometry):Int 
	{
		Assert.assert(geom.startIndex == -1);

        return geom.startIndex;
    }
    
    private static function setGeometryStartIndex(geom:Geometry, startIndex:Int):Void
	{
		Assert.assert(geom.startIndex < -1);

        geom.startIndex = startIndex;
    }

	public function new(name:String) 
	{
		super(name);
		
	}
	
	/**
     * Called by {@link Geometry geom} to specify that its world transform
     * has been changed.
     * 
     * @param geom The Geometry whose transform changed.
     */
    public function onTransformChange(geom:Geometry):Void
	{
		
	}
    
    /**
     * Called by {@link Geometry geom} to specify that its 
     * {@link Geometry#setMaterial(com.jme3.material.Material) material}
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
     * Called by {@link Geometry geom} to specify that its 
     * {@link Geometry#setMesh(com.jme3.scene.Mesh) mesh}
     * has been changed.
     * 
     * This is also called when the geometry's 
     * {@link Geometry#setLodLevel(int) lod level} changes.
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
     * Called by {@link Geometry geom} to specify that it
     * has been unassociated from its <code>GeoemtryGroupNode</code>.
     * 
     * Unassociation occurs when the {@link Geometry} is 
     * {@link Spatial#removeFromParent() detached} from its parent
     * {@link Node}.
     * 
     * @param geom The Geometry which is being unassociated.
     */
    public function onGeoemtryUnassociated(geom:Geometry):Void
	{
		
	}
}