package org.angle3d.shader;
import org.angle3d.utils.NativeObject;

/**
 * ...
 * @author
 */
class ShaderSource extends NativeObject {
	public var name:String;
	public var source:String;
	public var defines:String;
	public var language:String;
	public var sourceType:ShaderType;

	public function new(type:ShaderType) {
		super();
		this.sourceType = type;
	}
	
	public function setName(name:String):Void {
		this.name = name;
	}

	public function getName():String {
		return this.name;
	}

	public function setLanguage(language:String):Void {
		this.language = language;
		setUpdateNeeded();
	}

	public function getLanguage():String {
		return this.language;
	}

	public function setSource(source:String):Void {
		this.source = source;
		setUpdateNeeded();
	}

	public function setDefines(defines:String):Void {
		this.defines = defines;
		setUpdateNeeded();
	}

	public function getSource():String {
		return this.source;
	}

	public function getDefines():String {
		return this.defines;
	}
	
	public function resetObject():Void{
		id =-1;
		setUpdateNeeded();
	}
}