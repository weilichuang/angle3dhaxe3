package org.angle3d.io.parser.ms3d;

import flash.Lib;
import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.Vector;
import org.angle3d.animation.Animation;
import org.angle3d.animation.Bone;
import org.angle3d.animation.BoneTrack;
import org.angle3d.math.Quaternion;
import org.angle3d.math.Vector3f;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
import org.angle3d.scene.mesh.SkinnedMesh;
import org.angle3d.scene.mesh.SkinnedSubMesh;
import org.angle3d.scene.mesh.SubMesh;
import org.angle3d.utils.Assert;
import org.angle3d.utils.Logger;

typedef BoneAnimation = {
	var bones:Vector<Bone>;
	var animation:Animation;
}

class MS3DParser
{
	private var mMs3dVertices:Vector<MS3DVertex>;
	private var mMs3dTriangles:Vector<MS3DTriangle>;
	private var mMs3dGroups:Vector<MS3DGroup>;
	private var mMs3dMaterials:Vector<MS3DMaterial>;

	private var mFramesPerSecond:Float;
	private var mMs3dJoints:Vector<MS3DJoint>;
	private var mNumVertices:Int;
	private var mNumFrames:Int;

	public function new()
	{
	}

	public function parseStaticMesh(data:ByteArray):Mesh
	{
		data.endian = Endian.LITTLE_ENDIAN;
		data.position = 0;

		readHeader(data);
		readVertices(data);
		readTriangles(data);
		readGroups(data);
		readMaterials(data);

		var mesh:Mesh = new Mesh();

		var numTriangle:Int = mMs3dTriangles.length;
		var numGroups:Int = mMs3dGroups.length;
		for (i in 0...numGroups)
		{
			var subMesh:SubMesh = new SubMesh();
			
			var indices:Vector<UInt> = new Vector<UInt>();
			var vertices:Vector<Float> = new Vector<Float>();
			var normals:Vector<Float> = new Vector<Float>();
			var uvData:Vector<Float> = new Vector<Float>();

			var triangle:MS3DTriangle;
			for (t in 0...numTriangle)
			{
				triangle = mMs3dTriangles[t];

				if (triangle.groupIndex == i)
				{
					for (j in 0...3)
					{
						var vertex:MS3DVertex = mMs3dVertices[triangle.indices[j]];
						var normal:Vector3f = triangle.normals[j];

						vertices.push(vertex.x);
						vertices.push(vertex.y);
						vertices.push(vertex.z);

						normals.push(normal.x);
						normals.push(normal.y);
						normals.push(normal.z);

						uvData.push(triangle.tUs[j]);
						uvData.push(triangle.tVs[j]);
					}

					var index:Int = indices.length;
					indices.push(index);
					indices.push(index + 1);
					indices.push(index + 2);
				}
			}
			
			vertices.fixed = true;
			uvData.fixed = true;
			normals.fixed = true;
			indices.fixed = true;

			subMesh.setVertexBuffer(BufferType.POSITION, 3, vertices);
			subMesh.setVertexBuffer(BufferType.TEXCOORD, 2, uvData);
			subMesh.setVertexBuffer(BufferType.NORMAL, 3, normals);
			subMesh.setIndices(indices);
			subMesh.validate();

			mesh.addSubMesh(subMesh);
		}

		mesh.validate();

		return mesh;
	}

	public function parseSkinnedMesh(name:String, data:ByteArray):SkinnedMesh
	{
		data.endian = Endian.LITTLE_ENDIAN;
		data.position = 0;

		readHeader(data);
		readVertices(data);
		readTriangles(data);
		readGroups(data);
		readMaterials(data);

		readJoints(data);
		readAllComments(data);
		readWeights(data);

		//剩下的数据是编辑器使用的，忽略
		// joint extra
		// model extra

		var mesh:SkinnedMesh = new SkinnedMesh();

		var numTriangle:Int = mMs3dTriangles.length;
		var numGroups:Int = mMs3dGroups.length;
		for (i in 0...numGroups)
		{
			var subMesh:SkinnedSubMesh = new SkinnedSubMesh();
			
			var indices:Vector<UInt> = new Vector<UInt>();
			var vertices:Vector<Float> = new Vector<Float>();
			var normals:Vector<Float> = new Vector<Float>();
			var uvData:Vector<Float> = new Vector<Float>();
			var boneIndices:Vector<Float> = new Vector<Float>();
			var weights:Vector<Float> = new Vector<Float>();

			var triangle:MS3DTriangle;
			for (t in 0...numTriangle)
			{
				triangle = mMs3dTriangles[t];

				if (triangle.groupIndex == i)
				{
					for (j in 0...3)
					{
						var vertex:MS3DVertex = mMs3dVertices[triangle.indices[j]];
						var normal:Vector3f = triangle.normals[j];

						vertices.push(vertex.x);
						vertices.push(vertex.y);
						vertices.push(vertex.z);

						normals.push(normal.x);
						normals.push(normal.y);
						normals.push(normal.z);

						uvData.push(triangle.tUs[j]);
						uvData.push(triangle.tVs[j]);

						boneIndices.push(vertex.bones[0]);
						boneIndices.push(vertex.bones[1]);
						boneIndices.push(vertex.bones[2]);
						boneIndices.push(vertex.bones[3]);

						weights.push(vertex.weights[0]);
						weights.push(vertex.weights[1]);
						weights.push(vertex.weights[2]);
						weights.push(vertex.weights[3]);
					}

					var index:Int = indices.length;
					indices.push(index);
					indices.push(index + 1);
					indices.push(index + 2);
				}
			}
			
			vertices.fixed = true;
			uvData.fixed = true;
			normals.fixed = true;
			boneIndices.fixed = true;
			weights.fixed = true;

			subMesh.setVertexBuffer(BufferType.POSITION, 3, vertices);
			subMesh.setVertexBuffer(BufferType.BIND_POSE_POSITION, 3, vertices.slice(0));
			subMesh.setVertexBuffer(BufferType.TEXCOORD, 2, uvData);
			subMesh.setVertexBuffer(BufferType.NORMAL, 3, normals);
			subMesh.setVertexBuffer(BufferType.BONE_INDICES, 4, boneIndices);
			subMesh.setVertexBuffer(BufferType.BONE_WEIGHTS, 4, weights);
			subMesh.setIndices(indices);
			subMesh.validate();

			mesh.addSubMesh(subMesh);
		}

		mesh.validate();

		return mesh;
	}

	public function buildSkeleton():BoneAnimation
	{
		var length:Int = mMs3dJoints.length;
		
		var bones:Vector<Bone> = new Vector<Bone>(length,true);
		var tracks:Vector<BoneTrack> = new Vector<BoneTrack>(length,true);

		var animation:Animation = new Animation("default", mNumFrames);

		var q:Quaternion = new Quaternion();

		
		var bone:Bone;
		var joint:MS3DJoint;
		var track:BoneTrack;
		for (i in 0...length)
		{
			bone = new Bone("");
			bones[i] = bone;

			joint = mMs3dJoints[i];

			bone.name = joint.name;
			bone.parentName = joint.parentName;

			bone.localPos.copyFrom(joint.translation);
			bone.localRot.fromAngles(joint.rotation.x, joint.rotation.y, joint.rotation.z);

			var times:Vector<Float> = new Vector<Float>(mNumFrames);
			var rotations:Vector<Float> = new Vector<Float>(mNumFrames * 4);
			var translations:Vector<Float> = new Vector<Float>(mNumFrames * 3);

			var position:Vector3f = new Vector3f();
			var rotation:Quaternion = new Quaternion();

			//TODO 由于每个joint.positionKeys和rotationKeys数量不同，所以需要手工创建需要的部分（插值）
			//为了方便，这里将只在关键帧出进行插值
			for (j in 0...mNumFrames)
			{
				getKeyFramePositionAt(joint, j, position);
				getKeyFrameRotationAt(joint, j, rotation);
				
				translations[j * 3] = position.x;
				translations[j * 3 + 1] = position.y;
				translations[j * 3 + 2] = position.z;
				
				rotations[j * 4] = rotation.x;
				rotations[j * 4 + 1] = rotation.y;
				rotations[j * 4 + 2] = rotation.z;
				rotations[j * 4 + 3] = rotation.w;

				times[j] = j;
			}

			track = new BoneTrack(i, times, translations, rotations);
			animation.addTrack(track);
		}
		return { "bones":bones, "animation":animation };
	}

	/**
	 * 获得joint动画某个时间点的位移
	 */
	private function getKeyFramePositionAt(joint:MS3DJoint, time:Float, store:Vector3f):Void
	{
		var positionKeys:Vector<MS3DKeyframe> = joint.positionKeys;

		var posKeyFrame:MS3DKeyframe;
		var posTime:Float;
		var posData:Vector<Float>;
		if (time == 0)
		{
			posKeyFrame = positionKeys[0];
			posData = posKeyFrame.data;
			store.setTo(posData[0], posData[1], posData[2]);
		}
		else if (time >= mNumFrames)
		{
			posKeyFrame = positionKeys[positionKeys.length - 1];
			posData = posKeyFrame.data;
			store.setTo(posData[0], posData[1], posData[2]);
		}
		else
		{
			var posKeyFrame1:MS3DKeyframe;
			var posTime1:Float;
			var posData1:Vector<Float>;
			var size:Int = positionKeys.length - 1;
			for (i in 0...size)
			{
				//position
				posKeyFrame = positionKeys[i];
				posTime = posKeyFrame.time;

				posKeyFrame1 = positionKeys[i + 1];
				posTime1 = posKeyFrame1.time;
				if (time >= posTime && time <= posTime1)
				{
					posData = posKeyFrame.data;
					posData1 = posKeyFrame1.data;

					var interp:Float = (time - posTime) / (posTime1 - posTime);
					var interp1:Float = 1.0 - interp;
					var px:Float = posData[0] * interp1 + interp * posData1[0];
					var py:Float = posData[1] * interp1 + interp * posData1[1];
					var pz:Float = posData[2] * interp1 + interp * posData1[2];

					store.setTo(px, py, pz);

					break;
				}
			}
		}
	}

	/**
	 * 获得joint动画某个时间点的旋转
	 */
	private static var _tmpQ1:Quaternion = new Quaternion();
	private static var _tmpQ2:Quaternion = new Quaternion();

	private function getKeyFrameRotationAt(joint:MS3DJoint, time:Float, store:Quaternion):Void
	{
		var rotKeys:Vector<MS3DKeyframe> = joint.rotationKeys;
		var rotKeyFrame:MS3DKeyframe;
		var rotTime:Float;
		var rotData:Vector<Float>;
		if (time == 0)
		{
			rotKeyFrame = rotKeys[0];
			rotData = rotKeyFrame.data;

			store.fromAngles(rotData[0], rotData[1], rotData[2]);
		}
		else if (time >= mNumFrames)
		{
			rotKeyFrame = rotKeys[rotKeys.length - 1];
			rotData = rotKeyFrame.data;
			store.fromAngles(rotData[0], rotData[1], rotData[2]);
		}
		else
		{
			var rotKeyFrame1:MS3DKeyframe;
			var rotTime1:Float;
			var rotData1:Vector<Float>;
			var size:Int = rotKeys.length - 1;
			for (i in 0...size)
			{
				//position
				rotKeyFrame = rotKeys[i];
				rotTime = rotKeyFrame.time;

				rotKeyFrame1 = rotKeys[i + 1];
				rotTime1 = rotKeyFrame1.time;
				if (time >= rotTime && time <= rotTime1)
				{
					rotData = rotKeyFrame.data;
					rotData1 = rotKeyFrame1.data;

					_tmpQ1.fromAngles(rotData[0], rotData[1], rotData[2]);
					_tmpQ2.fromAngles(rotData1[0], rotData1[1], rotData1[2]);

					var interp:Float = (time - rotTime) / (rotTime1 - rotTime);
					store.slerp(_tmpQ1, _tmpQ2, interp);

					break;
				}
			}
		}
	}

	private function readHeader(data:ByteArray):Void
	{
		var id:String = data.readUTFBytes(10);
		var version:UInt = data.readUnsignedInt();
		#if debug
			Assert.assert(id == "MS3D000000", "This is not a valid MS3D file version.");
			Assert.assert(version == 4, "This is not a valid MS3D file version.");
		#end
	}

	private function readVertices(data:ByteArray):Void
	{
		//顶点数
		mNumVertices = data.readUnsignedShort();
		mMs3dVertices = new Vector<MS3DVertex>(mNumVertices);
		for (i in 0...mNumVertices)
		{
			var ms3dVertex:MS3DVertex = new MS3DVertex();
			//unuse flag
			data.position += 1;
			ms3dVertex.x = data.readFloat();
			ms3dVertex.y = data.readFloat();
			ms3dVertex.z = data.readFloat();
			ms3dVertex.bones[0] = data.readUnsignedByte();
			//unuse
			data.position += 1;
			mMs3dVertices[i] = ms3dVertex;
		}
	}

	private function readTriangles(data:ByteArray):Void
	{
		//triangles
		var numTriangles:Int = data.readUnsignedShort();
		mMs3dTriangles = new Vector<MS3DTriangle>(numTriangles);
		for (i in 0...numTriangles)
		{
			var triangle:MS3DTriangle = new MS3DTriangle();
			//unuse flag
			data.position += 2;
			triangle.indices[0] = data.readUnsignedShort();
			triangle.indices[1] = data.readUnsignedShort();
			triangle.indices[2] = data.readUnsignedShort();
			triangle.normals[0].x = data.readFloat();
			triangle.normals[1].x = data.readFloat();
			triangle.normals[2].x = data.readFloat();
			triangle.normals[0].y = data.readFloat();
			triangle.normals[1].y = data.readFloat();
			triangle.normals[2].y = data.readFloat();
			triangle.normals[0].z = data.readFloat();
			triangle.normals[1].z = data.readFloat();
			triangle.normals[2].z = data.readFloat();
			triangle.tUs[0] = data.readFloat();
			triangle.tUs[1] = data.readFloat();
			triangle.tUs[2] = data.readFloat();
			triangle.tVs[0] = data.readFloat();
			triangle.tVs[1] = data.readFloat();
			triangle.tVs[2] = data.readFloat();
			//smoothingGroup,unuse
			data.position += 1;
			triangle.groupIndex = data.readUnsignedByte();

			mMs3dTriangles[i] = triangle;
		}
	}

	private function readGroups(data:ByteArray):Void
	{
		var numGroups:Int = data.readUnsignedShort();
		mMs3dGroups = new Vector<MS3DGroup>(numGroups);
		for (i in 0...numGroups)
		{
			var group:MS3DGroup = new MS3DGroup();
			//unuse flags
			data.position += 1;

			group.name = data.readUTFBytes(32);

			var numIndices:Int = data.readUnsignedShort();
			var indices:Vector<UInt> = new Vector<UInt>(numIndices);
			for (j in 0...numIndices)
			{
				indices[j] = data.readUnsignedShort();
			}
			group.indices = indices;

			// material index
			group.materialID = data.readUnsignedByte();
			if (group.materialID == 255)
				group.materialID = 0;

			mMs3dGroups[i] = group;
		}
	}

	private function readMaterials(data:ByteArray):Void
	{
		// materials
		var numMaterials:Int = data.readUnsignedShort();
		mMs3dMaterials = new Vector<MS3DMaterial>(numMaterials);
		for (i in 0...numMaterials)
		{
			var mat:MS3DMaterial = new MS3DMaterial();
			mat.name = data.readUTFBytes(32);
			mat.ambient.setTo(data.readFloat(), data.readFloat(), data.readFloat(), data.readFloat());
			mat.diffuse.setTo(data.readFloat(), data.readFloat(), data.readFloat(), data.readFloat());
			mat.emissive.setTo(data.readFloat(), data.readFloat(), data.readFloat(), data.readFloat());
			mat.specular.setTo(data.readFloat(), data.readFloat(), data.readFloat(), data.readFloat());
			mat.shininess = Std.int(data.readFloat()); //0~128
			mat.transparency = data.readFloat(); // 0~1

			//mode
			data.position += 1;

			mat.texture = data.readUTFBytes(128);
			mat.alphaMap = data.readUTFBytes(128);

			mMs3dMaterials[i] = mat;
		}
	}

	private function readWeights(data:ByteArray):Void
	{
		if (data.bytesAvailable > 0)
		{
			var vertex:MS3DVertex;
			var subVersion:Int = data.readInt();
			if (subVersion == 1 || subVersion == 2)
			{
				for (i in 0...mNumVertices)
				{
					vertex = mMs3dVertices[i];

					vertex.bones[1] = data.readByte();
					vertex.bones[2] = data.readByte();
					vertex.bones[3] = data.readByte();

//						if(vertex.bones[1] <0)
//							vertex.bones[1] = 0;
//						if(vertex.bones[2] <0)
//							vertex.bones[2] = 0;
//						if(vertex.bones[2] <0)
//							vertex.bones[2] = 0;

					var w0:Float = data.readUnsignedByte() * 0.01;
					var w1:Float = data.readUnsignedByte() * 0.01;
					var w2:Float = data.readUnsignedByte() * 0.01;

					if (w0 != 0 || w1 != 0 || w2 != 0)
					{
						vertex.weights[0] = w0;
						vertex.weights[1] = w1;
						vertex.weights[2] = w2;
						vertex.weights[3] = 1 - w0 - w1 - w2;
					}

					if (subVersion == 2)
					{
						//extra
						data.position += 4;
					}
				}
			}
			else
			{
				Logger.log("Unknown subversion for vertex extra " + subVersion);
			}
		}
	}

	private function readJoints(data:ByteArray):Void
	{
		//animation time
		mFramesPerSecond = data.readFloat();
		if (mFramesPerSecond < 1)
			mFramesPerSecond = 1.0;

		var startTime:Float = data.readFloat();
		#if debug
			Lib.trace("startTime :" + startTime);
		#end

		//动画帧数
		mNumFrames = data.readInt();

		var numJoints:Int = data.readUnsignedShort();
		mMs3dJoints = new Vector<MS3DJoint>(numJoints);
		for (i in 0...numJoints)
		{
			//unuse flag
			data.position += 1;

			var joint:MS3DJoint = new MS3DJoint();
			joint.name = data.readUTFBytes(32);
			joint.parentName = data.readUTFBytes(32);

			joint.rotation.setTo(data.readFloat(), data.readFloat(), data.readFloat());
			joint.translation.setTo(data.readFloat(), data.readFloat(), data.readFloat());

			var numKeyFramesRot:UInt = data.readUnsignedShort();
			var numKeyFramesPos:UInt = data.readUnsignedShort();

			var keyFrame:MS3DKeyframe;

			// the frame time is in seconds, 
			//so multiply it by the animation fps, 
			//to get the frames rotation channel
			joint.rotationKeys = new Vector<MS3DKeyframe>(numKeyFramesRot);
			for (j in 0...numKeyFramesRot)
			{
				keyFrame = new MS3DKeyframe();
				keyFrame.time = data.readFloat() * mFramesPerSecond;
				keyFrame.data[0] = data.readFloat();
				keyFrame.data[1] = data.readFloat();
				keyFrame.data[2] = data.readFloat();

				joint.rotationKeys[j] = keyFrame;
			}

			joint.positionKeys = new Vector<MS3DKeyframe>(numKeyFramesPos);
			for (j in 0...numKeyFramesPos)
			{
				keyFrame = new MS3DKeyframe();
				keyFrame.time = data.readFloat() * mFramesPerSecond;
				keyFrame.data[0] = data.readFloat();
				keyFrame.data[1] = data.readFloat();
				keyFrame.data[2] = data.readFloat();

				joint.positionKeys[j] = keyFrame;
			}

			mMs3dJoints[i] = joint;
		}
	}

	private function readComments(data:ByteArray):Void
	{
		var numComments:Int = data.readUnsignedInt();
		for (j in 0...numComments)
		{
			var index:Int = data.readInt(); //index
			var size:Int = data.readInt(); //字符串长度
			if (size > 0)
			{
				var comment:String = data.readUTFBytes(size);
				#if debug
					Lib.trace(comment);
				#end
			}
		}
	}

	private function readModelComments(data:ByteArray):Void
	{
		var numComments:Int = data.readUnsignedInt();
		for (j in 0...numComments)
		{
			var size:Int = data.readInt(); //字符串长度
			if (size > 0)
			{
				var comment:String = data.readUTFBytes(size);
				Lib.trace(comment);
			}
		}
	}

	private function readAllComments(data:ByteArray):Void
	{
		if (data.bytesAvailable > 0)
		{
			var subVersion:Int = data.readInt();
			if (subVersion == 1)
			{
				//group
				readComments(data);
				//material
				readComments(data);
				//joint
				readComments(data);
				//model
				readModelComments(data);
			}
		}
	}
}