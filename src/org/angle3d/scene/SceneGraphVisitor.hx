package org.angle3d.scene;

/**
 * `SceneGraphVisitor` is used to traverse the scene graph tree.
 */
interface SceneGraphVisitor
{
	function visit(spatial:Spatial):Void;
}

