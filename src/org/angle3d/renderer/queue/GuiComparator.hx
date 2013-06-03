package org.angle3d.renderer.queue;

import org.angle3d.renderer.Camera;
import org.angle3d.scene.Geometry;

/**
 * <code>GuiComparator</code> sorts geometries back-to-front based
 * on their Z position.
 *
 * @author Kirill Vainer
 */
class GuiComparator implements GeometryComparator
{

	public function new()
	{
	}

	public function compare(o1:Geometry, o2:Geometry):Int
	{
		var z1:Float = o1.getWorldTranslation().z;
		var z2:Float = o2.getWorldTranslation().z;
		if (z1 > z2)
		{
			return 1;
		}
		else if (z1 < z2)
		{
			return -1;
		}
		else
		{
			return 0;
		}
	}

	public function setCamera(cam:Camera):Void
	{

	}
}

