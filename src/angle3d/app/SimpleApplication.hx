package angle3d.app;

import flash.ui.Keyboard;
import angle3d.input.FlyByCamera;
import angle3d.input.controls.ActionListener;
import angle3d.input.controls.KeyTrigger;
import angle3d.math.Quaternion;
import angle3d.math.Vector3f;
import angle3d.pool.Matrix3fPool;
import angle3d.pool.Matrix4fPool;
import angle3d.pool.QuaternionPool;
import angle3d.pool.Vector3fPool;
import angle3d.renderer.RenderManager;
import angle3d.renderer.queue.QueueBucket;
import angle3d.scene.CullHint;
import angle3d.scene.Node;
import angle3d.utils.Logger;

/**
 * SimpleApplication extends the Application
 * class to provide default functionality like a first-person camera,
 * and an accessible root node that is updated and rendered regularly.
 * Additionally, SimpleApplication will display a statistics view
 * using the StatsView class. It will display
 * the current frames-per-second value on-screen in addition to the statistics.
 * Several keys have special functionality in SimpleApplication:<br/>
 *
 * <table>
 * <tr><td>Esc</td><td>- Close the application</td></tr>
 * <tr><td>C</td><td>- Display the camera position and rotation in the console.</td></tr>
 * <tr><td>M</td><td>- Display memory usage in the console.</td></tr>
 * </table>
 */
class SimpleApplication extends LegacyApplication implements ActionListener {
	public static inline var INPUT_MAPPING_EXIT:String = "SIMPLEAPP_Exit";
	public static inline var INPUT_MAPPING_CAMERA_POS:String = "SIMPLEAPP_CameraPos";

	public var gui(get, null):Node;
	public var scene(get, null):Node;

	private var mScene:Node;
	private var mGui:Node;

	private var flyCam:FlyByCamera;

	public function new() {
		super();
	}

	public function onAction(name:String, value:Bool, tpf:Float):Void {
		if (!value) {
			return;
		}

		if (name == INPUT_MAPPING_EXIT) {
			stop();
		} else if (name == INPUT_MAPPING_CAMERA_POS) {
			if (camera != null) {
				var loc:Vector3f = camera.location;
				var rot:Quaternion = camera.rotation;

				#if debug
				Logger.log("Camera Position: (" + loc.x + ", " + loc.y + ", " + loc.z + ")");
				Logger.log("Camera Rotation: " + rot);
				Logger.log("Camera Direction: " + camera.getDirection());
				#end

			}
		}
	}

	/**
	 * Retrieves flyCam
	 * @return flyCam Camera object
	 *
	 */
	public function getFlyByCamera():FlyByCamera {
		return flyCam;
	}

	private inline function get_gui():Node {
		return mGui;
	}

	private inline function get_scene():Node {
		return mScene;
	}

	override private function initialize(width:Int, height:Int):Void {
		super.initialize(width, height);

		mScene = new Node("Root Node");
		mViewPort.attachScene(mScene);

		mGui = new Node("Gui Node");
		mGui.localQueueBucket = QueueBucket.Gui;
		mGui.localCullHint = CullHint.Never;
		mGuiViewPort.attachScene(mGui);

		if (mInputManager != null) {
			flyCam = new FlyByCamera(camera);
			flyCam.setMoveSpeed(10);
			flyCam.setRotationSpeed(3.0);
			flyCam.registerWithInput(mInputManager);
			flyCam.setDragToRotate(true);

			mInputManager.addTrigger(INPUT_MAPPING_CAMERA_POS, new KeyTrigger(Keyboard.C));

			var arr:Array<String> = [INPUT_MAPPING_CAMERA_POS];

			mInputManager.addListener(this, arr);
		}
	}

	override public function update():Void {
		super.update();

		//update states
		mStateManager.update(mTimePerFrame);

		// simple update and root node
		simpleUpdate(mTimePerFrame);

		mScene.updateLogicalState(mTimePerFrame);
		mGui.updateLogicalState(mTimePerFrame);

		mScene.updateGeometricState();
		mGui.updateGeometricState();

		#if USE_STATISTICS
		mRenderer.getStatistics().totalTriangle = mScene.getTriangleCount() + mGui.getTriangleCount();
		mRenderer.getStatistics().renderTriangle = 0;
		mRenderer.getStatistics().drawCount = 0;
		#end

		// render states
		mStateManager.render(mRenderManager);

		mRenderManager.render(mTimePerFrame);

		simpleRender(mRenderManager);

		mStateManager.postRender();

		Vector3fPool.instance.gc();
		QuaternionPool.instance.gc();
		Matrix3fPool.instance.gc();
		Matrix4fPool.instance.gc();
	}

	public function simpleInitApp():Void {
		start();
	}

	public function simpleUpdate(tpf:Float):Void {

	}

	public function simpleRender(rm:RenderManager):Void {

	}
}
