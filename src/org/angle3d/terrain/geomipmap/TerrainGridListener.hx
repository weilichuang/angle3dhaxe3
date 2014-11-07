package org.angle3d.terrain.geomipmap ;
import org.angle3d.math.Vector3f;

/**
 * Notifies the user of grid change events, such as moving to new grid cells.
 * @author Anthyon
 */
interface TerrainGridListener 
{
	/**
     * Called whenever the camera has moved full grid cells. This triggers new tiles to load.
     * @param newCenter 
     */
    function gridMoved(newCenter:Vector3f):Void;

    /**
     * Called when a TerrainQuad is attached to the scene and is visible (attached to the root TerrainGrid)
     * @param cell the cell that is moved into
     * @param quad the quad that was just attached
     */
    function tileAttached( cell:Vector3f, quad:TerrainQuad ):Void;

    /**
     * Called when a TerrainQuad is detached from its TerrainGrid parent: it is no longer on the scene graph.
     * @param cell the cell that is moved into
     * @param quad the quad that was just detached
     */
    function tileDetached( cell:Vector3f, quad:TerrainQuad ):Void;
}