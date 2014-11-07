package org.angle3d.terrain.geomipmap.picking ;
import org.angle3d.collision.CollisionResults;
import org.angle3d.math.Ray;
import org.angle3d.math.Vector3f;

/**
 * Pick the location on the terrain from a given ray.
 *
 * @author Brent Owens
 */
interface TerrainPicker 
{
	/**
     * Ask for the point of intersection between the given ray and the terrain.
     *
     * @param worldPick
     *            our pick ray, in world space.
     * @return null if no pick is found. Otherwise it returns a Vector3f  populated with the pick
     *         coordinates.
     */
    function getTerrainIntersection(worldPick:Ray, results:CollisionResults):Vector3f;
}