package com.bulletphysics.dynamics.vehicle;
import com.bulletphysics.collision.dispatch.CollisionWorld.ClosestRayResultCallback;
import vecmath.Vector3f;

/**
 * Default implementation of {@link VehicleRaycaster}.
 * @author weilichuang
 */
class DefaultVehicleRaycaster extends VehicleRaycaster
{

	private var dynamicsWorld:DynamicsWorld;

    public function new(world:DynamicsWorld)
	{
        this.dynamicsWorld = world;
    }

    override public function castRay(from:Vector3f, to:Vector3f, result:VehicleRaycasterResult):Dynamic
	{
        //RayResultCallback& resultCallback;

        var rayCallback:ClosestRayResultCallback = new ClosestRayResultCallback(from, to);

        dynamicsWorld.rayTest(from, to, rayCallback);

        if (rayCallback.hasHit())
		{
            var body:RigidBody = RigidBody.upcast(rayCallback.collisionObject);
            if (body != null && body.hasContactResponse())
			{
                result.hitPointInWorld.fromVector3f(rayCallback.hitPointWorld);
                result.hitNormalInWorld.fromVector3f(rayCallback.hitNormalWorld);
                result.hitNormalInWorld.normalize();
                result.distFraction = rayCallback.closestHitFraction;
                return body;
            }
        }
        return null;
    }
	
}