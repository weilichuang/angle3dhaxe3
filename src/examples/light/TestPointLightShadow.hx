package examples.light;

import flash.Lib;
import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.AnalogListener;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.PointLight;
import org.angle3d.material.Material;
import org.angle3d.material.VarType;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.post.FilterPostProcessor;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.shadow.EdgeFilteringMode;
import org.angle3d.shadow.PointLightShadowFilter;
import org.angle3d.shadow.PointLightShadowRenderer;
import org.angle3d.utils.Stats;

class TestPointLightShadow extends BasicExample implements AnalogListener
{
	static function main() 
	{
		Lib.current.addChild(new TestPointLightShadow());
	}
	
	public function new() 
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}
	
	private var _center:Vector3f;
	private var pl:PointLight;
	private var lightMdl:Geometry;
	
	private var useRender:Bool = true;
	private var plsr:PointLightShadowRenderer;
	private var shadowFilter:PointLightShadowFilter;
	private var fpp:FilterPostProcessor;
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		setupFloor();
		
		var hCount:Int = 6;
		var vCount:Int = 6;
		var halfHCount:Float = (hCount / 2);
		var halfVCount:Float = (vCount / 2);
		var index:Int = 0;
		for (i in 0...hCount)
		{
			for (j in 0...vCount)
			{
				var node:Geometry = createBox(i, j);
				node.localShadowMode = ShadowMode.CastAndReceive;
				node.setTranslationXYZ((i - halfHCount) * 15, 5, (j - halfVCount) * 15);
				scene.attachChild(node);
			}
		}
		
		_center = new Vector3f(0, 0, 0);

		camera.location.setTo(0, 40, 80);
		camera.lookAt(_center, Vector3f.Y_AXIS);
		
		flyCam.setMoveSpeed(20);
		
		pl = new PointLight();
		pl.color = Color.Random();
		pl.radius = 2000;
		pl.position = new Vector3f(0, 35, 0);
		scene.addLight(pl);
		
		var lightMat:Material = new Material();
		lightMat.load(Angle3D.materialFolder + "material/unshaded.mat");
        lightMat.setColor("u_MaterialColor",  pl.color);
		
		lightMdl = new Geometry("Light", new Sphere(1, 10, 10));
        lightMdl.setMaterial(lightMat);
        lightMdl.setLocalTranslation(new Vector3f(0, 35, 0));
        scene.attachChild(lightMdl);
        
        plsr = new PointLightShadowRenderer(1024);
        plsr.setLight(pl);
		plsr.setShadowInfo(0.0005, 0.7);
        plsr.setEdgeFilteringMode(EdgeFilteringMode.Nearest);
        //plsr.showShadowMap(true);
		//plsr.showFrustum(true);
        viewPort.addProcessor(plsr);
		
		shadowFilter = new PointLightShadowFilter(1024);
		shadowFilter.setLight(pl);
		shadowFilter.setShadowInfo(0.0003, 0.5);
        shadowFilter.setEdgeFilteringMode(EdgeFilteringMode.Nearest);
		shadowFilter.setEnabled(false);
		fpp = new FilterPostProcessor();
		fpp.addFilter(shadowFilter);
		viewPort.addProcessor(fpp);
		
		reshape(mContextWidth, mContextHeight);
		
		mInputManager.addTrigger("toggle", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addTrigger("DistanceUp", new KeyTrigger(Keyboard.UP));
		mInputManager.addTrigger("DistanceDown", new KeyTrigger(Keyboard.DOWN));
		mInputManager.addTrigger("MoveLeft", new KeyTrigger(Keyboard.LEFT));
		mInputManager.addTrigger("MoveRight", new KeyTrigger(Keyboard.RIGHT));
		mInputManager.addListener(this, Vector.ofArray(["toggle","DistanceUp", "DistanceDown","MoveLeft", "MoveRight"]));

		
		start();
	}
	
	private function setupFloor():Void
	{
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
        mat.setColor("u_MaterialColor",  new Color(0.8,0.8,0.8));

		var floor:Box = new Box(150, 1, 150);
		var floorGeom:Geometry = new Geometry("Floor", floor);
		floorGeom.setMaterial(mat);
		floorGeom.setLocalTranslation(new Vector3f(0, 0, 0));
		floorGeom.localShadowMode = ShadowMode.Receive;
		scene.attachChild(floorGeom);
	}
	
	private function createBox(i:Int,j:Int):Geometry
	{
		var geometry:Geometry = new Geometry("box" + i + "" + j, new Box(5, 5, 5));
		
		var mat:Material = new Material();
		//mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		//mat.setColor("u_MaterialColor", Color.Random());
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 1);
		mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
		mat.setColor("u_Ambient",  Color.White());
		mat.setColor("u_Diffuse",  Color.Random());
		mat.setColor("u_Specular", Color.White());

		geometry.setMaterial(mat);
		
		return geometry;
	}
	
	public function onAnalog(name:String, value:Float, tpf:Float):Void
	{
		switch(name)
		{
			case "DistanceUp":
				pl.position.y += 1;
				lightMdl.setLocalTranslation(pl.position);
			case "DistanceDown":
				pl.position.y -= 1;
				lightMdl.setLocalTranslation(pl.position);
			case "MoveLeft":
				pl.position.x -= 1;
				lightMdl.setLocalTranslation(pl.position);
			case "MoveRight":
				pl.position.x += 1;
				lightMdl.setLocalTranslation(pl.position);
		}
	}
	
	override public function onAction(name:String, isPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, isPressed, tpf);
		
		if (name == "toggle" && isPressed)
		{
            if (useRender)
			{
				useRender = false;
				viewPort.removeProcessor(plsr);
				shadowFilter.setEnabled(true);
				fpp.checkRenderDepth();
			}
			else
			{
				useRender = true;
				viewPort.addProcessor(plsr);
				shadowFilter.setEnabled(false);
				fpp.checkRenderDepth();
			}
        }
	}
	
	override public function update():Void 
	{
		super.update();
	}
}