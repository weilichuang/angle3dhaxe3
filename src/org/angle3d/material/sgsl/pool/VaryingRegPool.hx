package org.angle3d.material.sgsl.pool;

import org.angle3d.material.sgsl.DataType;
import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.material.shader.ShaderType;
import org.angle3d.error.Assert;


/**
 * 变化寄存器池
 
 */
class VaryingRegPool extends RegPool
{
	private var _pool:Vector<Int>;

	public function new(profile:ShaderProfile, shaderType:ShaderType)
	{
		super(profile,shaderType);

		_pool = new Vector<Int>(mRegLimit, true);
	}

	override private function getRegLimit():Int
	{
		switch(agalVersion)
		{
			case 1:
				return 8;
			case 2:
				return (mProfile == ShaderProfile.STANDARD) ? 10 : 8;
			case 3:
				return 10;
			default:
				return 8;
		}
	}

	override public function clear():Void
	{
		super.clear();

		for (i in 0...mRegLimit)
		{
			_pool[i] = 0;
		}
	}

	/**
	 * 设置tVar寄存器位置
	 * @param	tVar 对应的临时变量
	 */
	override public function register(node:RegNode):Void
	{
		Assert.assert(!node.registered, node.name + "不能注册多次");

		//TODO 应该尽量避免传递Mat4,Mat3，大部分情况下没必要
		var size:Int = DataType.getRegisterCount(node.dataType);
		for (i in 0...mRegLimit)
		{
			if (_pool[i] == 0)
			{
				node.index = i;
				for (j in 0...size)
				{
					_pool[i + j] = 1;
				}
				return;
			}
		}

		Assert.assert(false, "未能找到下一个空闲位置，寄存器已满");
	}
}

