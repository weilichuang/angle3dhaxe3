package examples.effect.gpu;

import examples.skybox.DefaultSkyBox;
import flash.display.BitmapData;
import flash.events.MouseEvent;
import org.angle3d.app.SimpleApplication;
import org.angle3d.effect.gpu.influencers.life.DefaultLifeInfluencer;
import org.angle3d.effect.gpu.influencers.position.DefaultPositionInfluencer;
import org.angle3d.effect.gpu.influencers.scale.DefaultScaleInfluencer;
import org.angle3d.effect.gpu.influencers.spritesheet.DefaultSpriteSheetInfluencer;
import org.angle3d.effect.gpu.influencers.velocity.DefaultVelocityInfluencer;
import org.angle3d.effect.gpu.ParticleShape;
import org.angle3d.effect.gpu.ParticleShapeGenerator;
import org.angle3d.effect.gpu.ParticleSystem;
import org.angle3d.math.FastMath;
import org.angle3d.math.Vector3f;
import org.angle3d.texture.BitmapTexture;
import org.angle3d.utils.Stats;



/**
 * 测试SpriteSheet模式
 */
class BulletTest extends SimpleApplication
{
	static function main() 
	{
		flash.Lib.current.addChild(new BulletTest());
	}
	
	private var particleSystem:ParticleSystem;
	private var bulletShape:ParticleShape;

	public function new()
	{
		super();
	}

	override private function initialize(width:Int, height:Int):Void
	{
		super.initialize(width, height);
		
		mViewPort.backgroundColor.setColor(0x0);

		flyCam.setDragToRotate(true);

		var bitmapData:BitmapData = new EMBED_DEBRIS(0, 0);
		var texture:BitmapTexture = new BitmapTexture(bitmapData, false);

		var particleGenerator:ParticleShapeGenerator = new ParticleShapeGenerator(50, 5);
		particleGenerator.setPositionInfluencer(new DefaultPositionInfluencer(new Vector3f(0, 0, 0)));
		particleGenerator.setVelocityInfluencer(new DefaultVelocityInfluencer(new Vector3f(1.0, 8, 1), 0.3));
		particleGenerator.setScaleInfluencer(new DefaultScaleInfluencer(0.5, 0.0));
		particleGenerator.setLifeInfluencer(new DefaultLifeInfluencer(4, 5));
		particleGenerator.setSpriteSheetInfluencer(new DefaultSpriteSheetInfluencer(16));

		//混合模式用于这个不太对
		bulletShape = particleGenerator.createParticleShape("bulletShape", texture);
		//bulletShape.blendMode = BlendMode.Color;
		//bulletShape.setColor(0xffffff, 0xffffff);
		//bulletShape.setAlpha(1.0, 0.5);
		bulletShape.setAcceleration(new Vector3f(0, -3, 0));
		bulletShape.setSpriteSheet(0.05, 4, 4);
		bulletShape.setSize(0.2, 0.2);
		bulletShape.loop = true;

		particleSystem = new ParticleSystem("bulletShapeSystem");
		particleSystem.addShape(bulletShape);
		scene.attachChild(particleSystem);
		
		var sky:DefaultSkyBox = new DefaultSkyBox(500);
		scene.attachChild(sky);

		camera.location.setTo(0, 0, -3);
		camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);

		particleSystem.play();

		this.stage.doubleClickEnabled = true;
		this.stage.addEventListener(MouseEvent.DOUBLE_CLICK, _doubleClickHandler);
		
		Stats.show(stage);
		start();
	}

	private function _doubleClickHandler(e:MouseEvent):Void
	{
		particleSystem.playOrPause();
	}

	private var angle:Float = 0;

	override public function simpleUpdate(tpf:Float):Void
	{
		angle += 0.03;
		angle %= FastMath.TWO_PI;

		//camera.location.setTo(Math.cos(angle) * 5, 0, Math.sin(angle) * 5);
		//camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}

@:bitmap("../assets/embed/particle/bullet.png") class EMBED_DEBRIS extends BitmapData { }
