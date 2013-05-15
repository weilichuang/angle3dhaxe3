package org.angle3d.app;

import flash.display.Sprite;
import flash.display.Stage3D;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display3D.Context3DProfile;
import flash.display3D.Context3DRenderMode;
import flash.events.Event;
import flash.Lib;
import org.angle3d.app.state.AppStateManager;
import org.angle3d.input.InputManager;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera3D;
import org.angle3d.renderer.DefaultRenderer;
import org.angle3d.renderer.IRenderer;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;



/**
 * The <code>Application</code> class represents an instance of a
 * real-time 3D rendering jME application.
 *
 * An <code>Application</code> provides all the tools that are commonly used in jME3
 * applications.
 *
 * jME3 applications should extend this class and call start() to begin the
 * application.
 *
 */
class Application extends Sprite
{
	public var guiViewPort(get, null):ViewPort;
	public var viewPort(get, null):ViewPort;
	public var camera(get, null):Camera3D;
	
	private var mRenderer:IRenderer;
	private var mRenderManager:RenderManager;

	private var mViewPort:ViewPort;
	private var mCamera:Camera3D;

	private var mGuiViewPort:ViewPort;
	private var mGuiCam:Camera3D;

	private var mStage3D:Stage3D;

	private var mContextWidth:Int;
	private var mContextHeight:Int;

	private var mInputEnabled:Bool;
	private var mInputManager:InputManager;
	private var mStateManager:AppStateManager;

	//time per frame(ms)
	private var mTimePerFrame:Float;
	private var mOldTime:Int;

	private var mProfile:ShaderProfile;

	public function new()
	{
		super();

		mInputEnabled = true;
		mOldTime = -1;

		this.addEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
	}

	public function setSize(w:Int, h:Int):Void
	{
		mContextWidth = w;
		mContextHeight = h;

		mStage3D.x = 0;
		mStage3D.y = 0;
		mStage3D.context3D.configureBackBuffer(mContextWidth, mContextHeight, 0, true);

		resize(mContextWidth, mContextHeight);
	}

	/**
	 * Starts the application as a display.
	 */
	public function start():Void
	{
		stage.addEventListener(Event.ENTER_FRAME, _onEnterFrameHandler, false, 0, true);
	}

	public function resize(w:Int, h:Int):Void
	{
		if (mRenderManager != null)
		{
			mRenderManager.resize(w, h);
		}
	}

	public function stop():Void
	{
		stage.removeEventListener(Event.ENTER_FRAME, _onEnterFrameHandler);
	}

	public function update():Void
	{
		if (mOldTime <= -1)
		{
			mTimePerFrame = 0;
			mOldTime = flash.Lib.getTimer();
			return;
		}

		var curTime:Int = flash.Lib.getTimer();
		mTimePerFrame = (curTime - mOldTime) * 0.001;
		mOldTime = curTime;

		if (mInputEnabled)
		{
			mInputManager.update(mTimePerFrame);
		}
	}

	
	private inline function get_guiViewPort():ViewPort
	{
		return mGuiViewPort;
	}

	
	private inline function get_viewPort():ViewPort
	{
		return mViewPort;
	}

	private function initialize(width:Int, height:Int):Void
	{
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		
		initShaderManager();
		initCamera(width, height);
		initStateManager();
		initInput();
	}

	private function initInput():Void
	{
		mInputManager = new InputManager();
		mInputManager.initialize(stage);
	}

	private function initStateManager():Void
	{
		mStateManager = new AppStateManager(this);
	}

	private function initShaderManager():Void
	{
		ShaderManager.init(mStage3D.context3D, mProfile);
	}

	/**
	 * Creates the camera to use for rendering. Default values are perspective
	 * projection with 45° field of view, with near and far values 1 and 1000
	 * units respectively.
	 */
	private function initCamera(width:Int, height:Int):Void
	{
		setSize(width, height);

		mCamera = new Camera3D(width, height);

		mCamera.setFrustumPerspective(60, width / height, 1, 5000);
		mCamera.location = new Vector3f(0, 0, 10);
		mCamera.lookAt(new Vector3f(0, 0, 0), Vector3f.Y_AXIS);

		mRenderer = new DefaultRenderer(mStage3D);
		//renderer.setAntiAlias(4);
		mRenderManager = new RenderManager(mRenderer);

		mViewPort = mRenderManager.createMainView("Default", mCamera);
		mViewPort.setClearFlags(true, true, true);

		mGuiCam = new Camera3D(width, height);
		mGuiViewPort = mRenderManager.createPostView("Gui Default", mGuiCam);
		mGuiViewPort.setClearFlags(false, false, false);
	}
	
	private function get_camera():Camera3D
	{
		return mCamera;
	}

	private function _addedToStageHandler(e:Event):Void
	{
		this.removeEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);

		//StageProxy.stage = stage;

		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;

		initContext3D();
	}

	private function initContext3D():Void
	{
		mStage3D = stage.stage3Ds[0];
		mStage3D.addEventListener(Event.CONTEXT3D_CREATE, _context3DCreateHandler);

		mProfile = ShaderProfile.BASELINE;
		mStage3D.requestContext3D("auto", ShaderProfile.BASELINE);
	}

	private function _context3DCreateHandler(e:Event):Void
	{
		#if debug
			Lib.trace(mStage3D.context3D.driverInfo);
			mStage3D.context3D.enableErrorChecking = true;
		#end

		if (isSoftware(mStage3D.context3D.driverInfo))
		{
			mProfile = ShaderProfile.BASELINE_CONSTRAINED;
			mStage3D.requestContext3D("auto", ShaderProfile.BASELINE_CONSTRAINED);
		}
		else
		{
			stage.addEventListener(Event.RESIZE, _resizeHandler, false, 0, true);
			initialize(stage.stageWidth, stage.stageHeight);
		}
	}

	private function isSoftware(driverInfo:String):Bool
	{
		return driverInfo.indexOf("Software") > -1;
	}

	private function _resizeHandler(e:Event):Void
	{
		setSize(stage.stageWidth, stage.stageHeight);
	}

	private function _onEnterFrameHandler(e:Event):Void
	{
		update();
	}
}

