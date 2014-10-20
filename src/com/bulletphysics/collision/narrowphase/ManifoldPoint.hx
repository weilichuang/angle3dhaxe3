package com.bulletphysics.collision.narrowphase;
import vecmath.Vector3f;

/**
 * ManifoldPoint collects and maintains persistent contactpoints. Used to improve
 * stability and performance of rigidbody dynamics response.
 * 
 * @author weilichuang
 */
class ManifoldPoint
{

	public var localPointA:Vector3f = new Vector3f();
    public var localPointB:Vector3f = new Vector3f();
    public var positionWorldOnB:Vector3f = new Vector3f();
    ///m_positionWorldOnA is redundant information, see getPositionWorldOnA(), but for clarity
    public var positionWorldOnA:Vector3f = new Vector3f();
    public var normalWorldOnB:Vector3f = new Vector3f();

    public var distance1:Float;
    public var combinedFriction:Float;
    public var combinedRestitution:Float;

    // BP mod, store contact triangles.
    public var partId0:Int;
    public var partId1:Int;
    public var index0:Int;
    public var index1:Int;

    public var userPersistentData:Dynamic;
    public var appliedImpulse:Float;

    public var lateralFrictionInitialized:Bool;
    public var appliedImpulseLateral1:Float;
    public var appliedImpulseLateral2:Float;
    public var lifeTime:Int; //lifetime of the contactpoint in frames

    public var lateralFrictionDir1:Vector3f = new Vector3f();
    public var lateralFrictionDir2:Vector3f = new Vector3f();

    public function new()
	{
		this.userPersistentData = null;
        this.appliedImpulse = 0;
        this.lateralFrictionInitialized = false;
        this.lifeTime = 0;
    }

    public function init(pointA:Vector3f, pointB:Vector3f, normal:Vector3f, distance:Float):Void
	{
        this.localPointA.fromVector3f(pointA);
        this.localPointB.fromVector3f(pointB);
        this.normalWorldOnB.fromVector3f(normal);
        this.distance1 = distance;
        this.combinedFriction = 0;
        this.combinedRestitution = 0;
        this.userPersistentData = null;
        this.appliedImpulse = 0;
        this.lateralFrictionInitialized = false;
        this.appliedImpulseLateral1 = 0;
        this.appliedImpulseLateral2 = 0;
        this.lifeTime = 0;
    }

    public inline function getDistance():Float
	{
        return distance1;
    }

    public inline function getLifeTime():Int
	{
        return lifeTime;
    }

    public function set(p:ManifoldPoint):Void
	{
        localPointA.fromVector3f(p.localPointA);
        localPointB.fromVector3f(p.localPointB);
        positionWorldOnA.fromVector3f(p.positionWorldOnA);
        positionWorldOnB.fromVector3f(p.positionWorldOnB);
        normalWorldOnB.fromVector3f(p.normalWorldOnB);
        distance1 = p.distance1;
        combinedFriction = p.combinedFriction;
        combinedRestitution = p.combinedRestitution;
        partId0 = p.partId0;
        partId1 = p.partId1;
        index0 = p.index0;
        index1 = p.index1;
        userPersistentData = p.userPersistentData;
        appliedImpulse = p.appliedImpulse;
        lateralFrictionInitialized = p.lateralFrictionInitialized;
        appliedImpulseLateral1 = p.appliedImpulseLateral1;
        appliedImpulseLateral2 = p.appliedImpulseLateral2;
        lifeTime = p.lifeTime;
        lateralFrictionDir1.fromVector3f(p.lateralFrictionDir1);
        lateralFrictionDir2.fromVector3f(p.lateralFrictionDir2);
    }

    public inline function getPositionWorldOnA(out:Vector3f):Vector3f
	{
        out.fromVector3f(positionWorldOnA);
        return out;
        //return m_positionWorldOnB + m_normalWorldOnB * m_distance1;
    }

    public inline function getPositionWorldOnB(out:Vector3f):Vector3f
	{
        out.fromVector3f(positionWorldOnB);
        return out;
    }

    public inline function setDistance(dist:Float):Void
	{
        distance1 = dist;
    }
	
}