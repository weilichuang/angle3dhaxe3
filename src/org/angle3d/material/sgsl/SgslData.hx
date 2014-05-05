package org.angle3d.material.sgsl;

import flash.Lib;
import flash.Vector;
import haxe.ds.StringMap;
import org.angle3d.material.sgsl.node.agal.AgalNode;
import org.angle3d.material.sgsl.node.ArrayAccessNode;
import org.angle3d.material.sgsl.node.AtomNode;
import org.angle3d.material.sgsl.node.ConstantNode;
import org.angle3d.material.sgsl.node.FunctionCallNode;
import org.angle3d.material.sgsl.node.LeafNode;
import org.angle3d.material.sgsl.node.reg.DepthReg;
import org.angle3d.material.sgsl.node.reg.OutputReg;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.sgsl.node.reg.TempReg;
import org.angle3d.material.sgsl.node.reg.TextureReg;
import org.angle3d.material.sgsl.pool.AttributeRegPool;
import org.angle3d.material.sgsl.pool.TempRegPool;
import org.angle3d.material.sgsl.pool.TextureRegPool;
import org.angle3d.material.sgsl.pool.UniformRegPool;
import org.angle3d.material.sgsl.pool.VaryingRegPool;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.utils.Assert;


using org.angle3d.utils.ArrayUtil;
/**
 * andy
 * @author andy
 */
class SgslData
{
	/**
	 * Shader类型
	 */
	public var shaderType:ShaderType;

	public var profile:ShaderProfile;
	
	public var agalVersion:Int = 1;

	public var nodes(get, null):Array<AgalNode>;

	private var _nodes:Array<AgalNode>;

	public var attributePool:AttributeRegPool;
	public var uniformPool:UniformRegPool;
	public var varyingPool:VaryingRegPool;
	public var texturePool:TextureRegPool;

	private var _tempPool:TempRegPool;

	/**
	 * 所有变量的集合
	 */
	private var _regsMap:StringMap<RegNode>;

	public function new(profile:ShaderProfile, shaderType:ShaderType)
	{
		this.profile = profile;
		this.shaderType = shaderType;
		
		agalVersion = (Std.string(profile) == "standard") ? 0x2 : 0x1;

		_nodes = new Array<AgalNode>();

		_tempPool = new TempRegPool(this.profile,this.shaderType);
		uniformPool = new UniformRegPool(this.profile,this.shaderType);
		varyingPool = new VaryingRegPool(this.profile,this.shaderType);
		if (shaderType == ShaderType.VERTEX)
		{
			attributePool = new AttributeRegPool(this.profile,this.shaderType);
		}
		else
		{
			texturePool = new TextureRegPool(this.profile,this.shaderType);
		}

		_regsMap = new StringMap<RegNode>();

		regOutput();
	}

	private function regOutput():Void
	{
		var reg:OutputReg;
		if (shaderType == ShaderType.VERTEX)
		{
			reg = new OutputReg(0);
			_regsMap.set(reg.name, reg);
		}
		else
		{
			if (agalVersion == 2)
			{
				for(i in 0...4)
				{
					reg = new OutputReg(i);
					_regsMap.set(reg.name, reg);
				}

				var depth:DepthReg = new DepthReg();
				_regsMap.set(depth.name, depth);
			}
			else
			{
				reg = new OutputReg(0);
				_regsMap.set(reg.name, reg);
			}
		}
	}

	public function clear():Void
	{
		_nodes = [];

		_tempPool.clear();
		uniformPool.clear();
		if (shaderType == ShaderType.VERTEX)
		{
			attributePool.clear();
			varyingPool.clear();
		}
		else
		{
			texturePool.clear();
		}

		_regsMap = new StringMap<RegNode>();
		regOutput();
	}

	private function get_nodes():Array<AgalNode>
	{
		return _nodes;
	}

	public function addNode(node:AgalNode):Void
	{
		var reg:LeafNode;

		var children:Array<LeafNode> = node.children;
		var cLength:Int = children.length;
		for (i in 0...cLength)
		{
			reg = children[i];

			if (Std.is(reg,FunctionCallNode))
			{
				var callNode:FunctionCallNode = Std.instance(reg,FunctionCallNode);
				var regChildren:Array<LeafNode> = callNode.children;
				var rLength:Int = regChildren.length;
				var j:Int = 0;
				while(j < rLength && j < 2)
				{
					if (Std.is(regChildren[j], ConstantNode))
					{
						addConstantNode(Std.instance(regChildren[j], ConstantNode));
					}
					j++;
				}
			}
			else if (Std.is(reg, ConstantNode))
			{
				addConstantNode(Std.instance(reg, ConstantNode));
			}
		}

		_nodes.push(node);
	}

	private function addConstantNode(node:ConstantNode):Void
	{
		uniformPool.addConstant(node.value);
	}

	public function getConstantIndex(value:Float):Int
	{
		return uniformPool.getConstantIndex(value);
	}

	public function getConstantMask(value:Float):String
	{
		return uniformPool.getConstantMask(value);
	}

	/**
	 * 共享Varying数据
	 * @param	other
	 */
	public function shareWith(vertexData:SgslData):Void
	{
		#if debug
		Assert.assert(vertexData.shaderType == ShaderType.VERTEX, "vertexData类型应该为" + ShaderType.VERTEX);
		Assert.assert(shaderType == ShaderType.FRAGMENT, "shareWith只能在Fragment中调用");
		#end

		var pool:VaryingRegPool = vertexData.varyingPool;

		var regs:Vector<RegNode> = pool.getRegs();
		var count:Int = regs.length;
		for (i in 0...count)
		{
			addReg(regs[i]);
		}
	}

	/**
	 * 添加变量到对应的寄存器池中
	 * @param	value
	 */
	public function addReg(reg:RegNode):Void
	{
		//忽略output
		#if debug
			Assert.assert(reg != null, "变量不存在");
			Assert.assert(reg.regType != RegType.OUTPUT, "output不需要定义");
			Assert.assert(!_regsMap.exists(reg.name), reg.name + "变量名定义重复");

			if (reg.regType == RegType.ATTRIBUTE)
			{
				Assert.assert(shaderType == ShaderType.VERTEX, "AttributeParam只能定义在Vertex中");
			}
			else if (Std.is(reg,TextureReg))
			{
				Assert.assert(shaderType == ShaderType.FRAGMENT, "Texture只能定义在Fragment中");
			}
		#end

		switch (reg.regType)
		{
			case RegType.ATTRIBUTE:
				attributePool.addReg(reg);
			case RegType.TEMP:
				_tempPool.addReg(reg);
			case RegType.UNIFORM:
				if (Std.is(reg,TextureReg))
				{
					texturePool.addReg(reg);
				}
				else
				{
					uniformPool.addReg(reg);
				}
			case RegType.VARYING:
				varyingPool.addReg(reg);
			case RegType.OUTPUT, RegType.DEPTH:
				//do nothing
				Lib.trace(reg.name);
		}

		_regsMap.set(reg.name,reg);
	}

	/**
	 * 根据name获取对应的变量
	 * @param	name
	 * @return
	 */
	public inline function getRegNode(name:String):RegNode
	{
		return _regsMap.get(name);
	}

	/**
	 * 注册所有Reg，设置它们的位置
	 */
	public function build():Void
	{
		if (shaderType == ShaderType.VERTEX)
		{
			attributePool.build();
			varyingPool.build();
		}
		else
		{
			texturePool.build();
		}
		uniformPool.build();


		//添加所有临时变量到一个数组中
		var tempList:Array<TempReg> = _getAllTempRegs();
		_registerTempReg(tempList);
	}

	/**
	 * 递归注册和释放临时变量
	 * @param	list
	 */
	private function _registerTempReg(list:Array<TempReg>):Void
	{
		if (list.length > 0)
		{
			//取出第一个临时变量
			var reg:TempReg = list.shift();

			//未注册的需要注册
			if (!reg.registered)
			{
				_tempPool.register(reg);
			}

			//如果数组中剩余项不包含这个变量，也就代表无引用了
			if (!list.contain(reg))
			{
				//可以释放其占用位置
				_tempPool.logout(reg);
			}

			//递归锁定和释放，直到数组为空
			_registerTempReg(list);
		}
	}

	/**
	 * 获得所有临时变量引用
	 * @return
	 */
	private function _getAllTempRegs():Array<TempReg>
	{
		var tempList:Array<TempReg> = new Array<TempReg>();
		var tLength:Int = _nodes.length;
		for (i in 0...tLength)
		{
			tempList = tempList.concat(_checkNodeTempRegs(_nodes[i]));
		}
		return tempList;
	}

	private function _checkLeafTempReg(leaf:LeafNode, list:Array<TempReg>):Void
	{
		if (Std.is(leaf, ArrayAccessNode))
		{
			_addTempReg(leaf.name, list);

			var access:AtomNode = Std.instance(leaf,ArrayAccessNode).access;
			if (access != null)
			{
				_addTempReg(access.name, list);
			}
		}
		else
		{
			_addTempReg(leaf.name, list);
		}
	}

	private function _addTempReg(name:String, list:Array<TempReg>):Void
	{
		var reg:RegNode = getRegNode(name);
		if (Std.is(reg,TempReg))
		{
			list.push(Std.instance(reg, TempReg));
		}
	}

	/**
	 * 获得node所有的临时变量引用
	 * @return
	 */
	private function _checkNodeTempRegs(node:AgalNode):Array<TempReg>
	{
		var list:Array<TempReg> = new Array<TempReg>();

		var leaf:LeafNode;

		var children:Array<LeafNode> = node.children;
		var cLength:Int = children.length;
		for (i in 0...cLength)
		{
			leaf = children[i];
			if (Std.is(leaf,FunctionCallNode))
			{
				var callNode:FunctionCallNode = Std.instance(leaf,FunctionCallNode);
				var leafChildren:Array<LeafNode> = callNode.children;
				var rLength:Int = leafChildren.length;
				var j:Int = 0;
				while(j < rLength && j < 2)
				{
					_checkLeafTempReg(leafChildren[j], list);
					j++;
				}
			}
			else
			{
				_checkLeafTempReg(leaf, list);
			}
		}

		return list;
	}
}

