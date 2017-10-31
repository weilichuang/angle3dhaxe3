package org.angle3d.material.shader;

import flash.display3D.Context3D;
import flash.display3D.Program3D;
import flash.utils.ByteArray;
import haxe.ds.StringMap;

import org.angle3d.manager.ShaderManager;
import org.angle3d.material.sgsl.node.reg.AttributeReg;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.node.reg.UniformReg;
import org.angle3d.renderer.Stage3DRenderer;


/**
 * 一个Shader是一个Technique中的一个实现，Technique根据不同的条件生成不同的Shader
 */
class Shader
{
	private static var mShaderTypes:Array<ShaderType> = [ShaderType.VERTEX, ShaderType.FRAGMENT];
	
	public var id:Int;
	
	public var name:String;
	
	public var vertexData:ByteArray;
	public var fragmentData:ByteArray;
	
	public var vertexUniformList(get, never):UniformList;
	public var fragmentUniformList(get, never):UniformList;
	
	//vertex
	private var _vUniformList:UniformList;
	private var _attributeList:AttributeList;

	//fragment
	private var _fUniformList:UniformList;
	private var _textureList:ShaderParamList;
	
	private var _boundUniforms:Array<Uniform>;
	
	private var _uniformMap:FastStringMap<Uniform>;

	private var program:Program3D;
	
	public var registerCount:Int = 0;

	public function new()
	{
		_attributeList = new AttributeList();
		_vUniformList = new UniformList();
		_fUniformList = new UniformList();
		_textureList = new ShaderParamList();
		
		_boundUniforms = new Array<Uniform>();
		
		_uniformMap = new FastStringMap<Uniform>();
	}

	public function addVariable(shaderType:ShaderType, paramType:ShaderParamType, regNode:RegNode):Void
	{
		switch (paramType)
		{
			case ShaderParamType.ATTRIBUTE:
				var attriReg:AttributeReg = cast regNode;
				_attributeList.addParam(new AttributeParam(attriReg.name, attriReg.size, attriReg.bufferType));
			case ShaderParamType.UNIFORM:
				var uniformReg:UniformReg = cast regNode;
				var bind:Int = uniformReg.uniformBind;
				var uniform:Uniform = new Uniform(uniformReg.name, uniformReg.size, bind);
				getUniformList(shaderType).addParam(uniform);
				
				_uniformMap.set(uniform.name, uniform);
				
				if (bind != -1)
				{
					_boundUniforms.push(uniform);
				}
				
			case ShaderParamType.TEXTURE:
				_textureList.addParam(new TextureParam(regNode.name, regNode.size));
		}
	}

	/**
	 *
	 * @param	shaderType
	 * @param	digits
	 */
	public function setConstants(shaderType:ShaderType, digits:Array<Float>):Void
	{
		var list:UniformList = getUniformList(shaderType);

		list.numbers = digits.slice();
	}
	
	public inline function getBoundUniforms():Array<Uniform>
	{
        return _boundUniforms;
    }

	public inline function getTextureParam(name:String):TextureParam
	{
		return cast _textureList.getParam(name);
	}

	//TODO 添加方法根据类型来获得AttributeParam
	public inline function getAttributeByName(name:String):AttributeParam
	{
		return cast _attributeList.getParam(name);
	}
	
	public inline function getAttributeList():AttributeList
	{
		return _attributeList;
	}

	public inline function getTextureList():ShaderParamList
	{
		return _textureList;
	}
	
	public inline function getUniformList(shaderType:ShaderType):UniformList
	{
		return (shaderType == ShaderType.VERTEX) ? _vUniformList : _fUniformList;
	}
	
	public function clearUniformsSetByCurrent():Void
	{
		var uniform:Uniform;
		var list:UniformList = getUniformList(ShaderType.VERTEX);
		for (j in 0...list.getUniforms().length)
		{
			uniform = list.getUniformAt(j);
			uniform.clearSetByCurrentMaterial();
		}
		
		list = getUniformList(ShaderType.FRAGMENT);
		for (j in 0...list.getUniforms().length)
		{
			uniform = list.getUniformAt(j);
			uniform.clearSetByCurrentMaterial();
		}
	}
	
	public function resetUniformsNotSetByCurrent():Void
	{
		var uniform:Uniform;
		var list:UniformList = getUniformList(ShaderType.VERTEX);
		for (j in 0...list.getUniforms().length)
		{
			uniform = list.getUniformAt(j);
			// Don't reset world globals! 
			if (!uniform.isSetByCurrentMaterial() && uniform.binding == -1)
			{
				uniform.clearValue();
			}
		}
		
		list = getUniformList(ShaderType.FRAGMENT);
		for (j in 0...list.getUniforms().length)
		{
			uniform = list.getUniformAt(j);
			// Don't reset world globals! 
			if (!uniform.isSetByCurrentMaterial() && uniform.binding == -1)
			{
				uniform.clearValue();
			}
		}
    }

	public function updateUniforms(render:Stage3DRenderer):Void
	{
		var list:UniformList;
		var uniforms:Array<ShaderParam>;
		var size:Int;
		var uniform:Uniform;
		
		//------------vertex-------------//
		list = _vUniformList;
		//总是先上传常量
		if (list.numberSize > 0)
		{
			render.setShaderConstants(ShaderType.VERTEX, 0, list.numbers, list.numberSize);
		}

		//其他自定义数据
		uniforms = list.getUniforms();
		size = uniforms.length;
		for (j in 0...size)
		{
			uniform = list.getUniformAt(j);
			if(uniform.needUpdated)
			{
				render.setShaderConstants(ShaderType.VERTEX, uniform.location, uniform.data, uniform.size);
				uniform.needUpdated = false;
			}
		}
		
		//------------fragment-------------//
		list = _fUniformList;
		//总是先上传常量
		if (list.numberSize > 0)
		{
			render.setShaderConstants(ShaderType.FRAGMENT, 0, list.numbers, list.numberSize);
		}

		//其他自定义数据
		uniforms = list.getUniforms();
		size = uniforms.length;
		for (j in 0...size)
		{
			uniform = list.getUniformAt(j);
			if(uniform.needUpdated)
			{
				render.setShaderConstants(ShaderType.FRAGMENT, uniform.location, uniform.data, uniform.size);
				uniform.needUpdated = false;
			}
		}
	}

	public function setUniform(name:String, data:Array<Float>):Void
	{
		var uniform:Uniform = getUniform(name);
		if (uniform != null)
		{
			uniform.setVector(data);
		}
	}

	//TODO 只根据名字来获得Uniform，需要确保vertex和fragment中uniform不重名
	//vertex中加前缀vu_代表vertex uniform
	//fragment中加前缀fu_代表fragment uniform
	//前缀为gu_代表 global uniform，这种类型的不需要用户修改数据，系统自动修改数据
	public inline function getUniform(name:String):Uniform
	{
		return _uniformMap.get(name);
	}
	
	public inline function getProgram3D(content:Context3D):Program3D
	{
		if (program == null)
		{
			if (this.vertexData != null && this.fragmentData != null)
			{
				program = content.createProgram();
				program.upload(this.vertexData, this.fragmentData);
			}
		}
		return program;
	}

	/**
	 * 计算attribute,uniform,varying位置
	 */
	public function updateLocations():Void
	{
		_attributeList.updateLocations();
		_vUniformList.updateLocations();
		_fUniformList.updateLocations();
		_textureList.updateLocations();
	}

	public function dispose():Void
	{
		_vUniformList = null;
		_fUniformList = null;
		_textureList = null;
		_attributeList = null;
		
		if (vertexData != null)
		{
			vertexData.clear();
			vertexData = null;
		}
		
		if (fragmentData != null)
		{
			fragmentData.clear();
			fragmentData = null;
		}

		if (program != null)
		{
			program.dispose();
			program = null;
		}
	}
	
	private inline function get_vertexUniformList():UniformList
	{
		return _vUniformList;
	}

	private inline function get_fragmentUniformList():UniformList
	{
		return _fUniformList;
	}
}

