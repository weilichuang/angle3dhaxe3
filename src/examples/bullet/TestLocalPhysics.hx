package examples.bullet;

import flash.events.Event;
import flash.events.MouseEvent;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.shapes.BoxCollisionShape;
import org.angle3d.bullet.collision.shapes.CylinderCollisionShape;
import org.angle3d.bullet.collision.shapes.MeshCollisionShape;
import org.angle3d.bullet.collision.shapes.PlaneCollisionShape;
import org.angle3d.bullet.collision.shapes.SphereCollisionShape;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.math.Plane;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Stats;

/**
 * ...
 * @author weilichuang
 */
class TestLocalPhysics extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestLocalPhysics());
	}
	
	private var bulletAppState:BulletAppState;

	public function new() 
	{
		super();
		
	}
	
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		bulletAppState = new BulletAppState();
        mStateManager.attach(bulletAppState);

        // Add a physics sphere to the world
        var physicsSphere:Node = PhysicsTestHelper.createPhysicsTestNode(new SphereCollisionShape(1), 1);
		getRigidBodyControl(physicsSphere).setFriction(0.2);
        getRigidBodyControl(physicsSphere).setPhysicsLocation(new Vector3f(3, 6, 0));
		getRigidBodyControl(physicsSphere).setApplyPhysicsLocal(true);
        scene.attachChild(physicsSphere);
        getPhysicsSpace().add(physicsSphere);

        // Add a physics sphere to the world using the collision shape from sphere one
        var physicsSphere2:Node = PhysicsTestHelper.createPhysicsTestNode(getRigidBodyControl(physicsSphere).getCollisionShape(), 1);
		getRigidBodyControl(physicsSphere2).setFriction(0.05);
        getRigidBodyControl(physicsSphere2).setPhysicsLocation(new Vector3f(4, 8, 0));
		getRigidBodyControl(physicsSphere2).setApplyPhysicsLocal(true);
        scene.attachChild(physicsSphere2);
        getPhysicsSpace().add(physicsSphere2);

        // Add a physics box to the world
        var physicsBox:Node = PhysicsTestHelper.createPhysicsTestNode(new BoxCollisionShape(new Vector3f(1, 1, 1)), 1);
        getRigidBodyControl(physicsBox).setFriction(0.1);
        getRigidBodyControl(physicsBox).setPhysicsLocation(new Vector3f(.6, 4, .5));
		getRigidBodyControl(physicsBox).setApplyPhysicsLocal(true);
        scene.attachChild(physicsBox);
        getPhysicsSpace().add(physicsBox);
		
		var physicsBox2:Node = PhysicsTestHelper.createPhysicsTestNode(new BoxCollisionShape(new Vector3f(1, 1, 1)), 1);
        getRigidBodyControl(physicsBox2).setFriction(0.1);
        getRigidBodyControl(physicsBox2).setPhysicsLocation(new Vector3f(.6, 10, .5));
		getRigidBodyControl(physicsBox2).setApplyPhysicsLocal(true);
        scene.attachChild(physicsBox2);
        getPhysicsSpace().add(physicsBox2);

        // Add a physics cylinder to the world
        var physicsCylinder:Node = PhysicsTestHelper.createPhysicsTestNode(new CylinderCollisionShape(new Vector3f(1, 1, 1.5)), 1);
        getRigidBodyControl(physicsCylinder).setPhysicsLocation(new Vector3f(2, 2, 0));
		getRigidBodyControl(physicsCylinder).setApplyPhysicsLocal(true);
        scene.attachChild(physicsCylinder);
        getPhysicsSpace().add(physicsCylinder);

        // an obstacle mesh, does not move (mass=0)
        //var node2:Node = PhysicsTestHelper.createPhysicsTestNode(new MeshCollisionShape(new Sphere(1.2, 16, 16)), 0);
        //getRigidBodyControl(node2).setPhysicsLocation(new Vector3f(2.5, -4, 0));
        //scene.attachChild(node2);
        //getPhysicsSpace().add(node2);

        // the floor mesh, does not move (mass=0)
        var node3:Node = PhysicsTestHelper.createPhysicsTestNode(new PlaneCollisionShape(new Plane(new Vector3f(0, 1, 0), 0)), 0);
        getRigidBodyControl(node3).setPhysicsLocation(new Vector3f(0, -6, 0));
		getRigidBodyControl(node3).setApplyPhysicsLocal(true);
        scene.attachChild(node3);
        getPhysicsSpace().add(node3);
		
		PhysicsTestHelper.createBallShooter(this, scene, bulletAppState.getPhysicsSpace());

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
	}
}