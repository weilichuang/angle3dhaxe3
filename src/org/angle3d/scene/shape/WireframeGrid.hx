package org.angle3d.scene.shape;

import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;

/**
 * ...
 * @author weilichuang
 */

class WireframeGrid extends WireframeShape
{

	public static inline var PLANE_XY:Int = 0x01;
	public static inline var PLANE_XZ:Int = 0x02;
	public static inline var PLANE_YZ:Int = 0x04;

	/**
	 *
	 * @param	subDivision
	 * @param	gridSize
	 * @param	thickness
	 * @param	color
	 * @param	plane default all plane
	 */
	public function new(subDivision:Int = 10, gridSize:Int = 100, plane:Int = 7)
	{
		super();

		if (subDivision == 0)
			subDivision = 1;
		if (gridSize == 0)
			gridSize = 1;

		if ((plane & PLANE_XY) != 0)
		{
			addGrid(subDivision, gridSize, PLANE_XY);
		}

		if ((plane & PLANE_YZ) != 0)
		{
			addGrid(subDivision, gridSize, PLANE_YZ);
		}

		if ((plane & PLANE_XZ) != 0)
		{
			addGrid(subDivision, gridSize, PLANE_XZ);
		}

		build();
	}

	private function addGrid(subDivision:Int, gridSize:Int, plane:Int):Void
	{
		var bound:Float = gridSize * .5;
		var step:Float = gridSize / subDivision;
		var inc:Float = -bound;
		while (inc <= bound)
		{
			switch (plane)
			{
				case PLANE_YZ:
					addSegment(new WireframeLineSet(0, inc, bound, 0, inc, -bound));
					addSegment(new WireframeLineSet(0, bound, inc, 0, -bound, inc));
				case PLANE_XY:
					addSegment(new WireframeLineSet(bound, inc, 0, -bound, inc, 0));
					addSegment(new WireframeLineSet(inc, bound, 0, inc, -bound, 0));
				default:
					addSegment(new WireframeLineSet(bound, 0, inc, -bound, 0, inc));
					addSegment(new WireframeLineSet(inc, 0, bound, inc, 0, -bound));
			}

			inc += step;
		}
	}
}

