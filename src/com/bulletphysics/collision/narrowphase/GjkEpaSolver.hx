package com.bulletphysics.collision.narrowphase;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.linearmath.QuaternionUtil;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.ObjectStackList;
import com.vecmath.Matrix3f;
import com.vecmath.MatrixUtil;
import com.vecmath.Quat4f;
import com.vecmath.Vector3f;
import haxe.ds.Vector;

/*
GJK-EPA collision solver by Nathanael Presson
Nov.2006
*/

/**
 * GjkEpaSolver contributed under zlib by Nathanael Presson.
 * @author weilichuang
 */
class GjkEpaSolver
{
    public var stackMkv:ObjectStackList<Mkv> = new ObjectStackList<Mkv>(Mkv);
    public var stackHe:ObjectStackList<He> = new ObjectStackList<He>(He);
    public var stackFace:ObjectStackList<Face> = new ObjectStackList<Face>(Face);

    public function pushStack():Void
	{
        stackMkv.push();
        stackHe.push();
        stackFace.push();
    }

    public function popStack():Void
	{
        stackMkv.pop();
        stackHe.pop();
        stackFace.pop();
    }

    public static var cstInf:Float = BulletGlobals.SIMD_INFINITY;
    public static var cstPi:Float = BulletGlobals.SIMD_PI;
    public static var cst2Pi:Float = BulletGlobals.SIMD_2_PI;
    public static var GJK_maxiterations:Int = 128;
    public static var GJK_hashsize:Int = 1 << 6;
    public static var GJK_hashmask:Int = GJK_hashsize - 1;
    public static var GJK_insimplex_eps:Float = 0.0001;
    public static var GJK_sqinsimplex_eps:Float = GJK_insimplex_eps * GJK_insimplex_eps;
    public static var EPA_maxiterations:Int = 256;
    public static var EPA_inface_eps:Float = 0.01;
    public static var EPA_accuracy:Float = 0.001;

    public static var mod3:Array<Int> = [0, 1, 2, 0, 1];

    public static var tetrahedron_fidx:Array<Array<Int>> = [[2, 1, 0], [3, 0, 1], [3, 1, 2], [3, 2, 0]];
    public static var tetrahedron_eidx:Array<Array<Int>> = [[0, 0, 2, 1], [0, 1, 1, 1], [0, 2, 3, 1], [1, 0, 3, 2], [2, 0, 1, 2], [3, 0, 2, 2]];

    public static var hexahedron_fidx:Array<Array<Int>> = [[2, 0, 4], [4, 1, 2], [1, 4, 0], [0, 3, 1], [0, 2, 3], [1, 3, 2]];
    public static var hexahedron_eidx:Array<Array<Int>> = [[0, 0, 4, 0], [0, 1, 2, 1], [0, 2, 1, 2], [1, 1, 5, 2], [1, 0, 2, 0], [2, 2, 3, 2], [3, 1, 5, 0], [3, 0, 4, 2], [5, 1, 4, 1]];

    
    public function new() 
	{
		gjk = new GJK(this);
	}

    private var gjk:GJK;

    public function collide(shape0:ConvexShape, wtrs0:Transform,
                            shape1:ConvexShape, wtrs1:Transform,
                            radialmargin:Float,
                            results:Results):Bool
    {

        // Initialize
        results.witnesses[0].setTo(0, 0, 0);
        results.witnesses[1].setTo(0, 0, 0);
        results.normal.setTo(0, 0, 0);
        results.depth = 0;
        results.status = ResultsStatus.Separated;
        results.epa_iterations = 0;
        results.gjk_iterations = 0;
		/* Use GJK to locate origin		*/
        gjk.init(wtrs0.basis, wtrs0.origin, shape0,
                wtrs1.basis, wtrs1.origin, shape1,
                radialmargin + EPA_accuracy);
			
		var collide:Bool = gjk.SearchOrigin();
		results.gjk_iterations = gjk.iterations + 1;
		if (collide)
		{
			/* Then EPA for penetration depth	*/
			var epa:EPA = new EPA(this,gjk);
			var pd:Float = epa.EvaluatePD();
			results.epa_iterations = epa.iterations + 1;
			if (pd > 0)
			{
				results.status = ResultsStatus.Penetrating;
				results.normal.fromVector3f(epa.normal);
				results.depth = pd;
				results.witnesses[0].fromVector3f(epa.nearest[0]);
				results.witnesses[1].fromVector3f(epa.nearest[1]);
				
				gjk.destroy();
				return true;
			} 
			else
			{
				if (epa.failed) 
				{
					results.status = ResultsStatus.EPA_Failed;
				}
			}
		} 
		else
		{
			if (gjk.failed)
			{
				results.status = ResultsStatus.GJK_Failed;
			}
		}
		
		gjk.destroy();
		return false;
    }
}


class Mkv 
{
	public var w:Vector3f = new Vector3f(); // Minkowski vertice
	public var r:Vector3f = new Vector3f(); // Ray

	public function set(m:Mkv):Void
	{
		w.fromVector3f(m.w);
		r.fromVector3f(m.r);
	}
}

class He 
{
	public var v:Vector3f = new Vector3f();
	public var n:He;
}

class GJK 
{
	public var table:Vector<He> = new Vector<He>(GjkEpaSolver.GJK_hashsize);
	public var wrotations:Array<Matrix3f> = [new Matrix3f(), new Matrix3f()];
	public var positions:Array<Vector3f> = [new Vector3f(), new Vector3f()];
	public var shapes:Vector<ConvexShape> = new Vector<ConvexShape>(2);
	public var simplex:Vector<Mkv> = new Vector<Mkv>(5);
	public var ray:Vector3f = new Vector3f();
	public var order:Int;
	public var iterations:Int;
	public var margin:Float;
	public var failed:Bool;

	public var solver:GjkEpaSolver;
	public function new(solver:GjkEpaSolver)
	{
		this.solver = solver;
		for (i in 0...simplex.length) 
			simplex[i] = new Mkv();
	}

	public function init(wrot0:Matrix3f, pos0:Vector3f, shape0:ConvexShape,
			    wrot1:Matrix3f, pos1:Vector3f, shape1:ConvexShape,
				pmargin:Float = 0):Void
	{
		solver.pushStack();
		wrotations[0].fromMatrix3f(wrot0);
		positions[0].fromVector3f(pos0);
		shapes[0] = shape0;
		wrotations[1].fromMatrix3f(wrot1);
		positions[1].fromVector3f(pos1);
		shapes[1] = shape1;
		margin = pmargin;
		failed = false;
	}

	public function destroy():Void
	{
		solver.popStack();
	}

	// vdh: very dummy hash
	public function Hash(v:Vector3f):Int
	{
		var h:Int = Std.int(v.x * 15461) ^ Std.int(v.y * 83003) ^ Std.int(v.z * 15473);
		return (h * 169639) & GjkEpaSolver.GJK_hashmask;
	}

	public function LocalSupport(d:Vector3f, i:Int, out:Vector3f):Vector3f
	{
		var tmp:Vector3f = new Vector3f();
		MatrixUtil.transposeTransform(tmp, d, wrotations[i]);

		shapes[i].localGetSupportingVertex(tmp, out);
		wrotations[i].transform(out);
		out.add(positions[i]);

		return out;
	}

	public function Support(d:Vector3f, v:Mkv):Void
	{
		v.r.fromVector3f(d);

		var tmp1:Vector3f = LocalSupport(d, 0, new Vector3f());

		var tmp:Vector3f = new Vector3f();
		tmp.fromVector3f(d);
		tmp.negate();
		var tmp2:Vector3f = LocalSupport(tmp, 1, new Vector3f());

		v.w.sub(tmp1, tmp2);
		v.w.scaleAdd(margin, d, v.w);
	}

	public function FetchSupport():Bool
	{
		var h:Int = Hash(ray);
		var e:He = table[h];
		while (e != null)
		{
			if (e.v.equals(ray))
			{
				--order;
				return false;
			} 
			else 
			{
				e = e.n;
			}
		}
		//e = (He*)sa->allocate(sizeof(He));
		//e = new He();
		e = solver.stackHe.get();
		e.v.fromVector3f(ray);
		e.n = table[h];
		table[h] = e;
		Support(ray, simplex[++order]);
		return (ray.dot(simplex[order].w) > 0);
	}

	public function SolveSimplex2(ao:Vector3f, ab:Vector3f):Bool
	{
		if (ab.dot(ao) >= 0)
		{
			var cabo:Vector3f = new Vector3f();
			cabo.cross(ab, ao);
			if (cabo.lengthSquared() > GjkEpaSolver.GJK_sqinsimplex_eps) 
			{
				ray.cross(cabo, ab);
			} 
			else
			{
				return true;
			}
		} 
		else
		{
			order = 0;
			simplex[0].set(simplex[1]);
			ray.fromVector3f(ao);
		}
		return false;
	}

	public function SolveSimplex3(ao:Vector3f, ab:Vector3f, ac:Vector3f):Bool
	{
		var tmp:Vector3f = new Vector3f();
		tmp.cross(ab, ac);
		return (SolveSimplex3a(ao, ab, ac, tmp));
	}

	public function SolveSimplex3a(ao:Vector3f, ab:Vector3f, ac:Vector3f, cabc:Vector3f):Bool
	{
		// TODO: optimize

		var tmp:Vector3f = new Vector3f();
		tmp.cross(cabc, ab);

		var tmp2:Vector3f = new Vector3f();
		tmp2.cross(cabc, ac);

		if (tmp.dot(ao) < -GjkEpaSolver.GJK_insimplex_eps)
		{
			order = 1;
			simplex[0].set(simplex[1]);
			simplex[1].set(simplex[2]);
			return SolveSimplex2(ao, ab);
		} 
		else if (tmp2.dot(ao) > GjkEpaSolver.GJK_insimplex_eps)
		{
			order = 1;
			simplex[1].set(simplex[2]);
			return SolveSimplex2(ao, ac);
		} 
		else
		{
			var d:Float = cabc.dot(ao);
			if (Math.abs(d) > GjkEpaSolver.GJK_insimplex_eps)
			{
				if (d > 0) 
				{
					ray.fromVector3f(cabc);
				} 
				else 
				{
					ray.negate(cabc);

					var swapTmp:Mkv = new Mkv();
					swapTmp.set(simplex[0]);
					simplex[0].set(simplex[1]);
					simplex[1].set(swapTmp);
				}
				return false;
			} 
			else
			{
				return true;
			}
		}
	}

	public function SolveSimplex4(ao:Vector3f, ab:Vector3f, ac:Vector3f, ad:Vector3f):Bool
	{
		// TODO: optimize

		var crs:Vector3f = new Vector3f();

		var tmp:Vector3f = new Vector3f();
		tmp.cross(ab, ac);

		var tmp2:Vector3f = new Vector3f();
		tmp2.cross(ac, ad);

		var tmp3:Vector3f = new Vector3f();
		tmp3.cross(ad, ab);

		if (tmp.dot(ao) > GjkEpaSolver.GJK_insimplex_eps)
		{
			crs.fromVector3f(tmp);
			order = 2;
			simplex[0].set(simplex[1]);
			simplex[1].set(simplex[2]);
			simplex[2].set(simplex[3]);
			return SolveSimplex3a(ao, ab, ac, crs);
		} 
		else if (tmp2.dot(ao) > GjkEpaSolver.GJK_insimplex_eps) 
		{
			crs.fromVector3f(tmp2);
			order = 2;
			simplex[2].set(simplex[3]);
			return SolveSimplex3a(ao, ac, ad, crs);
		} 
		else if (tmp3.dot(ao) > GjkEpaSolver.GJK_insimplex_eps) 
		{
			crs.fromVector3f(tmp3);
			order = 2;
			simplex[1].set(simplex[0]);
			simplex[0].set(simplex[2]);
			simplex[2].set(simplex[3]);
			return SolveSimplex3a(ao, ad, ab, crs);
		} 
		else
		{
			return true;
		}
	}

	public function SearchOrigin( initray:Vector3f = null):Bool
	{
		if (initray == null)
			initray = new Vector3f(1, 0, 0);
			
		var tmp1:Vector3f = new Vector3f();
		var tmp2:Vector3f = new Vector3f();
		var tmp3:Vector3f = new Vector3f();
		var tmp4:Vector3f = new Vector3f();

		order = -1;
		failed = false;
		ray.fromVector3f(initray);
		ray.normalize();

		for (i in 0...table.length)
		{
			table[i] = null;
		}

		FetchSupport();
		ray.negate(simplex[0].w);
		for (iterations in 0...GjkEpaSolver.GJK_maxiterations)
		{
			var rl:Float = ray.length();
			ray.scale(1 / (rl > 0 ? rl : 1));
			if (FetchSupport()) 
			{
				var found:Bool = false;
				switch (order) 
				{
					case 1: {
						tmp1.negate(simplex[1].w);
						tmp2.sub(simplex[0].w, simplex[1].w);
						found = SolveSimplex2(tmp1, tmp2);
					}
					case 2: {
						tmp1.negate(simplex[2].w);
						tmp2.sub(simplex[1].w, simplex[2].w);
						tmp3.sub(simplex[0].w, simplex[2].w);
						found = SolveSimplex3(tmp1, tmp2, tmp3);
					}
					case 3: {
						tmp1.negate(simplex[3].w);
						tmp2.sub(simplex[2].w, simplex[3].w);
						tmp3.sub(simplex[1].w, simplex[3].w);
						tmp4.sub(simplex[0].w, simplex[3].w);
						found = SolveSimplex4(tmp1, tmp2, tmp3, tmp4);
					}
				}
				if (found) 
				{
					return true;
				}
			} 
			else 
			{
				return false;
			}
		}
		failed = true;
		return false;
	}

	public function EncloseOrigin():Bool
	{
		var tmp:Vector3f = new Vector3f();
		var tmp1:Vector3f = new Vector3f();
		var tmp2:Vector3f = new Vector3f();

		switch (order)
		{
			// Point
			case 0:
			// Line
			case 1: {
				var ab:Vector3f = new Vector3f();
				ab.sub(simplex[1].w, simplex[0].w);

				var b:Array<Vector3f> = [new Vector3f(), new Vector3f(), new Vector3f()];
				b[0].setTo(1, 0, 0);
				b[1].setTo(0, 1, 0);
				b[2].setTo(0, 0, 1);

				b[0].cross(ab, b[0]);
				b[1].cross(ab, b[1]);
				b[2].cross(ab, b[2]);

				var m:Array<Float> = [b[0].lengthSquared(), b[1].lengthSquared(), b[2].lengthSquared()];

				var tmpQuat:Quat4f = new Quat4f();
				tmp.normalize(ab);
				QuaternionUtil.setRotation(tmpQuat, tmp, GjkEpaSolver.cst2Pi / 3);

				var r:Matrix3f = new Matrix3f();
				MatrixUtil.setRotation(r, tmpQuat);

				var w:Vector3f = new Vector3f();
				w.fromVector3f(b[m[0] > m[1] ? m[0] > m[2] ? 0 : 2 : m[1] > m[2] ? 1 : 2]);

				tmp.normalize(w);
				Support(tmp, simplex[4]);
				r.transform(w);
				tmp.normalize(w);
				Support(tmp, simplex[2]);
				r.transform(w);
				tmp.normalize(w);
				Support(tmp, simplex[3]);
				r.transform(w);
				order = 4;
				return (true);
			}
			// Triangle
			case 2: {
				tmp1.sub(simplex[1].w, simplex[0].w);
				tmp2.sub(simplex[2].w, simplex[0].w);
				var n:Vector3f = new Vector3f();
				n.cross(tmp1, tmp2);
				n.normalize();

				Support(n, simplex[3]);

				tmp.negate(n);
				Support(tmp, simplex[4]);
				order = 4;
				return (true);
			}
			// Tetrahedron
			case 3:
				return (true);
			// Hexahedron
			case 4:
				return (true);
		}
		return (false);
	}
}


enum ResultsStatus 
{
	Separated;		/* Shapes doesnt penetrate												*/
	Penetrating;	/* Shapes are penetrating												*/
	GJK_Failed;		/* GJK phase fail, no big issue, shapes are probably just 'touching'	*/
	EPA_Failed;		/* EPA phase fail, bigger problem, need to save parameters, and debug	*/
}

class Results 
{
	public var status:ResultsStatus;
	public var witnesses:Array<Vector3f> = [new Vector3f(), new Vector3f()];
	public var normal:Vector3f = new Vector3f();
	public var depth:Float;
	public var epa_iterations:Int;
	public var gjk_iterations:Int;
}
	
class Face 
{
	public var v:Array<Mkv> = [null,null,null];
	public var f:Array<Face> = [null,null,null];
	public var e:Array<Int> = [0,0,0];
	public var n:Vector3f = new Vector3f();
	public var d:Float;
	public var mark:Int;
	public var prev:Face;
	public var next:Face;
}

class EPA 
{
	public var gjk:GJK;
	public var root:Face;
	public var nfaces:Int;
	public var iterations:Int;
	public var features:Array<Array<Vector3f>>;
	public var nearest:Array<Vector3f> = [new Vector3f(), new Vector3f()];
	public var normal:Vector3f = new Vector3f();
	public var depth:Float;
	public var failed:Bool;
	public var solver:GjkEpaSolver;
	public function new(solver:GjkEpaSolver,pgjk:GJK)
	{
		this.solver = solver;
		gjk = pgjk;
		
		features = new Array<Array<Vector3f>>();
		for (i in 0...2) 
		{
			features[i] = [];
			for (j in 0...3)
			{
				features[i][j] = new Vector3f();
			}
		}
	}

	public function GetCoordinates(face:Face, out:Vector3f):Vector3f
	{
		var tmp:Vector3f = new Vector3f();
		var tmp1:Vector3f = new Vector3f();
		var tmp2:Vector3f = new Vector3f();

		var o:Vector3f = new Vector3f();
		o.scale(-face.d, face.n);

		var a:Array<Float> = [];

		tmp1.sub(face.v[0].w, o);
		tmp2.sub(face.v[1].w, o);
		tmp.cross(tmp1, tmp2);
		a[0] = tmp.length();

		tmp1.sub(face.v[1].w, o);
		tmp2.sub(face.v[2].w, o);
		tmp.cross(tmp1, tmp2);
		a[1] = tmp.length();

		tmp1.sub(face.v[2].w, o);
		tmp2.sub(face.v[0].w, o);
		tmp.cross(tmp1, tmp2);
		a[2] = tmp.length();

		var sm:Float = a[0] + a[1] + a[2];

		out.setTo(a[1], a[2], a[0]);
		out.scale(1 / (sm > 0 ? sm : 1));

		return out;
	}

	public function FindBest():Face
	{
		var bf:Face = null;
		if (root != null) 
		{
			var cf:Face = root;
			var bd:Float = GjkEpaSolver.cstInf;
			do
			{
				if (cf.d < bd) 
				{
					bd = cf.d;
					bf = cf;
				}
			}
			while (null != (cf = cf.next));
		}
		return bf;
	}

	public function Set(f:Face, a:Mkv, b:Mkv, c:Mkv):Bool
	{
		var tmp1:Vector3f = new Vector3f();
		var tmp2:Vector3f = new Vector3f();
		var tmp3:Vector3f = new Vector3f();

		var nrm:Vector3f = new Vector3f();
		tmp1.sub(b.w, a.w);
		tmp2.sub(c.w, a.w);
		nrm.cross(tmp1, tmp2);

		var len:Float = nrm.length();

		tmp1.cross(a.w, b.w);
		tmp2.cross(b.w, c.w);
		tmp3.cross(c.w, a.w);

		var valid:Bool = (tmp1.dot(nrm) >= -GjkEpaSolver.EPA_inface_eps) &&
				(tmp2.dot(nrm) >= -GjkEpaSolver.EPA_inface_eps) &&
				(tmp3.dot(nrm) >= -GjkEpaSolver.EPA_inface_eps);

		f.v[0] = a;
		f.v[1] = b;
		f.v[2] = c;
		f.mark = 0;
		f.n.scale(1 / (len > 0 ? len : GjkEpaSolver.cstInf), nrm);
		f.d = Math.max(0, -f.n.dot(a.w));
		return valid;
	}

	public function NewFace(a:Mkv, b:Mkv, c:Mkv):Face
	{
		//Face pf = new Face();
		var pf:Face = solver.stackFace.get();
		if (Set(pf, a, b, c))
		{
			if (root != null) 
			{
				root.prev = pf;
			}
			pf.prev = null;
			pf.next = root;
			root = pf;
			++nfaces;
		} 
		else
		{
			pf.prev = pf.next = null;
		}
		return (pf);
	}

	public function Detach(face:Face):Void
	{
		if (face.prev != null || face.next != null) 
		{
			--nfaces;
			if (face == root) 
			{
				root = face.next;
				root.prev = null;
			}
			else 
			{
				if (face.next == null) 
				{
					face.prev.next = null;
				} 
				else
				{
					face.prev.next = face.next;
					face.next.prev = face.prev;
				}
			}
			face.prev = face.next = null;
		}
	}

	public function Link(f0:Face, e0:Int, f1:Face, e1:Int):Void
	{
		f0.f[e0] = f1;
		f1.e[e1] = e0;
		f1.f[e1] = f0;
		f0.e[e0] = e1;
	}

	public function Support(w:Vector3f):Mkv
	{
		//Mkv v = new Mkv();
		var v:Mkv = solver.stackMkv.get();
		gjk.Support(w, v);
		return v;
	}

	public function BuildHorizon(markid:Int, w:Mkv, f:Face, e:Int, cf:Array<Face>, ff:Array<Face>):Int
	{
		var ne:Int = 0;
		if (f.mark != markid) 
		{
			var e1:Int = GjkEpaSolver.mod3[e + 1];
			if ((f.n.dot(w.w) + f.d) > 0) 
			{
				var nf:Face = NewFace(f.v[e1], f.v[e], w);
				Link(nf, 0, f, e);
				if (cf[0] != null)
				{
					Link(cf[0], 1, nf, 2);
				} 
				else 
				{
					ff[0] = nf;
				}
				cf[0] = nf;
				ne = 1;
			} 
			else
			{
				var e2:Int = GjkEpaSolver.mod3[e + 2];
				Detach(f);
				f.mark = markid;
				ne += BuildHorizon(markid, w, f.f[e1], f.e[e1], cf, ff);
				ne += BuildHorizon(markid, w, f.f[e2], f.e[e2], cf, ff);
			}
		}
		return (ne);
	}

	public function EvaluatePD(accuracy:Float=0.001):Float
	{
		solver.pushStack();
		
		var tmp:Vector3f = new Vector3f();

		//btBlock* sablock = sa->beginBlock();
		var bestface:Face = null;
		var markid:Int = 1;
		depth = -GjkEpaSolver.cstInf;
		normal.setTo(0, 0, 0);
		root = null;
		nfaces = 0;
		iterations = 0;
		failed = false;
		/* Prepare hull		*/
		if (gjk.EncloseOrigin())
		{
			//const U* pfidx = 0;
			var pfidx_ptr:Array<Array<Int>> = null;
			var pfidx_index:Int = 0;

			var nfidx:Int = 0;
			//const U* peidx = 0;
			var peidx_ptr:Array<Array<Int>> = null;
			var peidx_index:Int = 0;

			var neidx:Int = 0;
			var basemkv:Vector<Mkv> = new Vector<Mkv>(5);
			var basefaces:Vector<Face> = new Vector<Face>(6);
			switch (gjk.order) 
			{
				// Tetrahedron
				case 3: {
					//pfidx=(const U*)fidx;
					pfidx_ptr = GjkEpaSolver.tetrahedron_fidx;
					pfidx_index = 0;

					nfidx = 4;

					//peidx=(const U*)eidx;
					peidx_ptr = GjkEpaSolver.tetrahedron_eidx;
					peidx_index = 0;

					neidx = 6;
				}
				// Hexahedron
				case 4: {
					//pfidx=(const U*)fidx;
					pfidx_ptr = GjkEpaSolver.hexahedron_fidx;
					pfidx_index = 0;

					nfidx = 6;

					//peidx=(const U*)eidx;
					peidx_ptr = GjkEpaSolver.hexahedron_eidx;
					peidx_index = 0;

					neidx = 9;
				}
			}

			for (i in 0...(gjk.order + 1))
			{
				basemkv[i] = new Mkv();
				basemkv[i].set(gjk.simplex[i]);
			}
			
			var i = 0;
			while (i < nfidx)
			{
				basefaces[i] = NewFace(basemkv[pfidx_ptr[pfidx_index][0]], 
									basemkv[pfidx_ptr[pfidx_index][1]], 
									basemkv[pfidx_ptr[pfidx_index][2]]);
				
				++i;
				pfidx_index++;
			}
			
			i = 0;
			while (i < neidx)
			{
				Link(basefaces[peidx_ptr[peidx_index][0]], peidx_ptr[peidx_index][1], 
					basefaces[peidx_ptr[peidx_index][2]], peidx_ptr[peidx_index][3]);
				
				++i;
				peidx_index++;
			}
		}
		
		if (0 == nfaces)
		{
			//sa->endBlock(sablock);
			solver.popStack();
			return (depth);
		}
		
		/* Expand hull		*/
		while (iterations < GjkEpaSolver.EPA_maxiterations) 
		{
			var bf:Face = FindBest();
			if (bf != null)
			{
				tmp.negate(bf.n);
				var w:Mkv = Support(tmp);
				var d:Float = bf.n.dot(w.w) + bf.d;
				bestface = bf;
				if (d < -accuracy)
				{
					var cf:Array<Face> = [null];
					var ff:Array<Face> = [null];
					var nf:Int = 0;
					Detach(bf);
					bf.mark = ++markid;
					for (i in 0...3)
					{
						nf += BuildHorizon(markid, w, bf.f[i], bf.e[i], cf, ff);
					}
					if (nf <= 2)
					{
						break;
					}
					Link(cf[0], 1, ff[0], 2);
				} 
				else
				{
					break;
				}
			} 
			else 
			{
				break;
			}
			
			++iterations;
		}
		
		/* Extract contact	*/
		if (bestface != null)
		{
			var b:Vector3f = GetCoordinates(bestface, new Vector3f());
			normal.fromVector3f(bestface.n);
			depth = Math.max(0, bestface.d);
			for (i in 0...2)
			{
				var s:Float = i != 0 ? -1 : 1;
				for (j in 0...3)
				{
					tmp.scale(s, bestface.v[j].r);
					gjk.LocalSupport(tmp, i, features[i][j]);
				}
			}

			var tmp1:Vector3f = new Vector3f();
			var tmp2:Vector3f = new Vector3f();
			var tmp3:Vector3f = new Vector3f();

			tmp1.scale(b.x, features[0][0]);
			tmp2.scale(b.y, features[0][1]);
			tmp3.scale(b.z, features[0][2]);
			VectorUtil.add3(nearest[0], tmp1, tmp2, tmp3);

			tmp1.scale(b.x, features[1][0]);
			tmp2.scale(b.y, features[1][1]);
			tmp3.scale(b.z, features[1][2]);
			VectorUtil.add3(nearest[1], tmp1, tmp2, tmp3);
		} 
		else
		{
			failed = true;
		}
		//sa->endBlock(sablock);
		
		solver.popStack();
		return (depth);

	}

}
