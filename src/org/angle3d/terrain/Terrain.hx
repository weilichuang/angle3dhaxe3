package org.angle3d.terrain;
import flash.Vector;
import org.angle3d.material.Material;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;

/**
 * Terrain can be one or many meshes comprising of a, probably large, piece of land.
 * Terrain is Y-up in the grid axis, meaning gravity acts in the -Y direction.
 * Level of Detail (LOD) is supported and expected as terrains can get very large. LOD can
 * also be disabled if you so desire, however some terrain implementations can choose to ignore
 * useLOD(boolean).
 * Terrain implementations should extend Node, or at least Spatial.
 *
 */
interface Terrain 
{
  /**
     * Get the real-world height of the terrain at the specified X-Z coorindate.
     * @param xz the X-Z world coordinate
     * @return the height at the given point
     */
    function getHeight(xz:Vector2f):Float;
    
    /**
     * Get the normal vector for the surface of the terrain at the specified
     * X-Z coordinate. This normal vector can be a close approximation. It does not
     * take into account any normal maps on the material.
     * @param xz the X-Z world coordinate
     * @return the normal vector at the given point
     */
    function getNormal(xz:Vector2f):Vector3f;

    /**
     * Get the heightmap height at the specified X-Z coordinate. This does not
     * count scaling and snaps the XZ coordinate to the nearest (rounded) heightmap grid point.
     * @param xz world coordinate
     * @return the height, unscaled and uninterpolated
     */
    function getHeightmapHeight(xz:Vector2f):Float;

    /**
     * Set the height at the specified X-Z coordinate.
     * To set the height of the terrain and see it, you will have
     * to unlock the terrain meshes by calling terrain.setLocked(false) before
     * you call setHeight().
     * @param xzCoordinate coordinate to set the height
     * @param height that will be set at the coordinate
     */
    function setHeight(xzCoordinate:Vector2f, height:Float):Void;

    /**
     * Set the height at many points. The two lists must be the same size.
     * Each xz coordinate entry matches to a height entry, 1 for 1. So the 
     * first coordinate matches to the first height value, the last to the 
     * last etc.
     * @param xz a list of coordinates where the hight will be set
     * @param height the heights that match the xz coordinates
     */
    function setHeights(xz:Vector<Vector2f>,height:Vector<Float>):Void;

    /**
     * Raise/lower the height in one call (instead of getHeight then setHeight).
     * @param xzCoordinate world coordinate to adjust the terrain height
     * @param delta +- value to adjust the height by
     */
    function adjustHeight(xzCoordinate:Vector2f, delta:Float):Void;

    /**
     * Raise/lower the height at many points. The two lists must be the same size.
     * Each xz coordinate entry matches to a height entry, 1 for 1. So the
     * first coordinate matches to the first height value, the last to the
     * last etc.
     * @param xz a list of coordinates where the hight will be adjusted
     * @param height +- value to adjust the height by, that matches the xz coordinates
     */
    function adjustHeights(xz:Vector<Vector2f>, height:Vector<Float>):Void;

    /**
     * Get the heightmap of the entire terrain.
     * This can return null if that terrain object does not store the height data.
     * Infinite or "paged" terrains will not be able to support this, so use with caution.
     */
    function getHeightMap():Vector<Float>;
    
    /**
     * This is calculated by the specific LOD algorithm.
     * A value of one means that the terrain is showing full detail.
     * The higher the value, the more the terrain has been generalized
     * and the less detailed it will be.
     */
    function getMaxLod():Int;

    /**
     * Lock or unlock the meshes of this terrain.
     * Locked meshes are un-editable but have better performance.
     * This should call the underlying getMesh().setStatic()/setDynamic() methods.
     * @param locked or unlocked
     */
    function setLocked(locked:Bool):Void;

    /**
     * Pre-calculate entropy values.
     * Some terrain systems support entropy calculations to determine LOD
     * changes. Often these entropy calculations are expensive and can be
     * cached ahead of time. Use this method to do that.
     */
    function generateEntropy(monitor:ProgressMonitor):Void;

    /**
     * Returns the material that this terrain uses.
     * If it uses many materials, just return the one you think is best.
     * For TerrainQuads this is sufficient. For TerrainGrid you want to call
     * getMaterial(Vector3f) instead.
     */
    function getMaterial():Material;
    
    /**
     * Returns the material that this terrain uses.
     * Terrain can have different materials in different locations.
     * In general, the TerrainQuad will only have one material. But 
     * TerrainGrid will have a different material per tile.
     * 
     * It could be possible to pass in null for the location, some Terrain
     * implementations might just have the one material and not care where
     * you are looking. So implementations must handle null being supplied.
     * 
     * @param worldLocation the location, in world coordinates, of where 
     * we are interested in the underlying texture.
     */
    function getMaterialAt(worldLocation:Vector3f):Material;

    /**
     * Used for painting to get the number of vertices along the edge of the
     * terrain.
     * This is an un-scaled size, and should represent the vertex count (ie. the
     * texture coord count) along an edge of a square terrain.
     * 
     * In the standard TerrainQuad default implementation, this will return
     * the "totalSize" of the terrain (512 or so).
     */
    function getTerrainSize():Int;

    /**
     * 
     * 
     */
    function getNumMajorSubdivisions():Int;
}