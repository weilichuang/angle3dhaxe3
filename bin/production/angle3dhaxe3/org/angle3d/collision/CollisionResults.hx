package org.angle3d.collision;
import flash.Vector;
/**
 * <code>CollisionResults</code> is a collection returned as a result of a
 * collision detection operation done by {@link Collidable}.
 *
 * @author Kirill Vainer
 */
class CollisionResults
{

	private var results:Array<CollisionResult>;
	private var sorted:Bool;

	public function new()
	{
		results = new Array<CollisionResult>();
		sorted = true;
	}

	/**
	 * Clears all collision results added to this list
	 */
	public function clear():Void
	{
		results = new Array<CollisionResult>();
	}

	public function addCollision(c:CollisionResult):Void
	{
		results.push(c);
		sorted = false;
	}

	public var size(get, null):Int;
	private function get_size():Int
	{
		return results.length;
	}

	public function getClosestCollision():CollisionResult
	{
		if (results.length == 0)
			return null;

		if (!sorted)
		{
			results.sort(compareTo);
			sorted = true;
		}

		return results[0];
	}

	public function getFarthestCollision():CollisionResult
	{
		if (results.length == 0)
			return null;

		if (!sorted)
		{
			results.sort(compareTo);
			sorted = true;
		}

		return results[results.length - 1];
	}

	public function getCollision(index:Int):CollisionResult
	{
		if (results.length == 0)
			return null;

		if (!sorted)
		{
			results.sort(compareTo);
			sorted = true;
		}

		return results[index];
	}

	/**
	 * Internal use only.
	 * @param index
	 * @return
	 */
	public function getCollisionDirect(index:Int):CollisionResult
	{
		return results[index];
	}

	private function compareTo(a:CollisionResult, b:CollisionResult):Int
	{
		if (a.distance < b.distance)
			return -1;
		else if (a.distance > b.distance)
			return 1;
		else
			return 0;
	}
}

