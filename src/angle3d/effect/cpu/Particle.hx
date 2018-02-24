package angle3d.effect.cpu;

import angle3d.math.Color;
import angle3d.math.Vector3f;

/**
 * a single particle .
 *
 */
class Particle {
	/**
	 * Particle velocity.
	 * 速度
	 */
	public var velocity:Vector3f;

	/**
	 * Current particle position
	 * 位置
	 */
	public var position:Vector3f;

	/**
	 * Particle color
	 * 颜色
	 */
	public var color:UInt;

	/**
	 * Particle Alpha
	 */
	public var alpha:Float;

	/**
	 * 缩放比例
	 */
	public var size:Float;

	/**
	 * Particle remaining life, in seconds.
	 * 生命剩余时间
	 */
	public var life:Float;

	/**
	 * The initial particle life
	 *
	 */
	public var totalLife:Float;

	/**
	 * Particle rotation angle (in radians).
	 * 角度
	 */
	public var angle:Float;

	/**
	 * Particle rotation angle speed (in radians).
	 */
	public var spin:Float;

	/**
	 * Particle image index.
	 */
	public var frame:Int;

	public function new() {
		velocity = new Vector3f();
		position = new Vector3f();
		color = 0x0;
		alpha = 1.0;

		size = 0;
		angle = 0;
		spin = 0;
		frame = 0;
		totalLife = 0;
		life = 0;
	}

	public function reset():Void {
		color = 0x0;
		alpha = 1.0;

		size = 0;
		angle = 0;
		spin = 0;
		frame = 0;
		totalLife = 0;
		life = 0;
	}
}

