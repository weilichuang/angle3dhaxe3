package org.angle3d.material.sgsl.parser;

class TokenType
{
	/**
	 * Reserved words
	 */
	//数据类型
	public static inline var DATATYPE:String = "DATATYPE";

	//寄存器
	public static inline var REGISTER:String = "REGISTER";

	//函数
	/** function */
	public static inline var FUNCTION:String = "function";

	public static inline var IF:String = "if";

	public static inline var ELSE:String = "else";

	/** return */
	public static inline var RETURN:String = "return";


	public static inline var NONE:String = "NONE";
	public static inline var EOF:String = "EOF";

	public static inline var IDENTIFIER:String = "IDENTIFIER";
	public static inline var NUMBER:String = "NUMBER";

	//预编译条件
	/** # */
	public static inline var PREDEFINE:String = "PREDEFINE";

	/**
	 * Grouping, delimiting
	 */
	/** . */
	public static inline var DOT:String = "DOT";
	/** ; */
	public static inline var SEMI:String = "SEMI";
	/** { */
	public static inline var LBRACE:String = "LBRACE";
	/** } */
	public static inline var RBRACE:String = "RBRACE";
	/** ( */
	public static inline var LPAREN:String = "LPAREN";
	/** ) */
	public static inline var RPAREN:String = "RPAREN";
	/** , */
	public static inline var COMMA:String = "COMMA";

	/** + */
	public static inline var PLUS:String = "PLUS";

	/** - */
	public static inline var SUBTRACT:String = "SUBTRACT";

	/** * */
	public static inline var MULTIPLY:String = "MULTIPLY";

	/** / */
	public static inline var DIVIDE:String = "DIVIDE";

	/** = */
	public static inline var EQUAL:String = "EQUAL";

	/** && */
	public static inline var AND:String = "AND";

	/** || */
	public static inline var OR:String = "OR";

	/** == */
	public static inline var DOUBLE_EQUAL:String = "DOUBLE_EQUAL";

	/** != */
	public static inline var NOT_EQUAL:String = "NOT_EQUAL";

	/** >= */
	public static inline var GREATER_EQUAL:String = "GREATER_EQUAL";

	/** <= */
	public static inline var LESS_EQUAL:String = "LESS_EQUAL";

	/** > */
	public static inline var GREATER_THAN:String = "GREATER_THAN";

	/** < */
	public static inline var LESS_THAN:String = "LESS_THAN";

	/** [ */
	public static inline var LBRACKET:String = "LBRACKET";

	/** ] */
	public static inline var RBRACKET:String = "RBRACKET";
	
	public static inline var COMMENT:String = "COMMENT";
	
	public static inline var OPERATOR:String = "op";
	
	public static inline var RESERVED:String = "reserved";

	public static inline var KEYWORD:String = "keyw";

	public static inline var PREPROCESOR:String = "preproc";
	
	//public static inline var NUMBER:String = "number";
	
	public static inline var WORD:String = "word";
}


