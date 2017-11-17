package org.angle3d.scene.control;

import org.angle3d.material.Material;
import org.angle3d.math.Vector2f;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.MorphGeometry;
import org.angle3d.scene.Spatial;
import org.angle3d.scene.mesh.MorphMesh;
import org.angle3d.scene.mesh.MorphData;

/**
 * 变形动画控制器
 */
//TODO 添加两个不同动画之间的过渡
//TODO 添加一个可以倒播的动画，比如一个人物行走倒播就是人物倒着走的动画
class MorphControl extends AbstractControl {
	public var material(get, null):Material;
	public var mesh(get, null):MorphMesh;

	private var _morphData:MorphData;
	private var _fps:Float;
	private var _loop:Bool;

	private var _curFrame:Float;
	private var _nextFrame:Int;

	private var _pause:Bool;

	private var _node:MorphGeometry;
	private var _mesh:MorphMesh;
	private var _material:Material;

	private var _curAnimation:String;
	private var _oldAnimation:String;

	private var tmpVector2:Vector2f;

	public function new() {
		super();

		tmpVector2 = new Vector2f();
	}

	public function setAnimationSpeed(value:Float):Void {
		_fps = value / 60;
	}

	private function get_material():Material {
		if (_material == null) {
			_material = _node.getMaterial();
		}
		return _material;
	}

	private function get_mesh():MorphMesh {
		if (_mesh == null) {
			_mesh = _node.morphMesh;
		}
		return _mesh;
	}

	/**
	 *
	 * @param animationName 动画名称
	 * @param animationFPS 播放速度
	 * @param loop 是否循环
	 * @param fadOutTime 前一个动画淡出时间，如果有的话
	 */
	public function playAnimation(animation:String, loop:Bool = true, fadeOutTime:Float = 0.5):Void {
		_oldAnimation = _curAnimation;

		_curAnimation = animation;

		_morphData = mesh.getAnimation(_curAnimation);
		_loop = loop;

		_pause = false;
		if (_morphData != null) {
			_curFrame = _morphData.start;
			_nextFrame = Std.int(_curFrame + 1);
		}
	}

	//TODO 可能需要添加一些参数，用于控制在什么位置停止动画
	public function stop():Void {
		_pause = true;
	}

	override public function cloneForSpatial(spatial:Spatial):Control {
		var control:MorphControl = new MorphControl();
		control.setSpatial(spatial);
		control.setEnabled(this.isEnabled());
		return control;
	}

	override public function setSpatial(spatial:Spatial):Void {
		super.setSpatial(spatial);
		_node = Std.instance(spatial, MorphGeometry);
	}

	override private function controlUpdate(tpf:Float):Void {
		if (_pause || _morphData == null)
			return;

		_curFrame += _fps;

		if (!_loop && _curFrame >= _morphData.end) {
			_curFrame = _morphData.end;
			_nextFrame = Std.int(_curFrame);
			_pause = !_loop;
		} else
		{
			if (_curFrame >= _morphData.end + 1) {
				//循环情况下,_curFrame超过最后一帧后，不应该立即设为_keyframe.start,
				//因为此时正在做最后一帧和开始帧之间的插值计算，所以要等到
				//_curFrame >= _keyframe.end + 1时才设为_keyframe.start
				_curFrame = _morphData.start;
			}
			_nextFrame = Std.int(_curFrame + 1);
			if (_nextFrame > _morphData.end)
				_nextFrame = _morphData.start;
		}

		mesh.setFrame(Std.int(_curFrame), _nextFrame);

		//influence是两帧之间的插值，传递给Shader用于计算最终位置
		var interp:Float = _curFrame - Std.int(_curFrame);
		tmpVector2.x = 1 - interp;
		tmpVector2.y = interp;
		material.setVector2("u_Interpolate", tmpVector2);
	}
}
