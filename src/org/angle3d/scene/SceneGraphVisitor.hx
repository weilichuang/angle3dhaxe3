package org.angle3d.scene;

/**
 * `SceneGraphVisitor` is used to traverse the scene
 * graph tree.
 * Use by calling {Spatial#depthFirstTraversal(org.angle3d.scene.SceneGraphVisitor) }
 * or {Spatial#breadthFirstTraversal(org.angle3d.scene.SceneGraphVisitor)}.
 */
interface SceneGraphVisitor
{
	function visit(spatial:Spatial):Void;
}

