package org.angle3d.light;
import flash.Vector;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.bounding.BoundingSphere;
import org.angle3d.bounding.BoundingVolume;
import org.angle3d.light.LightList;
import org.angle3d.scene.Geometry;
import org.angle3d.renderer.Camera;
import org.angle3d.utils.TempVars;

//TODO 是否未考虑到灯光被删除的情况
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
		
		var i:Int = processedLights.length - 1;
		while (i >= 0)
		{
			var light:Light = processedLights[i];
			if (light.owner == null)
			{
				var index:Int = processedLights.indexOf(light);
				processedLights.splice(index, 1);
				light.frustumCheckNeeded = false;
			}
			else
			{
				light.frustumCheckNeeded = true;
			}
			i--;
		}
	}
	
	public function filterLights(geometry:Geometry, filteredLightList:LightList):Void 
	{
		var worldLights:LightList = geometry.getWorldLightList();
		for (i in 0...worldLights.getSize()) 
		{
			var light:Light = worldLights.getLightAt(i);
			
			// If this light is not enabled it will be ignored.
			if (!light.enabled) 
			{
				continue;
			}

			if (light.frustumCheckNeeded)
			{
				if(processedLights.indexOf(light) == -1)
					processedLights[processedLights.length] = light;
				light.frustumCheckNeeded = false;
				light.isIntersectsFrustum = light.intersectsFrustum(camera);
			}

			if (!light.isIntersectsFrustum) 
			{
				continue;
			}

			var bv:BoundingVolume = geometry.getWorldBound();
			
			if (Std.is(bv, BoundingBox))
			{
				if (!light.intersectsBox(cast bv))
				{
					continue;
				}
			} 
			else if (Std.is(bv, BoundingSphere))
			{
				if (!Math.isFinite(cast(bv, BoundingSphere).radius))
				{
					if (!light.intersectsSphere(cast bv)) 
					{
						continue;
					}
				}
			}

			filteredLightList.addLight(light);
		}
	}
	
}