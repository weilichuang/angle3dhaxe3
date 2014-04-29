package org.angle3d.light;

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
		super(LightType.Ambient);
	}
	
}