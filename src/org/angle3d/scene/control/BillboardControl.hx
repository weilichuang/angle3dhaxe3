package org.angle3d.scene.control;

import flash.geom.Vector3D;
import org.angle3d.math.FastMath;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera;
import org.angle3d.renderer.RenderManager;
import org.angle3d.renderer.ViewPort;
import org.angle3d.scene.Node;
import org.angle3d.scene.Spatial;

/**
 * andy
 * @author andy
 */

class BillboardControl extends AbstractControl
{
	private var orient:Matrix3f;
	private var look:Vector3f;
	private var left:Vector3f;
	private var alignment:Alignment;

	public function new()
	{
		super();
		orient = new Matrix3f();
		look = new Vector3f();
		left = new Vector3f();
		alignment = Alignment.Screen;
	}

	override public function cloneForSpatial(spatial:Spatial):Control
	{
		var control:BillboardControl = new BillboardControl();
		control.alignment = alignment;
		control.setSpatial(spatial);
		control.setEnabled(isEnabled());
		return control;
	}

	override private function controlRender(rm:RenderManager, vp:ViewPort):Void
	{
		var cam:Camera = vp.camera;
		rotateBillboard(cam);
	}

	/**
	 * rotate the billboard based on the type set
	 *
	 * @param cam
	 *            Camera
	 */
	private function rotateBillboard(cam:Camera):Void
	{
		switch (alignment)
		{
			case Alignment.AxialY:
				rotateAxial(cam, Vector3f.Y_AXIS);
			case Alignment.AxialZ:
				rotateAxial(cam, Vector3f.Z_AXIS);
			case Alignment.Screen:
				rotateScreenAligned(cam);
			case Alignment.Camera:
				rotateCameraAligned(cam);
		}
	}

	/**
	 * Aligns this Billboard so that it points to the camera position.
	 *
	 * @param camera
	 *            Camera
	 */
	private function rotateCameraAligned(camera:Camera):Void
	{
		var spatial:Spatial = getSpatial();
		
		look.copyFrom(camera.location);
		look.subtractLocal(spatial.getWorldTranslation());

		// coopt left for our own purposes.
		var xzp:Vector3f = left;
		// The xzp vector is the projection of the look vector on the xz plane
		xzp.setTo(look.x, 0, look.z);

		// check for undefined rotation...
		if (xzp.isZero())
		{
			return;
		}

		look.normalizeLocal();
		xzp.normalizeLocal();
		var cosp:Float = look.dot(xzp);

		// compute the local orientation matrix for the billboard
		orient.setValue(0, 0, xzp.z);
		orient.setValue(0, 1, xzp.x * -look.y);
		orient.setValue(0, 2, xzp.x * cosp);
		orient.setValue(1, 0, 0);
		orient.setValue(1, 1, cosp);
		orient.setValue(1, 2, look.y);
		orient.setValue(2, 0, -xzp.x);
		orient.setValue(2, 1, xzp.z * -look.y);
		orient.setValue(2, 2, xzp.z * cosp);

		// The billboard must be oriented to face the camera before it is
		// transformed into the world.
		spatial.setLocalRotationByMatrix3f(orient);
		fixRefreshFlags();
	}

	/**
	 * Rotate the billboard so it points directly opposite the direction the
	 * camera's facing
	 *
	 * @param camera
	 *            Camera
	 */
	private function rotateScreenAligned(camera:Camera):Void
	{
		var spatial:Spatial = getSpatial();
		
		// coopt diff for our in direction:
		look.copyFrom(camera.getDirection()).negateLocal();

		// coopt loc for our left direction:
		left.copyFrom(camera.getLeft()).negateLocal();

		orient.fromAxes(left, camera.getUp(), look);

		var parent:Node = spatial.parent;
		var rot:Quaternion = new Quaternion();
		rot.fromMatrix3f(orient);
		if (parent != null)
		{
			var pRot:Quaternion = parent.getWorldRotation();
			pRot = pRot.inverse();
			pRot.multiplyLocal(rot);
			rot = pRot;
			rot.normalizeLocal();
		}
		spatial.setLocalRotation(rot);
		fixRefreshFlags();
	}

	/**
	 * Rotate the billboard towards the camera, but keeping a given axis fixed.
	 *
	 * @param camera
	 *            Camera
	 */
	private function rotateAxial(camera:Camera, axis:Vector3f):Void
	{
		var spatial:Spatial = getSpatial();
		// Compute the additional rotation required for the billboard to face
		// the camera. To do this, the camera must be inverse-transformed into
		// the model space of the billboard.
		look.copyFrom(camera.location).subtractLocal(spatial.getWorldTranslation());
		var rotation:Quaternion = spatial.parent.getWorldRotation();
		rotation.multiplyVector(look, left); // coopt left for our own
		// purposes.
		left.x *= 1.0 / spatial.getWorldScale().x;
		left.y *= 1.0 / spatial.getWorldScale().y;
		left.z *= 1.0 / spatial.getWorldScale().z;

		// squared length of the camera projection in the xz-plane
		var lengthSquared:Float = left.x * left.x + left.z * left.z;
		if (lengthSquared < FastMath.FLT_EPSILON)
		{
			// camera on the billboard axis, rotation not defined
			return;
		}

		// unitize the projection
		var invLength:Float = 1 / Mathematics.sqrt(lengthSquared);
		if (axis.y == 1)
		{
			left.x *= invLength;
			left.y = 0.0;
			left.z *= invLength;

			// compute the local orientation matrix for the billboard
			orient.setValue(0, 0, left.z);
			orient.setValue(0, 1, 0);
			orient.setValue(0, 2, left.x);
			orient.setValue(1, 0, 0);
			orient.setValue(1, 1, 1);
			orient.setValue(1, 2, 0);
			orient.setValue(2, 0, -left.x);
			orient.setValue(2, 1, 0);
			orient.setValue(2, 2, left.z);
		}
		else if (axis.z == 1)
		{
			left.x *= invLength;
			left.y *= invLength;
			left.z = 0.0;

			// compute the local orientation matrix for the billboard
			orient.setValue(0, 0, left.y);
			orient.setValue(0, 1, left.x);
			orient.setValue(0, 2, 0);
			orient.setValue(1, 0, -left.y);
			orient.setValue(1, 1, left.x);
			orient.setValue(1, 2, 0);
			orient.setValue(2, 0, 0);
			orient.setValue(2, 1, 0);
			orient.setValue(2, 2, 1);
		}

		// The billboard must be oriented to face the camera before it is
		// transformed into the world.
		spatial.setLocalRotationByMatrix3f(orient);
		fixRefreshFlags();
	}

	private function fixRefreshFlags():Void
	{
		var spatial:Spatial = getSpatial();
		
		// force transforms to update below this node
		spatial.updateGeometricState();

		// force world bound to update
		var rootNode:Spatial = spatial;
		while (rootNode.parent != null)
		{
			rootNode = rootNode.parent;
		}
		rootNode.checkDoBoundUpdate();
	}

	/**
	 * Returns the alignment this Billboard is set_too.
	 *
	 * @return The alignment of rotation, AxialY, AxialZ, Camera or Screen.
	 */
	public function getAlignment():Alignment
	{
		return alignment;
	}

	/**
	 * Sets the type of rotation this Billboard will have. The alignment can
	 * be Camera, Screen, AxialY, or AxialZ. Invalid alignments will
	 * assume no billboard rotation.
	 */
	public function setAlignment(alignment:Alignment):Void
	{
		this.alignment = alignment;
	}
}

