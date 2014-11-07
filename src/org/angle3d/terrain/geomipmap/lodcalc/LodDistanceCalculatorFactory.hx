package org.angle3d.terrain.geomipmap.lodcalc ;

import org.angle3d.terrain.geomipmap.TerrainPatch;

/**
 *
 * @author bowens
 * @deprecated phasing out
 */
class LodDistanceCalculatorFactory implements LodCalculatorFactory
{

    private var lodThresholdSize:Float = 2.7;
    private var lodThreshold:LodThreshold = null;

    public function new(lodThreshold:LodThreshold)
	{
        this.lodThreshold = lodThreshold;
    }

    public function createCalculator():LodCalculator
	{
        return new DistanceLodCalculator();
    }

    public function createCalculatorWith(terrainPatch:TerrainPatch):LodCalculator
	{
        return new DistanceLodCalculator();
    }

    public function clone():LodDistanceCalculatorFactory
	{
        var clone:LodDistanceCalculatorFactory = new LodDistanceCalculatorFactory(lodThreshold.clone());
        clone.lodThresholdSize = lodThresholdSize;
        return clone;
    }

}
