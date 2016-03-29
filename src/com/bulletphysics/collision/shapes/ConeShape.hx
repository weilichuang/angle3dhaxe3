package com.bulletphysics.collision.shapes;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import org.angle3d.math.Vector3f;

/**
 * ConeShape implements a cone shape primitive, centered around the origin and
 * aligned with the Y axis. The {ConeShapeX} is aligned around the X axis
 * and {ConeShapeZ} around the Z axis.
 *
 * @author weilichuang
 */
class ConeShape extends ConvexInternalShape
{
	private var sinAngle:Float;
	private var radius:Float;
	private var height:Float;
	private var coneIndices:Array<Int> = [];

	public function new(radius:Float,height:Float) 
	{
		super();
		
		_shapeType = BroadphaseNativeType.CONE_SHAPE_PROXYTYPE;
		
		this.radius = radius;
		this.height = height;
		setConeUpIndex(1);
		
		sinAngle = (radius / Math.sqrt(this.radius * this.radius + this.height * this.height));
	}
	
	public function getRadius():Float
	{
		return radius;
	}
	
	public function getHeight():Float
	{
		return height;
	}
	
	public function coneLocalSupport(v:Vector3f, out:Vector3f):Vector3f
	{
		var halfHeight:Float = height * 0.5;
		
		if (LinearMathUtil.getCoord(v, coneIndices[1]) > v.length * sinAngle)
		{
            LinearMathUtil.setCoord(out, coneIndices[0], 0);
            LinearMathUtil.setCoord(out, coneIndices[1], halfHeight);
            LinearMathUtil.setCoord(out, coneIndices[2], 0);
            return out;
        }
		else
		{
            var v0:Float = LinearMathUtil.getCoord(v, coneIndices[0]);
            var v2:Float = LinearMathUtil.getCoord(v, coneIndices[2]);
            var s:Float = Math.sqrt(v0 * v0 + v2 * v2);
            if (s > BulletGlobals.FLT_EPSILON) 
			{
                var d:Float = radius / s;
                LinearMathUtil.setCoord(out, coneIndices[0], LinearMathUtil.getCoord(v, coneIndices[0]) * d);
                LinearMathUtil.setCoord(out, coneIndices[1], -halfHeight);
                LinearMathUtil.setCoord(out, coneIndices[2], LinearMathUtil.getCoord(v, coneIndices[2]) * d);
                return out;
            } 
			else
			{
                LinearMathUtil.setCoord(out, coneIndices[0], 0);
                LinearMathUtil.setCoord(out, coneIndices[1], -halfHeight);
                LinearMathUtil.setCoord(out, coneIndices[2], 0);
                return out;
            }
        }
	}
	
	override public function localGetSupportingVertexWithoutMargin(vec:Vector3f, out:Vector3f):Vector3f 
	{
		return coneLocalSupport(vec, out);
	}
	
	override public function batchedUnitVectorGetSupportingVertexWithoutMargin(vectors:Array<Vector3f>, supportVerticesOut:Array<Vector3f>, numVectors:Int):Void 
	{
		for (i in 0...numVectors)
		{
			var vec:Vector3f = vectors[i];
			coneLocalSupport(vec, supportVerticesOut[i]);
		}
	}
	
	override public function localGetSupportingVertex(vec:Vector3f, out:Vector3f):Vector3f 
	{
		var supVertex:Vector3f = coneLocalSupport(vec, out);
        if (getMargin() != 0)
		{
            var vecnorm:Vector3f = vec.clone();
            if (vecnorm.lengthSquared < (BulletGlobals.FLT_EPSILON * BulletGlobals.FLT_EPSILON))
			{
                vecnorm.setTo(-1, -1, -1);
            }
            vecnorm.normalizeLocal();
            supVertex.scaleAddBy(getMargin(), vecnorm, supVertex);
        }
        return supVertex;
	}

	override public function calculateLocalInertia(mass:Float, inertia:Vector3f):Void 
	{
		var identity:Transform = new Transform();
        identity.setIdentity();
        var aabbMin:Vector3f = new Vector3f();
		var aabbMax:Vector3f = new Vector3f();
        getAabb(identity, aabbMin, aabbMax);

        var halfExtents:Vector3f = new Vector3f();
        halfExtents.subtractBy(aabbMax, aabbMin);
        halfExtents.scaleLocal(0.5);

        var margin:Float = getMargin();

        var lx:Float = 2 * (halfExtents.x + margin);
        var ly:Float = 2 * (halfExtents.y + margin);
        var lz:Float = 2 * (halfExtents.z + margin);
        var x2:Float = lx * lx;
        var y2:Float = ly * ly;
        var z2:Float = lz * lz;
        var scaledmass:Float = mass * 0.08333333;

        inertia.setTo(y2 + z2, x2 + z2, x2 + y2);
        inertia.scaleLocal(scaledmass);

        //inertia.x() = scaledmass * (y2+z2);
        //inertia.y() = scaledmass * (x2+z2);
        //inertia.z() = scaledmass * (x2+y2);
	}
	
	override public function getName():String 
	{
		return "Cone";
	}
	
	// choose upAxis index
	private function setConeUpIndex(upIndex:Int):Void
	{
		switch (upIndex) 
		{
            case 0:
                coneIndices[0] = 1;
                coneIndices[1] = 0;
                coneIndices[2] = 2;
            case 1:
                coneIndices[0] = 0;
                coneIndices[1] = 1;
                coneIndices[2] = 2;
            case 2:
                coneIndices[0] = 0;
                coneIndices[1] = 2;
                coneIndices[2] = 1;
        }
	}
	
	public function getConeUpIndex():Int
	{
		return coneIndices[1];
	}
}