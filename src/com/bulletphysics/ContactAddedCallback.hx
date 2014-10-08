package com.bulletphysics;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;

/**
 * Called when contact has been created between two collision objects. At least
 * one of object must have {@link CollisionFlags#CUSTOM_MATERIAL_CALLBACK} flag set.
 *
 * @author weilichuang
 */
class ContactAddedCallback
{
	public function new()
	{
		
	}

	public function contactAdded(cp:ManifoldPoint, colObj0:CollisionObject, partId0:Int, index0:Int, colObj1:CollisionObject, partId1:Int, index1:Int):Bool
	{
		return false;
	}
	
}