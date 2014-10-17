package examples.bullet;

import flash.events.Event;
import flash.events.MouseEvent;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.PhysicsCollisionObject;
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
class TestCollisionGroups extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestCollisionGroups());
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
        getRigidBodyControl(physicsSphere).setPhysicsLocation(new Vector3f(3, 6, 0));
        scene.attachChild(physicsSphere);
        getPhysicsSpace().add(physicsSphere);
		
		// Add a physics sphere to the world
        var physicsSphere2:Node = PhysicsTestHelper.createPhysicsTestNode(new SphereCollisionShape(1), 1);
        getRigidBodyControl(physicsSphere2).setPhysicsLocation(new Vector3f(4, 8, 0));
        getRigidBodyControl(physicsSphere2).addCollideWithGroup(PhysicsCollisionObject.COLLISION_GROUP_02);
        scene.attachChild(physicsSphere2);
        getPhysicsSpace().add(physicsSphere2);

        // an obstacle mesh, does not move (mass=0)
        var node2:Node = PhysicsTestHelper.createPhysicsTestNode(new SphereCollisionShape(1), 1);
        getRigidBodyControl(node2).setPhysicsLocation(new Vector3f(2.5, -4, 0));
        getRigidBodyControl(node2).setCollisionGroup(PhysicsCollisionObject.COLLISION_GROUP_02);
        getRigidBodyControl(node2).setCollideWithGroups(PhysicsCollisionObject.COLLISION_GROUP_02);
        scene.attachChild(node2);
        getPhysicsSpace().add(node2);


        // the floor mesh, does not move (mass=0)
        var node3:Node = PhysicsTestHelper.createPhysicsTestNode(new PlaneCollisionShape(new Plane(new Vector3f(0, 1, 0), 0)), 0);
        getRigidBodyControl(node3).setPhysicsLocation(new Vector3f(0, -6, 0));
        scene.attachChild(node3);
        getPhysicsSpace().add(node3);

		Stats.show(stage);
		start();
	}
	
	private function getRigidBodyControl(spatial:Spatial):RigidBodyControl
	{
		return cast(spatial.getControlByClass(RigidBodyControl), RigidBodyControl);
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