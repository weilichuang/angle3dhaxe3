package org.angle3d.renderer;
import flash.display.Stage3D;
import org.angle3d.material.shader.ShaderProfile;

class DefaultRenderer extends Stage3DRenderer
{
	public function new(stage3D:Stage3D,profile:ShaderProfile)
	{
		super(stage3D,profile);
	}
}
