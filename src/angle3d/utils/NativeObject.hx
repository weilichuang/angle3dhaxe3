package angle3d.utils;

/**
 * Describes a native object. An encapsulation of a certain object
 * on the native side of the graphics library.
 *
 * This class is used to track when OpenGL native objects are
 * collected by the garbage collector, and then invoke the proper destructor
 * on the OpenGL library to delete it from memory.
 * @author
 */
class NativeObject {
	public static inline var INVALID_ID:Int = -1;

	private var _id:Int = INVALID_ID;

	public var updateNeeded:Bool;

	public function new() {

	}
	
	/**
     * Sets the ID of the NativeObject. This method is used in Renderer and must
     * not be called by the user.
     * 
     * @param id The ID to set
     */
	public function setId(id:Int):Void {
		this._id = id;
	}

	/**
     * @return The ID of the object. Should not be used by user code in most
     * cases.
     */
	public function getId():Int {
		return this._id;
	}

	/**
	* Internal use only. Indicates that the object has changed
	* and its state needs to be updated.
	*/
	public function setUpdateNeeded():Void {
		updateNeeded = true;
	}

	/**
	 * Internal use only. Indicates that the state changes were applied.
	 */
	public function clearUpdateNeeded():Void {
		updateNeeded = false;
	}

	/**
	 * Internal use only. Check if {@link #setUpdateNeeded()} was called before.
	 */
	public function isUpdateNeeded():Bool {
		return updateNeeded;
	}

	/**
	* Called when the GL context is restarted to reset all IDs. Prevents
	* "white textures" on display restart.
	*/
	public function resetObject():Void {

	}

	/**
	 * Deletes the GL object from the GPU when it is no longer used. Called
	 * automatically by the GL object manager.
	 *
	 * @param rendererObject The renderer to be used to delete the object
	 */
	public function deleteObject(rendererObject:Any):Void {

	}

	/**
	 * Deletes any associated native {@link Buffer buffers}.
	 * This is necessary because it is unlikely that native buffers
	 * will be garbage collected naturally (due to how GC works), therefore
	 * the collection must be handled manually.
	 *
	 * Only implementations that manage native buffers need to override
	 * this method. Note that the behavior that occurs when a
	 * deleted native buffer is used is not defined, therefore this
	 * method is protected
	 */
	private function deleteNativeBuffers():Void {

	}

	/**
     * Returns a unique ID for this NativeObject. No other NativeObject shall
     * have the same ID.
     * 
     * @return unique ID for this NativeObject.
     */
	public function getUniqueId():Int {
		return -1;
	}
}