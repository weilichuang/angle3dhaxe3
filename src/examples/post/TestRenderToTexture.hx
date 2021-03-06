package examples.post;
import flash.display.BitmapData;
import flash.Lib;
import org.angle3d.Angle3D;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.Material;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Geometry;
import org.angle3d.scene.shape.Box;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.texture.FrameBuffer;
import org.angle3d.texture.Texture2D;
import org.angle3d.texture.Texture;
import org.angle3d.utils.Stats;

/**
 * This test renders a scene to a texture, then displays the texture on a cube.
 */
class TestRenderToTexture extends BasicExample
{
	static function main() 
	{
		Lib.current.addChild(new TestRenderToTexture());
	}
	
	private var offBox:Geometry;
    private var angle:Float = 0;
    private var offView:ViewPort;
	
	public function new()
	{
		super();
	}
	
	public function setupOffscreenView():Texture
	{
        var offCamera:Camera = new Camera(512, 512);

        offView = mRenderManager.createPreView("Offscreen View", offCamera);
        offView.setClearFlags(true, true, true);
        offView.backgroundColor = new Color(0.2, 0.2, 0.2, 1);

        // create offscreen framebuffer
		var offTexture:Texture2D = new Texture2D(512, 512, false);
        var offBuffer:FrameBuffer = new FrameBuffer(512, 512);
		offBuffer.setColorTexture(offTexture);

        //setup framebuffer's cam
        offCamera.setFrustumPerspective(45, 1, 1, 1000);
        offCamera.location = new Vector3f(0, 0, -5);
        offCamera.lookAt(new Vector3f(0, 0, 0), Vector3f.UNIT_Y);

        //set viewport to render to offscreen framebuffer
        offView.setOutputFrameBuffer(offBuffer);

        // setup framebuffer's scene
        var boxMesh:Box = new Box(1, 1, 1);
		
		var decalMap : BitmapTexture = new BitmapTexture(new DECALMAP_ASSET(0, 0));
		
		var material:Material = new Material();
		material.load(Angle3D.materialFolder + "material/unshaded.mat");
		material.setTexture("u_DiffuseMap", decalMap);
		
        offBox = new Geometry("box", boxMesh);
        offBox.setMaterial(material);

        // attach the scene to the viewport to be rendered
        offView.attachScene(offBox);
        
        return offTexture;
    }

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		flyCam.setDragToRotate(true);
		
		mCamera.location = (new Vector3f(3, 3, 3));
        mCamera.lookAt(Vector3f.ZERO, Vector3f.UNIT_Y);

        //setup main scene
        var quad:Geometry = new Geometry("box", new Box(1, 1, 1));

        var offTex:Texture = setupOffscreenView();
		
		var mat:Material = new Material();
		mat.load(Angle3D.materialFolder + "material/unshaded.mat");
		mat.setTexture("u_DiffuseMap", offTex);
        quad.setMaterial(mat);
        mScene.attachChild(quad);

		
		start();
	}

	override public function simpleUpdate(tpf:Float):Void
	{
		var q:Quaternion = new Quaternion();
        
		angle += tpf;
		angle %= FastMath.TWO_PI;
		q.fromAngles(angle, 0, angle);
		
		offBox.setLocalRotation(q);
		offBox.updateLogicalState(tpf);
		offBox.updateGeometricState();
	}
}

@:bitmap("../assets/embed/no-shader.png") class DECALMAP_ASSET extends flash.display.BitmapData { }