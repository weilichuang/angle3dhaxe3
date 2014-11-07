package org.angle3d.terrain.geomipmap.lodcalc ;

import org.angle3d.terrain.geomipmap.TerrainPatch;

/**
 * Creates LOD Calculator objects for the terrain patches.
 *
 * @author Brent Owens
 * @deprecated phasing this out
 */
interface LodCalculatorFactory
{

    function createCalculator():LodCalculator;
    function createCalculatorWith(terrainPatch:TerrainPatch):LodCalculator;

    function clone():LodCalculatorFactory;
}
