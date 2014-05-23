package org.angle3d.material.technique;

import flash.Vector;
import org.angle3d.light.LightType;
import org.angle3d.material.BlendMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.math.Color;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.TextureMapBase;
import org.angle3d.utils.FileUtil;

/**
 * andy
 * @author andy
 */
class TechniqueGPUParticle extends Technique
{
	public var useLocalColor(get, set):Bool;
	public var useLocalAcceleration(get, set):Bool;
	public var loop(get, set):Bool;
	public var curTime(get, set):Float;
	public var texture(get, set):TextureMapBase;
	
	private var _texture:TextureMapBase;

	private var _offsetVector:Vector<Float>;

	private var _beginColor:Color;
	private var _endColor:Color;
	private var _incrementColor:Color;
	private var _useColor:Bool;

	private var _curTime:Vector3f;
	private var _size:Vector3f;

	private var _loop:Bool;

	private var _useAcceleration:Bool;
	private var _acceleration:Vector3f;

	/**
	 * 是否自转
	 */
	private var _useSpin:Bool;


	private var _useSpriteSheet:Bool;
	private var _useAnimation:Bool;
	private var _spriteSheetData:Vector<Float>;

	private var _useLocalAcceleration:Bool;
	private var _useLocalColor:Bool;

	private static inline var USE_ACCELERATION:String = "USE_ACCELERATION";
	private static inline var USE_LOCAL_ACCELERATION:String = "USE_LOCAL_ACCELERATION";

	private static inline var USE_SPRITESHEET:String = "USE_SPRITESHEET";
	private static inline var USE_ANIMATION:String = "USE_ANIMATION";

	private static inline var USE_COLOR:String = "USE_COLOR";

	private static inline var USE_LOCAL_COLOR:String = "USE_LOCAL_COLOR";

	private static inline var USE_SPIN:String = "USE_SPIN";

	private static inline var NOT_LOOP:String = "NOT_LOOP";

	public function new()
	{
		super();
		
		_beginColor = new Color(1, 1, 1, 0);
		_endColor = new Color(0, 0, 0, 0);
		_incrementColor = new Color(0, 0, 0, 1);
		_useColor = false;

		_curTime = new Vector3f(0, 0, 0);
		_size = new Vector3f(1, 1, 0);

		_loop = true;

		_useAcceleration = false;
		_useSpin = false;
		_useSpriteSheet = false;
		_useAnimation = false;
		_spriteSheetData = new Vector<Float>(4);

		_useLocalAcceleration = false;
		_useLocalColor = false;
		
		renderState.setDepthTest(true);
		renderState.setDepthWrite(false);
		renderState.setBlendMode(BlendMode.Color);

		_offsetVector = new Vector<Float>(16,true);
		_offsetVector[0] = -0.5;
		_offsetVector[1] = -0.5;
		_offsetVector[2] = 0;
		_offsetVector[3] = 1;

		_offsetVector[4] = 0.5;
		_offsetVector[5] = -0.5;
		_offsetVector[6] = 0;
		_offsetVector[7] = 1;

		_offsetVector[8] = -0.5;
		_offsetVector[9] = 0.5;
		_offsetVector[10] = 0;
		_offsetVector[11] = 1;

		_offsetVector[12] = 0.5;
		_offsetVector[13] = 0.5;
		_offsetVector[14] = 0;
		_offsetVector[15] = 1;
	}

	
	private function get_useLocalColor():Bool
	{
		return _useLocalColor;
	}
	private function set_useLocalColor(value:Bool):Bool
	{
		return _useLocalColor = value;
	}

	
	private function get_useLocalAcceleration():Bool
	{
		return _useLocalAcceleration;
	}
	private function set_useLocalAcceleration(value:Bool):Bool
	{
		return _useLocalAcceleration = value;
	}

	public function getUseSpin():Bool
	{
		return _useSpin;
	}
	
	public function setUseSpin(value:Bool):Void
	{
		_useSpin = value;
	}

	
	private function set_loop(value:Bool):Bool
	{
		return _loop = value;
	}

	private function get_loop():Bool
	{
		return _loop;
	}

	/**
	 *
	 * @param animDuration 秒
	 * @param col 列
	 * @param row 行
	 *
	 */
	public function setSpriteSheet(animDuration:Float, col:Int, row:Int):Void
	{
		//每个图像持续时间
		_spriteSheetData[0] = animDuration;

		_useAnimation = animDuration > 0;

		//列数
		_spriteSheetData[1] = col;
		//行数
		_spriteSheetData[2] = row;
		//总数
		_spriteSheetData[3] = col * row;

		_useSpriteSheet = col > 1 || row > 1;
	}

	
	private function get_curTime():Float
	{
		return _curTime.x;
	}
	private function set_curTime(value:Float):Float
	{
		_curTime.x = value;
		return _curTime.x;
	}

	public function setColor(start:UInt, end:UInt):Void
	{
		_beginColor.setRGB(start);
		_endColor.setRGB(end);

		_incrementColor.r = _endColor.r - _beginColor.r;
		_incrementColor.g = _endColor.g - _beginColor.g;
		_incrementColor.b = _endColor.b - _beginColor.b;

		_useColor = true;
	}

	public function setAlpha(start:Float, end:Float):Void
	{
		_beginColor.a = start;
		_endColor.a = end;
		_incrementColor.a = _endColor.a - _beginColor.a;

		_useColor = true;
	}

	public function setSize(start:Float, end:Float):Void
	{
		_size.x = start;
		_size.y = end;
		_size.z = end - start;
	}

	public function setAcceleration(acceleration:Vector3f):Void
	{
		_acceleration = acceleration;
		_useAcceleration = _acceleration != null && !_acceleration.isZero();
	}

	
	private function get_texture():TextureMapBase
	{
		return _texture;
	}

	private function set_texture(value:TextureMapBase):TextureMapBase
	{
		_texture = value;
		return _texture;
	}

	/**
	 * 更新Uniform属性
	 * @param	shader
	 */
	override public function updateShader(shader:Shader):Void
	{
		shader.getTextureParam("s_texture").textureMap = _texture;

		//顶点偏移
		shader.getUniform(ShaderType.VERTEX, "u_vertexOffset").setVector(_offsetVector);

		if (_useColor)
		{
			shader.getUniform(ShaderType.VERTEX, "u_beginColor").setColor(_beginColor);
			shader.getUniform(ShaderType.VERTEX, "u_incrementColor").setColor(_incrementColor);
		}

		shader.getUniform(ShaderType.VERTEX, "u_curTime").setVector3(_curTime);
		shader.getUniform(ShaderType.VERTEX, "u_size").setVector3(_size);

		if (_useAcceleration)
		{
			shader.getUniform(ShaderType.VERTEX, "u_acceleration").setVector3(_acceleration);
		}

		if (_useSpriteSheet)
		{
			shader.getUniform(ShaderType.VERTEX, "u_spriteSheet").setVector(_spriteSheetData);
		}
	}
	
	/**
	 * u_size ---> x=beginSize,y=endSize,z= endSize - beginSize
	 */
	override private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/gpuparticle.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/gpuparticle.fs");
	}

	override private function getOption(lightType:LightType, meshType:MeshType):Array<Array<String>>
	{
		var results:Array<Array<String>> = super.getOption(lightType, meshType);
		if (_useAcceleration)
		{
			results[0].push(USE_ACCELERATION);
		}

		if (_useLocalAcceleration)
		{
			results[0].push(USE_LOCAL_ACCELERATION);
		}

		if (!_loop)
		{
			results[0].push(NOT_LOOP);
		}

		if (_useSpriteSheet)
		{
			results[0].push(USE_SPRITESHEET);
			if (_useAnimation)
			{
				results[0].push(USE_ANIMATION);
			}
		}

		if (_useSpin)
		{
			results[0].push(USE_SPIN);
		}

		if (_useColor)
		{
			results[0].push(USE_COLOR);
			results[1].push(USE_COLOR);
		}

		if (_useLocalColor)
		{
			results[0].push(USE_LOCAL_COLOR);
			results[1].push(USE_LOCAL_COLOR);
		}

		return results;
	}

	override private function getKey(lightType:LightType, meshType:MeshType):String
	{
		var result:Array<String> = [name, meshType.getName()];

		if (_useAcceleration)
		{
			result.push(USE_ACCELERATION);
		}

		if (_useLocalAcceleration)
		{
			result.push(USE_LOCAL_ACCELERATION);
		}

		if (!_loop)
		{
			result.push(NOT_LOOP);
		}

		if (_useSpriteSheet)
		{
			result.push(USE_SPRITESHEET);
			if (_useAnimation)
			{
				result.push(USE_ANIMATION);
			}
		}

		if (_useSpin)
		{
			result.push(USE_SPIN);
		}

		if (_useColor)
		{
			result.push(USE_COLOR);
		}

		if (_useLocalColor)
		{
			result.push(USE_LOCAL_COLOR);
		}

		return result.join("_");
	}
}