package com.bulletphysics.linearmath.convexhull;
import org.angle3d.error.Assert;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;


/**
 * HullLibrary class can create a convex hull from a collection of vertices, using
 * the ComputeHull method. The {ShapeHull} class uses this HullLibrary to create
 * a approximate convex mesh given a general (non-polyhedral) convex shape.
 * 
 
 */
class HullLibrary
{
	public var vertexIndexMapping:IntArrayList = new IntArrayList();

    private var tris:ObjectArrayList<Tri> = new ObjectArrayList<Tri>();
	
	public function new()
	{
		
	}

    /**
     * Converts point cloud to polygonal representation.
     *
     * @param desc   describes the input request
     * @param result contains the result
     * @return whether conversion was successful
     */
    public function createConvexHull(desc:HullDesc, result:HullResult):Bool
	{
        var ret:Bool = false;

        var hr:PHullResult = new PHullResult();

        var vcount:Int = desc.vcount;
        if (vcount < 8) vcount = 8;

        var vertexSource:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>();
        vertexSource.resize(vcount, Vector3f);

        var scale:Vector3f = new Vector3f();

        var ovcount:Array<Int> = new Array<Int>(1);

        var ok:Bool = cleanupVertices(desc.vcount, desc.vertices, desc.vertexStride, ovcount, vertexSource, desc.normalEpsilon, scale); // normalize point cloud, remove duplicates!

        if (ok)
		{
            //		if ( 1 ) // scale vertices back to their original size.
            {
                for (i in 0...ovcount[0])
				{
                    var v:Vector3f = vertexSource.getQuick(i);
                    LinearMathUtil.mul(v, v, scale);
                }
            }

            ok = computeHull(ovcount[0], vertexSource, hr, desc.maxVertices);

            if (ok)
			{
                // re-index triangle mesh so it refers to only used vertices, rebuild a new vertex table.
                var vertexScratch:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>();
                vertexScratch.resize(hr.vcount, Vector3f);

                bringOutYourDead(hr.vertices, hr.vcount, vertexScratch, ovcount, hr.indices, hr.indexCount);

                ret = true;

				// if he wants the results as triangle!
                if (desc.hasHullFlag(HullFlags.TRIANGLES)) 
				{ 
                    result.polygons = false;
                    result.numOutputVertices = ovcount[0];
                    result.outputVertices.resize(ovcount[0], Vector3f);
                    result.numFaces = hr.faceCount;
                    result.numIndices = hr.indexCount;

                    MiscUtil.resizeIntArrayList(result.indices, hr.indexCount, 0);

                    for (i in 0...ovcount[0]) 
					{
                        result.outputVertices.getQuick(i).copyFrom(vertexScratch.getQuick(i));
                    }

                    if (desc.hasHullFlag(HullFlags.REVERSE_ORDER))
					{
                        var source_ptr:IntArrayList = hr.indices;
                        var source_idx:Int = 0;

                        var dest_ptr:IntArrayList = result.indices;
                        var dest_idx:Int = 0;

                        for (i in 0...hr.faceCount)
						{
                            dest_ptr.set(dest_idx + 0, source_ptr.get(source_idx + 2));
                            dest_ptr.set(dest_idx + 1, source_ptr.get(source_idx + 1));
                            dest_ptr.set(dest_idx + 2, source_ptr.get(source_idx + 0));
                            dest_idx += 3;
                            source_idx += 3;
                        }
                    }
					else
					{
                        for (i in 0...hr.indexCount) 
						{
                            result.indices.set(i, hr.indices.get(i));
                        }
                    }
                } 
				else
				{
                    result.polygons = true;
                    result.numOutputVertices = ovcount[0];
                    result.outputVertices.resize(ovcount[0], Vector3f);
                    result.numFaces = hr.faceCount;
                    result.numIndices = hr.indexCount + hr.faceCount;
                    MiscUtil.resizeIntArrayList(result.indices, result.numIndices, 0);
                    for (i in 0...ovcount[0]) 
					{
                        result.outputVertices.getQuick(i).copyFrom(vertexScratch.getQuick(i));
                    }

                    //if ( 1 )
                    {
                        var source_ptr:IntArrayList = hr.indices;
                        var source_idx:Int = 0;

                        var dest_ptr:IntArrayList = result.indices;
                        var dest_idx:Int = 0;

                        for (i in 0...hr.faceCount) 
						{
                            dest_ptr.set(dest_idx + 0, 3);
                            if (desc.hasHullFlag(HullFlags.REVERSE_ORDER))
							{
                                dest_ptr.set(dest_idx + 1, source_ptr.get(source_idx + 2));
                                dest_ptr.set(dest_idx + 2, source_ptr.get(source_idx + 1));
                                dest_ptr.set(dest_idx + 3, source_ptr.get(source_idx + 0));
                            } 
							else 
							{
                                dest_ptr.set(dest_idx + 1, source_ptr.get(source_idx + 0));
                                dest_ptr.set(dest_idx + 2, source_ptr.get(source_idx + 1));
                                dest_ptr.set(dest_idx + 3, source_ptr.get(source_idx + 2));
                            }

                            dest_idx += 4;
                            source_idx += 3;
                        }
                    }
                }
                releaseHull(hr);
            }
        }

        return ret;
    }

    /**
     * Release memory allocated for this result, we are done with it.
     */
    public function releaseResult(result:HullResult):Bool
	{
        if (result.outputVertices.size() != 0)
		{
            result.numOutputVertices = 0;
            result.outputVertices.clear();
        }
        if (result.indices.size() != 0)
		{
            result.numIndices = 0;
            result.indices.clear();
        }
        return true;
    }

    private function computeHull(vcount:Int, vertices:ObjectArrayList<Vector3f>, result:PHullResult, vlimit:Int):Bool
	{
        var tris_count:Array<Int> = new Array<Int>(1);
        var ret:Int = calchull(vertices, vcount, result.indices, tris_count, vlimit);
        if (ret == 0) 
			return false;
        result.indexCount = tris_count[0] * 3;
        result.faceCount = tris_count[0];
        result.vertices = vertices;
        result.vcount = vcount;
        return true;
    }

    private function allocateTriangle(a:Int, b:Int, c:Int):Tri
	{
        var tr:Tri = new Tri(a, b, c);
        tr.id = tris.size();
        tris.add(tr);

        return tr;
    }

    private function deAllocateTriangle( tri:Tri):Void
	{
        Assert.assert (tris.getQuick(tri.id) == tri);
        tris.setQuick(tri.id, null);
    }

    private function b2bfix( s:Tri, t:Tri):Void
	{
        for (i in 0...3)
		{
            var i1:Int = (i + 1) % 3;
            var i2:Int = (i + 2) % 3;
            var a:Int = s.getCoord(i1);
            var b:Int = s.getCoord(i2);
            Assert.assert (tris.getQuick(s.neib(a, b).get()).neib(b, a).get() == s.id);
            Assert.assert (tris.getQuick(t.neib(a, b).get()).neib(b, a).get() == t.id);
            tris.getQuick(s.neib(a, b).get()).neib(b, a).set(t.neib(b, a).get());
            tris.getQuick(t.neib(b, a).get()).neib(a, b).set(s.neib(a, b).get());
        }
    }

    private function removeb2b(s:Tri, t:Tri):Void
	{
        b2bfix(s, t);
        deAllocateTriangle(s);

        deAllocateTriangle(t);
    }

    private function checkit(t:Tri):Void
	{
        Assert.assert (tris.getQuick(t.id) == t);
        for (i in 0...3)
		{
            var i1:Int = (i + 1) % 3;
            var i2:Int = (i + 2) % 3;
            var a:Int = t.getCoord(i1);
            var b:Int = t.getCoord(i2);

            Assert.assert (a != b);
            Assert.assert (tris.getQuick(t.n.getCoord(i)).neib(b, a).get() == t.id);
        }
    }

    private function extrudable(epsilon:Float):Tri
	{
        var t:Tri = null;
        for (i in 0...tris.size()) 
		{
            if (t == null || (tris.getQuick(i) != null && t.rise < tris.getQuick(i).rise)) {
                t = tris.getQuick(i);
            }
        }
        return (t.rise > epsilon) ? t : null;
    }

    private function calchull(verts:ObjectArrayList<Vector3f>, verts_count:Int, 
							tris_out:IntArrayList, tris_count:Array<Int>, vlimit:Int):Int
	{
        var rc:Int = calchullgen(verts, verts_count, vlimit);
        if (rc == 0) return 0;

        var ts:IntArrayList = new IntArrayList();

        for (i in 0...tris.size())
		{
            if (tris.getQuick(i) != null) 
			{
                for (j in 0...3)
				{
                    ts.add((tris.getQuick(i)).getCoord(j));
                }
                deAllocateTriangle(tris.getQuick(i));
            }
        }
        tris_count[0] = Std.int(ts.size() / 3);
        MiscUtil.resizeIntArrayList(tris_out, ts.size(), 0);

        for (i in 0...ts.size()) 
		{
            tris_out.set(i, ts.get(i));
        }
        tris.resize(0, Tri);

        return 1;
    }

    private function calchullgen(verts:ObjectArrayList<Vector3f>, verts_count:Int, vlimit:Int):Int
	{
        if (verts_count < 4) return 0;

        var tmp:Vector3f = new Vector3f();
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        if (vlimit == 0)
		{
            vlimit = 1000000000;
        }
        //int j;
        var bmin:Vector3f = verts.getQuick(0).clone();
        var bmax:Vector3f = verts.getQuick(0).clone();
        var isextreme:IntArrayList = new IntArrayList();
        //isextreme.reserve(verts_count);
        var allow:IntArrayList = new IntArrayList();
        //allow.reserve(verts_count);

        for (j in 0...verts_count) 
		{
            allow.add(1);
            isextreme.add(0);
            LinearMathUtil.setMin(bmin, verts.getQuick(j));
            LinearMathUtil.setMax(bmax, verts.getQuick(j));
        }
        tmp.subtractBy(bmax, bmin);
        var epsilon:Float = tmp.length * 0.001;
        Assert.assert (epsilon != 0);

        var p:Int4 = findSimplex(verts, verts_count, allow, new Int4());
        if (p.x == -1)
		{
            return 0; // simplex failed

            // a valid interior point
        }
        var center:Vector3f = new Vector3f();
        LinearMathUtil.add4(center, verts.getQuick(p.getCoord(0)), verts.getQuick(p.getCoord(1)), verts.getQuick(p.getCoord(2)), verts.getQuick(p.getCoord(3)));
        center.scaleLocal(1 / 4);

        var t0:Tri = allocateTriangle(p.getCoord(2), p.getCoord(3), p.getCoord(1));
        t0.n.setTo(2, 3, 1);
        var t1:Tri = allocateTriangle(p.getCoord(3), p.getCoord(2), p.getCoord(0));
        t1.n.setTo(3, 2, 0);
        var t2:Tri = allocateTriangle(p.getCoord(0), p.getCoord(1), p.getCoord(3));
        t2.n.setTo(0, 1, 3);
        var t3:Tri = allocateTriangle(p.getCoord(1), p.getCoord(0), p.getCoord(2));
        t3.n.setTo(1, 0, 2);
        isextreme.set(p.getCoord(0), 1);
        isextreme.set(p.getCoord(1), 1);
        isextreme.set(p.getCoord(2), 1);
        isextreme.set(p.getCoord(3), 1);
        checkit(t0);
        checkit(t1);
        checkit(t2);
        checkit(t3);

        var n:Vector3f = new Vector3f();

        for (j in 0...tris.size())
		{
            var t:Tri = tris.getQuick(j);
            Assert.assert (t != null);
            Assert.assert (t.vmax < 0);
            triNormal(verts.getQuick(t.getCoord(0)), verts.getQuick(t.getCoord(1)), verts.getQuick(t.getCoord(2)), n);
            t.vmax = maxdirsterid(verts, verts_count, n, allow);
            tmp.subtractBy(verts.getQuick(t.vmax), verts.getQuick(t.getCoord(0)));
            t.rise = n.dot(tmp);
        }
        var te:Tri;
        vlimit -= 4;
        while (vlimit > 0 && ((te = extrudable(epsilon)) != null))
		{
            var ti:Int3 = te;
            var v:Int = te.vmax;
            Assert.assert (v != -1);
            Assert.assert (isextreme.get(v) == 0);  // wtf we've already done this vertex
            isextreme.set(v, 1);
            //if(v==p0 || v==p1 || v==p2 || v==p3) continue; // done these already
            var j:Int = tris.size();
            while ((j--) != 0)
			{
                if (tris.getQuick(j) == null) 
				{
                    continue;
                }
                var t:Int3 = tris.getQuick(j);
                if (above(verts, t, verts.getQuick(v), 0.01 * epsilon))
				{
                    extrude(tris.getQuick(j), v);
                }
            }
            // now check for those degenerate cases where we have a flipped triangle or a really skinny triangle
            j = tris.size();
            while ((j--) != 0) 
			{
                if (tris.getQuick(j) == null) 
				{
                    continue;
                }
                if (!hasvert(tris.getQuick(j), v)) 
				{
                    break;
                }
                var nt:Int3 = tris.getQuick(j);
                tmp1.subtractBy(verts.getQuick(nt.getCoord(1)), verts.getQuick(nt.getCoord(0)));
                tmp2.subtractBy(verts.getQuick(nt.getCoord(2)), verts.getQuick(nt.getCoord(1)));
                tmp.crossBy(tmp1, tmp2);
                if (above(verts, nt, center, 0.01 * epsilon) || tmp.length < epsilon * epsilon * 0.1) 
				{
                    var nb:Tri = tris.getQuick(tris.getQuick(j).n.getCoord(0));
                    Assert.assert (nb != null);
                    Assert.assert (!hasvert(nb, v));
                    Assert.assert (nb.id < j);
                    extrude(nb, v);
                    j = tris.size();
                }
            }
            j = tris.size();
            while ((j--) != 0)
			{
                var t:Tri = tris.getQuick(j);
                if (t == null)
				{
                    continue;
                }
                if (t.vmax >= 0) 
				{
                    break;
                }
                triNormal(verts.getQuick(t.getCoord(0)), verts.getQuick(t.getCoord(1)), verts.getQuick(t.getCoord(2)), n);
                t.vmax = maxdirsterid(verts, verts_count, n, allow);
                if (isextreme.get(t.vmax) != 0)
				{
                    t.vmax = -1; // already done that vertex - algorithm needs to be able to terminate.
                } 
				else 
				{
                    tmp.subtractBy(verts.getQuick(t.vmax), verts.getQuick(t.getCoord(0)));
                    t.rise = n.dot(tmp);
                }
            }
            vlimit--;
        }
        return 1;
    }

    private function findSimplex(verts:ObjectArrayList<Vector3f>, verts_count:Int, allow:IntArrayList, out:Int4):Int4
	{
        var tmp:Vector3f = new Vector3f();
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        var basis:Array<Vector3f> = [new Vector3f(), new Vector3f(), new Vector3f()];
        basis[0].setTo(0.01, 0.02, 1.0);
        var p0:Int = maxdirsterid(verts, verts_count, basis[0], allow);
        tmp.negateBy(basis[0]);
        var p1:Int = maxdirsterid(verts, verts_count, tmp, allow);
        basis[0].subtractBy(verts.getQuick(p0), verts.getQuick(p1));
        if (p0 == p1 || (basis[0].x == 0 && basis[0].y == 0 && basis[0].z == 0))
		{
            out.setTo(-1, -1, -1, -1);
            return out;
        }
        tmp.setTo(1, 0.02, 0);
        basis[1].crossBy(tmp, basis[0]);
        tmp.setTo(-0.02, 1, 0);
        basis[2].crossBy(tmp, basis[0]);
        if (basis[1].length > basis[2].length)
		{
            basis[1].normalizeLocal();
        } 
		else
		{
            basis[1].copyFrom(basis[2]);
            basis[1].normalizeLocal();
        }
        var p2:Int = maxdirsterid(verts, verts_count, basis[1], allow);
        if (p2 == p0 || p2 == p1) 
		{
            tmp.negateBy(basis[1]);
            p2 = maxdirsterid(verts, verts_count, tmp, allow);
        }
        if (p2 == p0 || p2 == p1) 
		{
            out.setTo(-1, -1, -1, -1);
            return out;
        }
        basis[1].subtractBy(verts.getQuick(p2), verts.getQuick(p0));
        basis[2].crossBy(basis[1], basis[0]);
        basis[2].normalizeLocal();
        var p3:Int = maxdirsterid(verts, verts_count, basis[2], allow);
        if (p3 == p0 || p3 == p1 || p3 == p2) 
		{
            tmp.negateBy(basis[2]);
            p3 = maxdirsterid(verts, verts_count, tmp, allow);
        }
        if (p3 == p0 || p3 == p1 || p3 == p2) 
		{
            out.setTo(-1, -1, -1, -1);
            return out;
        }
        Assert.assert (!(p0 == p1 || p0 == p2 || p0 == p3 || p1 == p2 || p1 == p3 || p2 == p3));

        tmp1.subtractBy(verts.getQuick(p1), verts.getQuick(p0));
        tmp2.subtractBy(verts.getQuick(p2), verts.getQuick(p0));
        tmp2.crossBy(tmp1, tmp2);
        tmp1.subtractBy(verts.getQuick(p3), verts.getQuick(p0));
        if (tmp1.dot(tmp2) < 0)
		{
            var swap_tmp:Int = p2;
            p2 = p3;
            p3 = swap_tmp;
        }
        out.setTo(p0, p1, p2, p3);
        return out;
    }

    //private ConvexH convexHCrop(ConvexH convex,Plane slice);

    private function extrude(t0:Tri, v:Int):Void
	{
        var t:Int3 = new Int3();
		t.fromInt3(t0);
        var n:Int = tris.size();
        var ta:Tri = allocateTriangle(v, t.getCoord(1), t.getCoord(2));
        ta.n.setTo(t0.n.getCoord(0), n + 1, n + 2);
        tris.getQuick(t0.n.getCoord(0)).neib(t.getCoord(1), t.getCoord(2)).set(n + 0);
        var tb:Tri = allocateTriangle(v, t.getCoord(2), t.getCoord(0));
        tb.n.setTo(t0.n.getCoord(1), n + 2, n + 0);
        tris.getQuick(t0.n.getCoord(1)).neib(t.getCoord(2), t.getCoord(0)).set(n + 1);
        var tc:Tri = allocateTriangle(v, t.getCoord(0), t.getCoord(1));
        tc.n.setTo(t0.n.getCoord(2), n + 0, n + 1);
        tris.getQuick(t0.n.getCoord(2)).neib(t.getCoord(0), t.getCoord(1)).set(n + 2);
        checkit(ta);
        checkit(tb);
        checkit(tc);
        if (hasvert(tris.getQuick(ta.n.getCoord(0)), v))
		{
            removeb2b(ta, tris.getQuick(ta.n.getCoord(0)));
        }
        if (hasvert(tris.getQuick(tb.n.getCoord(0)), v)) 
		{
            removeb2b(tb, tris.getQuick(tb.n.getCoord(0)));
        }
        if (hasvert(tris.getQuick(tc.n.getCoord(0)), v))
		{
            removeb2b(tc, tris.getQuick(tc.n.getCoord(0)));
        }
        deAllocateTriangle(t0);
    }

    //private ConvexH test_cube();

    //BringOutYourDead (John Ratcliff): When you create a convex hull you hand it a large input set of vertices forming a 'point cloud'.
    //After the hull is generated it give you back a set of polygon faces which index the *original* point cloud.
    //The thing is, often times, there are many 'dead vertices' in the point cloud that are on longer referenced by the hull.
    //The routine 'BringOutYourDead' find only the referenced vertices, copies them to an new buffer, and re-indexes the hull so that it is a minimal representation.
    private function bringOutYourDead(verts:ObjectArrayList<Vector3f>, vcount:Int, overts:ObjectArrayList<Vector3f>, ocount:Array<Int>, indices:IntArrayList, indexcount:Int):Void
	{
        var tmpIndices:IntArrayList = new IntArrayList();
        for (i in 0...vertexIndexMapping.size())
		{
            tmpIndices.add(vertexIndexMapping.size());
        }

        var usedIndices:IntArrayList = new IntArrayList();
        MiscUtil.resizeIntArrayList(usedIndices, vcount, 0);
        /*
        JAVA NOTE: redudant
		for (int i=0; i<vcount; i++) {
		usedIndices.set(i, 0);
		}
		*/

        ocount[0] = 0;

        for (i in 0...indexcount) 
		{
            var v:Int = indices.get(i); // original array index

            Assert.assert (v >= 0 && v < vcount);

            if (usedIndices.get(v) != 0)
			{ 
				// if already remapped
                indices.set(i, usedIndices.get(v) - 1); // index to new array
            }
			else 
			{
                indices.set(i, ocount[0]);      // new index mapping

                overts.getQuick(ocount[0]).copyFrom(verts.getQuick(v)); // copy old vert to new vert array

                for (k in 0...vertexIndexMapping.size())
				{
                    if (tmpIndices.get(k) == v) 
					{
                        vertexIndexMapping.set(k, ocount[0]);
                    }
                }

                ocount[0] = ocount[0] + 1; // increment output vert count

                Assert.assert (ocount[0] >= 0 && ocount[0] <= vcount);

                usedIndices.set(v, ocount[0]); // assign new index remapping
            }
        }
    }

    private static inline var EPSILON:Float = 0.000001; /* close enough to consider two btScalaring point numbers to be 'the same'. */

    private function cleanupVertices(svcount:Int,
                                    svertices:ObjectArrayList<Vector3f>,
                                    stride:Int,
                                    vcount:Array<Int>, // output number of vertices
                                    vertices:ObjectArrayList<Vector3f>, // location to store the results.
                                    normalepsilon:Float,
                                    scale:Vector3f):Bool
	{

        if (svcount == 0)
		{
            return false;
        }

        vertexIndexMapping.clear();

        vcount[0] = 0;

        var recip:Array<Float> = new Array<Float>(3);

        if (scale != null)
		{
            scale.setTo(1, 1, 1);
        }

        var bmin:Array<Float> = [FastMath.POSITIVE_INFINITY, FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY];
        var bmax:Array<Float> = [FastMath.NEGATIVE_INFINITY, FastMath.NEGATIVE_INFINITY, FastMath.NEGATIVE_INFINITY];

        var vtx_ptr:ObjectArrayList<Vector3f> = svertices;
        var vtx_idx:Int = 0;

        //	if ( 1 )
        {
            for (i in 0...svcount) 
			{
                var p:Vector3f = vtx_ptr.getQuick(vtx_idx);

                vtx_idx +=/*stride*/ 1;

                for (j in 0...3)
				{
                    if (LinearMathUtil.getCoord(p, j) < bmin[j])
					{
                        bmin[j] = LinearMathUtil.getCoord(p, j);
                    }
                    if (LinearMathUtil.getCoord(p, j) > bmax[j])
					{
                        bmax[j] = LinearMathUtil.getCoord(p, j);
                    }
                }
            }
        }

        var dx:Float = bmax[0] - bmin[0];
        var dy:Float = bmax[1] - bmin[1];
        var dz:Float = bmax[2] - bmin[2];

        var center:Vector3f = new Vector3f();

        center.x = dx * 0.5 + bmin[0];
        center.y = dy * 0.5 + bmin[1];
        center.z = dz * 0.5 + bmin[2];

        if (dx < EPSILON || dy < EPSILON || dz < EPSILON || svcount < 3)
		{

            var len:Float = FastMath.POSITIVE_INFINITY;

            if (dx > EPSILON && dx < len) len = dx;
            if (dy > EPSILON && dy < len) len = dy;
            if (dz > EPSILON && dz < len) len = dz;

            if (len == FastMath.POSITIVE_INFINITY)
			{
                dx = dy = dz = 0.01; // one centimeter
            } 
			else 
			{
                if (dx < EPSILON) dx = len * 0.05; // 1/5th the shortest non-zero edge.
                if (dy < EPSILON) dy = len * 0.05;
                if (dz < EPSILON) dz = len * 0.05;
            }

            var x1:Float = center.x - dx;
            var x2:Float = center.x + dx;

            var y1:Float = center.y - dy;
            var y2:Float = center.y + dy;

            var z1:Float = center.z - dz;
            var z2:Float = center.z + dz;

            addPoint(vcount, vertices, x1, y1, z1);
            addPoint(vcount, vertices, x2, y1, z1);
            addPoint(vcount, vertices, x2, y2, z1);
            addPoint(vcount, vertices, x1, y2, z1);
            addPoint(vcount, vertices, x1, y1, z2);
            addPoint(vcount, vertices, x2, y1, z2);
            addPoint(vcount, vertices, x2, y2, z2);
            addPoint(vcount, vertices, x1, y2, z2);

            return true; // return cube
        } 
		else 
		{
            if (scale != null)
			{
                scale.x = dx;
                scale.y = dy;
                scale.z = dz;

                recip[0] = 1 / dx;
                recip[1] = 1 / dy;
                recip[2] = 1 / dz;

                center.x *= recip[0];
                center.y *= recip[1];
                center.z *= recip[2];
            }
        }

        vtx_ptr = svertices;
        vtx_idx = 0;

        for (i in 0...svcount) 
		{
            var p:Vector3f = vtx_ptr.getQuick(vtx_idx);
            vtx_idx +=/*stride*/ 1;

            var px:Float = p.x;
            var py:Float = p.y;
            var pz:Float = p.z;

            if (scale != null)
			{
                px = px * recip[0]; // normalize
                py = py * recip[1]; // normalize
                pz = pz * recip[2]; // normalize
            }

            //if ( 1 )
            {
				var index:Int = 0;
                for (j in 0...vcount[0])
				{
                    /// XXX might be broken
                    var v:Vector3f = vertices.getQuick(j);

                    var x:Float = v.x;
                    var y:Float = v.y;
                    var z:Float = v.z;

                    dx = Math.abs(x - px);
                    dy = Math.abs(y - py);
                    dz = Math.abs(z - pz);

                    if (dx < normalepsilon && dy < normalepsilon && dz < normalepsilon)
					{
                        // ok, it is close enough to the old one
                        // now let us see if it is further from the center of the point cloud than the one we already recorded.
                        // in which case we keep this one instead.

                        var dist1:Float = getDist(px, py, pz, center);
                        var dist2:Float = getDist(v.x, v.y, v.z, center);

                        if (dist1 > dist2) 
						{
                            v.x = px;
                            v.y = py;
                            v.z = pz;
                        }

                        break;
                    }
					index++;
                }

                if (index == vcount[0])
				{
                    var dest:Vector3f = vertices.getQuick(vcount[0]);
                    dest.x = px;
                    dest.y = py;
                    dest.z = pz;
                    vcount[0] = vcount[0] + 1;
                }

                vertexIndexMapping.add(index);
            }
        }

        // ok..now make sure we didn't prune so many vertices it is now invalid.
        //	if ( 1 )
        {
            bmin = [FastMath.POSITIVE_INFINITY, FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY];
			bmax = [FastMath.NEGATIVE_INFINITY, FastMath.NEGATIVE_INFINITY, FastMath.NEGATIVE_INFINITY];

            for (i in 0...vcount[0])
			{
                var p:Vector3f = vertices.getQuick(i);
                for (j in 0...3) 
				{
                    if (LinearMathUtil.getCoord(p, j) < bmin[j])
					{
                        bmin[j] = LinearMathUtil.getCoord(p, j);
                    }
                    if (LinearMathUtil.getCoord(p, j) > bmax[j])
					{
                        bmax[j] = LinearMathUtil.getCoord(p, j);
                    }
                }
            }

            dx = bmax[0] - bmin[0];
            dy = bmax[1] - bmin[1];
            dz = bmax[2] - bmin[2];

            if (dx < EPSILON || dy < EPSILON || dz < EPSILON || vcount[0] < 3)
			{
                var cx:Float = dx * 0.5 + bmin[0];
                var cy:Float = dy * 0.5 + bmin[1];
                var cz:Float = dz * 0.5 + bmin[2];

                var len:Float = FastMath.POSITIVE_INFINITY;

                if (dx >= EPSILON && dx < len) len = dx;
                if (dy >= EPSILON && dy < len) len = dy;
                if (dz >= EPSILON && dz < len) len = dz;

                if (len == FastMath.POSITIVE_INFINITY)
				{
                    dx = dy = dz = 0.01; // one centimeter
                } 
				else 
				{
                    if (dx < EPSILON) dx = len * 0.05; // 1/5th the shortest non-zero edge.
                    if (dy < EPSILON) dy = len * 0.05;
                    if (dz < EPSILON) dz = len * 0.05;
                }

                var x1:Float = cx - dx;
                var x2:Float = cx + dx;

                var y1:Float = cy - dy;
                var y2:Float = cy + dy;

                var z1:Float = cz - dz;
                var z2:Float = cz + dz;

                vcount[0] = 0; // add box

                addPoint(vcount, vertices, x1, y1, z1);
                addPoint(vcount, vertices, x2, y1, z1);
                addPoint(vcount, vertices, x2, y2, z1);
                addPoint(vcount, vertices, x1, y2, z1);
                addPoint(vcount, vertices, x1, y1, z2);
                addPoint(vcount, vertices, x2, y1, z2);
                addPoint(vcount, vertices, x2, y2, z2);
                addPoint(vcount, vertices, x1, y2, z2);

                return true;
            }
        }

        return true;
    }

    ////////////////////////////////////////////////////////////////////////////

    private static function hasvert(t:Int3, v:Int):Bool
	{
        return (t.getCoord(0) == v || t.getCoord(1) == v || t.getCoord(2) == v);
    }

    private static function orth(v:Vector3f, out:Vector3f):Vector3f
	{
        var a:Vector3f = new Vector3f();
        a.setTo(0, 0, 1);
        a.crossBy(v, a);

        var b:Vector3f = new Vector3f();
        b.setTo(0, 1, 0);
        b.crossBy(v, b);

        if (a.length > b.length)
		{
            out.normalizeBy(a);
            return out;
        } 
		else
		{
            out.normalizeBy(b);
            return out;
        }
    }

    private static function maxdirfiltered(p:ObjectArrayList<Vector3f>, count:Int, dir:Vector3f, allow:IntArrayList):Int
	{
        Assert.assert (count != 0);
        var m:Int = -1;
        for (i in 0...count)
		{
            if (allow.get(i) != 0)
			{
                if (m == -1 || p.getQuick(i).dot(dir) > p.getQuick(m).dot(dir))
				{
                    m = i;
                }
            }
        }
        Assert.assert (m != -1);
        return m;
    }

    private static function maxdirsterid(p:ObjectArrayList<Vector3f>, count:Int, dir:Vector3f, allow:IntArrayList):Int
	{
        var tmp:Vector3f = new Vector3f();
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();
        var u:Vector3f = new Vector3f();
        var v:Vector3f = new Vector3f();

        var m:Int = -1;
        while (m == -1) 
		{
            m = maxdirfiltered(p, count, dir, allow);
            if (allow.get(m) == 3) 
			{
                return m;
            }
            orth(dir, u);
            v.crossBy(u, dir);
            var ma:Int = -1;
			var x:Float = 0;
            while (x <= 360)
			{
                var s:Float = Math.sin(BulletGlobals.SIMD_RADS_PER_DEG * (x));
                var c:Float = Math.cos(BulletGlobals.SIMD_RADS_PER_DEG * (x));

                tmp1.scaleBy(s, u);
                tmp2.scaleBy(c, v);
                tmp.addBy(tmp1, tmp2);
                tmp.scaleLocal(0.025);
                tmp.addLocal(dir);
                var mb:Int = maxdirfiltered(p, count, tmp, allow);
                if (ma == m && mb == m) 
				{
                    allow.set(m, 3);
                    return m;
                }
				// Yuck - this is really ugly
                if (ma != -1 && ma != mb) 
				{ 
                    var mc:Int = ma;
					var xx:Float = x - 40;
                    while (xx <= x)
					{
                        s = Math.sin(BulletGlobals.SIMD_RADS_PER_DEG * (xx));
                        c = Math.cos(BulletGlobals.SIMD_RADS_PER_DEG * (xx));

                        tmp1.scaleBy(s, u);
                        tmp2.scaleBy(c, v);
                        tmp.addBy(tmp1, tmp2);
                        tmp.scaleLocal(0.025);
                        tmp.addLocal(dir);

                        var md:Int = maxdirfiltered(p, count, tmp, allow);
                        if (mc == m && md == m)
						{
                            allow.set(m, 3);
                            return m;
                        }
                        mc = md;
						
						xx += 5;
                    }
                }
                ma = mb;
				
				x += 45;
            }
            allow.set(m, 0);
            m = -1;
        }
        Assert.assert (false);
        return m;
    }

    private static function triNormal( v0:Vector3f, v1:Vector3f, v2:Vector3f, out:Vector3f):Vector3f
	{
        var tmp1:Vector3f = new Vector3f();
        var tmp2:Vector3f = new Vector3f();

        // return the normal of the triangle
        // inscribed by v0, v1, and v2
        tmp1.subtractBy(v1, v0);
        tmp2.subtractBy(v2, v1);
        var cp:Vector3f = new Vector3f();
        cp.crossBy(tmp1, tmp2);
        var m:Float = cp.length;
        if (m == 0)
		{
            out.setTo(1, 0, 0);
            return out;
        }
        out.scaleBy(1 / m, cp);
        return out;
    }

    private static function above(vertices:ObjectArrayList<Vector3f>, t:Int3, p:Vector3f, epsilon:Float):Bool
	{
        var n:Vector3f = triNormal(vertices.getQuick(t.getCoord(0)), vertices.getQuick(t.getCoord(1)), vertices.getQuick(t.getCoord(2)), new Vector3f());
        var tmp:Vector3f = new Vector3f();
        tmp.subtractBy(p, vertices.getQuick(t.getCoord(0)));
        return (n.dot(tmp) > epsilon); // EPSILON???
    }

    private static function releaseHull(result:PHullResult):Void
	{
        if (result.indices.size() != 0) {
            result.indices.clear();
        }

        result.vcount = 0;
        result.indexCount = 0;
        result.vertices = null;
    }

    private static function addPoint(vcount:Array<Int>, p:ObjectArrayList<Vector3f>, x:Float, y:Float, z:Float):Void
	{
        // XXX, might be broken
        var dest:Vector3f = p.getQuick(vcount[0]);
        dest.x = x;
        dest.y = y;
        dest.z = z;
        vcount[0] = vcount[0] + 1;
    }

    private static function getDist(px:Float, py:Float, pz:Float, p2:Vector3f):Float
	{
        var dx:Float = px - p2.x;
        var dy:Float = py - p2.y;
        var dz:Float = pz - p2.z;

        return dx * dx + dy * dy + dz * dz;
    }
}