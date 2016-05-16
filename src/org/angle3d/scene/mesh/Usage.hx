package org.angle3d.scene.mesh;

@:enum abstract Usage(Int)  
{
        
	/**
	 * Mesh data is sent once and very rarely updated.
	 */
	var STATIC = 0;

	/**
	 * Mesh data is updated occasionally (once per frame or less).
	 */
	var DYNAMIC = 1;
	
	/**
	 * Mesh data is <em>not</em> sent to GPU at all. It is only
	 * used by the CPU.
	 */
	var CPUONLY = 2;
}