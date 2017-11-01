package examples.effect.gpu;

import flash.display.Sprite;


import org.angle3d.math.Vector2f;

/**
 * SpriteSheet UV测试
 */
class TexCoordTest extends Sprite
{
	static function main() 
	{
		flash.Lib.current.addChild(new TexCoordTest());
	}
	
	public function new()
	{
		super();

		//测试到达第几帧
		var duration:Float = 0.5;
		var startFrame:Int=5;
		var currentTime:Int = 15;
		var totalFrame:Int = 16;

		var frame:Int = Std.int(currentTime / duration) + startFrame;
		var index:Int = Std.int(frame / totalFrame);

		var real:Int = frame - index * totalFrame;
		Lib.trace(frame);
		Lib.trace(real);

		Lib.trace(getTexCoord(10, new Vector2f(1, 0), 4, 4));
		Lib.trace(getTexCoord(10, new Vector2f(0, 0), 4, 4));
		Lib.trace(getTexCoord(10, new Vector2f(1, 1), 4, 4));
		Lib.trace(getTexCoord(10, new Vector2f(0, 1), 4, 4));
		Lib.trace(getTexCoord(0, new Vector2f(1, 0), 4, 4));
		Lib.trace(getTexCoord(1, new Vector2f(0, 0), 4, 4));
		Lib.trace(getTexCoord(2, new Vector2f(1, 1), 4, 4));
		Lib.trace(getTexCoord(3, new Vector2f(0, 1), 4, 4));
	}

	/**
	 *
	 * @param frame
	 * @param vertex
	 * @param numCol 列数量
	 * @param numRow 行数量
	 * @return
	 *
	 */
	private function getTexCoord(frame:Int, vertex:Vector2f, numCol:Int, numRow:Int):Vector2f
	{
		var totalFrame:Int = numCol * numRow;

		var invertX:Float = 1 / numRow;
		var invertY:Float = 1 / numCol;

		var currentRowIndex:Int = Std.int(frame / numCol);
		var currentColIndex:Int = frame - currentRowIndex * numCol;

		var result:Vector2f = new Vector2f();

		result.x = currentColIndex * invertX + vertex.x * invertX;
		result.y = currentRowIndex * invertY + vertex.y * invertY;

		return result;
	}
}
