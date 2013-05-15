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
//			flyCam.setEnabled(false);

		var colorMat:MaterialColorFill = new MaterialColorFill(0xFF0000);
		
		var gm:Geometry;

		var cube:Cube = new Cube(100, 100, 100, 1, 1, 1);
		gm = new Geometry("cube", cube);
		gm.setMaterial(colorMat);
		gm.setTranslationXYZ(-100, 0, 0);
		scene.attachChild(gm);

		selectedMaterial = new MaterialColorFill(0xFFff00);
		selectedMaterial.technique.renderState.cullMode = Context3DTriangleFace.BACK;

		var torus:Torus = new Torus(50, 10, 10, 10, true);
		gm = new Geometry("torus", torus);
		gm.setMaterial(colorMat);
		gm.setTranslationXYZ(100, 0, 0);
		scene.attachChild(gm);

		var torusKnot:TorusKnot = new TorusKnot(30, 10, 20, 20, false, 2, 3, 2);
		gm = new Geometry("torusKnot", torusKnot);
		gm.setMaterial(colorMat);
		gm.setTranslationXYZ(100, 0, -100);
		scene.attachChild(gm);

		var sphere:Sphere = new Sphere(20, 10, 10);
		gm = new Geometry("sphere", sphere);
		gm.setMaterial(colorMat);
		gm.setTranslationXYZ(-100, 0, -100);
		scene.attachChild(gm);

		camera.location.setTo(0, 0, 300);
		camera.location.setTo(Math.cos(angle) * 300, 100, Math.sin(angle) * 300);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
		
		Stats.show(stage);
		
		start();
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		if (selectedGeometry != null)
		{
			scene.detachChild(selectedGeometry);
		}

		var origin:Vector3f = camera.getWorldCoordinates(mInputManager.getCursorPosition(), 0.0);
		var direction:Vector3f = camera.getWorldCoordinates(mInputManager.getCursorPosition(), 0.3);
		direction.subtractLocal(origin).normalizeLocal();

		var ray:Ray = new Ray(origin, direction);
		var results:CollisionResults = new CollisionResults();
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

