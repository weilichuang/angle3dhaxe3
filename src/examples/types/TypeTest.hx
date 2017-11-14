package examples.types;
import js.html.Float32Array;

import org.angle3d.types.FloatBuffer;
import org.angle3d.utils.BufferUtils;
import org.angle3d.material.VarType;
import org.angle3d.material.shader.Uniform;
/**
 * ...
 * @author 
 */
class TypeTest 
{
	static function main() 
	{
		var buffer = new FloatBuffer(12);
		buffer.push(1);
		buffer.push(2);
		buffer.push(3);
		trace(buffer[0]);
		trace(buffer.length);
		var arr:Float32Array = buffer.getNative();
		trace(arr);
		var arr2 = buffer.getNative();
		trace(arr2);

		var arr3 = [1, 2, 3, 4];
		var buff2 = BufferUtils.createFloatBufferFromIntArray(arr3);
		trace(buff2);
		
		var uniform:Uniform = new Uniform();
		uniform.setValue(VarType.IntArray, [1, 2, 3, 4]);
		trace(uniform.getMultiData());
	}

	public function new() 
	{
		
	}
	
}