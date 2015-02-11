package org.angle3d.material.technique;
import org.angle3d.material.Technique;

import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.animation.Skeleton;
import org.angle3d.light.LightType;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.Technique.TechniquePredefine;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.CubeTextureMap;
import org.angle3d.texture.TextureMapBase;
import org.angle3d.utils.FileUtil;

/**
 * Reflection mapping http://en.wikipedia.org/wiki/Reflection_mapping
 * http://developer.nvidia.com/book/export/html/86
 */
class TechniqueStandard extends Technique
{
	public var influence(get, set):Float;
	public var skinningMatrices(null, set):Vector<Float>;
	public var useTexCoord2(get, set):Bool;
	public var texture(get, set):TextureMapBase;
	public var lightmap(get, set):TextureMapBase;
	
	public var isReflect:Bool = false;
	public var isRefract:Bool = false;
	
	/**
	 * 反射率，一般应该设置在0~1之间
	 */
	public var reflectivity(get, set):Float;
	public var environmentMap(get, set):CubeTextureMap;
	
	/**
	 * 反射率，一般应该设置在0~1之间
	 */
	public var transmittance(get, set):Float;
	public var etaRatio(get, set):Float;
	
	private var _texture:TextureMapBase;

	private var _lightmap:TextureMapBase;

	private var _useTexCoord2:Bool = false;

	private var _influences:Vector<Float>;

	private var _skinningMatrices:Vector<Float>;
	
	private var _environmentMap:CubeTextureMap;
	private var _reflectivity:Float;
	
	private var _transmittance:Float;

	private var _etaRatios:Vector<Float>;

	public function new()
	{
		super();

		_etaRatios = new Vector<Float>(4);
	}
	
	
	private function get_influence():Float
	{
		return _influences[1];
	}
	private function set_influence(value:Float):Float
	{
		if (_influences == null)
			_influences = new Vector<Float>(4);
		_influences[0] = 1 - value;
		_influences[1] = value;
		return value;
	}

	
	private function set_skinningMatrices(data:Vector<Float>):Vector<Float>
	{
		return _skinningMatrices = data;
	}
	
	private function get_reflectivity():Float
	{
		return _reflectivity;
	}
	private function set_reflectivity(value:Float):Float
	{
		_reflectivity = value;
		if (_reflectivity < 0)
			_reflectivity = 0;
		return _reflectivity;
	}
	
	
	private function get_etaRatio():Float
	{
		return _etaRatios[0];
	}
	
	private function set_etaRatio(value:Float):Float
	{
//			if (value < 1.0)
//				value = 1.0;
		_etaRatios[0] = value;
		_etaRatios[1] = value * value;
		_etaRatios[2] = 1.0 - _etaRatios[1];
		return _etaRatios[0];
	}
	
	private function get_transmittance():Float
	{
		return _transmittance;
	}
	
	private function set_transmittance(value:Float):Float
	{
		_transmittance = value;
		if (_transmittance < 0)
			_transmittance = 0;
		return _transmittance;
	}

	private function get_environmentMap():CubeTextureMap
	{
		return _environmentMap;
	}

	private function set_environmentMap(value:CubeTextureMap):CubeTextureMap
	{
		return _environmentMap = value;
	}
	
	private function get_useTexCoord2():Bool
	{
		return _useTexCoord2;
	}
	private function set_useTexCoord2(value:Bool):Bool
	{
		return _useTexCoord2 = value;
	}

	
	private function get_texture():TextureMapBase
	{
		return _texture;
	}
	private function set_texture(value:TextureMapBase):TextureMapBase
	{
		return _texture = value;
	}

	
	private function get_lightmap():TextureMapBase
	{
		return _lightmap;
	}

	private function set_lightmap(value:TextureMapBase):TextureMapBase
	{
		return _lightmap = value;
	}

	/**
	 * 更新Uniform属性
	 * @param	shader
	 */
	override public function updateShader(shader:Shader):Void
	{
		shader.getTextureParam("s_texture").textureMap = _texture;

		if (_lightmap != null)
		{
			shader.getTextureParam("s_lightmap").textureMap = _lightmap;
		}
		
		if (_environmentMap != null)
		{
			if (isReflect)
			{
				shader.getUniform(ShaderType.FRAGMENT, "u_reflectivity").setFloat(_reflectivity);
				shader.getTextureParam("u_environmentMap").textureMap = _environmentMap;
			}
			else if (isRefract)
			{
				shader.getUniform(ShaderType.VERTEX, "u_etaRatio").setVector(_etaRatios);
				shader.getUniform(ShaderType.FRAGMENT, "u_transmittance").setFloat(_transmittance);
				shader.getTextureParam("u_environmentMap").textureMap = _environmentMap;
			}
		}

		var uniform:Uniform = shader.getUniform(ShaderType.VERTEX, "u_influences");
		if (uniform != null)
		{
			uniform.setVector(_influences);
		}

		uniform = shader.getUniform(ShaderType.VERTEX, "u_boneMatrixs");
		if (uniform != null)
		{
			uniform.setVector(_skinningMatrices);
		}
	}
	
	override private function getVertexSource():String
	{
		var source:String = FileUtil.getFileContent("../assets/shader/standard.vs");
		//source = StringUtil.format(source, Skeleton.MAX_BONE_COUNT * 3);
		var size:Int = Skeleton.MAX_BONE_COUNT * 3;
		return StringTools.replace(source, "{0}", size + "");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("../assets/shader/standard.fs");
	}
	
	override private function getPredefine(lightType:LightType, meshType:MeshType):TechniquePredefine
	{
		var predefine = super.getPredefine(lightType, meshType);

		if (_lightmap != null)
		{
			predefine.vertex.push("lightmap");
			predefine.fragment.push("lightmap");
			if (_useTexCoord2)
			{
				predefine.vertex.push("useTexCoord2");
				predefine.fragment.push("useTexCoord2");
			}
		}
		
		if (_environmentMap != null)
		{
			if (isReflect)
			{
				predefine.vertex.push("REFLECTION");
				predefine.fragment.push("REFLECTION");
			}
			else if (isRefract)
			{
				predefine.vertex.push("REFRACTION");
				predefine.fragment.push("REFRACTION");
			}
		}

		return predefine;
	}
	
	//TODO 优化，key应该缓存，不需要每次都计算
	override private function getKey(lightType:LightType, meshType:MeshType):String
	{
		//_keys.length = 0;
		_keys = [];
		_keys.push(name);
		_keys.push(meshType.getName());

		if (_lightmap != null)
		{
			_keys.push("lightmap");
			if (_useTexCoord2)
			{
				_keys.push("useTexCoord2");
			}
		}
		
		if (_environmentMap != null)
		{
			if (isReflect)
			{
				_keys.push("REFLECTION");
			}
			else if (isRefract)
			{
				_keys.push("REFRACTION");
			}
		}
		
		return _keys.join("_");
	}
}