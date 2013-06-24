package org.angle3d.material.shader;

import flash.display3D.Context3DVertexBufferFormat;

class AttributeList extends ShaderParamList
{
	public function new()
	{
		super();
	}

	/**
	 *
	 * @param	name
	 * @return
	 */
	private function getFormat(size:Int):Context3DVertexBufferFormat
	{
		switch (size)
		{
			case 1:
				return Context3DVertexBufferFormat.FLOAT_1;
			case 2:
				return Context3DVertexBufferFormat.FLOAT_2;
			case 3:
				return Context3DVertexBufferFormat.FLOAT_3;
			case 4:
				return Context3DVertexBufferFormat.FLOAT_4;
		}
		return null;
	}

	override public function build():Void
	{
		var att:AttributeParam;
		var offset:Int = 0;
		var length:Int = params.length;
		for (i in 0...length)
		{
			att = Std.instance(params[i], AttributeParam);
			att.index = i;
			att.location = offset;
			att.format = getFormat(att.size);
			offset+= att.size;
		}
	}
}

