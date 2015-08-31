
package com.bulletphysics.collision.gimpact ;

import com.bulletphysics.collision.shapes.StaticPlaneShape;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;

import com.vecmath.Vector3f;
import org.angle3d.math.Vector4f;

/**
 * @author weilichuang
 */
class PlaneShape
{

    public static function get_plane_equation(shape:StaticPlaneShape, equation:Vector4f):Void
	{
        var tmp:Vector3f = new Vector3f();
        shape.getPlaneNormal(tmp);
		equation.setTo(tmp.x, tmp.y, tmp.z, 0);
        equation.w = shape.getPlaneConstant();
    }

    public static function get_plane_equation_transformed(shape:StaticPlaneShape, trans:Transform, equation:Vector4f):Void
	{
        get_plane_equation(shape, equation);

        var tmp:Vector3f = new Vector3f();

        trans.basis.getRow(0, tmp);
        var x:Float = LinearMathUtil.dot3(tmp, equation);
        trans.basis.getRow(1, tmp);
        var y:Float = LinearMathUtil.dot3(tmp, equation);
        trans.basis.getRow(2, tmp);
        var z:Float = LinearMathUtil.dot3(tmp, equation);

        var w:Float = LinearMathUtil.dot3(trans.origin, equation) + equation.w;

        equation.setTo(x, y, z, w);
    }

}
