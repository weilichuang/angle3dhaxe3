package examples.bullet;

import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.shapes.BoxCollisionShape;
import org.angle3d.bullet.collision.shapes.CompoundCollisionShape;
import org.angle3d.bullet.collision.shapes.MeshCollisionShape;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.control.VehicleControl;
import org.angle3d.bullet.joints.SliderJoint;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Cylinder;
import org.angle3d.scene.shape.WireframeGrid;
import org.angle3d.scene.Spatial;
import org.angle3d.scene.WireframeGeometry;
import org.angle3d.utils.Stats;

/**
 * ...
 
 */
class TestAttachDriver extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestAttachDriver());
	}
	
	private var bulletAppState:BulletAppState;
	private var vehicle:VehicleControl;
	private var driver:RigidBodyControl;
	private var bridge:RigidBodyControl;
	private var slider:SliderJoint;
	
	private var accelerationForce:Float = 1000.0;
    private var brakeForce:Float = 100.0;
    private var steeringValue:Float = 0;
    private var accelerationValue:Float = 0;
    private var jumpForce:Vector3f = new Vector3f(0, 3000, 0);
	private var paused:Bool = false;
	private var dragToRotate:Bool = false;
	
	public function new() 
	{
		super();
		
	}
	
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		//flyCam.setEnabled(false);
		
		bulletAppState = new BulletAppState(true);
        mStateManager.attach(bulletAppState);
		bulletAppState.setEnabled(!paused);

		//PhysicsTestHelper.createPhysicsTestWorld(scene, bulletAppState.getPhysicsSpace());
		PhysicsTestHelper.createBallShooter(this, scene, bulletAppState.getPhysicsSpace());
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setColor("u_MaterialColor", Color.Pink());
		
		var wireBox:WireframeGrid = new WireframeGrid(20, 100, WireframeGrid.PLANE_XZ);
        var floorGeom:WireframeGeometry = new WireframeGeometry("Floor", wireBox);
        floorGeom.setLocalTranslation(new Vector3f(0, -3, 0));
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/wireframe.mat");
		material.setColor("u_color", Color.fromColor(0x000099));
		floorGeom.setMaterial(material);

		var floorControl:RigidBodyControl = new RigidBodyControl(new MeshCollisionShape(new Box(100, 1, 100)), 0);
        floorGeom.addControl(floorControl);
		floorControl.showDebug = false;
		
        scene.attachChild(floorGeom);
        getPhysicsSpace().add(floorGeom);
		
		
        //create a compound shape and attach the BoxCollisionShape for the car body at 0,1,0
        //this shifts the effective center of mass of the BoxCollisionShape to 0,-1,0
        var compoundShape:CompoundCollisionShape = new CompoundCollisionShape();
        var box:BoxCollisionShape = new BoxCollisionShape(new Vector3f(1.2, 0.5, 2.4));
        compoundShape.addChildShape(box, new Vector3f(0, 1, 0));
		

        //create vehicle node
        var vehicleNode:Node = new Node("vehicleNode");
        vehicle = new VehicleControl(compoundShape, 800);
        vehicleNode.addControl(vehicle);

        //setting suspension values for wheels, this can be a bit tricky
        //see also https://docs.google.com/Doc?docid=0AXVUZ5xw6XpKZGNuZG56a3FfMzU0Z2NyZnF4Zmo&hl=en
        var stiffness:Float = 60.0;//200=f1 car
        var compValue:Float = .3; //(should be lower than damp)
        var dampValue:Float = .4;
        vehicle.setSuspensionCompression(compValue * 2.0 * Math.sqrt(stiffness));
        vehicle.setSuspensionDamping(dampValue * 2.0 * Math.sqrt(stiffness));
        vehicle.setSuspensionStiffness(stiffness);
        vehicle.setMaxSuspensionForce(10000.0);

        //Create four wheels and add them at their locations
        var wheelDirection:Vector3f = new Vector3f(0, -1, 0); // was 0, -1, 0
        var wheelAxle:Vector3f = new Vector3f(-1, 0, 0); // was -1, 0, 0
        var radius:Float = 0.5;
        var restLength:Float = 0.3;
        var yOff:Float = 0.5;
        var xOff:Float = 1;
        var zOff:Float = 2;

        var wheelMesh:Cylinder = new Cylinder(16, 16, radius, radius * 0.6, true);

        var node1:Node = new Node("wheel 1 node");
        var wheels1:Geometry = new Geometry("wheel 1", wheelMesh);
        node1.attachChild(wheels1);
        wheels1.rotateAngles(0, FastMath.HALF_PI, 0);
        wheels1.setMaterial(mat);
        vehicle.addWheel(new Vector3f(-xOff, yOff, zOff),
                wheelDirection, wheelAxle, restLength, radius, true, node1);

        var node2:Node = new Node("wheel 2 node");
        var wheels2:Geometry = new Geometry("wheel 2", wheelMesh);
        node2.attachChild(wheels2);
        wheels2.rotateAngles(0, FastMath.HALF_PI, 0);
        wheels2.setMaterial(mat);
        vehicle.addWheel(new Vector3f(xOff, yOff, zOff),
                wheelDirection, wheelAxle, restLength, radius, true, node2);

        var node3:Node = new Node("wheel 3 node");
        var wheels3:Geometry = new Geometry("wheel 3", wheelMesh);
        node3.attachChild(wheels3);
        wheels3.rotateAngles(0, FastMath.HALF_PI, 0);
        wheels3.setMaterial(mat);
        vehicle.addWheel(new Vector3f(-xOff, yOff, -zOff),
                wheelDirection, wheelAxle, restLength, radius, false, node3);

        var node4:Node = new Node("wheel 4 node");
        var wheels4:Geometry = new Geometry("wheel 4", wheelMesh);
        node4.attachChild(wheels4);
        wheels4.rotateAngles(0, FastMath.HALF_PI, 0);
        wheels4.setMaterial(mat);
        vehicle.addWheel(new Vector3f(xOff, yOff, -zOff),
                wheelDirection, wheelAxle, restLength, radius, false, node4);

        vehicleNode.attachChild(node1);
        vehicleNode.attachChild(node2);
        vehicleNode.attachChild(node3);
        vehicleNode.attachChild(node4);
        scene.attachChild(vehicleNode);

        getPhysicsSpace().add(vehicle);
		
		//driver
        var driverNode:Node = new Node("driverNode");
        driverNode.setTranslationXYZ(0,2,0);
        driver = new RigidBodyControl(new BoxCollisionShape(new Vector3f(0.2, .5, 0.2)));
        driverNode.addControl(driver);

        scene.attachChild(driverNode);
        getPhysicsSpace().add(driver);

        //joint
        slider = new SliderJoint(driver, vehicle, new Vector3f(0, -1, 0) , new Vector3f(0, 1, 0), true);
        slider.setUpperLinLimit(.1);
        slider.setLowerLinLimit(-.1);

        getPhysicsSpace().add(slider);

        var pole1Node:Node = new Node("pole1Node");
        var pole2Node:Node = new Node("pole1Node");
        var bridgeNode:Node = new Node("pole1Node");
        pole1Node.setLocalTranslation(new Vector3f(-2,-1,4));
        pole2Node.setLocalTranslation(new Vector3f(2,-1,4));
        bridgeNode.setLocalTranslation(new Vector3f(0,1.4,4));

        var pole1:RigidBodyControl = new RigidBodyControl(new BoxCollisionShape(new Vector3f(0.2,1.25,0.2)),0);
        pole1Node.addControl(pole1);
        var pole2:RigidBodyControl = new RigidBodyControl(new BoxCollisionShape(new Vector3f(0.2,1.25,0.2)),0);
        pole2Node.addControl(pole2);
        bridge = new RigidBodyControl(new BoxCollisionShape(new Vector3f(2.5,0.2,0.2)));
        bridgeNode.addControl(bridge);

        scene.attachChild(pole1Node);
        scene.attachChild(pole2Node);
        scene.attachChild(bridgeNode);
        getPhysicsSpace().add(pole1);
        getPhysicsSpace().add(pole2);
        getPhysicsSpace().add(bridge);

		setupKeys();
		
		
		start();
	}
	
	private function setupKeys():Void
	{
        mInputManager.addTrigger("Lefts", new KeyTrigger(Keyboard.LEFT));
        mInputManager.addTrigger("Rights", new KeyTrigger(Keyboard.RIGHT));
        mInputManager.addTrigger("Ups", new KeyTrigger(Keyboard.UP));
        mInputManager.addTrigger("Downs", new KeyTrigger(Keyboard.DOWN));
        mInputManager.addTrigger("Space", new KeyTrigger(Keyboard.J));
        mInputManager.addTrigger("Reset", new KeyTrigger(Keyboard.R));
		mInputManager.addTrigger("Pause", new KeyTrigger(Keyboard.P));
		mInputManager.addTrigger("DragRotate", new KeyTrigger(Keyboard.M));
        mInputManager.addListener(this, Vector.ofArray(["Lefts", "Rights", "Ups", "Downs", "Space", "Reset", "Pause", "DragRotate"]));
    }
	
	private function getRigidBodyControl(spatial:Spatial):RigidBodyControl
	{
		return cast(spatial.getControl(RigidBodyControl), RigidBodyControl);
	}
	
	private function getPhysicsSpace():PhysicsSpace
	{
        return bulletAppState.getPhysicsSpace();
    }
	
	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
		
		if(!dragToRotate)
			camera.lookAt(vehicle.getPhysicsLocation(), Vector3f.Y_AXIS);
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		if (name == "Pause") 
		{
            if (!value)
			{
				paused = !paused;
                bulletAppState.setEnabled(!paused);
            } 
        }
		else if (name =="Lefts") 
		{
            if (value)
			{
                steeringValue -= 0.05;
            } 
			else 
			{
                //steeringValue = 0;
            }
			steeringValue = FastMath.clamp(steeringValue, -0.5, 0.5);
            vehicle.steer(steeringValue);
        }
		else if (name == "Rights")
		{
            if (value) 
			{
                steeringValue += 0.05;
            }
			else 
			{
                //steeringValue = 0;
            }
			steeringValue = FastMath.clamp(steeringValue, -0.5, 0.5);
            vehicle.steer(steeringValue);
        } 
		else if (name == "Ups")
		{
            if (value)
			{
                accelerationValue = accelerationForce;
            } 
			else
			{
                accelerationValue = 0;
            }
            vehicle.accelerate(accelerationValue);
        }
		else if (name == "Downs")
		{
            if (value) 
			{
                vehicle.brake(brakeForce);
            } 
			else
			{
                vehicle.brake(0);
            }
        }
		else if (name == "Space")
		{
            if (!value)
			{
                vehicle.applyImpulse(jumpForce, Vector3f.ZERO);
            }
        } 
		else if (name == "Reset")
		{
            if (!value) 
			{
                vehicle.setPhysicsLocation(Vector3f.ZERO);
                vehicle.setPhysicsRotation(new Matrix3f());
                vehicle.setLinearVelocity(Vector3f.ZERO);
                vehicle.setAngularVelocity(Vector3f.ZERO);
                vehicle.resetSuspension();
				
				bridge.setPhysicsLocation(new Vector3f(0,1.4,4));
                bridge.setPhysicsRotation(Quaternion.DIRECTION_Z.toMatrix3f());
				bridge.activate();
            } 
        }
		else if (name == "DragRotate")
		{
			if (!value)
			{
				dragToRotate = !dragToRotate;
			}
		}
		
		super.onAction(name, value, tpf);
	}
}