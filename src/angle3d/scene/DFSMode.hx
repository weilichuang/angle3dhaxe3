package angle3d.scene;

/**
 * Specifies the mode of the depth first search.
 */
enum DFSMode {
	/**
	 * Pre order: the current spatial is visited first, then its children.
	 */
	PRE_ORDER;

	/**
	 * Post order: the children are visited first, then the parent.
	 */
	POST_ORDER;
}