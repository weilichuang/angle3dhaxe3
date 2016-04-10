package org.angle3d.effect.cpu;

import flash.Vector;
import org.angle3d.bounding.BoundingBox;
import org.angle3d.effect.cpu.influencers.DefaultParticleInfluencer;
import org.angle3d.effect.cpu.influencers.IParticleInfluencer;
import org.angle3d.effect.cpu.shape.EmitterPointShape;
import org.angle3d.effect.cpu.shape.EmitterShape;
import org.angle3d.math.Color;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.queue.QueueBucket;
import org.angle3d.renderer.queue.ShadowMode;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Geometry;
import org.angle3d.utils.TempVars;
/**
 * `ParticleEmitter` is a special kind of geometry which simulates
 * a particle system.
 * <p>
 * Particle emitters can be used to simulate various kinds of phenomena,
 * such as fire, smoke, explosions and much more.
 * <p>
 * Particle emitters have many properties which are used to control the
 * simulation. The interpretation of these properties depends on the
 * {ParticleInfluencer} that has been assigned to the emitter via
 * {ParticleEmitter#setParticleInfluencer(org.angle3d.effect.influencers.ParticleInfluencer) }.
 * By default the implementation {DefaultParticleInfluencer} is used.
 *
 */
/**
 * 粒子发射器
 *
 * 设计要点：
 * 需要有层级的概念，类似于Pyro
 * 一个完整的粒子效果可能是有多个子特效组成
 * 子特效至少包含开始时间和结束时间
 * 编辑器的话需要使用类似于时间轴的概念来安排子特效到特效中
 */
//TODO 包围盒大小应该初步确定，以后就不更改大小
class ParticleEmitter extends Geometry
{
	private static var DEFAULT_SHAPE:EmitterShape = new EmitterPointShape();
	private static var DEFAULT_INFLUENCER:IParticleInfluencer = new DefaultParticleInfluencer();
	
	/**
	 * Set to enable or disable the particle emitter
	 *
	 * <p>When a particle is
	 * disabled, it will be "frozen in time" and not update.
	 *
	 * @param enabled True to enable the particle emitter
	 */
	public var enabled(get, set):Bool;
	
	/**
	 * Set the {ParticleInfluencer} to influence this particle emitter.
	 *
	 * @param particleInfluencer the {ParticleInfluencer} to influence
	 * this particle emitter.
	 *
	 * @see ParticleInfluencer
	 */
	public var particleInfluencer(get, set):IParticleInfluencer;
	/**
	 * Returns true if particles should spawn in world space.
	 *
	 * @return true if particles should spawn in world space.
	 *
	 * @see ParticleEmitter#setInWorldSpace(Bool)
	 */
	public var inWorldSpace(get, set):Bool;
	
	/**
	 * Set to true if every particle spawned
	 * should have a random facing angle.
	 *
	 * @param randomAngle if every particle spawned
	 * should have a random facing angle.
	 */
	public var randomAngle(get, set):Bool;
	
	/**
	 * Set to true if every particle spawned
	 * should get a random image from a pool of images constructed from
	 * the texture, with X by Y possible images.
	 *
	 * <p>By default, X and Y are equal
	 * to 1, thus allowing only 1 possible image to be selected, but if the
	 * particle is configured with multiple images by using {ParticleEmitter#setImagesX(int) }
	 * and {#link ParticleEmitter#setImagesY(int) } methods, then multiple images
	 * can be selected. Setting to false will cause each particle to have an animation
	 * of images displayed, starting at image 1, and going until image X*Y when
	 * the particle reaches its end of life.
	 *
	 * @param selectRandomImage True if every particle spawned should get a random
	 * image.
	 */
	public var randomImage(get, set):Bool;

	private var _enabled:Bool;

	private var _control:ParticleEmitterControl;
	private var _shape:EmitterShape;
	private var _particleMesh:ParticleCPUMesh;
	private var _particleInfluencer:IParticleInfluencer;

	private var _particles:Vector<Particle>;
	private var _firstUnUsed:Int;
	private var _lastUsed:Int;

	private var _randomAngle:Bool;
	private var _randomImage:Bool;
	private var _facingVelocity:Bool;
	private var _particlesPerSec:Int;
	private var _timeDifference:Float;

	private var _lowLife:Float;
	private var _highLife:Float;

	private var _gravity:Vector3f;
	private var _rotateSpeed:Float;
	private var _faceNormal:Vector3f;
	private var _imagesX:Int;
	private var _imagesY:Int;

	private var _startColor:Color;
	private var _endColor:Color;

	private var _startAlpha:Float;
	private var _endAlpha:Float;

	private var _startSize:Float;
	private var _endSize:Float;

	private var _worldSpace:Bool;

	//variable that helps with computations
	private var temp:Vector3f;
	private var lastPos:Vector3f;

	public function new(name:String, numParticles:Int)
	{
		super(name);

		init();

		setNumParticles(numParticles);
	}

	private function init():Void
	{
		_enabled = true;

		_shape = new EmitterPointShape();
		_particleInfluencer = new DefaultParticleInfluencer();

		_particlesPerSec = 20;
		_timeDifference = 0;
		_lowLife = 3;
		_highLife = 7;
		_gravity = new Vector3f(0.0, 0.1, 0.0);
		_rotateSpeed = 0;

		_faceNormal = new Vector3f(Math.NaN, Math.NaN, Math.NaN);
		_imagesX = 1;
		_imagesY = 1;

		_startColor = new Color(0.4, 0.4, 0.4);
		_endColor = new Color(0.1, 0.1, 0.1);

		_startAlpha = 0.5;
		_endAlpha = 0.0;

		_startSize = 0.2;
		_endSize = 2;
		_worldSpace = true;

		temp = new Vector3f();

		// ignore world transform, unless user sets inLocalSpace
		setIgnoreTransform(true);

		// particles neither receive nor cast shadows
		localShadowMode = ShadowMode.Off;

		// particles are usually transparent
		localQueueBucket = QueueBucket.Transparent;

		_control = new ParticleEmitterControl(this);
		addControl(_control);

		_particleMesh = new ParticleCPUMesh();
		setMesh(_particleMesh);
	}

	public function setShape(shape:EmitterShape):Void
	{
		_shape = shape;
	}

	public function getShape():EmitterShape
	{
		return _shape;
	}

	
	private inline function get_particleInfluencer():IParticleInfluencer
	{
		return _particleInfluencer;
	}
	private function set_particleInfluencer(influencer:IParticleInfluencer):IParticleInfluencer
	{
		return _particleInfluencer = influencer;
	}

	

	
	private inline function get_inWorldSpace():Bool
	{
		return _worldSpace;
	}
	private function set_inWorldSpace(worldSpace:Bool):Bool
	{
		setIgnoreTransform(worldSpace);
		return _worldSpace = worldSpace;
	}

	/**
	 * Returns the number of visible particles (spawned but not dead).
	 *
	 * @return the number of visible particles
	 */
	public function getNumVisibleParticles():Int
	{
//        return unusedIndices.size() + next;
		return _lastUsed + 1;
	}

	/**
	 * Set the maximum amount of particles that
	 * can exist at the same time with this emitter.
	 * Calling this method many times is not recommended.
	 *
	 * @param numParticles the maximum amount of particles that
	 * can exist at the same time with this emitter.
	 */
	public function setNumParticles(numParticles:Int):Void
	{
		_particles = new Vector<Particle>(numParticles);
		for (i in 0...numParticles)
		{
			_particles[i] = new Particle();
		}

		//We have to reinit the mesh's buffers with the new size
		_particleMesh.initParticleData(this, numParticles);
		_particleMesh.setImagesXY(_imagesX, _imagesY);
		_firstUnUsed = 0;
		_lastUsed = -1;
	}

	public function getNumParticles():Int
	{
		return _particles.length;
	}

	/**
	 * Returns a list of all particles (shouldn't be used in most cases).
	 *
	 * <p>
	 * This includes both existing and non-existing particles.
	 * The size of the array is set to the `numParticles` value
	 * specified in the constructor or {ParticleEmitter#setNumParticles(int) }
	 * method.
	 *
	 * @return a list of all particles.
	 */
	public function getParticles():Vector<Particle>
	{
		return _particles;
	}

	/**
	 * Get the normal which particles are facing.
	 *
	 * @return the normal which particles are facing.
	 *
	 * @see ParticleEmitter#setFaceNormal(org.angle3d.math.Vector3f)
	 */
	public function getFaceNormal():Vector3f
	{
		if (_faceNormal.isValid())
		{
			return _faceNormal;
		}
		else
		{
			return null;
		}
	}

	/**
	 * Sets the normal which particles are facing.
	 *
	 * <p>By default, particles
	 * will face the camera, but for some effects (e.g shockwave) it may
	 * be necessary to face a specific direction instead. To restore
	 * normal functionality, provide `null` as the argument for
	 * `faceNormal`.
	 *
	 * @param faceNormal The normals particles should face, or `null`
	 * if particles should face the camera.
	 */
	public function setFaceNormal(faceNormal:Vector3f):Void
	{
		if (faceNormal == null || !faceNormal.isValid())
		{
			this._faceNormal.setTo(Math.NaN, Math.NaN, Math.NaN);
		}
		else
		{
			this._faceNormal = faceNormal;
		}
	}

	/**
	 * Returns the rotation speed in radians/sec for particles.
	 *
	 * @return the rotation speed in radians/sec for particles.
	 *
	 * @see ParticleEmitter#setRotateSpeed(float)
	 */
	public function getRotateSpeed():Float
	{
		return _rotateSpeed;
	}

	/**
	 * Set the rotation speed in radians/sec for particles
	 * spawned after the invocation of this method.
	 *
	 * @param rotateSpeed the rotation speed in radians/sec for particles
	 * spawned after the invocation of this method.
	 */
	public function setRotateSpeed(rotateSpeed:Float):Void
	{
		this._rotateSpeed = rotateSpeed;
	}

	
	private inline function get_randomAngle():Bool
	{
		return _randomAngle;
	}
	
	private function set_randomAngle(randomAngle:Bool):Bool
	{
		return this._randomAngle = randomAngle;
	}

	
	private function get_randomImage():Bool
	{
		return _randomImage;
	}
	public function set_randomImage(randomImage:Bool):Bool
	{
		_randomImage = randomImage;
		return _randomImage;
	}

	/**
	 * Check if particles spawned should face their velocity.
	 *
	 * @return True if particles spawned should face their velocity.
	 *
	 * @see ParticleEmitter#setFacingVelocity(Bool)
	 */
	public function isFacingVelocity():Bool
	{
		return _facingVelocity;
	}

	/**
	 * Set to true if particles spawned should face
	 * their velocity (or direction to which they are moving towards).
	 *
	 * <p>This is typically used for e.g spark effects.
	 *
	 * @param followVelocity True if particles spawned should face their velocity.
	 *
	 */
	public function setFacingVelocity(followVelocity:Bool):Void
	{
		this._facingVelocity = followVelocity;
	}

	/**
	 * Get the end color of the particles spawned.
	 *
	 * @return the end color of the particles spawned.
	 *
	 * @see ParticleEmitter#setEndColor(org.angle3d.math.ColorRGBA)
	 */
	public function getEndColor():Color
	{
		return _endColor;
	}

	/**
	 * Set the end color of the particles spawned.
	 *
	 * <p>The
	 * particle color at any time is determined by blending the start color
	 * and end color based on the particle's current time of life relative
	 * to its end of life.
	 *
	 * @param endColor the end color of the particles spawned.
	 */
	public function setEndColor(endColor:Color):Void
	{
		this._endColor.copyFrom(endColor);
	}

	/**
	 * Get the end size of the particles spawned.
	 *
	 * @return the end size of the particles spawned.
	 *
	 * @see ParticleEmitter#setEndSize(float)
	 */
	public function getEndSize():Float
	{
		return _endSize;
	}

	/**
	 * Set the end size of the particles spawned.
	 *
	 * <p>The
	 * particle size at any time is determined by blending the start size
	 * and end size based on the particle's current time of life relative
	 * to its end of life.
	 *
	 * @param endSize the end size of the particles spawned.
	 */
	public function setEndSize(endSize:Float):Void
	{
		this._endSize = endSize;
	}

	/**
	 * Get the gravity vector.
	 *
	 * @return the gravity vector.
	 *
	 * @see ParticleEmitter#setGravity(org.angle3d.math.Vector3f)
	 */
	public function getGravity():Vector3f
	{
		return _gravity;
	}

	/**
	 * This method sets the gravity vector.
	 *
	 * @param gravity the gravity vector
	 */
	public function setGravity(gravity:Vector3f):Void
	{
		this._gravity.copyFrom(gravity);
	}

	/**
	 * Get the high value of life.
	 *
	 * @return the high value of life.
	 *
	 * @see ParticleEmitter#setHighLife(float)
	 */
	public function getHighLife():Float
	{
		return _highLife;
	}

	/**
	 * Set the high value of life.
	 *
	 * <p>The particle's lifetime/expiration
	 * is determined by randomly selecting a time between low life and high life.
	 *
	 * @param highLife the high value of life.
	 */
	public function setHighLife(highLife:Float):Void
	{
		this._highLife = highLife;
	}

	/**
	 * Get the number of images along the X axis (width).
	 *
	 * @return the number of images along the X axis (width).
	 *
	 * @see ParticleEmitter#setImagesX(int)
	 */
	public function getImagesX():Int
	{
		return _imagesX;
	}

	/**
	 * Set the number of images along the X axis (width).
	 *
	 * <p>To determine
	 * how multiple particle images are selected and used, see the
	 * {ParticleEmitter#setSelectRandomImage(Bool) } method.
	 *
	 * @param imagesX the number of images along the X axis (width).
	 */
	public function setImagesX(imagesX:Int):Void
	{
		this._imagesX = imagesX;
		_particleMesh.setImagesXY(this._imagesX, this._imagesY);
	}

	/**
	 * Get the number of images along the Y axis (height).
	 *
	 * @return the number of images along the Y axis (height).
	 *
	 * @see ParticleEmitter#setImagesY(int)
	 */
	public function getImagesY():Int
	{
		return _imagesY;
	}

	/**
	 * Set the number of images along the Y axis (height).
	 *
	 * <p>To determine how multiple particle images are selected and used, see the
	 * {ParticleEmitter#setSelectRandomImage(Bool) } method.
	 *
	 * @param imagesY the number of images along the Y axis (height).
	 */
	public function setImagesY(imagesY:Int):Void
	{
		this._imagesY = imagesY;
		_particleMesh.setImagesXY(this._imagesX, this._imagesY);
	}

	/**
	 * Get the low value of life.
	 *
	 * @return the low value of life.
	 *
	 * @see ParticleEmitter#setLowLife(float)
	 */
	public function getLowLife():Float
	{
		return _lowLife;
	}

	/**
	 * Set the low value of life.
	 *
	 * <p>The particle's lifetime/expiration
	 * is determined by randomly selecting a time between low life and high life.
	 *
	 * @param lowLife the low value of life.
	 */
	public function setLowLife(lowLife:Float):Void
	{
		this._lowLife = lowLife;
	}

	/**
	 * Get the number of particles to spawn per
	 * second.
	 *
	 * @return the number of particles to spawn per
	 * second.
	 *
	 * @see ParticleEmitter#setParticlesPerSec(int)
	 */
	public function getParticlesPerSec():Int
	{
		return _particlesPerSec;
	}

	/**
	 * Set the number of particles to spawn per
	 * second.
	 *
	 * @param particlesPerSec the number of particles to spawn per
	 * second.
	 */
	public function setParticlesPerSec(particlesPerSec:Int):Void
	{
		this._particlesPerSec = particlesPerSec;
	}

	/**
	 * Get the start color of the particles spawned.
	 *
	 * @return the start color of the particles spawned.
	 *
	 * @see ParticleEmitter#setStartColor(org.angle3d.math.ColorRGBA)
	 */
	public function getStartColor():Color
	{
		return _startColor;
	}

	/**
	 * Set the start color of the particles spawned.
	 *
	 * <p>The particle color at any time is determined by blending the start color
	 * and end color based on the particle's current time of life relative
	 * to its end of life.
	 *
	 * @param startColor the start color of the particles spawned
	 */
	public function setStartColor(startColor:Color):Void
	{
		this._startColor.copyFrom(startColor);
	}

	public function getStartAlpha():Float
	{
		return _startAlpha;
	}

	public function setStartAlpha(alpha:Float):Void
	{
		_startAlpha = alpha;
	}

	public function getEndAlpha():Float
	{
		return _endAlpha;
	}

	public function setEndAlpha(alpha:Float):Void
	{
		_endAlpha = alpha;
	}

	/**
	 * Get the start color of the particles spawned.
	 *
	 * @return the start color of the particles spawned.
	 *
	 * @see ParticleEmitter#setStartSize(float)
	 */
	public function getStartSize():Float
	{
		return _startSize;
	}

	/**
	 * Set the start size of the particles spawned.
	 *
	 * <p>The particle size at any time is determined by blending the start size
	 * and end size based on the particle's current time of life relative
	 * to its end of life.
	 *
	 * @param startSize the start size of the particles spawned.
	 */
	public function setStartSize(startSize:Float):Void
	{
		this._startSize = startSize;
	}
	
	public function setInitialVelocity(initialVelocity:Vector3f):Void
	{
        this.particleInfluencer.setInitialVelocity(initialVelocity);
    }
	
	public function setVelocityVariation(variation:Float):Void
	{
		this.particleInfluencer.setVelocityVariation(variation);
	}

	/**
	 * Instantly emits all the particles possible to be emitted. Any particles
	 * which are currently inactive will be spawned immediately.
	 */
	public function emitAllParticles():Void
	{
		// Force world transform to update
		checkDoTransformUpdate();

		var vars:TempVars = TempVars.getTempVars();

		var bbox:BoundingBox = Std.instance(this.getMesh().getBound(),BoundingBox);

		var min:Vector3f = vars.vect1;
		var max:Vector3f = vars.vect2;

		bbox.getMin(min);
		bbox.getMax(max);

		if (!min.isValid())
		{
			min.setTo(FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY);
		}
		if (!max.isValid())
		{
			max.setTo(FastMath.NEGATIVE_INFINITY,FastMath.NEGATIVE_INFINITY,FastMath.NEGATIVE_INFINITY);
		}

		while (emitParticle(min, max) != null)
		{
		}

		bbox.setMinMax(min, max);
		this.setBoundRefresh();

		vars.release();
	}

	/**
	 * Instantly kills all active particles, after this method is called, all
	 * particles will be dead and no longer visible.
	 */
	public function killAllParticles():Void
	{
		var len:Int = _particles.length;
		for (i in 0...len)
		{
			if (_particles[i].life > 0)
			{
				this.freeParticle(i);
			}
		}
	}

	/**
	 * Kills the particle at the given index.
	 *
	 * @param index The index of the particle to kill
	 * @see #getParticles()
	 */
	public function killParticle(index:Int):Void
	{
		freeParticle(index);
	}

	
	private inline function get_enabled():Bool
	{
		return _enabled;
	}
	private function set_enabled(enabled:Bool):Bool
	{
		return this._enabled = enabled;
	}

	/**
	 * Check if a particle emitter is enabled for update.
	 *
	 * @return True if a particle emitter is enabled for update.
	 *
	 * @see ParticleEmitter#setEnabled(Bool)
	 */
	

	/**
	 * Callback from Control.update(), do not use.
	 * @param tpf
	 */
	public function updateFromControl(tpf:Float):Void
	{
		if (_enabled)
		{
			updateParticleState(tpf);
		}
	}

	/**
	 * Callback from Control.render(), do not use.
	 *
	 * @param rm
	 * @param vp
	 */
	private static var _inverseRotation:Matrix3f = new Matrix3f();

	public function renderFromControl(rm:RenderManager, vp:ViewPort):Void
	{
		_inverseRotation.makeIdentity();

		if (!_worldSpace)
		{
			getWorldRotation().toMatrix3f(_inverseRotation);
			_inverseRotation.invertLocal();
		}

		_particleMesh.updateParticleData(_particles, vp.camera, _inverseRotation);
	}

	/**
	 * 初次发射粒子，对粒子位置速度等进行初始化
	 */
	private function emitParticle(min:Vector3f, max:Vector3f):Particle
	{
		var idx:Int = _lastUsed + 1;
		if (idx >= _particles.length)
		{
			return null;
		}

		var p:Particle = _particles[idx];

		if (_randomImage)
		{
			p.frame = Std.int(Math.random() * _imagesY) * _imagesX + 
						Std.int(Math.random() * _imagesX);
		}

		p.totalLife = _lowLife + Math.random() * (_highLife - _lowLife);
		p.life = p.totalLife;
		p.color = _startColor.getColor();
		p.size = _startSize;

		_particleInfluencer.influenceParticle(p, _shape);

		if (_worldSpace)
		{
			mWorldTransform.transformVector(p.position, p.position);
			mWorldTransform.rotation.multVector(p.velocity, p.velocity);
				// TODO: Make scale relevant somehow??
		}

		if (_randomAngle)
		{
			p.angle = Math.random() * FastMath.TWO_PI;
		}

		if (_rotateSpeed != 0)
		{
			p.spin = _rotateSpeed * (0.2 + (Math.random() * 2 - 1) * .8);
		}

		// Computing bounding volume
		temp.x = p.position.x + p.size;
		temp.y = p.position.y + p.size;
		temp.z = p.position.z + p.size;
		max.maxLocal(temp);

		temp.x = p.position.x - p.size;
		temp.y = p.position.y - p.size;
		temp.z = p.position.z - p.size;
		min.minLocal(temp);

		++_lastUsed;
		_firstUnUsed = idx + 1;
		return p;
	}

	/**
	 * 释放粒子，此粒子生命周期已经结束
	 */
	private function freeParticle(idx:Int):Void
	{
		var p:Particle = _particles[idx];
		p.reset();

		if (idx == _lastUsed)
		{
			while (_lastUsed >= 0 && _particles[_lastUsed].life == 0)
			{
				_lastUsed--;
			}
		}

		if (idx < _firstUnUsed)
		{
			_firstUnUsed = idx;
		}
	}

	private function swap(idx1:Int, idx2:Int):Void
	{
		var p1:Particle = _particles[idx1];
		_particles[idx1] = _particles[idx2];
		_particles[idx2] = p1;
	}

	/**
	 * 每次循环都更新粒子信息
	 */
	private static var _tColor:Color = new Color();

	/**
	 *
	 * @param p
	 * @param tpf
	 * @param min
	 * @param max
	 *
	 */
	private function updateParticle(p:Particle, tpf:Float, min:Vector3f, max:Vector3f):Void
	{
		// applying gravity
		p.velocity.x -= _gravity.x * tpf;
		p.velocity.y -= _gravity.y * tpf;
		p.velocity.z -= _gravity.z * tpf;

		p.position.x += p.velocity.x * tpf;
		p.position.y += p.velocity.y * tpf;
		p.position.z += p.velocity.z * tpf;


		_tColor.setColor(p.color);

		// affecting color, size and angle
		var interp:Float = (p.totalLife - p.life) / p.totalLife;

		_tColor.lerp(_startColor, _endColor, interp);
		p.color = _tColor.getColor();
		p.alpha = FastMath.lerp(_startAlpha, _endAlpha, interp);
		p.size = FastMath.lerp(_startSize, _endSize, interp);
		p.angle += p.spin * tpf;

		if (!_randomImage)
		{
			p.frame = Std.int(interp * _imagesX * _imagesY);
		}

		// Computing bounding volume
		//var vec:Vector3f = new Vector3f(p.size, p.size, p.size);
		//temp.copyFrom(p.position).addLocal(vec);
		temp.x = p.position.x + p.size;
		temp.y = p.position.y + p.size;
		temp.z = p.position.z + p.size;
		max.maxLocal(temp);

		//temp.copyFrom(p.position).subtractLocal(vec);
		temp.x = p.position.x - p.size;
		temp.y = p.position.y - p.size;
		temp.z = p.position.z - p.size;
		min.minLocal(temp);
	}

	private static var _tMin:Vector3f = new Vector3f();
	private static var _tMax:Vector3f = new Vector3f();

	private function updateParticleState(tpf:Float):Void
	{
		// Force world transform to update
		checkDoTransformUpdate();

		_tMin.setTo(FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY,FastMath.POSITIVE_INFINITY);
		_tMax.setTo(FastMath.NEGATIVE_INFINITY,FastMath.NEGATIVE_INFINITY,FastMath.NEGATIVE_INFINITY);

		var p:Particle;
		var numPaticle:Int = _particles.length;
		for (i in 0...numPaticle)
		{
			p = _particles[i];

			// particle is dead
			if (p.life == 0)
			{
				continue;
			}

			p.life -= tpf;
			if (p.life <= 0)
			{
				this.freeParticle(i);
				continue;
			}

			updateParticle(p, tpf, _tMin, _tMax);

			if (_firstUnUsed < i)
			{
				this.swap(_firstUnUsed, i);
				if (i == _lastUsed)
				{
					_lastUsed = _firstUnUsed;
				}
				_firstUnUsed++;
			}
		}

		// Spawns particles within the tpf timeslot with proper age
		var interval:Float = 1.0 / _particlesPerSec;
		var originalTpf:Float = tpf;
		tpf += _timeDifference;
		while (tpf > interval)
		{
			tpf -= interval;
			p = emitParticle(_tMin, _tMax);
			if (p != null)
			{
				p.life -= tpf;
				if (lastPos != null && inWorldSpace)
				{
                    p.position.interpolateLocal(lastPos, 1 - tpf / originalTpf);
                }
				if (p.life <= 0)
				{
					freeParticle(_lastUsed);
				}
				else
				{
					updateParticle(p, tpf, _tMin, _tMax);
				}
			}
		}
		_timeDifference = tpf;
		
		if (lastPos == null)
		{
            lastPos = new Vector3f();
        }

        lastPos.copyFrom(getWorldTranslation());

		var bbox:BoundingBox = cast this.getMesh().getBound();
		bbox.setMinMax(_tMin, _tMax);
		this.setBoundRefresh();
	}
}

