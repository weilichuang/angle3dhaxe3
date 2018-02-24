package angle3d.scene;
import angle3d.error.Assert;

/**
 * An abstract class for implementations that perform grouping of geometries
 * via instancing or batching.
 */
class GeometryGroupNode extends Node {
	public static function getGeometryStartIndex(geom:Geometry):Int {
		#if debug
		Assert.assert(geom.startIndex == -1);
		#end

		return geom.startIndex;
	}

	private static function setGeometryStartIndex(geom:Geometry, startIndex:Int):Void {
		#if debug
		Assert.assert(geom.startIndex < -1);
		#end

		geom.startIndex = startIndex;
	}

	/**
	 * Construct a `GeometryGroupNode`
	 *
	 * @param name The name of the GeometryGroupNode.
	 */
	public function new(name:String) {
		super(name);

	}

	/**
	 * Called by `Geometry` to specify that its world transform
	 * has been changed.
	 *
	 * @param geom The Geometry whose transform changed.
	 */
	public function onTransformChange(geom:Geometry):Void {

	}

	/**
	 * Called by `Geometry` to specify that its `Geometry.setMaterial`
	 * has been changed.
	 *
	 * @param geom The Geometry whose material changed.
	 */
	public function onMaterialChange(geom:Geometry):Void {

	}

	/**
	 * Called by `Geometry` to specify that its `Geometry.setMesh`
	 * has been changed.
	 *
	 * This is also called when the geometry's `Geometry.setLodLevel` changes.
	 *
	 * @param geom The Geometry whose mesh changed.
	 */
	public function onMeshChange(geom:Geometry):Void {

	}

	/**
	 * Called by `Geometry` to specify that it
	 * has been unassociated from its `GeoemtryGroupNode`.
	 *
	 * Unassociation occurs when the `Geometry` is
	 * `Spatial.removeFromParent` from its parent `Node`.
	 *
	 * @param geom The Geometry which is being unassociated.
	 */
	public function onGeometryUnassociated(geom:Geometry):Void {

	}
}