package org.angle3d.app;

import flash.display.Sprite;
import flash.display.Stage3D;
import flash.display.StageAlign;
import flash.display.StageScaleMode;
import flash.display3D.Context3D;
import flash.display3D.Context3DProfile;
import flash.display3D.Context3DRenderMode;
import flash.events.ErrorEvent;
import flash.events.Event;
import flash.Lib;
import flash.Vector;
import org.angle3d.app.state.AppState;
import org.angle3d.app.state.AppStateManager;
import org.angle3d.asset.AssetManager;
import org.angle3d.asset.LoaderType;
import org.angle3d.asset.caches.ImageCache;
import org.angle3d.asset.caches.NormalCache;
import org.angle3d.asset.parsers.BytesParser;
import org.angle3d.asset.parsers.ImageParser;
import org.angle3d.asset.parsers.TextParser;
import org.angle3d.audio.AudioRenderer;
import org.angle3d.input.InputManager;
import org.angle3d.manager.ShaderManager;
import org.angle3d.material.shader.ShaderProfile;
import org.angle3d.math.Vector3f;
import org.angle3d.profile.AppProfiler;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.DefaultRenderer;
import org.angle3d.renderer.Stage3DRenderer;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.system.AppSettings;
import org.angle3d.utils.Logger;

/**
 * The `LegacyApplication` class represents an instance of a
 * real-time 3D rendering application.
 *
 * An `LegacyApplication` provides all the tools that are commonly used in Angle3D
 * applications.
 *
 * Angle3D applications *SHOULD NOT EXTEND* this class but extend `SimpleApplication`instead.
 *
 */
class LegacyApplication extends Sprite implements Application
{
	public var guiViewPort(get, never):ViewPort;
	public var viewPort(get, never):ViewPort;
	public var camera(get, never):Camera;
	
	private var mLostFocusBehavior:LostFocusBehavior;
	
	private var mSettings:AppSettings;
	private var mProf:AppProfiler;
	
	private var mAudioRenderer:AudioRenderer;
	private var mRenderer:Stage3DRenderer;
	private var mRenderManager:RenderManager;

	private var mViewPort:ViewPort;
	private var mCamera:Camera;

	private var mGuiViewPort:ViewPort;
	private var mGuiCam:Camera;

	private var mStage3D:Stage3D;
	private var mContext3D:Context3D;

	private var mContextWidth:Int;
	private var mContextHeight:Int;

	private var mInputEnabled:Bool = true;
	private var mInputManager:InputManager;
	private var mStateManager:AppStateManager;

	//time per frame(ms)
	private var mTimePerFrame:Float;
	private var mOldTime:Int;

	private var mProfile:ShaderProfile;
	
	private var mSpeed:Float = 1;
	private var mPaused:Bool = false;
	
	private var _initialStates:Array<AppState>;

	public function new(initialStates:Array<AppState> = null)
	{
		super();
		
		this._initialStates = initialStates;
		
		mLostFocusBehavior = LostFocusBehavior.ThrottleOnLostFocus;

		mInputEnabled = true;
		mOldTime = -1;

		this.addEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);
	}
	
	/**
     * Determine the application's behavior when unfocused.
     *
     * @return The lost focus behavior of the application.
     */
    public function getLostFocusBehavior():LostFocusBehavior
	{
        return mLostFocusBehavior;
    }

    /**
     * Change the application's behavior when unfocused.
     *
     * By default, the application will
     * {@link LostFocusBehavior#ThrottleOnLostFocus throttle the update loop}
     * so as to not take 100% CPU usage when it is not in focus, e.g.
     * alt-tabbed, minimized, or obstructed by another window.
     *
     * @param lostFocusBehavior The new lost focus behavior to use.
     *
     * @see LostFocusBehavior
     */
    public function setLostFocusBehavior(lostFocusBehavior:LostFocusBehavior):Void
	{
        this.mLostFocusBehavior = lostFocusBehavior;
    }
	
	/**
     * Returns true if pause on lost focus is enabled, false otherwise.
     *
     * @return true if pause on lost focus is enabled
     *
     * @see #getLostFocusBehavior()
     */
    public function isPauseOnLostFocus():Bool
	{
        return getLostFocusBehavior() == LostFocusBehavior.PauseOnLostFocus;
    }

    /**
     * Enable or disable pause on lost focus.
     * <p>
     * By default, pause on lost focus is enabled.
     * If enabled, the application will stop updating
     * when it loses focus or becomes inactive (e.g. alt-tab).
     * For online or real-time applications, this might not be preferable,
     * so this feature should be set to disabled. For other applications,
     * it is best to keep it on so that CPU usage is not used when
     * not necessary.
     *
     * @param pauseOnLostFocus True to enable pause on lost focus, false
     * otherwise.
     *
     * @see #setLostFocusBehavior(com.jme3.app.LostFocusBehavior)
     */
    public function setPauseOnLostFocus(pauseOnLostFocus:Bool):Void
	{
        if (pauseOnLostFocus) 
		{
            setLostFocusBehavior(LostFocusBehavior.PauseOnLostFocus);
        } 
		else
		{
            setLostFocusBehavior(LostFocusBehavior.Disabled);
        }
    }
	
	/**
     * Set the display settings to define the display created.
     * <p>
     * Examples of display parameters include display pixel width and height,
     * color bit depth, z-buffer bits, anti-aliasing samples, and update frequency.
     * If this method is called while the application is already running, then
     * {@link #restart() } must be called to apply the settings to the display.
     *
     * @param settings The settings to set.
     */
    public function setSettings(settings:AppSettings):Void
	{
        this.mSettings = settings;
        //if (context != null && settings.useInput() != inputEnabled){
            //// may need to create or destroy input based
            //// on settings change
            //inputEnabled = !inputEnabled;
            //if (inputEnabled){
                //initInput();
            //}else{
                //destroyInput();
            //}
        //}else{
            //inputEnabled = settings.useInput();
        //}
    }
	
	/**
     * Sets an AppProfiler hook that will be called back for
     * specific steps within a single update frame.  Value defaults
     * to null.
     */
    public function setAppProfiler(prof:AppProfiler):Void
	{
        this.mProf = prof;
        if (mRenderManager != null) {
            mRenderManager.setAppProfiler(prof);
        }
    }

    /**
     * Returns the current AppProfiler hook, or null if none is set.
     */
    public function getAppProfiler():AppProfiler
	{
        return mProf;
    }

	public function setSize(w:Int, h:Int):Void
	{
		mContextWidth = w;
		mContextHeight = h;
		
		if (mContext3D == null)
			return;

		mContext3D.configureBackBuffer(mContextWidth, mContextHeight, 0, true);

		reshape(mContextWidth, mContextHeight);
	}

	/**
	 * Starts the application as a display.
	 */
	public function start():Void
	{
		stage.addEventListener(Event.ENTER_FRAME, _onEnterFrameHandler, false, 0, true);
	}
	
	/**
     * Restarts the context, applying any changed settings.
     * <p>
     * Changes to the `AppSettings` of this Application are not
     * applied immediately; calling this method forces the context
     * to restart, applying the new settings.
     */
	public function restart():Void
	{
		
	}

	/**
     * Requests the context to close, shutting down the main loop
     * and making necessary cleanup operations.
     */
	public function stop():Void
	{
		stage.removeEventListener(Event.ENTER_FRAME, _onEnterFrameHandler);
	}

	public function reshape(w:Int, h:Int):Void
	{
		if (mRenderManager != null)
		{
			mRenderManager.notifyReshape(w, h);
		}
	}
	
	public function update():Void
	{
		if (mOldTime <= -1)
		{
			mTimePerFrame = 0;
			mOldTime = Lib.getTimer();
			return;
		}

		var curTime:Int = Lib.getTimer();
		mTimePerFrame = (curTime - mOldTime) * 0.001;
		mOldTime = curTime;

		if (mInputEnabled)
		{
			mInputManager.update(mTimePerFrame);
		}
	}

	private function initialize(width:Int, height:Int):Void
	{
		stage.align = StageAlign.TOP_LEFT;
		stage.scaleMode = StageScaleMode.NO_SCALE;
		
		initAssetMananger();
		initShaderManager();
		initCamera(width, height);
		initStateManager();
		initInput();
		initAudio();
	}
	
	
	private function initAssetMananger():Void
	{
		AssetManager.isTrace = true;
		
		AssetManager.addCache(LoaderType.BINARY, new NormalCache());
		AssetManager.addParser(LoaderType.BINARY, new BytesParser());
		
		AssetManager.addCache(LoaderType.TEXT, new NormalCache());
		AssetManager.addParser(LoaderType.TEXT, new TextParser());
		
		AssetManager.addCache(LoaderType.IMAGE, new ImageCache());
		//不能使用new ImageParser，否则同时加载多个图片的时候会有问题
		AssetManager.addParser(LoaderType.IMAGE, ImageParser);
	}
	
	private function initAudio():Void
	{
		
	}

	/**
     * Initializes mouse and keyboard input. Also
     * initializes joystick input if joysticks are enabled in the
     * AppSettings.
     */
	private function initInput():Void
	{
		mInputManager = new InputManager();
		mInputManager.initialize(stage);
	}
	
	public function getInputManager():InputManager
	{
		return mInputManager;
	}
	
	public function getRenderManager():RenderManager
	{
		return mRenderManager;
	}
	
	public function getRenderer():Stage3DRenderer
	{
		return mRenderer;
	}
	
	public function getStateManager():AppStateManager
	{
		return mStateManager;
	}
	
	/**
     * @return The audio renderer for the application
     */
    public function getAudioRenderer():AudioRenderer
	{
        return mAudioRenderer;
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

		mCamera = new Camera(width, height);

		mCamera.setFrustumPerspective(45, width / height, 1, 1000);
		mCamera.location = new Vector3f(0, 0, 10);
		mCamera.lookAt(new Vector3f(0, 0, 0), Vector3f.UNIT_Y);

		mRenderer = new DefaultRenderer(mStage3D,mProfile);
		mRenderer.initialize();
		mRenderManager = new RenderManager(mRenderer);
		
		if (mProf != null)
		{
			mRenderManager.setAppProfiler(mProf);
		}

		mViewPort = mRenderManager.createMainView("Default", mCamera);
		mViewPort.setClearFlags(true, true, true);

		// Create a new cam for the gui
		mGuiCam = new Camera(width, height);
		mGuiViewPort = mRenderManager.createPostView("Gui Default", mGuiCam);
		mGuiViewPort.setClearFlags(false, false, false);
	}

	private function _addedToStageHandler(e:Event):Void
	{
		this.removeEventListener(Event.ADDED_TO_STAGE, _addedToStageHandler);

		stage.scaleMode = StageScaleMode.NO_SCALE;
		stage.align = StageAlign.TOP_LEFT;
		
		stage.addEventListener(Event.RESIZE, _resizeHandler, false, 0, true);

		initContext3D();
	}

	private function initContext3D():Void
	{
		mStage3D = stage.stage3Ds[0];
		mStage3D.x = 0;
		mStage3D.y = 0;
		
		mStage3D.addEventListener(Event.CONTEXT3D_CREATE, _context3DCreateHandler);
		mStage3D.addEventListener(ErrorEvent.ERROR, _context3DCreateErrorHandler);
		
		if (Reflect.hasField(mStage3D,"requestContext3DMatchingProfiles"))
		{
			untyped mStage3D["requestContext3DMatchingProfiles"](Vector.ofArray(["standard", "standardConstrained", "baselineExtended", "baseline", "baselineConstrained"]));
		}
		else
		{
			mProfile = Context3DProfile.BASELINE;
			mStage3D.requestContext3D(cast Context3DRenderMode.AUTO, Context3DProfile.BASELINE);
		}
	}
	
	private function _context3DCreateErrorHandler(e:Event):Void
	{
		
	}

	private function _context3DCreateHandler(e:Event):Void
	{
		#if debug
			Logger.log(mStage3D.context3D.driverInfo);
			mStage3D.context3D.enableErrorChecking = true;
		#else
			mStage3D.context3D.enableErrorChecking = false;
		#end
		
		var oldContext3D:Context3D = mContext3D;
		
		mContext3D = mStage3D.context3D;
		
		if(Reflect.hasField(mContext3D,"profile"))
			mProfile = untyped mContext3D["profile"];
			
		Angle3D.checkSupportSamplerState(mContext3D);
			
		#if debug
		Logger.log("Context3D profile is:" + mProfile);
		#end
		
		if (oldContext3D != null)
		{
			recreateGPUInfo();
		}
		
		initialize(stage.stageWidth, stage.stageHeight);
	}
	
	/**
	 * GPU设置丢失，需要重新创建所有相关内容
	 */
	public function recreateGPUInfo():Void
	{
		//TODO
		Lib.trace("recreateGPUInfo");
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
	
	private inline function get_guiViewPort():ViewPort
	{
		return mGuiViewPort;
	}

	private inline function get_viewPort():ViewPort
	{
		return mViewPort;
	}
	
	private function get_camera():Camera
	{
		return mCamera;
	}
}

