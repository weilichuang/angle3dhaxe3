package com.bulletphysics.collision.narrowphase;
import org.angle3d.math.Vector3f;

/**
 * SimplexSolverInterface can incrementally calculate distance between origin and
 * up to 4 vertices. Used by GJK or Linear Casting. Can be implemented by the
 * Johnson-algorithm or alternative approaches based on voronoi regions or barycentric
 * coordinates.
 * 
 * @author weilichuang
 */
interface SimplexSolverInterface
{
	function reset():Void;

    function addVertex(w:Vector3f, p:Vector3f, q:Vector3f):Void;

    function closest(v:Vector3f):Bool;

    function maxVertex():Float;

    function  fullSimplex():Bool;

    function getSimplex(pBuf:Array<Vector3f>, qBuf:Array<Vector3f>, yBuf:Array<Vector3f>):Int;

    function inSimplex(w:Vector3f):Bool;

    function backup_closest(v:Vector3f):Void;
	
    function emptySimplex():Bool;

    function compute_points(p1:Vector3f, p2:Vector3f):Void;

    function numVertices():Int;
}