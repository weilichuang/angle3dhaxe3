package org.angle3d.effect.gpu;

import flash.Vector;
import org.angle3d.effect.gpu.influencers.acceleration.IAccelerationInfluencer;
import org.angle3d.effect.gpu.influencers.alpha.IAlphaInfluencer;
import org.angle3d.effect.gpu.influencers.angle.DefaultAngleInfluencer;
import org.angle3d.effect.gpu.influencers.angle.IAngleInfluencer;
import org.angle3d.effect.gpu.influencers.birth.DefaultBirthInfluencer;
import org.angle3d.effect.gpu.influencers.birth.IBirthInfluencer;
import org.angle3d.effect.gpu.influencers.color.IColorInfluencer;
import org.angle3d.effect.gpu.influencers.life.DefaultLifeInfluencer;
import org.angle3d.effect.gpu.influencers.life.ILifeInfluencer;
import org.angle3d.effect.gpu.influencers.position.DefaultPositionInfluencer;
import org.angle3d.effect.gpu.influencers.position.IPositionInfluencer;
import org.angle3d.effect.gpu.influencers.scale.DefaultScaleInfluencer;
import org.angle3d.effect.gpu.influencers.scale.IScaleInfluencer;
import org.angle3d.effect.gpu.influencers.spin.DefaultSpinInfluencer;
import org.angle3d.effect.gpu.influencers.spin.ISpinInfluencer;
import org.angle3d.effect.gpu.influencers.spritesheet.DefaultSpriteSheetInfluencer;
import org.angle3d.effect.gpu.influencers.spritesheet.ISpriteSheetInfluencer;
import org.angle3d.effect.gpu.influencers.velocity.EmptyVelocityInfluencer;
import org.angle3d.effect.gpu.influencers.velocity.IVelocityInfluencer;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.SubMesh;
import org.angle3d.texture.TextureMapBase;
/**
 * 粒子生成器
 */
//TODO 是否需要添加一个每个粒子单独的加速度
class ParticleShapeGenerator
{
	private var _numParticles:Int;
	private var _totalLife:Float;
	private var _perSecondParticleCount:Int;

	private var _positionInfluencer:IPositionInfluencer;
	private var _velocityInfluencer:IVelocityInfluencer;
	private var _birthInfluencer:IBirthInfluencer;
	private var _lifeInfluencer:ILifeInfluencer;
	private var _scaleInfluencer:IScaleInfluencer;
	private var _spriteSheetInfluencer:ISpriteSheetInfluencer;
	private var _angleInfluencer:IAngleInfluencer;
	private var _spinInfluencer:ISpinInfluencer;
	private var _accelerationInfluencer:IAccelerationInfluencer;
	private var _colorInfluencer:IColorInfluencer;
	private var _alphaInfluencer:IAlphaInfluencer;

	/**
	 *
	 * @param numParticles 粒子数量
	 * @param totalLife 总生命时间
	 *
	 */
	public function new(numParticles:Int, totalLife:Float)
	{
		_numParticles = numParticles;
		_totalLife = totalLife;
		_perSecondParticleCount = Std.int(_numParticles / _totalLife);

		setPositionInfluencer(new DefaultPositionInfluencer());
		setVelocityInfluencer(new EmptyVelocityInfluencer());
		setBirthInfluencer(new DefaultBirthInfluencer());
		setLifeInfluencer(new DefaultLifeInfluencer(1, 1));
		setScaleInfluencer(new DefaultScaleInfluencer());
		setSpriteSheetInfluencer(new DefaultSpriteSheetInfluencer());
		setAngleInfluencer(new DefaultAngleInfluencer());
		setSpinInfluencer(new DefaultSpinInfluencer());
	}

	public var numParticles(get, null):Int;
	private inline function get_numParticles():Int
	{
		return _numParticles;
	}

	public var totalLife(get, null):Float;
	private inline function get_totalLife():Float
	{
		return _totalLife;
	}

	public var perSecondParticleCount(get, null):Int;
	private function get_perSecondParticleCount():Int
	{
		return _perSecondParticleCount;
	}

	public function setPositionInfluencer(influencer:IPositionInfluencer):Void
	{
		_positionInfluencer = influencer;
		_positionInfluencer.generator = this;
	}

	public function setVelocityInfluencer(influencer:IVelocityInfluencer):Void
	{
		_velocityInfluencer = influencer;
		_velocityInfluencer.generator = this;
	}

	public function setBirthInfluencer(influencer:IBirthInfluencer):Void
	{
		_birthInfluencer = influencer;
		_birthInfluencer.generator = this;
	}

	public function setLifeInfluencer(influencer:ILifeInfluencer):Void
	{
		_lifeInfluencer = influencer;
		_lifeInfluencer.generator = this;
	}

	public function setScaleInfluencer(influencer:IScaleInfluencer):Void
	{
		_scaleInfluencer = influencer;
		_scaleInfluencer.generator = this;
	}

	public function setSpriteSheetInfluencer(influencer:ISpriteSheetInfluencer):Void
	{
		_spriteSheetInfluencer = influencer;
		_spriteSheetInfluencer.generator = this;
	}

	public function setAngleInfluencer(influencer:IAngleInfluencer):Void
	{
		_angleInfluencer = influencer;
		_angleInfluencer.generator = this;
	}

	public function setSpinInfluencer(influencer:ISpinInfluencer):Void
	{
		_spinInfluencer = influencer;
		_spinInfluencer.generator = this;
	}

	public function setAccelerationInfluencer(influencer:IAccelerationInfluencer):Void
	{
		_accelerationInfluencer = influencer;
		_accelerationInfluencer.generator = this;
	}

	public function setColorInfluencer(influencer:IColorInfluencer):Void
	{
		_colorInfluencer = influencer;
		_colorInfluencer.generator = this;
	}

	public function setAlphaInfluencer(influencer:IAlphaInfluencer):Void
	{
		_alphaInfluencer = influencer;
		_alphaInfluencer.generator = this;
	}

	public function createParticleShape(name:String, texture:TextureMapBase):ParticleShape
	{
		var shape:ParticleShape = new ParticleShape(name, texture, _totalLife);
		shape.useLocalAcceleration = _accelerationInfluencer != null;
		shape.useLocalColor = _colorInfluencer != null || _alphaInfluencer != null;

		var mesh:Mesh = new Mesh();

		var subMesh:SubMesh = new SubMesh();

		var _vertices:Vector<Float> = new Vector<Float>(_numParticles * 16, true);
		var _indices:Vector<UInt> = new Vector<UInt>(_numParticles*6, true);
		var _texCoords:Vector<Float> = new Vector<Float>(_numParticles*16, true);

		var _velocities:Vector<Float> = new Vector<Float>(_numParticles*16, true);
		var _lifeScaleAngles:Vector<Float> = new Vector<Float>(_numParticles*16, true);

		var _accelerationList:Vector<Float> = null;
		var _acceleration:Vector3f = null;
		if (shape.useLocalAcceleration)
		{
			_accelerationList = new Vector<Float>(_numParticles*12, true);
			_acceleration = new Vector3f();
		}

		var _color:Color = null;
		var _colorList:Vector<Float> = null;
		if (shape.useLocalColor)
		{
			_colorList = new Vector<Float>(_numParticles*16, true);
			_color = new Color(0, 0, 0, 1);
		}

		var _pos:Vector3f = new Vector3f();
		var _velocity:Vector3f = new Vector3f();
		var totalFrame:Int = _spriteSheetInfluencer.getTotalFrame();

		for (i in 0..._numParticles)
		{
			var id4:Int = i * 4;
			var id6:Int = i * 6;
			var id16:Int = i * 16;
			var id12:Int = i * 12;

			// triangle 1
			_indices[id6 + 0] = id4 + 1;
			_indices[id6 + 1] = id4 + 0;
			_indices[id6 + 2] = id4 + 2;

			// triangle 2
			_indices[id6 + 3] = id4 + 1;
			_indices[id6 + 4] = id4 + 2;
			_indices[id6 + 5] = id4 + 3;

			var curFrame:Int = _spriteSheetInfluencer.getDefaultFrame();

			_texCoords[id16 + 0] = 0;
			_texCoords[id16 + 1] = 1;
			_texCoords[id16 + 2] = totalFrame;
			_texCoords[id16 + 3] = curFrame;

			_texCoords[id16 + 4] = 1;
			_texCoords[id16 + 5] = 1;
			_texCoords[id16 + 6] = totalFrame;
			_texCoords[id16 + 7] = curFrame;

			_texCoords[id16 + 8] = 0;
			_texCoords[id16 + 9] = 0;
			_texCoords[id16 + 10] = totalFrame;
			_texCoords[id16 + 11] = curFrame;

			_texCoords[id16 + 12] = 1;
			_texCoords[id16 + 13] = 0;
			_texCoords[id16 + 14] = totalFrame;
			_texCoords[id16 + 15] = curFrame;

			_positionInfluencer.getPosition(i, _pos);
			_velocityInfluencer.getVelocity(i, _velocity);

			if (shape.useLocalAcceleration)
			{
				_accelerationInfluencer.getAcceleration(_velocity, _acceleration);
			}

			//使用粒子颜色
			if (shape.useLocalColor)
			{
				if (_colorInfluencer != null)
				{
					_colorInfluencer.getColor(i, _color);
				}
				else
				{
					_color.setTo(0, 0, 0);
				}

				if (_alphaInfluencer != null)
				{
					_color.a = _alphaInfluencer.getAlpha(i);
				}
				else
				{
					_color.a = 1;
				}
			}

			var spin:Float = _spinInfluencer.getSpin(i);

			var birthTime:Float = _birthInfluencer.getBirth(i);
			var life:Float = _lifeInfluencer.getLife(i);
			var scale:Float = _scaleInfluencer.getDefaultScale(i);
			var angle:Float = _angleInfluencer.getDefaultAngle(i);

			var uniformIndex:Int = 0;
			for (j in 0...4)
			{
				var id16j4:Int = id16 + j * 4;
				var id12j3:Int = id12 + j * 3;

				_vertices[id16j4 + 0] = _pos.x;
				_vertices[id16j4 + 1] = _pos.y;
				_vertices[id16j4 + 2] = _pos.z;
				_vertices[id16j4 + 3] = uniformIndex++;

				//位移速度
				_velocities[id16j4 + 0] = _velocity.x;
				_velocities[id16j4 + 1] = _velocity.y;
				_velocities[id16j4 + 2] = _velocity.z;
				//旋转速度
				_velocities[id16j4 + 3] = spin;

				//出生时间
				_lifeScaleAngles[id16j4 + 0] = birthTime;
				//生命时间
				_lifeScaleAngles[id16j4 + 1] = life;
				//默认缩放
				_lifeScaleAngles[id16j4 + 2] = scale;
				//默认旋转角度
				_lifeScaleAngles[id16j4 + 3] = angle;

				if (shape.useLocalAcceleration)
				{
					_accelerationList[id12j3 + 0] = _acceleration.x;
					_accelerationList[id12j3 + 1] = _acceleration.y;
					_accelerationList[id12j3 + 2] = _acceleration.z;
				}

				if (shape.useLocalColor)
				{
					_colorList[id16j4 + 0] = _color.r;
					_colorList[id16j4 + 1] = _color.g;
					_colorList[id16j4 + 2] = _color.b;
					_colorList[id16j4 + 3] = _color.a;
				}
			}
		}

		subMesh.setVertexBuffer(BufferType.POSITION, 4, _vertices);
		subMesh.setVertexBuffer(BufferType.TEXCOORD, 4, _texCoords);
		subMesh.setVertexBuffer(BufferType.PARTICLE_VELOCITY, 4, _velocities);
		subMesh.setVertexBuffer(BufferType.PARTICLE_LIFE_SCALE_ANGLE, 4, _lifeScaleAngles);
		if (shape.useLocalAcceleration)
		{
			subMesh.setVertexBuffer(BufferType.PARTICLE_ACCELERATION, 3, _accelerationList);
		}
		if (shape.useLocalColor)
		{
			subMesh.setVertexBuffer(BufferType.COLOR, 4, _colorList);
		}
		subMesh.setIndices(_indices);

		mesh.addSubMesh(subMesh);

		shape.setMesh(mesh);

		return shape;
	}

}
