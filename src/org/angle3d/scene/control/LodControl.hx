package org.angle3d.scene.control;

import org.angle3d.bounding.BoundingVolume;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.ViewPort;
import org.angle3d.renderer.RenderManager;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.Spatial;
import org.angle3d.scene.control.Control;

/**
 * Determines what Level of Detail a spatial should be, based on how many pixels
 * on the screen the spatial is taking up. The mothe screen the spatial is taking up. re pixels covered, the more
 * detailed the spatial should be. It calculates the area of the screen that the
 * spatial covers by using its bounding box. When initializing, it will ask the
 * spatial for how many triangles it has for each LOD. It then uses that, along
 * with the trisPerPixel value to determine what LOD it should be at. It
 * requires the camera to do this. The controlRender method is called each frame
 * and will update the spatial's LOD if the camera has moved by a specified
 * amount.
 */
class LodControl extends AbstractControl implements Control
{
	private var trisPerPixel:Float = 1;
    private var distTolerance:Float = 1;
    private var lastDistance:Float = 0;
    private var lastLevel:Int = 0;
    private var numLevels:Int;
    private var numTris:Vector<Int>;

	public function new() 
	{
		super();
		
	}
	
	/**
     * Returns the distance tolerance for changing LOD.
     *
     * @return the distance tolerance for changing LOD.
     *
     * @see setDistTolerance(float)
     */
    public function getDistTolerance():Float
	{
        return distTolerance;
    }

    /**
     * Specifies the distance tolerance for changing the LOD level on the
     * geometry. The LOD level will only get changed if the geometry has moved
     * this distance beyond the current LOD level.
     *
     * @param distTolerance distance tolerance for changing LOD
     */
    public function setDistTolerance(distTolerance:Float):Void
	{
        this.distTolerance = distTolerance;
    }
	
	/**
     * Returns the triangles per pixel value.
     *
     * @return the triangles per pixel value.
     *
     * @see setTrisPerPixel(float)
     */
    public function getTrisPerPixel():Float
	{
        return trisPerPixel;
    }

    /**
     * Sets the triangles per pixel value. The
     * `LodControl` will use this value as an error metric to
     * determine which LOD level to use based on the geometry's area on the
     * screen.
     *
     * @param trisPerPixel triangles per pixel
     */
    public function setTrisPerPixel(trisPerPixel:Float):Void
	{
        this.trisPerPixel = trisPerPixel;
    }
	
	override public function cloneForSpatial(spatial:Spatial):Control 
	{
		var result:LodControl = new LodControl();
		result.setSpatial(spatial);
		result.lastDistance = 0;
		result.lastLevel = 0;
		result.numTris = numTris != null ? numTris.concat() : null;
		return result;
	}
	
	override public function setSpatial(spatial:Spatial):Void 
	{
		if (!Std.is(spatial, Geometry))
		{
			throw 'LodControl can only be attached to Geometry!';
		}
		
		super.setSpatial(spatial);
		
		var geom:Geometry = cast spatial;
		var mesh:Mesh = geom.getMesh();
		numLevels = mesh.getNumLodLevels();
		numTris = new Vector<Int>(numLevels);
		var i:Int = numLevels - 1;
		while (i >= 0)
		{
			numTris[i] = mesh.getTriangleCount(i);
			i--;
		}
	}
	
	override public function update(tpf:Float):Void 
	{
		
	}
	
	override public function render(rm:RenderManager, vp:ViewPort):Void 
	{
		if (numLevels <= 0)
			return;
			
		var bv:BoundingVolume = spatial.getWorldBound();

        var cam:Camera = vp.getCamera();
        var atanNH:Float = Math.atan(cam.frustumNear * cam.frustumTop);
        var ratio:Float = (Math.PI / (8 * atanNH));
        var newDistance:Float = bv.distanceTo(vp.getCamera().getLocation()) / ratio;
        var level:Int;

        if (Math.abs(newDistance - lastDistance) <= distTolerance) 
		{
            level = lastLevel; // we haven't moved relative to the model, send the old measurement back.
        } 
		else if (lastDistance > newDistance && lastLevel == 0)
		{
            level = lastLevel; // we're already at the lowest setting and we just got closer to the model, no need to keep trying.
        }
		else if (lastDistance < newDistance && lastLevel == numLevels - 1)
		{
            level = lastLevel; // we're already at the highest setting and we just got further from the model, no need to keep trying.
        } 
		else
		{
            lastDistance = newDistance;

            // estimate area of polygon via bounding volume
            var area:Float = AreaUtils.calcScreenArea(bv, lastDistance, cam.getWidth());
            var trisToDraw:Float = area * trisPerPixel;
            level = numLevels - 1;
			var i:Int = numLevels;
            while (--i >= 0) 
			{
                if (trisToDraw - numTris[i] < 0) 
				{
                    break;
                }
                level = i;
            }
            lastLevel = level;
        }

        spatial.setLodLevel(level);
	}
}