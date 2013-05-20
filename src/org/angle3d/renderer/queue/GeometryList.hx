package org.angle3d.renderer.queue;

import org.angle3d.renderer.Camera3D;
import org.angle3d.scene.Geometry;
import flash.Vector;

/**
 * This class is a special function list of Spatial objects for render
 * queuing.
 *
 * @author Jack Lindamood
 * @author Three Rings - better sorting alg.
 */
class GeometryList
{
	public var size(get, null):Int;
	public var isEmpty(get, null):Bool;
	
	private var _geometries:Array<Geometry>;
	private var _comparator:GeometryComparator;
	private var _size:Int;

	public function new(comparator:GeometryComparator)
	{
		_geometries = new Array<Geometry>();
		_size = 0;

		_comparator = comparator;
	}

	/**
	 * Returns the GeometryComparator that this Geometry list uses
	 * for sorting.
	 */
	public function getComparator():GeometryComparator
	{
		return _comparator;
	}

	public function setCamera(cam:Camera3D):Void
	{
		_comparator.setCamera(cam);
	}

	
	private function get_size():Int
	{
		return _size;
	}
	
	private function get_isEmpty():Bool
	{
		return _size == 0;
	}

	public inline function getGeometry(i:Int):Geometry
	{
		return _geometries[i];
	}

	/**
	 * Adds a geometry to the list. List size is doubled if there is no room.
	 *
	 * @param g
	 *            The geometry to add.
	 */
	public function add(g:Geometry):Void
	{
		_geometries[_size++] = g;
	}

	/**
	 * Resets list size to 0.
	 */
	public function clear():Void
	{
		_geometries = [];

		_size = 0;
	}

	/**
	 * Sorts the elements in the list according to their Comparator.
	 */
	//TODO 需要优化，目前排序时间有点长
	public function sort():Void
	{
		if (_size > 1)
		{
			// sort the spatial list using the comparator
			_geometries.sort(_comparator.compare);
		}
	}
}

