package org.angle3d.effect.cpu;

import org.angle3d.math.Color;
import org.angle3d.math.Matrix3f;
import org.angle3d.math.Vector3f;
import org.angle3d.renderer.Camera3D;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.SubMesh;
import org.angle3d.scene.mesh.VertexBuffer;
import flash.Vector;
/**
 * The <code>ParticleMesh</code> is the underlying visual implementation of a particle emitter.
 *
 */
class ParticleCPUMesh extends Mesh
{
	private var imageX:Int;
	private var imageY:Int;
	private var uniqueTexCoords:Bool;
	private var _emitter:ParticleEmitter;

	private var _subMesh:SubMesh;

	private var _color:Color;
	public function new()
	{
		super();
		
		_color = new Color();

		imageX = 1;
		imageY = 1;
		uniqueTexCoords = false;

		_subMesh = new SubMesh();
		this.addSubMesh(_subMesh);
	}

	/**
	 * a particle use 2 triangle,4 point
	 */
	public function initParticleData(emitter:ParticleEmitter, numParticles:Int):Void
	{
		_emitter = emitter;

		// set positions
		var posVector:Vector<Float> = new Vector<Float>(numParticles * 4 * 3,true);
		_subMesh.setVertexBuffer(BufferType.POSITION, 3, posVector);

		// set colors
		var colorVector:Vector<Float> = new Vector<Float>(numParticles * 4 * 4,true);
		_subMesh.setVertexBuffer(BufferType.COLOR, 4, colorVector);

		// set texcoords
		uniqueTexCoords = false;
		var texVector:Vector<Float> = new Vector<Float>(numParticles * 4 * 2,true);
		for (i in 0...numParticles)
		{
			texVector[i * 8 + 0] = 0;
			texVector[i * 8 + 1] = 1;

			texVector[i * 8 + 2] = 1;
			texVector[i * 8 + 3] = 1;

			texVector[i * 8 + 4] = 0;
			texVector[i * 8 + 5] = 0;

			texVector[i * 8 + 6] = 1;
			texVector[i * 8 + 7] = 0;
		}

		_subMesh.setVertexBuffer(BufferType.TEXCOORD, 2, texVector);

		// set indices
		var indices:Vector<UInt> = new Vector<UInt>(numParticles * 6,true);
		for (i in 0...numParticles)
		{
			var idx:Int = i * 6;

			var startIdx:Int = i * 4;

			// triangle 1
			indices[idx + 0] = startIdx + 1;
			indices[idx + 1] = startIdx + 0;
			indices[idx + 2] = startIdx + 2;

			// triangle 2
			indices[idx + 3] = startIdx + 1;
			indices[idx + 4] = startIdx + 2;
			indices[idx + 5] = startIdx + 3;
		}

		_subMesh.setIndices(indices);
		_subMesh.validate();
		//this.validate();
	}

	public function setImagesXY(imageX:Int, imageY:Int):Void
	{
		this.imageX = imageX;
		this.imageY = imageY;

		if (imageX != 1 || imageX != 1)
		{
			uniqueTexCoords = true;
		}
	}

	

	public function updateParticleData(particles:Vector<Particle>, cam:Camera3D, inverseRotation:Matrix3f):Void
	{
		var pvb:VertexBuffer = _subMesh.getVertexBuffer(BufferType.POSITION);
		var positions:Vector<Float> = pvb.getData();

		var cvb:VertexBuffer = _subMesh.getVertexBuffer(BufferType.COLOR);
		var colors:Vector<Float> = cvb.getData();

		var tvb:VertexBuffer = _subMesh.getVertexBuffer(BufferType.TEXCOORD);
		var texcoords:Vector<Float> = tvb.getData();

		var camUp:Vector3f = cam.getUp();
		var camLeft:Vector3f = cam.getLeft();
		var camDir:Vector3f = cam.getDirection();

		inverseRotation.multVecLocal(camUp);
		inverseRotation.multVecLocal(camLeft);
		inverseRotation.multVecLocal(camDir);

		var facingVelocity:Bool = _emitter.isFacingVelocity();

		var up:Vector3f = new Vector3f();
		var left:Vector3f = new Vector3f();

		if (!facingVelocity)
		{
			up.copyFrom(camUp);
			left.copyFrom(camLeft);
		}

		var faceNormal:Vector3f = _emitter.getFaceNormal();

		//update data in vertex buffers
		var p:Particle;
		var numParticle:Int = particles.length;
		for (i in 0...numParticle)
		{
			p = particles[i];

			if (p.life == 0)
			{
				for (j in 0...12)
				{
					positions[i * 12 + j] = 0;
				}
				continue;
			}

			if (facingVelocity)
			{
				left.copyFrom(p.velocity);
				left.normalizeLocal();
				camDir.cross(left, up);
				up.scaleLocal(p.size);
				left.scaleLocal(p.size);
			}
			else if (faceNormal != null)
			{
				up.copyFrom(faceNormal);
				up.crossLocal(Vector3f.X_AXIS);
				faceNormal.cross(up, left);
				up.scaleLocal(p.size);
				left.scaleLocal(p.size);
			}
			else if (p.angle != 0)
			{
				var fcos:Float = Math.cos(p.angle) * p.size;
				var fsin:Float = Math.sin(p.angle) * p.size;

				left.x = camLeft.x * fcos + camUp.x * fsin;
				left.y = camLeft.y * fcos + camUp.y * fsin;
				left.z = camLeft.z * fcos + camUp.z * fsin;

				up.x = camLeft.x * -fsin + camUp.x * fcos;
				up.y = camLeft.y * -fsin + camUp.y * fcos;
				up.z = camLeft.z * -fsin + camUp.z * fcos;
			}
			else
			{
				up.copyFrom(camUp);
				left.copyFrom(camLeft);
				up.scaleLocal(p.size);
				left.scaleLocal(p.size);
			}

			var px:Float = p.position.x;
			var py:Float = p.position.y;
			var pz:Float = p.position.z;
			var lx:Float = left.x;
			var ly:Float = left.y;
			var lz:Float = left.z;
			var ux:Float = up.x;
			var uy:Float = up.y;
			var uz:Float = up.z;

			positions[i * 12 + 0] = px + lx + ux;
			positions[i * 12 + 1] = py + ly + uy;
			positions[i * 12 + 2] = pz + lz + uz;

			positions[i * 12 + 3] = px - lx + ux;
			positions[i * 12 + 4] = py - ly + uy;
			positions[i * 12 + 5] = pz - lz + uz;

			positions[i * 12 + 6] = px + lx - ux;
			positions[i * 12 + 7] = py + ly - uy;
			positions[i * 12 + 8] = pz + lz - uz;

			positions[i * 12 + 9] = px - lx - ux;
			positions[i * 12 + 10] = py - ly - uy;
			positions[i * 12 + 11] = pz - lz - uz;

			if (uniqueTexCoords)
			{
				var imgX:Int = p.frame % imageX;
				var imgY:Int = Std.int((p.frame - imgX) / imageY);

				var startX:Float = imgX / imageX;
				var startY:Float = imgY / imageY;
				var endX:Float = startX + 1 / imageX;
				var endY:Float = startY + 1 / imageY;

				texcoords[i * 8 + 0] = startX;
				texcoords[i * 8 + 1] = endY;

				texcoords[i * 8 + 2] = endX;
				texcoords[i * 8 + 3] = endY;

				texcoords[i * 8 + 4] = startX;
				texcoords[i * 8 + 5] = startY;

				texcoords[i * 8 + 6] = endX;
				texcoords[i * 8 + 7] = startY;
			}

			_color.setColor(p.color);
			var pr:Float = _color.r;
			var pg:Float = _color.g;
			var pb:Float = _color.b;
			var pa:Float = p.alpha;
			for (m in 0...4)
			{
				colors[i * 16 + m * 4 + 0] = pr;
				colors[i * 16 + m * 4 + 1] = pg;
				colors[i * 16 + m * 4 + 2] = pb;
				colors[i * 16 + m * 4 + 3] = pa;
			}

		}

		// force renderer to re-send data to GPU
		pvb.updateData(positions);
		cvb.updateData(colors);
		if (uniqueTexCoords)
		{
			tvb.updateData(texcoords);
		}

		//this.validate();
	}
}


