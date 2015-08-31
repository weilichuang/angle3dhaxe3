package com.bulletphysics.collision.broadphase;
import com.bulletphysics.util.ObjectArrayList;
import com.vecmath.Vector3f;
import flash.Vector;

/**
 * ...
 * @author weilichuang
 */
class DbvtBroadphase implements BroadphaseInterface
{

	public static inline var DBVT_BP_MARGIN:Float = 0.05;

    public static inline var DYNAMIC_SET:Int = 0; // Dynamic set index
    public static inline var FIXED_SET:Int = 1; // Fixed set index
    public static inline var STAGECOUNT:Int = 2; // Number of stages

    public var sets:Vector<Dbvt> = new Vector<Dbvt>(2);                        // Dbvt sets
    public var stageRoots:Vector<DbvtProxy> = new Vector<DbvtProxy>(STAGECOUNT + 1); // Stages list
    public var paircache:OverlappingPairCache;                         // Pair cache
    public var predictedframes:Float;                                  // Frames predicted
    public var stageCurrent:Int;                                       // Current stage
    public var fupdates:Int;                                           // % of fixed updates per frame
    public var dupdates:Int;                                           // % of dynamic updates per frame
    public var pid:Int;                                                // Parse id
    public var gid:Int;                                                // Gen id
    public var releasepaircache:Bool;                               // Release pair cache on delete

    //#if DBVT_BP_PROFILE
    //btClock					m_clock;
    //struct	{
    //		unsigned long		m_total;
    //		unsigned long		m_ddcollide;
    //		unsigned long		m_fdcollide;
    //		unsigned long		m_cleanup;
    //		unsigned long		m_jobcount;
    //		}				m_profiling;
    //#endif
	
	private var collider:DbvtTreeCollider;

    public function new(paircache:OverlappingPairCache = null)
	{
        sets[0] = new Dbvt();
        sets[1] = new Dbvt();

        //Dbvt.benchmark();
        releasepaircache = (paircache != null ? false : true);
        predictedframes = 2;
        stageCurrent = 0;
        fupdates = 1;
        dupdates = 1;
        this.paircache = (paircache != null ? paircache : new HashedOverlappingPairCache());
        gid = 0;
        pid = 0;

        for (i in 0...(STAGECOUNT + 1))
		{
            stageRoots[i] = null;
        }
        //#if DBVT_BP_PROFILE
        //clear(m_profiling);
        //#endif
		
		collider = new DbvtTreeCollider(this);
    }

    public function collide(dispatcher:Dispatcher):Void
	{
		var dbvt0:Dbvt = sets[0];
		var dbvt1:Dbvt = sets[1];
        // optimize:
        dbvt0.optimizeIncremental(1 + Std.int((dbvt0.leaves * dupdates) * 0.01));
        dbvt1.optimizeIncremental(1 + Std.int((dbvt1.leaves * fupdates) * 0.01));

        // dynamic -> fixed set:
        stageCurrent = (stageCurrent + 1) % STAGECOUNT;
        var current:DbvtProxy = stageRoots[stageCurrent];
        if (current != null)
		{
            do {
                var next:DbvtProxy = current.links[1];
                stageRoots[current.stage] = listremove(current, stageRoots[current.stage]);
                stageRoots[STAGECOUNT] = listappend(current, stageRoots[STAGECOUNT]);
                Dbvt.collideTT(dbvt1.root, current.leaf, collider);
                dbvt0.remove(current.leaf);
                current.leaf = dbvt1.insert(current.aabb, current);
                current.stage = STAGECOUNT;
                current = next;
            } while (current != null);
        }

        // collide dynamics:
        {
            {
                //SPC(m_profiling.m_fdcollide);
                Dbvt.collideTT(dbvt0.root, dbvt1.root, collider);
            }
            {
                //SPC(m_profiling.m_ddcollide);
                Dbvt.collideTT(dbvt0.root, dbvt0.root, collider);
            }
        }

        // clean up:
        {
            //SPC(m_profiling.m_cleanup);
            var pairs:ObjectArrayList<BroadphasePair> = paircache.getOverlappingPairArray();
            if (pairs.size() > 0)
			{
				var i:Int = 0;
				var ni:Int = pairs.size();
				while(i < ni)
				{
                    var p:BroadphasePair = pairs.getQuick(i);
                    var pa:DbvtProxy = cast p.pProxy0;
                    var pb:DbvtProxy = cast p.pProxy1;
                    if (!DbvtAabbMm.Intersect(pa.aabb, pb.aabb)) 
					{
                        //if(pa>pb) btSwap(pa,pb);
                        //if (pa.hashCode() > pb.hashCode()) 
						//{
                            //var tmp:DbvtProxy = pa;
                            //pa = pb;
                            //pb = tmp;
                        //}
                        paircache.removeOverlappingPair(pa, pb, dispatcher);
                        ni--;
                        i--;
                    }
					
					i++;
                }
            }
        }
        pid++;
    }

    private static inline function listappend(item:DbvtProxy, list:DbvtProxy):DbvtProxy
	{
        item.links[0] = null;
        item.links[1] = list;
        if (list != null) list.links[0] = item;
        list = item;
        return list;
    }

    private static inline function listremove(item:DbvtProxy, list:DbvtProxy):DbvtProxy
	{
        if (item.links[0] != null)
		{
            item.links[0].links[1] = item.links[1];
        } 
		else
		{
            list = item.links[1];
        }

        if (item.links[1] != null) 
		{
            item.links[1].links[0] = item.links[0];
        }
        return list;
    }

    public function createProxy(aabbMin:Vector3f, 
								aabbMax:Vector3f,  
								shapeType:BroadphaseNativeType, 
								userPtr:Dynamic,  
								collisionFilterGroup:Int, 
								collisionFilterMask:Int, 
								dispatcher:Dispatcher, 
								multiSapProxy:Dynamic):BroadphaseProxy
	{
        var proxy:DbvtProxy = new DbvtProxy(userPtr, collisionFilterGroup, collisionFilterMask);
        DbvtAabbMm.FromMM(aabbMin, aabbMax, proxy.aabb);
        proxy.leaf = sets[0].insert(proxy.aabb, proxy);
        proxy.stage = stageCurrent;
        proxy.uniqueId = ++gid;
        stageRoots[stageCurrent] = listappend(proxy, stageRoots[stageCurrent]);
        return (proxy);
    }

    public function destroyProxy(absproxy:BroadphaseProxy, dispatcher:Dispatcher):Void
	{
        var proxy:DbvtProxy = cast absproxy;
        if (proxy.stage == STAGECOUNT)
		{
            sets[1].remove(proxy.leaf);
        } 
		else 
		{
            sets[0].remove(proxy.leaf);
        }
        stageRoots[proxy.stage] = listremove(proxy, stageRoots[proxy.stage]);
        paircache.removeOverlappingPairsContainingProxy(proxy, dispatcher);
        //btAlignedFree(proxy);
    }

	private var aabb:DbvtAabbMm = new DbvtAabbMm();
	private var delta:Vector3f = new Vector3f();
    public function setAabb(absproxy:BroadphaseProxy, aabbMin:Vector3f, aabbMax:Vector3f, dispatcher:Dispatcher):Void
	{
        var proxy:DbvtProxy = cast absproxy;
        var aabb:DbvtAabbMm = DbvtAabbMm.FromMM(aabbMin, aabbMax, aabb);
        if (proxy.stage == STAGECOUNT)
		{
            // fixed -> dynamic set
            sets[1].remove(proxy.leaf);
            proxy.leaf = sets[0].insert(aabb, proxy);
        } 
		else 
		{
            // dynamic set:
            if (DbvtAabbMm.Intersect(proxy.leaf.volume, aabb))
			{	
				/* Moving				*/
                //delta.add2(aabbMin, aabbMax);
                //delta.scale(0.5);
				//var tmpCenter:Vector3f = new Vector3f();
                //delta.sub(proxy.aabb.Center(tmpCenter));
				
				var pAabb:DbvtAabbMm = proxy.aabb;
				delta.x = ((aabbMin.x + aabbMax.x) - (pAabb.mi.x + pAabb.mx.x)) * 0.5;
				delta.y = ((aabbMin.y + aabbMax.y) - (pAabb.mi.y + pAabb.mx.y)) * 0.5;
				delta.z = ((aabbMin.x + aabbMax.z) - (pAabb.mi.z + pAabb.mx.z)) * 0.5;
				
				
                //#ifdef DBVT_BP_MARGIN
                delta.scaleLocal(predictedframes);
                sets[0].update3(proxy.leaf, aabb, delta, DBVT_BP_MARGIN);
                //#else
                //sets[0].update(proxy->leaf,aabb,delta*m_predictedframes);
                //#endif
            }
			else 
			{
                // teleporting:
                sets[0].update2(proxy.leaf, aabb);
            }
        }

        stageRoots[proxy.stage] = listremove(proxy, stageRoots[proxy.stage]);
        proxy.aabb.set(aabb);
        proxy.stage = stageCurrent;
        stageRoots[stageCurrent] = listappend(proxy, stageRoots[stageCurrent]);
    }

    public function calculateOverlappingPairs( dispatcher:Dispatcher):Void
	{
        collide(dispatcher);

        //#if DBVT_BP_PROFILE
        //if(0==(m_pid%DBVT_BP_PROFILING_RATE))
        //	{
        //	printf("fixed(%u) dynamics(%u) pairs(%u)\r\n",m_sets[1].m_leafs,m_sets[0].m_leafs,m_paircache->getNumOverlappingPairs());
        //	printf("mode:    %s\r\n",m_mode==MODE_FULL?"full":"incremental");
        //	printf("cleanup: %s\r\n",m_cleanupmode==CLEANUP_FULL?"full":"incremental");
        //	unsigned int	total=m_profiling.m_total;
        //	if(total<=0) total=1;
        //	printf("ddcollide: %u%% (%uus)\r\n",(50+m_profiling.m_ddcollide*100)/total,m_profiling.m_ddcollide/DBVT_BP_PROFILING_RATE);
        //	printf("fdcollide: %u%% (%uus)\r\n",(50+m_profiling.m_fdcollide*100)/total,m_profiling.m_fdcollide/DBVT_BP_PROFILING_RATE);
        //	printf("cleanup:   %u%% (%uus)\r\n",(50+m_profiling.m_cleanup*100)/total,m_profiling.m_cleanup/DBVT_BP_PROFILING_RATE);
        //	printf("total:     %uus\r\n",total/DBVT_BP_PROFILING_RATE);
        //	const unsigned long	sum=m_profiling.m_ddcollide+
        //							m_profiling.m_fdcollide+
        //							m_profiling.m_cleanup;
        //	printf("leaked: %u%% (%uus)\r\n",100-((50+sum*100)/total),(total-sum)/DBVT_BP_PROFILING_RATE);
        //	printf("job counts: %u%%\r\n",(m_profiling.m_jobcount*100)/((m_sets[0].m_leafs+m_sets[1].m_leafs)*DBVT_BP_PROFILING_RATE));
        //	clear(m_profiling);
        //	m_clock.reset();
        //	}
        //#endif
    }

    public function getOverlappingPairCache():OverlappingPairCache
	{
        return paircache;
    }

    public function getBroadphaseAabb(aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
        var bounds:DbvtAabbMm = new DbvtAabbMm();
        if (!sets[0].empty()) 
		{
            if (!sets[1].empty()) 
			{
                DbvtAabbMm.Merge(sets[0].root.volume, sets[1].root.volume, bounds);
            }
			else
			{
                bounds.set(sets[0].root.volume);
            }
        } 
		else if (!sets[1].empty())
		{
            bounds.set(sets[1].root.volume);
        } 
		else
		{
            DbvtAabbMm.FromCR(new Vector3f(0, 0, 0), 0, bounds);
        }
        aabbMin.copyFrom(bounds.Mins());
        aabbMax.copyFrom(bounds.Maxs());
    }

    public function printStats():Void
	{
    }
	
}