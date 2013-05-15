package org.angle3d.material.shader;

#if flash
typedef ShaderType = flash.display3D.Context3DProgramType;
#else
@:fakeEnum(String) enum ShaderType
{
	FRAGMENT;
	VERTEX;
}
#end

