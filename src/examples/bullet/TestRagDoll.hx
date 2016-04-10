package examples.bullet;

import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.shapes.CapsuleCollisionShape;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.joints.ConeJoint;
import org.angle3d.bullet.joints.PhysicsJoint;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Stats;

/**
 * ...
 
 */
class TestRagDoll extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestRagDoll());
	}
	
	private var bulletAppState:BulletAppState;
	private var ragDoll:Node;
    private var shoulders:Node;
    private var upforce:Vector3f = new Vector3f(0, 200, 0);
    private var applyForce:Bool = false;
	
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
		bulletAppState.setEnabled(true);

		PhysicsTestHelper.createPhysicsTestWorld(scene, bulletAppState.getPhysicsSpace());
		PhysicsTestHelper.createBallShooter(this, scene, bulletAppState.getPhysicsSpace());

		createRagDoll();

		setupKeys();
		
		
		start();
	}
	
	private function createRagDoll():Void
	{
		ragDoll = new Node("ragDoll");
		
		shoulders = createLimb(0.2, 1.0, new Vector3f(0.00, 1.5, 0), true);
        var uArmL:Node = createLimb(0.2, 0.5, new Vector3f(-0.75, 0.8, 0), false);
        var uArmR:Node = createLimb(0.2, 0.5, new Vector3f(0.75, 0.8, 0), false);
        var lArmL:Node = createLimb(0.2, 0.5, new Vector3f(-0.75, -0.2, 0), false);
        var lArmR:Node = createLimb(0.2, 0.5, new Vector3f(0.75, -0.2, 0), false);
        var body:Node = createLimb(0.2, 1.0, new Vector3f(0.00, 0.5, 0), false);
        var hips:Node = createLimb(0.2, 0.5, new Vector3f(0.00, -0.5, 0), true);
        var uLegL:Node = createLimb(0.2, 0.5, new Vector3f(-0.25, -1.2, 0), false);
        var uLegR:Node = createLimb(0.2, 0.5, new Vector3f(0.25, -1.2, 0), false);
        var lLegL:Node = createLimb(0.2, 0.5, new Vector3f(-0.25, -2.2, 0), false);
        var lLegR:Node = createLimb(0.2, 0.5, new Vector3f(0.25, -2.2, 0), false);

        join(body, shoulders, new Vector3f(0, 1.4, 0));
        join(body, hips, new Vector3f(0, -0.5, 0));

        join(uArmL, shoulders, new Vector3f(-0.75, 1.4, 0));
        join(uArmR, shoulders, new Vector3f(0.75, 1.4, 0));
        join(uArmL, lArmL, new Vector3f(-0.75, .4, 0));
        join(uArmR, lArmR, new Vector3f(0.75, .4, 0));

        join(uLegL, hips, new Vector3f(-.25, -0.5, 0));
        join(uLegR, hips, new Vector3f(.25, -0.5, 0));
        join(uLegL, lLegL, new Vector3f(-.25, -1.7, 0));
        join(uLegR, lLegR, new Vector3f(.25, -1.7, 0));

        ragDoll.attachChild(shoulders);
        ragDoll.attachChild(body);
        ragDoll.attachChild(hips);
        ragDoll.attachChild(uArmL);
        ragDoll.attachChild(uArmR);
        ragDoll.attachChild(lArmL);
        ragDoll.attachChild(lArmR);
        ragDoll.attachChild(uLegL);
        ragDoll.attachChild(uLegR);
        ragDoll.attachChild(lLegL);
        ragDoll.attachChild(lLegR);

        scene.attachChild(ragDoll);
        getPhysicsSpace().addAll(ragDoll);
	}
	
	private function createLimb(width:Float, height:Float, location:Vector3f, rotate:Bool):Node
	{
        var axis:Int = rotate ? PhysicsSpace.AXIS_X : PhysicsSpace.AXIS_Y;
        var shape:CapsuleCollisionShape = new CapsuleCollisionShape(width, height, axis);
        var node:Node = new Node("Limb");
        var rigidBodyControl:RigidBodyControl = new RigidBodyControl(shape, 1);
        node.setLocalTranslation(location);
        node.addControl(rigidBodyControl);
        return node;
    }

    private function join(A:Node, B:Node, connectionPoint:Vector3f):PhysicsJoint
	{
        var pivotA:Vector3f = A.worldToLocal(connectionPoint, new Vector3f());
        var pivotB:Vector3f = B.worldToLocal(connectionPoint, new Vector3f());
        var joint:ConeJoint = new ConeJoint(getRigidBodyControl(A), getRigidBodyControl(B), pivotA, pivotB);
        joint.setLimit(1, 1, 0);
        return joint;
    }
	
	private function setupKeys():Void
	{
        mInputManager.addTrigger("Ups", new KeyTrigger(Keyboard.UP));
        mInputManager.addListener(this, Vector.ofArray(["Ups"]));
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
		
		if (applyForce) 
		{
            getRigidBodyControl(shoulders).applyForce(upforce, Vector3f.ZERO);
        }
	}
	
	
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		if (name == "Ups")
		{
			if (value)
			{
				getRigidBodyControl(shoulders).activate();
                applyForce = true;
			}
			else
			{
				applyForce = false;
			}
        }
		
		super.onAction(name, value, tpf);
	}
}