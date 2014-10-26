package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.broadphase.Dbvt.ICollide;
import com.bulletphysics.collision.broadphase.Dbvt.DbvtNode;

/**
 * ...
 * @author weilichuang
 */
class DbvtTreeCollider extends ICollide
{
	public var pbp:DbvtBroadphase;

	public function new(p:DbvtBroadphase) 
	{
		super();
		this.pbp = p;
	}
	
	override public function Process2(na:DbvtNode, nb:DbvtNode):Void 
	{
		var pa:DbvtProxy = cast na.data;
        var pb:DbvtProxy = cast nb.data;
        //#if DBVT_BP_DISCRETPAIRS
        if (DbvtAabbMm.Intersect(pa.aabb, pb.aabb))
        //#endif
        {
            //if(pa>pb) btSwap(pa,pb);
            if (pa.uniqueId > pb.uniqueId) 
			{
                var tmp:DbvtProxy = pa;
                pa = pb;
                pb = tmp;
            }
            pbp.paircache.addOverlappingPair(pa, pb);
        }
	}
	
}