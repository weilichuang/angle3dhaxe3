package org.angle3d.material.shader;

import flash.utils.ByteArray;
import haxe.ds.StringMap;
import flash.Vector;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.reg.AttributeReg;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.node.reg.UniformReg;
import org.angle3d.renderer.IRenderer;


/**
 * 一个Shader是一个Technique中的一个实现，Technique根据不同的条件生成不同的Shader
 */
//TODO 优化
class Shader
{
	private static var mShaderTypes:Array<ShaderType> = [ShaderType.VERTEX, ShaderType.FRAGMENT];
	
	public var name:String;
	
	public var vertexData:ByteArray;
	public var fragmentData:ByteArray;
	
	
	//vertex
	private var _vUniformList:UniformList;
	private var _attributeList:AttributeList;

	//fragment
	private var _fUniformList:UniformList;
	private var _textureList:ShaderParamList;

	

	public function new()
	{
		_attributeList = new AttributeList();
		_vUniformList = new UniformList();
		_fUniformList = new UniformList();
		_textureList = new ShaderParamList();
	}

	public function addVariable(shaderType:ShaderType, type:ShaderParamType, regNode:RegNode):Void
	{
		switch (type)
		{
			case ShaderParamType.ATTRIBUTE:
				var attriReg:AttributeReg = Std.instance(regNode, AttributeReg);
				_attributeList.addParam(new AttributeParam(attriReg.name, attriReg.size, attriReg.bufferType));
			case ShaderParamType.UNIFORM:
				var uniformReg:UniformReg = Std.instance(regNode, UniformReg);
				var bind:UniformBinding = null;
				if (uniformReg.uniformBind != "")
				{
					bind = Type.createEnum(UniformBinding, uniformReg.uniformBind);
				}
				getUniformList(shaderType).addParam(new Uniform(uniformReg.name, uniformReg.size, bind));
			case ShaderParamType.TEXTURE:
				_textureList.addParam(new TextureParam(regNode.name, regNode.size));
		}
	}

	/**
	 *
	 * @param	shaderType
	 * @param	digits
	 */
	public function setConstants(shaderType:ShaderType, digits:Vector<Float>):Void
	{
		var list:UniformList = getUniformList(shaderType);

		list.constants = digits;
	}

	public function getTextureParam(name:String):TextureParam
	{
		return Std.instance(_textureList.getParam(name), TextureParam);
	}

	//TODO 添加方法根据类型来获得AttributeParam
	public function getAttributeByName(name:String):AttributeParam
	{
		return Std.instance(_attributeList.getParam(name), AttributeParam);
	}
	
	public function getAttributeList():AttributeList
	{
		return _attributeList;
	}

	
	public function getTextureList():ShaderParamList
	{
		return _textureList;
	}

	
	public inline function getUniformList(shaderType:ShaderType):UniformList
	{
		return (shaderType == ShaderType.VERTEX) ? _vUniformList : _fUniformList;
	}

	public function uploadTexture(render:IRenderer):Void
	{
		//上传贴图
		var textures:Vector<ShaderParam> = _textureList.params;
		var size:Int = textures.length;
		for (i in 0...size)
		{
			var tex:TextureParam = Std.instance(textures[i], TextureParam);
			render.setTextureAt(tex.location, tex.textureMap);
		}
	}

	public function upload(render:IRenderer):Void
	{
		var type:ShaderType;
		var list:UniformList;
		var uniforms:Vector<ShaderParam>;
		var size:Int;
		var uniform:Uniform;
		for (i in 0...2)
		{
			type = mShaderTypes[i];

			//上传常量
			uploadConstants(render, type);

			//其他自定义数据
			list = getUniformList(type);
			uniforms = list.getUniforms();
			size = uniforms.length;
			for (j in 0...size)
			{
				uniform = list.getUniformAt(j);
				if(uniform.needUpdated)
				{
					render.setShaderConstants(type, uniform.location, uniform.data, uniform.size);
					uniform.needUpdated = false;
				}
			}
		}
	}

	/**
	 * 常量总最先传
	 * @param	type
	 */
	private function uploadConstants(render:IRenderer, shaderType:ShaderType):Void
	{
		var digits:Vector<Float> = getUniformList(shaderType).constants;

		if (digits.length == 0)
			return;
			
		render.setShaderConstants(shaderType, 0, digits);
	}

	public function setUniform(type:ShaderType, name:String, data:Vector<Float>):Void
	{
		var uniform:Uniform = getUniform(type, name);
		if (uniform != null)
		{
			uniform.setVector(data);
		}
	}

	public function getUniform(type:ShaderType, name:String):Uniform
	{
		return Std.instance(getUniformList(type).getParam(name), Uniform);
	}

	/**
	 *
	 */
	public function build():Void
	{
		_attributeList.build();
		_vUniformList.build();
		_fUniformList.build();
		_textureList.build();
	}

	public function destroy():Void
	{
		_vUniformList = null;
		_fUniformList = null;
		_textureList = null;
		_attributeList = null;
		vertexData = null;
		fragmentData = null;
		ShaderManager.instance.unregisterShader(name);
	}
}

