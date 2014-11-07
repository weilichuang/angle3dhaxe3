package org.angle3d.terrain.geomipmap.lodcalc ;

/**
 * Calculates the LOD value based on where the camera is.
 * This is plugged into the Terrain system and any terrain
 * using LOD will use this to determine when a patch of the 
 * terrain should switch Levels of Detail.
 * 
 * @author bowens
 */
interface LodThreshold
{

    /**
     * A distance of how far between each LOD threshold.
     */
    function getLodDistanceThreshold():Float;

    function clone():LodThreshold;
}
