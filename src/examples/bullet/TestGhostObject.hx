package examples.bullet;

import flash.events.Event;
import flash.events.MouseEvent;
import flash.ui.Keyboard;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.PhysicsCollisionEvent;
import org.angle3d.bullet.collision.PhysicsCollisionListener;
import org.angle3d.bullet.collision.shapes.BoxCollisionShape;
import org.angle3d.bullet.collision.shapes.CollisionShape;
import org.angle3d.bullet.collision.shapes.CylinderCollisionShape;
import org.angle3d.bullet.collision.shapes.MeshCollisionShape;
import org.angle3d.bullet.collision.shapes.PlaneCollisionShape;
import org.angle3d.bullet.collision.shapes.SphereCollisionShape;
import org.angle3d.bullet.control.GhostControl;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.joints.HingeJoint;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.input.controls.ActionListener;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.input.KeyInput;
import org.angle3d.material.Material;
import org.angle3d.material.MaterialNormalColor;
import org.angle3d.math.Plane;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Logger;
import org.angle3d.utils.Stats;

/**
 * ...
 * @author weilichuang
 */
class TestGhostObject extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestGhostObject());
	}
	
	private var bulletAppState:BulletAppState;
	private var ghostControl:GhostControl;

	public function new() 
	{
		super();
	}

	
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		bulletAppState = new BulletAppState(true);
        mStateManager.attach(bulletAppState);
		
		// Mesh to be shared across several boxes.
        var boxGeom:Box = new Box(1, 1, 1);
        // CollisionShape to be shared across several boxes.
        var shape:CollisionShape = new BoxCollisionShape(new Vector3f(1, 1, 1));

        var physicsBox:Node = PhysicsTestHelper.createPhysicsTestNode(shape, 1);
        physicsBox.name = ("box0");
        getRigidBodyControl(physicsBox).setPhysicsLocation(new Vector3f(.6, 4, .5));
        scene.attachChild(physicsBox);
        getPhysicsSpace().add(physicsBox);

        var physicsBox1:Node = PhysicsTestHelper.createPhysicsTestNode(shape, 1);
        physicsBox1.name = ("box1");
        getRigidBodyControl(physicsBox1).setPhysicsLocation(new Vector3f(0, 40, 0));
        scene.attachChild(physicsBox1);
        getPhysicsSpace().add(physicsBox1);

        var physicsBox2:Node = PhysicsTestHelper.createPhysicsTestNode(new BoxCollisionShape(new Vector3f(1, 1, 1)), 1);
        physicsBox2.name = ("box2");
        getRigidBodyControl(physicsBox2).setPhysicsLocation(new Vector3f(.5, 80, -.8));
        scene.attachChild(physicsBox2);
        getPhysicsSpace().add(physicsBox2);

        // the floor, does not move (mass=0)
        var node:Node = PhysicsTestHelper.createPhysicsTestNode(new BoxCollisionShape(new Vector3f(100, 1, 100)), 0);
        node.name = ("floor");
        getRigidBodyControl(node).setPhysicsLocation(new Vector3f(0, -6, 0));
        scene.attachChild(node);
        getPhysicsSpace().add(node);

        initGhostObject();
		
		Stats.show(stage);
		start();
	}
	
	private function initGhostObject():Void
	{
        var halfExtents:Vector3f = new Vector3f(3, 4.2, 1);
        ghostControl = new GhostControl(new BoxCollisionShape(halfExtents));
        var node:Node = new Node("Ghost Object");
        node.addControl(ghostControl);
        scene.attachChild(node);
        getPhysicsSpace().add(ghostControl);
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
		
		Logger.log("Overlapping objects: " + ghostControl.getOverlappingObjects());
	}
}