package examples;

import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;

/**
 * ...
 * @author 
 */
class BasicExample extends SimpleApplication
{

	public function new() 
	{
		super();
		Angle3D.ignoreSamplerFlag = true;
	}
	
}