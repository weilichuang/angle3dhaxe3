package examples.bullet;

import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DTextureFilter;
import flash.display3D.Context3DWrapMode;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.shapes.SphereCollisionShape;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.input.controls.ActionListener;
import org.angle3d.input.controls.MouseButtonTrigger;
import org.angle3d.light.DirectionalLight;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/BrickWall.jpg") class ROCK_ASSET extends flash.display.BitmapData { }
@:bitmap("../assets/embed/Pond.jpg") class FLOOR_ASSET extends flash.display.BitmapData { }

class TestBrickWall extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestBrickWall());
	}

	private var mat:Material;
	private var brick:Box;

	private var nbBrick:Int = 0;
	private var radius:Float = 3;
	
	private var bLength:Float = 0.48;
	private var bWidth:Float = 0.24;
	private var bHeight:Float = 0.12;
	
	private var bullet:Sphere;
	private var bulletCollisionShape:SphereCollisionShape;
	private var sphere:Sphere;
	
	private var bulletAppState:BulletAppState;
	
	private var actionListener:ActionListener;
	
	public function new() 
	{
		super();
		
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		bulletAppState = new BulletAppState();
		bulletAppState.setDebugEnabled(false);
		mStateManager.attach(bulletAppState);
		
		bullet = new Sphere(0.4, 16, 16, true);
        bulletCollisionShape = new SphereCollisionShape(0.4);
		
		brick = new Box(bLength, bHeight, bWidth);
		brick.scaleTextureCoordinates(new Vector2f(1, 0.5));
		
		var bitmapTexture:BitmapTexture = new BitmapTexture(new ROCK_ASSET(0, 0),true);
		bitmapTexture.mipFilter = Context3DMipFilter.MIPLINEAR;
		bitmapTexture.textureFilter = Context3DTextureFilter.LINEAR;
		bitmapTexture.wrapMode = Context3DWrapMode.REPEAT;
		
		mat = new Material();
		mat.load("assets/material/unshaded.mat");
		mat.setTexture("u_DiffuseMap", bitmapTexture);
		
		initTower();
		initFloor();
		
		camera.location = (new Vector3f(0, 6, 6));
        camera.lookAt(new Vector3f(), new Vector3f(0, 1, 0));
        camera.frustumFar = 15;
		
		this.actionListener = new ShootActionListener(this.addBullet);
		
		mInputManager.addSingleMapping("shoot", new MouseButtonTrigger(0));
		mInputManager.addListener(actionListener, ["shoot"]);
		
		var pl = new DirectionalLight();
		//pl.position = new Vector3f(0, 25, 8);
		pl.color = new Color(0.8, 0.8, 0.8, 1);
		pl.direction = new Vector3f(0, 1, 0);
		//pl.radius = 1106;
		//scene.addLight(pl);
		
		//flyCam.setMoveSpeed(10);
		//flyCam.setEnabled(false);
		flyCam.setDragToRotate(true);
		
		Stats.show(stage);
		start();
	}
	
	private var bricksPerLayer:Int = 8;
	private var brickLayers:Int = 20;
	private var angle:Float = 0;
	private function initTower():Void
	{
		var startpt:Float = bLength / 4;
        var height:Float = 0;
        for (j in 0...15) 
		{
            for (i in 0...4)
			{
                var vt:Vector3f = new Vector3f(i * bLength * 2 + startpt, bHeight + height, 0);
                addBrick(vt);
            }
            startpt = -startpt;
            height += 2 * bHeight;
        }
	}
	
	public function initFloor():Void
	{
        var floorBox:Box = new Box(10, 0.1, 5);
        floorBox.scaleTextureCoordinates(new Vector2f(3, 6));
		
		var bitmapTexture:BitmapTexture = new BitmapTexture(new FLOOR_ASSET(0, 0));
		bitmapTexture.wrapMode = Context3DWrapMode.REPEAT;
		var mat3:Material = new Material();
		mat3.load("assets/material/unshaded.mat");
		mat3.setTexture("u_DiffuseMap", bitmapTexture);

        var floor:Geometry = new Geometry("floor", floorBox);
        floor.setMaterial(mat3);
        floor.setTranslationXYZ(0, 0, 0);
        scene.attachChild(floor);
		
		floor.addControl(new RigidBodyControl(null,0));
        this.bulletAppState.getPhysicsSpace().add(floor);
    }
	
	public function addBrick(ori:Vector3f):Void
	{
        var reBoxg:Geometry = new Geometry("brick", brick);
        reBoxg.setMaterial(mat);
        reBoxg.setLocalTranslation(ori);
        reBoxg.rotateAngles(0, FastMath.toRadians(angle) , 0);
		
		reBoxg.addControl(new RigidBodyControl(null, 1.5));
		cast(reBoxg.getControl(RigidBodyControl), RigidBodyControl).setFriction(1.6);
		
        this.scene.attachChild(reBoxg);
        nbBrick++;
		
		this.bulletAppState.getPhysicsSpace().add(reBoxg);
    }
	
	private function addBullet():Void
	{
		var bulletg:Geometry = new Geometry("bullet", bullet);
		bulletg.setMaterial(mat);
		bulletg.setLocalTranslation(camera.location);
		var bulletNode:RigidBodyControl = new BombControl(bulletCollisionShape, 1);
//                RigidBodyControl bulletNode = new RigidBodyControl(bulletCollisionShape, 1);
		bulletNode.setLinearVelocity(camera.getDirection().scale(25));
		bulletg.addControl(bulletNode);
		scene.attachChild(bulletg);
		bulletAppState.getPhysicsSpace().add(bulletNode);
	}
	
}

class ShootActionListener implements ActionListener
{
	private var onAcitonHandle:Void->Void;
	public function new(onActionHandle:Void->Void)
	{
		this.onAcitonHandle = onActionHandle;
	}
	
	public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		if (name == "shoot" && !isPressed)
		{
			this.onAcitonHandle();
		}
	}
}