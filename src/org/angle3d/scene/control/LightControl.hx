package org.angle3d.scene.control;

import org.angle3d.light.DirectionalLight;
import org.angle3d.light.Light;
import org.angle3d.light.PointLight;
import org.angle3d.light.SpotLight;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Spatial;
import org.angle3d.math.Vector3f;

/**
 * This Control maintains a reference to a Light
 * @author tim
 */
class LightControl extends AbstractControl
{
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

	public function new(light:Light = null, controlDir:String = "spatialToLight")
	{
		super();

		if (light != null)
		{
			this.mLight = light;
		}

		this.mControlDir = controlDir;
	}

	
	private function set_controlDir(dir:String):String
	{
		return this.mControlDir = dir;
	}
	
	private function get_controlDir():String
	{
		return mControlDir;
	}

	private function set_light(light:Light):Light
	{
		return this.mLight = light;
	}

	private function get_light():Light
	{
		return mLight;
	}

	override private function controlUpdate(tpf:Float):Void
	{
		if (spatial != null && mLight != null)
		{
			switch (mControlDir)
			{
				case SpatialToLight:
					_spatialToLight(mLight);
				case LightToSpatial:
					_lightToSpatial(mLight);
			}
		}
	}

	private function _spatialToLight(light:Light):Void
	{
		if (Std.is(light,PointLight))
		{
			var pl:PointLight = Std.instance(light,PointLight);
			pl.position = spatial.getWorldTranslation();
		}
		else if (Std.is(light,DirectionalLight))
		{
			var dl:DirectionalLight = Std.instance(light,DirectionalLight);
			//TODO 这里是不是传错了
			var p:Vector3f = dl.direction;
			p.copyFrom(spatial.getWorldTranslation());
				//p.scaleBy( -1);
		}

		//TODO add code for Spot light here when it's done
		//else if (Std.is(light, SpotLight))
		//{
		//var sp:SpotLight = Lib.as(light, SpotLight);
		//sp.setPosition(spatial.getWorldTranslation());
		//sp.setRotation(spatial.getWorldRotation());
		//}
	}

	private function _lightToSpatial(light:Light):Void
	{
		var vecDiff:Vector3f;
		if (Std.is(light,PointLight))
		{
			var pLight:PointLight = Std.instance(light, PointLight);

			vecDiff = pLight.position.subtract(spatial.getWorldTranslation());
			vecDiff.addLocal(spatial.translation);
			spatial.translation = vecDiff;
		}
		else if (Std.is(light,DirectionalLight))
		{
			var dLight:DirectionalLight = Std.instance(light,DirectionalLight);
			vecDiff = dLight.direction.clone();
			vecDiff.scaleLocal(-1);
			vecDiff.subtractLocal(spatial.getWorldTranslation());
			vecDiff.addLocal(spatial.translation);
			spatial.translation = vecDiff;
		}
	}

	override private function controlRender(rm:RenderManager, vp:ViewPort):Void
	{

	}

	override public function cloneForSpatial(newSpatial:Spatial):Control
	{
		var control:LightControl = new LightControl(this.mLight, this.mControlDir);
		control.spatial = newSpatial;
		control.enabled = enabled;
		return control;
	}
}


