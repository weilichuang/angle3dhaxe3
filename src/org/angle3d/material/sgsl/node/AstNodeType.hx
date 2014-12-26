package org.angle3d.material.sgsl.node;

/**
 * @author weilichuang
 */

enum AstNodeType 
{
	ShaderVar;// attribute vec3 a_pos;
	TempVar;// float t_pos;
	RegisterType;//attribute,uniform,varying
	DataType;//float,vec2,vec3,vec4
	Preprocesor;//#ifdef ...
	Function;// float function
	FunctionParam;//
	FunctionCall;
	Identifier;
	Const;
	Assignment;
	Divide;
	Multiplty;
	Add;
	Subtract;
	Neg;
}