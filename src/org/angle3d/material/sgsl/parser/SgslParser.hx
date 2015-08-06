package org.angle3d.material.sgsl.parser;
import flash.Vector;
import org.angle3d.material.sgsl.node.ArrayAccessNode;
import org.angle3d.material.sgsl.node.AssignNode;
import org.angle3d.material.sgsl.node.AtomNode;
import org.angle3d.material.sgsl.node.ConditionElseNode;
import org.angle3d.material.sgsl.node.ConditionEndNode;
import org.angle3d.material.sgsl.node.ConditionIfNode;
import org.angle3d.material.sgsl.node.NumberNode;
import org.angle3d.material.sgsl.node.FunctionCallNode;
import org.angle3d.material.sgsl.node.FunctionNode;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.node.NodeType;
import org.angle3d.material.sgsl.node.OpNode;
import org.angle3d.material.sgsl.node.ParameterNode;
import org.angle3d.material.sgsl.node.PredefineNode;
import org.angle3d.material.sgsl.node.PredefineSubNode;
import org.angle3d.material.sgsl.node.PredefineType;
import org.angle3d.material.sgsl.node.ProgramNode;
import org.angle3d.material.sgsl.node.reg.RegFactory;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.node.ReturnNode;
import org.angle3d.material.sgsl.node.SgslNode;

class SgslParser
{
	private var _tokens:Array<Token>;
	private var _tokenCount:Int;
	private var _position:Int;

	public function new() 
	{
	}
	
	public function exec(source:String):ProgramNode
	{
		_tokens = new Tokenizer().parse(source);
		_tokenCount = _tokens.length;
		_position = 0;

		var programNode:ProgramNode = new ProgramNode();
		parseProgram(programNode);
		return programNode;
	}
	
	public function execFunctions(source:String, define:Vector<String>):ProgramNode
	{
		_tokens = new Tokenizer().parse(source);
		_tokenCount = _tokens.length;
		_position = 0;

		var programNode:ProgramNode = new ProgramNode();
		while (getToken().type != TokenType.EOF)
		{
			if (getToken().type == TokenType.PREPROCESOR)
			{
				programNode.addChild(parsePredefine(false));
			}
			else if(getToken().type == TokenType.DATATYPE && getToken(1).text == "function")
			{
				programNode.addChild(parseFunction());
			}
			else if (getToken().text == ";")
			{
				acceptText(";");
			}
			else
			{
				error(getToken(), "dont support " + getToken().text);
			}
		}

		programNode.filter(define);
		
		return programNode;
	}
	
	/**
	 * program = { function | condition | shader_var };  至少包含一个main function
	 */
	private function parseProgram(program:SgslNode):Void
	{
		while (getToken().type != TokenType.EOF)
		{
			if (getToken().type == TokenType.PREPROCESOR)
			{
				program.addChild(parsePredefine(false));
			}
			else if(getToken().type == TokenType.DATATYPE && getToken(1).text == "function")
			{
				program.addChild(parseFunction());
			}
			else if(getToken().type == TokenType.REGISTERTYPE)
			{
				program.addChild(parseShaderVar());
			}
			else if (getToken().text == ";")
			{
				acceptText(";");
			}
			else
			{
				#if debug
				var token:Token = getToken();
				var nextoken:Token = getToken(1);
				error(token, "dont support " + token.text);
				#end
			}
		}
	}
	
	/**
	 * function = 'function' Identifier '(' [declaration {',' declaration}]  ')' block;
	 */
	private function parseFunction():FunctionNode
	{
		//datatype
		var dataType:String = accept(TokenType.DATATYPE).text;

		// SKIP 'function'
		acceptText("function");

		var fn:FunctionNode = new FunctionNode(accept(TokenType.WORD).text,dataType);

		//SKIP '('
		acceptText("(");

		//参数部分
		if (getToken().text != ")")
		{
			fn.addParam(parseFunctionParams());

			while (getToken().text != ")")
			{
				//SKIP ','
				acceptText(",");
				fn.addParam(parseFunctionParams());
			}
		}

		//SKIP ')'
		acceptText(")");

		//解析块  {...}
		parseBlock(fn, true);

		return fn;
	}
	
	/**
	 * 
	 * @param	parent
	 * @param	isFunction 是否在方法内部
	 */
	private function parseBlock(parent:SgslNode, isInsideFunction:Bool):Void
	{
		// skip '{'
		acceptText("{");

		while (getToken().text != "}")
		{
			parseStatement(parent,isInsideFunction);
		}

		// skip '}'
		acceptText("}");
	}
	
	private static var CompareOperations:Array<String> = [">", "<", ">=", "<=", "==", "!="];
	
	/**
	 * if(...) {...}
	 * 目前不支持elseif
	 * @param	ifNode
	 */
	private function parseIfCondition(parent:SgslNode):Void
	{
		var ifConditionNode:ConditionIfNode = new ConditionIfNode();

		acceptText("if");
		acceptText("(");

		ifConditionNode.addChild(parseExpression());

		// > < >= <= != ==
		ifConditionNode.compareMethod = getToken().text;
		
		#if debug
		if (CompareOperations.indexOf(getToken().text) == -1)
		{
			error(getToken(), "condition only support [>,<,>=,<=], but is : " + getToken().text);
		}
		#end
		
		//skip compareMethod
		accept(TokenType.OPERATOR);

		ifConditionNode.addChild(parseExpression());
		
		parent.addChild(ifConditionNode);

		acceptText(")");

		//解析块  {...}
		parseBlock(ifConditionNode, true);
		
		//查找ELSE
		if (getToken().text == "else")
		{
			acceptText("else");
			
			var elseConditionNode:ConditionElseNode = new ConditionElseNode();
			parent.addChild(elseConditionNode);

			//解析块  {...}
			parseBlock(elseConditionNode, true);
		}

		var conditionEndNode:ConditionEndNode = new ConditionEndNode();
		parent.addChild(conditionEndNode);
	}
	
	/**
	 * 表达式
	 * statement     = (declaration | assignment | function_call) ';';
	 * declaration   = Type Identifier;
	 * assignment    = [declaration | Identifier] '=|*=|+=|/=|-=' expression;
	 * function_call = Identifier '(' [expression] {',' expression} ')';
	 * 
	 * vec3 pos;
	 * vec3 pos.x = a_pos.x;
	 * pos.x = a_pos.x;
	 */
	private function parseStatement(parent:SgslNode,isInsideFunction:Bool):Void
	{
		var type:String = getToken().type;
		
		if (type == TokenType.EOF)
		{
			error(getToken(), "Unexpected end of file, missing end of block '}'");
			return;
		}
		
		if (!isInsideFunction && type == TokenType.REGISTERTYPE)
		{
			parent.addChild(parseShaderVar());
			return;
		}
		
		if (type == TokenType.PREPROCESOR)
		{
			parent.addChild(parsePredefine(isInsideFunction));
			return;
		}
		
		if (type == TokenType.DATATYPE)
		{
			//如果在function 内部，则不能在内部定义function
			var nextToken:Token = getToken(1);
			if (!isInsideFunction && nextToken.text == "function")
			{
				parent.addChild(parseFunction());
				return;
			}

			var declarName:String = getToken(1).text;

			parent.addChild(parseTempVar());
			
			if (getToken().text != ";")
			{
				var destNode:AtomNode = new AtomNode(declarName);
			
				if (getToken().text == ".")
				{
					parseMask(destNode);
				}
				
				var assignNode:AssignNode = parseAssignNode(destNode);

				parent.addChild(assignNode);
			}
		}
		else if (getToken().text == "if")
		{
			parseIfCondition(parent);
			return;
		}
		else if (getToken().text == "return")
		{
			parent.addChild(parseReturn());
			return;
		}
		else if(getToken().type == TokenType.WORD)
		{
			if (getToken(1).text == ".") // v0.x = ...;
			{
				var destNode:AtomNode = new AtomNode(accept(TokenType.WORD).text);
				parseMask(destNode);
				
				var assignNode:AssignNode = parseAssignNode(destNode);
				
				parent.addChild(assignNode);
			}
			else if (getToken(1).text == "[") // v0[1] = ...;
			{
				var destNode:ArrayAccessNode = new ArrayAccessNode(accept(TokenType.WORD).text);

				acceptText("["); // SKIP '['

				//此时只能是常数
				if (getToken().text != "]")
				{
					destNode.offset = Std.parseInt(accept(TokenType.NUMBER).text);
				}
				
				acceptText("]"); // SKIP ']'

				//.xyz
				if (getToken().text == ".")
				{
					parseMask(destNode);
				}
				
				var assignNode:AssignNode = new AssignNode();
				assignNode.addChild(destNode);
				
				acceptText("=");
				
				//表达式
				assignNode.addChild(parseExpression());
				
				parent.addChild(assignNode);
			}
			else if (getToken(1).text == "=" || 
					getToken(1).text == "*=" ||
					getToken(1).text == "/=" ||
					getToken(1).text == "+=" ||
					getToken(1).text == "-=" ||
					getToken(1).text == "++" ||
					getToken(1).text == "--") //v0 = ...;
			{
				if (getToken().type == TokenType.NUMBER)
				{
					error(getToken(), "dest cant be number");
				}
				
				var destNode:AtomNode = new AtomNode(accept(TokenType.WORD).text);

				var assignNode:AssignNode = parseAssignNode(destNode);
				
				parent.addChild(assignNode);
			}
			else if (getToken(1).text == "(") //max(...);
			{
				parent.addChild(parseFunctionCall());
			}
			else
			{
				error(getToken(), "Unsupport token: " + getToken().text);
			}
		}
		else
		{
			error(getToken(), "Unsupport token: " + getToken().text);
		}
		
		acceptText(";");
	}
	
	/**
	 * 赋值语句后面有多种情况
	 * 1、后面只有++,--
	 * 2、+=exp,-=exp,*=exp,/=exp;
	 * 3、=exp
	 * @param	destNode
	 * @return
	 */
	private function parseAssignNode(destNode:AtomNode):AssignNode
	{
		var assignNode:AssignNode = new AssignNode();
		assignNode.addChild(destNode);
		
		//后面可能是++,--,-=,+=,*=,/=,=...
		if (getToken().text == "++")
		{
			acceptText("++"); // SKIP "++"
			
			var opNode:OpNode = new OpNode(NodeType.ADD,"+");
			opNode.addChild(destNode.clone());
			opNode.addChild(new NumberNode(1));
			
			assignNode.addChild(opNode);
		}
		else if (getToken().text == "--")
		{
			acceptText("--"); // SKIP "--"
			
			var opNode:OpNode = new OpNode(NodeType.SUBTRACT,"-");
			opNode.addChild(destNode.clone());
			opNode.addChild(new NumberNode(1));
			
			assignNode.addChild(opNode);
		}
		else if (getToken().text == "*=")
		{
			acceptText("*="); // SKIP "*="

			var rightExp:LeafNode = parseExpression();
			
			var opNode:OpNode = new OpNode(NodeType.MULTIPLTY,"*");
			opNode.addChild(destNode.clone());
			opNode.addChild(rightExp);
			
			assignNode.addChild(opNode);
		}
		else if (getToken().text == "/=")
		{
			acceptText("/="); // SKIP "/="

			var rightExp:LeafNode = parseExpression();
			
			var opNode:OpNode = new OpNode(NodeType.DIVIDE,"/");
			opNode.addChild(destNode.clone());
			opNode.addChild(rightExp);
			
			assignNode.addChild(opNode);
		}
		else if (getToken().text == "+=")
		{
			acceptText("+="); // SKIP "+="

			var rightExp:LeafNode = parseExpression();
			
			var opNode:OpNode = new OpNode(NodeType.ADD,"+");
			opNode.addChild(destNode.clone());
			opNode.addChild(rightExp);
			
			assignNode.addChild(opNode);
		}
		else if (getToken().text == "-=")
		{
			acceptText("-="); // SKIP "-="

			var rightExp:LeafNode = parseExpression();
			
			var opNode:OpNode = new OpNode(NodeType.SUBTRACT,"-");
			opNode.addChild(destNode.clone());
			opNode.addChild(rightExp);
			
			assignNode.addChild(opNode);
		}
		else
		{
			acceptText("=");
		
			//表达式
			assignNode.addChild(parseExpression());
		}
		
		return assignNode;
	}
	
	/**
	 * 方法调用
	 * function_call = Identifier '(' [expression] {',' expression} ')';
	 */
	private function parseFunctionCall():FunctionCallNode
	{
		var bn:FunctionCallNode = new FunctionCallNode(accept(TokenType.WORD).text);

		acceptText("("); // SKIP '('

		while (getToken().text != ")")
		{
			bn.addChild(parseExpression());

			if (getToken().text == ",")
				acceptText(","); // SKIP ','
		}

		acceptText(")"); // SKIP ')'
		
		if (getToken().text == ".")
		{
			parseMask(bn);
		}

		return bn;
	}
	
	/**
	 * 临时变量定义,函数内部定义的变量(都是临时变量)
	 */
	private function parseTempVar():RegNode
	{
		var dataType:String = accept(TokenType.DATATYPE).text;
		var name:String = accept(TokenType.WORD).text;

		return RegFactory.create(name, RegType.TEMP, dataType);
	}
	
	private function parseExpression():LeafNode
	{
		return parseAddExpression();
	}
	
	private function parseAddExpression():LeafNode
	{
		var ret:LeafNode = parseMulExpression();
		while (true)
		{
			var bn:OpNode;
			if (getToken().text == "+")
			{
				bn = new OpNode(NodeType.ADD,"+");
			}
			else if (getToken().text == "-")
			{
				bn = new OpNode(NodeType.SUBTRACT,"-");
			}
			else
				return ret;
	
			accept(TokenType.OPERATOR);// SKIP '+' or '-'
			
			bn.addChild(ret);
			bn.addChild(parseMulExpression());
			
			ret = bn;
		}
		return ret;
	}
	
	private function parseMulExpression():LeafNode
	{
		var ret:LeafNode = parseUnaryExpression();
		while (true)
		{
			var bn:OpNode;
			if (getToken().text == "*")
			{
				bn = new OpNode(NodeType.MULTIPLTY,"*");
			}
			else if (getToken().text == "/")
			{
				bn = new OpNode(NodeType.DIVIDE,"/");
			}
			else
				return ret;
	
			accept(TokenType.OPERATOR);// SKIP '*' or '/'
			
			bn.addChild(ret);
			bn.addChild(parseUnaryExpression());

			ret = bn;
		}
		return ret;
	}
	
	private function parseUnaryExpression():LeafNode
	{
		if (getToken().text != "-")
		{
			return parseAtomExpression();
		}
			
		accept(TokenType.OPERATOR);// SKIP '-'
		
		//-100
		if (getToken().type == TokenType.NUMBER)
		{
			var num:Float = -Std.parseFloat(accept(TokenType.NUMBER).text);
			return new NumberNode(num);
		}
		
		var bn:FunctionCallNode = new FunctionCallNode("neg");
		bn.addChild(parseAtomExpression());
		return bn;
	}
	
	/**
	 *  abc
	 *  abc.rgb
	 *  abc[d.rgb+3]
	 *  abc[d.rgb+3].xyzw
	 *  100
	 * 	100.01
	 *
	 * @return
	 *
	 */
	private function parseAtomExpression():LeafNode
	{
		var ret:LeafNode = null;
		
		var token:Token = getToken();
		
		if (token.type == TokenType.WORD)
		{
			if (getToken(1).text == "(")
			{
				ret = parseFunctionCall();
			}
			else if (getToken(1).text == ".")
			{
				ret = parseDotExpression();
			}
			else if (getToken(1).text == "[")
			{
				ret = parseBracketExpression();
			}
			else
			{
				ret = new AtomNode(accept(TokenType.WORD).text);
			}
		}
		else if (token.type == TokenType.NUMBER)
		{
			ret = new NumberNode(Std.parseFloat(accept(TokenType.NUMBER).text));
		}
		else if (token.text == "(")
		{
			acceptText("(");
			var node:LeafNode = parseAddExpression();
			acceptText(")");
			
			if (getToken().text == ".")
			{
				parseMask(node);
			}
			
			ret = node;
		}
		else
		{
			error(token, "Unsupport token: " + token.text);
		}
		
		return ret;
	}
	
	/**
	 * mat[(t2.x-t3.x)+t5.w-10+t6.y].xyz
	 */
	private function parseBracketExpression():LeafNode
	{
		var bn:ArrayAccessNode = new ArrayAccessNode(accept(TokenType.WORD).text);

		acceptText("["); // SKIP '['

		if (getToken().text != "]")
		{
			bn.addChild(parseExpression());
		}
		
		if (bn.numChildren == 1)
		{
			var child:LeafNode = bn.children[0];
			if (Std.is(child, OpNode) && child.name == "+")
			{
				var opNode:OpNode = cast child;
				
				if (opNode.children[1].type == NodeType.NUMBER)
				{
					bn.offset = Std.int(cast(opNode.children[1], NumberNode).value);
					bn.setChildAt(opNode.children[0], 0);
				}
				else if (opNode.children[0].type == NodeType.NUMBER)
				{
					bn.offset = Std.int(cast(opNode.children[0], NumberNode).value);
					bn.setChildAt(opNode.children[1], 0);
				}
			}
			else if (Std.is(child, NumberNode))
			{
				bn.offset = Std.int(cast(child, NumberNode).value);
				bn.removeAllChildren();
			}
		}
		
		

		acceptText("]"); // SKIP ']'

		//.xyz
		if (getToken().text == ".")
		{
			parseMask(bn);
		}

		return bn;
	}
	
	private static var MASKWORD:String = "rgbaxyzw";
	private function parseDotExpression():AtomNode
	{
		var bn:AtomNode = new AtomNode(accept(TokenType.WORD).text);

		parseMask(bn);

		return bn;
	}
	
	private function parseMask(parent:LeafNode):Void
	{
		if (getToken().text == ".")
		{
			acceptText(".");
			
			parent.mask = accept(TokenType.WORD).text;
			
			#if debug
			if (parent.mask.length > 4)
			{
				error(getToken(), "mask max size is 4, but is:" + parent.mask.length);
			}
			
			for (i in 0...parent.mask.length)
			{
				var char:String = parent.mask.charAt(i);
				
				if (MASKWORD.indexOf(char) == -1)
				{
					error(getToken(), "mask char dont support: " + char);
				}
			}
			#end
		}
	}
	
	private function parseReturn():LeafNode
	{
		acceptText("return"); //SKIP "return"

		var node:ReturnNode = new ReturnNode();
		node.addChild(parseExpression());

		acceptText(";"); //SKIP ";"

		return node;
	}
	
	private function parseFunctionParams():ParameterNode
	{
		var dataType:String = accept(TokenType.DATATYPE).text;
		
		#if debug
		if (dataType == "void")
		{
			error(getToken(), "Function param dataType cant be void");
		}
		#end
		
		var name:String = accept(TokenType.WORD).text;
		return new ParameterNode(dataType, name);
	}
	
	private function parsePredefine(isInsideFunction:Bool):LeafNode
	{
		var condition:PredefineNode = new PredefineNode();

		condition.addChild(parseSubPredefine(isInsideFunction));

		//接下来一个也是条件，并且不是新的条件，而是之前条件的延续
		//#else || #elseif
		//TODO 需要判断之后是否有多个else
		while (getToken().type == TokenType.PREPROCESOR && 
			  (getToken().text != PredefineType.IFDEF && getToken().text != PredefineType.IFNDEF))
		{
			condition.addChild(parseSubPredefine(isInsideFunction));
		}

		return condition;
	}

	/**
	 * 一个条件中的分支条件
	 * @param condition
	 * @param parent
	 *
	 */
	private function parseSubPredefine(isInsideFunction:Bool):PredefineSubNode
	{
		var predefine:Token = getToken();

		var subNode:PredefineSubNode = new PredefineSubNode(predefine.text);

		accept(TokenType.PREPROCESOR); //SKIP '#ifdef'

		if (subNode.hasParam())
		{
			acceptText("("); //SKIP '('

			//至少有一个参数
			subNode.addKeyword(accept(TokenType.WORD).text);

			//剩余参数
			if (getToken().text != ")")
			{
				while (getToken().text != ")")
				{
					if (getToken().text == "&&")
					{
						subNode.addKeyword(accept(TokenType.OPERATOR).text);
					}
					else if (getToken().text == "||")
					{
						subNode.addKeyword(accept(TokenType.OPERATOR).text);
					}
					else
					{
						error(getToken(), "PREPROCESOR only support || or && operation,but is" + getToken().text);
					}

					subNode.addKeyword(accept(TokenType.WORD).text);
				}
			}

			acceptText(")"); //SKIP ')'
		}

		//解析块  {...}
		parseBlock(subNode, isInsideFunction);

		return subNode;
	}
	
	/**
	 * shader_var = Specifier Type Identifier (Identifier)|[Number] ';';
	 */
	private static var RegisterTypes:Array<String> = ["attribute", "varying", "uniform"];
	private function parseShaderVar():LeafNode
	{
		#if debug
		if (getToken().type != TokenType.REGISTERTYPE)
		{
			error(getToken(), "Shader Var should be define a RegisterType, but is " + getToken().text);
		}
		
		if (RegisterTypes.indexOf(getToken().text) == -1)
		{
			error(getToken(), "RegisterType should be one of [attribute,varying,uniform],but is " + getToken().text);
		}
		#end
		
		var registerType:String = accept(TokenType.REGISTERTYPE).text;
		
		var dataType:String = accept(TokenType.DATATYPE).text;
		
		//check dataType
		#if debug
		switch(registerType)
		{
			case "attribute":
				if (dataType != "float" && dataType != "vec2" && dataType != "vec3" && dataType != "vec4")
				{
					error(getToken(), "Attribute dataType only support [float,vec2,vec3,vec4],but is " + dataType);
				}
			case "uniform":
				if (dataType == "void")
				{
					error(getToken(), "Uniform dataType dont support void");
				}
			case "varying":
				//if (dataType != "vec4")
				//{
					//error(getToken(), "Varying dataType only support vec4, but is " + dataType);
				//}
		}
		#end
		
		var name:String = accept(TokenType.WORD).text;

		//只有uniform可以使用数组定义，并且数组大小必须一开始就定义好
		var arraySize:Int = 1;
		if (getToken().text == "[")
		{
			#if debug
			if (registerType != "uniform")
			{
				error(getToken(), "Only Uniform support array access");
			}
			#end
			
			acceptText("["); //Skip "["
			
			#if debug
			if (getToken().type != TokenType.NUMBER)
			{
				error(getToken(), "Array size only support const value, but is :" + getToken().text);
			}
			
			if (getToken().text.indexOf(".") != -1)
			{
				error(getToken(), "Array index should be Int, but is :" + Std.parseFloat(getToken().text));
			}
			#end
			
			arraySize = Std.parseInt(accept(TokenType.NUMBER).text);
			
			acceptText("]"); //Skip "]"
		}
		
		//uniform绑定或者顶点数据类型
		var bindName:String = "";
		if (getToken().text == "(")
		{
			acceptText("(");
			bindName = accept(TokenType.WORD).text;
			acceptText(")");
		}

		// skip ';'
		acceptText(";");

		return RegFactory.create(name, registerType, dataType, bindName, arraySize);
	}
	
	private inline function getToken(offset:Int = 0):Token
	{
		if (_position + offset < _tokenCount)
		{
			return _tokens[_position + offset];
		}
		else
		{
			return null;
		}
	}
	
	private inline function accept(type:String):Token
	{
		var token:Token = getToken();
		
		#if debug
		if (token.type != type)
		{
			error(token, "type should be " + type + ",but is " + token.type);
		}
		#end
		
		_position++;
		
		return token;
	}
	
	private inline function acceptText(text:String):Token
	{
		var token:Token = getToken();
		
		#if debug
		if (token.text != text)
		{
 			error(token, "text should be " + text + ",but is " + token.text);
		}
		#end
		
		_position++;
		
		return token;
	}
	
	private inline function error(t:Token, message:String) : Void
	{
		throw "Line: " + t.line + " col: " + t.position + " - " + message;
	}
	
}