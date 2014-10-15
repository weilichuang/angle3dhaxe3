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
class TriangleConvexcastCallback extends TriangleCallback
{
	public var convexShape:ConvexShape;
    public var convexShapeFrom:Transform = new Transform();
    public var convexShapeTo:Transform = new Transform();
    public var triangleToWorld:Transform = new Transform();
    public var hitFraction:Float;
    public var triangleCollisionMargin:Float;

    public function new(convexShape:ConvexShape, convexShapeFrom:Transform, convexShapeTo:Transform, triangleToWorld:Transform, triangleCollisionMargin:Float)
	{
		super();
        this.convexShape = convexShape;
        this.convexShapeFrom.fromTransform(convexShapeFrom);
        this.convexShapeTo.fromTransform(convexShapeTo);
        this.triangleToWorld.fromTransform(triangleToWorld);
        this.hitFraction = 1;
        this.triangleCollisionMargin = triangleCollisionMargin;
    }
	
	override public function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void
	{
		var triangleShape:TriangleShape = new TriangleShape(triangle[0], triangle[1], triangle[2]);
        triangleShape.setMargin(triangleCollisionMargin);

        var simplexSolver:VoronoiSimplexSolver = new VoronoiSimplexSolver();
        var gjkEpaPenetrationSolver:GjkEpaPenetrationDepthSolver = new GjkEpaPenetrationDepthSolver();

        //#define  USE_SUBSIMPLEX_CONVEX_CAST 1
        //if you reenable USE_SUBSIMPLEX_CONVEX_CAST see commented out code below
        //#ifdef USE_SUBSIMPLEX_CONVEX_CAST
        // TODO: implement ContinuousConvexCollision
        var convexCaster:SubsimplexConvexCast = new SubsimplexConvexCast(convexShape, triangleShape, simplexSolver);
        //#else
        // //btGjkConvexCast	convexCaster(m_convexShape,&triangleShape,&simplexSolver);
        //btContinuousConvexCollision convexCaster(m_convexShape,&triangleShape,&simplexSolver,&gjkEpaPenetrationSolver);
        //#endif //#USE_SUBSIMPLEX_CONVEX_CAST

        var castResult:CastResult = new CastResult();
        castResult.fraction = 1;
        if (convexCaster.calcTimeOfImpact(convexShapeFrom, convexShapeTo, triangleToWorld, triangleToWorld, castResult)) {
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