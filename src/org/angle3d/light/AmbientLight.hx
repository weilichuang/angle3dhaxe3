package org.angle3d.light;
import org.angle3d.scene.Spatial;

/**
 * An ambient light adds a constant color to the scene.
 * <p>
 * Ambient lights are unaffected by the surface normal, and are constant
 * regardless of the model's location. The material's ambient color is
 * multiplied by the ambient light color to get the final ambient color of
 * an object.
 * 
 */
class AmbientLight extends Light
{

	public function new() 
	{
		super();
		this.type = LightType.Ambient;
	}
	
	override public function computeLastDistance(owner:Spatial):Void
	{
		// ambient lights must always be before directional lights.
        lastDistance = -2;
	}
	
	override public function clone():Light
	{
		var light:AmbientLight = new AmbientLight();
		light.copyFrom(this);
		return light;
	}
}