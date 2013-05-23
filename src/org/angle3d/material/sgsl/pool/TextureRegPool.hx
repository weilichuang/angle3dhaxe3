package org.angle3d.material.sgsl.pool;


import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.utils.Assert;
import flash.Vector;
/**
 * 取样器寄存器池
 * @author andy
 */
class TextureRegPool extends RegPool
{
	private var _pool:Vector<Int>;

	public function new(profile:ShaderProfile)
	{
		super(profile);

		_pool = new Vector<Int>(mRegLimit, true);
	}

	override private function getRegLimit():Int
	{
		#if flash11_8
		if (mProfile == ShaderProfile.BASELINE_EXTENDED)
		{
			return 16;
		}
		#end
		if (mProfile == ShaderProfile.BASELINE)
		{
			return 8;
		}
		else
		{
			return 4;
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
	 * 设置value寄存器位置
	 * @param value 对应的临时变量
	 */
	override public function register(node:RegNode):Void
	{
		Assert.assert(!node.registered, node.name + "不能注册多次");
		
		for (i in 0...mRegLimit)
		{
			if (_pool[i] == 0)
			{
				node.index = i;
				_pool[i] = 1;
				return;
			}
		}

		Assert.assert(false, "未能找到下一个空闲位置，寄存器已满");
	}
}

