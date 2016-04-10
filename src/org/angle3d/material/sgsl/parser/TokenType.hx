package org.angle3d.material.sgsl.parser;

/**
 * ...
 
 */
@:enum abstract TokenType(Int)   
{
	var COMMENT:TokenType = 1;
	
	var OPERATOR:TokenType = 2;
	
	var REGISTERTYPE:TokenType = 3;
	
	var RESERVED:TokenType = 4;

	var PREPROCESOR:TokenType = 5;
	
	var WORD:TokenType = 6;
	
	var DATATYPE:TokenType = 7;
	
	var NUMBER:TokenType = 8;
	
	var EOF:TokenType = 9;
	
	public static function getTokenTypeNameBy(type:TokenType):String
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
			case RESERVED:
				return "RESERVED";
			case EOF:
				return "EOF";
		}
	}
}