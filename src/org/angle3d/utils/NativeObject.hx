package org.angle3d.utils;

/**
 * Describes a native object. An encapsulation of a certain object 
 * on the native side of the graphics library.
 * 
 * This class is used to track when OpenGL native objects are 
 * collected by the garbage collector, and then invoke the proper destructor
 * on the OpenGL library to delete it from memory.
 * @author 
 */
class NativeObject 
{
	public static inline var INVALID_ID:Int = -1;
	
	private var _id:Int = INVALID_ID;

	public function new() 
	{
		
	}
	
	public function setId(id:Int):Void
	{
		this._id = id;
	}
	
	public function getId():Int
	{
		return this._id;
	}
	
}