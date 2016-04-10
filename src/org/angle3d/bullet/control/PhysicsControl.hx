package org.angle3d.bullet.control;
import org.angle3d.scene.control.Control;

/**
 
 */

interface PhysicsControl extends Control
{
	/**
     * Only used internally, do not call.
     * @param space
     */
    function setPhysicsSpace(space:PhysicsSpace):Void;

    function getPhysicsSpace():PhysicsSpace;
}