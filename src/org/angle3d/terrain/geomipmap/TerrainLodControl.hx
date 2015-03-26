package org.angle3d.terrain.geomipmap ;
import org.angle3d.scene.Spatial;

import org.angle3d.utils.FastStringMap;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.scene.control.AbstractControl;
import org.angle3d.scene.control.Control;
import org.angle3d.terrain.geomipmap.lodcalc.DistanceLodCalculator;
import org.angle3d.terrain.geomipmap.lodcalc.LodCalculator;

/**
 * Tells the terrain to update its Level of Detail.
 * It needs the cameras to do this, and there could possibly
 * be several cameras in the scene, so it accepts a list
 * of cameras.
 * NOTE: right now it just uses the first camera passed in,
 * in the future it will use all of them to determine what
 * LOD to set.
 *
 * This control serializes, but it does not save the Camera reference.
 * This camera reference has to be manually added in when you load the
 * terrain to the scene!
 * 
 * When the control or the terrain are removed from the scene, you should call
 * TerrainLodControl.detachAndCleanUpControl() to remove any threads it created
 * to handle the LOD processing. If you supply your own executor service, then
 * you have to handle its thread termination yourself.
 * 
 * @author Brent Owens
 */
class TerrainLodControl extends AbstractControl
{

	private var terrain:Terrain;
    private var cameras:Array<Camera>;
    private var cameraLocations:Array<Vector3f> = new Array<Vector3f>();
    private var lodCalculator:LodCalculator;
    private var hasResetLod:Bool = false; // used when enabled is set to false

    private var updatedPatches:FastStringMap<UpdatedTerrainPatch>;
    private var updatePatchesLock:Dynamic = { };
    
    private var lastCameraLocations:Array<Vector3f>; // used for LOD calc
    private var lodCalcRunning:Bool = false;
    private var lodOffCount:Int = 0;
    
    private var indexer:FastStringMap<UpdatedTerrainPatch>;
    private var _forceUpdate:Bool = true;
    
    public function new(terrain:Terrain, camera:Camera)
	{
		super();
        var cams:Array<Camera> = new Array<Camera>();
        cams.push(camera);
        this.terrain = terrain;
        this.cameras = cams;
        lodCalculator = new DistanceLodCalculator(65, 2.7); // a default calculator
    }
	
	override private function controlUpdate(tpf:Float):Void
	{
		//list of cameras for when terrain supports multiple cameras (ie split screen)

        if (lodCalculator == null)
            return;
        
        if (!_enabled) 
		{
            if (!hasResetLod) 
			{
                // this will get run once
                hasResetLod = true;
                lodCalculator.turnOffLod();
            }
        }
        
        if (cameras != null)
		{
            cameraLocations = [];
            for (c in cameras) // populate them
            {
                cameraLocations.push(c.location);
            }
            updateLOD(cameraLocations, lodCalculator);
        }
	}
	
    /**
     * Call this when you remove the terrain or this control from the scene.
     * It will clear up any threads it had.
     */
    public function detachAndCleanUpControl():Void
	{
        //if (executor != null)
            //executor.shutdownNow();
        getSpatial().removeControl(this);
    }

    // do all of the LOD calculations
    private function updateLOD(locations:Array<Vector3f>, lodCalculator:LodCalculator):Void
	{
        if (getSpatial() == null)
		{
            return;
        }
        
        // update any existing ones that need updating
        updateQuadLODs();

        if (lodCalculator.isLodOff())
		{
            // we want to calculate the base lod at least once
            if (lodOffCount == 1)
                return;
            else
                lodOffCount++;
        } else 
            lodOffCount = 0;
        
        if (lastCameraLocations != null)
		{
            if (!_forceUpdate && lastCameraLocationsTheSame(locations) && !lodCalculator.isLodOff())
                return; // don't update if in same spot
            else
                lastCameraLocations = cloneVectorList(locations);
            _forceUpdate = false;
        }
        else
		{
            lastCameraLocations = cloneVectorList(locations);
            return;
        }

        if (isLodCalcRunning()) 
		{
            return;
        }
        setLodCalcRunning(true);

        //if (executor == null)
            //executor = createExecutorService();
        
        prepareTerrain();
        
        var updateLodThread:UpdateLOD = getLodThread(locations, lodCalculator);
        //indexer = executor.submit(updateLodThread);
    }

    /**
     * Force the LOD to update instantly, does not wait for the camera to move.
     * It will reset once it has updated.
     */
    public function forceUpdate():Void
	{
        this._forceUpdate = true;
    }
    
    private function prepareTerrain():Void
	{
        var terrain:TerrainQuad = cast getSpatial();
        terrain.cacheTerrainTransforms();// cache the terrain's world transforms so they can be accessed on the separate thread safely
    }
    
    private function getLodThread(locations:Array<Vector3f>, lodCalculator:LodCalculator):UpdateLOD
	{
        return new UpdateLOD(this,locations, lodCalculator);
    }

    /**
     * Back on the ogl thread: update the terrain patch geometries
     */
    private function updateQuadLODs():Void
	{
        //if (indexer != null)
		//{
            //if (indexer.isDone()) 
			//{
                //try {
                    //
                    //HashMap<String, UpdatedTerrainPatch> updated = indexer.get();
                    //if (updated != null) {
                        //// do the actual geometry update here
                        //for (UpdatedTerrainPatch utp : updated.values()) {
                            //utp.updateAll();
                        //}
                    //}
                    //
                //} catch (InterruptedException ex) {
                    //Logger.getLogger(TerrainLodControl.class.getName()).log(Level.SEVERE, null, ex);
                //} catch (ExecutionException ex) {
                    //Logger.getLogger(TerrainLodControl.class.getName()).log(Level.SEVERE, null, ex);
                //} finally {
                    //indexer = null;
                //}
            //}
        //}
    }
    
    private function lastCameraLocationsTheSame(locations:Array<Vector3f>):Bool
	{
        var theSame:Bool = true;
        for (l in locations)
		{
            for (v in lastCameraLocations)
			{
                if (!v.equals(l) ) 
				{
                    theSame = false;
                    return false;
                }
            }
        }
        return theSame;
    }
    
    public function isLodCalcRunning():Bool
	{
        return lodCalcRunning;
    }

    public function setLodCalcRunning(running:Bool):Void
	{
        lodCalcRunning = running;
    }

    private function cloneVectorList(locations:Array<Vector3f>):Array<Vector3f>
	{
        var cloned:Array<Vector3f> = new Array<Vector3f>();
        for(l in locations)
            cloned.push(l.clone());
        return cloned;
    }

    override public function cloneForSpatial(spatial:Spatial):Control 
	{
		if (Std.is(spatial, Terrain))
		{
            var cameraClone:Array<Camera> = new Array<Camera>();
            if (cameras != null)
			{
                for (c in cameras)
				{
                    cameraClone.push(c);
                }
            }
            var cloned:TerrainLodControl = new TerrainLodControl(cast spatial, cameraClone[0]);
            cloned.setLodCalculator(lodCalculator.clone());
            return cloned;
        }
        return null;
	}

    public function setCamera(camera:Camera):Void
	{
        var cams:Array<Camera> = new Array<Camera>();
        cams.push(camera);
        setCameras(cams);
    }
    
    public function setCameras(cameras:Array<Camera>):Void
	{
        this.cameras = cameras;
        cameraLocations = [];
        for (c in cameras)
		{
            cameraLocations.push(c.location);
        }
    }
	
	override public function setSpatial(value:Spatial):Void 
	{
		super.setSpatial(value);
		if (Std.is(spatial, Terrain))
		{
            this.terrain = cast spatial;
        }
	}

    public function setTerrain(terrain:Terrain):Void
	{
        this.terrain = terrain;
    }

    public function getLodCalculator():LodCalculator
	{
        return lodCalculator;
    }

    public function setLodCalculator(lodCalculator:LodCalculator):Void
	{
        this.lodCalculator = lodCalculator;
    }
	
	override public function setEnabled(value:Bool):Void 
	{
		this._enabled = value;
        if (!_enabled) 
		{
            // reset the lod levels to max detail for the terrain
            hasResetLod = false;
        }
		else 
		{
            hasResetLod = true;
            lodCalculator.turnOnLod();
        }
	}
}

/**
 * Calculates the LOD of all child terrain patches.
 */
class UpdateLOD //implements Callable<HashMap<String,UpdatedTerrainPatch>> 
{
	private var control:TerrainLodControl;
	private var camLocations:Array<Vector3f>;
	private var lodCalculator:LodCalculator;

	public function new(control:TerrainLodControl,camLocations:Array<Vector3f>, lodCalculator:LodCalculator)
	{
		this.control = control;
		this.camLocations = camLocations;
		this.lodCalculator = lodCalculator;
	}

	public function call():FastStringMap<UpdatedTerrainPatch>
	{
		//long start = System.currentTimeMillis();
		//if (isLodCalcRunning()) {
		//    return null;
		//}
		control.setLodCalcRunning(true);

		var terrainQuad:TerrainQuad = cast control.getSpatial();
		
		// go through each patch and calculate its LOD based on camera distance
		var updated:FastStringMap<UpdatedTerrainPatch> = new FastStringMap<UpdatedTerrainPatch>();
		var lodChanged:Bool = terrainQuad.calculateLod(camLocations, updated, lodCalculator); // 'updated' gets populated here

		if (!lodChanged) 
		{
			// not worth updating anything else since no one's LOD changed
			control.setLodCalcRunning(false);
			return null;
		}
		
		
		// then calculate its neighbour LOD values for seaming in the shader
		terrainQuad.findNeighboursLod(updated);

		terrainQuad.fixEdges(updated); // 'updated' can get added to here

		terrainQuad.reIndexPages(updated, lodCalculator.usesVariableLod());

		//setUpdateQuadLODs(updated); // set back to main ogl thread

		control.setLodCalcRunning(false);
		
		return updated;
	}
}