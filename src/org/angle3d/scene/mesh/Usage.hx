package org.angle3d.scene.mesh;

@:final class Usage 
{
        
	/**
	 * Mesh data is sent once and very rarely updated.
	 */
	public static inline var STATIC:Int = 0;

	/**
	 * Mesh data is updated occasionally (once per frame or less).
	 */
	public static inline var DYNAMIC:Int = 1;
	
	/**
	 * Mesh data is <em>not</em> sent to GPU at all. It is only
	 * used by the CPU.
	 */
	public static inline var CPUONLY:Int = 2;
}