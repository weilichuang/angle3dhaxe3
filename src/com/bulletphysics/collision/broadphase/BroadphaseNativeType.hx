package com.bulletphysics.collision.broadphase;

/**
 * ...
 */
@:enum abstract BroadphaseNativeType(Int)   
{
	var NONE = -1;
	// polyhedral convex shapes:
    var BOX_SHAPE_PROXYTYPE = 0;
    var TRIANGLE_SHAPE_PROXYTYPE = 1;
    var TETRAHEDRAL_SHAPE_PROXYTYPE = 2;
    var CONVEX_TRIANGLEMESH_SHAPE_PROXYTYPE = 3;
    var CONVEX_HULL_SHAPE_PROXYTYPE = 4;

    // implicit convex shapes:
    var IMPLICIT_CONVEX_SHAPES_START_HERE = 5;
    var SPHERE_SHAPE_PROXYTYPE = 6;
    var MULTI_SPHERE_SHAPE_PROXYTYPE = 7;
    var CAPSULE_SHAPE_PROXYTYPE = 8;
    var CONE_SHAPE_PROXYTYPE = 9;
    var CONVEX_SHAPE_PROXYTYPE = 10;
    var CYLINDER_SHAPE_PROXYTYPE = 11;
    var UNIFORM_SCALING_SHAPE_PROXYTYPE = 12;
    var MINKOWSKI_SUM_SHAPE_PROXYTYPE = 13;
    var MINKOWSKI_DIFFERENCE_SHAPE_PROXYTYPE = 14;

    // concave shapes:
    var CONCAVE_SHAPES_START_HERE = 15;

    // keep all the convex shapetype below here, for the check IsConvexShape in broadphase proxy!
    var TRIANGLE_MESH_SHAPE_PROXYTYPE = 16;
    var SCALED_TRIANGLE_MESH_SHAPE_PROXYTYPE = 17;

    // used for demo integration FAST/Swift collision library and Bullet:
    var FAST_CONCAVE_MESH_PROXYTYPE = 18;

    // terrain:
    var TERRAIN_SHAPE_PROXYTYPE = 19;

    // used for GIMPACT Trimesh integration:
    var GIMPACT_SHAPE_PROXYTYPE = 20;

    // multimaterial mesh:
    var MULTIMATERIAL_TRIANGLE_MESH_PROXYTYPE = 21;

    var EMPTY_SHAPE_PROXYTYPE = 22;
    var STATIC_PLANE_PROXYTYPE = 23;
    var CONCAVE_SHAPES_END_HERE = 24;
    var COMPOUND_SHAPE_PROXYTYPE = 25;

    var SOFTBODY_SHAPE_PROXYTYPE = 26;

    var INVALID_SHAPE_PROXYTYPE = 27;

    var MAX_BROADPHASE_COLLISION_TYPES = 28;
	
	public inline function new(v:Int)
        this = v;

    public inline function toInt():Int
    	return this;
}