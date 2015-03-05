package org.angle3d.terrain.geomipmap.lodcalc ;
import haxe.ds.UnsafeStringMap;
import org.angle3d.math.Vector3f;

/**
 * Calculate the Level of Detail of a terrain patch based on the
 * cameras, or other locations.
 *
 * @author Brent Owens
 */
interface LodCalculator 
{
	function calculateLod(terrainPatch:TerrainPatch, locations:Array<Vector3f>, updates:UnsafeStringMap<UpdatedTerrainPatch>):Bool;
    
    function clone():LodCalculator;
    
    function turnOffLod():Void;
    function turnOnLod():Void;
    function isLodOff():Bool;

    /**
     * If true, then this calculator can cause neighbouring terrain chunks to 
     * have LOD levels that are greater than 1 apart.
     * Entropy algorithms will want to return true for this. Straight distance
     * calculations will just want to return false.
     */
    function usesVariableLod():Bool;
}