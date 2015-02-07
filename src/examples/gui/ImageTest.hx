package examples.gui;


import flash.display.BitmapData;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.BlendMode;
import org.angle3d.material.MaterialTexture;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.ui.Picture;
import org.angle3d.texture.Texture2D;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/no-shader.png") class EmbedPositiveZ extends BitmapData { }
@:bitmap("../assets/embed/rock.jpg") class Embed2 extends BitmapData { }

//TODO 测试混合模式
class ImageTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new ImageTest());
	}
	
	private var image:Picture;
	private var image2:Picture;

	public function new()
	{
		super();
	}

	private var material:MaterialTexture;
	private var material2:MaterialTexture;

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		flyCam.setEnabled(false);

		var texture:Texture2D = new Texture2D(new EmbedPositiveZ(0,0));
		var texture2:Texture2D = new Texture2D(new Embed2(0,0));

		image = new Picture("image", false);
		image.move(new Vector3f(0, 0, 20));
		image.setPosition(200, 200);
		image.setSize(200, 200);
		image.setTexture(texture, true);


		material = cast image.getMaterial();
		//material.technique.renderState.applyBlendMode = true;
		//material.technique.renderState.blendMode = BlendMode.Additive;

		image2 = new Picture("image2", false);
		image2.move(new Vector3f(0, 0, 10));
		image2.setPosition(350, 200);
		image2.setSize(300, 300);
		image2.setTexture(texture2,false);

		material2 = cast image2.getMaterial();
		material2.technique.renderState.applyBlendMode = true;
		material2.technique.renderState.blendMode = BlendMode.Modulate;
		
		gui.attachChild(image);
		gui.attachChild(image2);
		
		Stats.show(stage);
		start();
	}

	override public function simpleUpdate(tpf:Float):Void
	{
	}
}

