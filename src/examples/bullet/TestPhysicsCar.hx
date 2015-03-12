package examples.bullet;

import flash.ui.Keyboard;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.shapes.BoxCollisionShape;
import org.angle3d.bullet.collision.shapes.CompoundCollisionShape;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.control.VehicleControl;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Cylinder;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Stats;

class TestPhysicsCar extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestPhysicsCar());
	}
	
	private var bulletAppState:BulletAppState;
	private var vehicle:VehicleControl;
	private var accelerationForce:Float = 1000.0;
    private var brakeForce:Float = 100.0;
    private var steeringValue:Float = 0;
    private var accelerationValue:Float = 0;
    private var jumpForce:Vector3f = new Vector3f(0, 3000, 0);
	private var paused:Bool = false;
	
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

		PhysicsTestHelper.createPhysicsTestWorld(scene, bulletAppState.getPhysicsSpace());
		PhysicsTestHelper.createBallShooter(this, scene, bulletAppState.getPhysicsSpace());
		
		var mat:Material = new Material();
		mat.load("assets/material/unshaded.mat");
		mat.setColor("u_MaterialColor", Color.Pink());

        //create a compound shape and attach the BoxCollisionShape for the car body at 0,1,0
        //this shifts the effective center of mass of the BoxCollisionShape to 0,-1,0
        var compoundShape:CompoundCollisionShape = new CompoundCollisionShape();
        var box:BoxCollisionShape = new BoxCollisionShape(new Vector3f(1.2, 0.5, 2.4));
        compoundShape.addChildShape(box, new Vector3f(0, 1, 0));
		

        //create vehicle node
        var vehicleNode:Node = new Node("vehicleNode");
        vehicle = new VehicleControl(compoundShape, 400);
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
		
		//var newNoe:Node = new Node("test node");
        //var newWheel:Geometry = new Geometry("new wheel", wheelMesh);
        //newNoe.attachChild(newWheel);
        //newNoe.setTranslationXYZ(4, -4, 4);
        //newWheel.setMaterial(mat);
        //scene.attachChild(newNoe);
		//newWheel.rotateAngles(0, FastMath.HALF_PI(), 0);

        var node1:Node = new Node("wheel 1 node");
        var wheels1:Geometry = new Geometry("wheel 1", wheelMesh);
        node1.attachChild(wheels1);
        wheels1.rotateAngles(0, FastMath.HALF_PI(), 0);
        wheels1.setMaterial(mat);
        vehicle.addWheel(new Vector3f(-xOff, yOff, zOff),
                wheelDirection, wheelAxle, restLength, radius, true, node1);

        var node2:Node = new Node("wheel 2 node");
        var wheels2:Geometry = new Geometry("wheel 2", wheelMesh);
        node2.attachChild(wheels2);
        wheels2.rotateAngles(0, FastMath.HALF_PI(), 0);
        wheels2.setMaterial(mat);
        vehicle.addWheel(new Vector3f(xOff, yOff, zOff),
                wheelDirection, wheelAxle, restLength, radius, true, node2);

        var node3:Node = new Node("wheel 3 node");
        var wheels3:Geometry = new Geometry("wheel 3", wheelMesh);
        node3.attachChild(wheels3);
        wheels3.rotateAngles(0, FastMath.HALF_PI(), 0);
        wheels3.setMaterial(mat);
        vehicle.addWheel(new Vector3f(-xOff, yOff, -zOff),
                wheelDirection, wheelAxle, restLength, radius, false, node3);

        var node4:Node = new Node("wheel 4 node");
        var wheels4:Geometry = new Geometry("wheel 4", wheelMesh);
        node4.attachChild(wheels4);
        wheels4.rotateAngles(0, FastMath.HALF_PI(), 0);
        wheels4.setMaterial(mat);
        vehicle.addWheel(new Vector3f(xOff, yOff, -zOff),
                wheelDirection, wheelAxle, restLength, radius, false, node4);

        vehicleNode.attachChild(node1);
        vehicleNode.attachChild(node2);
        vehicleNode.attachChild(node3);
        vehicleNode.attachChild(node4);
        scene.attachChild(vehicleNode);

        getPhysicsSpace().add(vehicle);

		setupKeys();
		
		Stats.show(stage);
		start();
	}
	
	private function setupKeys():Void
	{
        mInputManager.addSingleMapping("Lefts", new KeyTrigger(Keyboard.LEFT));
        mInputManager.addSingleMapping("Rights", new KeyTrigger(Keyboard.RIGHT));
        mInputManager.addSingleMapping("Ups", new KeyTrigger(Keyboard.UP));
        mInputManager.addSingleMapping("Downs", new KeyTrigger(Keyboard.DOWN));
        mInputManager.addSingleMapping("Space", new KeyTrigger(Keyboard.J));
        mInputManager.addSingleMapping("Reset", new KeyTrigger(Keyboard.R));
		mInputManager.addSingleMapping("Pause", new KeyTrigger(Keyboard.P));
        mInputManager.addListener(this, ["Lefts", "Rights", "Ups", "Downs", "Space", "Reset", "Pause"]);
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
                steeringValue = -0.5;
            } 
			else 
			{
                //steeringValue = 0;
            }
            vehicle.steer(steeringValue);
        }
		else if (name == "Rights")
		{
            if (value) 
			{
                steeringValue = 0.5;
            }
			else 
			{
                //steeringValue = 0;
            }
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
            } 
        }
		
		super.onAction(name, value, tpf);
	}
}