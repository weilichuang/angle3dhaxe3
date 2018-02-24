package angle3d.scene.shape;

import angle3d.math.Vector3f;
import angle3d.scene.mesh.BufferType;

/**
 * A box with solid (filled) faces.
 *
 */
class Box extends AbstractBox {
	private static var GEOMETRY_INDICES_DATA:Array<UInt>;
	private static var GEOMETRY_NORMALS_DATA:Array<Float>;
	private static var GEOMETRY_COLORS_DATA:Array<Float>;
	private static var GEOMETRY_TEXTURE_DATA:Array<Float>;
	static function __init__():Void {
		var array:Array<UInt> = [0, 1, 2, 0, 2, 3, // back
		4, 5, 6, 4, 6, 7, // right
		8, 9, 10, 8, 10, 11, // front
		12, 13, 14, 12, 14, 15, // left
		16, 17, 18, 16, 18, 19, // top
		20, 21, 22, 20, 22, 23 // bottom
								];

		GEOMETRY_INDICES_DATA = array;

		GEOMETRY_NORMALS_DATA = [0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, // back
		1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, // right
		0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, // front
		-1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, // left
		0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, 0.0, 1.0, 0.0, // top
		0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0, 0.0, -1.0, 0.0 // bottom
								];

		GEOMETRY_COLORS_DATA = [1.0, 0.5, 0.3, 1,
		1.0, 0.0, 0.0, 1,
		1.0, 0.1, 0.3, 1,
		1.0, 0.4, 0.2, 1, // back
		0.0, 0.4, 1.0, 1,
		0.0, 0.1, 1.0, 1,
		0.0, 0.2, 1.0, 1,
		0.9, 0.5, 1.0, 1, // right
		1.0, 0.8, 0.0, 1,
		1.0, 0.6, 0.0, 1,
		1.0, 0.0, 0.4, 1,
		1.0, 0.8, 0.0, 1, // front
		0.2, 0.2, 1.0, 1,
		0.7, 0.7, 1.0, 1,
		0.2, 0.3, 1.0, 1,
		0.0, 0.2, 1.0, 1, // left
		0.5, 1.0, 0.3, 1,
		0.1, 1.0, 0.6, 1,
		0.1, 1.0, 0.0, 1,
		0.0, 1.0, 0.1, 1, // top
		0.0, 1.0, 0.8, 1,
		0.6, 1.0, 0.4, 1,
		0.3, 1.0, 0.5, 1,
		0.7, 1.0, 0.1, 1 // bottom
							   ];

		GEOMETRY_TEXTURE_DATA = [1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, // back
		1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, // right
		1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, // front
		1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, // left
		1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0, // top
		1.0, 0.0, 0.0, 0.0, 0.0, 1.0, 1.0, 1.0 // bottom
								];
	}

	/**
	 * Creates a new box.
	 * <p>
	 * The box has a center of 0,0,0 and extends in the out from the center by
	 * the given amount in <em>each</em> direction. So, for example, a box
	 * with extent of 0.5 would be the unit cube.
	 *
	 * @param name the name of the box.
	 * @param x the size of the box along the x axis, in both directions.
	 * @param y the size of the box along the y axis, in both directions.
	 * @param z the size of the box along the z axis, in both directions.
	 */
	public function new(x:Float, y:Float, z:Float, center:Vector3f = null) {
		super();
		if (center == null) {
			center = new Vector3f(0, 0, 0);
		}
		updateGeometryByXYZ(center, x, y, z);
	}

	public function clone():Box {
		return new Box(xExtent, yExtent, zExtent, center);
	}

	override private function duUpdateGeometryIndices():Void {
		setIndices(GEOMETRY_INDICES_DATA.concat());
	}

	override private function duUpdateGeometryColors():Void {
		setVertexBuffer(BufferType.COLOR, 4, GEOMETRY_COLORS_DATA.concat());
	}

	override private function duUpdateGeometryNormals():Void {
		setVertexBuffer(BufferType.NORMAL, 3, GEOMETRY_NORMALS_DATA.concat());
	}

	override private function duUpdateGeometryTextures():Void {
		setVertexBuffer(BufferType.TEXCOORD, 2, GEOMETRY_TEXTURE_DATA.concat());
	}

	override private function duUpdateGeometryVertices():Void {
		var v:Array<Vector3f> = computeVertices();

		var vertices:Array<Float> = Vector.ofArray([v[0].x, v[0].y, v[0].z, v[1].x, v[1].y, v[1].z, v[2].x, v[2].y, v[2].z, v[3].x, v[3].y, v[3].z, // back
		v[1].x, v[1].y, v[1].z, v[4].x, v[4].y, v[4].z, v[6].x, v[6].y, v[6].z, v[2].x, v[2].y, v[2].z, // right
		v[4].x, v[4].y, v[4].z, v[5].x, v[5].y, v[5].z, v[7].x, v[7].y, v[7].z, v[6].x, v[6].y, v[6].z, // front
		v[5].x, v[5].y, v[5].z, v[0].x, v[0].y, v[0].z, v[3].x, v[3].y, v[3].z, v[7].x, v[7].y, v[7].z, // left
		v[2].x, v[2].y, v[2].z, v[6].x, v[6].y, v[6].z, v[7].x, v[7].y, v[7].z, v[3].x, v[3].y, v[3].z, // top
		v[0].x, v[0].y, v[0].z, v[5].x, v[5].y, v[5].z, v[4].x, v[4].y, v[4].z, v[1].x, v[1].y, v[1].z // bottom
												   ]);

		v = null;

		setVertexBuffer(BufferType.POSITION, 3, vertices);
	}
}

