package org.angle3d.material;

import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.Technique;
import org.angle3d.renderer.IRenderer;

/**
 * Describes a material parameter. This is used for both defining a name and type
 * as well as a material parameter value.
 *
 */
class MatParam
{
	public var type:String;
	public var name:String;
	public var value:Dynamic;
	public var shaderType:ShaderType;

	public function new(type:String, name:String, value:Dynamic)
	{
		this.type = type;
		this.name = name;
		this.value = value;
	}

	public function apply(r:IRenderer, technique:Technique):Void
	{
		technique.updateUniformParam(shaderType, name, type, value);
	}

	public function clone():MatParam
	{
		return new MatParam(this.type, this.name, this.value);
	}

	public function equals(other:MatParam):Bool
	{
        if (other == null)
		{
            return false;
        }

        if (this.type != other.type)
		{
            return false;
        }
		
        if (this.name != other.name)
		{
            return false;
        }
		
        if (this.value != other.value)
		{
			if (this.value == null || !Reflect.hasField(this.value,"equals") || !this.value.equals(other.value))
			{
				return false;
			}
        }
		
        return true;
    }

}
