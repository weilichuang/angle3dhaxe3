package com.bulletphysics.collision.broadphase;

/**
 * BroadphasePair class contains a pair of AABB-overlapping objects.
 * {Dispatcher} can search a {CollisionAlgorithm} that performs
 * exact/narrowphase collision detection on the actual collision shapes.
 
 */
class BroadphasePair
{
	public var pProxy0:BroadphaseProxy;
	public var pProxy1:BroadphaseProxy;
	public var algorithm:CollisionAlgorithm;
	public var userInfo:Dynamic;
	
	public function new(pProxy0:BroadphaseProxy, pProxy1:BroadphaseProxy)
	{
		this.pProxy0 = pProxy0;
		this.pProxy1 = pProxy1;
		this.algorithm = null;
		this.userInfo = null;
	}
	
	public function fromBroadphasePair(p:BroadphasePair):Void
	{
		this.pProxy0 = p.pProxy0;
		this.pProxy1 = p.pProxy1;
		this.algorithm = p.algorithm;
		this.userInfo = p.userInfo;
	}
	
	public function equals(p:BroadphasePair):Bool
	{
		return pProxy0 == p.pProxy0 && pProxy1 == p.pProxy1;
	}
	
	public static function broadphasePairSortPredicate(a:BroadphasePair, b:BroadphasePair):Int
	{
		var result:Bool = a.pProxy0.getUid() > b.pProxy0.getUid() ||
                    (a.pProxy0.getUid() == b.pProxy0.getUid() && a.pProxy1.getUid() > b.pProxy1.getUid()) ||
                    (a.pProxy0.getUid() == b.pProxy0.getUid() && a.pProxy1.getUid() == b.pProxy1.getUid() /*&& a.algorithm > b.m_algorithm*/);
		return result ? -1 : 1;
	}
	
}