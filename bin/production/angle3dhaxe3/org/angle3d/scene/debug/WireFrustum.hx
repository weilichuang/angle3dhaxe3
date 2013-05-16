package org.angle3d.scene.debug;

import org.angle3d.math.Vector3f;
import org.angle3d.scene.shape.WireframeLineSet;
import org.angle3d.scene.shape.WireframeShape;
import flash.Vector;

class WireFrustum extends WireframeShape
{
	public function new(points:Vector<Vector3f>)
	{
		super();

		buildWireFrustum(points);
	}

	public function buildWireFrustum(points:Vector<Vector3f>):Void
	{
		addLine(points, 0, 1);
		addLine(points, 1, 2);
		addLine(points, 2, 3);
		addLine(points, 3, 0);

		addLine(points, 4, 5);
		addLine(points, 5, 6);
		addLine(points, 6, 7);
		addLine(points, 7, 4);

		addLine(points, 0, 4);
		addLine(points, 1, 5);
		addLine(points, 2, 6);
		addLine(points, 3, 7);

		build();
	}

	private function addLine(points:Vector<Vector3f>, begin:Int, end:Int):Void
	{
		var bv:Vector3f = points[begin];
		var ev:Vector3f = points[end];
		this.addSegment(new WireframeLineSet(bv.x, bv.y, bv.z, ev.x, ev.y, ev.z));
	}
}
