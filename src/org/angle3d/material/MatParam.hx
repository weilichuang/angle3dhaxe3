package org.angle3d.material;

import org.angle3d.shader.ShaderType;
import org.angle3d.material.Technique;
import org.angle3d.renderer.Renderer;
import org.angle3d.shader.VarType;

/**
 * Describes a material parameter. This is used for both defining a name and type
 * as well as a material parameter value.
 */
class MatParam {
	public var type:VarType;
	public var name:String;
	public var prefixedName:String;

	/**
	 * the value of this material parameter
	 */
	public var value:Dynamic;

	public function new(type:VarType, name:String, value:Dynamic) {
		this.type = type;
		this.name = name;
		this.prefixedName = "m_" + name;
		this.value = value;
	}

	public function setName(name:String):Void {
		this.name = name;
		this.prefixedName = "m_" + name;
	}

	public function clone():MatParam {
		return new MatParam(this.type, this.name, this.value);
	}

	public function equals(other:MatParam):Bool {
		if (other == null) {
			return false;
		}

		if (this.type != other.type) {
			return false;
		}

		if (this.name == null || other.name == null || this.name != other.name) {
			return false;
		}

		if (this.value != other.value && (this.value == null || !this.value.equals(other.value))) {
			return false;
		}

		return true;
	}

	public function toString():String {
		if (value != null) {
			return Type.enumConstructor(type) + " " + name + " : " + value;
		} else{
			return Type.enumConstructor(type) + " " + name;
		}
	}
}