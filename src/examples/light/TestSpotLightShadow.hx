package examples.light;
import flash.Lib;
import flash.ui.Keyboard;
import flash.Vector;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.SpotLight;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.post.FilterPostProcessor;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.shadow.EdgeFilteringMode;
import org.angle3d.shadow.SpotLightShadowFilter;
import org.angle3d.shadow.SpotLightShadowRenderer;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.WrapMode;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/wood.jpg") class ROCK_ASSET extends flash.display.BitmapData { }

class TestSpotLightShadow extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestSpotLightShadow());
	}
	
	private var lightTarget:Vector3f;
	private var lightGeom:Geometry;
	private var spotLight:SpotLight;
	
	private var useRender:Bool = true;
	private var shadowRender:SpotLightShadowRenderer;
	private var shadowFilter:SpotLightShadowFilter;
	private var fpp:FilterPostProcessor;
	
	private var angle:Float = 0;
	private var stopMove:Bool = false;

	public function new() 
	{
		super();
		Angle3D.maxAgalVersion = 1;
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		setupFloor();
		setupLighting();
		
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(30);
		
		mCamera.setLocation(new Vector3f(27.492603, 29.138166, -13.232513));
		mCamera.setRotation(new Quaternion(0.25168246, -0.10547892, 0.02760565, 0.96164864));
		
		mCamera.lookAt(new Vector3f(0, 0, 0), Vector3f.UNIT_Y);

		mInputManager.addTrigger("stopMove", new KeyTrigger(Keyboard.NUMBER_1));
		mInputManager.addTrigger("toggle", new KeyTrigger(Keyboard.SPACE));
		mInputManager.addListener(this, Vector.ofArray(["toggle","stopMove"]));
		
		
		start();
	}
	
	private function setupLighting():Void
	{
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.3, 0.3, 0.3);
		scene.addLight(al);
		
		scene.localShadowMode = ShadowMode.CastAndReceive;
		
		lightTarget = new Vector3f(0, 0, 0);
		
		spotLight = new SpotLight();
		spotLight.color = Color.Random(false);
		spotLight.spotRange = 1000;
		spotLight.innerAngle = 10 * FastMath.DEG_TO_RAD;
		spotLight.outerAngle = 30 * FastMath.DEG_TO_RAD;
		spotLight.position = new Vector3f(Math.cos(angle) * 20, 15, Math.sin(angle) * 20);
		spotLight.direction = lightTarget.subtract(spotLight.position).normalizeLocal();
		scene.addLight(spotLight);
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setColor("u_MaterialColor", spotLight.color);
		
		lightGeom = new Geometry("Light", new Sphere(0.1, 10, 10));
		lightGeom.setMaterial(mat);
		lightGeom.setLocalTranslation(new Vector3f(Math.cos(angle) * 20, 15, Math.sin(angle) * 20));
		lightGeom.setLocalScaleXYZ(5, 5, 5);
		scene.attachChild(lightGeom);
		
		var mat2:Material = new Material();
		//mat2.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat2.load(Angle3D.materialFolder + "material/lighting.mat");
		mat2.setFloat("u_Shininess", 32);
        mat2.setBoolean("useMaterialColor", false);
		mat2.setBoolean("useVertexLighting", false);
		mat2.setBoolean("useLowQuality", false);
        mat2.setColor("u_Ambient",  Color.White());
        mat2.setColor("u_Diffuse",  Color.Random());
        mat2.setColor("u_Specular", Color.White());
		
		var box2:Box = new Box(4, 4, 4);
		var boxGeom = new Geometry("Box", box2);
		boxGeom.setMaterial(mat2);
		boxGeom.localShadowMode = ShadowMode.Cast;
		boxGeom.setLocalTranslation(new Vector3f(0, 4, 0));
		scene.attachChild(boxGeom);

		shadowRender = new SpotLightShadowRenderer(512);
		shadowRender.setLight(spotLight);
		shadowRender.setShadowInfo(0.0005, 0.5);
		//shadowRender.setShadowZExtend(100);
		//shadowRender.setShadowZFadeLength(5);
		shadowRender.setEdgeFilteringMode(EdgeFilteringMode.Nearest);
		shadowRender.showShadowMap(true);
		shadowRender.showFrustum(true);
		mViewPort.addProcessor(shadowRender);
		shadowRender.setRenderBackFacesShadows(true);
		
		//TODO SpotLightShadowFilter显示错误
		shadowFilter = new SpotLightShadowFilter(512);
		shadowFilter.setLight(spotLight);
		shadowFilter.setShadowInfo(0.0005, 0.5);
		//shadowFilter.setShadowZExtend(100);
		//shadowFilter.setShadowZFadeLength(5);
		shadowFilter.setEdgeFilteringMode(EdgeFilteringMode.Nearest);
		shadowFilter.setEnabled(false);
		
		fpp = new FilterPostProcessor();
		fpp.addFilter(shadowFilter);
		viewPort.addProcessor(fpp);
	}
	
	private function setupFloor():Void
	{
		var mat:Material = new Material();
		//mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.load(Angle3D.materialFolder + "material/lighting.mat");
		mat.setFloat("u_Shininess", 32);
        mat.setBoolean("useMaterialColor", false);
		mat.setBoolean("useVertexLighting", false);
		mat.setBoolean("useLowQuality", false);
        mat.setColor("u_Ambient",  Color.White());
        mat.setColor("u_Diffuse",  new Color(0.8,0.8,0.8));
        mat.setColor("u_Specular", Color.White());

		var groundTexture = new BitmapTexture(new ROCK_ASSET(0, 0));
		groundTexture.wrapMode = org.angle3d.texture.WrapMode.REPEAT;
		mat.setTexture("u_DiffuseMap", groundTexture);
		
		var floor:Box = new Box(50, 1, 50);
		var floorGeom:Geometry = new Geometry("Floor", floor);
		floor.scaleTextureCoordinates(new Vector2f(5, 5));
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
			
		if (name == "toggle" && isPressed)
		{
            if (useRender)
			{
				useRender = false;
				//shadowRender.showFrustum(false);
				viewPort.removeProcessor(shadowRender);
				shadowFilter.setEnabled(true);
				fpp.checkRenderDepth();
			}
			else
			{
				useRender = true;
				//shadowRender.showFrustum(true);
				viewPort.addProcessor(shadowRender);
				shadowFilter.setEnabled(false);
				fpp.checkRenderDepth();
			}
        }
			
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
		super.simpleUpdate(tpf);
		
		if (!stopMove)
		{
			angle += tpf * 0.5;
			angle %= FastMath.TWO_PI;
			
			spotLight.position = new Vector3f(Math.cos(angle) * 20, 15, Math.sin(angle) * 20);
			lightGeom.setLocalTranslation(spotLight.position);
			spotLight.direction = lightTarget.subtract(spotLight.position);
		}
	}
}