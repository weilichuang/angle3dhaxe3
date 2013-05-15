package org.angle3d.renderer.queue;

import org.angle3d.renderer.Camera3D;
import org.angle3d.scene.Geometry;

/**
 * <code>NullComparator</code> does not sort geometries. They will be in
 * arbitrary order.
 *
 * @author Kirill Vainer
 */
class NullComparator implements GeometryComparator
{

	public function new()
	{
	}

	public function compare(o1:Geometry, o2:Geometry):Int
	{
		return 0;
	}

	public function setCamera(cam:Camera3D):Void
	{

	}
}

