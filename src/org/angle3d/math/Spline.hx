package org.angle3d.math;

import flash.Vector;
import org.angle3d.math.Vector3f;
import org.angle3d.error.Assert;


class Spline
{
	private var controlPoints:Vector<Vector3f>;
	private var knots:Vector<Float>; //knots of NURBS spline
	private var weights:Vector<Float>; //weights of NURBS spline
	private var basisFunctionDegree:Int; //degree of NURBS spline basis function (computed automatically)
	private var cycle:Bool;
	private var segmentsLength:Vector<Float>;
	private var totalLength:Float;
	private var CRcontrolPoints:Vector<Vector3f>;
	private var curveTension:Float;
	private var _type:SplineType;

	public function new()
	{
		controlPoints = new Vector<Vector3f>();
		curveTension = 0.5;
		_type = SplineType.CatmullRom;
	}

	/**
	 * Create a spline
	 * @param splineType the type of the spline @see {SplineType}
	 * @param controlPoints a list of vector to use as control points of the spline
	 * If the type of the curve is Bezier curve the control points should be provided
	 * in the appropriate way. Each point 'p' describing control position in the scene
	 * should be surrounded by two handler points. This applies to every point except
	 * for the border points of the curve, who should have only one handle point.
	 * The pattern should be as follows:
	 * P0 - H0  :  H1 - P1 - H1  :  ...  :  Hn - Pn
	 *
	 * n is the amount of 'P' - points.
	 * @param curveTension the tension of the spline
	 * @param cycle true if the spline cycle.
	 */
	public function createNormal(splineType:SplineType, controlPoints:Vector<Vector3f>, curveTension:Float = 0.5, cycle:Bool = false):Void
	{
		Assert.assert(splineType != SplineType.Nurb, "To create NURBS spline use createNURBS");

		this._type = splineType;
		this.controlPoints.concat(controlPoints);
		this.curveTension = curveTension;
		this.cycle = cycle;

		this.computeTotalLength();
	}

	/**
	 * Create a NURBS spline. A spline type is automatically set_to SplineType.Nurb.
	 * The cycle is set_to <b>false</b> by default.
	 * @param controlPoints a list of vector to use as control points of the spline
	 * @param nurbKnots the nurb's spline knots
	 */
	public function createNURBS(controlPoints:Vector<Vector4f>, nurbKnots:Vector<Float>):Void
	{
		//input data control
		#if debug
		var length:Int = (nurbKnots.length - 1);
		for (i in 0...length)
		{
			Assert.assert(nurbKnots[i] <= nurbKnots[i + 1], "The knots values cannot decrease!");
		}
		#end

		//storing the data
		_type = SplineType.Nurb;
		this.weights = new Vector<Float>(controlPoints.length);
		this.knots = nurbKnots;
		this.basisFunctionDegree = nurbKnots.length - weights.length;
		for (i in 0...controlPoints.length)
		{
			var cp:Vector4f = controlPoints[i];
			var v3:Vector3f = new Vector3f();
			v3.x = cp.x;
			v3.y = cp.y;
			v3.z = cp.z;
			this.controlPoints.push(v3);
			this.weights[i] = cp.w;
		}
		CurveAndSurfaceMath.prepareNurbsKnots(knots, basisFunctionDegree);
		this.computeTotalLength();
	}

	private function initCatmullRomWayPoints(list:Vector<Vector3f>):Void
	{
		CRcontrolPoints = new Vector<Vector3f>();

		var nb:Int = list.length - 1;
		if (cycle)
		{
			CRcontrolPoints.push(list[list.length - 2]);
		}
		else
		{
			CRcontrolPoints.push(list[0].subtract(list[1].subtract(list[0])));
		}

		for (i in 0...list.length)
		{
			CRcontrolPoints.push(list[i]);
		}

		if (cycle)
		{
			CRcontrolPoints.push(list[1]);
		}
		else
		{
			CRcontrolPoints.push(list[nb].add(list[nb].subtract(list[nb - 1])));
		}
	}

	/**
	 * Adds a controlPoint to the spline
	 * @param controlPoint a position in world space
	 */
	public function addControlPoint(controlPoint:Vector3f):Void
	{
		if (controlPoints.length > 2 && this.cycle)
		{
			controlPoints.splice(controlPoints.length - 1, 1);
		}

		controlPoints.push(controlPoint.clone());

		if (controlPoints.length > 2 && this.cycle)
		{
			controlPoints.push(controlPoints[0].clone());
		}

		if (controlPoints.length > 1)
		{
			this.computeTotalLength();
		}
	}

	/**
	 * remove the controlPoint from the spline
	 * @param controlPoint the controlPoint to remove
	 */
	public function removeControlPoint(controlPoint:Vector3f):Void
	{
		var index:Int = controlPoints.indexOf(controlPoint);
		if (index > -1)
		{
			controlPoints.splice(index, 1);
		}
		if (controlPoints.length > 1)
		{
			this.computeTotalLength();
		}
	}

	public function clearControlPoints():Void
	{
		controlPoints = new Vector<Vector3f>();
		totalLength = 0;
	}

	/**
	 * This method computes the total length of the curve.
	 */
	private function computeTotalLength():Void
	{
		totalLength = 0;

		var l:Float = 0;
		
		segmentsLength = new Vector<Float>();

		if (_type == SplineType.Linear)
		{
			var cLength:Int = (controlPoints.length - 1);
			for (i in 0...cLength)
			{
				l = controlPoints[i + 1].subtract(controlPoints[i]).length;
				segmentsLength.push(l);
				totalLength += l;
			}
		}
		else if (_type == SplineType.Bezier)
		{
			this.computeBezierLength();
		}
		else if (_type == SplineType.Nurb)
		{
			this.computeNurbLength();
		}
		else
		{
			this.initCatmullRomWayPoints(controlPoints);
			this.computeCatmulLength();
		}
	}

	/**
	 * This method computes the Catmull Rom curve length.
	 */
	private function computeCatmulLength():Void
	{
		var l:Float = 0;
		if (controlPoints.length > 1)
		{
			var cLength:Int = (controlPoints.length - 1);
			for (i in 0...cLength)
			{
				l = CurveAndSurfaceMath.getCatmullRomP1toP2Length(CRcontrolPoints[i], CRcontrolPoints[i + 1], CRcontrolPoints[i + 2], CRcontrolPoints[i + 3], 0, 1, curveTension);
				segmentsLength.push(l);
				totalLength += l;
			}
		}
	}

	/**
	 * This method calculates the Bezier curve length.
	 */
	private function computeBezierLength():Void
	{
		var l:Float = 0;
		if (controlPoints.length > 1)
		{
			var i:Int = 0;
			while (i < controlPoints.length - 1)
			{
				l = CurveAndSurfaceMath.getBezierP1toP2Length(controlPoints[i], controlPoints[i + 1], controlPoints[i + 2], controlPoints[i + 3]);

				segmentsLength.push(l);

				totalLength += l;

				i += 3;
			}
		}
	}

	/**
	 * This method calculates the NURB curve length.
	 */
	private function computeNurbLength():Void
	{
		//TODO: implement
	}

	/**
	 * Iterpolate a position on the spline
	 * @param value a value from 0 to 1 that represent the postion between the curent control point and the next one
	 * @param currentControlPoint the current control point
	 * @param store a vector to store the result (use null to create a new one that will be returned by the method)
	 * @return the position
	 */
	public function interpolate(value:Float, currentControlPoint:Int, store:Vector3f = null):Vector3f
	{
		if (store == null)
		{
			store = new Vector3f();
		}

		switch (_type)
		{
			case SplineType.CatmullRom:
				CurveAndSurfaceMath.interpolateCatmullRomVector(value, curveTension, CRcontrolPoints[currentControlPoint], CRcontrolPoints[currentControlPoint + 1], CRcontrolPoints[currentControlPoint + 2], CRcontrolPoints[currentControlPoint + 3], store);
			case SplineType.Linear:
				FastMath.lerpVector3(controlPoints[currentControlPoint], controlPoints[currentControlPoint + 1], value, store);
			case SplineType.Bezier:
				CurveAndSurfaceMath.interpolateBezierVector(value, controlPoints[currentControlPoint], controlPoints[currentControlPoint + 1], controlPoints[currentControlPoint + 2], controlPoints[currentControlPoint + 3], store);
			case SplineType.Nurb:
				CurveAndSurfaceMath.interpolateNurbs(value, this, store);
		}
		return store;
	}

	/**
	 * returns the curve tension
	 */
	public function getCurveTension():Float
	{
		return curveTension;
	}

	/**
	 * sets the curve tension
	 *
	 * @param curveTension the tension
	 */
	public function setCurveTension(curveTension:Float):Void
	{
		this.curveTension = curveTension;
		if (_type == SplineType.CatmullRom && getControlPoints().length > 0)
		{
			this.computeTotalLength();
		}
	}

	/**
	 * returns true if the spline cycle
	 */
	public function isCycle():Bool
	{
		return cycle;
	}

	/**
	 * set_to true to make the spline cycle
	 * @param cycle
	 */
	public function setCycle(cycle:Bool):Void
	{
		if (_type != SplineType.Nurb)
		{
			if (controlPoints.length >= 2)
			{
				if (this.cycle && !cycle)
				{
					controlPoints.splice(controlPoints.length - 1, 1);
				}

				if (!this.cycle && cycle)
				{
					controlPoints.push(controlPoints[0]);
				}
				this.cycle = cycle;
				this.computeTotalLength();
			}
			else
			{
				this.cycle = cycle;
			}
		}
	}

	/**
	 * return the total lenght of the spline
	 */
	public function getTotalLength():Float
	{
		return totalLength;
	}

	/**
	 * return the type of the spline
	 */
	public var type(get, set):SplineType;
	private function get_type():SplineType
	{
		return _type;
	}

	private function set_type(type:SplineType):SplineType
	{
		_type = type;
		computeTotalLength();
		
		return _type;
	}

	/**
	 * returns this spline control points
	 */
	public function getControlPoints():Vector<Vector3f>
	{
		return controlPoints;
	}

	public function getControlPointAt(index:Int):Vector3f
	{
		return controlPoints[index];
	}

	/**
	 * returns a list of float representing the segments lenght
	 */
	public function getSegmentsLength():Vector<Float>
	{
		return segmentsLength;
	}

	public function getSegmentLengthAt(i:Int):Float
	{
		return segmentsLength[i];
	}

	//////////// NURBS getters /////////////////////

	/**
	 * This method returns the minimum nurb curve knot value. Check the nurb type before calling this method. It the curve is not of a Nurb
	 * type - NPE will be thrown.
	 * @return the minimum nurb curve knot value
	 */
	public function getMinNurbKnot():Float
	{
		return knots[basisFunctionDegree - 1];
	}

	/**
	 * This method returns the maximum nurb curve knot value. Check the nurb type before calling this method. It the curve is not of a Nurb
	 * type - NPE will be thrown.
	 * @return the maximum nurb curve knot value
	 */
	public function getMaxNurbKnot():Float
	{
		return knots[weights.length];
	}

	/**
	 * This method returns NURBS' spline knots.
	 * @return NURBS' spline knots
	 */
	public function getKnots():Vector<Float>
	{
		return knots;
	}

	/**
	 * This method returns NURBS' spline weights.
	 * @return NURBS' spline weights
	 */
	public function getWeights():Vector<Float>
	{
		return weights;
	}

	/**
	 * This method returns NURBS' spline basis function degree.
	 * @return NURBS' spline basis function degree
	 */
	public function getBasisFunctionDegree():Int
	{
		return basisFunctionDegree;
	}
}


