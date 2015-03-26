package org.angle3d.material.shader;

import org.angle3d.asset.AssetKey;

/**
 * ...
 * @author weilichuang
 */
class ShaderKey extends AssetKey
{
	public var defines:DefineList;
	public var vertName:String;
	public var fragName:String;

	public function new(defines:DefineList,vertName:String,fragName:String) 
	{
		super();
		this.defines = defines;
		this.vertName = vertName;
		this.fragName = fragName;
	}
	
	override public function clone():AssetKey
	{
		var result:ShaderKey = new ShaderKey(this.defines.clone(), this.vertName, this.fragName);
		return result;
	}
	
	override public function equals(other:AssetKey):Bool
	{
		var otherShaderKey:ShaderKey = Std.instance(other,ShaderKey);
		if (otherShaderKey == null)
			return false;
			
		if (this.vertName != otherShaderKey.vertName || this.fragName != otherShaderKey.fragName)
		{
			return false;
		}
		
		if (defines != null && otherShaderKey.defines != null)
		{
			return defines.equals(otherShaderKey.defines);
		}
		else if (defines != null || otherShaderKey.defines != null)
		{
			return false;
		}
		else
		{
			return true;
		}
	}
	
	public function toString():String
	{
		return "vert:" + vertName+",frag:" + fragName+",defines:" + defines;
	}
	
}