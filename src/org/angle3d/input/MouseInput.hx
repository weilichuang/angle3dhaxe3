package org.angle3d.input;

import flash.display.Stage;
import flash.events.MouseEvent;

import flash.ui.Mouse;
import org.angle3d.input.event.MouseButtonEvent;
import org.angle3d.input.event.MouseMotionEvent;
import org.angle3d.input.event.MouseWheelEvent;


/**
 * A specific API for interfacing with the mouse.
 */
class MouseInput implements Input
{
	/**
     * Mouse X axis.
     */
	public static inline var AXIS_X:Int = 0;
	
	/**
     * Mouse Y axis.
     */
	public static inline var AXIS_Y:Int = 1;
	
	/**
     * Mouse wheel axis.
     */
	public static inline var AXIS_WHEEL:Int = 2;

	/**
	 * Left mouse button.
	 */
	public static inline var BUTTON_LEFT:Int = 0;

	/**
	 * Right mouse button.
	 */
	public static inline var BUTTON_RIGHT:Int = 1;

	/**
	 * Middle mouse button.
	 */
	public static inline var BUTTON_MIDDLE:Int = 2;

	private var mStage:Stage;

	private var mListener:RawInputListener;

	private var cursorVisible:Bool;
	
	private var curX:Float;
	private var curY:Float;
	private var curWheel:Int;

	public function new()
	{
		curX = 0;
		curY = 0;
		curWheel = 0;
		cursorVisible = true;

		mStage = null;
		mListener = null;
	}

	/**
	 * set whether the mouse cursor should be visible or not.
	 *
	 * @param visible Whether the mouse cursor should be visible or not.
	 */
	public function setCursorVisible(visible:Bool):Void
	{
		this.cursorVisible = visible;
		if (visible)
		{
			Mouse.show();
		}
		else
		{
			Mouse.hide();
		}
	}

	/**
	* Initializes the native side to listen into events from the device.
	*/
	public function initialize(stage:Stage):Void
	{
		mStage = stage;

		if (mStage != null)
		{
			mStage.addEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			mStage.addEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			mStage.addEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			mStage.addEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			
			mStage.addEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
			mStage.addEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp);

			mStage.addEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleMouseDown);
			mStage.addEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMiddleMouseUp);
			
			curX = mStage.mouseX;
			curY = mStage.mouseY;
		}
	}

	/**
	 * Queries the device for input. All events should be sent to the
	 * RawInputListener set with setInputListener.
	 *
	 * @see `setInputListener`
	 */
	public function update():Void
	{

	}

	/**
	 * Ceases listening to events from the device.
	 */
	public function destroy():Void
	{
		if (mStage != null)
		{
			mStage.removeEventListener(MouseEvent.MOUSE_DOWN, onMouseDown);
			mStage.removeEventListener(MouseEvent.MOUSE_WHEEL, onMouseWheel);
			mStage.removeEventListener(MouseEvent.MOUSE_UP, onMouseUp);
			mStage.removeEventListener(MouseEvent.MOUSE_MOVE, onMouseMove);
			mStage.removeEventListener(MouseEvent.RIGHT_MOUSE_DOWN, onRightMouseDown);
			mStage.removeEventListener(MouseEvent.RIGHT_MOUSE_UP, onRightMouseUp);
			mStage.removeEventListener(MouseEvent.MIDDLE_MOUSE_DOWN, onMiddleMouseDown);
			mStage.removeEventListener(MouseEvent.MIDDLE_MOUSE_UP, onMiddleMouseUp);
			mStage = null;
		}
	}

	/**
	 * @return True if the device has been initialized and not destroyed.
	 * @see `initialize`
	 * @see `destroy`
	 */
	public function isInitialized():Bool
	{
		return mStage != null;
	}

	/**
	 * Sets the input listener to receive events from this device. The
	 * appropriate events should be dispatched through the callbacks
	 * in RawInputListener.
	 * @param listener
	 */
	public function setInputListener(listener:RawInputListener):Void
	{
		this.mListener = listener;
	}

	/**
	 * @return The current absolute time as milliseconds. This time is expected
	 * to be relative to the time given in InputEvents time property.
	 */
	public function getInputTime():Int
	{
		return Lib.getTimer();
	}
	
	private function onMouseDown(e:MouseEvent):Void
	{
		var evt:MouseButtonEvent = new MouseButtonEvent(true, e.stageX, e.stageY, BUTTON_LEFT);
		evt.setTime(Lib.getTimer());
		mListener.onMouseButtonEvent(evt);
	}
	
	private function onMouseUp(e:MouseEvent):Void
	{
		var evt:MouseButtonEvent = new MouseButtonEvent(false, e.stageX, e.stageY,BUTTON_LEFT);
		evt.setTime(Lib.getTimer());
		mListener.onMouseButtonEvent(evt);
	}
	
	private function onMiddleMouseDown(e:MouseEvent):Void
	{
		var evt:MouseButtonEvent = new MouseButtonEvent(true, e.stageX, e.stageY, BUTTON_MIDDLE);
		evt.setTime(Lib.getTimer());
		mListener.onMouseButtonEvent(evt);
	}
	
	private function onMiddleMouseUp(e:MouseEvent):Void
	{
		var evt:MouseButtonEvent = new MouseButtonEvent(false, e.stageX, e.stageY, BUTTON_MIDDLE);
		evt.setTime(Lib.getTimer());
		mListener.onMouseButtonEvent(evt);
	}

	private function onRightMouseDown(e:MouseEvent):Void
	{
		var evt:MouseButtonEvent = new MouseButtonEvent(true, e.stageX, e.stageY, BUTTON_RIGHT);
		evt.setTime(Lib.getTimer());
		mListener.onMouseButtonEvent(evt);
	}
	
	private function onRightMouseUp(e:MouseEvent):Void
	{
		var evt:MouseButtonEvent = new MouseButtonEvent(false, e.stageX, e.stageY, BUTTON_RIGHT);
		evt.setTime(Lib.getTimer());
		mListener.onMouseButtonEvent(evt);
	}

	private function onMouseMove(e:MouseEvent):Void
	{
		var dx:Float = e.stageX - curX;
		var dy:Float = e.stageY - curY;
		
		curX = e.stageX;
		curY = e.stageY;

		var evt:MouseMotionEvent = new MouseMotionEvent(curX, curY, dx, dy);
		evt.setTime(Lib.getTimer());
		mListener.onMouseMotionEvent(evt);
	}

	private function onMouseWheel(e:MouseEvent):Void
	{
		var wheelDelta:Int = e.delta;
		curWheel += wheelDelta;

		var evt:MouseWheelEvent = new MouseWheelEvent(curWheel, wheelDelta);
		evt.setTime(Lib.getTimer());
		mListener.onMouseWheelEvent(evt);
	}
}

