package com.bulletphysics.collision.broadphase;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.linearmath.MatrixUtil;
import vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class DbvtAabbMm
{
	private var mi:Vector3f = new Vector3f();
    private var mx:Vector3f = new Vector3f();

    public function new( o:DbvtAabbMm = null)
	{
		if(o != null)
			set(o);
    }

    public function set( o:DbvtAabbMm):Void
	{
        mi.fromVector3f(o.mi);
        mx.fromVector3f(o.mx);
    }

    public static function swap(p1:DbvtAabbMm, p2:DbvtAabbMm):Void
	{
        var tmp:Vector3f = new Vector3f();

        tmp.fromVector3f(p1.mi);
        p1.mi.fromVector3f(p2.mi);
        p2.mi.fromVector3f(tmp);

        tmp.fromVector3f(p1.mx);
        p1.mx.fromVector3f(p2.mx);
        p2.mx.fromVector3f(tmp);
    }

    public function Center(out:Vector3f):Vector3f
	{
        out.add(mi, mx);
        out.scale(0.5);
        return out;
    }

    public function Lengths(out:Vector3f):Vector3f
	{
        out.sub(mx, mi);
        return out;
    }

    public function Extents(out:Vector3f):Vector3f 
	{
        out.sub(mx, mi);
        out.scale(0.5);
        return out;
    }

    public function Mins():Vector3f
	{
        return mi;
    }

    public function Maxs():Vector3f
	{
        return mx;
    }

    public static function FromCE(c:Vector3f, e:Vector3f, out:DbvtAabbMm):DbvtAabbMm
	{
        var box:DbvtAabbMm = out;
        box.mi.sub(c, e);
        box.mx.add(c, e);
        return box;
    }

    public static function FromCR(c:Vector3f, r:Float, out:DbvtAabbMm):DbvtAabbMm
	{
        var tmp:Vector3f = new Vector3f();
        tmp.setTo(r, r, r);
        return FromCE(c, tmp, out);
    }

    public static function FromMM(mi:Vector3f, mx:Vector3f, out:DbvtAabbMm):DbvtAabbMm
	{
        var box:DbvtAabbMm = out;
        box.mi.fromVector3f(mi);
        box.mx.fromVector3f(mx);
        return box;
    }

    //public static function  DbvtAabbMm	FromPoints( btVector3* pts,int n);
    //public static function  DbvtAabbMm	FromPoints( btVector3** ppts,int n);

    public function Expand(e:Vector3f):Void
	{
        mi.sub(e);
        mx.add(e);
    }

    public function SignedExpand(e:Vector3f):Void
	{
        if (e.x > 0) 
		{
            mx.x += e.x;
        } 
		else 
		{
            mi.x += e.x;
        }

        if (e.y > 0) 
		{
            mx.y += e.y;
        } 
		else 
		{
            mi.y += e.y;
        }

        if (e.z > 0) 
		{
            mx.z += e.z;
        } 
		else
		{
            mi.z += e.z;
        }
    }

    public function Contain(a:DbvtAabbMm):Bool
	{
        return ((mi.x <= a.mi.x) &&
                (mi.y <= a.mi.y) &&
                (mi.z <= a.mi.z) &&
                (mx.x >= a.mx.x) &&
                (mx.y >= a.mx.y) &&
                (mx.z >= a.mx.z));
    }

    public function Classify( n:Vector3f, o:Float, s:Int):Int
	{
        var pi:Vector3f = new Vector3f();
        var px:Vector3f = new Vector3f();

        switch (s)
		{
            case 0://(0 + 0 + 0):
                px.setTo(mi.x, mi.y, mi.z);
                pi.setTo(mx.x, mx.y, mx.z);
            case 1://(1 + 0 + 0):
                px.setTo(mx.x, mi.y, mi.z);
                pi.setTo(mi.x, mx.y, mx.z);
            case 2://(0 + 2 + 0):
                px.setTo(mi.x, mx.y, mi.z);
                pi.setTo(mx.x, mi.y, mx.z);
            case 3://(1 + 2 + 0):
                px.setTo(mx.x, mx.y, mi.z);
                pi.setTo(mi.x, mi.y, mx.z);
            case 4://(0 + 0 + 4):
                px.setTo(mi.x, mi.y, mx.z);
                pi.setTo(mx.x, mx.y, mi.z);
            case 5://(1 + 0 + 4):
                px.setTo(mx.x, mi.y, mx.z);
                pi.setTo(mi.x, mx.y, mi.z);
            case 6://(0 + 2 + 4):
                px.setTo(mi.x, mx.y, mx.z);
                pi.setTo(mx.x, mi.y, mi.z);
            case 7://(1 + 2 + 4):
                px.setTo(mx.x, mx.y, mx.z);
                pi.setTo(mi.x, mi.y, mi.z);
        }

        if ((n.dot(px) + o) < 0)
		{
            return -1;
        }
        if ((n.dot(pi) + o) >= 0)
		{
            return 1;
        }
        return 0;
    }

    public function ProjectMinimum( v:Vector3f, signs:Int):Float
	{
        var b:Array<Vector3f> = [mx, mi];
        var p:Vector3f = new Vector3f();
        p.setTo(b[(signs >> 0) & 1].x,
                b[(signs >> 1) & 1].y,
                b[(signs >> 2) & 1].z);
        return p.dot(v);
    }

    public static function Intersect(a:DbvtAabbMm, b:DbvtAabbMm):Bool
	{
        return ((a.mi.x <= b.mx.x) &&
                (a.mx.x >= b.mi.x) &&
                (a.mi.y <= b.mx.y) &&
                (a.mx.y >= b.mi.y) &&
                (a.mi.z <= b.mx.z) &&
                (a.mx.z >= b.mi.z));
    }

    public static function Intersect2(a:DbvtAabbMm, b:DbvtAabbMm, xform:Transform):Bool
	{
        var d0:Vector3f = new Vector3f();
        var d1:Vector3f = new Vector3f();
        var tmp:Vector3f = new Vector3f();

        // JAVA NOTE: check
        b.Center(d0);
        xform.transform(d0);
        d0.sub(a.Center(tmp));

        MatrixUtil.transposeTransform(d1, d0, xform.basis);

        var s0:Array<Float> = [0, 0];
        var s1:Array<Float> = [];
        s1[0] = xform.origin.dot(d0);
        s1[1] = s1[0];

        a.AddSpan(d0, s0, 0, s0, 1);
        b.AddSpan(d1, s1, 0, s1, 1);
        if (s0[0] > (s1[1]))
		{
            return false;
        }
        if (s0[1] < (s1[0]))
		{
            return false;
        }
        return true;
    }

    public static function Intersect3(a:DbvtAabbMm, b:Vector3f):Bool
	{
        return ((b.x >= a.mi.x) &&
                (b.y >= a.mi.y) &&
                (b.z >= a.mi.z) &&
                (b.x <= a.mx.x) &&
                (b.y <= a.mx.y) &&
                (b.z <= a.mx.z));
    }

    public static function Intersect4(a:DbvtAabbMm, org:Vector3f, invdir:Vector3f, signs:Array<Int>):Bool
	{
        var bounds:Array<Vector3f> = [a.mi, a.mx];
        var txmin:Float = (bounds[signs[0]].x - org.x) * invdir.x;
        var txmax:Float = (bounds[1 - signs[0]].x - org.x) * invdir.x;
        var tymin:Float = (bounds[signs[1]].y - org.y) * invdir.y;
        var tymax:Float = (bounds[1 - signs[1]].y - org.y) * invdir.y;
        if ((txmin > tymax) || (tymin > txmax))
		{
            return false;
        }

        if (tymin > txmin)
		{
            txmin = tymin;
        }
        if (tymax < txmax) 
		{
            txmax = tymax;
        }
		
        var tzmin:Float = (bounds[signs[2]].z - org.z) * invdir.z;
        var tzmax:Float = (bounds[1 - signs[2]].z - org.z) * invdir.z;
        if ((txmin > tzmax) || (tzmin > txmax)) 
		{
            return false;
        }

        if (tzmin > txmin) 
		{
            txmin = tzmin;
        }
        if (tzmax < txmax) 
		{
            txmax = tzmax;
        }
        return (txmax > 0);
    }

    public static function Proximity(a:DbvtAabbMm, b:DbvtAabbMm):Float
	{
        var d:Vector3f = new Vector3f();
        var tmp:Vector3f = new Vector3f();

        d.add(a.mi, a.mx);
        tmp.add(b.mi, b.mx);
        d.sub(tmp);
        return Math.abs(d.x) + Math.abs(d.y) + Math.abs(d.z);
    }

    public static function Merge(a:DbvtAabbMm, b:DbvtAabbMm, r:DbvtAabbMm):Void
	{
        for (i in 0...3)
		{
            if (VectorUtil.getCoord(a.mi, i) < VectorUtil.getCoord(b.mi, i))
			{
                VectorUtil.setCoord(r.mi, i, VectorUtil.getCoord(a.mi, i));
            } 
			else
			{
                VectorUtil.setCoord(r.mi, i, VectorUtil.getCoord(b.mi, i));
            }

            if (VectorUtil.getCoord(a.mx, i) > VectorUtil.getCoord(b.mx, i)) 
			{
                VectorUtil.setCoord(r.mx, i, VectorUtil.getCoord(a.mx, i));
            }
			else
			{
                VectorUtil.setCoord(r.mx, i, VectorUtil.getCoord(b.mx, i));
            }
        }
    }

    public static function NotEqual(a:DbvtAabbMm, b:DbvtAabbMm):Bool
	{
        return ((a.mi.x != b.mi.x) ||
                (a.mi.y != b.mi.y) ||
                (a.mi.z != b.mi.z) ||
                (a.mx.x != b.mx.x) ||
                (a.mx.y != b.mx.y) ||
                (a.mx.z != b.mx.z));
    }

    private function AddSpan(d:Vector3f, smi:Array<Float>, smi_idx:Int, smx:Array<Float>, smx_idx:Int):Void
	{
        for (i in 0...3)
		{
            if (VectorUtil.getCoord(d, i) < 0)
			{
                smi[smi_idx] += VectorUtil.getCoord(mx, i) * VectorUtil.getCoord(d, i);
                smx[smx_idx] += VectorUtil.getCoord(mi, i) * VectorUtil.getCoord(d, i);
            } 
			else 
			{
                smi[smi_idx] += VectorUtil.getCoord(mi, i) * VectorUtil.getCoord(d, i);
                smx[smx_idx] += VectorUtil.getCoord(mx, i) * VectorUtil.getCoord(d, i);
            }
        }
    }

	
}