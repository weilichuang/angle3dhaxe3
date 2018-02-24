package angle3d.effect.gpu;

import angle3d.material.BlendMode;
import angle3d.material.Material;
import angle3d.math.Color;
import angle3d.math.Vector3f;
import angle3d.renderer.queue.QueueBucket;
import angle3d.renderer.queue.ShadowMode;
import angle3d.scene.Geometry;
import angle3d.texture.Texture;

class ParticleShape extends Geometry {
	private var _useLocalAcceleration:Bool = false;
	public var useLocalAcceleration(get, set):Bool;

	private var _useLocalColor:Bool = false;
	public var useLocalColor(get, set):Bool;

	//public var blendMode(get, set):BlendMode;

	private var _useSpin:Bool = false;
	public var useSpin(get, set):Bool;

	private var _loop:Bool = false;
	public var loop(get, set):Bool;

	public var startTime(get, set):Float;

	public var isDead(get, null):Bool;

	//开始时间
	private var _startTime:Float = 0;

	//当前时间
	private var _currentTime:Float = 0;

	//生命
	private var _totalLife:Float;

	private var _gpuMaterial:Material;

	private var _spriteSheetData:Array<Float>;

	private var beginColor:Color;
	private var incrementColor:Color;
	/**
	 *
	 * @param name 名字
	 * @param texture 贴图
	 * @param totalLife 生命周期
	 * @param startTime 开始时间
	 *
	 */
	public function new(name:String, texture:Texture, totalLife:Float, startTime:Float = 0) {
		super(name);

		_startTime = startTime;
		_totalLife = totalLife;

		_spriteSheetData = new Array<Float>(4);

		beginColor = new Color(1, 1, 1, 1);
		incrementColor = new Color(0, 0, 0, 0);

		_gpuMaterial = new Material();
		_gpuMaterial.load(Angle3D.materialFolder + "material/gpuparticle.mat");
		_gpuMaterial.setTexture("u_DiffuseMap", texture);
		setMaterial(_gpuMaterial);
		localShadowMode = ShadowMode.Off;
		localQueueBucket = QueueBucket.Transparent;

		loop = true;
	}

	/**
	 * 使用粒子单独加速度
	 */

	private function get_useLocalAcceleration():Bool {
		return _useLocalAcceleration;
	}

	private function set_useLocalAcceleration(value:Bool):Bool {
		_useLocalAcceleration = value;
		_gpuMaterial.setBoolean("useLocalAcceleration", value);
		return _useLocalAcceleration;
	}

	private function get_useLocalColor():Bool {
		return _useLocalColor;
	}

	private function set_useLocalColor(value:Bool):Bool {
		_useLocalColor = value;
		_gpuMaterial.setBoolean("useLocalColor", value);
		return _useLocalColor;
	}

	/**
	 * 使用自转
	 */
	private function get_useSpin():Bool {
		return _useSpin;
	}

	private function set_useSpin(value:Bool):Bool {
		_useSpin = value;
		_gpuMaterial.setBoolean("useSpin", value);
		return _useSpin;
	}

	/**
	 * 设置全局加速度，会影响每一个粒子
	 */
	public function setAcceleration(acceleration:Vector3f):Void {
		_gpuMaterial.setBoolean("useAcceleration", acceleration != null && !acceleration.isZero());
		_gpuMaterial.setVector3("u_acceleration",acceleration);
	}

	/**
	 *
	 * @param animDuration 播放速度,多长时间播放一次（秒）
	 * @param col
	 * @param row
	 *
	 */
	public function setSpriteSheet(animDuration:Float, col:Int, row:Int):Void {
		//每个图像持续时间
		_spriteSheetData[0] = animDuration;

		//列数
		_spriteSheetData[1] = col;
		//行数
		_spriteSheetData[2] = row;
		//总数
		_spriteSheetData[3] = col * row;

		_gpuMaterial.setBoolean("useAnimation", animDuration > 0);
		_gpuMaterial.setBoolean("useSpriteSheet", col > 1 || row > 1);
		_gpuMaterial.setVector3("u_spriteSheet",new Vector3f(animDuration, col, row));
	}

	public function setColor(start:UInt, end:UInt):Void {
		beginColor.setRGB(start);

		var endColor:Color = new Color();
		endColor.setRGB(end);

		incrementColor.r = endColor.r - beginColor.r;
		incrementColor.g = endColor.g - beginColor.g;
		incrementColor.b = endColor.b - beginColor.b;

		_gpuMaterial.setBoolean("useColor", true);
		_gpuMaterial.setColor("u_beginColor", beginColor);
		_gpuMaterial.setColor("u_incrementColor",incrementColor);
	}

	public function setAlpha(start:Float, end:Float):Void {
		beginColor.a = start;
		incrementColor.a = end - beginColor.a;

		_gpuMaterial.setBoolean("useColor", true);
		_gpuMaterial.setColor("u_beginColor", beginColor);
		_gpuMaterial.setColor("u_incrementColor",incrementColor);
	}

	public function setSize(start:Float, end:Float):Void {
		_gpuMaterial.setVector3("u_size", new Vector3f(start, end, end - start));
	}

	private function get_loop():Bool {
		return _loop;
	}
	private function set_loop(value:Bool):Bool {
		_loop = value;
		_gpuMaterial.setBoolean("notLoop", !_loop);
		return _loop;
	}

	public function reset():Void {
		_currentTime = 0;
		_gpuMaterial.setFloat("u_curTime", 0);
		visible = false;
	}

	private function get_startTime():Float {
		return _startTime;
	}
	private function set_startTime(value:Float):Float {
		return _startTime = value;
	}

	private function get_isDead():Bool {
		return !loop && (_currentTime - _startTime) > _totalLife;
	}

	/**
	 * 内部调用
	 */
	public function updateMaterial(tpf:Float):Void {
		_currentTime += tpf;

		_gpuMaterial.setFloat("u_curTime", _currentTime);
	}
}
