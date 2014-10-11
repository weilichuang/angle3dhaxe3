package examples.batching;

import org.angle3d.app.SimpleApplication;
import org.angle3d.material.Material;
import org.angle3d.material.MaterialTexture;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.BatchNode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Logger;
import org.angle3d.utils.Stats;

@:bitmap("embed/BrickWall.jpg") class ROCK_ASSET extends flash.display.BitmapData { }
@:bitmap("embed/Pond.jpg") class FLOOR_ASSET extends flash.display.BitmapData { }

class TestBatchNodeTower extends SimpleApplication
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
		
		batchNode = new BatchNode("batch Node");
		
		brick = new Box(brickWidth, brickHeight, brickDepth);
		//brick.scaleTextureCoordinates(new Vector2f(1, 0.5));
	
		var bitmapTexture:Texture2D = new Texture2D(new ROCK_ASSET(0, 0));
		mat = new MaterialTexture(bitmapTexture);
		
		initTower();
		initFloor();
		
		camera.location = (new Vector3f(0, 25, 8));
        camera.lookAt(new Vector3f(), new Vector3f(0, 1, 0));
        camera.frustumFar = 80;
		
		batchNode.batch();
		scene.attachChild(batchNode);
		
		flyCam.setMoveSpeed(10);
		//flyCam.setEnabled(false);
		
		Stats.show(stage);
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
              Logger.log("x=" + tempX + " y=" + tempY + " z=" + tempZ);
			  
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
		var mat3:Material = new MaterialTexture(bitmapTexture);

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
	
}