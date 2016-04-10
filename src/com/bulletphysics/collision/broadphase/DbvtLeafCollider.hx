package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.broadphase.Dbvt.ICollide;
import com.bulletphysics.collision.broadphase.Dbvt.DbvtNode;

/**
 * ...
 
 */
class DbvtLeafCollider extends ICollide
{

	public var pbp:DbvtBroadphase;
    public var ppx:DbvtProxy;

    public function new(p:DbvtBroadphase, px:DbvtProxy) 
	{
		super();
        this.pbp = p;
        this.ppx = px;
    }
	
	override public function Process(na:DbvtNode):Void 
	{
		var nb:DbvtNode = ppx.leaf;
        if (nb != na)
		{
            var pa:DbvtProxy = cast na.data;
            var pb:DbvtProxy = cast nb.data;

            //#if DBVT_BP_DISCRETPAIRS
            if (DbvtAabbMm.Intersect(pa.aabb, pb.aabb))
            //#endif
            {
                //if(pa>pb) btSwap(pa,pb);
				//需要修改，为何判断hashCode
                //if (pa.hashCode() > pb.hashCode())
				//{
                    //var tmp:DbvtProxy = pa;
                    //pa = pb;
                    //pb = tmp;
                //}
                pbp.paircache.addOverlappingPair(pa, pb);
            }
        }
	}
	
}