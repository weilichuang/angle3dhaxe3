package org.angle3d.material.sgsl.parser;

import flash.utils.RegExp;
import haxe.ds.StringMap;
import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.error.UnexpectedTokenError;
import org.angle3d.material.sgsl.RegType;


//TODO 优化解析速度
class Tokenizer
{
	private var _tokenRegex:Array<String>;
	private var _regSource:String;
	private var _tokenRegexpCount:Int;

	private var _reservedMap:StringMap<String>;

	private var _finalRegex:RegExp;

	private var _source:String;
	private var _sourceSize:Int;
	private var _position:Int;

	public var token:Token;
	public var nextToken:Token;

	public function new(source:String)
	{
		_reservedMap = new StringMap<String>();
		_reservedMap.set("function",TokenType.FUNCTION);
		_reservedMap.set("return",TokenType.RETURN);
		_reservedMap.set("if",TokenType.IF);
		_reservedMap.set("else",TokenType.ELSE);
		_reservedMap.set(DataType.VOID,TokenType.DATATYPE);
		_reservedMap.set(DataType.FLOAT,TokenType.DATATYPE);
		_reservedMap.set(DataType.VEC2,TokenType.DATATYPE);
		_reservedMap.set(DataType.VEC3,TokenType.DATATYPE);
		_reservedMap.set(DataType.VEC4,TokenType.DATATYPE);
		_reservedMap.set(DataType.MAT3, TokenType.DATATYPE);
		_reservedMap.set(DataType.MAT34,TokenType.DATATYPE);
		_reservedMap.set(DataType.MAT4,TokenType.DATATYPE);
		_reservedMap.set(DataType.SAMPLER2D,TokenType.DATATYPE);
		_reservedMap.set(DataType.SAMPLERCUBE,TokenType.DATATYPE);
		_reservedMap.set(RegType.ATTRIBUTE,TokenType.REGISTER);
		_reservedMap.set(RegType.VARYING,TokenType.REGISTER);
		_reservedMap.set(RegType.UNIFORM,TokenType.REGISTER);
		_reservedMap.set(RegType.TEMP,TokenType.REGISTER);

		setSource(source);
	}

	/**
	 * 检查下一个
	 */
	//TODO 优化，每次检查之后应该去掉之前的字符串
	public function next():Void
	{
		// end of script
		if (_position >= _sourceSize)
		{
			if (_position == _sourceSize)
			{
				token = nextToken;
				nextToken = new Token(TokenType.EOF, "<EOF>");
			}
			else
			{
				nextToken = new Token(TokenType.NONE, "<NONE>");
				token = new Token(TokenType.EOF, "<EOF>");
			}
			return;
		}
		
		// skip spaces
		while (_source.charCodeAt(_position) <= 32)
		{
			_position++;
			if (_position >= _sourceSize)
			{
				if (_position == _sourceSize)
				{
					token = nextToken;
					nextToken = new Token(TokenType.EOF, "<EOF>");
				}
				else
				{
					nextToken = new Token(TokenType.NONE, "<NONE>");
					token = new Token(TokenType.EOF, "<EOF>");
				}
				return;
			}
		}

		token = nextToken;
		nextToken = _createNextToken(_source.substr(_position));
	}

	/**
	 * 检查是否正确，返回当前Token,并解析下一个关键字
	 */
	public function accept(type:String):Token
	{
		#if debug
		//检查是否同一类型
		if (token.type != type)
			throw new UnexpectedTokenError(token, type);
		#end

		var t:Token = token;
		next();
		return t;
	}

	public function getSource():String
	{
		return _source;
	}

	public function setSource(value:String):Void
	{
		//忽略注释
		_source = cleanSource(value);

		_sourceSize = _source.length;
		_position = 0;

		_buildRegex();

		token = new Token(TokenType.NONE, "<NONE>");
		nextToken = new Token(TokenType.NONE, "<NONE>");
		next();
	}

	//优化代码
	private function cleanSource(value:String):String
	{
		//删除/**/和//类型注释
		var result:String = ~/\/\*(.|[^.])*?\*\/|\/\/.*[^.]/g.replace(value,"");
		/**
		 * 除去多余的空格换行符等等
		 */
		result = ~/\t+|\\x20+/g.replace(result," ");
		result = ~/\r\n|\n/g.replace(result,"");

		return result;
	}

	private function _buildRegex():Void
	{
		if (_tokenRegex == null)
		{
			_tokenRegex = [TokenType.IDENTIFIER, "[a-zA-Z_][a-zA-Z0-9_]*",
							TokenType.NUMBER, "[-]?[0-9]+[.]?[0-9]*([eE][-+]?[0-9]+)?",
							TokenType.PREDEFINE, "#ifdef|#ifndef|#elseif|#else",
							// grouping
							TokenType.SEMI, ";",
							TokenType.LBRACE, "{",
							TokenType.RBRACE, "}",
							TokenType.LBRACKET, "\\[",
							TokenType.RBRACKET, "\\]",
							TokenType.LPAREN, "\\(",
							TokenType.RPAREN, "\\)",
							TokenType.COMMA, ",",
							//compare
							TokenType.GREATER_THAN, "\\>",
							TokenType.LESS_THAN, "\\<",
							TokenType.GREATER_EQUAL, "\\>=",
							TokenType.LESS_EQUAL, "\\<=",
							TokenType.NOT_EQUAL, "\\!=",
							TokenType.DOUBLE_EQUAL, "==",
							//operators
							TokenType.DOT, "\\.",
							TokenType.PLUS, "\\+",
							TokenType.SUBTRACT, "-",
							TokenType.MULTIPLY, "\\*",
							TokenType.DIVIDE, "\\/",
							TokenType.EQUAL, "=",
							TokenType.AND, "&&",
							TokenType.OR, "\\|\\|"];

			_tokenRegexpCount = Std.int(_tokenRegex.length * 0.5);

			_regSource = "^(";
			for (i in 0..._tokenRegexpCount)
			{
				_regSource += "?P<" + _tokenRegex[i * 2] + ">" + _tokenRegex[i * 2 + 1];
				if (i < _tokenRegexpCount)
					_regSource += ")|^(";
			}

			_regSource += ")";
		}
		
		_finalRegex = new RegExp(_regSource);
	}

	private function _createNextToken(source:String):Token
	{
		var result:Dynamic = _finalRegex.exec(source);
		var result0:String = result[0];
		_position += result0.length;

		var type:String = "";
		//首先检查关键字
		if (_reservedMap.exists(result0))
		{
			type = _reservedMap.get(result0);
		}
		else
		{
			for (i in 0..._tokenRegexpCount)
			{
				var curType:String = _tokenRegex[i * 2];
				if (untyped result[curType] == result0)
				{
					type = curType;
					break;
				}
			}
		}

		//做个缓存池
		return new Token(type, result0);
	}
}
