package angle3d.bullet.collision.shapes;
import com.bulletphysics.collision.shapes.ConvexHullShape;
import com.bulletphysics.util.ObjectArrayList;
import angle3d.math.Vector3f;
import angle3d.bullet.util.Converter;
import angle3d.scene.mesh.BufferType;
import angle3d.scene.mesh.Mesh;

/**
 * ...

 */
class HullCollisionShape extends CollisionShape {
	private var points:Array<Float>;

	public function new() {
		super();
	}

	public function fromMesh(mesh:Mesh):Void {
		this.points = getPoints(mesh);
		createShape(this.points);
	}

	public function fromPoints(points:Array<Float>):Void {
		this.points = points;
		createShape(this.points);
	}

	private function createShape(points:Array<Float>):Void {
		var pointList:ObjectArrayList<Vector3f> = new ObjectArrayList<Vector3f>();

		var i:Int = 0;
		while (i < points.length) {
			pointList.add(new Vector3f(points[i], points[i + 1], points[i + 2]));
			i += 3;
		}

		cShape = new ConvexHullShape(pointList);
		cShape.setLocalScaling(getScale());
		cShape.setMargin(margin);
	}

	private function getPoints(mesh:Mesh):Array<Float> {
		var vertices = mesh.getVertexBuffer(BufferType.POSITION).getData();

		var components:Int = mesh.getVertexCount() * 3;
		var pointsArray:Array<Float> = [];

		var i:Int = 0;
		while (i < components) {
			pointsArray[i] = vertices[i];
			pointsArray[i + 1] = vertices[i+1];
			pointsArray[i + 2] = vertices[i + 2];
			i += 3;
		}
		return pointsArray;
	}
}