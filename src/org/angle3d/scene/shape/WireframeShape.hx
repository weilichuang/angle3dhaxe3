package org.angle3d.scene.shape;

import flash.Vector;
import org.angle3d.scene.mesh.BufferType;
import org.angle3d.scene.mesh.Mesh;
using org.angle3d.math.VectorUtil;

//TODO 可以实时修改线框
class WireframeShape extends Mesh
{
	private var mPosVector:Vector<Float>;
	private var mPos1Vector:Vector<Float>;

	private var mSegments:Vector<WireframeLineSet>;

	public function new()
	{
		super();

		mSegments = new Vector<WireframeLineSet>();
	}

	public function clearSegment():Void
	{
		mSegments.length = 0;
	}

	public function addSegment(segment:WireframeLineSet):Void
	{
		mSegments.push(segment);
	}
	
	public function removeSegment(segment:WireframeLineSet):Bool
	{
		return mSegments.remove(segment);
	}

	/**
	 * 生成线框模式需要的数据
	 * 
	 */
	public function build(updateIndices:Bool = true):Void
	{
		var sLength:Int = mSegments.length;
		
		mPosVector = new Vector<Float>(sLength * 12, true);
		mPos1Vector = new Vector<Float>(sLength * 16, true);
		if (updateIndices)
		{
			mIndices = new Vector<UInt>(sLength * 6, true);
		}

		var indicesSize:Int = 0;
		for (i in 0...sLength)
		{
			var segment:WireframeLineSet = mSegments[i];

			var index:Int = i << 2;
			if (updateIndices)
			{
				mIndices[indicesSize] = index + 2;
				mIndices[indicesSize + 1] = index + 1;
				mIndices[indicesSize + 2] = index + 0;
				
				mIndices[indicesSize + 3] = index + 1;
				mIndices[indicesSize + 4] = index + 2;
				mIndices[indicesSize + 5] = index + 3;
				indicesSize += 6;
			}

			var i12:Int = i * 12;
			var i16:Int = i * 16;

			var sx:Float = segment.sx, sy:Float = segment.sy, sz:Float = segment.sz;
			var ex:Float = segment.ex, ey:Float = segment.ey, ez:Float = segment.ez;

			//pos
			mPosVector[i12 + 0] = sx;
			mPosVector[i12 + 1] = sy;
			mPosVector[i12 + 2] = sz;

			mPosVector[i12 + 3] = ex;
			mPosVector[i12 + 4] = ey;
			mPosVector[i12 + 5] = ez;

			mPosVector[i12 + 6] = sx;
			mPosVector[i12 + 7] = sy;
			mPosVector[i12 + 8] = sz;

			mPosVector[i12 + 9] = ex;
			mPosVector[i12 + 10] = ey;
			mPosVector[i12 + 11] = ez;

			//pos1
			mPos1Vector[i16 + 0] = ex;
			mPos1Vector[i16 + 1] = ey;
			mPos1Vector[i16 + 2] = ez;
			//thickness
			mPos1Vector[i16 + 3] = 1;

			mPos1Vector[i16 + 4] = sx;
			mPos1Vector[i16 + 5] = sy;
			mPos1Vector[i16 + 6] = sz;
			mPos1Vector[i16 + 7] = -1;

			mPos1Vector[i16 + 8] = ex;
			mPos1Vector[i16 + 9] = ey;
			mPos1Vector[i16 + 10] = ez;
			mPos1Vector[i16 + 11] = -1;

			mPos1Vector[i16 + 12] = sx;
			mPos1Vector[i16 + 13] = sy;
			mPos1Vector[i16 + 14] = sz;
			mPos1Vector[i16 + 15] = 1;
		}

		updateBuffer(updateIndices);

		validate();
	}

	private function updateBuffer(updateIndices:Bool = true):Void
	{
		if (updateIndices)
		{
			setIndices(mIndices);
		}

		setVertexBuffer(BufferType.POSITION, 3, mPosVector);
		setVertexBuffer(BufferType.POSITION1, 4, mPos1Vector);
		validate();
	}
}

