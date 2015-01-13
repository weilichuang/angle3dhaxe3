package org.angle3d.material.sgsl;

/**
 * 操作符
 * @author weilichuang
 */
class OpCode
{
	public var emitCode:Int;
	public var flags:Int;
	public var numRegister:Int;

	public var names:Array<String>;

	/**
	 * 只能在Fragment中使用
	 * @return
	 */
	public var isFragOnly(get, null):Bool;
	
	public var isVersion2(get, null):Bool;

	/**
	 *
	 * @param	names 名称
	 * @param	numRegister 参数数量
	 * @param	emitCode
	 * @param	flags
	 */
	public function new(names:Array<String>, numRegister:Int, emitCode:Int, flags:Int)
	{
		this.names = names;
		this.numRegister = numRegister;
		this.emitCode = emitCode;
		this.flags = flags;
	}

	private function get_isFragOnly():Bool
	{
		return (flags & OpCodeManager.OP_FRAG_ONLY) != 0;
	}

	private function get_isVersion2():Bool
	{
		return (flags & OpCodeManager.OP_VERSION2) != 0;
	}
}

