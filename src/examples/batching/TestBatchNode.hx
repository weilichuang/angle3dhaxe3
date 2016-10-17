package examples.batching;

import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.Material;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.BatchNode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/wood.jpg") class ROCK_ASSET extends flash.display.BitmapData { }


class TestBatchNode extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestBatchNode());
	}

	private var batch:BatchNode;

	private var cube:Geometry;
	private var cube2:Geometry;

	private var time:Float = 0;
	
	public function new() 
	{
		super();
		
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		batch = new BatchNode("theBatchNode");
		
		var boxShape:Box = new Box(1, 1, 1);
		cube = new Geometry("cube1", boxShape);
		
		var bitmapTexture:BitmapTexture = new BitmapTexture(new ROCK_ASSET(0, 0));

		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setTexture("u_DiffuseMap", bitmapTexture);
		
		cube.setMaterial(mat);
		
		var boxShape2:Box = new Box(1, 1, 1);
		cube2 = new Geometry("cube2", boxShape2);
		cube2.setMaterial(mat);
		
		batch.attachChild(cube);
		batch.attachChild(cube2);
		batch.batch();
		
		scene.attachChild(batch);
		
		cube.setTranslationXYZ(3, 0, 0);
		cube2.setTranslationXYZ(0, 20, 0);

        flyCam.setMoveSpeed(10);
		flyCam.setEnabled(false);

		
		start();
	}
	
	override public function simpleUpdate(tpf:Float):Void 
	{
		super.simpleUpdate(tpf);
		
        time += tpf;

        cube2.setTranslationXYZ(Math.sin(-time) * 3, Math.cos(time) * 3, 0);
        cube2.setLocalRotation(new Quaternion().fromAngleAxis(time, Vector3f.UNIT_Z));
		
		var scale:Float = Math.max(Math.sin(time), 0.5);
        cube2.setLocalScaleXYZ(scale,scale,scale);
	}
}