package examples.effect.gpu;

import flash.display.BitmapData;
import flash.events.MouseEvent;
import angle3d.app.SimpleApplication;
import angle3d.effect.gpu.influencers.birth.DefaultBirthInfluencer;
import angle3d.effect.gpu.influencers.life.DefaultLifeInfluencer;
import angle3d.effect.gpu.influencers.position.PlanePositionInfluencer;
import angle3d.effect.gpu.influencers.scale.DefaultScaleInfluencer;
import angle3d.effect.gpu.influencers.velocity.EmptyVelocityInfluencer;
import angle3d.effect.gpu.ParticleShape;
import angle3d.effect.gpu.ParticleShapeGenerator;
import angle3d.effect.gpu.ParticleSystem;
import angle3d.math.FastMath;
import angle3d.math.Vector3f;
import angle3d.texture.BitmapTexture;
import angle3d.texture.Texture2D;
import angle3d.utils.Stats;



/**
 * 
 */
class CrazyFlash extends BasicExample
{
	static function main() 
	{
		flash.Lib.current.addChild(new CrazyFlash());
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
		
		flyCam.setDragToRotate(true);
		
		var bitmapData:BitmapData = new EMBED_DEBRIS(0, 0);
		var texture:BitmapTexture = new BitmapTexture(bitmapData, false);
		
		var particleGenerator:ParticleShapeGenerator = new ParticleShapeGenerator(150, 3);
		particleGenerator.setPositionInfluencer(new PlanePositionInfluencer(new Vector3f(0, 0, 0),5,5,"xy"));
		particleGenerator.setVelocityInfluencer(new EmptyVelocityInfluencer());
		particleGenerator.setScaleInfluencer(new DefaultScaleInfluencer(1, 0.0));
		particleGenerator.setBirthInfluencer(new DefaultBirthInfluencer());
		particleGenerator.setLifeInfluencer(new DefaultLifeInfluencer(3, 3));

		bulletShape = particleGenerator.createParticleShape("bulletShape", texture);
		//bulletShape.blendMode = BlendMode.AlphaAdditive;
		bulletShape.setColor(0xffffff, 0xffffff);
		bulletShape.setAlpha(1.0, 1.0);
		bulletShape.setAcceleration(new Vector3f(0, -0.3, 0));
		bulletShape.setSize(3.0, 0.5);
		bulletShape.loop = true;
		
		var particleGenerator2:ParticleShapeGenerator = new ParticleShapeGenerator(10, 10);
		particleGenerator2.setPositionInfluencer(new PlanePositionInfluencer(new Vector3f(0, 0, 0),5,5,"xy"));
		particleGenerator2.setVelocityInfluencer(new EmptyVelocityInfluencer());
		particleGenerator2.setScaleInfluencer(new DefaultScaleInfluencer(0.5, 0.4));
		particleGenerator2.setLifeInfluencer(new DefaultLifeInfluencer(0.1, 2));
		
		bitmapData = new EMBED_GLOW(0, 0);
		var texture2:Texture2D = new BitmapTexture(bitmapData, false);
		
		
		var shape:ParticleShape = particleGenerator.createParticleShape("glowShape", texture2);
		//shape.setColor(0xffffff, 0xffffff);
		shape.setAlpha(1.0, 0);
//			shape.setAcceleration(new Vector3f(0, 0, 0));
		shape.setSize(0.3, 1.0);
		shape.loop = true;
		
		particleSystem = new ParticleSystem("bulletShapeSystem");
		particleSystem.addShape(bulletShape);
		//particleSystem.addShape(shape);
		scene.attachChild(particleSystem);
		
		camera.location.setTo(0, 0, -3);
		camera.lookAt(new Vector3f(), Vector3f.UNIT_Y);
		
		particleSystem.play();
		
		this.stage.doubleClickEnabled = true;
		this.stage.addEventListener(MouseEvent.DOUBLE_CLICK, _doubleClickHandler);
		
		
		start();
	}
	
	private function _doubleClickHandler(e:MouseEvent):Void
	{
		particleSystem.playOrPause();
	}
	
	private var angle:Float = 0;
	
	override public function simpleUpdate(tpf:Float):Void
	{
		super.simpleUpdate(tpf);
		
		angle += 0.03;
		angle %= FastMath.TWO_PI;
		
		//			camera.location.setTo(Math.cos(angle) * 5, 10, Math.sin(angle) * 5);
		//			camera.lookAt(new Vector3f(), Vector3f.Y_AXIS);
	}
}

@:bitmap("../assets/embed/particle/spikey.png") class EMBED_DEBRIS extends BitmapData { }
@:bitmap("../assets/embed/particle/glow.png") class EMBED_GLOW extends BitmapData { }