package examples.light;
import flash.display3D.Context3DWrapMode;
import flash.ui.Keyboard;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.input.controls.KeyTrigger;
import org.angle3d.light.AmbientLight;
import org.angle3d.light.DirectionalLight;
import org.angle3d.material.Material;
import org.angle3d.material.sgsl.SgslCompiler;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.scene.shape.Sphere;
import org.angle3d.scene.Spatial;
import org.angle3d.shadow.DirectionalLightShadowRenderer;
import org.angle3d.shadow.EdgeFilteringMode;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/wood.jpg") class ROCK_ASSET extends flash.display.BitmapData { }

/**
 * ...
 * @author weilichuang
 */
class TestDirectionalLightShadow extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new TestDirectionalLightShadow());
	}
	
	private var objList:Array<Spatial>;
	private var matList:Array<Material>;
	
	private var light:DirectionalLight;
	private var shadowRenderer:DirectionalLightShadowRenderer;
	
	private var frustumSize:Int = 100;

	public function new() 
	{
		super();
		Angle3D.maxAgalVersion = 2;
	}
	
	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		setupFloor();
		
		flyCam.setDragToRotate(true);
		flyCam.setMoveSpeed(100);
		
		objList = [];
		objList[0] = new Geometry("sphere", new Sphere(2, 30, 30));
		objList[0].setShadowMode(ShadowMode.CastAndReceive);
        objList[1] = new Geometry("cube", new Box(1.0, 1.0, 1.0));
        objList[1].setShadowMode(ShadowMode.CastAndReceive);
		
		matList = [];
		matList[0] = new Material();
		matList[0].load(Angle3D.materialFolder + "material/unshaded.mat");
		matList[0].setColor("u_MaterialColor", Color.Green());
		
		matList[1] = new Material();
		matList[1].load(Angle3D.materialFolder + "material/unshaded.mat");
		matList[1].setColor("u_MaterialColor", Color.Yellow());
		
		for (i in 0...30)
		{
			var t:Spatial = objList[Std.int(Math.random() * 2)].clone("clone" + i, false);
			var scale:Float = Math.random() * 10;
			t.setLocalScaleXYZ(scale, scale, scale);
			t.setMaterial(matList[Std.int(Math.random() * 2)]);
			scene.attachChild(t);
			t.setLocalTranslation(new Vector3f(Math.random() * 200, Math.random() * 30 + 20, 30 * (i + 2)));
		}
		
		light = new DirectionalLight();
		light.direction = new Vector3f( -1, -1, -1);
		scene.addLight(light);
		
		var al:AmbientLight = new AmbientLight();
		al.color = new Color(0.5, 0.5, 0.5);
		scene.addLight(al);
		
		shadowRenderer = new DirectionalLightShadowRenderer(512, 3);
        shadowRenderer.setLight(light);
        shadowRenderer.setLambda(0.55);
        shadowRenderer.setShadowInfo(0.0005, 0.6);
        shadowRenderer.setEdgeFilteringMode(EdgeFilteringMode.Nearest);
        shadowRenderer.showFrustum(true);
		shadowRenderer.showShadowMap(true);
        mViewPort.addProcessor(shadowRenderer);
		
		mCamera.setLocation(new Vector3f(65.25412, 244.38738, 9.087874));
		mCamera.setRotation(new Quaternion(0.078139365, 0.050241485, -0.003942559, 0.9956679));
		
		initInputs();
		
		reshape(mContextWidth, mContextHeight);
		
		Stats.show(stage);
		start();
	}
	
	private function initInputs():Void
	{
		mInputManager.addSingleMapping("ThicknessUp", new KeyTrigger(Keyboard.Y));
        mInputManager.addSingleMapping("ThicknessDown", new KeyTrigger(Keyboard.H));
        mInputManager.addSingleMapping("lambdaUp", new KeyTrigger(Keyboard.U));
        mInputManager.addSingleMapping("lambdaDown", new KeyTrigger(Keyboard.J));
        mInputManager.addSingleMapping("switchGroundMat", new KeyTrigger(Keyboard.M));
        mInputManager.addSingleMapping("debug", new KeyTrigger(Keyboard.X));
        mInputManager.addSingleMapping("stabilize", new KeyTrigger(Keyboard.B));
        mInputManager.addSingleMapping("distance", new KeyTrigger(Keyboard.N));


        mInputManager.addSingleMapping("up", new KeyTrigger(Keyboard.NUMPAD_8));
        mInputManager.addSingleMapping("down", new KeyTrigger(Keyboard.NUMPAD_2));
        mInputManager.addSingleMapping("right", new KeyTrigger(Keyboard.NUMPAD_6));
        mInputManager.addSingleMapping("left", new KeyTrigger(Keyboard.NUMPAD_4));
        mInputManager.addSingleMapping("fwd", new KeyTrigger(Keyboard.PAGE_UP));
        mInputManager.addSingleMapping("back", new KeyTrigger(Keyboard.PAGE_DOWN));
        mInputManager.addSingleMapping("pp", new KeyTrigger(Keyboard.P));
		
		mInputManager.addSingleMapping("Size+", new KeyTrigger(Keyboard.W));
        mInputManager.addSingleMapping("Size-", new KeyTrigger(Keyboard.S));
		
		mInputManager.addListener(this, ["lambdaUp", "lambdaDown", "ThicknessUp", "ThicknessDown",
                "switchGroundMat", "debug", "up", "down", "right", "left", "fwd", "back", "pp", "stabilize", "distance"]);
		mInputManager.addListener(this, ["Size+", "Size-"]);
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
		groundTexture.wrapMode = Context3DWrapMode.REPEAT;
		mat.setTexture("u_DiffuseMap", groundTexture);
		
		var floor:Box = new Box(1000, 2, 1000, new Vector3f(0, 10, 550));
		var floorGeom:Geometry = new Geometry("Floor", floor);
		floor.scaleTextureCoordinates(new Vector2f(10, 10));
		floorGeom.setMaterial(mat);
		floorGeom.setLocalTranslation(new Vector3f(0, 0, 0));
		floorGeom.localShadowMode = ShadowMode.Receive;
		scene.attachChild(floorGeom);
	}
	
	override public function onAction(name:String, keyPressed:Bool, tpf:Float):Void
	{
		super.onAction(name, keyPressed, tpf);
		
		if (name == "pp" && keyPressed)
		{
            if (mCamera.isParallelProjection())
			{
                mCamera.setFrustumPerspective(45, mCamera.getWidth() / mCamera.getHeight(), 1, 1000);
            }
			else
			{
                mCamera.setParallelProjection(true);
                var aspect:Float = mCamera.getWidth() / mCamera.getHeight();
                mCamera.setFrustum(-1000, 1000, -aspect * frustumSize, aspect * frustumSize, frustumSize, -frustumSize);
            }
        }

        if (name == "lambdaUp" && keyPressed)
		{
            shadowRenderer.setLambda(shadowRenderer.getLambda() + 0.01);
            shadowRenderer.setLambda(shadowRenderer.getLambda() + 0.01);
            //System.out.println("Lambda : " + dlsr.getLambda());
        } 
		else if (name == "lambdaDown" && keyPressed)
		{
            shadowRenderer.setLambda(shadowRenderer.getLambda() - 0.01);
            shadowRenderer.setLambda(shadowRenderer.getLambda() - 0.01);
            //System.out.println("Lambda : " + dlsr.getLambda());
        }


        if (name == "debug" && keyPressed)
		{
            shadowRenderer.showFrustum(!shadowRenderer.isShowFrustum());
        }

        if (name == "stabilize" && keyPressed)
		{
            shadowRenderer.setEnabledStabilization(!shadowRenderer.isEnabledStabilization());
            //shadowStabilizationText.setText("(b:on/off) Shadow stabilization : " + dlsr.isEnabledStabilization());
        }
        if (name == "distance" && keyPressed)
		{
            if (shadowRenderer.getShadowZExtend() > 0) 
			{
                shadowRenderer.setShadowZExtend(0);
                shadowRenderer.setShadowZFadeLength(0);
                shadowRenderer.setShadowZExtend(0);
                shadowRenderer.setShadowZFadeLength(0);
            } 
			else 
			{
                shadowRenderer.setShadowZExtend(500);
                shadowRenderer.setShadowZFadeLength(50);
                shadowRenderer.setShadowZExtend(500);
                shadowRenderer.setShadowZFadeLength(50);
            }
            //shadowZfarText.setText("(n:on/off) Shadow extend to 500 and fade to 50 : " + (dlsr.getShadowZExtend() > 0));

        }

        //if (name == "switchGroundMat") && keyPressed)
		//{
            //if (ground.getMaterial() == matGroundL)
			//{
                //ground.setMaterial(matGroundU);
            //} 
			//else
			//{
                //ground.setMaterial(matGroundL);
            //}
        //}

        if (name == "up") 
		{
            up = keyPressed;
        }
        if (name == "down") 
		{
            down = keyPressed;
        }
        if (name == "right")
		{
            right = keyPressed;
        }
        if (name == "left")
		{
            left = keyPressed;
        }
        if (name == "fwd")
		{
            fwd = keyPressed;
        }
        if (name == "back")
		{
            back = keyPressed;
        }
	}
	
	private var up:Bool = false;
    private var down:Bool = false;
    private var left:Bool = false;
    private var right:Bool = false;
    private var fwd:Bool = false;
    private var back:Bool = false;
    private var time:Float = 0;
    private var s:Float = 1;
	override public function simpleUpdate(tpf:Float):Void
	{
		var v:Vector3f = light.direction;
		if (up)
		{
            v.y += tpf / s;
            setDir(v);
        }
        if (down)
		{
            v.y -= tpf / s;
            setDir(v);
        }
        if (right) 
		{
            v.x += tpf / s;
            setDir(v);
        }
        if (left) 
		{
            v.x -= tpf / s;
            setDir(v);
        }
        if (fwd) 
		{
            v.z += tpf / s;
            setDir(v);
        }
        if (back)
		{
            v.z -= tpf / s;
            setDir(v);
        }
	}
	
	private function setDir(v:Vector3f):Void
	{
		light.direction = v;
	}
}