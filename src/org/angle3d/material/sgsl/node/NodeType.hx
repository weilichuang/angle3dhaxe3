package org.angle3d.material.sgsl.node; 

class NodeType 
{
	public static inline var EMPTY:Int = 0;
	public static inline var PROGRAM:Int = 1;
	public static inline var FUNCTION:Int = 2;
	public static inline var FUNCTIONPARAM:Int = 3;
	public static inline var FUNCTION_CALL:Int = 4;
	public static inline var SHADERVAR:Int = 5;
	public static inline var PREPROCESOR:Int = 6;
	public static inline var ASSIGNMENT:Int = 7;
	public static inline var ARRAYACCESS:Int = 8;
	public static inline var NUMBER:Int = 9;
	public static inline var IDENTIFIER:Int = 10;
	public static inline var DIVIDE:Int = 11;
	public static inline var MULTIPLTY:Int = 12;
	public static inline var ADD:Int = 13;
	public static inline var SUBTRACT:Int = 14;
	public static inline var RETURN:Int = 15;
	public static inline var CONDITION:Int = 16;
}