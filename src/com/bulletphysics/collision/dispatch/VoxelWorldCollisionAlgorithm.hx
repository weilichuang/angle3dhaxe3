package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.broadphase.CollisionAlgorithm;
import com.bulletphysics.collision.broadphase.CollisionAlgorithmConstructionInfo;
import com.bulletphysics.collision.broadphase.DispatcherInfo;
import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.dispatch.ManifoldResult;
import com.bulletphysics.collision.narrowphase.PersistentManifold;
import com.bulletphysics.collision.shapes.voxel.VoxelInfo;
import com.bulletphysics.collision.shapes.voxel.VoxelWorldShape;
import com.bulletphysics.linearmath.IntUtil;
import com.bulletphysics.linearmath.Transform;
import de.polygonal.ds.error.Assert;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.Matrix3f;
import vecmath.Matrix4f;
import vecmath.Vector3f;
import vecmath.Vector3i;


/**
 * ...
 * @author weilichuang
 */
class VoxelWorldCollisionAlgorithm extends CollisionAlgorithm
{
	private var blockCollisionInfo:Array<BlockCollisionInfo> = new Array<BlockCollisionInfo>();
    private var isSwapped:Bool;
    private var lastMin:Vector3i = new Vector3i(0, 0, 0);
    private var lastMax:Vector3i = new Vector3i(-1, -1, -1);

    public function init2(ci:CollisionAlgorithmConstructionInfo, body0:CollisionObject, body1:CollisionObject, isSwapped:Bool):Void
	{
        this.dispatcher = ci.dispatcher1;

        this.isSwapped = isSwapped;
    }
	
	override function destroy():Void
	{
		for (info in blockCollisionInfo) 
		{
            if (info.algorithm != null) 
			{
                dispatcher.freeCollisionAlgorithm(info.algorithm);
            }
        }
        blockCollisionInfo = [];
        lastMin.setTo(0, 0, 0);
        lastMax.setTo(-1, -1, -1);
	}
	
	override public function processCollision(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Void 
	{
		var colObj:CollisionObject = isSwapped ? body1 : body0;
        var otherObj:CollisionObject = isSwapped ? body0 : body1;
		
        Assert.assert (colObj.getCollisionShape().getShapeType() == BroadphaseNativeType.VOXEL_WORLD_PROXYTYPE);

        var worldShape:VoxelWorldShape = cast colObj.getCollisionShape();

        var otherObjTransform:Transform = new Transform();
        otherObj.getWorldTransform(otherObjTransform);
        var aabbMin:Vector3f = new Vector3f();
        var aabbMax:Vector3f = new Vector3f();
        otherObj.getCollisionShape().getAabb(otherObjTransform, aabbMin, aabbMax);
        var otherObjMatrix:Matrix4f = new Matrix4f();
        otherObjTransform.getMatrix(otherObjMatrix);
        var otherObjPos:Vector3f = new Vector3f();
        otherObjMatrix.getTranslation(otherObjPos);

        var regionMin:Vector3i = new Vector3i(IntUtil.floorToInt(aabbMin.x + 0.5), 
											IntUtil.floorToInt(aabbMin.y + 0.5), 
											IntUtil.floorToInt(aabbMin.z + 0.5));
        var regionMax:Vector3i = new Vector3i(IntUtil.floorToInt(aabbMax.x + 0.5), 
											IntUtil.floorToInt(aabbMax.y + 0.5), 
											IntUtil.floorToInt(aabbMax.z + 0.5));

        var orgTrans:Transform = new Transform();
        colObj.getWorldTransform(orgTrans);

        var newChildWorldTrans:Transform = new Transform();
        var childMat:Matrix4f = new Matrix4f();

        var rot:Matrix3f = new Matrix3f();
        rot.setIdentity();

        for (x in regionMin.x...(regionMax.x + 1))
		{
            for (y in regionMin.y...(regionMax.y+1)) 
			{
                for (z in regionMin.z...(regionMax.z+1)) 
				{
                    if ((x < lastMin.x || x > lastMax.x) ||
						(y < lastMin.y || y > lastMax.y) ||
						(z < lastMin.z || z > lastMax.z)) 
					{
                        blockCollisionInfo.push(new BlockCollisionInfo(x, y, z));
                    }
                }
            }
        }
		
		var i:Int = 0;
		while(i < blockCollisionInfo.length)
		{
			var info:BlockCollisionInfo = blockCollisionInfo[i];
			// Check still in bounds
            if (info.position.x < regionMin.x || info.position.x > regionMax.x ||
                    info.position.y < regionMin.y || info.position.y > regionMax.y ||
                    info.position.z < regionMin.z || info.position.z > regionMax.z) 
			{
                if (info.algorithm != null) {
                    dispatcher.freeCollisionAlgorithm(info.algorithm);
                }
				blockCollisionInfo.splice(i, 1);
				i--;
            }
			else
			{
                var childInfo:VoxelInfo = worldShape.getWorld().getCollisionShapeAt(info.position.x, info.position.y, info.position.z);
                if (childInfo.isBlocking()) 
				{
                    if (info.algorithm != null && 
						info.blockShape != childInfo.getCollisionShape().getShapeType()) 
					{
                        dispatcher.freeCollisionAlgorithm(info.algorithm);
                        info.algorithm = null;
                    }
                    colObj.internalSetTemporaryCollisionShape(childInfo.getCollisionShape());
                    if (info.algorithm == null)
					{
                        info.algorithm = dispatcher.findAlgorithm(colObj, otherObj);
                        info.blockShape = childInfo.getCollisionShape().getShapeType();
                    }
					
					var cOffset:Vector3f = childInfo.getCollisionOffset();
                    childMat.fromMatrix3fAndTranslation(rot, 
														new Vector3f(info.position.x + cOffset.x, 
																	info.position.y + cOffset.y, 
																	info.position.z + cOffset.z),
														1.0);
                    newChildWorldTrans.fromMatrix4f(childMat);
                    colObj.setWorldTransform(newChildWorldTrans);
                    colObj.setInterpolationWorldTransform(newChildWorldTrans);
                    colObj.setUserPointer(childInfo.getUserData());

                    info.algorithm.processCollision(colObj, otherObj, dispatchInfo, resultOut);

                } 
				else if (info.algorithm != null)
				{
                    dispatcher.freeCollisionAlgorithm(info.algorithm);
                    info.algorithm = null;
                    info.blockShape = BroadphaseNativeType.INVALID_SHAPE_PROXYTYPE;
                }
            }
			
			i++;
		}

        lastMin.fromVector3i(regionMin);
        lastMax.fromVector3i(regionMax);

        colObj.internalSetTemporaryCollisionShape(worldShape);
        colObj.setWorldTransform(orgTrans);
        colObj.setInterpolationWorldTransform(orgTrans);
	}
	
	override public function calculateTimeOfImpact(body0:CollisionObject, body1:CollisionObject, dispatchInfo:DispatcherInfo, resultOut:ManifoldResult):Float 
	{
		// TODO: Implement this? Although not used for discrete dynamics
        /*PerformanceMonitor.startActivity("World Calculate Time Of Impact");
        CollisionObject colObj = isSwapped ? body1 : body0;
        CollisionObject otherObj = isSwapped ? body0 : body1;

        assert (colObj.getCollisionShape().getShapeType() == BroadphaseNativeType.INVALID_SHAPE_PROXYTYPE);

        WorldShape worldShape = (WorldShape) colObj.getCollisionShape();

        Transform otherObjTransform = new Transform();
        Vector3f otherLinearVelocity = new Vector3f();
        Vector3f otherAngularVelocity = new Vector3f();
        otherObj.getInterpolationWorldTransform(otherObjTransform);
        otherObj.getInterpolationLinearVelocity(otherLinearVelocity);
        otherObj.getInterpolationAngularVelocity(otherAngularVelocity);
        Vector3f aabbMin = new Vector3f();
        Vector3f aabbMax = new Vector3f();
        otherObj.getCollisionShape().getAabb(otherObjTransform, aabbMin, aabbMax);

        Region3i region = Region3i.createFromMinMax(new Vector3i(aabbMin, 0.5f), new Vector3i(aabbMax, 0.5f));

        Transform orgTrans = new Transform();
        Transform childTrans = new Transform();
        float hitFraction = 1f;

        Matrix3f rot = new Matrix3f();
        rot.setIdentity();

        for (Vector3i blockPos : region) {
            Block block = worldShape.getWorld().getBlock(blockPos);
            if (block.isPenetrable()) continue;

            // recurse, using each shape within the block.
            CollisionShape childShape = defaultBox;

            // backup
            colObj.getWorldTransform(orgTrans);

            childTrans.set(new Matrix4f(rot, blockPos.toVector3f(), 1.0f));
            colObj.setWorldTransform(childTrans);

            // the contactpoint is still projected back using the original inverted worldtrans
            CollisionShape tmpShape = colObj.getCollisionShape();
            colObj.internalSetTemporaryCollisionShape(childShape);
            colObj.setUserPointer(blockPos);

            CollisionAlgorithm collisionAlg = collisionAlgorithmFactory.dispatcher1.findAlgorithm(colObj, otherObj);
            usedCollisionAlgorithms.add(collisionAlg);
            float frac = collisionAlg.calculateTimeOfImpact(colObj, otherObj, dispatchInfo, resultOut);
            if (frac < hitFraction) {
                hitFraction = frac;
            }

            // revert back
            colObj.internalSetTemporaryCollisionShape(tmpShape);
            colObj.setWorldTransform(orgTrans);
        }
        PerformanceMonitor.endActivity();
        return hitFraction;        */
        return 1.0;
	}
	
	override public function getAllContactManifolds(manifoldArray:ObjectArrayList<PersistentManifold>):Void 
	{
		for (info in blockCollisionInfo) 
		{
            if (info.algorithm != null)
			{
                info.algorithm.getAllContactManifolds(manifoldArray);
            }
        }
	}
}

class BlockCollisionInfo 
{
	public var position:Vector3i;
	public var blockShape:BroadphaseNativeType = BroadphaseNativeType.INVALID_SHAPE_PROXYTYPE;
	public var algorithm:CollisionAlgorithm;

	public function new(x:Int, y:Int, z:Int)
	{
		this.position = new Vector3i(x, y, z);
	}
}