package examples.model;

import flash.display3D.Context3DTriangleFace;

import org.angle3d.app.SimpleApplication;
import org.angle3d.collision.CollisionResult;
import org.angle3d.collision.CollisionResults;
import org.angle3d.material.MaterialColorFill;
import org.angle3d.material.MaterialTexture;
import org.angle3d.math.Ray;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Cube;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.shape.Torus;
import org.angle3d.scene.shape.TorusKnot;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

@:bitmap("embed/rock.jpg") class ROCK_ASSET extends flash.display.BitmapData { }

//TODO 添加箭头测试
/**
 * 拾取测试,拾取到的物品高亮显示
 * 这里高亮方式用了一种hack方式
 * 在原模型位置添加一个相同模型，稍微放大，然后设置其cullMode为back
 */
class ShapeCollisionTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new ShapeCollisionTest());
	}
	
	private var angle:Float;

	public function new()
	{
		super();

		angle = 0;
	}

	private var selectedMaterial:MaterialColorFill;
	private var selectedGeometry:Geometry;

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		flyCam.setDragToRotate(true);

		var bitmapTexture:Texture2D = new Texture2D(new ROCK_ASSET(0, 0));
		var material:MaterialTexture = new MaterialTexture(bitmapTexture);
		var gm:Geometry;
		var cube:Cube = new Cube(10, 10, 10, 1, 1, 1);
		
		for (i in 0...20)
		{
			for (j in 0...20)
			{
				gm = new Geometry("cube", cube);
				gm.setMaterial(material);
				gm.setTranslationXYZ((i - 10) * 25, 0, (j - 10) * 25);
				scene.attachChild(gm);
			}
		}
		
		selectedMaterial = new MaterialColorFill(0xFFff00);
		selectedMaterial.technique.renderState.cullMode = Context3DTriangleFace.BACK;

		camera.location.setTo(Math.cos(angle) * 300, 100, Math.sin(angle) * 300);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
		Stats.show(stage);
		
		results = new CollisionResults();
		
		start();
	}

	private var results:CollisionResults;
	override public function simpleUpdate(tpf:Float):Void
	{
		if (selectedGeometry != null)
		{
			scene.detachChild(selectedGeometry);
		}

		var origin:Vector3f = camera.getWorldCoordinates(mInputManager.cursorPosition, 0.0);
		var direction:Vector3f = camera.getWorldCoordinates(mInputManager.cursorPosition, 0.3);
		direction.subtractLocal(origin).normalizeLocal();

		var ray:Ray = new Ray(origin, direction);
		
		scene.collideWith(ray, results);

		if (results.size > 0)
		{
			var closest:CollisionResult = results.getClosestCollision();
			selectedGeometry = new Geometry(closest.geometry.name + "_selected", closest.geometry.getMesh());
			selectedGeometry.setScaleXYZ(1.03, 1.03, 1.03);
			selectedGeometry.setMaterial(selectedMaterial);
			selectedGeometry.translation = closest.geometry.translation;
			scene.attachChild(selectedGeometry);
		}
	}
}

