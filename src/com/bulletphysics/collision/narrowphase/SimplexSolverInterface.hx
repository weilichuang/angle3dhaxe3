package com.bulletphysics.collision.narrowphase;
import vecmath.Vector3f;

/**
 * SimplexSolverInterface can incrementally calculate distance between origin and
 * up to 4 vertices. Used by GJK or Linear Casting. Can be implemented by the
 * Johnson-algorithm or alternative approaches based on voronoi regions or barycentric
 * coordinates.
 * 
 * @author weilichuang
 */
class SimplexSolverInterface
{
	public function new()
	{
	}

	public function reset():Void
	{
		
	}

    public function addVertex(w:Vector3f, p:Vector3f, q:Vector3f):Void
	{
		
	}

    public function closest(v:Vector3f):Bool
	{
		return false;
	}

    public function maxVertex():Float
	{
		return 0;
	}

    public function  fullSimplex():Bool
	{
		return false;
	}

    public function getSimplex(pBuf:Array<Vector3f>, qBuf:Array<Vector3f>, yBuf:Array<Vector3f>):Int
	{
		return 0;
	}

    public function inSimplex(w:Vector3f):Bool
	{
		return false;
	}

    public function backup_closest(v:Vector3f):Void
	{
		
	}

    public function emptySimplex():Bool
	{
		return false;
	}

    public function compute_points(p1:Vector3f, p2:Vector3f):Void
	{
		
	}

    public function numVertices():Int
	{
		return 0;
	}
	
}