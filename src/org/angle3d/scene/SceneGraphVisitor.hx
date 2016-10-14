package org.angle3d.scene;

/**
 * `SceneGraphVisitorAdapter` is used to traverse the scene graph tree. 
 * Use by calling `Spatial.depthFirstTraversal` or `Spatial.breadthFirstTraversal`.
 */
interface SceneGraphVisitor
{
	/**
     * Called when a spatial is visited in the scene graph.
     * 
     * @param spatial The visited spatial
     */
	function visit(spatial:Spatial):Void;
}

