package angle3d.utils;

import angle3d.math.Vector2f;
import angle3d.math.Vector3f;
import angle3d.types.FloatBuffer;

class BufferUtils {
	public static inline function setInBuffer(vector:Vector3f, buf:Array<Float>, index:Int):Void {
		var i3:Int = index * 3;
		buf[i3] = vector.x;
		buf[i3 + 1] = vector.y;
		buf[i3 + 2] = vector.z;
	}

	/**
	 * Updates the values of the given vector from the specified buffer at the
	 * index provided.
	 *
	 * @param vector
	 *            the vector to set_data on
	 * @param buf
	 *            the buffer to read from
	 * @param index
	 *            the position (in terms of vectors, not floats) to read from
	 *            the buf
	 */
	public static inline function populateFromBuffer(vector:Vector3f, buf:Array<Float>, index:Int):Void {
		var i3:Int = index * 3;
		vector.x = buf[i3];
		vector.y = buf[i3 + 1];
		vector.z = buf[i3 + 2];
	}

	public static inline function populateFromVector2f(vector:Vector2f, buf:Array<Float>, index:Int):Void {
		var i2:Int = index * 2;
		vector.x = buf[i2];
		vector.y = buf[i2 + 1];
	}

	/**
	 * Copies a Vector3f from one position in the buffer to another. The index
	 * values are in terms of vector number (eg, vector number 0 is postions 0-2
	 * in the NumberBuffer.)
	 *
	 * @param buf
	 *            the buffer to copy from/to
	 * @param fromPos
	 *            the index of the vector to copy
	 * @param toPos
	 *            the index to copy the vector to
	 */
	public static inline function copyInternalVector3(buf:Array<Float>, fromPos:Int, toPos:Int):Void {
		copyInternal(buf, fromPos * 3, toPos * 3, 3);
	}

	/**
	 * Copies a Vector2f from one position in the buffer to another. The index
	 * values are in terms of vector number (eg, vector number 0 is postions 0-1
	 * in the NumberBuffer.)
	 *
	 * @param buf
	 *            the buffer to copy from/to
	 * @param fromPos
	 *            the index of the vector to copy
	 * @param toPos
	 *            the index to copy the vector to
	 */
	public static inline function copyInternalVector2(buf:Array<Float>, fromPos:Int, toPos:Int):Void {
		copyInternal(buf, fromPos * 2, toPos * 2, 2);
	}

	/**
	 * Copies floats from one position in the buffer to another.
	 *
	 * @param buf
	 *            the buffer to copy from/to
	 * @param fromPos
	 *            the starting point to copy from
	 * @param toPos
	 *            the starting point to copy to
	 * @param length
	 *            the number of floats to copy
	 */
	public static inline function copyInternal(buf:Array<Float>, fromPos:Int, toPos:Int, length:Int):Void {
		for (i in 0...length) {
			buf[toPos + i] = buf[fromPos + i];
		}
	}

	public static inline function createFloatBufferFromFloatArray(arr:Array<Float>):FloatBuffer {
		var result:FloatBuffer = arr;
		return result;
	}

	public static inline function createFloatBufferFromIntArray(arr:Array<Int>):FloatBuffer {
		var result:FloatBuffer = arr;
		return result;
	}

	public static inline function ensureLargeEnough(buffer:FloatBuffer, required:Int):FloatBuffer {
		if (buffer == null) {
			buffer = new FloatBuffer(required);
		} else{
			buffer.resize(required);
		}
		return buffer;
	}
}

