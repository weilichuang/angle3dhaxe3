package org.angle3d.material.shader;

import flash.utils.ByteArray;
import haxe.ds.StringMap;
import flash.Vector;
import org.angle3d.manager.ShaderManager;
import org.angle3d.renderer.IRenderer;


/**
 * 一个Shader是一个Technique中的一个实现，Technique根据不同的条件生成不同的Shader
 */
//TODO 优化
class Shader
{
	//vertex
	private var _vUniformList:UniformList;
	private var _attributeList:AttributeList;

	//fragment
	private var _fUniformList:UniformList;
	private var _textureList:ShaderVariableList;

	private var _bindUniforms:Array<Uniform>;

	private var _bindAttributes:StringMap<ShaderVariable>;

	public var vertexData:ByteArray;
	public var fragmentData:ByteArray;

	public var name:String;

	public function new()
	{
		_attributeList = new AttributeList();
		_vUniformList = new UniformList();
		_fUniformList = new UniformList();
		_textureList = new ShaderVariableList();

		_bindUniforms = new Array<Uniform>();
		_bindAttributes = new StringMap<ShaderVariable>();
	}

	public function addVariable(shaderType:ShaderType, type:ShaderVarType, name:String, size:Int):Void
	{
		switch (type)
		{
			case ShaderVarType.ATTRIBUTE:
				_attributeList.addVariable(new AttributeVar(name, size));
			case ShaderVarType.UNIFORM:
				getUniformList(shaderType).addVariable(new Uniform(name, size));
			case ShaderVarType.TEXTURE:
				_textureList.addVariable(new TextureVariable(name, size));
		}
	}

	/**
	 *
	 * @param	shaderType
	 * @param	digits
	 */
	public function setConstants(shaderType:ShaderType, digits:Array<Array<Float>>):Void
	{
		var list:UniformList = getUniformList(shaderType);

		list.setConstants(digits);
	}

	public function getTextureVar(name:String):TextureVariable
	{
		return cast(_textureList.getVariable(name), TextureVariable);
	}

	//TODO 添加方法根据类型来获得AttributeVar
	public function getAttributeByName(name:String):AttributeVar
	{
		return cast(_attributeList.getVariable(name), AttributeVar);
	}

	
	public function getTextureList():ShaderVariableList
	{
		return _textureList;
	}

	
	public function getUniformList(shaderType:ShaderType):UniformList
	{
		return (shaderType == ShaderType.VERTEX) ? _vUniformList : _fUniformList;
	}

	private static var mShaderTypes:Array<ShaderType> = [ShaderType.VERTEX, ShaderType.FRAGMENT];

	public function uploadTexture(render:IRenderer):Void
	{
		//上传贴图
		var textures:Array<ShaderVariable> = _textureList.getVariables();
		var size:Int = textures.length;
		for (i in 0...size)
		{
			var tex:TextureVariable = cast(textures[i], TextureVariable);
			render.setTextureAt(tex.location, tex.textureMap);
		}
	}

	//TODO 这里可以测试是否可以合并数据，一次提交数据
	public function upload(render:IRenderer):Void
	{
		for (i in 0...2)
		{
			var type:ShaderType = mShaderTypes[i];

			//上传常量
			_uploadConstants(render, type);

			//其他自定义数据
			var list:UniformList = getUniformList(type);
			var uniforms:Array<ShaderVariable> = list.getUniforms();
			var size:Int = uniforms.length;
			var uniform:Uniform;
			for (j in 0...size)
			{
				uniform = list.getUniformAt(j);
				render.setShaderConstants(type, uniform.location, uniform.data, uniform.size);
			}
		}
	}

	/**
	 * 常量总最先传
	 * @param	type
	 */
	private function _uploadConstants(render:IRenderer, shaderType:ShaderType):Void
	{
		var digits:Array<Array<Float>> = getUniformList(shaderType).getConstants();

		if (digits == null)
			return;

		var length:Int = digits.length;
		for (i in 0...length)
		{
			var vDigits:Vector<Float> = Vector.ofArray(digits[i]);
			render.setShaderConstants(shaderType, i, vDigits, 1);
		}
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
		return cast(getUniformList(type).getVariable(name), Uniform);
	}

	public function getAttributes():StringMap<ShaderVariable>
	{
		return _bindAttributes;
	}

	public function bindAttribute(bufferType:String, name:String):Void
	{
		_bindAttributes.set(bufferType,_attributeList.getVariable(name));
	}

	public function getAttribute(bufferType:String):AttributeVar
	{
		return cast(_bindAttributes.get(bufferType), AttributeVar);
	}

	/**
	 * 设置由系统自动计算传递数据的一些Uniform，例如worldViewProjectionMatrix
	 * @param	type
	 * @param	name
	 * @param	bd
	 */
	public function bindUniform(type:ShaderType, name:String, bd:UniformBinding):Void
	{
		var uniform:Uniform = getUniform(type, name);
		if (uniform != null)
		{
			uniform.binding = bd;
			_bindUniforms.push(uniform);
		}
	}

	/**
	 * Returns a list of uniforms that implements the world parameters
	 * that were requested by the material definition.
	 *
	 * @return a list of uniforms implementing the world parameters.
	 */
	public function getBindUniforms():Array<Uniform>
	{
		return _bindUniforms;
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
		_bindUniforms = null;
		vertexData = null;
		fragmentData = null;
		ShaderManager.instance.unregisterShader(name);
	}

	/**
	 * 设置系统绑定的Uniform
	 */
	public function setUniformBindings(binds:Array<UniformBindingHelp>):Void
	{
		var bLength:Int = binds.length;
		for (i in 0...bLength)
		{
			var help:UniformBindingHelp = binds[i];
			bindUniform(help.shaderType, help.name, help.bindType);
		}
	}

	/**
	 * 设置系统绑定的Attribute
	 */
	public function setAttributeBindings(attributeMap:StringMap<String>):Void
	{
		var keys:Iterator<String> = attributeMap.keys();
		for (key in keys)
		{
			bindAttribute(key, attributeMap.get(key));
		}
	}
}

