package org.angle3d.material.shader;

#if js
	import js.html.webgl.Program;
#end

import haxe.EnumTools;
import haxe.ds.IntMap;
import haxe.ds.StringMap;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.utils.NativeObject;

/**
 * 一个Shader是一个Technique中的一个实现，Technique根据不同的条件生成不同的Shader
 */
class Shader extends NativeObject {
	private static var mShaderTypes:Array<ShaderType> = [ShaderType.VERTEX, ShaderType.FRAGMENT];

	public var name:String;

	/**
	 * A list of all shader sources currently attached.
	 */
	private var shaderSourceList:Array<ShaderSource>;

	private var _boundUniforms:Array<Uniform>;

	private var _uniformMap:StringMap<Uniform>;
	private var _uniforms:Array<Uniform>;

	private var _attributeMap:IntMap<Attribute>;

	public function new() {
		shaderSourceList = [];
		_boundUniforms = [];

		_attributeMap = new IntMap<Attribute>();

		_uniforms = [];
		_uniformMap = new StringMap<Uniform>();
	}

	public function addSource(type:ShaderType, name:String,source:String, defines:String, language:String):Void {
		var shaderSource = new ShaderSource(type);
		shaderSource.setSource(source);
		shaderSource.setName(name);
		shaderSource.setLanguage(language);
		if (defines != null) {
			shaderSource.setDefines(defines);
		}
		shaderSourceList.push(shaderSource);
		setUpdateNeeded();
	}

	public function addUniformBinding(binding:UniformBinding):Void {
		var uniformName = Type.enumConstructor(binding);
		var uniform = _uniformMap.get(uniformName);
		if (uniform == null) {
			uniform = new Uniform();
			uniform.name = uniformName;
			uniform.binding = binding;
			_uniformMap.set(uniformName, uniform);
			_boundUniforms.push(uniform);
			_uniforms.push(uniform);
		}
	}

	public function getUniform(name:String):Uniform {
		var uniform = _uniformMap.get(name);
		if (uniform == null) {
			uniform = new Uniform();
			uniform.name = name;
			_uniformMap.set(name, uniform);
			_uniforms.push(uniform);
		}
		return uniform;
	}

	public function removeUniform(name:String):Void {
		var uniform = _uniformMap.get(name);
		if (uniform != null) {
			_uniformMap.remove(name);
			_uniforms.remove(uniform);
		}
	}

	public function getAttribute(attribType:BufferType):Attribute {
		var attrib = _attributeMap.get(Type.enumIndex(attribType));
		if (attrib == null) {
			attrib = new Attribute();
			attrib.name = Type.enumConstructor(attribType);
			_attributeMap.set(name, attrib);
		}
		return attrib;
	}

	public inline function getUniformMap():StringMap<Uniform> {
		return _uniformMap;
	}

	public inline function getBoundUniforms():Array<Uniform> {
		return _boundUniforms;
	}

	public inline function getSources():Array<ShaderSource> {
		return shaderSourceList;
	}

	/**
	 * Removes the "set-by-current-material" flag from all uniforms.
	 * When a uniform is modified after this call, the flag shall
	 * become "set-by-current-material".
	 * A call to {@link #resetUniformsNotSetByCurrent() } will reset
	 * all uniforms that do not have the "set-by-current-material" flag
	 * to their default value (usually all zeroes or false).
	 */
	public function clearUniformsSetByCurrentFlag():Void {
		for (i in 0..._uniforms.length) {
			var uniform:Uniform = _uniforms[i];
			uniform.clearSetByCurrentMaterial();
		}
	}

	/**
	 * Resets all uniforms that do not have the "set-by-current-material" flag
	 * to their default value (usually all zeroes or false).
	 * When a uniform is modified, that flag is set, to remove the flag,
	 * use {@link #clearUniformsSetByCurrent() }.
	 */
	public function resetUniformsNotSetByCurrent():Void {
		for (i in 0..._uniforms.length) {
			var uniform:Uniform = _uniforms[i];
			if (!uniform.isSetByCurrentMaterial()) {
				uniform.clearSetByCurrentMaterial();
			}
		}
	}

	/**
	 * Usually called when the shader itself changes or during any
	 * time when the variable locations need to be refreshed.
	 */
	public function resetLocations():Void {
		for (i in 0..._uniforms.length) {
			var uniform:Uniform = _uniforms[i];
			uniform.reset();
		}
		
		for (attrib in _attributeMap){
			attrib.location = null;
		}
	}

	public function dispose():Void {
		_uniforms = null;
		_uniformMap = null;
		_attributeMap = null;
	}
}

