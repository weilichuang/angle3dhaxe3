package org.angle3d.material.technique;
import flash.utils.ByteArray;
import flash.Vector;
import org.angle3d.light.LightType;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.shader.Uniform;
import org.angle3d.math.Color;
import org.angle3d.scene.mesh.MeshType;
import org.angle3d.texture.TextureMapBase;
import org.angle3d.utils.FileUtil;
import org.angle3d.material.shader.Shader;

class TechniquePointLight extends Technique
{
	public var texture(get, set):TextureMapBase;
	public var diffuseColor(get, set):Vector<Float>;
	public var specularColor(get, set):Vector<Float>;
	
	private var _diffuseColor:Vector<Float>;
	private var _specularColor:Vector<Float>;
	
	private var _texture:TextureMapBase;
	
	private var _influences:Vector<Float>;

	public function new() 
	{
		super();
		
		this.requiresLight = true;
		
		_diffuseColor = new Vector<Float>();
		_specularColor = new Vector<Float>();
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
	
	private function get_diffuseColor():Vector<Float>
	{
		return _diffuseColor;
	}

	private function set_diffuseColor(value:Vector<Float>):Vector<Float>
	{
		_diffuseColor = value;
		return _diffuseColor;
	}
	
	private function get_specularColor():Vector<Float>
	{
		return _specularColor;
	}

	private function set_specularColor(value:Vector<Float>):Vector<Float>
	{
		_specularColor = value;
		return _specularColor;
	}
	
	private function get_texture():TextureMapBase
	{
		return _texture;
	}
	private function set_texture(value:TextureMapBase):TextureMapBase
	{
		return _texture = value;
	}
	
	override public function updateShader(shader:Shader):Void
	{
		shader.getUniform(ShaderType.VERTEX, "u_Diffuse").setVector(_diffuseColor);
		shader.getUniform(ShaderType.VERTEX, "u_Specular").setVector(_specularColor);
		
		shader.getTextureParam("s_texture").textureMap = _texture;

		var uniform:Uniform = shader.getUniform(ShaderType.VERTEX, "u_influences");
		if (uniform != null)
		{
			uniform.setVector(_influences);
		}
	}

	override private function getVertexSource():String
	{
		return FileUtil.getFileContent("shader/PhongPointLighting.vs");
	}

	override private function getFragmentSource():String
	{
		return FileUtil.getFileContent("shader/PhongPointLighting.fs");
	}
	
	override private function getKey(lightType:LightType, meshType:MeshType):String
	{
		var result:Array<String> = [name, meshType.getName()];
		return result.join("_");
	}
}