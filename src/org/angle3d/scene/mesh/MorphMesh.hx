package org.angle3d.scene.mesh;

import flash.Vector;
import haxe.ds.StringMap;


/**
 * 变形动画
 */
class MorphMesh extends Mesh
{
	public var useNormal(get, set):Bool;
	public var totalFrame(get, set):Int;
	//当前帧
	private var mCurrentFrame:Int = -1;
	private var mNextFrame:Int;
	private var mTotalFrame:Int;

	private var mAnimationMap:StringMap<MorphData>;

	private var mUseNormal:Bool;
	
	private var mVerticesList:Vector<Vector<Float>>;

	private var mNormalList:Vector<Vector<Float>>;

	public function new()
	{
		super();

		type = MeshType.KEYFRAME;

		mAnimationMap = new StringMap<MorphData>();
		
		mVerticesList = new Vector<Vector<Float>>();
		mNormalList = new Vector<Vector<Float>>();
	}

	/**
	 * 不需要使用normal时设置为false，提高速度
	 */
	
	private function get_useNormal():Bool
	{
		return mUseNormal;
	}

	private function set_useNormal(value:Bool):Bool
	{
		return mUseNormal = value;
	}

	
	private function set_totalFrame(value:Int):Int
	{
		return mTotalFrame = value;
	}

	private function get_totalFrame():Int
	{
		return mTotalFrame;
	}

	public function addAnimation(name:String, start:Int, end:Int):Void
	{
		mAnimationMap.set(name,new MorphData(name, start, end));
	}

	public function getAnimation(name:String):MorphData
	{
		return mAnimationMap.get(name);
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

	public function setFrame(curFrame:Int, nextFrame:Int):Void
	{
		if (mCurrentFrame == curFrame)
			return;

		mCurrentFrame = curFrame;
		mNextFrame = nextFrame;

		//更新两帧的位置数据
		setVertexBuffer(BufferType.POSITION, 3, getVertices(curFrame));
		setVertexBuffer(BufferType.POSITION1, 3, getVertices(nextFrame));

		if (useNormal)
		{
			setVertexBuffer(BufferType.NORMAL, 3, getNormals(curFrame));
			setVertexBuffer(BufferType.NORMAL1, 3, getNormals(nextFrame));
		}
	}
	
	override public function validate():Void 
	{
		setFrame(0, 1);
		super.validate();
	}
}
