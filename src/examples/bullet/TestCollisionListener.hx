package examples.bullet;

import flash.events.Event;
import flash.events.MouseEvent;
import flash.ui.Keyboard;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.PhysicsCollisionEvent;
import org.angle3d.bullet.collision.PhysicsCollisionListener;
import org.angle3d.bullet.collision.shapes.BoxCollisionShape;
import org.angle3d.bullet.collision.shapes.CylinderCollisionShape;
import org.angle3d.bullet.collision.shapes.MeshCollisionShape;
import org.angle3d.bullet.collision.shapes.PlaneCollisionShape;
import org.angle3d.bullet.collision.shapes.SphereCollisionShape;
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
import org.angle3d.utils.Stats;

/**
 * ...
 * @author weilichuang
 */
class TestCollisionListener extends SimpleApplication implements PhysicsCollisionListener
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestCollisionListener());
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
		
		bulletAppState = new BulletAppState(true);
        mStateManager.attach(bulletAppState);

		PhysicsTestHelper.createPhysicsTestWorld(scene, getPhysicsSpace());
		PhysicsTestHelper.createBallShooter(this, scene, getPhysicsSpace(), false);
		
		// add ourselves as collision listener
        getPhysicsSpace().addCollisionListener(this);
		
		Stats.show(stage);
		start();
	}
	
	public function collision(event:PhysicsCollisionEvent):Void
	{
		if (event.getNodeA().name == "Box" || event.getNodeB().name == "Box")
		{
			if (event.getNodeA().name == "bullet" || event.getNodeB().name == "bullet")
			{
				trace("You hit the box!");
			}
		}
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