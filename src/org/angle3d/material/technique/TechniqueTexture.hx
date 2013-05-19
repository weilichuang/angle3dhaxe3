package org.angle3d.material.technique;

import flash.utils.ByteArray;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.animation.Skeleton;
import org.angle3d.light.LightType;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.shader.UniformBinding;
import org.angle3d.material.shader.UniformBindingHelp;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.TextureMapBase;

/**
 * andy
 * @author andy
 */

class TechniqueTexture extends Technique
{
	private var _texture:TextureMapBase;

	private var _lightmap:TextureMapBase;

	private var _useTexCoord2:Bool;

	private var _influences:Vector<Float>;

	private var _skinningMatrices:Vector<Float>;

	public function new()
	{
		super();

		_useTexCoord2 = false;
		_texture = null;
		_lightmap = null;
	}
	
	public var influence(get, set):Float;
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

	public var skinningMatrices(null, set):Vector<Float>;
	private function set_skinningMatrices(data:Vector<Float>):Vector<Float>
	{
		return _skinningMatrices = data;
	}

	
	public var useTexCoord2(get, set):Bool;
	private function get_useTexCoord2():Bool
	{
		return _useTexCoord2;
	}
	private function set_useTexCoord2(value:Bool):Bool
	{
		return _useTexCoord2 = value;
	}

	public var texture(get, set):TextureMapBase;
	private function get_texture():TextureMapBase
	{
		return _texture;
	}
	private function set_texture(value:TextureMapBase):TextureMapBase
	{
		return _texture = value;
	}

	public var lightmap(get, set):TextureMapBase;
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
		shader.getTextureVar("s_texture").textureMap = _texture;

		if (_lightmap != null)
		{
			shader.getTextureVar("s_lightmap").textureMap = _lightmap;
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
	
	
	override private function initSouce():Void
	{
		var vb:ByteArray = new TextureVS();
		var source:String = ba.readUTFBytes(vb.length);
		//source = StringUtil.format(source, Skeleton.MAX_BONE_COUNT * 3);
		var size:Int = Skeleton.MAX_BONE_COUNT * 3;
		mVertexSource = StringTools.replace(source, "{0}", size + "");

		var fb:ByteArray = new TextureFS();
		mFragmentSource = fb.readUTFBytes(fb.length);
	}

	override private function getOption(lightType:LightType, meshType:MeshType):Array<Array<String>>
	{
		var results:Array<Array<String>> = super.getOption(lightType, meshType);

		if (_lightmap != null)
		{
			results[0].push("lightmap");
			results[1].push("lightmap");
			if (_useTexCoord2)
			{
				results[0].push("useTexCoord2");
				results[1].push("useTexCoord2");
			}
		}
		return results;
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
		return _keys.join("_");
	}

	override private function getBindAttributes(lightType:LightType, meshType:MeshType):StringMap<String>
	{
		var map:StringMap<String> = new StringMap<String>();
		map.set(BufferType.POSITION, "a_position");
		map.set(BufferType.TEXCOORD,"a_texCoord");

		if (_lightmap != null && _useTexCoord2)
		{
			map.set(BufferType.TEXCOORD2,"a_texCoord2");
		}

		if (meshType == MeshType.KEYFRAME)
		{
			map.set(BufferType.POSITION1,"a_position1");
		}
		else if (meshType == MeshType.SKINNING)
		{
			map.set(BufferType.BONE_INDICES,"a_boneIndices");
			map.set(BufferType.BONE_WEIGHTS,"a_boneWeights");
		}

		return map;
	}

	override private function getBindUniforms(lightType:LightType, meshType:MeshType):Array<UniformBindingHelp>
	{
		var list:Array<UniformBindingHelp> = new Array<UniformBindingHelp>();
		list.push(new UniformBindingHelp(ShaderType.VERTEX, "u_WorldViewProjectionMatrix", UniformBinding.WorldViewProjectionMatrix));
		
		return list;
	}
}

@:file("org/angle3d/material/technique/data/texture.vs") 
class TextureVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/texture.fs") 
class TextureFS extends flash.utils.ByteArray{}
