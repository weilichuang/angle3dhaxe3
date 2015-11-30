package com.bulletphysics.collision.dispatch;
import com.bulletphysics.collision.broadphase.BroadphaseNativeType;
import com.bulletphysics.collision.dispatch.CollisionAlgorithmCreateFunc;
import com.bulletphysics.collision.dispatch.createfunc.ConvexConvexCreateFunc;
import com.bulletphysics.collision.dispatch.createfunc.ConvexPlaneCreateFunc;
import com.bulletphysics.collision.dispatch.createfunc.CompoundCreateFunc;
import com.bulletphysics.collision.dispatch.createfunc.CompoundSwappedCreateFunc;
import com.bulletphysics.collision.dispatch.createfunc.CovexConcaveCreateFunc;
import com.bulletphysics.collision.dispatch.createfunc.CovexConcaveSwappedCreateFunc;
import com.bulletphysics.collision.dispatch.createfunc.EmptyCreateFunc;
import com.bulletphysics.collision.dispatch.createfunc.SphereSphereCreateFunc;
import com.bulletphysics.collision.narrowphase.ConvexPenetrationDepthSolver;
import com.bulletphysics.collision.narrowphase.GjkEpaPenetrationDepthSolver;
import com.bulletphysics.collision.narrowphase.VoronoiSimplexSolver;

using com.bulletphysics.collision.broadphase.BroadphaseNativeTypeUtil;
/**
 * Default implementation of {CollisionConfiguration}. Provides all core
 * collision algorithms. Some extra algorithms (like {GImpactCollisionAlgorithm GImpact})
 * must be registered manually by calling appropriate register method.
 * 
 * @author weilichuang
 */
class DefaultCollisionConfiguration extends CollisionConfiguration
{

	//default simplex/penetration depth solvers
    private var simplexSolver:VoronoiSimplexSolver;
    private var pdSolver:ConvexPenetrationDepthSolver;

    //default CreationFunctions, filling the m_doubleDispatch table
    private var convexConvexCreateFunc:CollisionAlgorithmCreateFunc;
    private var convexConcaveCreateFunc:CollisionAlgorithmCreateFunc;
    private var swappedConvexConcaveCreateFunc:CollisionAlgorithmCreateFunc;
    private var compoundCreateFunc:CollisionAlgorithmCreateFunc;
    private var swappedCompoundCreateFunc:CollisionAlgorithmCreateFunc;
    private var emptyCreateFunc:CollisionAlgorithmCreateFunc;
    private var sphereSphereCF:CollisionAlgorithmCreateFunc;
    private var sphereBoxCF:CollisionAlgorithmCreateFunc;
    private var boxSphereCF:CollisionAlgorithmCreateFunc;
    private var boxBoxCF:CollisionAlgorithmCreateFunc;
    private var sphereTriangleCF:CollisionAlgorithmCreateFunc;
    private var triangleSphereCF:CollisionAlgorithmCreateFunc;
    private var planeConvexCF:CollisionAlgorithmCreateFunc;
    private var convexPlaneCF:CollisionAlgorithmCreateFunc;

    public function new()
	{
		super();
		
        simplexSolver = new VoronoiSimplexSolver();

        //#define USE_EPA 1
        //#ifdef USE_EPA
        pdSolver = new GjkEpaPenetrationDepthSolver();
        //#else
        //pdSolver = new MinkowskiPenetrationDepthSolver();
        //#endif//USE_EPA

		/*
        //default CreationFunctions, filling the m_doubleDispatch table
		*/

        convexConvexCreateFunc = new ConvexConvexCreateFunc(simplexSolver, pdSolver);
        convexConcaveCreateFunc = new CovexConcaveCreateFunc();
        swappedConvexConcaveCreateFunc = new CovexConcaveSwappedCreateFunc();
        compoundCreateFunc = new CompoundCreateFunc();
        swappedCompoundCreateFunc = new CompoundSwappedCreateFunc();
        emptyCreateFunc = new EmptyCreateFunc();

        sphereSphereCF = new SphereSphereCreateFunc();
        /*
		m_sphereBoxCF = new(mem) btSphereBoxCollisionAlgorithm::CreateFunc;
		m_boxSphereCF = new (mem)btSphereBoxCollisionAlgorithm::CreateFunc;
		m_boxSphereCF->m_swapped = true;
		m_sphereTriangleCF = new (mem)btSphereTriangleCollisionAlgorithm::CreateFunc;
		m_triangleSphereCF = new (mem)btSphereTriangleCollisionAlgorithm::CreateFunc;
		m_triangleSphereCF->m_swapped = true;

		mem = btAlignedAlloc(sizeof(btBoxBoxCollisionAlgorithm::CreateFunc),16);
		m_boxBoxCF = new(mem)btBoxBoxCollisionAlgorithm::CreateFunc;
		*/

        // convex versus plane
        convexPlaneCF = new ConvexPlaneCreateFunc();
        planeConvexCF = new ConvexPlaneCreateFunc();
        planeConvexCF.swapped = true;

		/*
		///calculate maximum element size, big enough to fit any collision algorithm in the memory pool
		int maxSize = sizeof(btConvexConvexAlgorithm);
		int maxSize2 = sizeof(btConvexConcaveCollisionAlgorithm);
		int maxSize3 = sizeof(btCompoundCollisionAlgorithm);
		int maxSize4 = sizeof(btEmptyAlgorithm);

		int	collisionAlgorithmMaxElementSize = btMax(maxSize,maxSize2);
		collisionAlgorithmMaxElementSize = btMax(collisionAlgorithmMaxElementSize,maxSize3);
		collisionAlgorithmMaxElementSize = btMax(collisionAlgorithmMaxElementSize,maxSize4);

		if (stackAlloc)
		{
			m_ownsStackAllocator = false;
			this->m_stackAlloc = stackAlloc;
		} else
		{
			m_ownsStackAllocator = true;
			void* mem = btAlignedAlloc(sizeof(btStackAlloc),16);
			m_stackAlloc = new(mem)btStackAlloc(DEFAULT_STACK_ALLOCATOR_SIZE);
		}

		if (persistentManifoldPool)
		{
			m_ownsPersistentManifoldPool = false;
			m_persistentManifoldPool = persistentManifoldPool;
		} else
		{
			m_ownsPersistentManifoldPool = true;
			void* mem = btAlignedAlloc(sizeof(btPoolAllocator),16);
			m_persistentManifoldPool = new (mem) btPoolAllocator(sizeof(btPersistentManifold),DEFAULT_MAX_OVERLAPPING_PAIRS);
		}

		if (collisionAlgorithmPool)
		{
			m_ownsCollisionAlgorithmPool = false;
			m_collisionAlgorithmPool = collisionAlgorithmPool;
		} else
		{
			m_ownsCollisionAlgorithmPool = true;
			void* mem = btAlignedAlloc(sizeof(btPoolAllocator),16);
			m_collisionAlgorithmPool = new(mem) btPoolAllocator(collisionAlgorithmMaxElementSize,DEFAULT_MAX_OVERLAPPING_PAIRS);
		}
		*/
    }
	
	override public function getCollisionAlgorithmCreateFunc(proxyType0:BroadphaseNativeType, proxyType1:BroadphaseNativeType):CollisionAlgorithmCreateFunc 
	{
		if ((proxyType0 == BroadphaseNativeType.SPHERE_SHAPE_PROXYTYPE) && 
			(proxyType1 == BroadphaseNativeType.SPHERE_SHAPE_PROXYTYPE)) 
		{
            return sphereSphereCF;
        }

		/*
		if ((proxyType0 == SPHERE_SHAPE_PROXYTYPE) && (proxyType1==BOX_SHAPE_PROXYTYPE))
		{
			return	m_sphereBoxCF;
		}

		if ((proxyType0 == BOX_SHAPE_PROXYTYPE ) && (proxyType1==SPHERE_SHAPE_PROXYTYPE))
		{
			return	m_boxSphereCF;
		}

		if ((proxyType0 == SPHERE_SHAPE_PROXYTYPE ) && (proxyType1==TRIANGLE_SHAPE_PROXYTYPE))
		{
			return	m_sphereTriangleCF;
		}

		if ((proxyType0 == TRIANGLE_SHAPE_PROXYTYPE  ) && (proxyType1==SPHERE_SHAPE_PROXYTYPE))
		{
			return	m_triangleSphereCF;
		}

		if ((proxyType0 == BOX_SHAPE_PROXYTYPE) && (proxyType1 == BOX_SHAPE_PROXYTYPE)) {
			return boxBoxCF;
		}
		*/

        if (proxyType0.isConvex() && (proxyType1 == BroadphaseNativeType.STATIC_PLANE_PROXYTYPE)) 
		{
            return convexPlaneCF;
        }

        if (proxyType1.isConvex() && (proxyType0 == BroadphaseNativeType.STATIC_PLANE_PROXYTYPE)) 
		{
            return planeConvexCF;
        }

        if (proxyType0.isConvex() && proxyType1.isConvex()) 
		{
            return convexConvexCreateFunc;
        }

        if (proxyType0.isConvex() && proxyType1.isConcave())
		{
            return convexConcaveCreateFunc;
        }

        if (proxyType1.isConvex() && proxyType0.isConcave()) 
		{
            return swappedConvexConcaveCreateFunc;
        }

        if (proxyType0.isCompound()) 
		{
            return compoundCreateFunc;
        } 
		else
		{
            if (proxyType1.isCompound()) 
			{
                return swappedCompoundCreateFunc;
            }
        }

        // failed to find an algorithm
        return emptyCreateFunc;
	}
}