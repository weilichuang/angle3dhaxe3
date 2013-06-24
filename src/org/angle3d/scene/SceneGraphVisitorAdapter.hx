package org.angle3d.scene;


/**
 * <code>SceneGraphVisitorAdapter</code> is used to traverse the scene
 * graph tree. The adapter version of the interface simply separates
 * between the {@link Geometry geometries} and the {@link Node nodes} by
 * supplying visit methods that take them.
 * Use by calling {@link Spatial#depthFirstTraversal(org.angle3d.scene.SceneGraphVisitor) }
 * or {@link Spatial#breadthFirstTraversal(org.angle3d.scene.SceneGraphVisitor)}.
 */
class SceneGraphVisitorAdapter implements SceneGraphVisitor
{

	public function new()
	{
	}

	public function visit(spatial:Spatial):Void
	{
		if (Std.is(spatial,Geometry))
		{
			visitGeometry(Std.instance(spatial, Geometry));
		}
		else
		{
			visitNode(Std.instance(spatial, Node));
		}
	}


	/**
	 * Called when a {@link Geometry} is visited.
	 *
	 * @param geom The visited geometry
	 */
	private function visitGeometry(geom:Geometry):Void
	{
	}

	/**
	 * Called when a {@link visit} is visited.
	 *
	 * @param geom The visited node
	 */
	private function visitNode(node:Node):Void
	{
		if (node == null)
		{
			return;
		}

	}
}

