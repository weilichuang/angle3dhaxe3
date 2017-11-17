package org.angle3d.math;

/**
 * Line defines a line. Where a line is defined as infinite along
 * two points. The two points of the line are defined as the origin and direction.
 */
class Line {
	/**
	 * the origin of the line
	 */
	public var origin:Vector3f;

	/**
	 * the direction of the line
	 */
	public var direction:Vector3f;

	public function new(origin:Vector3f = null, direction:Vector3f = null) {
		this.origin = new Vector3f();
		this.direction = new Vector3f();

		if (origin != null) {
			this.origin.copyFrom(origin);
		}

		if (direction != null) {
			this.direction.copyFrom(direction);
		}
	}

	/**
	 * 到某点的距离
	 * @param	point
	 * @return
	 */
	//TODO 如何计算的列出步骤
	public function distanceSquared(point:Vector3f):Float {
		var compVec1:Vector3f = new Vector3f();
		var compVec2:Vector3f = new Vector3f();

		point.subtract(origin, compVec1);
		var lineParameter:Float = direction.dot(compVec1);
		direction.scale(lineParameter, compVec2);
		origin.add(compVec2, compVec2);
		compVec2.subtract(point, compVec1);

		return compVec1.lengthSquared;
	}

	public function distance(point:Vector3f):Float {
		return Math.sqrt(distanceSquared(point));
	}

	public function getRandomPointInLine(result:Vector3f):Void {
		var rand:Float = Math.random();
		var rand1:Float = 1.0 - rand;
		result.x = origin.x * rand1 + direction.x * rand;
		result.y = origin.y * rand1 + direction.y * rand;
		result.z = origin.z * rand1 + direction.z * rand;
	}

	public inline function clone():Line {
		return new Line(this.origin, this.direction);
	}
}

