package org.angle3d.scene.mesh;

enum Usage 
{
        
	/**
	 * Mesh data is sent once and very rarely updated.
	 */
	STATIC;

	/**
	 * Mesh data is updated occasionally (once per frame or less).
	 */
	DYNAMIC;
	
	/**
	 * Mesh data is <em>not</em> sent to GPU at all. It is only
	 * used by the CPU.
	 */
	CPUONLY;
}