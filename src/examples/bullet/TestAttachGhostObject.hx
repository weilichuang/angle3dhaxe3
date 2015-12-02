package examples.bullet;

import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.PhysicsCollisionObject;
import org.angle3d.bullet.collision.shapes.BoxCollisionShape;
import org.angle3d.bullet.collision.shapes.SphereCollisionShape;
import org.angle3d.bullet.control.GhostControl;
import org.angle3d.bullet.control.PhysicsControl;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.joints.HingeJoint;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Logger;
import org.angle3d.utils.Stats;

/**
 * ...
 * @author weilichuang
 */
class TestAttachGhostObject extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestAttachGhostObject());
	}
	
	private var bulletAppState:BulletAppState;
	private var joint:HingeJoint;
	private var ghostControl:GhostControl;
	private var collisionNode:Node;
	
	public function new() 
	{
		super();
		
	}
	
	private function setupKeys():Void
	{
        mInputManager.addTrigger("Left", new KeyTrigger(Keyboard.LEFT));
        mInputManager.addTrigger("Right", new KeyTrigger(Keyboard.RIGHT));
        mInputManager.addTrigger("Swing", new KeyTrigger(Keyboard.DOWN));
        mInputManager.addListener(this, Vector.ofArray(["Left", "Right", "Swing"]));
		mInputEnabled = true;
    }
	
	override public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, isPressed, tpf);
		
		if (isPressed)
			return;
			
        if (name == "Left")
		{
            joint.enableMotor(true, 1, .1);
        }
        else if (name == "Right")
		{
            joint.enableMotor(true, -1, .1);
        }
        else if (name == "Swing")
		{
            joint.enableMotor(false, 0, 0);
        }
    }
	
	private function setupJoint():Void
	{
		var holderNode:Node = PhysicsTestHelper.createPhysicsTestNode(new BoxCollisionShape(new Vector3f( .1, .1, .1)), 0);
        getRigidBodyControl(holderNode).setPhysicsLocation(new Vector3f(0, 0, 0));
        scene.attachChild(holderNode);
        getPhysicsSpace().add(holderNode);

        var hammerNode:Node = PhysicsTestHelper.createPhysicsTestNode(new BoxCollisionShape(new Vector3f( .3, .3, .3)), 1);
        getRigidBodyControl(hammerNode).setPhysicsLocation(new Vector3f(0, -1, 0));
        scene.attachChild(hammerNode);
        getPhysicsSpace().add(hammerNode);
		
		//immovable
        collisionNode = PhysicsTestHelper.createPhysicsTestNode(new BoxCollisionShape(new Vector3f(.3, .3, .3)), 0);
        getRigidBodyControl(collisionNode).setPhysicsLocation(new Vector3f(1.8, 0, 0));
        scene.attachChild(collisionNode);
        getPhysicsSpace().add(collisionNode);
		
		//ghost node
        ghostControl = new GhostControl(new SphereCollisionShape(0.7));

        hammerNode.addControl(ghostControl);
        getPhysicsSpace().add(ghostControl);

        joint=new HingeJoint(cast holderNode.getControl(RigidBodyControl), cast hammerNode.getControl(RigidBodyControl), Vector3f.ZERO, new Vector3f(0,-1,0), Vector3f.Z_AXIS, Vector3f.Z_AXIS);
        getPhysicsSpace().add(joint);
	}
	
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		bulletAppState = new BulletAppState(true);
        mStateManager.attach(bulletAppState);

		setupJoint();
        setupKeys();
		
		Stats.show(stage);
		start();
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
		
		var objects:Array<PhysicsCollisionObject> = ghostControl.getOverlappingObjects();
		if (objects.indexOf(cast collisionNode.getControl(PhysicsControl)) != -1)
		{
            Logger.log("collide");
        }
	}
}