package org.angle3d.scene.debug;

import org.angle3d.scene.shape.WireframeLineSet;
import org.angle3d.scene.shape.WireframeShape;

/**
 * ...
 * @author weilichuang
 */
class WireBox extends WireframeShape
{

	public function new(xExt:Float, yExt:Float, zExt:Float)
	{
		super();
		buildBox(xExt, yExt, zExt);
	}
	
	public function buildBox(xExt:Float, yExt:Float, zExt:Float):Void
	{
		clearSegment();
		var points:Array<Float> = [-xExt, -yExt,  zExt,
									 xExt, -yExt,  zExt,
									 xExt,  yExt,  zExt,
									-xExt,  yExt,  zExt,

									-xExt, -yExt, -zExt,
									 xExt, -yExt, -zExt,
									 xExt,  yExt, -zExt,
									-xExt,  yExt, -zExt];
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

	private function addLine(points:Array<Float>, begin:Int, end:Int):Void
	{
		var bx:Float = points[begin * 3];
		var by:Float = points[begin * 3 + 1];
		var bz:Float = points[begin * 3 + 2];
		
		var ex:Float = points[end * 3];
		var ey:Float = points[end * 3 + 1];
		var ez:Float = points[end * 3 + 2];
		this.addSegment(new WireframeLineSet(bx,by,bz,ex,ey,ez));
	}
	
}