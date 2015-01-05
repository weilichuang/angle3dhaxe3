package org.angle3d.material.sgsl.node;

import flash.Vector;
using org.angle3d.utils.ArrayUtil;

class PredefineSubNode extends SgslNode
{
	private var _keywords:Array<String>;

	private var _arrangeList:Array<Array<String>>;

	public function new(name:String)
	{
		super(NodeType.PREPROCESOR,name);

		_keywords = new Array<String>();
	}
	
	public function hasParam():Bool
	{
		return name == PredefineType.IFDEF ||
			name == PredefineType.IFNDEF || 
			name == PredefineType.ELSEIF;
	}

	override public function clone():LeafNode
	{
		var node:PredefineSubNode = new PredefineSubNode(name);
		node._keywords = _keywords.slice(0);

		cloneChildren(node);

		return node;
	}

	/**
	 * 整理分类keywords，根据'||'划分为多个数组
	 */
	private function arrangeKeywords():Void
	{
		if (_arrangeList != null)
			return;

		_arrangeList = new Array<Array<String>>();

		_arrangeList[0] = new Array<String>();
		_arrangeList[0].push(_keywords[0]);

		var length:Int = _keywords.length;
		for (i in 1...length)
		{
			if (_keywords[i] == "||")
			{
				_arrangeList[_arrangeList.length] = new Array<String>();
			}
			else if (_keywords[i] != "&&")
			{
				_arrangeList[_arrangeList.length - 1].push(_keywords[i]);
			}
		}
	}

	public function isMatch(defines:Array<String>):Bool
	{
		//到达这里时必定符合条件
		if (name == PredefineType.ELSE)
		{
			return true;
		}

		arrangeKeywords();
		
		var invert:Bool = false;
		if (name == PredefineType.IFNDEF)
		{
			invert = true;
		}

		var length:Int = _arrangeList.length;
		for (i in 0...length)
		{
			if (matchDefines(defines, _arrangeList[i], invert))
			{
				return true;
			}
		}

		return false;
	}

	/**
	 * conditions是否包含了所有list中的字符串
	 * @param defines 条件
	 * @param conditions
	 * @param invert
	 * @return
	 *
	 */
	private function matchDefines(defines:Array<String>, conditions:Array<String>, invert:Bool = false):Bool
	{
		if (defines.length == 0)
			return invert;
			
		var length:Int = conditions.length;
		for (i in 0...length)
		{
			if (!defines.contains(conditions[i]))
			{
				return invert;
			}
		}
		return !invert;
	}

	public function addKeyword(value:String):Void
	{
		_keywords.push(value);
	}

	override public function toString(level:Int = 0):String
	{
		var result:String = "";

		result += getSelfString(level);
		var space:String = getSpace(level);
		result += space + "{\n";
		result += getChildrenString(level);
		result += space + "}\n";
		return result;
	}

	private function getSelfString(level:Int):String
	{
		var result:String = "";

		result += getSpace(level) + name;

		if (name != PredefineType.ELSE)
		{
			result += "(" + _keywords.join(" ") + ")";
		}

		result += "\n";

		return result;
	}
}

