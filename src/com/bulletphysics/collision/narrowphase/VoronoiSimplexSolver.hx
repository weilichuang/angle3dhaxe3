package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.linearmath.VectorUtil;
import de.polygonal.ds.error.Assert;
import com.bulletphysics.util.ObjectPool;
import com.bulletphysics.util.StackPool;
import vecmath.Vector3f;
import haxe.ds.Vector;

/**
 * VoronoiSimplexSolver is an implementation of the closest point distance algorithm
 * from a 1-4 points simplex to the origin. Can be used with GJK, as an alternative
 * to Johnson distance algorithm.
 * 
 * @author weilichuang
 */
class VoronoiSimplexSolver implements SimplexSolverInterface
{
	private var subsimplexResultsPool:ObjectPool<SubSimplexClosestResult> = ObjectPool.getPool(SubSimplexClosestResult);

    private static inline var VORONOI_SIMPLEX_MAX_VERTS:Int = 5;

    private static inline var VERTA:Int = 0;
    private static inline var VERTB:Int = 1;
    private static inline var VERTC:Int = 2;
    private static inline var VERTD:Int = 3;

    public var _numVertices:Int;

    public var simplexVectorW:Vector<Vector3f> = new Vector<Vector3f>(VORONOI_SIMPLEX_MAX_VERTS);
    public var simplexPointsP:Vector<Vector3f> = new Vector<Vector3f>(VORONOI_SIMPLEX_MAX_VERTS);
    public var simplexPointsQ:Vector<Vector3f> = new Vector<Vector3f>(VORONOI_SIMPLEX_MAX_VERTS);

    public var cachedP1:Vector3f = new Vector3f();
    public var cachedP2:Vector3f = new Vector3f();
    public var cachedV:Vector3f = new Vector3f();
    public var lastW:Vector3f = new Vector3f();
    public var cachedValidClosest:Bool;

    public var cachedBC:SubSimplexClosestResult = new SubSimplexClosestResult();

    public var needsUpdate:Bool;
	
	public function new()
	{
		for (i in 0...VORONOI_SIMPLEX_MAX_VERTS) 
		{
            simplexVectorW[i] = new Vector3f();
            simplexPointsP[i] = new Vector3f();
            simplexPointsQ[i] = new Vector3f();
        }
	}

    public inline function removeVertex(index:Int):Void
	{
		#if debug
        Assert.assert (_numVertices > 0);
		#end
		
        _numVertices--;
        simplexVectorW[index].fromVector3f(simplexVectorW[_numVertices]);
        simplexPointsP[index].fromVector3f(simplexPointsP[_numVertices]);
        simplexPointsQ[index].fromVector3f(simplexPointsQ[_numVertices]);
    }

    public inline function reduceVertices(usedVerts:UsageBitfield):Void
	{
        if ((numVertices() >= 4) && (!usedVerts.usedVertexD))
            removeVertex(3);

        if ((numVertices() >= 3) && (!usedVerts.usedVertexC))
            removeVertex(2);

        if ((numVertices() >= 2) && (!usedVerts.usedVertexB))
            removeVertex(1);

        if ((numVertices() >= 1) && (!usedVerts.usedVertexA))
            removeVertex(0);
    }

    public function updateClosestVectorAndPoints():Bool
	{
        if (needsUpdate) 
		{
            cachedBC.reset();

            needsUpdate = false;

            switch (numVertices())
			{
                case 0:
                    cachedValidClosest = false;
                case 1:
				{
                    cachedP1.fromVector3f(simplexPointsP[0]);
                    cachedP2.fromVector3f(simplexPointsQ[0]);
                    cachedV.sub2(cachedP1, cachedP2); //== m_simplexVectorW[0]
                    cachedBC.reset();
                    cachedBC.setBarycentricCoordinates(1, 0, 0, 0);
                    cachedValidClosest = cachedBC.isValid();
                }
                case 2: 
				{
					var pool:StackPool = StackPool.get();
					
                    var tmp:Vector3f = pool.getVector3f();

                    //closest point origin from line segment
                    var from:Vector3f = simplexVectorW[0];
                    var to:Vector3f = simplexVectorW[1];
                    var nearest:Vector3f = pool.getVector3f();

                    var p:Vector3f = pool.getVector3f();
                    p.setTo(0, 0, 0);
                    var diff:Vector3f = pool.getVector3f();
                    diff.sub2(p, from);

                    var v:Vector3f = pool.getVector3f();
                    v.sub2(to, from);

                    var t:Float = v.dot(diff);

                    if (t > 0) 
					{
                        var dotVV:Float = v.dot(v);
                        if (t < dotVV)
						{
                            t /= dotVV;
                            tmp.scale2(t, v);
                            diff.sub(tmp);
                            cachedBC.usedVertices.usedVertexA = true;
                            cachedBC.usedVertices.usedVertexB = true;
                        } 
						else 
						{
                            t = 1;
                            diff.sub(v);
                            // reduce to 1 point
                            cachedBC.usedVertices.usedVertexB = true;
                        }
                    } 
					else 
					{
                        t = 0;
                        //reduce to 1 point
                        cachedBC.usedVertices.usedVertexA = true;
                    }
                    cachedBC.setBarycentricCoordinates(1 - t, t, 0, 0);

                    tmp.scale2(t, v);
                    nearest.add2(from, tmp);

                    tmp.sub2(simplexPointsP[1], simplexPointsP[0]);
                    tmp.scale(t);
                    cachedP1.add2(simplexPointsP[0], tmp);

                    tmp.sub2(simplexPointsQ[1], simplexPointsQ[0]);
                    tmp.scale(t);
                    cachedP2.add2(simplexPointsQ[0], tmp);

                    cachedV.sub2(cachedP1, cachedP2);

                    reduceVertices(cachedBC.usedVertices);

                    cachedValidClosest = cachedBC.isValid();
					
					pool.release();
                }
                case 3: 
				{
					var pool:StackPool = StackPool.get();
					
                    var tmp1:Vector3f = pool.getVector3f();
                    var tmp2:Vector3f = pool.getVector3f();
                    var tmp3:Vector3f = pool.getVector3f();

                    // closest point origin from triangle
                    var p:Vector3f = pool.getVector3f();
                    p.setTo(0, 0, 0);

                    var a:Vector3f = simplexVectorW[0];
                    var b:Vector3f = simplexVectorW[1];
                    var c:Vector3f = simplexVectorW[2];

                    closestPtPointTriangle(p, a, b, c, cachedBC);

                    tmp1.scale2(cachedBC.barycentricCoords[0], simplexPointsP[0]);
                    tmp2.scale2(cachedBC.barycentricCoords[1], simplexPointsP[1]);
                    tmp3.scale2(cachedBC.barycentricCoords[2], simplexPointsP[2]);
                    VectorUtil.add3(cachedP1, tmp1, tmp2, tmp3);

                    tmp1.scale2(cachedBC.barycentricCoords[0], simplexPointsQ[0]);
                    tmp2.scale2(cachedBC.barycentricCoords[1], simplexPointsQ[1]);
                    tmp3.scale2(cachedBC.barycentricCoords[2], simplexPointsQ[2]);
                    VectorUtil.add3(cachedP2, tmp1, tmp2, tmp3);

                    cachedV.sub2(cachedP1, cachedP2);

                    reduceVertices(cachedBC.usedVertices);
                    cachedValidClosest = cachedBC.isValid();
					
					pool.release();
                }
                case 4: 
				{
					var pool:StackPool = StackPool.get();
					
                    var tmp1:Vector3f = pool.getVector3f();
                    var tmp2:Vector3f = pool.getVector3f();
                    var tmp3:Vector3f = pool.getVector3f();
                    var tmp4:Vector3f = pool.getVector3f();

                    var p:Vector3f = pool.getVector3f();
                    p.setTo(0, 0, 0);

                    var a:Vector3f = simplexVectorW[0];
                    var b:Vector3f = simplexVectorW[1];
                    var c:Vector3f = simplexVectorW[2];
                    var d:Vector3f = simplexVectorW[3];

                    var hasSeperation:Bool = closestPtPointTetrahedron(p, a, b, c, d, cachedBC);

                    if (hasSeperation)
					{
                        tmp1.scale2(cachedBC.barycentricCoords[0], simplexPointsP[0]);
                        tmp2.scale2(cachedBC.barycentricCoords[1], simplexPointsP[1]);
                        tmp3.scale2(cachedBC.barycentricCoords[2], simplexPointsP[2]);
                        tmp4.scale2(cachedBC.barycentricCoords[3], simplexPointsP[3]);
                        VectorUtil.add4(cachedP1, tmp1, tmp2, tmp3, tmp4);

                        tmp1.scale2(cachedBC.barycentricCoords[0], simplexPointsQ[0]);
                        tmp2.scale2(cachedBC.barycentricCoords[1], simplexPointsQ[1]);
                        tmp3.scale2(cachedBC.barycentricCoords[2], simplexPointsQ[2]);
                        tmp4.scale2(cachedBC.barycentricCoords[3], simplexPointsQ[3]);
                        VectorUtil.add4(cachedP2, tmp1, tmp2, tmp3, tmp4);

                        cachedV.sub2(cachedP1, cachedP2);
                        reduceVertices(cachedBC.usedVertices);
						
						cachedValidClosest = cachedBC.isValid();
                    }
					else
					{
                        //					printf("sub distance got penetration\n");

                        if (cachedBC.degenerate)
						{
                            cachedValidClosest = false;
                        } 
						else
						{
                            cachedValidClosest = true;
                            //degenerate case == false, penetration = true + zero
                            cachedV.setTo(0, 0, 0);
                        }
						
						cachedValidClosest = cachedBC.isValid();
                    }
					
					pool.release();
                }
                default: 
				{
                    cachedValidClosest = false;
                }
            }
        }

        return cachedValidClosest;
    }

	var ab:Vector3f = new Vector3f();
	var ac:Vector3f = new Vector3f();
	var ap:Vector3f = new Vector3f();
	var bp:Vector3f = new Vector3f();
	var cp:Vector3f = new Vector3f();
	var tmp0:Vector3f = new Vector3f();
	var tmp2:Vector3f = new Vector3f();
	var tmp3:Vector3f = new Vector3f();
    public function closestPtPointTriangle(p:Vector3f, a:Vector3f, b:Vector3f, c:Vector3f, result:SubSimplexClosestResult):Bool
	{
        result.usedVertices.reset();

        // Check if P in vertex region outside A
        
        ab.sub2(b, a);

        ac.sub2(c, a);

        ap.sub2(p, a);

        var d1:Float = ab.dot(ap);
        var d2:Float = ac.dot(ap);

        if (d1 <= 0 && d2 <= 0)
		{
            result.closestPointOnSimplex.fromVector3f(a);
            result.usedVertices.usedVertexA = true;
            result.setBarycentricCoordinates(1, 0, 0, 0);
			
            return true; // a; // barycentric coordinates (1,0,0)
        }

        // Check if P in vertex region outside B
        
        bp.sub2(p, b);

        var d3:Float = ab.dot(bp);
        var d4:Float = ac.dot(bp);

        if (d3 >= 0 && d4 <= d3) 
		{
            result.closestPointOnSimplex.fromVector3f(b);
            result.usedVertices.usedVertexB = true;
            result.setBarycentricCoordinates(0, 1, 0, 0);

            return true; // b; // barycentric coordinates (0,1,0)
        }

        // Check if P in edge region of AB, if so return projection of P onto AB
        var vc:Float = d1 * d4 - d3 * d2;
        if (vc <= 0 && d1 >= 0 && d3 <= 0)
		{
            var v:Float = d1 / (d1 - d3);
            result.closestPointOnSimplex.scaleAdd(v, ab, a);
            result.usedVertices.usedVertexA = true;
            result.usedVertices.usedVertexB = true;
            result.setBarycentricCoordinates(1 - v, v, 0, 0);

            return true;
            //return a + v * ab; // barycentric coordinates (1-v,v,0)
        }

        // Check if P in vertex region outside C
        
        cp.sub2(p, c);

        var d5:Float = ab.dot(cp);
        var d6:Float = ac.dot(cp);

        if (d6 >= 0 && d5 <= d6)
		{
            result.closestPointOnSimplex.fromVector3f(c);
            result.usedVertices.usedVertexC = true;
            result.setBarycentricCoordinates(0, 0, 1, 0);

            return true;//c; // barycentric coordinates (0,0,1)
        }

        // Check if P in edge region of AC, if so return projection of P onto AC
        var vb:Float = d5 * d2 - d1 * d6;
        if (vb <= 0 && d2 >= 0 && d6 <= 0)
		{
            var w:Float = d2 / (d2 - d6);
            result.closestPointOnSimplex.scaleAdd(w, ac, a);
            result.usedVertices.usedVertexA = true;
            result.usedVertices.usedVertexC = true;
            result.setBarycentricCoordinates(1 - w, 0, w, 0);
			
            return true;
            //return a + w * ac; // barycentric coordinates (1-w,0,w)
        }

        // Check if P in edge region of BC, if so return projection of P onto BC
        var va:Float = d3 * d6 - d5 * d4;
        if (va <= 0 && (d4 - d3) >= 0 && (d5 - d6) >= 0) 
		{
            var w:Float = (d4 - d3) / ((d4 - d3) + (d5 - d6));

            tmp0.sub2(c, b);
            result.closestPointOnSimplex.scaleAdd(w, tmp0, b);

            result.usedVertices.usedVertexB = true;
            result.usedVertices.usedVertexC = true;
            result.setBarycentricCoordinates(0, 1 - w, w, 0);
			
            return true;
            // return b + w * (c - b); // barycentric coordinates (0,1-w,w)
        }

        // P inside face region. Compute Q through its barycentric coordinates (u,v,w)
        var denom:Float = 1 / (va + vb + vc);
        var v:Float = vb * denom;
        var w:Float = vc * denom;

        tmp2.scale2(v, ab);
        tmp3.scale2(w, ac);
        VectorUtil.add3(result.closestPointOnSimplex, a, tmp2, tmp3);
        result.usedVertices.usedVertexA = true;
        result.usedVertices.usedVertexB = true;
        result.usedVertices.usedVertexC = true;
        result.setBarycentricCoordinates(1 - v - w, v, w, 0);

        return true;
        //	return a + ab * v + ac * w; // = u*a + v*b + w*c, u = va * denom = btScalar(1.0) - v - w
    }

    /// Test if point p and d lie on opposite sides of plane through abc
	private static var tmp1:Vector3f = new Vector3f();
	private static var normal:Vector3f = new Vector3f();
    public static inline function pointOutsideOfPlane(p:Vector3f, a:Vector3f, b:Vector3f, c:Vector3f, d:Vector3f):Int
	{
        normal.sub2(b, a);
        tmp1.sub2(c, a);
        normal.cross(normal, tmp1);

        tmp1.sub2(p, a);
        var signp:Float = tmp1.dot(normal); // [AP AB AC]

        tmp1.sub2(d, a);
        var signd:Float = tmp1.dot(normal); // [AD AB AC]

        //#ifdef CATCH_DEGENERATE_TETRAHEDRON
//	#ifdef BT_USE_DOUBLE_PRECISION
//	if (signd * signd < (btScalar(1e-8) * btScalar(1e-8)))
//		{
//			return -1;
//		}
//	#else
        if (signd * signd < ((1e-4) * (1e-4)))
		{
            //		printf("affine dependent/degenerate\n");//
            return -1;
        }
        //#endif

        //#endif
        // Points on opposite sides if expression signs are opposite
        return (signp * signd < 0) ? 1 : 0;
    }

	private var tempResult:SubSimplexClosestResult = new SubSimplexClosestResult();
	private var tmp:Vector3f = new Vector3f();
	private var q:Vector3f = new Vector3f();
    public function closestPtPointTetrahedron(p:Vector3f, a:Vector3f, b:Vector3f, c:Vector3f, d:Vector3f, 
											finalResult:SubSimplexClosestResult):Bool
	{
        tempResult.reset();

		// Start out assuming point inside all halfspaces, so closest to itself
		finalResult.closestPointOnSimplex.fromVector3f(p);
		finalResult.usedVertices.reset();
		finalResult.usedVertices.usedVertexA = true;
		finalResult.usedVertices.usedVertexB = true;
		finalResult.usedVertices.usedVertexC = true;
		finalResult.usedVertices.usedVertexD = true;

		var pointOutsideABC:Int = pointOutsideOfPlane(p, a, b, c, d);
		var pointOutsideACD:Int = pointOutsideOfPlane(p, a, c, d, b);
		var pointOutsideADB:Int = pointOutsideOfPlane(p, a, d, b, c);
		var pointOutsideBDC:Int = pointOutsideOfPlane(p, b, d, c, a);

		if (pointOutsideABC < 0 || pointOutsideACD < 0 || pointOutsideADB < 0 || pointOutsideBDC < 0) 
		{
			finalResult.degenerate = true;
			return false;
		}

		if (pointOutsideABC == 0 && pointOutsideACD == 0 && pointOutsideADB == 0 && pointOutsideBDC == 0)
		{
			return false;
		}


		var bestSqDist:Float = Math.POSITIVE_INFINITY;
		// If point outside face abc then compute closest point on abc
		if (pointOutsideABC != 0)
		{
			closestPtPointTriangle(p, a, b, c, tempResult);
			q.fromVector3f(tempResult.closestPointOnSimplex);

			tmp.sub2(q, p);
			var sqDist:Float = tmp.dot(tmp);
			// Update best closest point if (squared) distance is less than current best
			if (sqDist < bestSqDist)
			{
				bestSqDist = sqDist;
				finalResult.closestPointOnSimplex.fromVector3f(q);
				//convert result bitmask!
				finalResult.usedVertices.reset();
				finalResult.usedVertices.usedVertexA = tempResult.usedVertices.usedVertexA;
				finalResult.usedVertices.usedVertexB = tempResult.usedVertices.usedVertexB;
				finalResult.usedVertices.usedVertexC = tempResult.usedVertices.usedVertexC;
				finalResult.setBarycentricCoordinates(
						tempResult.barycentricCoords[VERTA],
						tempResult.barycentricCoords[VERTB],
						tempResult.barycentricCoords[VERTC],
						0
				);

			}
		}


		// Repeat test for face acd
		if (pointOutsideACD != 0)
		{
			closestPtPointTriangle(p, a, c, d, tempResult);
			q.fromVector3f(tempResult.closestPointOnSimplex);
			//convert result bitmask!

			tmp.sub2(q, p);
			var sqDist:Float = tmp.dot(tmp);
			if (sqDist < bestSqDist)
			{
				bestSqDist = sqDist;
				finalResult.closestPointOnSimplex.fromVector3f(q);
				finalResult.usedVertices.reset();
				finalResult.usedVertices.usedVertexA = tempResult.usedVertices.usedVertexA;

				finalResult.usedVertices.usedVertexC = tempResult.usedVertices.usedVertexB;
				finalResult.usedVertices.usedVertexD = tempResult.usedVertices.usedVertexC;
				finalResult.setBarycentricCoordinates(
						tempResult.barycentricCoords[VERTA],
						0,
						tempResult.barycentricCoords[VERTB],
						tempResult.barycentricCoords[VERTC]
				);

			}
		}
		// Repeat test for face adb


		if (pointOutsideADB != 0)
		{
			closestPtPointTriangle(p, a, d, b, tempResult);
			q.fromVector3f(tempResult.closestPointOnSimplex);
			//convert result bitmask!

			tmp.sub2(q, p);
			var sqDist:Float = tmp.dot(tmp);
			if (sqDist < bestSqDist)
			{
				bestSqDist = sqDist;
				finalResult.closestPointOnSimplex.fromVector3f(q);
				finalResult.usedVertices.reset();
				finalResult.usedVertices.usedVertexA = tempResult.usedVertices.usedVertexA;
				finalResult.usedVertices.usedVertexB = tempResult.usedVertices.usedVertexC;

				finalResult.usedVertices.usedVertexD = tempResult.usedVertices.usedVertexB;
				finalResult.setBarycentricCoordinates(
						tempResult.barycentricCoords[VERTA],
						tempResult.barycentricCoords[VERTC],
						0,
						tempResult.barycentricCoords[VERTB]
				);

			}
		}
		// Repeat test for face bdc


		if (pointOutsideBDC != 0)
		{
			closestPtPointTriangle(p, b, d, c, tempResult);
			q.fromVector3f(tempResult.closestPointOnSimplex);
			//convert result bitmask!
			tmp.sub2(q, p);
			var sqDist:Float = tmp.dot(tmp);
			if (sqDist < bestSqDist)
			{
				bestSqDist = sqDist;
				finalResult.closestPointOnSimplex.fromVector3f(q);
				finalResult.usedVertices.reset();
				//
				finalResult.usedVertices.usedVertexB = tempResult.usedVertices.usedVertexA;
				finalResult.usedVertices.usedVertexC = tempResult.usedVertices.usedVertexC;
				finalResult.usedVertices.usedVertexD = tempResult.usedVertices.usedVertexB;

				finalResult.setBarycentricCoordinates(
						0,
						tempResult.barycentricCoords[VERTA],
						tempResult.barycentricCoords[VERTC],
						tempResult.barycentricCoords[VERTB]
				);

			}
		}

		//help! we ended up full !

		if (finalResult.usedVertices.usedVertexA &&
				finalResult.usedVertices.usedVertexB &&
				finalResult.usedVertices.usedVertexC &&
				finalResult.usedVertices.usedVertexD)
		{
			return true;
		}

		return true;
    }

    /**
     * Clear the simplex, remove all the vertices.
     */
    public function reset():Void
	{
        cachedValidClosest = false;
        _numVertices = 0;
        needsUpdate = true;
        lastW.setTo(1e30, 1e30, 1e30);
        cachedBC.reset();
    }

    public function addVertex(w:Vector3f, p:Vector3f, q:Vector3f):Void
	{
        lastW.fromVector3f(w);
        needsUpdate = true;

        simplexVectorW[_numVertices].fromVector3f(w);
        simplexPointsP[_numVertices].fromVector3f(p);
        simplexPointsQ[_numVertices].fromVector3f(q);

        _numVertices++;
    }

    /**
     * Return/calculate the closest vertex.
     */
    public function closest(v:Vector3f):Bool
	{
        var succes:Bool = updateClosestVectorAndPoints();
        v.fromVector3f(cachedV);
        return succes;
    }

    public function maxVertex():Float
	{
        var numverts:Int = numVertices();
        var maxV:Float = 0;
        for (i in 0...numverts)
		{
            var curLen2:Float = simplexVectorW[i].lengthSquared();
            if (maxV < curLen2) 
			{
                maxV = curLen2;
            }
        }
        return maxV;
    }

    public function fullSimplex():Bool
	{
        return (_numVertices == 4);
    }

    public function getSimplex(pBuf:Array<Vector3f>, qBuf:Array<Vector3f>, yBuf:Array<Vector3f>):Int
	{
        for (i in 0...numVertices()) 
		{
            yBuf[i].fromVector3f(simplexVectorW[i]);
            pBuf[i].fromVector3f(simplexPointsP[i]);
            qBuf[i].fromVector3f(simplexPointsQ[i]);
        }
        return numVertices();
    }

    public function inSimplex(w:Vector3f):Bool
	{
        var found:Bool = false;
        var numverts:Int = numVertices();
        //btScalar maxV = btScalar(0.);

        //w is in the current (reduced) simplex
        for (i in 0...numverts) 
		{
            if (simplexVectorW[i].equals(w))
			{
                found = true;
            }
        }

        //check in case lastW is already removed
        if (w.equals(lastW)) 
		{
            return true;
        }

        return found;
    }

    public function backup_closest(v:Vector3f):Void
	{
        v.fromVector3f(cachedV);
    }

    public function emptySimplex():Bool
	{
        return (numVertices() == 0);
    }

    public function compute_points(p1:Vector3f, p2:Vector3f):Void
	{
        updateClosestVectorAndPoints();
        p1.fromVector3f(cachedP1);
        p2.fromVector3f(cachedP2);
    }

    public inline function numVertices():Int
	{
        return _numVertices;
    }
}

class UsageBitfield 
{
	public var usedVertexA:Bool;
	public var usedVertexB:Bool;
	public var usedVertexC:Bool;
	public var usedVertexD:Bool;
	
	public function new()
	{
		
	}

	public inline function reset():Void
	{
		usedVertexA = false;
		usedVertexB = false;
		usedVertexC = false;
		usedVertexD = false;
	}
}

class SubSimplexClosestResult
{
	public var closestPointOnSimplex:Vector3f = new Vector3f();
	//MASK for m_usedVertices
	//stores the simplex vertex-usage, using the MASK,
	// if m_usedVertices & MASK then the related vertex is used
	public var usedVertices:UsageBitfield = new UsageBitfield();
	public var barycentricCoords:Vector<Float> = new Vector<Float>(4);
	public var degenerate:Bool;

	public inline function reset():Void
	{
		degenerate = false;
		setBarycentricCoordinates(0, 0, 0, 0);
		usedVertices.reset();
	}

	public inline function isValid():Bool
	{
		var valid:Bool = (barycentricCoords[0] >= 0) &&
				(barycentricCoords[1] >= 0) &&
				(barycentricCoords[2] >= 0) &&
				(barycentricCoords[3] >= 0);
		return valid;
	}

	public inline function setBarycentricCoordinates( a:Float, b:Float, c:Float, d:Float):Void
	{
		barycentricCoords[0] = a;
		barycentricCoords[1] = b;
		barycentricCoords[2] = c;
		barycentricCoords[3] = d;
	}
}