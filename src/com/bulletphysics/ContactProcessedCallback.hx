package com.bulletphysics;
import com.bulletphysics.collision.narrowphase.ManifoldPoint;

/**
 * Called when existing contact between two collision objects has been processed.
 * @author weilichuang
 */
interface ContactProcessedCallback
{
	function contactProcessed(cp:ManifoldPoint, body0:Dynamic, body1:Dynamic):Bool;
}