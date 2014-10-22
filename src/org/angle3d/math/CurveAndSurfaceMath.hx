package org.angle3d.math;

import org.angle3d.math.Vector3f;
import flash.Vector;
import de.polygonal.ds.error.Assert;

/**
 * This class offers methods to help with curves and surfaces calculations.
 * @author Marcin Roguski (Kealthas)
 */
class CurveAndSurfaceMath
{
	private static var KNOTS_MINIMUM_DELTA:Float = 0.0001;

	/**
	 * This method interpolates tha data for the nurbs curve.
	 * @param u
	 *            the u value
	 * @param nurbSpline
	 *            the nurbs spline definition
	 * @param store
	 *            the resulting point in 3D space
	 */
	public static function interpolateNurbs(u:Float, nurbSpline:Spline, store:Vector3f):Void
	{
		Assert.assert(nurbSpline.type == SplineType.Nurb, "Given spline is not of a NURB type!");

		var controlPoints:Vector<Vector3f> = nurbSpline.getControlPoints();

		var weights:Vector<Float> = nurbSpline.getWeights();

		var knots:Vector<Float> = nurbSpline.getKnots();

		var controlPointAmount:Int = controlPoints.length;

		store.setTo(0, 0, 0);
		var delimeter:Float = 0;
		for (i in 0...controlPointAmount)
		{
			var val:Float = weights[i] * CurveAndSurfaceMath.computeBaseFunctionValue(i, nurbSpline.getBasisFunctionDegree(), u, knots);

			store.x += controlPoints[i].x * val;
			store.y += controlPoints[i].y * val;
			store.z += controlPoints[i].z * val;

			delimeter += val;
		}
		store.scaleLocal(1 / delimeter);
	}

	/**
	 * This method interpolates tha data for the nurbs surface.
	 *
	 * @param u
	 *            the u value
	 * @param v
	 *            the v value
	 * @param controlPoints
	 *            the nurbs' control points
	 * @param knots
	 *            the nurbs' knots
	 * @param basisUFunctionDegree
	 *            the degree of basis U function
	 * @param basisVFunctionDegree
	 *            the degree of basis V function
	 * @param store
	 *            the resulting point in 3D space
	 */
	public static function interpolate(u:Float, v:Float, 
										controlPoints:Array<Array<Vector4f>>, 
										knots:Vector<Vector<Float>>, 
										basisUFunctionDegree:Int, basisVFunctionDegree:Int, store:Vector3f):Void
	{
		store.setTo(0, 0, 0);
		var delimeter:Float = 0;
		var vControlPointsAmount:Int = controlPoints.length;
		var uControlPointsAmount:Int = controlPoints[0].length;
		for (i in 0...vControlPointsAmount)
		{
			for (j in 0...uControlPointsAmount)
			{
				var controlPoint:Vector4f = controlPoints[i][j];
				var val:Float = controlPoint.w * computeBaseFunctionValue(i, basisVFunctionDegree, v, knots[1]) * computeBaseFunctionValue(j, basisUFunctionDegree, u, knots[0]);

				store.x += controlPoint.x * val;
				store.y += controlPoint.y * val;
				store.z += controlPoint.z * val;

				delimeter += val;
			}
		}
		store.scaleLocal(1 / delimeter);
	}

	/**
	 * This method prepares the knots to be used. If the knots represent non-uniform B-splines (first and last knot values are being
	 * repeated) it leads to NaN results during calculations. This method adds a small Float to each of such knots to aVoid NaN's.
	 * @param knots
	 *            the knots to be prepared to use
	 * @param basisFunctionDegree
	 *            the degree of basis function
	 */
	// TODO: improve this; constant delta may lead to errors if the difference between tha last repeated
	// point and the following one is lower than it
	public static function prepareNurbsKnots(knots:Vector<Float>, basisFunctionDegree:Int):Void
	{
		var delta:Float = KNOTS_MINIMUM_DELTA;
		var prevValue:Float = knots[0];
		for (i in 1...knots.length)
		{
			var value:Float = knots[i];
			if (value <= prevValue)
			{
				value += delta;
				knots[i] = value;
				delta += KNOTS_MINIMUM_DELTA;
			}
			else
			{
				delta = KNOTS_MINIMUM_DELTA; //reset_the delta's value
			}

			prevValue = value;
		}
	}

	/**
	 * This method computes the base function value for the NURB curve.
	 * @param i
	 *            the knot index
	 * @param k
	 *            the base function degree
	 * @param t
	 *            the knot value
	 * @param knots
	 *            the knots' values
	 * @return the base function value
	 */
	private static function computeBaseFunctionValue(i:Int, k:Int, t:Float, knots:Vector<Float>):Float
	{
		if (k == 1)
		{
			return knots[i] <= t && t < knots[i + 1] ? 1.0 : 0.0;
		}
		else
		{
			return (t - knots[i]) / (knots[i + k - 1] - knots[i]) * CurveAndSurfaceMath.computeBaseFunctionValue(i, k - 1, t, knots) + (knots[i + k] - t) / (knots[i + k] - knots[i + 1]) * CurveAndSurfaceMath.computeBaseFunctionValue(i + 1, k - 1, t, knots);
		}
	}

	/**Interpolate a spline between at least 4 control points following the Catmull-Rom equation.
	 * here is the interpolation matrix
	 * m = [ 0.0  1.0  0.0   0.0 ]
	 *     [-T    0.0  T     0.0 ]
	 *     [ 2T   T-3  3-2T  -T  ]
	 *     [-T    2-T  T-2   T   ]
	 * where T is the curve tension
	 * the result is a value between p1 and p2, t=0 for p1, t=1 for p2
	 * @param u value from 0 to 1
	 * @param T The tension of the curve
	 * @param p0 control point 0
	 * @param p1 control point 1
	 * @param p2 control point 2
	 * @param p3 control point 3
	 * @return catmull-Rom interpolation
	 */
	public static function interpolateCatmullRom(u:Float, T:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float
	{
		var c1:Float, c2:Float, c3:Float, c4:Float;
		c1 = p1;
		c2 = -1.0 * T * p0 + T * p2;
		c3 = 2 * T * p0 + (T - 3) * p1 + (3 - 2 * T) * p2 + -T * p3;
		c4 = -T * p0 + (2 - T) * p1 + (T - 2) * p2 + T * p3;

		return (((c4 * u + c3) * u + c2) * u + c1);
	}

	/**Interpolate a spline between at least 4 control points following the Catmull-Rom equation.
	 * here is the interpolation matrix
	 * m = [ 0.0  1.0  0.0   0.0 ]
	 *     [-T    0.0  T     0.0 ]
	 *     [ 2T   T-3  3-2T  -T  ]
	 *     [-T    2-T  T-2   T   ]
	 * where T is the tension of the curve
	 * the result is a value between p1 and p2, t=0 for p1, t=1 for p2
	 * @param u value from 0 to 1
	 * @param T The tension of the curve
	 * @param p0 control point 0
	 * @param p1 control point 1
	 * @param p2 control point 2
	 * @param p3 control point 3
	 * @param store a Vector3f to store the result
	 * @return catmull-Rom interpolation
	 */
	public static function interpolateCatmullRomVector(u:Float, T:Float, p0:Vector3f, p1:Vector3f, p2:Vector3f, p3:Vector3f, store:Vector3f = null):Vector3f
	{
		if (store == null)
		{
			store = new Vector3f();
		}
		store.x = interpolateCatmullRom(u, T, p0.x, p1.x, p2.x, p3.x);
		store.y = interpolateCatmullRom(u, T, p0.y, p1.y, p2.y, p3.y);
		store.z = interpolateCatmullRom(u, T, p0.z, p1.z, p2.z, p3.z);
		return store;
	}

	/**Interpolate a spline between at least 4 control points following the Bezier equation.
	 * here is the interpolation matrix
	 * m = [ -1.0   3.0  -3.0    1.0 ]
	 *     [  3.0  -6.0   3.0    0.0 ]
	 *     [ -3.0   3.0   0.0    0.0 ]
	 *     [  1.0   0.0   0.0    0.0 ]
	 * where T is the curve tension
	 * the result is a value between p1 and p3, t=0 for p1, t=1 for p3
	 * @param u value from 0 to 1
	 * @param p0 control point 0
	 * @param p1 control point 1
	 * @param p2 control point 2
	 * @param p3 control point 3
	 * @return Bezier interpolation
	 */
	public static function interpolateBezier(u:Float, p0:Float, p1:Float, p2:Float, p3:Float):Float
	{
		var oneMinusU:Float = 1.0 - u;
		var oneMinusU2:Float = oneMinusU * oneMinusU;
		var u2:Float = u * u;
		return p0 * oneMinusU2 * oneMinusU + 3.0 * p1 * u * oneMinusU2 + 3.0 * p2 * u2 * oneMinusU + p3 * u2 * u;
	}

	/**Interpolate a spline between at least 4 control points following the Bezier equation.
	 * here is the interpolation matrix
	 * m = [ -1.0   3.0  -3.0    1.0 ]
	 *     [  3.0  -6.0   3.0    0.0 ]
	 *     [ -3.0   3.0   0.0    0.0 ]
	 *     [  1.0   0.0   0.0    0.0 ]
	 * where T is the tension of the curve
	 * the result is a value between p1 and p3, t=0 for p1, t=1 for p3
	 * @param u value from 0 to 1
	 * @param p0 control point 0
	 * @param p1 control point 1
	 * @param p2 control point 2
	 * @param p3 control point 3
	 * @param store a Vector3f to store the result
	 * @return Bezier interpolation
	 */
	public static function interpolateBezierVector(u:Float, p0:Vector3f, p1:Vector3f, p2:Vector3f, p3:Vector3f, store:Vector3f = null):Vector3f
	{
		if (store == null)
		{
			store = new Vector3f();
		}
		store.x = interpolateBezier(u, p0.x, p1.x, p2.x, p3.x);
		store.y = interpolateBezier(u, p0.y, p1.y, p2.y, p3.y);
		store.z = interpolateBezier(u, p0.z, p1.z, p2.z, p3.z);
		return store;
	}

	/**
	 * Compute the lenght on a catmull rom spline between control point 1 and 2
	 * @param p0 control point 0
	 * @param p1 control point 1
	 * @param p2 control point 2
	 * @param p3 control point 3
	 * @param startRange the starting range on the segment (use 0)
	 * @param endRange the end range on the segment (use 1)
	 * @param curveTension the curve tension
	 * @return the length of the segment
	 */
	public static function getCatmullRomP1toP2Length(p0:Vector3f, p1:Vector3f, p2:Vector3f, p3:Vector3f, startRange:Float, endRange:Float, curveTension:Float):Float
	{
		var epsilon:Float = 0.001;
		var middleValue:Float = (startRange + endRange) * 0.5;

		var start:Vector3f = p1.clone();
		if (startRange != 0)
		{
			interpolateCatmullRomVector(startRange, curveTension, p0, p1, p2, p3, start);
		}

		var end:Vector3f = p2.clone();
		if (endRange != 1)
		{
			interpolateCatmullRomVector(endRange, curveTension, p0, p1, p2, p3, end);
		}

		var middle:Vector3f = interpolateCatmullRomVector(middleValue, curveTension, p0, p1, p2, p3);
		var l:Float = end.distance(start);
		var l1:Float = middle.distance(start);
		var l2:Float = end.distance(middle);
		var len:Float = l1 + l2;
		if (l + epsilon < len)
		{
			l1 = getCatmullRomP1toP2Length(p0, p1, p2, p3, startRange, middleValue, curveTension);
			l2 = getCatmullRomP1toP2Length(p0, p1, p2, p3, middleValue, endRange, curveTension);
		}
		l = l1 + l2;
		return l;
	}

	/**
	 * Compute the lenght on a bezier spline between control point 1 and 2
	 * @param p0 control point 0
	 * @param p1 control point 1
	 * @param p2 control point 2
	 * @param p3 control point 3
	 * @return the length of the segment
	 */
	public static function getBezierP1toP2Length(p0:Vector3f, p1:Vector3f, p2:Vector3f, p3:Vector3f):Float
	{
		var delta:Float = 0.02, t:Float = 0.0, result:Float = 0.0;
		var v1:Vector3f = p0.clone(), v2:Vector3f = new Vector3f();

		while (t <= 1.0)
		{
			interpolateBezierVector(t, p0, p1, p2, p3, v2);
			result += v1.distance(v2);
			v1.copyFrom(v2);
			t += delta;
		}
		return result;
	}
}

