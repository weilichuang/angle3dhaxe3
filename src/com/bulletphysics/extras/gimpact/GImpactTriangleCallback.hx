package com.bulletphysics.extras.gimpact;

import com.bulletphysics.collision.dispatch.CollisionObject;
import com.bulletphysics.collision.shapes.TriangleCallback;

import vecmath.Vector3f;

/**
 * @author weilichuang
 */
class GImpactTriangleCallback extends TriangleCallback 
{

    public var algorithm:GImpactCollisionAlgorithm;
    public var body0:CollisionObject;
    public var body1:CollisionObject;
    public var gimpactshape0:GImpactShapeInterface;
    public var swapped:Bool;
    public var margin:Float;
	
	override public function processTriangle(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void 
	{
		var tri1:TriangleShapeEx = new TriangleShapeEx(triangle[0], triangle[1], triangle[2]);
        tri1.setMargin(margin);
        if (swapped) 
		{
            algorithm.setPart0(partId);
            algorithm.setFace0(triangleIndex);
        } 
		else
		{
            algorithm.setPart1(partId);
            algorithm.setFace1(triangleIndex);
        }
        algorithm.gimpact_vs_shape(body0, body1, gimpactshape0, tri1, swapped);
	}

}
