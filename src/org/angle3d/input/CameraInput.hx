package org.angle3d.input;

/**
 * This class defines all the constants used in camera handlers for registration
 * with the inputManager
 *
 */
class CameraInput
{
	//ChaseCamera constants
    /**
     * Chase camera mapping for moving down. Default assigned to
     * MouseInput.AXIS_Y direction depending on the invertYaxis configuration
     */
    public static inline var CHASECAM_DOWN:String = "ChaseCamDown";
    /**
     * Chase camera mapping for moving up. Default assigned to MouseInput.AXIS_Y
     * direction depending on the invertYaxis configuration
     */
    public static inline var CHASECAM_UP:String = "ChaseCamUp";
    /**
     * Chase camera mapping for zooming in. Default assigned to
     * MouseInput.AXIS_WHEEL direction positive
     */
    public static inline var CHASECAM_ZOOMIN:String = "ChaseCamZoomIn";
    /**
     * Chase camera mapping for zooming out. Default assigned to
     * MouseInput.AXIS_WHEEL direction negative
     */
    public static inline var CHASECAM_ZOOMOUT:String = "ChaseCamZoomOut";
    /**
     * Chase camera mapping for moving left. Default assigned to
     * MouseInput.AXIS_X direction depending on the invertXaxis configuration
     */
    public static inline var CHASECAM_MOVELEFT:String = "ChaseCamMoveLeft";
    /**
     * Chase camera mapping for moving right. Default assigned to
     * MouseInput.AXIS_X direction depending on the invertXaxis configuration
     */
    public static inline var CHASECAM_MOVERIGHT:String = "ChaseCamMoveRight";
    /**
     * Chase camera mapping to initiate the rotation of the cam. Default assigned
     * to MouseInput.BUTTON_LEFT and MouseInput.BUTTON_RIGHT
     */
    public static inline var CHASECAM_TOGGLEROTATE:String = "ChaseCamToggleRotate";
    
        
    
    //fly cameara constants
    /**
     * Fly camera mapping to look left. Default assigned to MouseInput.AXIS_X,
     * direction negative
     */
    public static inline var FLYCAM_LEFT:String = "FLYCAM_Left";
    /**
     * Fly camera mapping to look right. Default assigned to MouseInput.AXIS_X,
     * direction positive
     */
    public static inline var FLYCAM_RIGHT:String = "FLYCAM_Right";
    /**
     * Fly camera mapping to look up. Default assigned to MouseInput.AXIS_Y,
     * direction positive
     */
    public static inline var FLYCAM_UP:String = "FLYCAM_Up";
    /**
     * Fly camera mapping to look down. Default assigned to MouseInput.AXIS_Y,
     * direction negative
     */
    public static inline var FLYCAM_DOWN:String = "FLYCAM_Down";
    /**
     * Fly camera mapping to move left. Default assigned to KeyInput.KEY_A   
     */
    public static inline var FLYCAM_STRAFELEFT:String = "FLYCAM_StrafeLeft";
    /**
     * Fly camera mapping to move right. Default assigned to KeyInput.KEY_D  
     */
    public static inline var FLYCAM_STRAFERIGHT:String = "FLYCAM_StrafeRight";
    /**
     * Fly camera mapping to move forward. Default assigned to KeyInput.KEY_W   
     */
    public static inline var FLYCAM_FORWARD:String = "FLYCAM_Forward";
    /**
     * Fly camera mapping to move backward. Default assigned to KeyInput.KEY_S   
     */
    public static inline var FLYCAM_BACKWARD:String = "FLYCAM_Backward";
    /**
     * Fly camera mapping to zoom in. Default assigned to MouseInput.AXIS_WHEEL,
     * direction positive
     */
    public static inline var FLYCAM_ZOOMIN:String = "FLYCAM_ZoomIn";
    /**
     * Fly camera mapping to zoom in. Default assigned to MouseInput.AXIS_WHEEL,
     * direction negative
     */
    public static inline var FLYCAM_ZOOMOUT:String = "FLYCAM_ZoomOut";
    /**
     * Fly camera mapping to toggle rotation. Default assigned to 
     * MouseInput.BUTTON_LEFT   
     */
    public static inline var FLYCAM_ROTATEDRAG:String = "FLYCAM_RotateDrag";
    /**
     * Fly camera mapping to move up. Default assigned to KeyInput.KEY_Q   
     */
    public static inline var FLYCAM_RISE:String = "FLYCAM_Rise";
    /**
     * Fly camera mapping to move down. Default assigned to KeyInput.KEY_W   
     */
    public static inline var FLYCAM_LOWER:String = "FLYCAM_Lower";
    
    public static inline var FLYCAM_INVERTY:String = "FLYCAM_InvertY";
}