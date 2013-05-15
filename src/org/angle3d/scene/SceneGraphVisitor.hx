package org.angle3d.scene;

/**
 * <code>SceneGraphVisitor</code> is used to traverse the scene
 * graph tree.
 * Use by calling {@link Spatial#depthFirstTraversal(org.angle3d.scene.SceneGraphVisitor) }
 * or {@link Spatial#breadthFirstTraversal(org.angle3d.scene.SceneGraphVisitor)}.
 */
interface SceneGraphVisitor
{
	function visit(spatial:Spatial):Void;
}

