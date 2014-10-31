package examples.bullet;

import flash.display3D.Context3DMipFilter;
import flash.display3D.Context3DTextureFilter;
import flash.display3D.Context3DWrapMode;
import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.app.SimpleApplication;
import org.angle3d.bullet.BulletAppState;
import org.angle3d.bullet.collision.shapes.SphereCollisionShape;
import org.angle3d.bullet.control.RigidBodyControl;
import org.angle3d.input.controls.ActionListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.input.controls.MouseButtonTrigger;
import org.angle3d.light.DirectionalLight;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.MaterialLight;
import org.angle3d.material.MaterialNormalColor;
import org.angle3d.material.MaterialTexture;
import org.angle3d.material.MaterialWireframe;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.BatchNode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.shape.WireframeShape;
import org.angle3d.scene.shape.WireframeUtil;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Logger;
import org.angle3d.utils.Stats;

//@:bitmap("embed/BrickWall.jpg") class ROCK_ASSET extends flash.display.BitmapData { }
@:bitmap("embed/Pond.jpg") class FLOOR_ASSET extends flash.display.BitmapData { }

//TODO 目前帧率太低，每帧耗时350ms左右，需要大优化
class TestBrickTower extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestBrickTower());
	}

	private var mat:Material;
	private var brick:Box;
	private var wireframeBrick:WireframeShape;
	private var wireframeMat:MaterialWireframe;

	private var nbBrick:Int = 0;
	private var radius:Float = 3;
	
	private var brickWidth:Float = 0.75;
	private var brickHeight:Float = 0.25;
	private var brickDepth:Float = 0.25;
	
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
		
		brick = new Box(brickWidth, brickHeight, brickDepth);
		//brick.scaleTextureCoordinates(new Vector2f(1, 0.5));
		
		wireframeMat = new MaterialWireframe(0x008822);
		
		wireframeBrick = WireframeUtil.generateWireframe(brick);
	
		//var bitmapTexture:Texture2D = new Texture2D(new ROCK_ASSET(0, 0),true);
		//bitmapTexture.mipFilter = Context3DMipFilter.MIPLINEAR;
		//bitmapTexture.textureFilter = Context3DTextureFilter.LINEAR;
		//bitmapTexture.wrapMode = Context3DWrapMode.CLAMP;
		
		//mat = new MaterialTexture(bitmapTexture);
		
		//mat = new MaterialLight();
		//cast(mat,MaterialLight).diffuseColor = Vector.ofArray([1.0, 1.0, 1.0, 1.0]);
		//cast(mat,MaterialLight).specularColor = Vector.ofArray([1.0, 1.0, 1.0, 32.0]);
		//cast(mat,MaterialLight).texture = bitmapTexture;
		
		mat = new MaterialNormalColor();
		cast(mat, MaterialNormalColor).technique.normalScale = new Vector3f(Math.random(), Math.random(), Math.random());
		
		initTower();
		initFloor();
		
		camera.location = (new Vector3f(0, 15, 8));
        camera.lookAt(new Vector3f(), new Vector3f(0, 1, 0));
        camera.frustumFar = 80;
		
		this.actionListener = new ShootActionListener(this.addBullet);
		
		mInputManager.addSingleMapping("shoot", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(actionListener, ["shoot"]);
		
		//var pl = new DirectionalLight();
		//pl.position = new Vector3f(0, 25, 8);
		//pl.color = new Color(0.8, 0.8, 0.8, 1);
		//pl.direction = new Vector3f(0, 1, 0);
		//pl.radius = 1106;
		//scene.addLight(pl);
		
		flyCam.setDragToRotate(true);
		
		Stats.show(stage);
		start();
	}
	
	private var bricksPerLayer:Int = 8;
	private var brickLayers:Int = 20;
	private var angle:Float = 0;
	private function initTower():Void
	{
		var tempX:Float = 0;
        var tempY:Float = 0;
        var tempZ:Float = 0;
        angle = 0;
        for (i in 0...brickLayers)
		{
            // Increment rows
            if (i != 0) 
			{
                tempY += brickHeight * 2;
            } 
			else
			{
                tempY = brickHeight;
            }
            // Alternate brick seams
            angle = 360.0 / bricksPerLayer * i/2;
            for (j in 0...bricksPerLayer)
			{
              tempZ = Math.cos(FastMath.toRadians(angle))*radius;
              tempX = Math.sin(FastMath.toRadians(angle)) * radius;
			  
              //Logger.log("x=" + tempX + " y=" + tempY + " z=" + tempZ);
			  
              var vt:Vector3f = new Vector3f(tempX, tempY, tempZ);
              // Add crenelation
              if (i == brickLayers - 1)
			  {
                if (j % 2 == 0)
				{
                    addBrick(vt);
                }
              }
              // Create main tower
              else
			  {
                addBrick(vt);
              }
              angle += 360.0 / bricksPerLayer;
            }
        }
	}
	
	public function initFloor():Void
	{
        var floorBox:Box = new Box(10, 0.1, 5);
        //floorBox.scaleTextureCoordinates(new Vector2f(3, 6));
		
		var bitmapTexture:Texture2D = new Texture2D(new FLOOR_ASSET(0, 0));
		bitmapTexture.wrapMode = Context3DWrapMode.REPEAT;
		var mat3:Material = new MaterialTexture(bitmapTexture);

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