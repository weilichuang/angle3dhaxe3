package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.dispatch.ManifoldResult;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.util.ObjectArrayList;

import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.dispatch.CollisionObject;

/**
 * Empty algorithm, used as fallback when no collision algorithm is found for given
 * shape type pair.
 * @author weilichuang
 */
class EmptyAlgorithm extends CollisionAlgorithm
{
	public static var INSTANCE:EmptyAlgorithm = new EmptyAlgorithm();
	
	public function new() 
	{
		super();
	}
	
	override public function destroy():Void 
	{
		
	}
	
	override public function processCollision(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Void 
	{
		
	}
	
	override public function calculateTimeOfImpact(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Float 
	{
		return 1;
	}
	
	override public function getAllContactManifolds(manifoldArray:ObjectArrayList<PersistentManifold>):Void 
	{
		
	}
	
}