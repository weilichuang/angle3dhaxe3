package examples.batching;

import angle3d.Angle3D;
import angle3d.app.SimpleApplication;
import angle3d.light.PointLight;
import angle3d.material.Material;
import angle3d.math.FastMath;
import angle3d.math.Vector2f;
import angle3d.math.Vector3f;
import angle3d.scene.BatchNode;
import angle3d.scene.Geometry;
import angle3d.scene.shape.Box;
import angle3d.math.Color;
import angle3d.texture.BitmapTexture;
import angle3d.texture.WrapMode;
import angle3d.utils.Logger;
import angle3d.utils.Stats;

@:bitmap("../assets/embed/wood.jpg") class ROCK_ASSET extends flash.display.BitmapData { }
@:bitmap("../assets/embed/wood.jpg") class FLOOR_ASSET extends flash.display.BitmapData { }

class TestBatchNodeTower extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestBatchNodeTower());
	}

	private var mat:Material;
	private var brick:Box;
	private var batchNode:BatchNode;
	
	private var nbBrick:Int = 0;
	private var radius:Float = 3;
	
	private var brickWidth:Float = 0.75;
	private var brickHeight:Float = 0.25;
	private var brickDepth:Float = 0.25;
	
	public function new() 
	{
		super();
		
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		var pl = new PointLight();
		pl.color = new Color(1, 1, 1);
		pl.radius = 2000;
		pl.position = new Vector3f(0, 20, 0);
		scene.addLight(pl);
		
		pointLight = new PointLight();
		pointLight.color = Color.Random();
		pointLight.radius = 2000;
		pointLight.position = new Vector3f(-10, 10, 0);
		scene.addLight(pointLight);
		
		batchNode = new BatchNode("batch Node");
		
		brick = new Box(brickWidth, brickHeight, brickDepth);
		brick.scaleTextureCoordinates(new Vector2f(0.5, 0.5));
	
		var bitmapTexture:BitmapTexture = new BitmapTexture(new ROCK_ASSET(0, 0));

		mat = new Material();
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setTexture("u_DiffuseMap", bitmapTexture);
		mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
        mat.setColor("u_Ambient",  Color.Random());
        mat.setColor("u_Diffuse",  Color.Random());
        mat.setColor("u_Specular", Color.Random());
		
		initTower();
		initFloor();
		
		camera.location = (new Vector3f(0, 25, 8));
        camera.lookAt(new Vector3f(), new Vector3f(0, 1, 0));
        camera.frustumFar = 80;
		
		batchNode.batch();
		scene.attachChild(batchNode);
		
		flyCam.setMoveSpeed(10);
		//flyCam.setEnabled(false);
		
		
		start();
	}
	
	private var bricksPerLayer:Int = 8;
	private var brickLayers:Int = 30;
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
              tempX = Math.sin(FastMath.toRadians(angle))*radius;
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
        floorBox.scaleTextureCoordinates(new Vector2f(3, 6));
		
		var bitmapTexture:BitmapTexture = new BitmapTexture(new FLOOR_ASSET(0, 0));
		bitmapTexture.wrapMode = WrapMode.REPEAT;

		var mat3:Material = new Material();
		mat3.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat3.setTexture("u_DiffuseMap", bitmapTexture);
		
        var floor:Geometry = new Geometry("floor", floorBox);
        floor.setMaterial(mat3);
        floor.setTranslationXYZ(0, 0, 0);
        scene.attachChild(floor);
    }
	
	public function addBrick(ori:Vector3f):Void
	{
        var reBoxg:Geometry = new Geometry("brick", brick);
        reBoxg.setMaterial(mat);
        reBoxg.setLocalTranslation(ori);
        reBoxg.rotateAngles(0, FastMath.toRadians(angle) , 0);
        this.batchNode.attachChild(reBoxg);
        nbBrick++;
    }
	
	private var rotationAngle:Float = 0;
	private var pointLight:PointLight;
	override public function simpleUpdate(tpf : Float) : Void
	{
		super.simpleUpdate(tpf);
		
		rotationAngle += 0.01;

		if (rotationAngle > FastMath.TWO_PI)
		{
			pointLight.color = Color.Random();
		}

		rotationAngle %= FastMath.TWO_PI;
		pointLight.position.setTo(Math.cos(rotationAngle) * 10, 10, Math.sin(rotationAngle) * 10);
	}
	
}