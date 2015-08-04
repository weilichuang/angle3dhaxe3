package com.bulletphysics.collision.shapes.voxel;

import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.linearmath.Transform;
import com.vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class VoxelWorldShape extends CollisionShape
{
	public static var AABB_SIZE:Float = Math.POSITIVE_INFINITY;
	
    private var world:VoxelPhysicsWorld;

    private var collisionMargin:Float = 0;
    private var localScaling:Vector3f = new Vector3f(1, 1, 1);

    public function new(world:VoxelPhysicsWorld)
	{
		super();
        this.world = world;
    }
	
	override public function getAabb(t:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		aabbMin.setTo(-AABB_SIZE, -AABB_SIZE, -AABB_SIZE);
        aabbMax.setTo(AABB_SIZE, AABB_SIZE, AABB_SIZE);
	}

	override public function setLocalScaling(scaling:Vector3f):Void 
	{
		localScaling.fromVector3f(scaling);
	}
    
	override public function getLocalScaling(out:Vector3f):Vector3f 
	{
		out.fromVector3f(localScaling);
		return out;
	}
	
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		inertia.setTo(0, 0, 0);
	}

    override public function getShapeType():BroadphaseNativeType 
	{
		return BroadphaseNativeType.VOXEL_WORLD_PROXYTYPE;
	}
	
	override public function setMargin(margin:Float):Void 
	{
		collisionMargin = margin;
	}

    override public function getMargin():Float 
	{
		return collisionMargin;
	}
	
	override public function getName():String 
	{
		return "VoxelWorld";
	}

    public function getWorld():VoxelPhysicsWorld
	{
        return world;
    }
	
}