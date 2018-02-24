package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.ManifoldResult;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.collision.shapes.CollisionShape;
import com.bulletphysics.collision.shapes.CompoundShape;
import com.bulletphysics.linearmath.Transform;
import angle3d.error.Assert;
import com.bulletphysics.util.ObjectArrayList;


/**
 * ...
 
 */
class CompoundCollisionAlgorithm extends CollisionAlgorithm
{

	public function new() 
	{
		super();
		
	}
	
	private var childCollisionAlgorithms:ObjectArrayList<CollisionAlgorithm> = new ObjectArrayList<CollisionAlgorithm>();
    private var isSwapped:Bool;

    public function init(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject, isSwapped:Bool)
	{
        setConstructionInfo(ci);

        this.isSwapped = isSwapped;

        var colObj:CollisionObject = isSwapped ? body1 : body0;
        var otherObj:CollisionObject = isSwapped ? body0 : body1;
		
		#if debug
        Assert.assert (colObj.getCollisionShape().isCompound());
		#end

        var compoundShape:CompoundShape = cast colObj.getCollisionShape();
        var numChildren:Int = compoundShape.getNumChildShapes();

        //childCollisionAlgorithms.resize(numChildren);
        for (i in 0...numChildren)
		{
            var tmpShape:CollisionShape = colObj.getCollisionShape();
            var childShape:CollisionShape = compoundShape.getChildShape(i);
            colObj.internalSetTemporaryCollisionShape(childShape);
            childCollisionAlgorithms.add(ci.dispatcher1.findAlgorithm(colObj, otherObj));
            colObj.internalSetTemporaryCollisionShape(tmpShape);
        }
    }
	
	override public function destroy():Void 
	{
		var numChildren:Int = childCollisionAlgorithms.size();
        for (i in 0...numChildren) 
		{
            dispatcher.freeCollisionAlgorithm(childCollisionAlgorithms.getQuick(i));
        }
        childCollisionAlgorithms.clear();
	}
	
	var tmpTrans:Transform = new Transform();
	var orgTrans:Transform = new Transform();
	var childTrans:Transform = new Transform();
	var orgInterpolationTrans:Transform = new Transform();
	var newChildWorldTrans:Transform = new Transform();
	override public function processCollision(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Void 
	{
		var colObj:CollisionObject = isSwapped ? body1 : body0;
        var otherObj:CollisionObject = isSwapped ? body0 : body1;

		#if debug
        Assert.assert (colObj.getCollisionShape().isCompound());
		#end
		
        var compoundShape:CompoundShape = cast colObj.getCollisionShape();

        // We will use the OptimizedBVH, AABB tree to cull potential child-overlaps
        // If both proxies are Compound, we will deal with that directly, by performing sequential/parallel tree traversals
        // given Proxy0 and Proxy1, if both have a tree, Tree0 and Tree1, this means:
        // determine overlapping nodes of Proxy1 using Proxy0 AABB against Tree1
        // then use each overlapping node AABB against Tree0
        // and vise versa.

        var numChildren:Int = childCollisionAlgorithms.size();
        for (i in 0...numChildren)
		{
            // temporarily exchange parent btCollisionShape with childShape, and recurse
            var childShape:CollisionShape = compoundShape.getChildShape(i);

            // backup
            colObj.getWorldTransformTo(orgTrans);
            colObj.getInterpolationWorldTransformTo(orgInterpolationTrans);

            compoundShape.getChildTransform(i, childTrans);
            newChildWorldTrans.mul2(orgTrans, childTrans);
            colObj.setWorldTransform(newChildWorldTrans);
            colObj.setInterpolationWorldTransform(newChildWorldTrans);

            // the contactpoint is still projected back using the original inverted worldtrans
            var tmpShape:CollisionShape = colObj.getCollisionShape();
            colObj.internalSetTemporaryCollisionShape(childShape);
            childCollisionAlgorithms.getQuick(i).processCollision(colObj, otherObj, dispatchInfo, resultOut);
            // revert back
            colObj.internalSetTemporaryCollisionShape(tmpShape);
            colObj.setWorldTransform(orgTrans);
            colObj.setInterpolationWorldTransform(orgInterpolationTrans);
        }
	}
	
	override public function calculateTimeOfImpact(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Float 
	{
		var colObj:CollisionObject = isSwapped ? body1 : body0;
        var otherObj:CollisionObject = isSwapped ? body0 : body1;

		#if debug
        Assert.assert (colObj.getCollisionShape().isCompound());
		#end

        var compoundShape:CompoundShape = cast colObj.getCollisionShape();

        // We will use the OptimizedBVH, AABB tree to cull potential child-overlaps
        // If both proxies are Compound, we will deal with that directly, by performing sequential/parallel tree traversals
        // given Proxy0 and Proxy1, if both have a tree, Tree0 and Tree1, this means:
        // determine overlapping nodes of Proxy1 using Proxy0 AABB against Tree1
        // then use each overlapping node AABB against Tree0
        // and vise versa.

        var hitFraction:Float = 1;

        var numChildren:Int = childCollisionAlgorithms.size();
        for (i in 0...numChildren)
		{
            // temporarily exchange parent btCollisionShape with childShape, and recurse
            var childShape:CollisionShape = compoundShape.getChildShape(i);

            // backup
            colObj.getWorldTransformTo(orgTrans);

            compoundShape.getChildTransform(i, childTrans);
            //btTransform	newChildWorldTrans = orgTrans*childTrans ;
            tmpTrans.fromTransform(orgTrans);
            tmpTrans.mul(childTrans);
            colObj.setWorldTransform(tmpTrans);

            var tmpShape:CollisionShape = colObj.getCollisionShape();
            colObj.internalSetTemporaryCollisionShape(childShape);
            var frac:Float = childCollisionAlgorithms.getQuick(i).calculateTimeOfImpact(colObj, otherObj, dispatchInfo, resultOut);
            if (frac < hitFraction)
			{
                hitFraction = frac;
            }
            // revert back
            colObj.internalSetTemporaryCollisionShape(tmpShape);
            colObj.setWorldTransform(orgTrans);
        }
        return hitFraction;
	}

	override public function getAllContactManifolds(manifoldArray:ObjectArrayList<PersistentManifold>):Void 
	{
		for (i in 0...childCollisionAlgorithms.size()) 
		{
            childCollisionAlgorithms.getQuick(i).getAllContactManifolds(manifoldArray);
        }
	}
}
