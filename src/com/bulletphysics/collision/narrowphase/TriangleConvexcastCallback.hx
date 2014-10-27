package com.bulletphysics.collision.narrowphase;

import com.bulletphysics.collision.narrowphase.CastResult;
import com.bulletphysics.collision.shapes.ConvexShape;
import com.bulletphysics.collision.shapes.TriangleCallback;
import com.bulletphysics.collision.shapes.TriangleShape;
import com.bulletphysics.linearmath.Transform;
import vecmath.Vector3f;

/**
 * ...
 * @author weilichuang
 */
class TriangleConvexcastCallback implements TriangleCallback
{
	public var convexShape:ConvexShape;
    public var convexShapeFrom:Transform = new Transform();
    public var convexShapeTo:Transform = new Transform();
    public var triangleToWorld:Transform = new Transform();
    public var hitFraction:Float;
    public var triangleCollisionMargin:Float;
	
	private var triangleShape:TriangleShape = new TriangleShape(null, null, null);
	private var simplexSolver:VoronoiSimplexSolver = new VoronoiSimplexSolver();
	private var gjkEpaPenetrationSolver:GjkEpaPenetrationDepthSolver = new GjkEpaPenetrationDepthSolver();
	private var convexCaster:SubsimplexConvexCast = new SubsimplexConvexCast();
	private var castResult:CastResult = new CastResult();

    public function new(convexShape:ConvexShape, convexShapeFrom:Transform, convexShapeTo:Transform, triangleToWorld:Transform, triangleCollisionMargin:Float)
	{
        this.convexShape = convexShape;
        this.convexShapeFrom.fromTransform(convexShapeFrom);
        this.convexShapeTo.fromTransform(convexShapeTo);
        this.triangleToWorld.fromTransform(triangleToWorld);
        this.hitFraction = 1;
        this.triangleCollisionMargin = triangleCollisionMargin;
    }
	
	public function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void
	{
		triangleShape.init(triangle[0], triangle[1], triangle[2]);
        triangleShape.setMargin(triangleCollisionMargin);

        //#define  USE_SUBSIMPLEX_CONVEX_CAST 1
        //if you reenable USE_SUBSIMPLEX_CONVEX_CAST see commented out code below
        //#ifdef USE_SUBSIMPLEX_CONVEX_CAST
        // TODO: implement ContinuousConvexCollision
        convexCaster.init(convexShape, triangleShape, simplexSolver);
        //#else
        // //btGjkConvexCast	convexCaster(m_convexShape,&triangleShape,&simplexSolver);
        //btContinuousConvexCollision convexCaster(m_convexShape,&triangleShape,&simplexSolver,&gjkEpaPenetrationSolver);
        //#endif //#USE_SUBSIMPLEX_CONVEX_CAST

        castResult.fraction = 1;
        if (convexCaster.calcTimeOfImpact(convexShapeFrom, convexShapeTo, triangleToWorld, triangleToWorld, castResult))
		{
            // add hit
            if (castResult.normal.lengthSquared() > 0.0001)
			{
                if (castResult.fraction < hitFraction) 
				{

					/* btContinuousConvexCast's normal is already in world space */
                    /*
                    //#ifdef USE_SUBSIMPLEX_CONVEX_CAST
					// rotate normal into worldspace
					convexShapeFrom.basis.transform(castResult.normal);
					//#endif //USE_SUBSIMPLEX_CONVEX_CAST
					*/
                    castResult.normal.normalize();

                    reportHit(castResult.normal,
                            castResult.hitPoint,
                            castResult.fraction,
                            partId,
                            triangleIndex);
                }
            }
        }
	}

    public function reportHit(hitNormalLocal:Vector3f, hitPointLocal:Vector3f, hitFraction:Float, partId:Int,  triangleIndex:Int):Float
	{
		return 0;
	}
}