package com.bulletphysics.dynamics.vehicle;
import com.bulletphysics.collision.dispatch.CollisionWorld.ClosestRayResultCallback;
import org.angle3d.math.Vector3f;

/**
 * Default implementation of {VehicleRaycaster}.
 
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
                result.hitPointInWorld.copyFrom(rayCallback.hitPointWorld);
                result.hitNormalInWorld.copyFrom(rayCallback.hitNormalWorld);
                result.hitNormalInWorld.normalizeLocal();
                result.distFraction = rayCallback.closestHitFraction;
                return body;
            }
        }
        return null;
    }
	
}