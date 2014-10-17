package org.angle3d.bullet.debug;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.objects.PhysicsVehicle;
import org.angle3d.bullet.objects.VehicleWheel;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.debug.Arrow;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;

/**
 * ...
 * @author weilichuang
 */
class BulletVehicleDebugControl extends AbstractPhysicsDebugControl
{
	private var body:PhysicsVehicle;
    private var location:Vector3f = new Vector3f();
    private var rotation:Quaternion = new Quaternion();
    private var suspensionNode:Node;

	public function new(debugAppState:BulletDebugAppState,body:PhysicsVehicle) 
	{
		super(debugAppState);
		
		this.body = body;
        suspensionNode = new Node("Suspension");
        createVehicle();
	}
	
	override public function setSpatial(spatial:Spatial):Void 
	{
		if (spatial != null && Std.is(spatial,Node))
		{
            var node:Node = cast spatial;
            node.attachChild(suspensionNode);
        } 
		else if (spatial == null && this.spatial != null)
		{
            var node:Node = cast this.spatial;
            node.detachChild(suspensionNode);
        }
		super.setSpatial(spatial);
	}
	
	private function createVehicle():Void
	{
        suspensionNode.detachAllChildren();
        for (i in 0...body.getNumWheels())
		{
            var physicsVehicleWheel:VehicleWheel = body.getWheel(i);
            var location:Vector3f = physicsVehicleWheel.getLocation().clone();
            var direction:Vector3f = physicsVehicleWheel.getDirection().clone();
            var axle:Vector3f = physicsVehicleWheel.getAxle().clone();
            var restLength:Float = physicsVehicleWheel.getRestLength();
            var radius:Float = physicsVehicleWheel.getRadius();

            var locArrow:Arrow = new Arrow(location);
            var axleArrow:Arrow = new Arrow(axle.normalizeLocal().scaleLocal(0.3));
            var wheelArrow:Arrow = new Arrow(direction.normalizeLocal().scaleLocal(radius));
            var dirArrow:Arrow = new Arrow(direction.normalizeLocal().scaleLocal(restLength));
            var locGeom:Geometry = new Geometry("WheelLocationDebugShape" + i, locArrow);
            var dirGeom:Geometry = new Geometry("WheelDirectionDebugShape" + i, dirArrow);
            var axleGeom:Geometry = new Geometry("WheelAxleDebugShape" + i, axleArrow);
            var wheelGeom:Geometry = new Geometry("WheelRadiusDebugShape" + i, wheelArrow);
            dirGeom.setLocalTranslation(location);
            axleGeom.setLocalTranslation(location.add(direction));
            wheelGeom.setLocalTranslation(location.add(direction));
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
	
	override function controlUpdate(tpf:Float):Void 
	{
		for (i in 0...body.getNumWheels())
		{
            var physicsVehicleWheel:VehicleWheel = body.getWheel(i);
            var location:Vector3f = physicsVehicleWheel.getLocation().clone();
            var direction:Vector3f = physicsVehicleWheel.getDirection().clone();
            var axle:Vector3f = physicsVehicleWheel.getAxle().clone();
            var restLength:Float = physicsVehicleWheel.getRestLength();
            var radius:Float = physicsVehicleWheel.getRadius();

            var locGeom:Geometry = cast suspensionNode.getChildByName("WheelLocationDebugShape" + i);
            var dirGeom:Geometry = cast suspensionNode.getChildByName("WheelDirectionDebugShape" + i);
            var axleGeom:Geometry = cast suspensionNode.getChildByName("WheelAxleDebugShape" + i);
            var wheelGeom:Geometry = cast suspensionNode.getChildByName("WheelRadiusDebugShape" + i);

            var locArrow:Arrow = cast locGeom.getMesh();
            locArrow.setArrowExtent(location);
            var axleArrow:Arrow = cast axleGeom.getMesh();
            axleArrow.setArrowExtent(axle.normalizeLocal().scaleLocal(0.3));
            var wheelArrow:Arrow = cast wheelGeom.getMesh();
            wheelArrow.setArrowExtent(direction.normalizeLocal().scaleLocal(radius));
            var dirArrow:Arrow = cast dirGeom.getMesh();
            dirArrow.setArrowExtent(direction.normalizeLocal().scaleLocal(restLength));

            dirGeom.setLocalTranslation(location);
            axleGeom.setLocalTranslation(location.addLocal(direction));
            wheelGeom.setLocalTranslation(location);
        }
        applyPhysicsTransform(body.getPhysicsLocation(location), body.getPhysicsRotation(rotation));
	}
}