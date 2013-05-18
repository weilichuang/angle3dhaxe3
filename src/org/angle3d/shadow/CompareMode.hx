package org.angle3d.shadow;

/**
 * ...
 * @author 
 */
enum CompareMode
{
	/**
     * Shadow depth comparisons are done by using shader code
     */
    Software;
    /**
     * Shadow depth comparisons are done by using the GPU's dedicated shadowing
     * pipeline.
     */
    Hardware;
}