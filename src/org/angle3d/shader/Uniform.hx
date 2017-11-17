package org.angle3d.shader;

import org.angle3d.math.Matrix3f;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.types.FloatBuffer;
import org.angle3d.shader.VarType;
import org.angle3d.math.Color;

class Uniform extends ShaderVariable {
	/**
	 * Binding to a renderer value, or null if user-defined uniform
	 */
	public var binding:UniformBinding;

	/**
	 * efficient format that can be sent to GL faster.
	 */
	private var multiData:FloatBuffer;

	/**
	 * Type of uniform
	 */
	private var varType:VarType;

	/**
	 * Used to track which uniforms to clear to avoid
	 * values leaking from other materials that use that shader.
	 */
	private var setByCurrentMaterial:Bool = false;

	public function new() {
		super();
	}

	public inline function getVarType():VarType {
		return varType;
	}

	public inline function getMultiData():FloatBuffer {
		return multiData;
	}

	public function setValue(varType:VarType, value:Dynamic):Void {
		//if (location == null)
		//return;

		if (this.varType != null && this.varType != varType) {
			throw "Expected a " + this.varType + " value!";
		}

		setByCurrentMaterial = true;

		switch (varType) {
			case VarType.Vector2:
				if (multiData == null) {
					multiData = new FloatBuffer(2);
				} else {
					multiData.resize(2);
				}
				if (multiData[0] == value.x && multiData[1] == value.y)
					return;
				multiData[0] = value.x;
				multiData[1] = value.y;
			case VarType.Vector3:
				if (multiData == null) {
					multiData = new FloatBuffer(3);
				} else {
					multiData.resize(3);
				}
				if (multiData[0] == value.x && multiData[1] == value.y && multiData[2] == value.z)
					return;
				multiData[0] = value.x;
				multiData[1] = value.y;
				multiData[2] = value.z;
			case VarType.Vector4:
				if (multiData == null) {
					multiData = new FloatBuffer(4);
				} else {
					multiData.resize(4);
				}
				if (Std.is(value, Color)) {
					if (multiData[0] == value.r && multiData[1] == value.g && multiData[2] == value.b && multiData[3] == value.a)
						return;
					multiData[0] = value.r;
					multiData[1] = value.g;
					multiData[2] = value.b;
					multiData[3] = value.a;
				} else {
					if (multiData[0] == value.x && multiData[1] == value.y && multiData[2] == value.z && multiData[3] == value.w)
						return;
					multiData[0] = value.x;
					multiData[1] = value.y;
					multiData[2] = value.z;
					multiData[3] = value.w;
				}
			case VarType.FLOAT,VarType.INT,VarType.BOOL:
				if (multiData == null) {
					multiData = new FloatBuffer(1);
				} else {
					multiData.resize(1);
				}
				if (multiData[0] == value)
					return;
				multiData[0] = value;
			case VarType.Matrix3:
				if (multiData == null) {
					multiData = new FloatBuffer(9);
				} else {
					multiData.resize(9);
				}
				if (multiData[0] == value.m00 && multiData[1] == value.m01 && multiData[2] == value.m02 &&
						multiData[3] == value.m10 && multiData[4] == value.m11 && multiData[5] == value.m12 &&
						multiData[6] == value.m20 && multiData[7] == value.m21 && multiData[8] == value.m22)
					return;
				multiData[0] = value.m00; multiData[1] = value.m01; multiData[2] = value.m02;
				multiData[3] = value.m10; multiData[4] = value.m11; multiData[5] = value.m12;
				multiData[6] = value.m20; multiData[7] = value.m21; multiData[8] = value.m22;
			case VarType.Matrix4:
				if (multiData == null) {
					multiData = new FloatBuffer(16);
				} else {
					multiData.resize(16);
				}
				if (multiData[0] == value.m00 && multiData[1] == value.m01 && multiData[2] == value.m02 && multiData[3] == value.m03 &&
						multiData[4] == value.m10 && multiData[5] == value.m11 && multiData[6] == value.m12 && multiData[7] == value.m13 &&
						multiData[8] == value.m20 && multiData[9] == value.m21 && multiData[10] == value.m22 && multiData[11] == value.m23 &&
						multiData[12] == value.m30 && multiData[13] == value.m31 && multiData[14] == value.m32 && multiData[15] == value.m33)
					return;
				multiData[0] = value.m00; multiData[1] = value.m01; multiData[2] = value.m02; multiData[3] = value.m03;
				multiData[4] = value.m10; multiData[5] = value.m11; multiData[6] = value.m12; multiData[7] = value.m13;
				multiData[8] = value.m20; multiData[9] = value.m21; multiData[10] = value.m22; multiData[11] = value.m23;
				multiData[12] = value.m30; multiData[13] = value.m31; multiData[14] = value.m32; multiData[15] == value.m33;
			case VarType.IntArray:
				var ia:Array<Int> = cast value;
				if (multiData == null) {
					multiData = new FloatBuffer(ia.length);
				} else {
					multiData.resize(ia.length);
				}
				for (i in 0...ia.length) {
					multiData[i] = ia[i];
				}
			case VarType.FloatArray:
				var fa:Array<Float> = cast value;
				if (multiData == null) {
					multiData = new FloatBuffer(fa.length);
				} else {
					multiData.resize(fa.length);
				}
				for (i in 0...fa.length) {
					multiData[i] = fa[i];
				}
			case VarType.Vector2Array:
				var v2a:Array<Vector2f> = cast value;
				if (multiData == null) {
					multiData = new FloatBuffer(v2a.length * 2);
				} else {
					multiData.resize(v2a.length * 2);
				}
				for (i in 0...v2a.length) {
					multiData[i * 2] = v2a[i].x;
					multiData[i * 2 + 1] = v2a[i].y;
				}
			case VarType.Vector3Array:
				var v3a:Array<Vector3f> = cast value;
				if (multiData == null) {
					multiData = new FloatBuffer(v3a.length * 3);
				} else {
					multiData.resize(v3a.length * 3);
				}
				for (i in 0...v3a.length) {
					multiData[i * 3] = v3a[i].x;
					multiData[i * 3 + 1] = v3a[i].y;
					multiData[i * 3 + 2] = v3a[i].z;
				}
			case VarType.Vector4Array:
				var v4a:Array<Vector4f> = cast value;
				if (multiData == null) {
					multiData = new FloatBuffer(v4a.length * 4);
				} else {
					multiData.resize(v4a.length * 4);
				}
				for (i in 0...v4a.length) {
					multiData[i * 4] = v4a[i].x;
					multiData[i * 4 + 1] = v4a[i].y;
					multiData[i * 4 + 2] = v4a[i].z;
					multiData[i * 4 + 3] = v4a[i].w;
				}
			case VarType.Matrix3Array:
				var m3a:Array<Matrix3f> = cast value;
				if (multiData == null) {
					multiData = new FloatBuffer(m3a.length * 9);
				} else {
					multiData.resize(m3a.length * 9);
				}
				for (i in 0...m3a.length) {
					var mat3 = m3a[i];
					multiData[i * 9 + 0] = mat3.m00; multiData[i * 9 + 1] = mat3.m01; multiData[i * 9 + 2] = mat3.m02;
					multiData[i * 9 + 3] = mat3.m10; multiData[i * 9 + 4] = mat3.m11; multiData[i * 9 + 5] = mat3.m12;
					multiData[i * 9 + 6] = mat3.m20; multiData[i * 9 + 7] = mat3.m21; multiData[i * 9 + 8] = mat3.m22;
				}
			case VarType.Matrix4Array:
				var m4a:Array<Matrix4f> = cast value;
				if (multiData == null) {
					multiData = new FloatBuffer(m4a.length * 16);
				} else {
					multiData.resize(m4a.length * 16);
				}
				for (i in 0...m4a.length) {
					var mat4 = m4a[i];
					multiData[i * 16 + 0] = mat4.m00;
					multiData[i * 16 + 1] = mat4.m01;
					multiData[i * 16 + 2] = mat4.m02;
					multiData[i * 16 + 3] = mat4.m03;

					multiData[i * 16 + 4] = mat4.m10;
					multiData[i * 16 + 5] = mat4.m11;
					multiData[i * 16 + 6] = mat4.m12;
					multiData[i * 16 + 7] = mat4.m13;

					multiData[i * 16 + 8] = mat4.m20;
					multiData[i * 16 + 9] = mat4.m21;
					multiData[i * 16 + 10] = mat4.m22;
					multiData[i * 16 + 11] = mat4.m23;

					multiData[i * 16 + 12] = mat4.m30;
					multiData[i * 16 + 13] = mat4.m31;
					multiData[i * 16 + 14] = mat4.m32;
					multiData[i * 16 + 15] = mat4.m33;
				}
			default:
				//do nothing
		}

		this.varType = varType;
		updateNeeded = true;
	}

	public function clearValue():Void {
		updateNeeded = true;
		if (multiData != null) {
			for (i in 0...multiData.length) {
				multiData[i] = 0;
			}
		}
	}

	public inline function isSetByCurrentMaterial():Bool {
		return setByCurrentMaterial;
	}

	public inline function clearSetByCurrentMaterial():Void {
		setByCurrentMaterial = false;
	}

	public function setVector4Length(length:Int):Void {
		if (multiData == null)
			multiData = new FloatBuffer(length * 4);
		else
			multiData.resize(length * 4);

		this.varType = VarType.Vector4Array;
		setByCurrentMaterial = true;
		updateNeeded = true;
	}

	public inline function setVector4InArray(x:Float, y:Float, z:Float, w:Float, index:Int):Void {
		#if debug
		if (this.varType != null && this.varType != VarType.Vector4Array) {
			throw "Expected a Vector4Array value!";
		}
		#end

		var index4:Int = index * 4;
		multiData[index4] = x;
		multiData[index4 + 1] = y;
		multiData[index4 + 2] = z;
		multiData[index4 + 3] = w;

		setByCurrentMaterial = true;
		updateNeeded = true;
	}

	public function isUpdateNeeded():Bool {
		return updateNeeded;
	}

	public function clearUpdateNeeded():Void {
		updateNeeded = false;
	}

	public function reset():Void {
		setByCurrentMaterial = false;
		updateNeeded = true;
		location = null;
	}
}

