package com.bulletphysics.collision.dispatch;

import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.broadphase.Dispatcher;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.collision.shapes.TriangleShape;
import com.bulletphysics.linearmath.Transform;
import vecmath.Vector3f;

/**
 * For each triangle in the concave mesh that overlaps with the AABB of a convex
 * (see {@link #convexBody} field), processTriangle is called.
 * @author weilichuang
 */
class ConvexTriangleCallback extends TriangleCallback
{
	private var convexBody:CollisionObject;
    private var triBody:CollisionObject;

    private var aabbMin:Vector3f = new Vector3f();
    private var aabbMax:Vector3f = new Vector3f();

    private var resultOut:ManifoldResult;

    private var dispatcher:Dispatcher;
    private var dispatchInfoPtr:DispatcherInfo;
    private var collisionMarginTriangle:Float;

    public var triangleCount:Int;
    public var manifoldPtr:PersistentManifold;

	public function new(dispatcher:Dispatcher,body0:CollisionObject,body1:CollisionObject,isSwapped:Bool) 
	{
		super();
		
		this.dispatcher = dispatcher;
		this.dispatchInfoPtr = null;
		
		convexBody = isSwapped ? body1 : body0;
        triBody = isSwapped ? body0 : body1;

        //
        // create the manifold from the dispatcher 'manifold pool'
        //
        manifoldPtr = dispatcher.getNewManifold(convexBody, triBody);

        clearCache();
	}
	
	public function destroy():Void
	{
		clearCache();
        dispatcher.releaseManifold(manifoldPtr);
	}
	
	public function setTimeStepAndCounters(collisionMarginTriangle:Float, dispatchInfo:DispatcherInfo,  resultOut:ManifoldResult):Void
	{
        this.dispatchInfoPtr = dispatchInfo;
        this.collisionMarginTriangle = collisionMarginTriangle;
        this.resultOut = resultOut;

        // recalc aabbs
        var convexInTriangleSpace:Transform = new Transform();

        triBody.getWorldTransform(convexInTriangleSpace);
        convexInTriangleSpace.inverse();
        convexInTriangleSpace.mul(convexBody.getWorldTransform(new Transform()));

        var convexShape:CollisionShape = cast convexBody.getCollisionShape();
        //CollisionShape* triangleShape = static_cast<btCollisionShape*>(triBody->m_collisionShape);
        convexShape.getAabb(convexInTriangleSpace, aabbMin, aabbMax);
        var extraMargin:Float = collisionMarginTriangle;
        var extra:Vector3f = new Vector3f();
        extra.setTo(extraMargin, extraMargin, extraMargin);

        aabbMax.add(extra);
        aabbMin.sub(extra);
    }

    private var ci:CollisionAlgorithmConstructionInfo = new CollisionAlgorithmConstructionInfo();
    private var tm:TriangleShape = new TriangleShape(null,null,null);

    override public function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void
	{
        // just for debugging purposes
        //printf("triangle %d",m_triangleCount++);

        // aabb filter is already applied!

        ci.dispatcher1 = dispatcher;

        var ob:CollisionObject = triBody;

        // debug drawing of the overlapping triangles
        if (dispatchInfoPtr != null && dispatchInfoPtr.debugDraw != null && dispatchInfoPtr.debugDraw.getDebugMode() > 0)
		{
            var color:Vector3f = new Vector3f();
            color.setTo(255, 255, 0);
            var tr:Transform = ob.getWorldTransform(new Transform());

            var tmp1:Vector3f = new Vector3f();
            var tmp2:Vector3f = new Vector3f();

            tmp1.fromVector3f(triangle[0]);
            tr.transform(tmp1);
            tmp2.fromVector3f(triangle[1]);
            tr.transform(tmp2);
            dispatchInfoPtr.debugDraw.drawLine(tmp1, tmp2, color);

            tmp1.fromVector3f(triangle[1]);
            tr.transform(tmp1);
            tmp2.fromVector3f(triangle[2]);
            tr.transform(tmp2);
            dispatchInfoPtr.debugDraw.drawLine(tmp1, tmp2, color);

            tmp1.fromVector3f(triangle[2]);
            tr.transform(tmp1);
            tmp2.fromVector3f(triangle[0]);
            tr.transform(tmp2);
            dispatchInfoPtr.debugDraw.drawLine(tmp1, tmp2, color);

            //btVector3 center = triangle[0] + triangle[1]+triangle[2];
            //center *= btScalar(0.333333);
            //m_dispatchInfoPtr->m_debugDraw->drawLine(tr(triangle[0]),tr(center),color);
            //m_dispatchInfoPtr->m_debugDraw->drawLine(tr(triangle[1]),tr(center),color);
            //m_dispatchInfoPtr->m_debugDraw->drawLine(tr(triangle[2]),tr(center),color);
        }

        //btCollisionObject* colObj = static_cast<btCollisionObject*>(m_convexProxy->m_clientObject);

        if (convexBody.getCollisionShape().isConvex()) 
		{
            tm.init(triangle[0], triangle[1], triangle[2]);
            tm.setMargin(collisionMarginTriangle);

            var tmpShape:CollisionShape = ob.getCollisionShape();
            ob.internalSetTemporaryCollisionShape(tm);

            var colAlgo:CollisionAlgorithm = ci.dispatcher1.findAlgorithm(convexBody, triBody, manifoldPtr);
            // this should use the btDispatcher, so the actual registered algorithm is used
            //		btConvexConvexAlgorithm cvxcvxalgo(m_manifoldPtr,ci,m_convexBody,m_triBody);

            resultOut.setShapeIdentifiers(-1, -1, partId, triangleIndex);
            //cvxcvxalgo.setShapeIdentifiers(-1,-1,partId,triangleIndex);
            //cvxcvxalgo.processCollision(m_convexBody,m_triBody,*m_dispatchInfoPtr,m_resultOut);
            colAlgo.processCollision(convexBody, triBody, dispatchInfoPtr, resultOut);
            //colAlgo.destroy();
            ci.dispatcher1.freeCollisionAlgorithm(colAlgo);
            ob.internalSetTemporaryCollisionShape(tmpShape);
        }
    }

    public function clearCache():Void 
	{
        dispatcher.clearManifold(manifoldPtr);
    }

    public function getAabbMin(out:Vector3f):Vector3f 
	{
        out.fromVector3f(aabbMin);
        return out;
    }

    public function getAabbMax(out:Vector3f):Vector3f 
	{
        out.fromVector3f(aabbMax);
        return out;
    }
}