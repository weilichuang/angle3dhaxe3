package com.bulletphysics.collision.broadphase;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.LinearMathUtil;
import com.bulletphysics.linearmath.MatrixUtil;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class DbvtAabbMm
{
	private static var tmp:Vector3f = new Vector3f();
	private static var d:Vector3f = new Vector3f();
	private static var d0:Vector3f = new Vector3f();
	private static var d1:Vector3f = new Vector3f();
	private static var s0:Array<Float> = [0, 0];
    private static var s1:Array<Float> = [];
	
    public static inline function swap(p1:DbvtAabbMm, p2:DbvtAabbMm):Void
	{
        tmp.copyFrom(p1.mi);
        p1.mi.copyFrom(p2.mi);
        p2.mi.copyFrom(tmp);

        tmp.copyFrom(p1.mx);
        p1.mx.copyFrom(p2.mx);
        p2.mx.copyFrom(tmp);
    }
	
	public static inline function FromCE(c:Vector3f, e:Vector3f, out:DbvtAabbMm):DbvtAabbMm
	{
        out.mi.subtractBy(c, e);
        out.mx.addBy(c, e);
        return out;
    }

    public static inline function FromCR(c:Vector3f, r:Float, out:DbvtAabbMm):DbvtAabbMm
	{
        tmp.setTo(r, r, r);
        return FromCE(c, tmp, out);
    }

    public static inline function FromMM(mi:Vector3f, mx:Vector3f, out:DbvtAabbMm):DbvtAabbMm
	{
        out.mi.copyFrom(mi);
        out.mx.copyFrom(mx);
        return out;
    }
	
	public static inline function Intersect(a:DbvtAabbMm, b:DbvtAabbMm):Bool
	{
		var ami:Vector3f = a.mi;
		var amx:Vector3f = a.mx;
		var bmi:Vector3f = b.mi;
		var bmx:Vector3f = b.mx;
        return ((ami.x <= bmx.x) && (amx.x >= bmi.x) &&
                (ami.y <= bmx.y) && (amx.y >= bmi.y) &&
                (ami.z <= bmx.z) && (amx.z >= bmi.z));
    }

    public static function Intersect2(a:DbvtAabbMm, b:DbvtAabbMm, xform:Transform):Bool
	{
        // JAVA NOTE: check
        b.Center(d0);
        xform.transform(d0);
        d0.subtractLocal(a.Center(tmp));

        MatrixUtil.transposeTransform(d1, d0, xform.basis);

        s0[0] = 0;
		s0[1] = 0;
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

    public static inline function Intersect3(a:DbvtAabbMm, b:Vector3f):Bool
	{
		var ami = a.mi;
		var amx = a.mx;
        return ((b.x >= ami.x) &&
                (b.y >= ami.y) &&
                (b.z >= ami.z) &&
                (b.x <= amx.x) &&
                (b.y <= amx.y) &&
                (b.z <= amx.z));
    }

    public static function Intersect4(a:DbvtAabbMm, org:Vector3f, invdir:Vector3f, signs:Array<Int>):Bool
	{
        var bounds:Array<Vector3f> = a.bounds;
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

    public static inline function Proximity(a:DbvtAabbMm, b:DbvtAabbMm):Float
	{
        d.addBy(a.mi, a.mx);
        tmp.addBy(b.mi, b.mx);
        d.subtractLocal(tmp);
        return FastMath.abs(d.x) + FastMath.abs(d.y) + FastMath.abs(d.z);
    }

    public static inline function Merge(a:DbvtAabbMm, b:DbvtAabbMm, r:DbvtAabbMm):Void
	{
		//原代码
        //for (i in 0...3)
		//{
            //if (VectorUtil.getCoord(a.mi, i) < VectorUtil.getCoord(b.mi, i))
			//{
                //VectorUtil.setCoord(r.mi, i, VectorUtil.getCoord(a.mi, i));
            //} 
			//else
			//{
                //VectorUtil.setCoord(r.mi, i, VectorUtil.getCoord(b.mi, i));
            //}
//
            //if (VectorUtil.getCoord(a.mx, i) > VectorUtil.getCoord(b.mx, i)) 
			//{
                //VectorUtil.setCoord(r.mx, i, VectorUtil.getCoord(a.mx, i));
            //}
			//else
			//{
                //VectorUtil.setCoord(r.mx, i, VectorUtil.getCoord(b.mx, i));
            //}
        //}
		
		//优化代码
		//x
		r.mi.x = FastMath.min(a.mi.x, b.mi.x);
		r.mx.x = FastMath.max(a.mx.x, b.mx.x);
		//y
		r.mi.y = FastMath.min(a.mi.y, b.mi.y);
		r.mx.y = FastMath.max(a.mx.y, b.mx.y);
		//z
		r.mi.z = FastMath.min(a.mi.z, b.mi.z);
		r.mx.z = FastMath.max(a.mx.z, b.mx.z);
    }

    public static inline function NotEqual(a:DbvtAabbMm, b:DbvtAabbMm):Bool
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
        //for (i in 0...3)
		//{
            //if (VectorUtil.getCoord(d, i) < 0)
			//{
                //smi[smi_idx] += VectorUtil.getCoord(mx, i) * VectorUtil.getCoord(d, i);
                //smx[smx_idx] += VectorUtil.getCoord(mi, i) * VectorUtil.getCoord(d, i);
            //} 
			//else 
			//{
                //smi[smi_idx] += VectorUtil.getCoord(mi, i) * VectorUtil.getCoord(d, i);
                //smx[smx_idx] += VectorUtil.getCoord(mx, i) * VectorUtil.getCoord(d, i);
            //}
        //}
		
		//------------------x---------------//
		var dx:Float = d.x;
		if (dx < 0)
		{
			smi[smi_idx] += mx.x * dx;
			smx[smx_idx] += mi.x * dx;
		}
		else
		{
			smi[smi_idx] += mi.x * dx;
			smx[smx_idx] += mx.x * dx;
		}
		
		//------------------y---------------//
		dx = d.y;
		if (dx < 0)
		{
			smi[smi_idx] += mx.y * dx;
			smx[smx_idx] += mi.y * dx;
		}
		else
		{
			smi[smi_idx] += mi.y * dx;
			smx[smx_idx] += mx.y * dx;
		}
		
		//------------------z---------------//
		dx = d.z;
		if (dx < 0)
		{
			smi[smi_idx] += mx.z * dx;
			smx[smx_idx] += mi.z * dx;
		}
		else
		{
			smi[smi_idx] += mi.z * dx;
			smx[smx_idx] += mx.z * dx;
		}
    }
	
	public var mi:Vector3f = new Vector3f();
    public var mx:Vector3f = new Vector3f();
	public var bounds:Array<Vector3f>;

    public function new()
	{
		bounds = [mi, mx];
    }

    public inline function set( o:DbvtAabbMm):Void
	{
        mi.copyFrom(o.mi);
        mx.copyFrom(o.mx);
    }

    public inline function Center(out:Vector3f):Vector3f
	{
        out.addBy(mi, mx);
        out.scaleLocal(0.5);
        return out;
    }

    public inline function Lengths(out:Vector3f):Vector3f
	{
        out.subtractBy(mx, mi);
        return out;
    }

    public inline function Extents(out:Vector3f):Vector3f 
	{
        out.subtractBy(mx, mi);
        out.scaleLocal(0.5);
        return out;
    }

    public inline function Mins():Vector3f
	{
        return mi;
    }

    public inline function Maxs():Vector3f
	{
        return mx;
    }

	// volume + edge lengths
    public inline function Size():Float
	{
		var x:Float = mx.x - mi.x;
		var y:Float = mx.y - mi.y;
		var z:Float = mx.z - mi.z;
		return x * y * z + x + y + z;
	}

    //public static function  DbvtAabbMm	FromPoints( btVector3* pts,int n);
    //public static function  DbvtAabbMm	FromPoints( btVector3** ppts,int n);

    public inline function Expand(e:Vector3f):Void
	{
        mi.subtractLocal(e);
        mx.addLocal(e);
    }
	
	public inline function ExpandXYZ(x:Float,y:Float,z:Float):Void
	{
        mi.x -= x;
		mi.y -= y;
		mi.z -= z;
		
        mx.x += x;
		mx.y += y;
		mx.z += z;
    }

    public inline function SignedExpand(e:Vector3f):Void
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

    public inline function Contain(a:DbvtAabbMm):Bool
	{
		var ami = a.mi;
		var amx = a.mx;
        return ((mi.x <= ami.x) &&
                (mi.y <= ami.y) &&
                (mi.z <= ami.z) &&
                (mx.x >= amx.x) &&
                (mx.y >= amx.y) &&
                (mx.z >= amx.z));
    }

	//private var pi:Vector3f = new Vector3f();
	//private var px:Vector3f = new Vector3f();
    public function Classify( n:Vector3f, o:Float, s:Int):Int
	{
		var pxx:Float = 0; var pxy:Float = 0; var pxz:Float = 0;
		var pix:Float = 0; var piy:Float = 0; var piz:Float = 0;
        switch (s)
		{
            case 0://(0 + 0 + 0):
				pxx = mi.x; pxy = mi.y; pxz = mi.z;
				pix = mx.x; piy = mx.y; piz = mx.z;
                //px.setTo(mi.x, mi.y, mi.z);
                //pi.setTo(mx.x, mx.y, mx.z);
            case 1://(1 + 0 + 0):
				pxx = mx.x; pxy = mi.y; pxz = mi.z;
				pix = mi.x; piy = mx.y; piz = mx.z;
                //px.setTo(mx.x, mi.y, mi.z);
                //pi.setTo(mi.x, mx.y, mx.z);
            case 2://(0 + 2 + 0):
				pxx = mi.x; pxy = mx.y; pxz = mi.z;
				pix = mx.x; piy = mi.y; piz = mx.z;
                //px.setTo(mi.x, mx.y, mi.z);
                //pi.setTo(mx.x, mi.y, mx.z);
            case 3://(1 + 2 + 0):
				pxx = mx.x; pxy = mx.y; pxz = mi.z;
				pix = mi.x; piy = mi.y; piz = mx.z;
                //px.setTo(mx.x, mx.y, mi.z);
                //pi.setTo(mi.x, mi.y, mx.z);
            case 4://(0 + 0 + 4):
				pxx = mi.x; pxy = mi.y; pxz = mx.z;
				pix = mx.x; piy = mx.y; piz = mi.z;
                //px.setTo(mi.x, mi.y, mx.z);
                //pi.setTo(mx.x, mx.y, mi.z);
            case 5://(1 + 0 + 4):
				pxx = mx.x; pxy = mi.y; pxz = mx.z;
				pix = mi.x; piy = mx.y; piz = mi.z;
                //px.setTo(mx.x, mi.y, mx.z);
                //pi.setTo(mi.x, mx.y, mi.z);
            case 6://(0 + 2 + 4):
				pxx = mi.x; pxy = mx.y; pxz = mx.z;
				pix = mx.x; piy = mi.y; piz = mi.z;
                //px.setTo(mi.x, mx.y, mx.z);
                //pi.setTo(mx.x, mi.y, mi.z);
            case 7://(1 + 2 + 4):
				pxx = mx.x; pxy = mx.y; pxz = mx.z;
				pix = mi.x; piy = mi.y; piz = mi.z;
                //px.setTo(mx.x, mx.y, mx.z);
                //pi.setTo(mi.x, mi.y, mi.z);
        }

        //if ((n.dot(px) + o) < 0)
		if ((n.x * pxx + n.y * pxy + n.z * pxz + o) < 0)
		{
            return -1;
        }
        //if ((n.dot(pi) + o) >= 0)
		if ((n.x * pix + n.y * piy + n.z * piz + o) < 0)
		{
            return 1;
        }
        return 0;
    }

    public inline function ProjectMinimum( v:Vector3f, signs:Int):Float
	{
        //var p:Vector3f = new Vector3f();
        //p.setTo(b[(signs >> 0) & 1].x,
                //b[(signs >> 1) & 1].y,
                //b[(signs >> 2) & 1].z);
        //return p.dot(v);
		var px:Float = bounds[(signs >> 0) & 1].x;
		var py:Float = bounds[(signs >> 1) & 1].y;
		var pz:Float = bounds[(signs >> 2) & 1].z;
		return px * v.x + py * v.y + pz * v.z;
    }
}