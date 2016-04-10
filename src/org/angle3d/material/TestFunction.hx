package org.angle3d.material;

/**
 * `TestFunction` specifies the testing function for stencil test
 * function and alpha test function.
 *
 * <p>The functions work similarly as described except that for stencil
 * test function, the reference value given in the stencil command is
 * the input value while the reference is the value already in the stencil
 * buffer.
 */
typedef TestFunction = flash.display3D.Context3DCompareMode;