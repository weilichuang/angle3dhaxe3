package examples.model;

import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.collision.CollisionResult;
import org.angle3d.collision.CollisionResults;
import org.angle3d.material.CullMode;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.Ray;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Cube;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;


@:bitmap("../assets/embed/rock.jpg") class ROCK_ASSET extends flash.display.BitmapData { }

//TODO 添加箭头测试
/**
 * 拾取测试,拾取到的物品高亮显示
 * 这里高亮方式用了一种hack方式
 * 在原模型位置添加一个相同模型，稍微放大，然后设置其cullMode为back
 */
class ShapeCollisionTest extends BasicExample
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

	private var selectedMaterial:Material;
	private var selectedGeometry:Geometry;

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		flyCam.setDragToRotate(true);

		var bitmapTexture:BitmapTexture = new BitmapTexture(new ROCK_ASSET(0, 0));
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/unshaded.mat");
		material.setTexture("u_DiffuseMap", bitmapTexture);
		
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
		
		selectedMaterial = new Material();
		selectedMaterial.load(Angle3D.materialFolder + "material/unshaded.mat");
		selectedMaterial.setColor("u_MaterialColor", Color.fromColor(0xFFff00));
		selectedMaterial.getAdditionalRenderState().setCullMode(CullMode.FRONT);

		camera.location.setTo(Math.cos(angle) * 300, 100, Math.sin(angle) * 300);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
		
		
		start();
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		if (selectedGeometry != null)
		{
			scene.detachChild(selectedGeometry);
		}

		var origin:Vector3f = camera.getWorldCoordinates(mInputManager.cursorPosition.x,mInputManager.cursorPosition.y, 0.0);
		var direction:Vector3f = camera.getWorldCoordinates(mInputManager.cursorPosition.x,mInputManager.cursorPosition.y, 0.3);
		direction.subtractLocal(origin).normalizeLocal();

		var ray:Ray = new Ray(origin, direction);
		var results:CollisionResults = new CollisionResults();
		scene.collideWith(ray, results);

		if (results.size > 0)
		{
			var closest:CollisionResult = results.getClosestCollision();
			selectedGeometry = new Geometry(closest.geometry.name + "_selected", closest.geometry.getMesh());
			selectedGeometry.setLocalScaleXYZ(1.03, 1.03, 1.03);
			selectedGeometry.setMaterial(selectedMaterial);
			selectedGeometry.translation = closest.geometry.translation;
			scene.attachChild(selectedGeometry);
		}
	}
}

