package org.angle3d.terrain.geomipmap.lodcalc ;


import haxe.ds.StringMap;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.terrain.geomipmap.TerrainPatch;
import org.angle3d.terrain.geomipmap.UpdatedTerrainPatch;
import org.angle3d.utils.Logger;

class PerspectiveLodCalculator implements LodCalculator
{

    private var cam:Camera;
    private var pixelError:Float;
    private var _turnOffLod:Bool = false;

    public function new(cam:Camera, pixelError:Float)
	{
        this.cam = cam;
        this.pixelError = pixelError;
    }

    /**
     * This computes the "C" value in the geomipmapping paper.
     * See section "2.3.1.2 Pre-calculating d"
     * 
     * @param cam
     * @param pixelLimit
     * @return
     */
    private function getCameraConstant(cam:Camera, pixelLimit:Float):Float
	{
        var n:Float = cam.frustumNear;
        var t:Float = FastMath.abs(cam.frustumTop);
        var A:Float = n / t;
        var v_res:Float = cam.height;
        var T:Float = (2 * pixelLimit) / v_res;
        return A / T;
    }
    
    public function calculateLod(patch:TerrainPatch, locations:Array<Vector3f>, updates:StringMap<UpdatedTerrainPatch>):Bool
	{
        if (_turnOffLod) 
		{
            // set to full detail
            var prevLOD:Int = patch.getLod();
            var utp:UpdatedTerrainPatch = updates.get(patch.name);
            if (utp == null)
			{
                utp = new UpdatedTerrainPatch(patch);
                updates.set(utp.getName(), utp);
            }
            utp.setNewLod(0);
            utp.setPreviousLod(prevLOD);
            //utp.setReIndexNeeded(true);
            return true;
        }
        
        var lodEntropies:Array<Float> = patch.getLodEntropies();
        var cameraConstant:Float = getCameraConstant(cam, pixelError);
        
        var patchPos:Vector3f = getCenterLocation(patch);

        // vector from camera to patch
        //Vector3f toPatchDir = locations.get(0).subtract(patchPos).normalizeLocal();
        //float facing = cam.getDirection().dot(toPatchDir);
        var distance:Float = patchPos.distance(locations[0]);

        // go through each lod level to find the one we are in
        for (i in 0...(patch.getMaxLod() + 1))
		{
            if (distance < lodEntropies[i] * cameraConstant || i == patch.getMaxLod())
			{
                var reIndexNeeded:Bool = false;
                if (i != patch.getLod())
				{
                    reIndexNeeded = true;
                    //Logger.log("lod change: "+lod+" > "+i+"    dist: "+distance);
                }
                var prevLOD:Int = patch.getLod();

                var utp:UpdatedTerrainPatch = updates.get(patch.name);
                if (utp == null)
				{
                    utp = new UpdatedTerrainPatch(patch);//save in here, do not update actual variables
                    updates.set(utp.getName(), utp);
                }
                utp.setNewLod(i);
                utp.setPreviousLod(prevLOD);
                //utp.setReIndexNeeded(reIndexNeeded);
                return reIndexNeeded;
            }
        }

        return false;
    }

    public function getCenterLocation(patch:TerrainPatch):Vector3f
	{
        var loc:Vector3f = patch.getWorldTranslation().clone();
        loc.x += patch.getSize() / 2;
        loc.z += patch.getSize() / 2;
        return loc;
    }

    public function clone():LodCalculator
	{
        return new PerspectiveLodCalculator(cam, pixelError);
    }

    public function usesVariableLod():Bool
	{
        return true;
    }

    public function getPixelError():Float 
	{
        return pixelError;
    }

    public function setPixelError(pixelError:Float):Void 
	{
        this.pixelError = pixelError;
    }

    public function setCam(cam:Camera):Void 
	{
        this.cam = cam;
    }

    public function turnOffLod():Void 
	{
        _turnOffLod = true;
    }
    
    public function isLodOff():Bool
	{
        return _turnOffLod;
    }
    
    public function turnOnLod():Void
	{
        _turnOffLod = false;
    }
    
}
