package examples.bullet;


import angle3d.app.SimpleApplication;
import angle3d.bullet.BulletAppState;
import angle3d.bullet.collision.PhysicsCollisionObject;
import angle3d.bullet.collision.PhysicsSweepTestResult;
import angle3d.bullet.collision.shapes.CapsuleCollisionShape;
import angle3d.bullet.control.RigidBodyControl;
import angle3d.bullet.PhysicsSpace;
import angle3d.math.Transform;
import angle3d.math.Vector3f;
import angle3d.scene.Node;
import angle3d.scene.Spatial;
import angle3d.utils.Stats;

/**
 * ...
 
 */
class TestSweepTest extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestSweepTest());
	}
	
	private var bulletAppState:BulletAppState;
	private var obstacleCollisionShape:CapsuleCollisionShape = new CapsuleCollisionShape(0.3, 0.5);
    private var capsuleCollisionShape:CapsuleCollisionShape = new CapsuleCollisionShape(1, 1);
    private var capsule:Node;
    private var obstacle:Node;
    private var dist:Float = .5;

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

        capsule = new Node("capsule");
        capsule.move(-2, 0, 0);
        capsule.addControl(new RigidBodyControl(capsuleCollisionShape, 1));
        getRigidBodyControl(capsule).setKinematic(true);
        bulletAppState.getPhysicsSpace().add(capsule);
        scene.attachChild(capsule);

        obstacle = new Node("obstacle");
        obstacle.move(2, 0, 0);
        var bodyControl:RigidBodyControl = new RigidBodyControl(obstacleCollisionShape, 0);
        obstacle.addControl(bodyControl);
        bulletAppState.getPhysicsSpace().add(obstacle);
        scene.attachChild(obstacle);

        bulletAppState.setDebugEnabled(true);

		
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
		
		var move:Float = tpf * 1;
		
		var ta:Transform = new Transform();
		ta.translation.copyFrom(capsule.getWorldTranslation());
		var tb:Transform = new Transform();
		tb.translation.copyFrom(capsule.getWorldTranslation().add(new Vector3f(dist, 0, 0)));

        var sweepTest:Array<PhysicsSweepTestResult> = bulletAppState.getPhysicsSpace().sweepTest(capsuleCollisionShape, ta, tb );

        if (sweepTest.length > 0)
		{
            var result:PhysicsSweepTestResult = sweepTest[0];
            var collisionObject:PhysicsCollisionObject = result.getCollisionObject();
            Lib.trace("Almost colliding with " + Std.string(collisionObject.getUserObject()));
        } 
		else 
		{
            // if the sweep is clear then move the spatial
            capsule.move(move, 0, 0);
        }
	}
}