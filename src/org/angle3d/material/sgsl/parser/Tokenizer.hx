package org.angle3d.material.sgsl.parser;
import flash.Vector;
import org.angle3d.math.FastMath;

class Tokenizer
{
	private var _source:String;
	private var _lineAt:Int;
	private var _charIndex:Int;

	private static var _preprocesor:Vector<String> = Vector.ofArray(["#ifdef", "#else", "#ifndef", "#elseif", "#define", "#version","#textureformat"]);
	
	private static var _registerType:Vector<String> = Vector.ofArray(["attribute", "varying", "uniform"]);
	
	private static var _reserved:Vector<String> = Vector.ofArray(["return", "function", "if", "else"]);
      
    private static var _dataType:Vector<String> = Vector.ofArray(["float", "vec2", "vec3", "vec4", "mat4", "mat3", "mat34", "void", "sampler2D", "samplerCube"]);
      
    private static var _operators:Vector<String> = Vector.ofArray(["++", "--", "+=", "-=", "*=", "/=",
																	"&&", "||", "<=", ">=", "==", "!=", ">", "<", "+", "-", "*", "/",
																	".","=",",",";","(",")","{","}","[","]"]);

	public function new() 
	{
		
	}
	
	public function parse(source:String):Vector<Token>
	{
		_source = ~/\r/g.replace(source, "");
        _source += "\n";
		
		var tokens:Vector<Token> = new Vector<Token>();
		_lineAt = 0;
		_charIndex = 0;
		var c:String;
		while (_charIndex < _source.length)
		{
			var t:Token = null;
			if ((t = isComment(_charIndex))  == null)
			{
				if ((t = isTokenArray(_charIndex, _preprocesor, TokenType.PREPROCESOR)) == null)
				{
					if ((t = isTokenArray(_charIndex, _reserved, TokenType.RESERVED)) == null)
					{
						if ((t = isTokenArray(_charIndex, _registerType, TokenType.REGISTERTYPE)) == null)
						{
							if ((t = isTokenArray(_charIndex, _dataType, TokenType.DATATYPE)) == null)
							{
								if ((t = isWord(_charIndex)) == null)
								{
									if ((t = isTokenArray(_charIndex, _operators, TokenType.OPERATOR)) == null)
									{
										c = _source.charAt(_charIndex);
										if (isNewLine(c))
										{
											_lineAt++;
										}
										else if (c != "\t")
										{
											if (c != String.fromCharCode(32))
											{
												error(_charIndex,"Unexpected character \'" + c + "\'.");
											}
										}
									}
								}
							}
						}
					}
				}
			}
			
			
			if (t != null)
			{
				if (t.type != TokenType.COMMENT)
				{
					tokens[tokens.length] = t;
				}
				_charIndex += t.text.length;
			}
			else
			{
				_charIndex++;
			}
		}
		
		tokens[tokens.length] = new Token(TokenType.EOF, "End of File", getLinesAt(_charIndex), getPositionAt(_charIndex));
		
		return tokens;
	}
	
	private function isTokenArray(start:Int, array:Vector<String>, type:TokenType) : Token
	{
		for(i in 0...array.length)
		{
			var t:Token = isToken(start, array[i], type);
			if(t != null)
			{
				return t;
			}
		}
		return null;
	}
	
	private function isToken(start:Int, text:String, type:TokenType) : Token
	{
		var size:Int = text.length;
		if (_source.substr(start, size) == text)
		{
			if (type != TokenType.OPERATOR && isDigitOrLetter(_source.charAt(_charIndex + size)))
			{
				return null;
			}
			return new Token(type, text, getLinesAt(start), getPositionAt(start));
		}
		return null;
	}
	
	private function isWord(start:Int):Token
	{
		var ch:String = _source.charAt(start);
		if (!isDigitOrLetter(ch) && ch != ".")
		{
			return null;
		}
		
		var t:String = "";
		var pos:Int = start;
		while(isDigitOrLetter(ch) || (ch == ".") || (ch.toLowerCase() == "x"))
		{
			t += ch;
			ch = _source.charAt(++start);
		}
		
		if(t.length > 0)
		{
			var firstChar:String = t.charAt(0);
			if(isDigit(firstChar) || (firstChar == "."))
			{
				var value:Float = Std.parseFloat(t);
				if(FastMath.isNaN(value))
				{
					if(firstChar == ".")
					{
						return new Token(TokenType.OPERATOR, ".", getLinesAt(pos), getPositionAt(pos));
					}
					error(start - t.length, "Invalid number value:" + t);
				}
				return new Token(TokenType.NUMBER, t, getLinesAt(pos), getPositionAt(pos));
			}
			if(t.indexOf(".") != -1)
			{
				t = t.substr(0, t.indexOf("."));
			}
			return new Token(TokenType.WORD, t, getLinesAt(pos), getPositionAt(pos));
		}
		return null;
	}
	
	private function isComment(start:Int) : Token
	{
		var ch:String = _source.substr(start, 2);
		var t:String = "";
		if(ch == "//")
		{
			start++;
			while(!isNewLine(ch))
			{
				ch = _source.charAt(++start);
				t += ch;
			}
			return new Token(TokenType.COMMENT, t + ch, getLinesAt(start), getPositionAt(start));
		}
		
		if(ch == "/*")
		{
			var i:Int = _source.indexOf("*/",start);
			if(i == -1)
			{
				i = _source.length - 2;
			}
			
			var str:String = _source.substr(start, i - start);
			var eReg:EReg = ~/\n/;
			var lineCount:Int = 0;
			while (eReg.match(str))
			{
				lineCount++;
				str = eReg.matchedRight(); 
			}
			
			_lineAt = _lineAt + lineCount;
			
			return new Token(TokenType.COMMENT, _source.substring(start, i + 2), getLinesAt(start), getPositionAt(start));
		}
		
		return null;
	}
	
	private inline function isNewLine(ch:String) : Bool
	{
		return ch == "\r" || ch == "\n";
	}
	
	private inline function isDigit(ch:String) : Bool
	{
		var code:Int = ch.charCodeAt(0);
		// 0-9
		return code >= 48 && code <= 57;
		
		//return (ch >= "0") && (ch <= "9");
	}

	private inline function isLetter(ch:String) : Bool
	{
		var code:Int = ch.charCodeAt(0);
		// 0-9, A-Z, a-z, _
		return code >= 48 && code <= 57 || code >= 65 && code <= 90 || code >= 97 && code <= 122 || ch == "_";
		
		//return (ch >= "A") && (ch <= "Z") || (ch >= "a") && (ch <= "z") || (ch == "_");
	}
	
	private inline function isDigitOrLetter(ch:String) : Bool
	{
		return isDigit(ch) || isLetter(ch);
	}

	private inline function getLinesAt(start:Int) : Int
	{
		return _lineAt + 1;
	}

	private inline function getPositionAt(start:Int) : Int
	{
		return start - _source.lastIndexOf("\n",start);
	}
	
	private inline function error(char:Int, message:String) : Void
	{
		#if debug
		throw "Line: " + getLinesAt(char) + " col: " + getPositionAt(char) + " - " + message;
		#end
	}
	
}