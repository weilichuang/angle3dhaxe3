package org.angle3d.terrain.geomipmap.lodcalc ;

import org.angle3d.renderer.Camera;
import org.angle3d.terrain.geomipmap.TerrainPatch;

/**
 * TODO: Make it work with multiple cameras
 * TODO: Fix the cracks when the lod differences are greater than 1
 * for two adjacent blocks.
 * @deprecated phasing out
 */
class LodPerspectiveCalculatorFactory implements LodCalculatorFactory 
{

    private var cam:Camera;
    private var pixelError:Float;

    public function new(cam:Camera, pixelError:Float)
	{
        this.cam = cam;
        this.pixelError = pixelError;
    }

    public function createCalculator():LodCalculator
	{
        return new PerspectiveLodCalculator(cam, pixelError);
    }

    public function createCalculatorWith(terrainPatch:TerrainPatch):LodCalculator
	{
        var p:PerspectiveLodCalculator = new PerspectiveLodCalculator(cam, pixelError);
        return p;
    }

    public function clone():LodCalculatorFactory
	{
       return new LodPerspectiveCalculatorFactory(cam, pixelError);
    }

}
