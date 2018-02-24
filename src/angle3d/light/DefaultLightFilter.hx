package angle3d.light;

import angle3d.bounding.BoundingBox;
import angle3d.bounding.BoundingSphere;
import angle3d.bounding.BoundingVolume;
import angle3d.light.LightList;
import angle3d.scene.Geometry;
import angle3d.renderer.Camera;
import angle3d.utils.TempVars;

//TODO 是否未考虑到灯光被删除的情况
class DefaultLightFilter implements LightFilter {
	private var camera:Camera;

	private var processedLights:Array<Light>;

	public function new() {
		processedLights = new Array<Light>();
	}

	public function setCamera(camera:Camera):Void {
		this.camera = camera;

		var i:Int = processedLights.length - 1;
		while (i >= 0) {
			var light:Light = processedLights[i];
			light.frustumCheckNeeded = true;
			i--;
		}
	}

	public function filterLights(geometry:Geometry, filteredLightList:LightList):Void {
		var worldLights:LightList = geometry.getWorldLightList();
		for (i in 0...worldLights.getSize()) {
			var light:Light = worldLights.getLightAt(i);

			// If this light is not enabled it will be ignored.
			if (!light.enabled) {
				continue;
			}

			if (light.frustumCheckNeeded) {
				if (processedLights.indexOf(light) == -1)
					processedLights[processedLights.length] = light;
				light.frustumCheckNeeded = false;
				light.isIntersectsFrustum = light.intersectsFrustum(camera);
			}

			if (!light.isIntersectsFrustum) {
				continue;
			}

			var bv:BoundingVolume = geometry.getWorldBound();

			if (Std.is(bv, BoundingBox)) {
				if (!light.intersectsBox(cast bv)) {
					continue;
				}
			} else if (Std.is(bv, BoundingSphere)) {
				if (!Math.isFinite(cast(bv, BoundingSphere).radius)) {
					if (!light.intersectsSphere(cast bv)) {
						continue;
					}
				}
			}

			filteredLightList.addLight(light);
		}
	}

}