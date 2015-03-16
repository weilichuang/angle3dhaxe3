package org.angle3d.light;
import flash.Vector;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingSphere;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.light.LightList;
import org.angle3d.scene.Geometry;
import org.angle3d.renderer.Camera;
import org.angle3d.utils.TempVars;

class DefaultLightFilter implements LightFilter
{
	private var camera:Camera;
	
    private var processedLights:Vector<Light>;

	public function new() 
	{
		processedLights = new Vector<Light>();
	}
	
	public function setCamera(camera:Camera):Void 
	{
		this.camera = camera;
        for (light in processedLights)
		{
            light.frustumCheckNeeded = true;
        }
	}
	
	public function filterLights(geometry:Geometry, filteredLightList:LightList):Void 
	{
		var vars:TempVars = TempVars.getTempVars();

		var worldLights:LightList = geometry.getWorldLightList();
		for (i in 0...worldLights.getSize()) 
		{
			var light:Light = worldLights.getLightAt(i);

			if (light.frustumCheckNeeded)
			{
				processedLights.push(light);
				light.frustumCheckNeeded = false;
				light.isIntersectsFrustum = light.intersectsFrustum(camera, vars);
			}

			if (!light.isIntersectsFrustum) 
			{
				continue;
			}

			var bv:BoundingVolume = geometry.getWorldBound();
			
			if (Std.is(bv, BoundingBox))
			{
				if (!light.intersectsBox(cast bv, vars))
				{
					continue;
				}
			} 
			else if (Std.is(bv, BoundingSphere))
			{
				if (!Math.isFinite(cast(bv, BoundingSphere).radius))
				{
					// Non-infinite bounding sphere... Not supported yet.
					throw ("Only AABB supported for now");
				}
			}

			filteredLightList.addLight(light);
		}

		vars.release();
	}
	
}