
package com.bulletphysics.extras.gimpact;

import com.bulletphysics.linearmath.VectorUtil;

import com.vecmath.Vector3f;

/**
 * @author weilichuang
 */
class Quantization 
{

    public static function bt_calc_quantization_parameters(outMinBound:Vector3f, outMaxBound:Vector3f, bvhQuantization:Vector3f, srcMinBound:Vector3f, srcMaxBound:Vector3f, quantizationMargin:Float):Void
	{
        // enlarge the AABB to avoid division by zero when initializing the quantization values
        var clampValue:Vector3f = new Vector3f();
        clampValue.setTo(quantizationMargin, quantizationMargin, quantizationMargin);
        outMinBound.sub(srcMinBound, clampValue);
        outMaxBound.add(srcMaxBound, clampValue);
        var aabbSize:Vector3f = new Vector3f();
        aabbSize.sub(outMaxBound, outMinBound);
        bvhQuantization.setTo(65535.0, 65535.0, 65535.0);
        VectorUtil.div(bvhQuantization, bvhQuantization, aabbSize);
    }

    public static function bt_quantize_clamp(out:Array<Int>, point:Vector3f, min_bound:Vector3f, max_bound:Vector3f, bvhQuantization:Vector3f):Void
	{
        var clampedPoint:Vector3f = point.clone();
        VectorUtil.setMax(clampedPoint, min_bound);
        VectorUtil.setMin(clampedPoint, max_bound);

        var v:Vector3f = new Vector3f();
        v.sub(clampedPoint, min_bound);
        VectorUtil.mul(v, v, bvhQuantization);

        out[0] = Std.int(v.x + 0.5);
        out[1] = Std.int(v.y + 0.5);
        out[2] = Std.int(v.z + 0.5);
    }

    public static function bt_unquantize(vecIn:Array<Int>, offset:Vector3f, bvhQuantization:Vector3f, out:Vector3f):Vector3f
	{
        out.setTo((vecIn[0] & 0xFFFF) / (bvhQuantization.x),
                (vecIn[1] & 0xFFFF) / (bvhQuantization.y),
                (vecIn[2] & 0xFFFF) / (bvhQuantization.z));
        out.add(offset);
        return out;
    }

}
