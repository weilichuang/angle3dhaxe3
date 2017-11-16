import org.angle3d.shader.UniformBindingManager;
package org.angle3d.shader;

import org.angle3d.math.Matrix3f;
import org.angle3d.math.Matrix4f;
import org.angle3d.math.Vector2f;
import org.angle3d.math.Vector3f;
import org.angle3d.math.Vector4f;
import org.angle3d.renderer.Camera;

/**
 * `UniformBindingManager` helps RenderManager to manage uniform bindings.
 *
 * The updateUniformBindings will update  a given list of uniforms based
 * on the current state of the manager.
 *
 */
class UniformBindingManager {
	private var viewX:Int;
	private var viewY:Int;
	private var viewWidth:Int;
	private var viewHeight:Int;

	private var camUp:Vector3f;
	private var camLeft:Vector3f;
	private var camDir:Vector3f;
	private var camLoc:Vector3f;

	private var tmpMatrix:Matrix4f;
	private var tmpMatrix3:Matrix3f;

	private var viewMatrix:Matrix4f;
	private var projMatrix:Matrix4f;
	private var viewProjMatrix:Matrix4f;
	private var worldMatrix:Matrix4f;

	private var worldViewMatrix:Matrix4f;
	private var worldViewProjMatrix:Matrix4f;
	private var normalMatrix:Matrix3f;

	private var worldMatrixInv:Matrix4f;
	private var viewMatrixInv:Matrix4f;
	private var projMatrixInv:Matrix4f;
	private var viewProjMatrixInv:Matrix4f;
	private var worldViewMatrixInv:Matrix4f;
	private var normalMatrixInv:Matrix3f;
	private var worldViewProjMatrixInv:Matrix4f;

	private var viewPort:Vector4f;
	private var resolution:Vector2f;
	private var resolutionInv:Vector2f;
	private var nearFar:Vector4f;

	public function new() {
		camUp = new Vector3f();
		camLeft = new Vector3f();
		camDir = new Vector3f();
		camLoc = new Vector3f();

		tmpMatrix = new Matrix4f();
		tmpMatrix3 = new Matrix3f();

		viewMatrix = new Matrix4f();
		projMatrix = new Matrix4f();
		viewProjMatrix = new Matrix4f();
		worldMatrix = new Matrix4f();

		worldViewMatrix = new Matrix4f();
		worldViewProjMatrix = new Matrix4f();
		normalMatrix = new Matrix3f();

		worldMatrixInv = new Matrix4f();
		viewMatrixInv = new Matrix4f();
		projMatrixInv = new Matrix4f();
		viewProjMatrixInv = new Matrix4f();
		worldViewMatrixInv = new Matrix4f();
		normalMatrixInv = new Matrix3f();
		worldViewProjMatrixInv = new Matrix4f();

		viewPort = new Vector4f();
		resolution = new Vector2f();
		resolutionInv = new Vector2f();
		nearFar = new Vector4f();
	}

	/**
	 * Internal use only.
	 * Updates the given list of uniforms with `UniformBinding`
	 * based on the current world state.
	 */
	public function updateUniformBindings(shader:Shader):Void {
		var params:Array<Uniform> = shader.getBoundUniforms();
		var pLength:Int = params.length;
		for (i in 0...pLength) {
			var u:Uniform = params[i];
			switch (u.binding) {
				case UniformBinding.WorldMatrix:
					u.setValue(VarType.Matrix4, worldMatrix);

				case UniformBinding.ViewMatrix:
					u.setValue(VarType.Matrix4, viewMatrix);

				case UniformBinding.ProjectionMatrix:
					u.setValue(VarType.Matrix4, projMatrix);

				case UniformBinding.ViewProjectionMatrix:
					u.setValue(VarType.Matrix4, viewProjMatrix);

				case UniformBinding.WorldViewMatrix:
					tmpMatrix.copyMultLocal(viewMatrix, worldMatrix);
					u.setValue(VarType.Matrix4, tmpMatrix);

				case UniformBinding.WorldViewProjectionMatrix:
					tmpMatrix.copyMultLocal(viewProjMatrix, worldMatrix);
					u.setValue(VarType.Matrix4, tmpMatrix);

				case UniformBinding.NormalMatrix:
					tmpMatrix.copyMultLocal(viewMatrix, worldMatrix);
					tmpMatrix.toMatrix3f(tmpMatrix3);
					tmpMatrix3.invertLocal();
					tmpMatrix3.transposeLocal();
					u.setValue(VarType.Matrix3, tmpMatrix3);

				case UniformBinding.WorldMatrixInverse:
					tmpMatrix.copyFrom(worldMatrix);
					tmpMatrix.invertLocal();
					u.setValue(VarType.Matrix4, tmpMatrix);

				case UniformBinding.ViewMatrixInverse:
					tmpMatrix.copyFrom(viewMatrix);
					tmpMatrix.invertLocal();
					u.setValue(VarType.Matrix4, tmpMatrix);

				case UniformBinding.ProjectionMatrixInverse:
					tmpMatrix.copyFrom(projMatrix);
					tmpMatrix.invertLocal();
					u.setValue(VarType.Matrix4, tmpMatrix);

				case UniformBinding.ViewProjectionMatrixInverse:
					tmpMatrix.copyFrom(viewProjMatrix);
					tmpMatrix.invertLocal();
					u.setValue(VarType.Matrix4, tmpMatrix);

				case UniformBinding.WorldViewMatrixInverse:
					tmpMatrix.copyMultLocal(viewMatrix, worldMatrix);
					tmpMatrix.invertLocal();
					u.setValue(VarType.Matrix4, tmpMatrix);

				case UniformBinding.NormalMatrixInverse:
					tmpMatrix.copyMultLocal(viewMatrix, worldMatrix);
					tmpMatrix3 = tmpMatrix.toMatrix3f();
					tmpMatrix3.invertLocal();
					tmpMatrix3.transposeLocal();
					tmpMatrix3.invertLocal();
					u.setValue(VarType.Matrix3, tmpMatrix3);

				case UniformBinding.WorldViewProjectionMatrixInverse:
					tmpMatrix.copyMultLocal(viewProjMatrix, worldMatrix);
					tmpMatrix.invertLocal();
					u.setValue(VarType.Matrix4, tmpMatrix);

				case UniformBinding.CameraPosition:
					u.setValue(VarType.Vector3, camLoc);

				case UniformBinding.CameraDirection:
					u.setValue(VarType.Vector3, camDir);

				case UniformBinding.ViewPort:
					u.setValue(VarType.Vector4,viewPort);

				case UniformBinding.NearFar:
					u.setValue(VarType.Vector4,nearFar);
			}
		}
	}

	/**
	 * Internal use only. Sets the world matrix to use for future
	 * rendering. This has no effect unless objects are rendered manually
	 * using `Material.render`.
	 * Using `renderGeometry` will override this value.
	 *
	 * @param mat The world matrix to set
	 */
	public function setWorldMatrix(mat:Matrix4f):Void {
		worldMatrix.copyFrom(mat);
	}

	public function setCamera(cam:Camera, viewMatrix:Matrix4f, projMatrix:Matrix4f, viewProjMatrix:Matrix4f):Void {
		this.viewMatrix.copyFrom(viewMatrix);
		this.projMatrix.copyFrom(projMatrix);
		this.viewProjMatrix.copyFrom(viewProjMatrix);

		camLoc.copyFrom(cam.location);
		cam.getLeft(camLeft);
		cam.getUp(camUp);
		cam.getDirection(camDir);

		nearFar.x = cam.frustumNear;
		nearFar.y = cam.frustumFar;
		nearFar.z = 1 / (cam.frustumFar - cam.frustumNear);
		nearFar.w = cam.frustumNear + cam.frustumFar;
	}

	public function setViewPort(viewX:Int, viewY:Int, viewWidth:Int, viewHeight:Int):Void {
		this.viewX = viewX;
		this.viewY = viewY;
		this.viewWidth = viewWidth;
		this.viewHeight = viewHeight;

		viewPort.setTo(viewX, viewY, viewWidth, viewHeight);
	}
}
