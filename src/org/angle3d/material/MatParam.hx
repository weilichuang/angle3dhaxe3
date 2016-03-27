package org.angle3d.material;

import org.angle3d.material.shader.ShaderType;
import org.angle3d.material.Technique;
import org.angle3d.renderer.RendererBase;

/**
 * Describes a material parameter. This is used for both defining a name and type
 * as well as a material parameter value.
 *
 */
class MatParam
{
	public var type:VarType;
	public var name:String;
	public var value:Dynamic;

	public function new(type:VarType, name:String, value:Dynamic)
	{
		this.type = type;
		this.name = name;
		this.value = value;
	}

	public function apply(r:RendererBase, technique:Technique):Void
	{
		technique.updateUniformParam(name, type, value);
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
