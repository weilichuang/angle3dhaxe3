package org.angle3d.app;

/**
 * Defines the behavior of an application when it is not in focus or minimized.
 */
enum LostFocusBehavior {
	/**
	 * No lost focus behavior.
	 *
	 * The application will update and render as usual.
	 */
	Disabled;
	/**
	 * The appl;ication will not update when unfocused.
	 *
	 * For online or real-time applications, this might not be preferable. For
	 * other applications, it is best to keep it on so that CPU usage is not
	 * used when not necessary.
	 */
	PauseOnLostFocus;
	/**
	 * The application will update at a reduced rate when unfocused.
	 *
	 * This is a compromise between {@link #Disabled} and
	 * {@link #PauseOnLostFocus}, allowing the application to update at a
	 * reduced rate (20 updates per second), but without rendering.
	 */
	ThrottleOnLostFocus;
}