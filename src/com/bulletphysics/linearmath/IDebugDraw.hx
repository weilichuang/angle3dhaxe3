package com.bulletphysics.linearmath;
import org.angle3d.math.Vector3f;

/**
 * IDebugDraw interface class allows hooking up a debug renderer to visually debug
 * simulations.<p>
 * <p/>
 * Typical use case: create a debug drawer object, and assign it to a {CollisionWorld}
 * or {DynamicsWorld} using setDebugDrawer and call debugDrawWorld.<p>
 * <p/>
 * A class that implements the IDebugDraw interface has to implement the drawLine
 * method at a minimum.
 * 
 * @author weilichuang
 */
class IDebugDraw
{
	public function new()
	{
		
	}

	public function drawLine( from:Vector3f, to:Vector3f, color:Vector3f):Void
	{
		
	}

    public function drawTriangle(v0:Vector3f, v1:Vector3f, v2:Vector3f, color:Vector3f, alpha:Float):Void
	{
        drawLine(v0, v1, color);
        drawLine(v1, v2, color);
        drawLine(v2, v0, color);
    }

    public function drawContactPoint( PointOnB:Vector3f, normalOnB:Vector3f, distance:Float, lifeTime:Int, color:Vector3f):Void
	{
		
	}

    public function reportErrorWarning(warningString:String):Void
	{
		
	}

    public function draw3dText(location:Vector3f, textString:String):Void
	{
		
	}

    public function setDebugMode(debugMode:Int):Void
	{
		
	}

    public function getDebugMode():Int
	{
		return 0;
	}

    public function drawAabb(from:Vector3f, to:Vector3f, color:Vector3f):Void
	{
        var halfExtents:Vector3f = to.clone();
        halfExtents.subtractLocal(from);
        halfExtents.scaleLocal(0.5);

        var center:Vector3f = to.clone();
        center.addLocal(from);
        center.scaleLocal(0.5);

        var edgecoord:Vector3f = new Vector3f();
        edgecoord.setTo(1, 1, 1);
        var pa:Vector3f = new Vector3f();
		var pb:Vector3f = new Vector3f();
        for (i in 0...4)
		{
            for (j in 0...3)
			{
                pa.setTo(edgecoord.x * halfExtents.x, edgecoord.y * halfExtents.y, edgecoord.z * halfExtents.z);
                pa.addLocal(center);

                var othercoord:Int = j % 3;

                LinearMathUtil.mulCoord(edgecoord, othercoord, -1);
                pb.setTo(edgecoord.x * halfExtents.x, edgecoord.y * halfExtents.y, edgecoord.z * halfExtents.z);
                pb.addLocal(center);

                drawLine(pa, pb, color);
            }
            edgecoord.setTo(-1, -1, -1);
            if (i < 3)
			{
                LinearMathUtil.mulCoord(edgecoord, i, -1);
            }
        }
    }
	
}