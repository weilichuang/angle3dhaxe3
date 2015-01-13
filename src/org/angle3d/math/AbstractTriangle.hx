package org.angle3d.math;

import org.angle3d.collision.Collidable;
import org.angle3d.collision.CollisionResults;
import org.angle3d.math.Vector3f;

/**
 * andy
 * @author weilichuang
 */

class AbstractTriangle implements Collidable
{

	public function new()
	{

	}

	public function getPoint(i:Int):Vector3f
	{
		return null;
	}

	public function setPoint(i:Int, point:Vector3f):Void
	{

	}


	public function getPoint1():Vector3f
	{
		return null;
	}

	public function getPoint2():Vector3f
	{
		return null;
	}

	public function getPoint3():Vector3f
	{
		return null;
	}

	public function setPoints(p1:Vector3f, p2:Vector3f, p3:Vector3f):Void
	{

	}

	public function collideWith(other:Collidable, results:CollisionResults):Int
	{
		return other.collideWith(this, results);
	}
}

