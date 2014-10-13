package com.bulletphysics.extras.gimpact;
import com.bulletphysics.extras.gimpact.BoxCollision.AABB;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.linearmath.VectorUtil;
import vecmath.Matrix3f;
import vecmath.Vector3f;
import vecmath.Vector4f;

/**
 * ...
 * @author weilichuang
 */
class BoxCollision
{

	public static inline var BOX_PLANE_EPSILON:Float = 0.000001;

    public static inline function BT_GREATER(x:Float, y:Float):Bool
	{
        return Math.abs(x) > y;
    }

    public static inline function BT_MAX3(a:Float, b:Float, c:Float):Float
	{
        return Math.max(a, Math.max(b, c));
    }

    public static inline function BT_MIN3(a:Float, b:Float, c:Float):Float 
	{
        return Math.min(a, Math.min(b, c));
    }

    public static function TEST_CROSS_EDGE_BOX_MCR(edge:Vector3f, absolute_edge:Vector3f, 
												pointa:Vector3f, pointb:Vector3f, _extend:Vector3f, 
												i_dir_0:Int, i_dir_1:Int, i_comp_0:Int, i_comp_1:Int):Bool 
	{
        var dir0:Float = -VectorUtil.getCoord(edge, i_dir_0);
        var dir1:Float = VectorUtil.getCoord(edge, i_dir_1);
        var pmin:Float = VectorUtil.getCoord(pointa, i_comp_0) * dir0 + VectorUtil.getCoord(pointa, i_comp_1) * dir1;
        var pmax:Float = VectorUtil.getCoord(pointb, i_comp_0) * dir0 + VectorUtil.getCoord(pointb, i_comp_1) * dir1;
        if (pmin > pmax)
		{
            //BT_SWAP_NUMBERS(pmin,pmax);
            pmin = pmin + pmax;
            pmax = pmin - pmax;
            pmin = pmin - pmax;
        }
        var abs_dir0:Float = VectorUtil.getCoord(absolute_edge, i_dir_0);
        var abs_dir1:Float = VectorUtil.getCoord(absolute_edge, i_dir_1);
        var rad:Float = VectorUtil.getCoord(_extend, i_comp_0) * abs_dir0 + VectorUtil.getCoord(_extend, i_comp_1) * abs_dir1;
        if (pmin > rad || -rad > pmax)
		{
            return false;
        }
        return true;
    }

    public static inline function TEST_CROSS_EDGE_BOX_X_AXIS_MCR(edge:Vector3f, absolute_edge:Vector3f, 
												pointa:Vector3f, pointb:Vector3f, _extend:Vector3f):Bool
	{
        return TEST_CROSS_EDGE_BOX_MCR(edge, absolute_edge, pointa, pointb, _extend, 2, 1, 1, 2);
    }

    public static inline function TEST_CROSS_EDGE_BOX_Y_AXIS_MCR(edge:Vector3f, absolute_edge:Vector3f, 
												pointa:Vector3f, pointb:Vector3f, _extend:Vector3f):Bool
	{
        return TEST_CROSS_EDGE_BOX_MCR(edge, absolute_edge, pointa, pointb, _extend, 0, 2, 2, 0);
    }

    public static inline function TEST_CROSS_EDGE_BOX_Z_AXIS_MCR(edge:Vector3f, absolute_edge:Vector3f, 
												pointa:Vector3f, pointb:Vector3f, _extend:Vector3f):Bool
	{
        return TEST_CROSS_EDGE_BOX_MCR(edge, absolute_edge, pointa, pointb, _extend, 1, 0, 0, 1);
    }

    /**
     * Returns the dot product between a vec3f and the col of a matrix.
     */
    public static function bt_mat3_dot_col(mat:Matrix3f, vec3:Vector3f, colindex:Int):Float
	{
        return vec3.x * mat.getElement(0, colindex) + vec3.y * mat.getElement(1, colindex) + vec3.z * mat.getElement(2, colindex);
    }

    /**
     * Compairison of transformation objects.
     */
    public static function compareTransformsEqual(t1:Transform, t2:Transform):Bool
	{
        return t1.equals(t2);
    }
}

class BoxBoxTransformCache 
{
	public var T1to0:Vector3f = new Vector3f(); // Transforms translation of model1 to model 0
	public var R1to0:Matrix3f = new Matrix3f(); // Transforms Rotation of model1 to model 0, equal  to R0' * R1
	public var AR:Matrix3f = new Matrix3f();    // Absolute value of m_R1to0

	//public function set(cache:BoxBoxTransformCache):Void
	//{
		//throw new UnsupportedOperationException();
	//}

	public function calc_absolute_matrix():Void
	{
		//static const btVector3 vepsi(1e-6f,1e-6f,1e-6f);
		//m_AR[0] = vepsi + m_R1to0[0].absolute();
		//m_AR[1] = vepsi + m_R1to0[1].absolute();
		//m_AR[2] = vepsi + m_R1to0[2].absolute();

		for (i in 0...3)
		{
			for (j in 0...3)
			{
				AR.setElement(i, j, 1e-6 + Math.abs(R1to0.getElement(i, j)));
			}
		}
	}

	/**
	 * Calc the transformation relative  1 to 0. Inverts matrics by transposing.
	 */
	public function calc_from_homogenic(trans0:Transform, trans1:Transform):Void
	{
		var temp_trans:Transform = new Transform();
		temp_trans.inverse(trans0);
		temp_trans.mul(trans1);

		T1to0.fromVector3f(temp_trans.origin);
		R1to0.fromMatrix3f(temp_trans.basis);

		calc_absolute_matrix();
	}

	/**
	 * Calcs the full invertion of the matrices. Useful for scaling matrices.
	 */
	public function calc_from_full_invert(trans0:Transform, trans1:Transform):Void
	{
		R1to0.invert(trans0.basis);
		T1to0.negate(trans0.origin);
		R1to0.transform(T1to0);

		var tmp:Vector3f = new Vector3f();
		tmp.fromVector3f(trans1.origin);
		R1to0.transform(tmp);
		T1to0.add(tmp);

		R1to0.mul(trans1.basis);

		calc_absolute_matrix();
	}

	public function transform(point:Vector3f, out:Vector3f):Vector3f
	{
		if (point == out) 
		{
			point = point.clone();
		}

		var tmp:Vector3f = new Vector3f();
		R1to0.getRow(0, tmp);
		out.x = tmp.dot(point) + T1to0.x;
		R1to0.getRow(1, tmp);
		out.y = tmp.dot(point) + T1to0.y;
		R1to0.getRow(2, tmp);
		out.z = tmp.dot(point) + T1to0.z;
		return out;
	}
}

class AABB 
{
	public var min:Vector3f = new Vector3f();
	public var max:Vector3f = new Vector3f();
	
	public function new()
	{
		
	}
	
	public function clone():AABB
	{
		var newAabb:AABB = new AABB();
		newAabb.fromAABB(this);
		return newAabb;
	}


	public function fromTriangle(V1:Vector3f, V2:Vector3f, V3:Vector3f):Void
	{
		calc_from_triangle(V1, V2, V3);
	}

	public function fromTriangleMargin(V1:Vector3f, V2:Vector3f, V3:Vector3f, margin:Float):Void
	{
		calc_from_triangle_margin(V1, V2, V3, margin);
	}

	public function fromAABB(other:AABB):Void
	{
		min.fromVector3f(other.min);
		max.fromVector3f(other.max);
	}
	
	public function fromAABBMargin(other:AABB,margin:Float):Void
	{
		min.fromVector3f(other.min);
		max.fromVector3f(other.max);
		min.x -= margin;
		min.y -= margin;
		min.z -= margin;
		max.x += margin;
		max.y += margin;
		max.z += margin;
	}

	public function init(V1:Vector3f, V2:Vector3f, V3:Vector3f, margin:Float):Void
	{
		calc_from_triangle_margin(V1, V2, V3, margin);
	}

	public function invalidate():Void
	{
		min.setTo(BulletGlobals.SIMD_INFINITY, BulletGlobals.SIMD_INFINITY, BulletGlobals.SIMD_INFINITY);
		max.setTo(-BulletGlobals.SIMD_INFINITY, -BulletGlobals.SIMD_INFINITY, -BulletGlobals.SIMD_INFINITY);
	}

	public function increment_margin(margin:Float):Void
	{
		min.x -= margin;
		min.y -= margin;
		min.z -= margin;
		max.x += margin;
		max.y += margin;
		max.z += margin;
	}

	public function copy_with_margin(other:AABB, margin:Float):Void
	{
		min.x = other.min.x - margin;
		min.y = other.min.y - margin;
		min.z = other.min.z - margin;

		max.x = other.max.x + margin;
		max.y = other.max.y + margin;
		max.z = other.max.z + margin;
	}

	public function calc_from_triangle(V1:Vector3f, V2:Vector3f, V3:Vector3f):Void
	{
		min.x = BoxCollision.BT_MIN3(V1.x, V2.x, V3.x);
		min.y = BoxCollision.BT_MIN3(V1.y, V2.y, V3.y);
		min.z = BoxCollision.BT_MIN3(V1.z, V2.z, V3.z);

		max.x = BoxCollision.BT_MAX3(V1.x, V2.x, V3.x);
		max.y = BoxCollision.BT_MAX3(V1.y, V2.y, V3.y);
		max.z = BoxCollision.BT_MAX3(V1.z, V2.z, V3.z);
	}

	public function calc_from_triangle_margin(V1:Vector3f, V2:Vector3f, V3:Vector3f, margin:Float):Void 
	{
		calc_from_triangle(V1, V2, V3);
		min.x -= margin;
		min.y -= margin;
		min.z -= margin;
		max.x += margin;
		max.y += margin;
		max.z += margin;
	}

	/**
	 * Apply a transform to an AABB.
	 */
	public function appy_transform(trans:Transform):Void
	{
		var tmp:Vector3f = new Vector3f();

		var center:Vector3f = new Vector3f();
		center.add(max, min);
		center.scale(0.5);

		var extends_:Vector3f = new Vector3f();
		extends_.sub(max, center);

		// Compute new center
		trans.transform(center);

		var textends:Vector3f = new Vector3f();

		trans.basis.getRow(0, tmp);
		tmp.absolute();
		textends.x = extends_.dot(tmp);

		trans.basis.getRow(1, tmp);
		tmp.absolute();
		textends.y = extends_.dot(tmp);

		trans.basis.getRow(2, tmp);
		tmp.absolute();
		textends.z = extends_.dot(tmp);

		min.sub(center, textends);
		max.add(center, textends);
	}

	/**
	 * Apply a transform to an AABB.
	 */
	public function appy_transform_trans_cache(trans:BoxBoxTransformCache):Void
	{
		var tmp:Vector3f = new Vector3f();

		var center:Vector3f = new Vector3f();
		center.add(max, min);
		center.scale(0.5);

		var extends_:Vector3f = new Vector3f();
		extends_.sub(max, center);

		// Compute new center
		trans.transform(center, center);

		var textends:Vector3f = new Vector3f();

		trans.R1to0.getRow(0, tmp);
		tmp.absolute();
		textends.x = extends_.dot(tmp);

		trans.R1to0.getRow(1, tmp);
		tmp.absolute();
		textends.y = extends_.dot(tmp);

		trans.R1to0.getRow(2, tmp);
		tmp.absolute();
		textends.z = extends_.dot(tmp);

		min.sub(center, textends);
		max.add(center, textends);
	}

	/**
	 * Merges a Box.
	 */
	public function merge(box:AABB):Void
	{
		min.x = Math.min(min.x, box.min.x);
		min.y = Math.min(min.y, box.min.y);
		min.z = Math.min(min.z, box.min.z);

		max.x = Math.max(max.x, box.max.x);
		max.y = Math.max(max.y, box.max.y);
		max.z = Math.max(max.z, box.max.z);
	}

	/**
	 * Merges a point.
	 */
	public function merge_point(point:Vector3f):Void
	{
		min.x = Math.min(min.x, point.x);
		min.y = Math.min(min.y, point.y);
		min.z = Math.min(min.z, point.z);

		max.x = Math.max(max.x, point.x);
		max.y = Math.max(max.y, point.y);
		max.z = Math.max(max.z, point.z);
	}

	/**
	 * Gets the extend and center.
	 */
	public function get_center_extend(center:Vector3f, extend:Vector3f):Void
	{
		center.add(max, min);
		center.scale(0.5);

		extend.sub(max, center);
	}

	/**
	 * Finds the intersecting box between this box and the other.
	 */
	public function find_intersection(other:AABB, intersection:AABB):Void
	{
		intersection.min.x = Math.max(other.min.x, min.x);
		intersection.min.y = Math.max(other.min.y, min.y);
		intersection.min.z = Math.max(other.min.z, min.z);

		intersection.max.x = Math.min(other.max.x, max.x);
		intersection.max.y = Math.min(other.max.y, max.y);
		intersection.max.z = Math.min(other.max.z, max.z);
	}

	public function has_collision(other:AABB):Bool
	{
		if (min.x > other.max.x ||
				max.x < other.min.x ||
				min.y > other.max.y ||
				max.y < other.min.y ||
				min.z > other.max.z ||
				max.z < other.min.z)
		{
			return false;
		}
		return true;
	}

	/**
	 * Finds the Ray intersection parameter.
	 *
	 * @param aabb    aligned box
	 * @param vorigin a vec3f with the origin of the ray
	 * @param vdir    a vec3f with the direction of the ray
	 */
	public function collide_ray(vorigin:Vector3f, vdir:Vector3f):Bool
	{
		var extents:Vector3f = new Vector3f();
		var center:Vector3f = new Vector3f();
		get_center_extend(center, extents);

		var Dx:Float = vorigin.x - center.x;
		if (BoxCollision.BT_GREATER(Dx, extents.x) && Dx * vdir.x >= 0.0) return false;

		var Dy:Float = vorigin.y - center.y;
		if (BoxCollision.BT_GREATER(Dy, extents.y) && Dy * vdir.y >= 0.0) return false;

		var Dz:Float = vorigin.z - center.z;
		if (BoxCollision.BT_GREATER(Dz, extents.z) && Dz * vdir.z >= 0.0) return false;

		var f:Float = vdir.y * Dz - vdir.z * Dy;
		if (Math.abs(f) > extents.y * Math.abs(vdir.z) + extents.z * Math.abs(vdir.y)) return false;

		f = vdir.z * Dx - vdir.x * Dz;
		if (Math.abs(f) > extents.x * Math.abs(vdir.z) + extents.z * Math.abs(vdir.x)) return false;

		f = vdir.x * Dy - vdir.y * Dx;
		if (Math.abs(f) > extents.x * Math.abs(vdir.y) + extents.y * Math.abs(vdir.x)) return false;

		return true;
	}

	public function projection_interval(direction:Vector3f, vmin:Array<Float>, vmax:Array<Float>):Void
	{
		var tmp:Vector3f = new Vector3f();

		var center:Vector3f = new Vector3f();
		var extend:Vector3f = new Vector3f();
		get_center_extend(center, extend);

		var _fOrigin:Float = direction.dot(center);
		tmp.absolute(direction);
		var _fMaximumExtent:Float = extend.dot(tmp);
		vmin[0] = _fOrigin - _fMaximumExtent;
		vmax[0] = _fOrigin + _fMaximumExtent;
	}

	public function plane_classify(plane:Vector4f):PlaneIntersectionType
	{
		var tmp:Vector3f = new Vector3f();

		var _fmin:Array<Float> = [];
		var _fmax:Array<Float> = [];
		tmp.setTo(plane.x, plane.y, plane.z);
		projection_interval(tmp, _fmin, _fmax);

		if (plane.w > _fmax[0] + BoxCollision.BOX_PLANE_EPSILON) 
		{
			return PlaneIntersectionType.BACK_PLANE; // 0
		}

		if (plane.w + BoxCollision.BOX_PLANE_EPSILON >= _fmin[0])
		{
			return PlaneIntersectionType.COLLIDE_PLANE; //1
		}

		return PlaneIntersectionType.FRONT_PLANE; //2
	}

	public function overlapping_trans_conservative(box:AABB, trans1_to_0:Transform):Bool
	{
		var tbox:AABB = box.clone();
		tbox.appy_transform(trans1_to_0);
		return has_collision(tbox);
	}

	public function overlapping_trans_conservative2(box:AABB, trans1_to_0:BoxBoxTransformCache):Bool
	{
		var tbox:AABB = box.clone();
		tbox.appy_transform_trans_cache(trans1_to_0);
		return has_collision(tbox);
	}

	/**
	 * transcache is the transformation cache from box to this AABB.
	 */
	public function overlapping_trans_cache(box:AABB, transcache:BoxBoxTransformCache, fulltest:Bool):Bool
	{
		var tmp:Vector3f = new Vector3f();

		// Taken from OPCODE
		var ea:Vector3f = new Vector3f();
		var eb:Vector3f = new Vector3f(); //extends
		var ca:Vector3f = new Vector3f();
		var cb:Vector3f = new Vector3f(); //extends
		get_center_extend(ca, ea);
		box.get_center_extend(cb, eb);

		var T:Vector3f = new Vector3f();
		var t:Float, t2:Float;

		// Class I : A's basis vectors
		for (i in 0...3) 
		{
			transcache.R1to0.getRow(i, tmp);
			VectorUtil.setCoord(T, i, tmp.dot(cb) + VectorUtil.getCoord(transcache.T1to0, i) - VectorUtil.getCoord(ca, i));

			transcache.AR.getRow(i, tmp);
			t = tmp.dot(eb) + VectorUtil.getCoord(ea, i);
			if (BoxCollision.BT_GREATER(VectorUtil.getCoord(T, i), t))
			{
				return false;
			}
		}
		// Class II : B's basis vectors
		for (i in 0...3)
		{
			t = BoxCollision.bt_mat3_dot_col(transcache.R1to0, T, i);
			t2 = BoxCollision.bt_mat3_dot_col(transcache.AR, ea, i) + VectorUtil.getCoord(eb, i);
			if (BoxCollision.BT_GREATER(t, t2)) 
			{
				return false;
			}
		}
		// Class III : 9 cross products
		if (fulltest)
		{
			var m:Int, n:Int, o:Int, p:Int, q:Int, r:Int;
			for (i in 0...3)
			{
				m = (i + 1) % 3;
				n = (i + 2) % 3;
				o = (i == 0) ? 1 : 0;
				p = (i == 2) ? 1 : 2;
				for (j in 0...3) 
				{
					q = j == 2 ? 1 : 2;
					r = j == 0 ? 1 : 0;
					t = VectorUtil.getCoord(T, n) * transcache.R1to0.getElement(m, j) - VectorUtil.getCoord(T, m) * transcache.R1to0.getElement(n, j);
					t2 = VectorUtil.getCoord(ea, o) * transcache.AR.getElement(p, j) + VectorUtil.getCoord(ea, p) * transcache.AR.getElement(o, j) +
							VectorUtil.getCoord(eb, r) * transcache.AR.getElement(i, q) + VectorUtil.getCoord(eb, q) * transcache.AR.getElement(i, r);
					if (BoxCollision.BT_GREATER(t, t2)) 
					{
						return false;
					}
				}
			}
		}
		return true;
	}

	/**
	 * Simple test for planes.
	 */
	public function collide_plane(plane:Vector4f):Bool
	{
		var classify:PlaneIntersectionType = plane_classify(plane);
		return (classify == PlaneIntersectionType.COLLIDE_PLANE);
	}

	/**
	 * Test for a triangle, with edges.
	 */
	public function collide_triangle_exact(p1:Vector3f, p2:Vector3f, p3:Vector3f, triangle_plane:Vector4f):Bool
	{
		if (!collide_plane(triangle_plane))
		{
			return false;
		}
		
		var center:Vector3f = new Vector3f();
		var extends_:Vector3f = new Vector3f();
		get_center_extend(center, extends_);

		var v1:Vector3f = new Vector3f();
		v1.sub(p1, center);
		var v2:Vector3f = new Vector3f();
		v2.sub(p2, center);
		var v3:Vector3f = new Vector3f();
		v3.sub(p3, center);

		// First axis
		var diff:Vector3f = new Vector3f();
		diff.sub(v2, v1);
		var abs_diff:Vector3f = new Vector3f();
		abs_diff.absolute(diff);

		// Test With X axis
		BoxCollision.TEST_CROSS_EDGE_BOX_X_AXIS_MCR(diff, abs_diff, v1, v3, extends_);
		// Test With Y axis
		BoxCollision.TEST_CROSS_EDGE_BOX_Y_AXIS_MCR(diff, abs_diff, v1, v3, extends_);
		// Test With Z axis
		BoxCollision.TEST_CROSS_EDGE_BOX_Z_AXIS_MCR(diff, abs_diff, v1, v3, extends_);

		diff.sub(v3, v2);
		abs_diff.absolute(diff);

		// Test With X axis
		BoxCollision.TEST_CROSS_EDGE_BOX_X_AXIS_MCR(diff, abs_diff, v2, v1, extends_);
		// Test With Y axis
		BoxCollision.TEST_CROSS_EDGE_BOX_Y_AXIS_MCR(diff, abs_diff, v2, v1, extends_);
		// Test With Z axis
		BoxCollision.TEST_CROSS_EDGE_BOX_Z_AXIS_MCR(diff, abs_diff, v2, v1, extends_);

		diff.sub(v1, v3);
		abs_diff.absolute(diff);

		// Test With X axis
		BoxCollision.TEST_CROSS_EDGE_BOX_X_AXIS_MCR(diff, abs_diff, v3, v2, extends_);
		// Test With Y axis
		BoxCollision.TEST_CROSS_EDGE_BOX_Y_AXIS_MCR(diff, abs_diff, v3, v2, extends_);
		// Test With Z axis
		BoxCollision.TEST_CROSS_EDGE_BOX_Z_AXIS_MCR(diff, abs_diff, v3, v2, extends_);

		return true;
	}
}