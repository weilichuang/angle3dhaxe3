package angle3d.scene.control;

import angle3d.light.DirectionalLight;
import angle3d.light.Light;
import angle3d.light.PointLight;
import angle3d.light.SpotLight;
import angle3d.renderer.RenderManager;
import angle3d.renderer.ViewPort;
import angle3d.scene.Spatial;
import angle3d.math.Vector3f;

/**
 * This Control maintains a reference to a Light
 */
class LightControl extends AbstractControl {
	/**
	 * Means, that the Light's transform is "copied"
	 * to the Transform of the Spatial.
	 */
	public static inline var LightToSpatial:String = "lightToSpatial";
	/**
	 * Means, that the Spatial's transform is "copied"
	 * to the Transform of the light.
	 */
	public static inline var SpatialToLight:String = "spatialToLight";

	public var controlDir(get, set):String;
	public var light(get, set):Light;

	private var mLight:Light;
	private var mControlDir:String;

	public function new(light:Light = null, controlDir:String = "spatialToLight") {
		super();

		if (light != null) {
			this.mLight = light;
		}

		this.mControlDir = controlDir;
	}

	private function set_controlDir(dir:String):String {
		return this.mControlDir = dir;
	}

	private function get_controlDir():String {
		return mControlDir;
	}

	private function set_light(light:Light):Light {
		return this.mLight = light;
	}

	private function get_light():Light {
		return mLight;
	}

	override private function controlUpdate(tpf:Float):Void {
		if (getSpatial() != null && mLight != null) {
			switch (mControlDir) {
				case SpatialToLight:
					_spatialToLight(mLight);
				case LightToSpatial:
					_lightToSpatial(mLight);
			}
		}
	}

	private function _spatialToLight(light:Light):Void {
		var spatial:Spatial = getSpatial();
		if (Std.is(light,PointLight)) {
			var pl:PointLight = cast light;
			pl.position = spatial.getWorldTranslation();
		} else if (Std.is(light,DirectionalLight)) {
			var dl:DirectionalLight = cast light;
			var p:Vector3f = dl.direction;
			p.copyFrom(spatial.getWorldTranslation());
			p.scaleLocal( -1);
		} else if (Std.is(light, SpotLight)) {
			var sp:SpotLight = cast light;
			sp.position = spatial.getWorldTranslation();
			sp.direction = spatial.getWorldRotation().multVecLocal(new Vector3f(0,1,0)).scaleLocal(-1);
		}
	}

	private function _lightToSpatial(light:Light):Void {
		var spatial:Spatial = getSpatial();

		var vecDiff:Vector3f;
		if (Std.is(light,PointLight)) {
			var pLight:PointLight = Std.instance(light, PointLight);

			vecDiff = pLight.position.subtract(spatial.getWorldTranslation());
			vecDiff.addLocal(spatial.localTranslation);
			spatial.localTranslation = vecDiff;
		} else if (Std.is(light,DirectionalLight)) {
			var dLight:DirectionalLight = Std.instance(light,DirectionalLight);
			vecDiff = dLight.direction.clone();
			vecDiff.scaleLocal(-1);
			vecDiff.subtractLocal(spatial.getWorldTranslation());
			vecDiff.addLocal(spatial.localTranslation);
			spatial.localTranslation = vecDiff;
		}
	}

	override private function controlRender(rm:RenderManager, vp:ViewPort):Void {

	}

	override public function cloneForSpatial(newSpatial:Spatial):Control {
		var control:LightControl = new LightControl(this.mLight, this.mControlDir);
		control.setSpatial(newSpatial);
		control.setEnabled(isEnabled());
		return control;
	}
}

