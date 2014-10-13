package com.bulletphysics.extras.gimpact;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.dispatch.CollisionDispatcher;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.ManifoldResult;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.collision.shapes.CompoundShape;
import com.bulletphysics.collision.shapes.ConcaveShape;
import com.bulletphysics.collision.shapes.StaticPlaneShape;
import com.bulletphysics.extras.gimpact.BoxCollision.AABB;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.Vector3f;
import vecmath.Vector4f;

import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.dispatch.CollisionAlgorithmCreateFunc;
import com.bulletphysics.util.ObjectPool;

/**
 * Collision Algorithm for GImpact Shapes.<p>
 * <p/>
 * For register this algorithm in Bullet, proceed as following:
 * <pre>
 * CollisionDispatcher dispatcher = (CollisionDispatcher)dynamicsWorld.getDispatcher();
 * GImpactCollisionAlgorithm.registerAlgorithm(dispatcher);
 * </pre>
 * @author weilichuang
 */
class GImpactCollisionAlgorithm extends CollisionAlgorithm
{

	private var convex_algorithm:CollisionAlgorithm;
    private var manifoldPtr:PersistentManifold;
    private var resultOut:ManifoldResult;
    private var dispatchInfo:DispatcherInfo;
    private var triface0:Int;
    private var part0:Int;
    private var triface1:Int;
    private var part1:Int;

    private var tmpPairset:PairSet = new PairSet();

    public function init(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):Void
	{
        this.setConstructionInfo(ci);
        manifoldPtr = null;
        convex_algorithm = null;
    }
	
	override public function destroy():Void 
	{
		clearCache();
	}

    override public function processCollision(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Void 
	{
		clearCache();

        this.resultOut = resultOut;
        this.dispatchInfo = dispatchInfo;
        var gimpactshape0:GImpactShapeInterface;
        var gimpactshape1:GImpactShapeInterface;

        if (body0.getCollisionShape().getShapeType() == BroadphaseNativeType.GIMPACT_SHAPE_PROXYTYPE)
		{
            gimpactshape0 = cast body0.getCollisionShape();

            if (body1.getCollisionShape().getShapeType() == BroadphaseNativeType.GIMPACT_SHAPE_PROXYTYPE)
			{
                gimpactshape1 = cast body1.getCollisionShape();

                gimpact_vs_gimpact(body0, body1, gimpactshape0, gimpactshape1);
            } 
			else 
			{
                gimpact_vs_shape(body0, body1, gimpactshape0, body1.getCollisionShape(), false);
            }

        } 
		else if (body1.getCollisionShape().getShapeType() == BroadphaseNativeType.GIMPACT_SHAPE_PROXYTYPE)
		{
            gimpactshape1 = cast body1.getCollisionShape();

            gimpact_vs_shape(body1, body0, gimpactshape1, body0.getCollisionShape(), true);
        }
	}

    public function gimpact_vs_gimpact(body0:CollisionObject, body1:CollisionObject, shape0:GImpactShapeInterface, shape1:GImpactShapeInterface):Void
	{
        if (shape0.getGImpactShapeType() == ShapeType.TRIMESH_SHAPE) 
		{
            var meshshape0:GImpactMeshShape = cast shape0;
            part0 = meshshape0.getMeshPartCount();

            while ((part0--) != 0)
			{
                gimpact_vs_gimpact(body0, body1, meshshape0.getMeshPart(part0), shape1);
            }

            return;
        }

        if (shape1.getGImpactShapeType() == ShapeType.TRIMESH_SHAPE)
		{
            var meshshape1:GImpactMeshShape = cast shape1;
            part1 = meshshape1.getMeshPartCount();

            while ((part1--) != 0)
			{
                gimpact_vs_gimpact(body0, body1, shape0, meshshape1.getMeshPart(part1));
            }

            return;
        }

        var orgtrans0:Transform = body0.getWorldTransform(new Transform());
        var orgtrans1:Transform = body1.getWorldTransform(new Transform());

        var pairset:PairSet = tmpPairset;
        pairset.clear();

        gimpact_vs_gimpact_find_pairs(orgtrans0, orgtrans1, shape0, shape1, pairset);

        if (pairset.size() == 0)
		{
            return;
        }
        if (shape0.getGImpactShapeType() == ShapeType.TRIMESH_SHAPE_PART &&
                shape1.getGImpactShapeType() == ShapeType.TRIMESH_SHAPE_PART)
		{

            var shapepart0:GImpactMeshShapePart = cast shape0;
            var shapepart1:GImpactMeshShapePart = cast shape1;

            //specialized function
            //#ifdef BULLET_TRIANGLE_COLLISION
            //collide_gjk_triangles(body0,body1,shapepart0,shapepart1,&pairset[0].m_index1,pairset.size());
            //#else
            collide_sat_triangles(body0, body1, shapepart0, shapepart1, pairset, pairset.size());
            //#endif

            return;
        }

        // general function

        shape0.lockChildShapes();
        shape1.lockChildShapes();

        var retriever0:GIM_ShapeRetriever = new GIM_ShapeRetriever(shape0);
        var retriever1:GIM_ShapeRetriever = new GIM_ShapeRetriever(shape1);

        var child_has_transform0:Bool = shape0.childrenHasTransform();
        var child_has_transform1:Bool = shape1.childrenHasTransform();

        var tmpTrans:Transform = new Transform();

        var i:Int = pairset.size();
        while ((i--) != 0) 
		{
            var pair:Pair = pairset.get(i);
            triface0 = pair.index1;
            triface1 = pair.index2;
            var colshape0:CollisionShape = retriever0.getChildShape(triface0);
            var colshape1:CollisionShape = retriever1.getChildShape(triface1);

            if (child_has_transform0)
			{
                tmpTrans.mul(orgtrans0, shape0.getChildTransform(triface0));
                body0.setWorldTransform(tmpTrans);
            }

            if (child_has_transform1)
			{
                tmpTrans.mul(orgtrans1, shape1.getChildTransform(triface1));
                body1.setWorldTransform(tmpTrans);
            }

            // collide two convex shapes
            convex_vs_convex_collision(body0, body1, colshape0, colshape1);

            if (child_has_transform0) 
			{
                body0.setWorldTransform(orgtrans0);
            }

            if (child_has_transform1)
			{
                body1.setWorldTransform(orgtrans1);
            }

        }

        shape0.unlockChildShapes();
        shape1.unlockChildShapes();
    }

    public function gimpact_vs_shape(body0:CollisionObject, body1:CollisionObject, shape0:GImpactShapeInterface, shape1:CollisionShape, swapped:Bool):Void
	{
        if (shape0.getGImpactShapeType() == ShapeType.TRIMESH_SHAPE) 
		{
            var meshshape0:GImpactMeshShape = cast shape0;
            part0 = meshshape0.getMeshPartCount();

            while ((part0--) != 0)
			{
                gimpact_vs_shape(body0,
                        body1,
                        meshshape0.getMeshPart(part0),
                        shape1, swapped);
            }

            return;
        }

        //#ifdef GIMPACT_VS_PLANE_COLLISION
        if (shape0.getGImpactShapeType() == ShapeType.TRIMESH_SHAPE_PART &&
                shape1.getShapeType() == BroadphaseNativeType.STATIC_PLANE_PROXYTYPE)
		{
            var shapepart:GImpactMeshShapePart = cast shape0;
            var planeshape:StaticPlaneShape = cast shape1;
            gimpacttrimeshpart_vs_plane_collision(body0, body1, shapepart, planeshape, swapped);
            return;
        }
        //#endif

        if (shape1.isCompound()) 
		{
            var compoundshape:CompoundShape =  cast shape1;
            gimpact_vs_compoundshape(body0, body1, shape0, compoundshape, swapped);
            return;
        } 
		else if (shape1.isConcave())
		{
            var concaveshape:ConcaveShape = cast shape1;
            gimpact_vs_concave(body0, body1, shape0, concaveshape, swapped);
            return;
        }

        var orgtrans0:Transform = body0.getWorldTransform(new Transform());
        var orgtrans1:Transform = body1.getWorldTransform(new Transform());

        var collided_results:IntArrayList = new IntArrayList();

        gimpact_vs_shape_find_pairs(orgtrans0, orgtrans1, shape0, shape1, collided_results);

        if (collided_results.size() == 0)
		{
            return;
        }
        shape0.lockChildShapes();

        var retriever0:GIM_ShapeRetriever = new GIM_ShapeRetriever(shape0);

        var child_has_transform0:Bool = shape0.childrenHasTransform();

        var tmpTrans:Transform = new Transform();

        var i:Int = collided_results.size();

        while ((i--) != 0)
		{
            var child_index:Int = collided_results.get(i);
            if (swapped)
			{
                triface1 = child_index;
            } 
			else 
			{
                triface0 = child_index;
            }
            var colshape0:CollisionShape = retriever0.getChildShape(child_index);

            if (child_has_transform0)
			{
                tmpTrans.mul(orgtrans0, shape0.getChildTransform(child_index));
                body0.setWorldTransform(tmpTrans);
            }

            // collide two shapes
            if (swapped)
			{
                shape_vs_shape_collision(body1, body0, shape1, colshape0);
            } 
			else 
			{
                shape_vs_shape_collision(body0, body1, colshape0, shape1);
            }

            // restore transforms
            if (child_has_transform0)
			{
                body0.setWorldTransform(orgtrans0);
            }

        }

        shape0.unlockChildShapes();
    }

    public function gimpact_vs_compoundshape(body0:CollisionObject, body1:CollisionObject, shape0:GImpactShapeInterface, shape1:CompoundShape, swapped:Bool):Void
	{
        var orgtrans1:Transform = body1.getWorldTransform(new Transform());
        var childtrans1:Transform = new Transform();
        var tmpTrans:Transform = new Transform();

        var i:Int = shape1.getNumChildShapes();
        while ((i--) != 0)
		{
            var colshape1:CollisionShape = shape1.getChildShape(i);
            childtrans1.mul(orgtrans1, shape1.getChildTransform(i, tmpTrans));

            body1.setWorldTransform(childtrans1);

            // collide child shape
            gimpact_vs_shape(body0, body1,
                    shape0, colshape1, swapped);

            // restore transforms
            body1.setWorldTransform(orgtrans1);
        }
    }

    public function gimpact_vs_concave(body0:CollisionObject, body1:CollisionObject, shape0:GImpactShapeInterface, shape1:ConcaveShape, swapped:Bool):Void
	{
        // create the callback
        var tricallback:GImpactTriangleCallback = new GImpactTriangleCallback();
        tricallback.algorithm = this;
        tricallback.body0 = body0;
        tricallback.body1 = body1;
        tricallback.gimpactshape0 = shape0;
        tricallback.swapped = swapped;
        tricallback.margin = shape1.getMargin();

        // getting the trimesh AABB
        var gimpactInConcaveSpace:Transform = new Transform();

        body1.getWorldTransform(gimpactInConcaveSpace);
        gimpactInConcaveSpace.inverse();
        gimpactInConcaveSpace.mul(body0.getWorldTransform(new Transform()));

        var minAABB:Vector3f = new Vector3f();
		var maxAABB:Vector3f = new Vector3f();
        shape0.getAabb(gimpactInConcaveSpace, minAABB, maxAABB);

        shape1.processAllTriangles(tricallback, minAABB, maxAABB);
    }

    /**
     * Creates a new contact point.
     */
    private function newContactManifold(body0:CollisionObject, body1:CollisionObject):PersistentManifold 
	{
        manifoldPtr = dispatcher.getNewManifold(body0, body1);
        return manifoldPtr;
    }

    private function destroyConvexAlgorithm():Void
	{
        if (convex_algorithm != null) 
		{
            //convex_algorithm.destroy();
            dispatcher.freeCollisionAlgorithm(convex_algorithm);
            convex_algorithm = null;
        }
    }

    private function destroyContactManifolds():Void
	{
        if (manifoldPtr == null) return;
        dispatcher.releaseManifold(manifoldPtr);
        manifoldPtr = null;
    }

    private function clearCache():Void
	{
        destroyContactManifolds();
        destroyConvexAlgorithm();

        triface0 = -1;
        part0 = -1;
        triface1 = -1;
        part1 = -1;
    }

    private function getLastManifold():PersistentManifold
	{
        return manifoldPtr;
    }

    /**
     * Call before process collision.
     */
    private function checkManifold(body0:CollisionObject, body1:CollisionObject):Void
	{
        if (getLastManifold() == null)
		{
            newContactManifold(body0, body1);
        }

        resultOut.setPersistentManifold(getLastManifold());
    }

    /**
     * Call before process collision.
     */
    private function newAlgorithm(body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm
	{
        checkManifold(body0, body1);

        var convex_algorithm:CollisionAlgorithm = dispatcher.findAlgorithm(body0, body1, getLastManifold());
        return convex_algorithm;
    }

    /**
     * Call before process collision.
     */
    private function checkConvexAlgorithm(body0:CollisionObject, body1:CollisionObject):Void
	{
        if (convex_algorithm != null) return;
        convex_algorithm = newAlgorithm(body0, body1);
    }

    private function addContactPoint(body0:CollisionObject, body1:CollisionObject, point:Vector3f, normal:Vector3f, distance:Float):Void
	{
        resultOut.setShapeIdentifiers(part0, triface0, part1, triface1);
        checkManifold(body0, body1);
        resultOut.addContactPoint(normal, point, distance);
    }

	/*
    private void collide_gjk_triangles(CollisionObject body0, CollisionObject body1, GImpactMeshShapePart shape0, GImpactMeshShapePart shape1, IntArrayList pairs, int pair_count) {
	}
	*/

    public function collide_sat_triangles(body0:CollisionObject, body1:CollisionObject, shape0:GImpactMeshShapePart, shape1:GImpactMeshShapePart, pairs:PairSet, pair_count:Int):Void
	{
        var tmp:Vector3f = new Vector3f();

        var orgtrans0:Transform = body0.getWorldTransform(new Transform());
        var orgtrans1:Transform = body1.getWorldTransform(new Transform());

        var ptri0:PrimitiveTriangle = new PrimitiveTriangle();
        var ptri1:PrimitiveTriangle = new PrimitiveTriangle();
        var contact_data:TriangleContact = new TriangleContact();

        shape0.lockChildShapes();
        shape1.lockChildShapes();

        var pair_pointer:Int = 0;

        while ((pair_count--) != 0) 
		{
            //triface0 = pairs.get(pair_pointer);
            //triface1 = pairs.get(pair_pointer + 1);
            //pair_pointer += 2;
            var pair:Pair = pairs.get(pair_pointer++);
            triface0 = pair.index1;
            triface1 = pair.index2;

            shape0.getPrimitiveTriangle(triface0, ptri0);
            shape1.getPrimitiveTriangle(triface1, ptri1);

            //#ifdef TRI_COLLISION_PROFILING
            //bt_begin_gim02_tri_time();
            //#endif

            ptri0.applyTransform(orgtrans0);
            ptri1.applyTransform(orgtrans1);

            // build planes
            ptri0.buildTriPlane();
            ptri1.buildTriPlane();

            // test conservative
            if (ptri0.overlap_test_conservative(ptri1)) 
			{
                if (ptri0.find_triangle_collision_clip_method(ptri1, contact_data)) 
				{

                    var j:Int = contact_data.point_count;
                    while ((j--) != 0) 
					{
                        tmp.x = contact_data.separating_normal.x;
                        tmp.y = contact_data.separating_normal.y;
                        tmp.z = contact_data.separating_normal.z;

                        addContactPoint(body0, body1,
                                contact_data.points[j],
                                tmp,
                                -contact_data.penetration_depth);
                    }
                }
            }

            //#ifdef TRI_COLLISION_PROFILING
            //bt_end_gim02_tri_time();
            //#endif
        }

        shape0.unlockChildShapes();
        shape1.unlockChildShapes();
    }

    private function shape_vs_shape_collision(body0:CollisionObject, body1:CollisionObject, shape0:CollisionShape, shape1:CollisionShape):Void
	{
        var tmpShape0:CollisionShape = body0.getCollisionShape();
        var tmpShape1:CollisionShape = body1.getCollisionShape();

        body0.internalSetTemporaryCollisionShape(shape0);
        body1.internalSetTemporaryCollisionShape(shape1);

        {
            var algor:CollisionAlgorithm = newAlgorithm(body0, body1);
            // post :	checkManifold is called

            resultOut.setShapeIdentifiers(part0, triface0, part1, triface1);

            algor.processCollision(body0, body1, dispatchInfo, resultOut);

            //algor.destroy();
            dispatcher.freeCollisionAlgorithm(algor);
        }

        body0.internalSetTemporaryCollisionShape(tmpShape0);
        body1.internalSetTemporaryCollisionShape(tmpShape1);
    }

    private function convex_vs_convex_collision(body0:CollisionObject, body1:CollisionObject, shape0:CollisionShape, shape1:CollisionShape):Void
	{
        var tmpShape0:CollisionShape = body0.getCollisionShape();
        var tmpShape1:CollisionShape = body1.getCollisionShape();

        body0.internalSetTemporaryCollisionShape(shape0);
        body1.internalSetTemporaryCollisionShape(shape1);

        resultOut.setShapeIdentifiers(part0, triface0, part1, triface1);

        checkConvexAlgorithm(body0, body1);
        convex_algorithm.processCollision(body0, body1, dispatchInfo, resultOut);

        body0.internalSetTemporaryCollisionShape(tmpShape0);
        body1.internalSetTemporaryCollisionShape(tmpShape1);
    }

    private function gimpact_vs_gimpact_find_pairs(trans0:Transform, trans1:Transform, 
												 shape0:GImpactShapeInterface, shape1:GImpactShapeInterface, pairset:PairSet):Void
	{
        if (shape0.hasBoxSet() && shape1.hasBoxSet())
		{
            GImpactBvh.find_collision(shape0.getBoxSet(), trans0, shape1.getBoxSet(), trans1, pairset);
        } 
		else 
		{
            var boxshape0:AABB = new AABB();
            var boxshape1:AABB = new AABB();
            var i:Int = shape0.getNumChildShapes();

            while ((i--) != 0)
			{
                shape0.getChildAabb(i, trans0, boxshape0.min, boxshape0.max);

                var j:Int = shape1.getNumChildShapes();
                while ((j--) != 0)
				{
                    shape1.getChildAabb(i, trans1, boxshape1.min, boxshape1.max);

                    if (boxshape1.has_collision(boxshape0)) 
					{
                        pairset.push_pair(i, j);
                    }
                }
            }
        }
    }

    private function gimpact_vs_shape_find_pairs(trans0:Transform, trans1:Transform, 
												 shape0:GImpactShapeInterface, shape1:CollisionShape, collided_primitives:IntArrayList):Void
	{
        var boxshape:AABB = new AABB();

        if (shape0.hasBoxSet()) 
		{
            var trans1to0:Transform = new Transform();
            trans1to0.inverse(trans0);
            trans1to0.mul(trans1);

            shape1.getAabb(trans1to0, boxshape.min, boxshape.max);

            shape0.getBoxSet().boxQuery(boxshape, collided_primitives);
        } 
		else
		{
            shape1.getAabb(trans1, boxshape.min, boxshape.max);

            var boxshape0:AABB = new AABB();
            var i:Int = shape0.getNumChildShapes();

            while ((i--) != 0)
			{
                shape0.getChildAabb(i, trans0, boxshape0.min, boxshape0.max);

                if (boxshape.has_collision(boxshape0))
				{
                    collided_primitives.add(i);
                }
            }
        }
    }

    private function gimpacttrimeshpart_vs_plane_collision(body0:CollisionObject, body1:CollisionObject, 
												 shape0:GImpactMeshShapePart, shape1:StaticPlaneShape, swapped:Bool):Void
	{
        var orgtrans0:Transform = body0.getWorldTransform(new Transform());
        var orgtrans1:Transform = body1.getWorldTransform(new Transform());

        var planeshape:StaticPlaneShape = shape1;
        var plane:Vector4f = new Vector4f();
        PlaneShape.get_plane_equation_transformed(planeshape, orgtrans1, plane);

        // test box against plane

        var tribox:AABB = new AABB();
        shape0.getAabb(orgtrans0, tribox.min, tribox.max);
        tribox.increment_margin(planeshape.getMargin());

        if (tribox.plane_classify(plane) != PlaneIntersectionType.COLLIDE_PLANE)
		{
            return;
        }
        shape0.lockChildShapes();

        var margin:Float = shape0.getMargin() + planeshape.getMargin();

        var vertex:Vector3f = new Vector3f();

        var tmp:Vector3f = new Vector3f();

        var vi:Int = shape0.getVertexCount();
        while ((vi--) != 0) 
		{
            shape0.getVertex(vi, vertex);
            orgtrans0.transform(vertex);

            var distance:Float = VectorUtil.dot3(vertex, plane) - plane.w - margin;

            if (distance < 0)//add contact
            {
                if (swapped)
				{
                    tmp.setTo(-plane.x, -plane.y, -plane.z);
                    addContactPoint(body1, body0, vertex, tmp, distance);
                } 
				else
				{
                    tmp.setTo(plane.x, plane.y, plane.z);
                    addContactPoint(body0, body1, vertex, tmp, distance);
                }
            }
        }

        shape0.unlockChildShapes();
    }


    public function setFace0(value:Int):Void
	{
        triface0 = value;
    }

    public function getFace0():Int
	{
        return triface0;
    }

    public function setFace1(value:Int):Void
	{
        triface1 = value;
    }

    public function getFace1():Int
	{
        return triface1;
    }

    public function setPart0(value:Int):Void
	{
        part0 = value;
    }

    public function getPart0():Int
	{
        return part0;
    }

    public function setPart1(value:Int):Void
	{
        part1 = value;
    }

    public function getPart1():Int
	{
        return part1;
    }
	
	override public function calculateTimeOfImpact(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Float 
	{
		return 1;
	}

    override public function getAllContactManifolds(manifoldArray:ObjectArrayList<PersistentManifold>):Void 
	{
		if (manifoldPtr != null) 
		{
            manifoldArray.add(manifoldPtr);
        }
	}

    /**
     * Use this function for register the algorithm externally.
     */
    public static function registerAlgorithm(dispatcher:CollisionDispatcher):Void
	{
        var createFunc:CreateFunc = new CreateFunc();

		var gimpactIndex:Int = Type.enumIndex(BroadphaseNativeType.GIMPACT_SHAPE_PROXYTYPE);
		var count = Type.enumIndex(BroadphaseNativeType.MAX_BROADPHASE_COLLISION_TYPES);
        for (i in 0...count)
		{
            dispatcher.registerCollisionCreateFunc(gimpactIndex, i, createFunc);
        }

        for (i in 0...count)
		{
            dispatcher.registerCollisionCreateFunc(i, gimpactIndex, createFunc);
        }
    }
}

class CreateFunc extends CollisionAlgorithmCreateFunc 
{
	private var pool:ObjectPool<GImpactCollisionAlgorithm> = ObjectPool.getPool(GImpactCollisionAlgorithm);

	override public function createCollisionAlgorithm(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject):CollisionAlgorithm 
	{
		var algo:GImpactCollisionAlgorithm = pool.get();
		algo.init(ci, body0, body1);
		return algo;
	}
	
	override public function releaseCollisionAlgorithm(algo:CollisionAlgorithm):Void 
	{
		pool.release(cast algo);
	}
}