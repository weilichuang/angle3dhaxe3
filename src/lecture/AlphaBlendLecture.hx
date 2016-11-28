package lecture;

import flash.text.TextField;
import flash.Vector;
import org.angle3d.material.BlendMode;
import org.angle3d.math.Vector2f;
import flash.Lib;
import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.post.filter.FadeFilter;
import org.angle3d.post.filter.FogFilter;
import org.angle3d.post.FilterPostProcessor;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.LightNode;
import org.angle3d.scene.Node;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.ui.Picture;
import org.angle3d.shadow.BasicShadowRenderer;
import org.angle3d.utils.Stats;

class AlphaBlendLecture extends BasicLecture
{
	static function main() 
	{
		Lib.current.addChild(new AlphaBlendLecture());
	}
	
	private var enabled:Bool = false;
	public function new() 
	{
		super();
	}
	
	private var _center:Vector3f;
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		var node:Geometry = createBox(0);
		node.setTranslationXYZ(0, 5, 15);
		node.localQueueBucket = QueueBucket.Transparent;
		scene.attachChild(node);
		
		var node2:Geometry = createBox(0);
		node2.setTranslationXYZ(5, 5, 25);
		node2.localQueueBucket = QueueBucket.Transparent;
		scene.attachChild(node2);
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(0, 10, 80);
		camera.lookAt(_center, Vector3f.UNIT_Y);
		
		flyCam.setMoveSpeed(20);

		initInputs();
		
		reshape(mContextWidth, mContextHeight);
		
		start();
	}
	
	private function initInputs():Void
	{
		mInputManager.addTrigger("toggle", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, Vector.ofArray(["toggle"]));
	}
	
	private function createBox(index:Int):Geometry
	{
		var geometry:Geometry = new Geometry("box" + index,new Box(5,5,5));
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setTransparent(true);
		mat.getAdditionalRenderState().setBlendMode(BlendMode.Alpha);
		mat.setParam("u_MaterialColor", VarType.COLOR, new Color(Math.random(),Math.random(),Math.random(),0.7));
		
		geometry.setMaterial(mat);
		
		return geometry;
	}
	
	override public function onAction(name:String, value:Bool, tpf:Float):Void
	{
		super.onAction(name, value, tpf);
		
		if (name == "toggle" && value)
		{
			if (enabled)
			{
				enabled = false;
			}
			else
			{
				enabled = true;
			}
		}
	}
}