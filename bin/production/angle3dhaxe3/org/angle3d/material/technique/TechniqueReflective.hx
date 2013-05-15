package org.angle3d.material.technique;

import flash.utils.ByteArray;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.light.LightType;
import org.angle3d.material.CullMode;
import org.angle3d.material.shader.Shader;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.material.shader.UniformBinding;
import org.angle3d.material.shader.UniformBindingHelp;
import org.angle3d.material.TestFunction;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.CubeTextureMap;
import org.angle3d.texture.TextureMapBase;

/**
 * Reflection mapping
 * @author andy
 * @see http://developer.nvidia.com/book/export/html/86
 * @see http://en.wikipedia.org/wiki/Reflection_mapping
 */
class TechniqueReflective extends Technique
{
	private var _influences:Vector<Float>;

	private var _decalMap:TextureMapBase;

	private var _environmentMap:CubeTextureMap;

	private var _reflectivity:Float;

	public function new(decalMap:TextureMapBase, environmentMap:CubeTextureMap, reflectivity:Float = 0.5)
	{
		super();

		_renderState.applyCullMode = true;
		_renderState.cullMode = CullMode.FRONT;

		_renderState.applyDepthTest = true;
		_renderState.depthTest = true;
		_renderState.compareMode = TestFunction.LESS_EQUAL;

		_renderState.applyBlendMode = false;

		this.decalMap = decalMap;
		this.environmentMap = environmentMap;
		this.reflectivity = reflectivity;
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

	

	/**
	 * 反射率，一般应该设置在0~1之间
	 */
	public var reflectivity(get, set):Float;
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

	
	public var decalMap(get, set):TextureMapBase;
	private function get_decalMap():TextureMapBase
	{
		return _decalMap;
	}

	private function set_decalMap(value:TextureMapBase):TextureMapBase
	{
		return _decalMap = value;
	}

	public var environmentMap(get, set):CubeTextureMap;
	private function get_environmentMap():CubeTextureMap
	{
		return _environmentMap;
	}

	private function set_environmentMap(value:CubeTextureMap):CubeTextureMap
	{
		return _environmentMap = value;
	}

	override public function updateShader(shader:Shader):Void
	{
		shader.getUniform(ShaderType.FRAGMENT, "u_reflectivity").setFloat(_reflectivity);
		shader.getTextureVar("u_decalMap").textureMap = _decalMap;
		shader.getTextureVar("u_environmentMap").textureMap = _environmentMap;

		var uniform:Uniform = shader.getUniform(ShaderType.VERTEX, "u_influences");
		if (uniform != null)
		{
			uniform.setVector(_influences);
		}
	}

	override private function getVertexSource():String
	{
		var ba:ByteArray = new ReflectiveVS();
		return ba.readUTFBytes(ba.length);
	}

	override private function getFragmentSource():String
	{
		var ba:ByteArray = new ReflectiveFS();
		return ba.readUTFBytes(ba.length);
	}

	override private function getKey(lightType:LightType, meshType:MeshType):String
	{
		var result:Array<String> = [name, meshType.getName()];
		return result.join("_");
	}

	override private function getBindAttributes(lightType:LightType, meshType:MeshType):StringMap<String>
	{
		var map:StringMap<String> = new StringMap<String>();
		map.set(BufferType.POSITION, "a_position");
		map.set(BufferType.TEXCOORD, "a_texCoord");
		map.set(BufferType.NORMAL, "a_normal");
		if (meshType == MeshType.KEYFRAME)
		{
			map.set(BufferType.POSITION1, "a_position1");
			map.set(BufferType.NORMAL1, "a_normal1");
		}
		return map;
	}

	override private function getBindUniforms(lightType:LightType, meshType:MeshType):Array<UniformBindingHelp>
	{
		var list:Array<UniformBindingHelp> = new Array<UniformBindingHelp>();
		list.push(new UniformBindingHelp(ShaderType.VERTEX, "u_WorldViewProjectionMatrix", UniformBinding.WorldViewProjectionMatrix));
		list.push(new UniformBindingHelp(ShaderType.VERTEX, "u_worldMatrix", UniformBinding.WorldMatrix));
		list.push(new UniformBindingHelp(ShaderType.VERTEX, "u_camPosition", UniformBinding.CameraPosition));
		
		return list;
	}
}

@:file("org/angle3d/material/technique/data/reflective.vs") 
class ReflectiveVS extends flash.utils.ByteArray{}
@:file("org/angle3d/material/technique/data/reflective.fs") 
class ReflectiveFS extends flash.utils.ByteArray{}