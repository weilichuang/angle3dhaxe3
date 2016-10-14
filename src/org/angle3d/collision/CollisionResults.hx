package org.angle3d.collision;
import flash.Vector;
/**
 * CollisionResults is a collection returned as a result of a
 * collision detection operation done by Collidable.
 *
 */
class CollisionResults
{
	public var size(get, null):Int;
	
	private var results:Vector<CollisionResult>;
	private var sorted:Bool;
	private var _size:Int = 0;

	public function new()
	{
		results = new Vector<CollisionResult>();
		sorted = true;
	}

	/**
	 * Clears all collision results added to this list
	 */
	public inline function clear():Void
	{
		results.length = 0;
		_size = 0;
	}

	public function addCollision(c:CollisionResult):Void
	{
		results[_size] = c;
		_size++;
		sorted = false;
	}

	public function getClosestCollision():CollisionResult
	{
		if (_size == 0)
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
		if (_size == 0)
			return null;

		if (!sorted)
		{
			results.sort(compareTo);
			sorted = true;
		}

		return results[_size - 1];
	}

	public function getCollision(index:Int):CollisionResult
	{
		if (_size == 0)
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
	@:dox(hide)
	public function getCollisionDirect(index:Int):CollisionResult
	{
		return results[index];
	}
	
	private inline function get_size():Int
	{
		return _size;
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

