package angle3d.bullet.debug;
import angle3d.bullet.collision.shapes.CollisionShape;
import angle3d.bullet.objects.PhysicsGhostObject;
import angle3d.bullet.util.DebugShapeFactory;
import angle3d.math.Quaternion;
import angle3d.math.Vector3f;
import angle3d.scene.Node;
import angle3d.scene.Spatial;

/**
 * ...

 */
class BulletGhostObjectDebugControl extends AbstractPhysicsDebugControl {
	private var body:PhysicsGhostObject;
	private var location:Vector3f = new Vector3f();
	private var rotation:Quaternion = new Quaternion();
	private var myShape:CollisionShape;
	private var geom:Spatial;

	public function new(debugAppState:BulletDebugAppState,body:PhysicsGhostObject) {
		super(debugAppState);

		this.body = body;
		myShape = body.getCollisionShape();
		this.geom = DebugShapeFactory.getDebugShape(body.getCollisionShape());
		this.geom.name = Std.string(body);
		geom.setMaterial(debugAppState.DEBUG_YELLOW);
	}

	override public function setSpatial(spatial:Spatial):Void {
		if (spatial != null && Std.is(spatial,Node)) {
			var node:Node = cast spatial;
			node.attachChild(geom);
		} else if (spatial == null && this.spatial != null) {
			var node:Node = cast this.spatial;
			node.detachChild(geom);
		}
		super.setSpatial(spatial);
	}

	override function controlUpdate(tpf:Float):Void {
		if (myShape != body.getCollisionShape()) {
			var node:Node = cast this.spatial;
			node.detachChild(geom);
			geom = DebugShapeFactory.getDebugShape(body.getCollisionShape());
			geom.setMaterial(debugAppState.DEBUG_YELLOW);
			node.attachChild(geom);
		}
		applyPhysicsTransform(body.getPhysicsLocation(location), body.getPhysicsRotation(rotation));
		geom.setLocalScale(body.getCollisionShape().getScale());
	}

}