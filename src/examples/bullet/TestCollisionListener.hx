package examples.bullet;

import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.PhysicsCollisionEvent;
import org.angle3d.bullet.collision.PhysicsCollisionListener;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Stats;

/**
 * ...
 * @author weilichuang
 */
class TestCollisionListener extends BasicExample implements PhysicsCollisionListener
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