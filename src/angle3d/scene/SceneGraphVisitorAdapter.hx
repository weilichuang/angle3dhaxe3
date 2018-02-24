package angle3d.scene;

/**
 * `SceneGraphVisitorAdapter` is used to traverse the scene
 * graph tree. The adapter version of the interface simply separates
 * between the geometries and the nodes by
 * supplying visit methods that take them.
 * Use by calling `Spatial.depthFirstTraversal` or `Spatial.breadthFirstTraversal`.
 */
class SceneGraphVisitorAdapter implements SceneGraphVisitor {

	public function new() {
	}

	public function visit(spatial:Spatial):Void {
		if (Std.is(spatial,Geometry)) {
			visitGeometry(cast spatial);
		} else
		{
			visitNode(cast spatial);
		}
	}

	/**
	 * Called when a `Geometry` is visited.
	 *
	 * @param geom The visited geometry
	 */
	private function visitGeometry(geom:Geometry):Void {
	}

	/**
	 * Called when a `Node` is visited.
	 *
	 * @param geom The visited node
	 */
	private function visitNode(node:Node):Void {
		if (node == null) {
			return;
		}
	}
}

