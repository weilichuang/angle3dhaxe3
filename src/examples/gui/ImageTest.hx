package examples.gui;


import flash.display.BitmapData;
import org.angle3d.app.SimpleApplication;
import org.angle3d.material.BlendMode;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.ui.Picture;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;

@:bitmap("../assets/embed/no-shader.png") class EmbedPositiveZ extends BitmapData { }
@:bitmap("../assets/embed/rock.jpg") class Embed2 extends BitmapData { }

class ImageTest extends BasicExample
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

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);

		flyCam.setEnabled(false);

		var texture:BitmapTexture = new BitmapTexture(new EmbedPositiveZ(0,0));
		var texture2:BitmapTexture = new BitmapTexture(new Embed2(0,0));

		image = new Picture("image", false);
		image.move(new Vector3f(0, 0, 20));
		image.setPosition(400, 300);
		image.setSize(256, 256);
		image.setTexture(texture, true);

		image2 = new Picture("image2", false);
		image2.move(new Vector3f(0, 0, 10));
		image2.setPosition(420, 320);
		image2.setSize(256, 256);
		image2.setTexture(texture2,false);

		//var material2 = cast image2.getMaterial();
		//material2.getAdditionalRenderState().setBlendMode(BlendMode.Modulate);
		
		gui.attachChild(image);
		gui.attachChild(image2);
		
		Stats.show(stage);
		start();
	}

	override public function simpleUpdate(tpf:Float):Void
	{
	}
}

