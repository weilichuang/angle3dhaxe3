package angle3d.app.state;

import angle3d.app.LegacyApplication;
import angle3d.renderer.RenderManager;

/**
 * `AbstractAppState` implements some common methods
 * that make creation of AppStates easier.
 *
 */
class AbstractAppState implements AppState {
	/**
	 * `initialized` is set_to true when the method
	 * {AbstractAppState#initialize(angle3d.app.state.AppStateManager, angle3d.app.Application) }
	 * is called. When {AbstractAppState#cleanup() } is called, `initialized`
	 * is set_back to false.
	 */
	private var mInitialized:Bool;
	private var mEnabled:Bool;

	public function new() {
		mInitialized = false;
		mEnabled = true;
	}

	/**
	 * Called to initialize the AppState.
	 *
	 * @param stateManager The state manager
	 * @param app
	 */
	public function initialize(stateManager:AppStateManager, app:LegacyApplication):Void {
		mInitialized = true;
	}

	/**
	 * @return True if `initialize()` was called on the state,
	 * false otherwise.
	 */
	public function isInitialized():Bool {
		return mInitialized;
	}

	/**
	 * Enable or disable the functionality of the `AppState`.
	 * The effect of this call depends on implementation. An
	 * `AppState` starts as being enabled by default.
	 *
	 * @param active activate the AppState or not.
	 */
	public function setEnabled(value:Bool):Void {
		this.mEnabled = value;
	}

	/**
	 * @return True if the `AppState` is enabled, false otherwise.
	 *
	 * @see `AppState.setEnabled`
	 */
	public function isEnabled():Bool {
		return mEnabled;
	}

	/**
	 * Called when the state was attached.
	 *
	 * @param stateManager State manager to which the state was attached to.
	 */
	public function stateAttached(stateManager:AppStateManager):Void {

	}

	/**
	 * Called when the state was detached.
	 *
	 * @param stateManager The state manager from which the state was detached from.
	 */
	public function stateDetached(stateManager:AppStateManager):Void {

	}

	/**
	 * Called to update the state.
	 *
	 * @param tpf Time per frame.
	 */
	public function update(tpf:Float):Void {

	}

	/**
	 * Render the state.
	 *
	 * @param rm RenderManager
	 */
	public function render(rm:RenderManager):Void {

	}

	/**
	 * Called after all rendering commands are flushed.
	 */
	public function postRender():Void {

	}

	/**
	 * Cleanup the game state.
	 */
	public function cleanup():Void {
		mInitialized = false;
	}

}

