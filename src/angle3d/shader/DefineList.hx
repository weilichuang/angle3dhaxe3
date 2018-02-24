package angle3d.shader;
import haxe.ds.Vector;
import angle3d.error.Assert;

import angle3d.material.MatParam;
import angle3d.material.TechniqueDef;
import angle3d.shader.VarType;
import angle3d.math.FastMath;
import angle3d.utils.Cloneable;
import haxe.ds.StringMap;

/**
 * The new define list.
 *
 */
class DefineList {
	public static inline var MAX_DEFINES:Int = 30;

	private var isSet:Int;
	private var values:Vector<Float>;

	public function new(numValues:Int) {
		#if debug
		Assert.assert(numValues >= 0 && numValues <= MAX_DEFINES,'numValues must be between 0 and $MAX_DEFINES');
		#end

		values = new Vector<Float>(numValues);
	}

	public function copyFrom(other:DefineList):Void {
		this.values.isSet = other.isSet;
		for (i in 0...other.values.length) {
			this.values[i] = other.values[i];
		}
	}

	public function clone():DefineList {
		var result:DefineList = new DefineList(this.values.length);
		result.copyFrom(this);
		return result;
	}

	private inline function rangeCheck(id:Int):Void {
		#if debug
		Assert.assert(0 <= id && id < MAX_DEFINES);
		#end
	}

	public function unset(id:Int):Void {
		isSet &= ~(1 << id);
		values[id] = 0;
	}

	public inline function setFloat(id:Int, value:Float):Void {
		rangeCheck(id);

		isSet |= (1 << id);
		values[id] = value;
	}

	public inline function setBool(id:Int, value:Bool):Void {
		if (value) {
			setFloat(id, 1);
		} else{
			// Because #ifdef usage is very common in shaders, unset the define
			// instead of setting it to 0 for booleans.
			unset(id);
		}
	}

	public inline function setObject(id:Int, type:VarType, value:Dynamic):Void {
		if (value == null) {
			unset(id);
			return;
		}

		switch (type) {
			case VarType.INT, VarType.FLOAT:
				setFloat(id, cast value);
			case VarType.BOOL:
				setBool(id, cast value);
			default:
				setFloat(id, 1);
		}
	}

	public function setAll(other:DefineList):Void {
		for (i in 0...other.values.length) {
			setObject(i, other.values[i]);
		}
	}

	public inline function clear():Void {
		isSet = 0;
		for (i in 0...values.length) {
			values[i] = 0;
		}
	}

	public inline function getBoolean(id:Int):Bool {
		return values[id] != 0;
	}

	public inline function getFloat(id:Int):Float {
		return values[id];
	}

	public inline function getInt(id:Int):Int {
		return Std.int(values[id]);
	}

	public function equals(other:DefineList):Bool {
		if (other.isSet == this.isSet) {
			for (i in 0...values.length) {
				if (other.values[i] != values[i]) {
					return false;
				}
			}
			return true;
		}
		return false;
	}

	public inline function checkIsSet(id:Int):Bool {
		rangeCheck(id);
		return (isSet & (1 << id)) != 0;
	}

	public function generateSource(defineNames:Array<String>, defineTypes:Array<VarType>):String {
		var result:String = "";
		for (i in 0...values.length) {
			if (!checkIsSet(i))
				continue;

			var value:Float = values[i];
			if (FastMath.isFinite(value) || FastMath.isNaN(value)) {
				throw "GLSL does not support NaN or Infinite float literals");
			}

			result += "#define " + defineNames[i] + " " + value + "\n";
		}
		return result;
	}
}