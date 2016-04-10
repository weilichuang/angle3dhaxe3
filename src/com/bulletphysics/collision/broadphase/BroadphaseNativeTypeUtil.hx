package com.bulletphysics.collision.broadphase;

/**
 * ...
 
 */
class BroadphaseNativeTypeUtil
{
	public function new()
	{
		
	}

	public static inline function isPolyhedral(type:BroadphaseNativeType):Bool
	{
		return type.toInt() < BroadphaseNativeType.IMPLICIT_CONVEX_SHAPES_START_HERE.toInt();
	}
	
	public static inline function isConvex(type:BroadphaseNativeType):Bool
	{
		return type.toInt() < BroadphaseNativeType.CONCAVE_SHAPES_START_HERE.toInt();
	}
	
	public static inline function isConcave(type:BroadphaseNativeType):Bool
	{
		var index:Int = type.toInt();
		return index > BroadphaseNativeType.CONCAVE_SHAPES_START_HERE.toInt() &&
				index < BroadphaseNativeType.CONCAVE_SHAPES_END_HERE.toInt();
	}
	
	public static inline function isCompound(type:BroadphaseNativeType):Bool
	{
		return type == BroadphaseNativeType.COMPOUND_SHAPE_PROXYTYPE;
	}
	
	public static inline function isInfinite(type:BroadphaseNativeType):Bool
	{
		return type == BroadphaseNativeType.STATIC_PLANE_PROXYTYPE;
	}
	
}