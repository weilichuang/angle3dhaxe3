package org.angle3d.material.sgsl.parser;

/**
 * ...
 * @author weilichuang
 */
class TokenType
{
	public static inline var COMMENT:Int = 1;
	
	public static inline var OPERATOR:Int = 2;
	
	public static inline var REGISTERTYPE:Int = 3;
	
	public static inline var RESERVED:Int = 4;

	public static inline var PREPROCESOR:Int = 5;
	
	public static inline var WORD:Int = 6;
	
	public static inline var DATATYPE:Int = 7;
	
	public static inline var NUMBER:Int = 8;
	
	public static inline var EOF:Int = 9;
	
	public static function getTokenTypeNameBy(type:Int)
	{
		switch(type)
		{
			case COMMENT:
				return "COMMENT";
			case OPERATOR:
				return "OPERATOR";
			case REGISTERTYPE:
				return "REGISTERTYPE";
			case PREPROCESOR:
				return "PREPROCESOR";
			case WORD:
				return "WORD";
			case DATATYPE:
				return "DATATYPE";
			case NUMBER:
				return "NUMBER";
			case EOF:
				return "EOF";
		}
		return "";
	}
}