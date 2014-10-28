package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.MatrixUtil;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.Matrix3f;
import vecmath.Vector3f;

/**
 * CompoundShape allows to store multiple other {@link CollisionShape}s. This allows
 * for moving concave collision objects. This is more general than the {@link BvhTriangleMeshShape}.
 * @author weilichuang
 */
class CompoundShape extends CollisionShape
{
	private var children:ObjectArrayList<CompoundShapeChild> = new ObjectArrayList<CompoundShapeChild>();
	private var localAabbMin:Vector3f = new Vector3f(1e30, 1e30, 1e30);
	private var localAabbMax:Vector3f = new Vector3f( -1e30, -1e30, -1e30);
	
	private var aabbTree:OptimizedBvh = null;
	
	private var collisionMargin:Float = 0;
	
	private var localScaling:Vector3f = new Vector3f(1, 1, 1);

	public function new() 
	{
		super();	
	}
	
	public function addChildShape(localTransform:Transform, shape:CollisionShape):Void
	{
		var child:CompoundShapeChild = new CompoundShapeChild();
		child.transform.fromTransform(localTransform);
		child.childShape = shape;
		child.childShapeType = shape.getShapeType();
		child.childMargin = shape.getMargin();
		
		children.add(child);
		
		var _localAabbMin:Vector3f = new Vector3f();
		var _localAabbMax:Vector3f = new Vector3f();
		
		shape.getAabb(localTransform, _localAabbMin, _localAabbMax);
		VectorUtil.setMin(this.localAabbMin, _localAabbMin);
        VectorUtil.setMax(this.localAabbMax, _localAabbMax);
	}
	
	/**
     * Remove all children shapes that contain the specified shape.
     */
	public function removeChildShape(shape:CollisionShape):Void
	{
		var done_removing:Bool;
		
		// Find the children containing the shape specified, and remove those children.
		do
		{
			done_removing = true;
			
			for (i in 0...children.size())
			{
				if (children.getQuick(i).childShape == shape)
				{
					children.removeQuick(i);
					done_removing = false;// Do another iteration pass after removing from the vector
					break;
				}
			}
		}
		while (!done_removing);
		
		recalculateLocalAabb();
	}
	
	public function getNumChildShapes():Int
	{
		return children.size();
	}
	
	public function getChildShape(index:Int):CollisionShape
	{
		return children.getQuick(index).childShape;
	}
	
	public function getChildTransform(index:Int, out:Transform):Transform
	{
		out.fromTransform(children.getQuick(index).transform);
		return out;
	}
	
	public function getChildList():ObjectArrayList<CompoundShapeChild>
	{
		return children;
	}
	
	/**
     * getAabb's default implementation is brute force, expected derived classes to implement a fast dedicated version.
     */
	var tmpHalfExtents:Vector3f = new Vector3f();
	var localCenter:Vector3f = new Vector3f();
	var abs_b:Matrix3f = new Matrix3f();
	var center:Vector3f = new Vector3f();
	var tmp:Vector3f = new Vector3f();
	var extent:Vector3f = new Vector3f();
	override public function getAabb(trans:Transform, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
		var margin:Float = getMargin();
		
        tmpHalfExtents.sub2(localAabbMax, localAabbMin);
        tmpHalfExtents.scale(0.5);
        tmpHalfExtents.x += margin;
        tmpHalfExtents.y += margin;
        tmpHalfExtents.z += margin;

        
        localCenter.add2(localAabbMax, localAabbMin);
        localCenter.scale(0.5);

        abs_b.fromMatrix3f(trans.basis);
        MatrixUtil.absolute(abs_b);

        center.fromVector3f(localCenter);
        trans.transform(center);

        abs_b.getRow(0, tmp);
        extent.x = tmp.dot(tmpHalfExtents);
        abs_b.getRow(1, tmp);
        extent.y = tmp.dot(tmpHalfExtents);
        abs_b.getRow(2, tmp);
        extent.z = tmp.dot(tmpHalfExtents);

        aabbMin.sub2(center, extent);
        aabbMax.add2(center, extent);
	}
	
	/**
     * Re-calculate the local Aabb. Is called at the end of removeChildShapes.
     * Use this yourself if you modify the children or their transforms.
     */
	private var tmpAabbMin:Vector3f = new Vector3f();
	private var tmpAabbMax:Vector3f = new Vector3f();
    public function recalculateLocalAabb():Void
	{
		// Recalculate the local aabb
        // Brute force, it iterates over all the shapes left.
        localAabbMin.setTo(1e30, 1e30, 1e30);
        localAabbMax.setTo(-1e30, -1e30, -1e30);

        // extend the local aabbMin/aabbMax
        for (j in 0...children.size()) 
		{
            children.getQuick(j).childShape.getAabb(children.getQuick(j).transform, tmpAabbMin, tmpAabbMax);

            //for (i in 0...3)
			//{
                //if (VectorUtil.getCoord(localAabbMin, i) > VectorUtil.getCoord(tmpLocalAabbMin, i))
				//{
                    //VectorUtil.setCoord(localAabbMin, i, VectorUtil.getCoord(tmpLocalAabbMin, i));
                //}
                //if (VectorUtil.getCoord(localAabbMax, i) < VectorUtil.getCoord(tmpLocalAabbMax, i))
				//{
                    //VectorUtil.setCoord(localAabbMax, i, VectorUtil.getCoord(tmpLocalAabbMax, i));
                //}
            //}
			
			//x
			if (localAabbMin.x > tmpAabbMin.x)
				localAabbMin.x = tmpAabbMin.x;
				
			if (localAabbMax.x < tmpAabbMax.x)
				localAabbMax.x = tmpAabbMax.x;
			
			//y
			if (localAabbMin.y > tmpAabbMin.y)
				localAabbMin.y = tmpAabbMin.y;
				
			if (localAabbMax.y < tmpAabbMax.y)
				localAabbMax.y = tmpAabbMax.y;
			
			//z
			if (localAabbMin.z > tmpAabbMin.z)
				localAabbMin.z = tmpAabbMin.z;
				
			if (localAabbMax.z < tmpAabbMax.z)
				localAabbMax.z = tmpAabbMax.z;
        }
	}
	
	override public function setLocalScaling(scaling:Vector3f):Void 
	{
		localScaling.fromVector3f(scaling);
	}
	
	override public function getLocalScaling(out:Vector3f):Vector3f 
	{
		out.fromVector3f(localScaling);
		return out;
	}
	
	var ident:Transform = new Transform();
	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		// approximation: take the inertia from the aabb for now
        
        ident.setIdentity();
        getAabb(ident, tmpAabbMin, tmpAabbMax);

        tmpHalfExtents.sub2(tmpAabbMax, tmpAabbMin);
        tmpHalfExtents.scale(0.5);

        var lx:Float = 2 * tmpHalfExtents.x;
        var ly:Float = 2 * tmpHalfExtents.y;
        var lz:Float = 2 * tmpHalfExtents.z;
		
		var m12:Float = mass / 12;

        inertia.x = m12 * (ly * ly + lz * lz);
        inertia.y = m12 * (lx * lx + lz * lz);
        inertia.z = m12 * (lx * lx + ly * ly);
	}
	
	override public function getShapeType():BroadphaseNativeType 
	{
		return BroadphaseNativeType.COMPOUND_SHAPE_PROXYTYPE;
	}
	
	override public function setMargin(margin:Float):Void 
	{
		collisionMargin = margin;
	}
	
	override public function getMargin():Float 
	{
		return collisionMargin;
	}
	
	override public function getName():String 
	{
		return "Compound";
	}
	
	public function getAabbTree():OptimizedBvh
	{
		return aabbTree;
	}
	
	/**
     * Computes the exact moment of inertia and the transform from the coordinate
     * system defined by the principal axes of the moment of inertia and the center
     * of mass to the current coordinate system. "masses" points to an array
     * of masses of the children. The resulting transform "principal" has to be
     * applied inversely to all children transforms in order for the local coordinate
     * system of the compound shape to be centered at the center of mass and to coincide
     * with the principal axes. This also necessitates a correction of the world transform
     * of the collision object by the principal transform.
     */
    public function calculatePrincipalAxisTransform(masses:Array<Float>, principal:Transform, inertia:Vector3f):Void
	{
        var n:Int = children.size();

        var totalMass:Float = 0;
        var center:Vector3f = new Vector3f();
        for (k in 0...n)
		{
            center.scaleAdd(masses[k], children.getQuick(k).transform.origin, center);
            totalMass += masses[k];
        }
        center.scale(1 / totalMass);
        principal.origin.fromVector3f(center);

        var tensor:Matrix3f = new Matrix3f();
        tensor.setZero();

		var j:Matrix3f = new Matrix3f();
		var i:Vector3f = new Vector3f();
		var o:Vector3f = new Vector3f();
        for (k in 0...n)
		{
            children.getQuick(k).childShape.calculateLocalInertia(masses[k], i);

            var t:Transform = children.getQuick(k).transform;
            
            o.sub2(t.origin, center);

            // compute inertia tensor in coordinate system of compound shape
            
            j.transpose2(t.basis);

            j.m00 *= i.x;
            j.m01 *= i.x;
            j.m02 *= i.x;
            j.m10 *= i.y;
            j.m11 *= i.y;
            j.m12 *= i.y;
            j.m20 *= i.z;
            j.m21 *= i.z;
            j.m22 *= i.z;

            j.mul2(t.basis, j);

            // add inertia tensor
            tensor.addMatrix3f(j);

            // compute inertia tensor of pointmass at o
            var o2:Float = o.lengthSquared();
            j.setRow(0, o2, 0, 0);
            j.setRow(1, 0, o2, 0);
            j.setRow(2, 0, 0, o2);
            j.m00 += o.x * -o.x;
            j.m01 += o.y * -o.x;
            j.m02 += o.z * -o.x;
            j.m10 += o.x * -o.y;
            j.m11 += o.y * -o.y;
            j.m12 += o.z * -o.y;
            j.m20 += o.x * -o.z;
            j.m21 += o.y * -o.z;
            j.m22 += o.z * -o.z;

            // add inertia tensor of pointmass
            tensor.m00 += masses[k] * j.m00;
            tensor.m01 += masses[k] * j.m01;
            tensor.m02 += masses[k] * j.m02;
            tensor.m10 += masses[k] * j.m10;
            tensor.m11 += masses[k] * j.m11;
            tensor.m12 += masses[k] * j.m12;
            tensor.m20 += masses[k] * j.m20;
            tensor.m21 += masses[k] * j.m21;
            tensor.m22 += masses[k] * j.m22;
        }

        MatrixUtil.diagonalize(tensor, principal.basis, 0.00001, 20);

        inertia.setTo(tensor.m00, tensor.m11, tensor.m22);
    }
}