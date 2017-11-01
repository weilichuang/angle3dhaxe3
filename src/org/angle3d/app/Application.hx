package org.angle3d.app;
import org.angle3d.app.state.AppStateManager;
import org.angle3d.audio.AudioRenderer;
import org.angle3d.input.InputManager;
import org.angle3d.profile.AppProfiler;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.GLRenderer;
import org.angle3d.renderer.ViewPort;
import org.angle3d.system.AppSettings;

/**
 * The `Application` interface represents the minimum exposed
 * capabilities of a concrete application.
 */
interface Application 
{
	/**
     * @return The GUI viewport. Which is used for the on screen
     * statistics and FPS or game ui.
     */
    var guiViewPort(get,never):ViewPort;

    var viewPort(get,never):ViewPort;
	
	/**
     * @return The main camera for the application
     */
    var camera(get,never):Camera;
	
	/**
     * Determine the application's behavior when unfocused.
     *
     * @return The lost focus behavior of the application.
     */
    function getLostFocusBehavior():LostFocusBehavior;

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
	 function setLostFocusBehavior(lostFocusBehavior:LostFocusBehavior):Void;

    /**
     * Returns true if pause on lost focus is enabled, false otherwise.
     *
     * @return true if pause on lost focus is enabled
     *
     * @see #getLostFocusBehavior()
     */
	 function isPauseOnLostFocus():Bool;

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
     * @see `setLostFocusBehavior`
     */
	function setPauseOnLostFocus(pauseOnLostFocus:Bool):Void;

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
    function setSettings(settings:AppSettings):Void;

    /**
     * @return The {@link AssetManager asset manager} for this application.
     */
    //public AssetManager getAssetManager();

    /**
     * @return the input manager.
     */
    function getInputManager():InputManager;

    /**
     * @return the app state manager
     */
	function getStateManager():AppStateManager;

    /**
     * @return the render manager
     */
	function getRenderManager():RenderManager;

    /**
     * @return The renderer for the application
     */
    function getRenderer():GLRenderer;

    /**
     * @return The audio renderer for the application
     */
    function getAudioRenderer():AudioRenderer;

    /**
     * Starts the application.
     */
    function start():Void;

    /**
     * Sets an AppProfiler hook that will be called back for
     * specific steps within a single update frame.  Value defaults
     * to null.
     */
    function setAppProfiler(prof:AppProfiler):Void;

    /**
     * Returns the current AppProfiler hook, or null if none is set.
     */
    function getAppProfiler():AppProfiler;

    /**
     * Restarts the context, applying any changed settings.
     * <p>
     * Changes to the `AppSettings` of this Application are not
     * applied immediately; calling this method forces the context
     * to restart, applying the new settings.
     */
    function restart():Void;

    /**
     * Requests the context to close, shutting down the main loop
     * and making necessary cleanup operations.
     *
     * @see #stop(boolean)
     */
    function stop():Void;
}