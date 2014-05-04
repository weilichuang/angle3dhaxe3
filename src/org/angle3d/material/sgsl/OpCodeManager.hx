package org.angle3d.material.sgsl;


import haxe.ds.StringMap;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.utils.Logger;


/**
 * mov	0x00	move	move data from source1 to destination, componentwise
 * add	0x01	add	destination = source1 + source2, componentwise
 * sub	0x02	subtract	destination = source1 - source2, componentwise
 * mul	0x03	multiply	destination = source1 * source2, componentwise
 * div	0x04	divide	destination = source1 / source2, componentwise
 * rcp	0x05	reciprocal	destination = 1/source1, componentwise
 * min	0x06	minimum	destination = minimum(source1,source2), componentwise
 * max	0x07	maximum	destination = maximum(source1,source2), componentwise
 * frc	0x08	fractional	destination = source1 - (float)floor(source1), componentwise
 * sqt	0x09	square root	destination = sqrt(source1), componentwise
 * rsq	0x0a	reciprocal root	destination = 1/sqrt(source1), componentwise
 * pow	0x0b	power	destination = pow(source1,source2), componentwise
 * log	0x0c	logarithm	destination = log_2(source1), componentwise
 * exp	0x0d	exponential	destination = 2^source1, componentwise
 * nrm	0x0e	normalize	destination = normalize(source1), componentwise (produces only a 3 component result, destination must be masked to .xyz or less)
 * sin	0x0f	sine	destination = sin(source1), componentwise
 * cos	0x10	cosine	destination = cos(source1), componentwise
 * crs	0x11	cross product
 *                            destination.x = source1.y * source2.z - source1.z * source2.y
 *                            destination.y = source1.z * source2.x - source1.x * source2.z
 *                            destination.z = source1.x * source2.y - source1.y * source2.x
 *                            (produces only a 3 component result, destination must be masked to .xyz or less)
 * dp3	0x12	dot product	destination = source1.x*source2.x + source1.y*source2.y + source1.z*source2.z
 * dp4	0x13	dot product	destination = source1.x*source2.x + source1.y*source2.y + source1.z*source2.z + source1.w*source2.w
 * abs	0x14	absolute	destination = abs(source1), componentwise
 * neg	0x15	negate	destination = -source1, componentwise
 * sat	0x16	saturate	destination = maximum(minimum(source1,1),0), componentwise
 * m33	0x17	multiply matrix 3x3
 *                            destination.x = (source1.x * source2[0].x) + (source1.y * source2[0].y) + (source1.z * source2[0].z)
 *                            destination.y = (source1.x * source2[1].x) + (source1.y * source2[1].y) + (source1.z * source2[1].z)
 *                            destination.z = (source1.x * source2[2].x) + (source1.y * source2[2].y) + (source1.z * source2[2].z)
 *                            (produces only a 3 component result, destination must be masked to .xyz or less)
 * m44	0x18	multiply matrix 4x4
 *                            destination.x = (source1.x * source2[0].x) + (source1.y * source2[0].y) + (source1.z * source2[0].z) + (source1.w * source2[0].w)
 *                            destination.y = (source1.x * source2[1].x) + (source1.y * source2[1].y) + (source1.z * source2[1].z) + (source1.w * source2[1].w)
 *                            destination.z = (source1.x * source2[2].x) + (source1.y * source2[2].y) + (source1.z * source2[2].z) + (source1.w * source2[2].w)
 *                            destination.w = (source1.x * source2[3].x) + (source1.y * source2[3].y) + (source1.z * source2[3].z) + (source1.w * source2[3].w)
 *
 * m34	0x19	multiply matrix 3x4
 *                            destination.x = (source1.x * source2[0].x) + (source1.y * source2[0].y) + (source1.z * source2[0].z) + (source1.w * source2[0].w)
 *                            destination.y = (source1.x * source2[1].x) + (source1.y * source2[1].y) + (source1.z * source2[1].z) + (source1.w * source2[1].w)
 *                            destination.z = (source1.x * source2[2].x) + (source1.y * source2[2].y) + (source1.z * source2[2].z) + (source1.w * source2[2].w)
 *                            (produces only a 3 component result, destination must be masked to .xyz or less)
 * kil	0x27	kill/discard (fragment shader only)	If single scalar source component is less than zero, fragment is discarded and not drawn to the frame buffer. (Destination register must be set_to all 0)
 * tex	0x28	texture sample (fragment shader only)	destination equals load from texture source2 at coordinates source1. In this case, source2 must be in sampler format.
 * sge	0x29	set-if-greater-equal	destination = source1 >= source2 ? 1 : 0, componentwise
 * slt	0x2a	set-if-less-than	destination = source1 < source2 ? 1 : 0, componentwise
 * seq	0x2c	set-if-equal	destination = source1 == source2 ? 1 : 0, componentwise
 * sne	0x2d	set-if-not-equal	destination = source1 != source2 ? 1 : 0, componentwise
 *
 * @see http://help.adobe.com/en_US/as3/dev/WSd6a006f2eb1dc31e-310b95831324724ec56-8000.html
 */
class OpCodeManager
{
	public static inline var OP_SCALAR:Int = 0x1;
	public static inline var OP_INC_NEST:Int = 0x2;
	public static inline var OP_DEC_NEST:Int = 0x4;
	public static inline var OP_SPECIAL_TEX:Int = 0x8;
	public static inline var OP_SPECIAL_MATRIX:Int = 0x10;
	public static inline var OP_FRAG_ONLY:Int = 0x20;
	public static inline var OP_VERT_ONLY:Int = 0x40;
	public static inline var OP_NO_DEST:Int = 0x80;
	public static inline var OP_VERSION2:Int = 0x100;
	public static inline var OP_INCNEST:Int = 0x200;
	public static inline var OP_DECNEST:Int = 0x400;

	private var _opCodeMap:StringMap<OpCode>;

	public var profile:ShaderProfile;
	
	public var agalVersion:Int = 1;

	public var movCode:OpCode;

	public var textureCode:OpCode;

	public var killCode:OpCode;

	public function new(profile:ShaderProfile)
	{
		this.profile = profile;
		agalVersion = (Std.string(profile) == "standard") ? 0x2 : 0x1;
		_initCodes();
	}

	public function isTexture(name:String):Bool
	{
		return _opCodeMap.get(name) == textureCode;
	}

	public inline function getCode(name:String):OpCode
	{
		if (!_opCodeMap.exists(name))
		{
			Logger.warn("can not find opCode " + name + ",please check your sgsl version !");
		}
		return _opCodeMap.get(name);
	}

	public inline function containCode(name:String):Bool
	{
		return _opCodeMap.exists(name);
	}

	private function _initCodes():Void
	{
		_opCodeMap = new StringMap<OpCode>();

		movCode = addCode(["mov"], 2, 0x00, 0);
		addCode(["add"], 3, 0x01, 0);
		addCode(["sub", "subtract"], 3, 0x02, 0);
		addCode(["mul", "multiply"], 3, 0x03, 0);
		addCode(["div", "divide"], 3, 0x04, 0);
		addCode(["rcp", "reciprocal"], 2, 0x05, 0);
		addCode(["min"], 3, 0x06, 0);
		addCode(["max"], 3, 0x07, 0);
		addCode(["frc", "fract"], 2, 0x08, 0);
		addCode(["sqt", "sqrt"], 2, 0x09, 0);
		addCode(["rsq", "invSqrt"], 2, 0x0a, 0);
		addCode(["pow"], 3, 0x0b, 0);
		addCode(["log"], 2, 0x0c, 0);
		addCode(["exp"], 2, 0x0d, 0);
		addCode(["nrm", "normalize"], 2, 0x0e, 0);
		addCode(["sin"], 2, 0x0f, 0);
		addCode(["cos"], 2, 0x10, 0);
		addCode(["crs", "cross", "crossProduct"], 3, 0x11, 0);

		addCode(["dp3", "dot3", "dotProduct3"], 3, 0x12, 0);
		addCode(["dp4", "dot4", "dotProduct4"], 3, 0x13, 0);

		addCode(["abs"], 2, 0x14, 0);
		addCode(["neg", "negate"], 2, 0x15, 0);
		addCode(["sat", "saturate"], 2, 0x16, 0);

		addCode(["m33"], 3, 0x17, OP_SPECIAL_MATRIX);
		addCode(["m44"], 3, 0x18, OP_SPECIAL_MATRIX);
		addCode(["m34"], 3, 0x19, OP_SPECIAL_MATRIX);

		//available in agal version 2
		if (agalVersion == 2)
		{
			addCode(["ddx"], 2, 0x1a, OP_VERSION2 | OP_FRAG_ONLY);
			addCode(["ddy"], 2, 0x1b, OP_VERSION2 | OP_FRAG_ONLY);
			addCode(["ife"], 2, 0x1c, OP_NO_DEST | OP_VERSION2 | OP_INCNEST | OP_SCALAR);
			addCode(["ine"], 2, 0x1d, OP_NO_DEST | OP_VERSION2 | OP_INCNEST | OP_SCALAR);
			addCode(["ifg"], 2, 0x1e, OP_NO_DEST | OP_VERSION2 | OP_INCNEST | OP_SCALAR);
			addCode(["ifl"], 2, 0x1f, OP_NO_DEST | OP_VERSION2 | OP_INCNEST | OP_SCALAR);
			addCode(["els"], 0, 0x20, OP_NO_DEST | OP_VERSION2 | OP_INCNEST | OP_DECNEST | OP_SCALAR);
			addCode(["eif"], 0, 0x21, OP_NO_DEST | OP_VERSION2 | OP_DECNEST | OP_SCALAR);
			// space
			addCode(["ted"], 3, 0x26, OP_FRAG_ONLY | OP_SPECIAL_TEX | OP_VERSION2);
		}

		killCode = addCode(["kil", "kill", "discard"], 1, 0x27, OP_NO_DEST | OP_FRAG_ONLY);
		textureCode = addCode(["texture2D", "textureCube"], 3, 0x28, OP_FRAG_ONLY | OP_SPECIAL_TEX);

		//约束模式下不能使用
		if (profile != ShaderProfile.BASELINE_CONSTRAINED)
		{
			addCode(["sge", "greaterThanEqual", "step"], 3, 0x29, 0);
			addCode(["slt", "lessThan"], 3, 0x2a, 0);

			addCode(["sgn"], 2, 0x2b, 0);
			addCode(["seq", "equal"], 3, 0x2c, 0);
			addCode(["sne", "notEqual"], 3, 0x2d, 0);
		}
	}

	/**
	 * 添加原生函数
	 * @param	name  原名
	 * @param	nicknames 别名列表
	 */
	private function addCode(names:Array<String>, numRegister:Int, emitCode:Int, flags:Int):OpCode
	{
		var code:OpCode = new OpCode(names, numRegister, emitCode, flags);

		var length:Int = names.length;
		for (i in 0...length)
		{
			_opCodeMap.set(names[i], code);
		}

		return code;
	}
}

