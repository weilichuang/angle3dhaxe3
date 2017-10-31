package org.angle3d.material.sgsl.pool;


import org.angle3d.material.sgsl.node.reg.RegNode;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.material.shader.ShaderType;

using org.angle3d.utils.VectorUtil;
/**
 * 寄存器池
 
 */
class RegPool
{
	private var mRegLimit:Int;

	private var mProfile:ShaderProfile;
	private var shaderType:ShaderType;

	private var mRegs:Vector<RegNode>;
	
	private var agalVersion:Int = 1;

	public function new(profile:ShaderProfile, shaderType:ShaderType)
	{
		this.mProfile = profile;
		agalVersion = (Std.string(profile) == "standard") ? 0x2 : 0x1;
		
		this.shaderType = shaderType;

		mRegLimit = getRegLimit();
		mRegs = new Vector<RegNode>();
	}

	private function getRegLimit():Int
	{
		return 0;
	}

	public function setProfile(value:ShaderProfile):Void
	{
		mProfile = value;
	}

	public function addReg(value:RegNode):Void
	{
		if (!mRegs.contain(value))
		{
			mRegs.push(value);
		}
	}

	public function getRegs():Vector<RegNode>
	{
		return mRegs;
	}

	public function clear():Void
	{
		mRegs.length = 0;
	}

	public function build():Void
	{
		var count:Int = mRegs.length;
		for (i in 0...count)
		{
			register(mRegs[i]);
		}
	}

	/**
	 * 注册寄存器位置
	 * @param value
	 */
	public function register(node:RegNode):Void
	{

	}

	/**
	 * 注销
	 * @param value
	 */
	public function release(node:RegNode):Void
	{

	}
}
