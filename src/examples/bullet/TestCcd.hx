package examples.bullet;

import flash.ui.Keyboard;

import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.shapes.BoxCollisionShape;
import org.angle3d.bullet.collision.shapes.MeshCollisionShape;
import org.angle3d.bullet.collision.shapes.SphereCollisionShape;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.bullet.PhysicsSpace;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.Spatial;
import org.angle3d.utils.Stats;

/**
 * ...
 
 */
class TestCcd extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestCcd());
	}
	
	private var bulletAppState:BulletAppState;
	private var mat:Material;
	private var bullet:Sphere;
    private var bulletCollisionShape:SphereCollisionShape;

	public function new() 
	{
		super();
		
	}
	
	private function setupKeys():Void
	{
        mInputManager.addTrigger("Left", new KeyTrigger(Keyboard.LEFT));
        mInputManager.addTrigger("Right", new KeyTrigger(Keyboard.RIGHT));
        mInputManager.addListener(this, Vector.ofArray(["Left", "Right"]));
		mInputEnabled = true;
    }
	
	override public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, isPressed, tpf);
		
		if (isPressed)
			return;
			
        if (name == "Left")
		{
            var bulletg:Geometry = new Geometry("bullet", bullet);
            bulletg.setMaterial(mat);
            bulletg.setLocalTranslation(camera.location);
            bulletg.addControl(new RigidBodyControl(bulletCollisionShape, 1));
            getRigidBodyControl(bulletg).setCcdMotionThreshold(0.1);
			getRigidBodyControl(bulletg).setCcdSweptSphereRadius(0.2);
            getRigidBodyControl(bulletg).setLinearVelocity(camera.getDirection().scaleLocal(40));
			getRigidBodyControl(bulletg).showDebug = false;
            scene.attachChild(bulletg);
            getPhysicsSpace().add(bulletg);
        }
        else if (name == "Right")
		{
            var bulletg:Geometry = new Geometry("bullet", bullet);
            bulletg.setMaterial(mat);
            bulletg.setLocalTranslation(camera.location);
            bulletg.addControl(new RigidBodyControl(bulletCollisionShape, 1));
			getRigidBodyControl(bulletg).showDebug = false;
            getRigidBodyControl(bulletg).setLinearVelocity(camera.getDirection().scaleLocal(40));
            scene.attachChild(bulletg);
            getPhysicsSpace().add(bulletg);
        }
    }
	
	private function setupNode():Void
	{
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setColor("u_MaterialColor", Color.Pink());
		
		bullet = new Sphere(0.4, 16, 16, true);
        bulletCollisionShape = new SphereCollisionShape(0.1);
		
		
		// An obstacle mesh, does not move (mass=0)
        var node2:Node = new Node("mesh");
        node2.setLocalTranslation(new Vector3f(2.5, 0, 0));
        node2.addControl(new RigidBodyControl(new MeshCollisionShape(new Box(4, 4, 0.1)), 0));
        scene.attachChild(node2);
        getPhysicsSpace().add(node2);

        // The floor, does not move (mass=0)
        var node3:Node = new Node("floor");
        node3.setLocalTranslation(new Vector3f(0, -6, 0));
        node3.addControl(new RigidBodyControl(new BoxCollisionShape(new Vector3f(100, 1, 100)), 0));
        scene.attachChild(node3);
        getPhysicsSpace().add(node3);
	}
	
	override private function initialize(width : Int, height : Int) : Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		bulletAppState = new BulletAppState(true);
        mStateManager.attach(bulletAppState);

		setupNode();
        setupKeys();

		
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