package org.angle3d.scene.mesh;

import flash.Vector;

/**
 * 变形动画
 */
class MorphSubMesh extends SubMesh
{
	public var totalFrame(get, set):Int;
	
	private var mTotalFrame:Int;

	private var mVerticesList:Vector<Vector<Float>>;

	private var mNormalList:Vector<Vector<Float>>;

	public function new()
	{
		super();

		mVerticesList = new Vector<Vector<Float>>();
		mNormalList = new Vector<Vector<Float>>();
	}

	override public function validate():Void
	{
		//mNormalList.length = mTotalFrame;

		updateBound();
	}

	private function get_totalFrame():Int
	{
		return mTotalFrame;
	}
	
	private function set_totalFrame(value:Int):Int
	{
		return mTotalFrame = value;
	}

	public function getNormals(frame:Int):Vector<Float>
	{
		//需要时再创建，解析模型时一起创建耗时有点久
		if (mNormalList[frame] == null)
		{
			mNormalList[frame] = MeshHelper.buildVertexNormals(mIndices, getVertices(frame));
		}

		return mNormalList[frame];
	}

	public function addNormals(list:Vector<Float>):Void
	{
		mNormalList.push(list);
	}

	public function getVertices(frame:Int):Vector<Float>
	{
		return mVerticesList[frame];
	}

	public function addVertices(vertices:Vector<Float>):Void
	{
		mVerticesList.push(vertices);
	}

	public function setFrame(curFrame:Int, nextFrame:Int, useNormal:Bool):Void
	{
		//更新两帧的位置数据
		setVertexBuffer(BufferType.POSITION, 3, getVertices(curFrame));
		setVertexBuffer(BufferType.POSITION1, 3, getVertices(nextFrame));

		if (useNormal)
		{
			setVertexBuffer(BufferType.NORMAL, 3, getNormals(curFrame));
			setVertexBuffer(BufferType.NORMAL1, 3, getNormals(nextFrame));
		}
	}
}
