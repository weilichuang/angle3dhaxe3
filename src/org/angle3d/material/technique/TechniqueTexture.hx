package org.angle3d.material.technique;

import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.animation.Skeleton;
import org.angle3d.light.LightType;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.TextureMapBase;

/**
 * andy
 * @author andy
 */

class TechniqueTexture extends Technique
{
	public var influence(get, set):Float;
	public var skinningMatrices(null, set):Vector<Float>;
	public var useTexCoord2(get, set):Bool;
	public var texture(get, set):TextureMapBase;
	public var lightmap(get, set):TextureMapBase;
	
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
		var vb:ByteArray = new TextureVS();
		var source:String = vb.readUTFBytes(vb.length);
		//source = StringUtil.format(source, Skeleton.MAX_BONE_COUNT * 3);
		var size:Int = Skeleton.MAX_BONE_COUNT * 3;
		return StringTools.replace(source, "{0}", size + "");
	}

	override private function getFragmentSource():String
	{
		var fb:ByteArray = new TextureFS();
		return fb.readUTFBytes(fb.length);
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
}

@:file("org/angle3d/material/technique/data/texture.vs") 
class TextureVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/texture.fs") 
class TextureFS extends flash.utils.ByteArray{}
