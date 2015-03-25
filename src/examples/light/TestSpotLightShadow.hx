package examples.light;
import flash.Lib;
import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.input.KeyInput;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.post.FilterPostProcessor;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.shadow.BasicShadowRenderer;
import org.angle3d.shadow.EdgeFilteringMode;
import org.angle3d.shadow.ShadowUtil;
import org.angle3d.shadow.SpotLightShadowFilter;
import org.angle3d.shadow.SpotLightShadowRenderer;
import org.angle3d.utils.Stats;

class TestSpotLightShadow extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestSpotLightShadow());
	}
	
	private var lightTarget:Vector3f;
	private var lightGeom:Geometry;
	private var spotLight:SpotLight;
	
	private var shadowRender:SpotLightShadowRenderer;
	
	private var angle:Float = 0;
	private var stopMove:Bool = false;

	public function new() 
	{
		super();
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		mCamera.setLocation(new Vector3f(27.492603, 29.138166, -13.232513));
		mCamera.setRotation(new Quaternion(0.25168246, -0.10547892, 0.02760565, 0.96164864));
		mCamera.frustumFar = 30;
		
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(30);
		
		setupFloor();
		setupLighting();
		
		reshape(mContextWidth, mContextHeight);
		
		mInputManager.addSingleMapping("stopMove", new KeyTrigger(Keyboard.NUMBER_1));
		
		Stats.show(stage);
		start();
	}
	
	private function setupLighting():Void
	{
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.3, 0.3, 0.3);
		scene.addLight(al);
		
		scene.localShadowMode = ShadowMode.CastAndReceive;
		
		lightTarget = new Vector3f(12, 3.5, 30);
		
		spotLight = new SpotLight();
		spotLight.spotRange = 1000;
		spotLight.innerAngle = 5 * FastMath.DEGTORAD();
		spotLight.outerAngle = 10 * FastMath.DEGTORAD();
		spotLight.position = new Vector3f(70.70334, 34.013165, 27.1017);
		spotLight.direction = lightTarget.subtract(spotLight.position).normalizeLocal();
		scene.addLight(spotLight);
		
		var mat:Material = new Material();
		mat.load("assets/material/unshaded.mat");
		mat.setColor("u_MaterialColor", Color.Red());
		
		lightGeom = new Geometry("Light", new Sphere(0.1, 10, 10));
		lightGeom.setMaterial(mat);
		lightGeom.setLocalTranslation(new Vector3f(77.70334, 34.013165, 27.1017));
		lightGeom.setLocalScaleXYZ(5, 5, 5);
		scene.attachChild(lightGeom);
		
		//shadowRender = new SpotLightShadowRenderer(512);
		//shadowRender.setLight(spotLight);
		//shadowRender.setShadowIntensity(0.5);
		//shadowRender.setShadowZExtend(100);
		//shadowRender.setShadowZFadeLength(5);
		//shadowRender.setEdgeFilteringMode(EdgeFilteringMode.PCF4);
		//mViewPort.addProcessor(shadowRender);
		
		//var filter:SpotLightShadowFilter = new SpotLightShadowFilter(512);
		//filter.setLight(spotLight);
		//filter.setShadowIntensity(0.5);
		//filter.setShadowZExtend(100);
		//filter.setShadowZFadeLength(5);
		//filter.setEdgeFilteringMode(EdgeFilteringMode.PCF4);
		//filter.setEnabled(false);
		//
		//var fpp:FilterPostProcessor = new FilterPostProcessor();
		//fpp.addFilter(filter);
		//mViewPort.addProcessor(fpp);
	}
	
	private function setupFloor():Void
	{
		var mat:Material = new Material();
		mat.load("assets/material/unshaded.mat");
		mat.setColor("u_MaterialColor", Color.White());
		
		var floor:Box = new Box(50, 1, 50);
		var floorGeom:Geometry = new Geometry("Floor", floor);
		floorGeom.setMaterial(mat);
		floorGeom.setLocalTranslation(new Vector3f(0, 0, 0));
		floorGeom.localShadowMode = ShadowMode.Receive;
		scene.attachChild(floorGeom);
	}
	
	override public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, isPressed, tpf);
		
		if (!isPressed)
			return;
			
		switch(name)
		{
			case "stopMove":
					stopMove = !stopMove;
					Lib.trace('spotLight position: ${spotLight.position}');
					Lib.trace('spotLight direction: ${spotLight.direction}');
		}
	}
	override public function simpleUpdate(tpf:Float):Void
	{
		if (!stopMove)
		{
			super.simpleUpdate(tpf);
			
			angle+= tpf;
			angle %= FastMath.TWO_PI();
			
			spotLight.position = new Vector3f(Math.cos(angle) * 30, 34.013165, Math.sin(angle) * 30);
			lightGeom.setLocalTranslation(spotLight.position);
			spotLight.direction = lightTarget.subtract(spotLight.position);
		}
	}
}