package angle3d.io.parser.md2;

import flash.utils.ByteArray;
import flash.utils.Endian;
import flash.utils.RegExp;

import angle3d.scene.mesh.BufferType;
import angle3d.scene.mesh.Mesh;
import angle3d.scene.mesh.MeshHelper;
import angle3d.scene.mesh.MorphMesh;
import angle3d.scene.mesh.MorphData;
import angle3d.error.Assert;


//need generate normal
class MD2Parser
{
	public static inline var MD2_MAGIC_NUMBER:Int = 844121161;
	public static inline var MD2_VERSION:Int = 8;

	private var mData:ByteArray;
	private var mHeader:MD2Header;
	private var mFaces:Array<Int>;
	private var mGlobalUVs:Array<Float>;

	private var mMesh:MorphMesh;

	private var mLastFrameName:String;

	public function new()
	{
		mHeader = new MD2Header();
	}

	public function parse(data:ByteArray):MorphMesh
	{
		mData = data;
		mData.endian = Endian.LITTLE_ENDIAN;
		mData.position = 0;

		mLastFrameName = "";

		mMesh = new MorphMesh();

		parseHeader();
		parseUVs();
		parseFaces();
		parseFrames();
		finalize();

		return mMesh;
	}

	private function parseHeader():Void
	{
		var magic:Int = mData.readInt();
		var version:Int = mData.readInt();

		if (magic != MD2_MAGIC_NUMBER || version != MD2_VERSION)
		{
			Assert.assert(false, "This is not a md2 model");
			return;
		}

		mHeader.skinWidth = mData.readInt();
		mHeader.skinHeight = mData.readInt();
		mHeader.frameSize = mData.readInt();
		mHeader.numSkins = mData.readInt();
		mHeader.numVertices = mData.readInt();
		mHeader.numTexcoords = mData.readInt();
		mHeader.numFaces = mData.readInt();
		mHeader.numGlCommands = mData.readInt();
		mHeader.numFrames = mData.readInt();
		mHeader.offsetSkins = mData.readInt();
		mHeader.offsetTexcoords = mData.readInt();
		mHeader.offsetFaces = mData.readInt();
		mHeader.offsetFrames = mData.readInt();
		mHeader.offsetGlCommands = mData.readInt();
		mHeader.offsetEnd = mData.readInt();

		mMesh.totalFrame = mHeader.numFrames;
	}

	private function parseUVs():Void
	{
		mData.position = mHeader.offsetTexcoords;

		var invWidth:Float = 1.0 / mHeader.skinWidth;
		var invHeight:Float = 1.0 / mHeader.skinHeight;

		mGlobalUVs = new Array<Float>(mHeader.numTexcoords * 2);
		for (i in 0...mHeader.numTexcoords)
		{
			mGlobalUVs[i * 2] = (0.5 + mData.readShort()) * invWidth;
			mGlobalUVs[i * 2 + 1] = (0.5 + mData.readShort()) * invHeight;
		}
	}

	private function parseFrames():Void
	{
		mData.position = mHeader.offsetFrames;

		var numVertices:Int = mHeader.numVertices;

		var intVertices:Array<Int> = new Array<Int>(numVertices * 3);

		var numFrames:Int = mHeader.numFrames;
		for (i in 0...numFrames)
		{
			//z 与  y 进行了交换
			var sx:Float = mData.readFloat();
			var sz:Float = mData.readFloat();
			var sy:Float = mData.readFloat();
			var tx:Float = mData.readFloat();
			var tz:Float = mData.readFloat();
			var ty:Float = mData.readFloat();

			var frameName:String = mData.readUTFBytes(16);
			frameName = untyped frameName.replace(new RegExp("[0-9]", "g"), "");
			if (frameName != mLastFrameName)
			{
				mMesh.addAnimation(frameName, i, i);
				mLastFrameName = frameName;
			}
			else
			{
				//同一个动作，改变结束帧即可
				mMesh.getAnimation(frameName).end = i;
			}

			//x,y,z,normalIndex
			for (j in 0...numVertices)
			{
				// read vertex
				var vx:Int = mData.readUnsignedByte();
				var vz:Int = mData.readUnsignedByte();
				var vy:Int = mData.readUnsignedByte();
				//normal index
				mData.readUnsignedByte();

				var j3:Int = j * 3;
				intVertices[j3] = vx;
				intVertices[j3 + 1] = vy;
				intVertices[j3 + 2] = vz;
			}

			var numFaces:Int = mHeader.numFaces;
			var vertices:Array<Float> = new Array<Float>(numFaces * 9);
			var vertexIndex:Int = 0;
			for (f in 0...numFaces)
			{
				var f6:Int = f * 6;
				var index:Int = mFaces[f6] * 3;
				vertices[vertexIndex] = (intVertices[index] * sx + tx);
				vertices[vertexIndex + 1] = (intVertices[index + 1] * sy + ty);
				vertices[vertexIndex + 2] = (intVertices[index + 2] * sz + tz);

				index = mFaces[(f6 + 1)] * 3;
				vertices[vertexIndex + 3] = (intVertices[index] * sx + tx);
				vertices[vertexIndex + 4] = (intVertices[index + 1] * sy + ty);
				vertices[vertexIndex + 5] = (intVertices[index + 2] * sz + tz);

				index = mFaces[(f6 + 2)] * 3;
				vertices[vertexIndex + 6] = (intVertices[index] * sx + tx);
				vertices[vertexIndex + 7] = (intVertices[index + 1] * sy + ty);
				vertices[vertexIndex + 8] = (intVertices[index + 2] * sz + tz);
				
				vertexIndex += 9;
			}

			mMesh.addVertices(vertices);
		}

		intVertices = null;
	}

	private function parseFaces():Void
	{
		mData.position = mHeader.offsetFaces;

		var numFaces:Int = mHeader.numFaces;
		mFaces = new Array<Int>(numFaces * 6);
		var faceIndex:Int = 0;
		for (i in 0...numFaces)
		{
			mFaces[faceIndex] = mData.readShort();
			mFaces[faceIndex + 1] = mData.readShort();
			mFaces[faceIndex + 2] = mData.readShort();
			mFaces[faceIndex + 3] = mData.readShort();
			mFaces[faceIndex + 4] = mData.readShort();
			mFaces[faceIndex + 5] = mData.readShort();
			
			faceIndex += 6;
		}
	}

	private function finalize():Void
	{
		var count:Int = mHeader.numFaces * 3;
		var indices:Array<UInt> = new Array<UInt>(count);
		
		var index:Int = 0;
		for (f in 0...mHeader.numFaces)
		{
			var index3:Int = index * 3;
			
			indices[index3 + 0] = index3 + 2;
			indices[index3 + 1] = index3 + 1;
			indices[index3 + 2] = index3 + 0;
			
			index += 1;
		}

		mMesh.setIndices(indices);

		var numFaces:Int = mHeader.numFaces;
		var uvData:Array<Float> = new Array<Float>(numFaces*6);
		var uvDataIndex:Int = 0;
		for (f in 0...numFaces)
		{
			var f6:Int = f * 6;
			var uvIndex:Int 		= mFaces[f6 + 3] * 2;
			uvData[uvDataIndex] 	= mGlobalUVs[uvIndex];
			uvData[uvDataIndex + 1] = mGlobalUVs[uvIndex + 1];

			uvIndex = mFaces[f6 + 4] * 2;
			uvData[uvDataIndex + 2] = mGlobalUVs[uvIndex];
			uvData[uvDataIndex + 3] = mGlobalUVs[uvIndex + 1];

			uvIndex = mFaces[f6 + 5] * 2;
			uvData[uvDataIndex + 4] = mGlobalUVs[uvIndex];
			uvData[uvDataIndex + 5] = mGlobalUVs[uvIndex + 1];
			
			uvDataIndex += 6;
		}
		
		mFaces = null;
		mGlobalUVs = null;

		mMesh.setVertexBuffer(BufferType.TEXCOORD, 2, uvData);
		mMesh.validate();
	}
}

class MD2Header
{
	public var skinWidth:Int;
	public var skinHeight:Int;
	public var frameSize:Int;
	public var numSkins:Int;
	public var numVertices:Int;
	public var numTexcoords:Int;
	public var numFaces:Int;
	public var numGlCommands:Int;
	public var numFrames:Int;
	public var offsetSkins:Int;
	public var offsetTexcoords:Int;
	public var offsetFaces:Int;
	public var offsetFrames:Int;
	public var offsetGlCommands:Int;
	public var offsetEnd:Int;
	
	public function new()
	{
		
	}
}
