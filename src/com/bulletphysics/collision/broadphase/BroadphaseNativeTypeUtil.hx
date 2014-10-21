package com.bulletphysics.collision.broadphase;

/**
 * ...
 * @author weilichuang
 */
class BroadphaseNativeTypeUtil
{
	public function new()
	{
		
	}

	public static function isPolyhedral(type:BroadphaseNativeType):Bool
	{
		return Type.enumIndex(type) < Type.enumIndex(BroadphaseNativeType.IMPLICIT_CONVEX_SHAPES_START_HERE);
	}
	
	public static function isConvex(type:BroadphaseNativeType):Bool
	{
		return Type.enumIndex(type) < Type.enumIndex(BroadphaseNativeType.CONCAVE_SHAPES_START_HERE);
	}
	
	public static function isConcave(type:BroadphaseNativeType):Bool
	{
		var index:Int = Type.enumIndex(type);
		return index > Type.enumIndex(BroadphaseNativeType.CONCAVE_SHAPES_START_HERE) &&
				index < Type.enumIndex(BroadphaseNativeType.CONCAVE_SHAPES_END_HERE);
	}
	
	public static function isCompound(type:BroadphaseNativeType):Bool
	{
		return type == BroadphaseNativeType.COMPOUND_SHAPE_PROXYTYPE;
	}
	
	public static function isVoxelWorld(type:BroadphaseNativeType):Bool
	{
		return type == BroadphaseNativeType.VOXEL_WORLD_PROXYTYPE;
	}
	
	public static function isInfinite(type:BroadphaseNativeType):Bool
	{
		return type == BroadphaseNativeType.STATIC_PLANE_PROXYTYPE;
	}
	
}