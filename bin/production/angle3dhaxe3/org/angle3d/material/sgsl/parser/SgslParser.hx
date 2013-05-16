package org.angle3d.material.sgsl.parser;

import org.angle3d.material.sgsl.node.NodeType;
import org.angle3d.material.sgsl.RegType;
import org.angle3d.material.sgsl.error.UnexpectedTokenError;
import org.angle3d.material.sgsl.node.ArrayAccessNode;
import org.angle3d.material.sgsl.node.AtomNode;
import org.angle3d.material.sgsl.node.BranchNode;
import org.angle3d.material.sgsl.node.ConstantNode;
import org.angle3d.material.sgsl.node.FunctionCallNode;
import org.angle3d.material.sgsl.node.FunctionNode;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.node.ParameterNode;
import org.angle3d.material.sgsl.node.PredefineNode;
import org.angle3d.material.sgsl.node.PredefineSubNode;
import org.angle3d.material.sgsl.node.PredefineType;
import org.angle3d.material.sgsl.node.agal.AgalNode;
import org.angle3d.material.sgsl.node.agal.ConditionElseNode;
import org.angle3d.material.sgsl.node.agal.ConditionEndNode;
import org.angle3d.material.sgsl.node.agal.ConditionIfNode;
import org.angle3d.material.sgsl.node.reg.RegFactory;
import org.angle3d.material.sgsl.node.reg.RegNode;

import flash.Vector;

//TODO 添加更多的语法错误提示
//TODO 预定义部分是否应该提前排除
class SgslParser
{
	private var _tok:Tokenizer;

	public function new()
	{
	}

	public function exec(source:String):BranchNode
	{
		_tok = new Tokenizer(source);
		_tok.next();

		var programNode:BranchNode = new BranchNode();
		parseProgram(programNode);
		return programNode;
	}

	public function execFunctions(source:String, define:Array<String>):Array<FunctionNode>
	{
		_tok = new Tokenizer(source);
		_tok.next();

		var programNode:BranchNode = new BranchNode();
		while (_tok.token.type != TokenType.EOF)
		{
			if (_tok.token.type == TokenType.DATATYPE && _tok.nextToken.type == TokenType.FUNCTION)
			{
				programNode.addChild(parseFunction());
			}
			else if (_tok.token.type == TokenType.PREDEFINE)
			{
				programNode.addChild(parsePredefine());
			}
		}

		programNode.filter(define);

		var result:Array<FunctionNode> = new Array<FunctionNode>();
		for (i in 0...programNode.numChildren)
		{
			result.push(cast(programNode.children[i], FunctionNode));
		}

		return result;
	}

	/**
	 * program = { function | condition | shader_var };  至少包含一个main function
	 */
	private function parseProgram(program:BranchNode):Void
	{
		while (_tok.token.type != TokenType.EOF)
		{
			if (_tok.token.type == TokenType.DATATYPE && _tok.nextToken.type == TokenType.FUNCTION)
			{
				program.addChild(parseFunction());
			}
			else if (_tok.token.type == TokenType.PREDEFINE)
			{
				program.addChild(parsePredefine());
			}
			else
			{
				program.addChild(parseShaderVar());
			}
		}
	}

	/**
	 * #ifdef(...){
	 * }
	 * #elseif(...){
	 * }
	 * #else{
	 * }
	 *
	 * condition = '#ifdef || #elseif' '(' Identifier { "||" | "&&" } ")" || '#else' block;
	 */

	private function parsePredefine():PredefineNode
	{
		var condition:PredefineNode = new PredefineNode();

		condition.addChild(parseSubPredefine());

		//接下来一个也是条件，并且不是新的条件，而是之前条件的延续
		while (_tok.token.type == TokenType.PREDEFINE && _tok.token.name != PredefineType.IFDEF)
		{
			condition.addChild(parseSubPredefine());
		}

		return condition;
	}

	/**
	 * 一个条件中的分支条件
	 * @param condition
	 * @param parent
	 *
	 */
	private function parseSubPredefine():PredefineSubNode
	{
		var predefine:Token = _tok.token;

		var subNode:PredefineSubNode = new PredefineSubNode(predefine.name);

		_tok.accept(TokenType.PREDEFINE); //SKIP '#ifdef'

		if (subNode.name == PredefineType.IFDEF || subNode.name == PredefineType.ELSEIF)
		{
			_tok.accept(TokenType.LPAREN); //SKIP '('

			//至少有一个参数
			subNode.addKeyword(_tok.accept(TokenType.IDENTIFIER).name);

			//剩余参数
			if (_tok.token.type != TokenType.RPAREN)
			{
				while (_tok.token.type != TokenType.RPAREN)
				{
					if (_tok.token.type == TokenType.AND)
					{
						// &&
						subNode.addKeyword(_tok.accept(TokenType.AND).name);
					}
					else
					{
						// ||
						subNode.addKeyword(_tok.accept(TokenType.OR).name);
					}

					subNode.addKeyword(_tok.accept(TokenType.IDENTIFIER).name);
				}
			}

			_tok.accept(TokenType.RPAREN); //SKIP ')'
		}

		//解析块  {...}
		// skip '{'
		_tok.accept(TokenType.LBRACE);

		while (_tok.token.type != TokenType.RBRACE)
		{
			var t:Token = _tok.token;
			if (t.type == TokenType.REGISTER)
			{
				subNode.addChild(parseShaderVar());
			}
			else if (t.type == TokenType.DATATYPE && _tok.nextToken.type == TokenType.FUNCTION)
			{
				subNode.addChild(parseFunction());
			}
			else if (t.type == TokenType.PREDEFINE)
			{
				subNode.addChild(parsePredefine());
			}
			else
			{
				parseStatement(subNode);
			}
		}

		// skip '}'
		_tok.accept(TokenType.RBRACE);

		return subNode;
	}

	/**
	 * function = 'function' Identifier '(' [declaration {',' declaration}]  ')' block;
	 */
	private function parseFunction():FunctionNode
	{
		var fn:FunctionNode = new FunctionNode();

		//datatype
		fn.dataType = _tok.accept(TokenType.DATATYPE).name;

		// SKIP 'function'
		_tok.accept(TokenType.FUNCTION);

		fn.name = _tok.accept(TokenType.IDENTIFIER).name;

		//SKIP '('
		_tok.accept(TokenType.LPAREN);

		//参数部分
		if (_tok.token.type != TokenType.RPAREN)
		{
			fn.addParam(parseFunctionParams());

			while (_tok.token.type != TokenType.RPAREN)
			{
				//SKIP ','
				_tok.accept(TokenType.COMMA);
				fn.addParam(parseFunctionParams());
			}
		}

		//SKIP ')'
		_tok.accept(TokenType.RPAREN);

		//解析块  {...}
		// skip '{'
		_tok.accept(TokenType.LBRACE);

		while (_tok.token.type != TokenType.RBRACE)
		{
			var type:String = _tok.token.type;
			if (type == TokenType.PREDEFINE)
			{
				fn.addChild(parsePredefine());
			}
			else if (type == TokenType.IF)
			{
				parseIfCondition(fn);
			}
			else if (type == TokenType.RETURN)
			{
				fn.returnNode = parseReturn();
			}
			else
			{
				parseStatement(fn);
			}
		}

		// skip '}'
		_tok.accept(TokenType.RBRACE);

		return fn;
	}

	private function parseIfCondition(parent:BranchNode):Void
	{
		var conditionToken:Token = _tok.token;
		var ifConditionNode:ConditionIfNode = new ConditionIfNode(conditionToken.name);

		_tok.accept(TokenType.IF);
		_tok.accept(TokenType.LPAREN);

		var leftNode:LeafNode = parseAtomExpression();
		ifConditionNode.addChild(leftNode);

		// > < >= ...
		ifConditionNode.compareMethod = _tok.token.name;
		//skip compareMethod
		_tok.next();

		var rightNode:LeafNode = parseAtomExpression();
		ifConditionNode.addChild(rightNode);

		parent.addChild(ifConditionNode);

		_tok.accept(TokenType.RPAREN);

		//解析块  {...}
		// skip '{'
		_tok.accept(TokenType.LBRACE);

		while (_tok.token.type != TokenType.RBRACE)
		{
			var type:String = _tok.token.type;
			if (type == TokenType.PREDEFINE)
			{
				parent.addChild(parsePredefine());
			}
			else if (type == TokenType.IF)
			{
				parseIfCondition(parent);
			}
			//不应该出现这种情况
			else if (type == TokenType.RETURN)
			{
				//fn.result = parseReturn();
			}
			else
			{
				parseStatement(parent);
			}
		}

		// skip '}'
		_tok.accept(TokenType.RBRACE);

		//TODO 查找ELSE
		if (_tok.token.type == TokenType.ELSE)
		{
			parseElseCondition(parent);
		}

		var conditionEndNode:ConditionEndNode = new ConditionEndNode();
		parent.addChild(conditionEndNode);
	}

	/**
	 * else{...}
	 * @param	ifNode
	 */
	private function parseElseCondition(parent:BranchNode):Void
	{
		var conditionToken:Token = _tok.token;
		var elseConditionNode:ConditionElseNode = new ConditionElseNode();

		_tok.accept(TokenType.ELSE);

		//解析块  {...}
		// skip '{'
		_tok.accept(TokenType.LBRACE);

		while (_tok.token.type != TokenType.RBRACE)
		{
			var type:String = _tok.token.type;
			if (type == TokenType.PREDEFINE)
			{
				parent.addChild(parsePredefine());
			}
			else if (type == TokenType.IF)
			{
				parseIfCondition(parent);
			}
			//不应该出现这种情况
			else if (type == TokenType.RETURN)
			{
				//fn.result = parseReturn();
			}
			else
			{
				parseStatement(parent);
			}
		}

		// skip '}'
		_tok.accept(TokenType.RBRACE);
	}

	/**
	 * shader_var = Specifier Type Identifier ';';
	 */
	private function parseShaderVar():RegNode
	{
		var registerType:String = _tok.accept(TokenType.REGISTER).name;
		var dataType:String = _tok.accept(TokenType.DATATYPE).name;
		var name:String = _tok.accept(TokenType.IDENTIFIER).name;

		//只有uniform可以使用数组定义，并且数组大小必须一开始就定义好
		var arraySize:Int = 1;
		if (_tok.token.type == TokenType.LBRACKET)
		{
			_tok.accept(TokenType.LBRACKET); //Skip "["
			arraySize = Std.parseInt(_tok.accept(TokenType.NUMBER).name);
			_tok.accept(TokenType.RBRACKET); //Skip "]"
		}

		// skip ';'
		_tok.accept(TokenType.SEMI);

		return RegFactory.create(name, registerType, dataType, arraySize);
	}

	private function parseReturn():LeafNode
	{
		_tok.accept(TokenType.RETURN); //SKIP "return"

		var node:LeafNode = parseExpression();

		_tok.accept(TokenType.SEMI); //SKIP ";"

		return node;
	}

	/**
	 * 表达式
	 * statement     = (declaration | assignment | function_call) ';';
	 * declaration   = Type Identifier;
	 * assignment    = [declaration | Identifier] '=' expression;
	 * function_call = Identifier '(' [expression] {',' expression} ')';
	 */
	private function parseStatement(parent:BranchNode):Void
	{
		var statement:AgalNode;
		var t:String = _tok.token.type;
		//临时变量定义
		if (t == TokenType.DATATYPE)
		{
			var declarName:String = _tok.nextToken.name;

			parent.addChild(parseVarDeclaration());

			// plain declaration
			if (_tok.token.type != TokenType.SEMI)
			{
				statement = new AgalNode();

				statement.addChild(new AtomNode(declarName));

				_tok.accept(TokenType.EQUAL); // SKIP '='

				statement.addChild(parseExpression());

				parent.addChild(statement);
			}
		}
		else if (_tok.nextToken.type == TokenType.LPAREN)
		{
			// function call

			statement = new AgalNode();

			statement.addChild(parseFunctionCall());

			parent.addChild(statement);
		}
		else
		{
			statement = new AgalNode();

			//左侧的不能是方法调用，所以用parseAtomExpression
			statement.addChild(parseAtomExpression());

			_tok.accept(TokenType.EQUAL); // SKIP '='

			statement.addChild(parseExpression());

			parent.addChild(statement);
		}

		_tok.accept(TokenType.SEMI); //SKIP ";"
	}

	/**
	 *参数定义
	 */
	private function parseFunctionParams():ParameterNode
	{
		var dataType:String = _tok.accept(TokenType.DATATYPE).name;
		var name:String = _tok.accept(TokenType.IDENTIFIER).name;
		return new ParameterNode(dataType, name);
	}

	/**
	 * 临时变量定义,函数内部定义的变量(都是临时变量)
	 */
	private function parseVarDeclaration():RegNode
	{
		var dataType:String = _tok.accept(TokenType.DATATYPE).name;
		var name:String = _tok.accept(TokenType.IDENTIFIER).name;

		return RegFactory.create(name, RegType.TEMP, dataType);
	}

	/**
	 * 方法调用
	 * function_call = Identifier '(' [expression] {',' expression} ')';
	 */
	private function parseFunctionCall():FunctionCallNode
	{
		var bn:FunctionCallNode = new FunctionCallNode(_tok.accept(TokenType.IDENTIFIER).name);

		_tok.accept(TokenType.LPAREN); // SKIP '('

		while (_tok.token.type != TokenType.RPAREN)
		{
			//TODO 修改，目前不支持方法中嵌套方法
			//以后考虑支持嵌套
			//bn.addChild(parseExpression());

			bn.addChild(parseAtomExpression());

			if (_tok.token.type == TokenType.COMMA)
				_tok.next(); // SKIP ','
		}

		_tok.accept(TokenType.RPAREN); // SKIP ')'

		return bn;
	}

	/**
	 * expression  = Identifier | function_call | number_literal | Access | ArrayAccess;
	 */
	private function parseExpression():LeafNode
	{
		// a function call.
		if (_tok.token.type == TokenType.IDENTIFIER && _tok.nextToken.type == TokenType.LPAREN)
		{
			return parseFunctionCall();
		}
		else
		{
			return parseAtomExpression();
		}
	}
	
	private function parseAddExpression():LeafNode
	{
		var node:LeafNode = parseMulExpression();
		while (true)
		{
			var newNode:BranchNode;
			if (_tok.token.type == TokenType.PLUS)
			{
				newNode = new BranchNode();
				newNode.type = NodeType.ADD;
			}
			else if (_tok.token.type == TokenType.SUBTRACT)
			{
				newNode = new BranchNode();
				newNode.type = NodeType.SUBTRACT;
			}
			else
			{
				return node;
			}
			
			_tok.next();//skip '+' or '-'
			newNode.addChild(node);
			newNode.addChild(parseMulExpression());
			node = newNode;
		}
		
		return node;
	}
	
	private function parseMulExpression():LeafNode
	{
		var node:LeafNode = parseUnaryExpression();
		while (true)
		{
			var newNode:BranchNode;
			if (_tok.token.type == TokenType.MULTIPLY)
			{
				newNode = new BranchNode();
				newNode.type = NodeType.MULTIPLTY;
			}
			else if (_tok.token.type == TokenType.DIVIDE)
			{
				newNode = new BranchNode();
				newNode.type = NodeType.DIVIDE;
			}
			else
			{
				return node;
			}
			
			_tok.next();//skip '*' or '/'
			newNode.addChild(node);
			newNode.addChild(parseUnaryExpression());
			node = newNode;
		}
		
		return node;
	}
	
	/**
	 * -vt0.x
	 * @return
	 */
	private function parseUnaryExpression():LeafNode
	{
		if (_tok.token.type == TokenType.SUBTRACT)
		{
			var node:BranchNode = new BranchNode();
			node.type = NodeType.NEG;
			
			_tok.next();//skip '-'
			
			node.addChild(parseAtomExpression());
		}
		
		return parseAtomExpression();
	}

	/**
	 *  abc
	 *  abc.efg
	 *  abc[efg.rgb+3].xyzw
	 *
	 * @return
	 *
	 */
	private function parseAtomExpression():LeafNode
	{
		var ret:LeafNode;

		var type:String = _tok.token.type;
		if (type == TokenType.IDENTIFIER)
		{
			var pType:String = _tok.nextToken.type;

			if (pType == TokenType.LBRACKET)
			{
				//abc[efg]
				ret = parseBracketExpression();
			}
			else
			{
				// variable
				ret = parseDotExpression();
			}
		}
		// number literal
		else if (type == TokenType.NUMBER)
		{
			ret = new ConstantNode(Std.parseFloat(_tok.accept(TokenType.NUMBER).name));
		}
		else
		{
			throw new UnexpectedTokenError(_tok.token);
		}

		return ret;
	}

	private function parseDotExpression():AtomNode
	{
		var bn:AtomNode = new AtomNode(_tok.accept(TokenType.IDENTIFIER).name);

		if (_tok.token.type == TokenType.DOT)
		{
			_tok.next(); // SKIP 'dot'
			bn.mask = _tok.accept(TokenType.IDENTIFIER).name;
		}

		return bn;
	}

	/**
	 * 几种情况如下：
	 * [1]
	 * [vt0] 这种情况下vt0类型应该为float
	 * [vt0.x]
	 * [vt0.x+1]
	 * [1+vt0.x]
	 * [1+vt0]
	 */
	private function parseBracketExpression():ArrayAccessNode
	{
		var bn:ArrayAccessNode = new ArrayAccessNode(_tok.accept(TokenType.IDENTIFIER).name);

		_tok.accept(TokenType.LBRACKET); // SKIP '['

		//TODO 优化判断，目前这里不够精确
		if (_tok.token.type != TokenType.RBRACKET)
		{
			while (_tok.token.type != TokenType.RBRACKET)
			{
				if (_tok.token.type == TokenType.NUMBER)
				{
					bn.offset= Std.parseInt(_tok.accept(TokenType.NUMBER).name);
				}
				else if (_tok.token.type == TokenType.PLUS)
				{
					_tok.next(); // SKIP '+'
				}
				else
				{
					bn.access = parseDotExpression();
				}
			}
		}

		_tok.accept(TokenType.RBRACKET); // SKIP ']'

		//检查后面有没有.xyz
		if (_tok.token.type == TokenType.DOT)
		{
			_tok.next(); // SKIP "."
			bn.mask = _tok.accept(TokenType.IDENTIFIER).name;
		}

		return bn;
	}

	/**
	 * 这里判断名字为name的变量是否已经定义
	 */
	private function createAtomNode(name:String):AtomNode
	{
		var node:AtomNode = new AtomNode(name);
		return node;
	}

	private function createArrayAccessNode(name:String):ArrayAccessNode
	{
		var node:ArrayAccessNode = new ArrayAccessNode(name);
		return node;
	}
}


