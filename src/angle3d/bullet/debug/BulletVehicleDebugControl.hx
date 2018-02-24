package angle3d.bullet.debug;
import angle3d.bullet.collision.shapes.CollisionShape;
import angle3d.bullet.objects.PhysicsVehicle;
import angle3d.bullet.objects.VehicleWheel;
import angle3d.math.Quaternion;
import angle3d.math.Vector3f;
import angle3d.scene.debug.Arrow;
import angle3d.scene.Geometry;
import angle3d.scene.Node;
import angle3d.scene.Spatial;
import angle3d.utils.Logger;

class BulletVehicleDebugControl extends AbstractPhysicsDebugControl {
	private var body:PhysicsVehicle;
	private var location:Vector3f = new Vector3f();
	private var rotation:Quaternion = new Quaternion();
	private var suspensionNode:Node;

	private var tmpLocation:Vector3f = new Vector3f();
	private var tmpDirection:Vector3f = new Vector3f();
	private var tmpAxle:Vector3f = new Vector3f();

	public function new(debugAppState:BulletDebugAppState,body:PhysicsVehicle) {
		super(debugAppState);

		this.body = body;
		suspensionNode = new Node("Suspension");
		createVehicle();
	}

	override public function setSpatial(spatial:Spatial):Void {
		if (spatial != null && Std.is(spatial,Node)) {
			var node:Node = cast spatial;
			node.attachChild(suspensionNode);
		} else if (spatial == null && this.spatial != null) {
			var node:Node = cast this.spatial;
			node.detachChild(suspensionNode);
		}
		super.setSpatial(spatial);
	}

	private function createVehicle():Void {
		suspensionNode.detachAllChildren();
		for (i in 0...body.getNumWheels()) {
			var physicsVehicleWheel:VehicleWheel = body.getWheel(i);

			tmpLocation.copyFrom(physicsVehicleWheel.getLocation());
			tmpDirection.copyFrom(physicsVehicleWheel.getDirection());
			tmpAxle.copyFrom(physicsVehicleWheel.getAxle());

			var restLength:Float = physicsVehicleWheel.getRestLength();
			var radius:Float = physicsVehicleWheel.getRadius();

			var locArrow:Arrow = new Arrow(tmpLocation);
			var axleArrow:Arrow = new Arrow(tmpAxle.normalizeLocal().scaleLocal(0.3));
			var wheelArrow:Arrow = new Arrow(tmpDirection.normalizeLocal().scaleLocal(radius));
			var dirArrow:Arrow = new Arrow(tmpDirection.normalizeLocal().scaleLocal(restLength));
			var locGeom:Geometry = new Geometry("WheelLocationDebugShape" + i, locArrow);
			var dirGeom:Geometry = new Geometry("WheelDirectionDebugShape" + i, dirArrow);
			var axleGeom:Geometry = new Geometry("WheelAxleDebugShape" + i, axleArrow);
			var wheelGeom:Geometry = new Geometry("WheelRadiusDebugShape" + i, wheelArrow);
			dirGeom.setLocalTranslation(tmpLocation);
			axleGeom.setLocalTranslation(tmpLocation.add(tmpDirection));
			wheelGeom.setLocalTranslation(tmpLocation.add(tmpDirection));
			locGeom.setMaterial(debugAppState.DEBUG_MAGENTA);
			dirGeom.setMaterial(debugAppState.DEBUG_MAGENTA);
			axleGeom.setMaterial(debugAppState.DEBUG_MAGENTA);
			wheelGeom.setMaterial(debugAppState.DEBUG_MAGENTA);
			suspensionNode.attachChild(locGeom);
			suspensionNode.attachChild(dirGeom);
			suspensionNode.attachChild(axleGeom);
			suspensionNode.attachChild(wheelGeom);
		}
	}

	override function controlUpdate(tpf:Float):Void {
		for (i in 0...body.getNumWheels()) {
			var physicsVehicleWheel:VehicleWheel = body.getWheel(i);

			tmpLocation.copyFrom(physicsVehicleWheel.getLocation());
			tmpDirection.copyFrom(physicsVehicleWheel.getDirection());
			tmpAxle.copyFrom(physicsVehicleWheel.getAxle());

			var restLength:Float = physicsVehicleWheel.getRestLength();
			var radius:Float = physicsVehicleWheel.getRadius();

			var locGeom:Geometry = cast suspensionNode.getChildByName("WheelLocationDebugShape" + i);
			var dirGeom:Geometry = cast suspensionNode.getChildByName("WheelDirectionDebugShape" + i);
			var axleGeom:Geometry = cast suspensionNode.getChildByName("WheelAxleDebugShape" + i);
			var wheelGeom:Geometry = cast suspensionNode.getChildByName("WheelRadiusDebugShape" + i);

			var locArrow:Arrow = cast locGeom.getMesh();
			locArrow.setArrowExtent(tmpLocation);

			var axleArrow:Arrow = cast axleGeom.getMesh();
			axleArrow.setArrowExtent(tmpAxle.normalizeLocal().scaleLocal(0.3));

			var wheelArrow:Arrow = cast wheelGeom.getMesh();
			wheelArrow.setArrowExtent(tmpDirection.normalizeLocal().scaleLocal(radius));

			var dirArrow:Arrow = cast dirGeom.getMesh();
			dirArrow.setArrowExtent(tmpDirection.normalizeLocal().scaleLocal(restLength));

			dirGeom.setLocalTranslation(tmpLocation);
			axleGeom.setLocalTranslation(tmpLocation.addLocal(tmpDirection));
			wheelGeom.setLocalTranslation(tmpLocation);
		}
		applyPhysicsTransform(body.getPhysicsLocation(location), body.getPhysicsRotation(rotation),this.spatial);
	}
}