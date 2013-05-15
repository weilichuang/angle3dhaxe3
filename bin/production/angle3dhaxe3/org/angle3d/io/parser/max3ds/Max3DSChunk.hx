package org.angle3d.io.parser.max3ds;

import flash.utils.ByteArray;

class Max3DSChunk
{
	public static inline var PRIMARY:Int = 0x4D4D;

	public static inline var SCENE:Int = 0x3D3D;
	public static inline var OBJECT:Int = 0x4000;

	public static inline var MESH:Int = 0x4100;
	public static inline var MESH_VERTICES:Int = 0x4110;
	public static inline var MESH_INDICES:Int = 0x4120;
	public static inline var MESH_MATERIAL:Int = 0x4130;
	public static inline var MESH_MAPPING:Int = 0x4140;
	public static inline var MESH_MATRIX:Int = 0x4160;

	public static inline var MATERIAL:Int = 0xAFFF;
	public static inline var MATERIAL_NAME:Int = 0xA000;
	public static inline var MATERIAL_TEXMAP:Int = 0xA200;
	public static inline var MATERIAL_MAPNAME:Int = 0xA300;

	private var _identifier:Int = 0;
	private var _length:Int = 0;
	private var _endOffset:Int = 0;
	private var _data:ByteArray = null;

	public function new(data:ByteArray)
	{
		_data = data;

		_endOffset = _data.position;

		_identifier = _data.readUnsignedShort();
		_length = _data.readUnsignedInt();

		_endOffset += _length;
	}
	
	public var identifier(get, null):Int;
	private function get_identifier():Int
	{
		return _identifier;
	}

	public var length(get, null):Int;
	private function get_length():Int
	{
		return _length;
	}

	public var data(get, null):ByteArray;
	public function get_data():ByteArray
	{
		return _data;
	}

	public var bytesAvailable(get, null):Int;
	public function get_bytesAvailable():Int
	{
		return _endOffset > Std.int(_data.position) ? _endOffset - _data.position : 0;
	}

	/**
	 * 跳过此Chunk
	 */
	public function skip():Void
	{
		_data.position += _length - 6;
	}

	public function readString():String
	{
		var result:String = "";
		var c:Int = 0;

		while ((c = _data.readByte()) != 0)
			result += String.fromCharCode(c);

		return (result);
	}
}
