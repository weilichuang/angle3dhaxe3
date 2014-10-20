package com.bulletphysics.collision.shapes;
import com.bulletphysics.linearmath.AabbUtil2;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.linearmath.VectorUtil;
import com.bulletphysics.util.Assert;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.Vector3f;

/**
 * OptimizedBvh store an AABB tree that can be quickly traversed on CPU (and SPU, GPU in future).
 * @author weilichuang
 */
class OptimizedBvh
{
	private static var DEBUG_TREE_BUILDING:Bool = false;
	
	private static var gStackDepth:Int = 0;
	private static var gMaxStackDepth:Int = 0;
	private static var maxIterations:Int = 0;
	
	// Note: currently we have 16 bytes per quantized node
	public static var MAX_SUBTREE_SIZE_IN_BYTES:Int = 2048;
	
	// 10 gives the potential for 1024 parts, with at most 2^21 (2097152) (minus one
    // actually) triangles each (since the sign bit is reserved
    public static var MAX_NUM_PARTS_IN_BITS:Int = 10;
	
	private var leafNodes:ObjectArrayList<OptimizedBvhNode> = new ObjectArrayList<OptimizedBvhNode>();
	private var contiguousNodes:ObjectArrayList<OptimizedBvhNode> = new ObjectArrayList<OptimizedBvhNode>();
	
	private var quantizedLeafNodes:QuantizedBvhNodes = new QuantizedBvhNodes();
	private var quantizedContiguousNodes:QuantizedBvhNodes = new QuantizedBvhNodes();
	
	private var curNodeIndex:Int;
	
	// quantization data
	private var useQuantization:Bool;
	private var bvhAabbMin:Vector3f = new Vector3f();
	private var bvhAabbMax:Vector3f = new Vector3f();
	private var bvhQuantization:Vector3f = new Vector3f();
	
	private var traversalMode:TraversalMode = TraversalMode.STACKLESS;
	private var SubtreeHeaders:ObjectArrayList<BvhSubtreeInfo> = new ObjectArrayList<BvhSubtreeInfo>();
	private var subtreeHeaderCount:Int;

	public function new() 
	{
		
	}
	
	public function setInternalNodeAabbMin(nodeIndex:Int, aabbMin:Vector3f):Void
	{
		if (useQuantization) 
		{
			quantizedContiguousNodes.setQuantizedAabbMin(nodeIndex, quantizeWithClamp(aabbMin));
		}
		else
		{
			contiguousNodes.getQuick(nodeIndex).aabbMinOrg.fromVector3f(aabbMin);
		}
	}
	
	public function setInternalNodeAabbMax(nodeIndex:Int, aabbMax:Vector3f):Void
	{
		if (useQuantization) 
		{
			quantizedContiguousNodes.setQuantizedAabbMin(nodeIndex, quantizeWithClamp(aabbMax));
		}
		else
		{
			contiguousNodes.getQuick(nodeIndex).aabbMaxOrg.fromVector3f(aabbMax);
		}
	}
	
	public function getAabbMin(nodeIndex:Int):Vector3f
	{
		if (useQuantization) 
		{
			var tmp:Vector3f = new Vector3f();
			unQuantize(tmp, quantizedLeafNodes.getQuantizedAabbMin(nodeIndex));
            return tmp;
		}
		
		// non-quantized
		return leafNodes.getQuick(nodeIndex).aabbMinOrg;
	}
	
	public function getAabbMax(nodeIndex:Int):Vector3f
	{
		if (useQuantization)
		{
			var tmp:Vector3f = new Vector3f();
			unQuantize(tmp, quantizedLeafNodes.getQuantizedAabbMax(nodeIndex));
            return tmp;
		}
		
		// non-quantized
		return leafNodes.getQuick(nodeIndex).aabbMaxOrg;
	}
	
	public function setQuantizationValues(aabbMin:Vector3f, aabbMax:Vector3f, quantizationMargin:Float = 1.0):Void
	{
		// enlarge the AABB to avoid division by zero when initializing the quantization values
        var clampValue:Vector3f = new Vector3f();
        clampValue.setTo(quantizationMargin, quantizationMargin, quantizationMargin);
        bvhAabbMin.sub2(aabbMin, clampValue);
        bvhAabbMax.add2(aabbMax, clampValue);
        var aabbSize:Vector3f = new Vector3f();
        aabbSize.sub2(bvhAabbMax, bvhAabbMin);
        bvhQuantization.setTo(65535, 65535, 65535);
        VectorUtil.div(bvhQuantization, bvhQuantization, aabbSize);
	}
	
	
	public function setInternalNodeEscapeIndex(nodeIndex:Int, escapeIndex:Int):Void
	{
        if (useQuantization)
		{
            quantizedContiguousNodes.setEscapeIndexOrTriangleIndex(nodeIndex, -escapeIndex);
        } 
		else 
		{
            contiguousNodes.getQuick(nodeIndex).escapeIndex = escapeIndex;
        }
    }

    public function mergeInternalNodeAabb(nodeIndex:Int, newAabbMin:Vector3f, newAabbMax:Vector3f):Void
	{
        if (useQuantization)
		{
            var quantizedAabbMin:Int;
            var quantizedAabbMax:Int;

            quantizedAabbMin = quantizeWithClamp(newAabbMin);
            quantizedAabbMax = quantizeWithClamp(newAabbMax);
            for (i in 0...3) 
			{
                if (quantizedContiguousNodes.getQuantizedAabbMinAt(nodeIndex, i) > QuantizedBvhNodes.getCoord(quantizedAabbMin, i)) 
				{
                    quantizedContiguousNodes.setQuantizedAabbMinAt(nodeIndex, i, QuantizedBvhNodes.getCoord(quantizedAabbMin, i));
                }

                if (quantizedContiguousNodes.getQuantizedAabbMaxAt(nodeIndex, i) < QuantizedBvhNodes.getCoord(quantizedAabbMax, i)) 
				{
                    quantizedContiguousNodes.setQuantizedAabbMaxAt(nodeIndex, i, QuantizedBvhNodes.getCoord(quantizedAabbMax, i));
                }
            }
        } 
		else
		{
            // non-quantized
            VectorUtil.setMin(contiguousNodes.getQuick(nodeIndex).aabbMinOrg, newAabbMin);
            VectorUtil.setMax(contiguousNodes.getQuick(nodeIndex).aabbMaxOrg, newAabbMax);
        }
    }

    public function swapLeafNodes(i:Int, splitIndex:Int):Void
	{
        if (useQuantization) 
		{
            quantizedLeafNodes.swap(i, splitIndex);
        } 
		else 
		{
            var tmp:OptimizedBvhNode = leafNodes.getQuick(i);
            leafNodes.setQuick(i, leafNodes.getQuick(splitIndex));
            leafNodes.setQuick(splitIndex, tmp);
        }
    }

    public function assignInternalNodeFromLeafNode(internalNode:Int, leafNodeIndex:Int):Void 
	{
        if (useQuantization)
		{
            quantizedContiguousNodes.set(internalNode, quantizedLeafNodes, leafNodeIndex);
        } 
		else
		{
            contiguousNodes.getQuick(internalNode).set(leafNodes.getQuick(leafNodeIndex));
        }
    }


    public function build(triangles:StridingMeshInterface, useQuantizedAabbCompression:Bool, 
						_aabbMin:Vector3f, _aabbMax:Vector3f):Void
	{
        this.useQuantization = useQuantizedAabbCompression;

        // NodeArray	triangleNodes;

        var numLeafNodes:Int = 0;

        if (useQuantization) 
		{
            // initialize quantization values
            setQuantizationValues(_aabbMin, _aabbMax);

            var callback:QuantizedNodeTriangleCallback = new QuantizedNodeTriangleCallback(quantizedLeafNodes, this);

            triangles.internalProcessAllTriangles(callback, bvhAabbMin, bvhAabbMax);

            // now we have an array of leafnodes in m_leafNodes
            numLeafNodes = quantizedLeafNodes.size();

            quantizedContiguousNodes.resize(2 * numLeafNodes);
        }
		else
		{
            var callback:NodeTriangleCallback = new NodeTriangleCallback(leafNodes);

            var aabbMin:Vector3f = new Vector3f();
            aabbMin.setTo(-1e30, -1e30, -1e30);
            var aabbMax:Vector3f = new Vector3f();
            aabbMax.setTo(1e30, 1e30, 1e30);

            triangles.internalProcessAllTriangles(callback, aabbMin, aabbMax);

            // now we have an array of leafnodes in m_leafNodes
            numLeafNodes = leafNodes.size();

            contiguousNodes.resize(2 * numLeafNodes, OptimizedBvhNode);
        }

        curNodeIndex = 0;

        buildTree(0, numLeafNodes);

        //  if the entire tree is small then subtree size, we need to create a header info for the tree
        if (useQuantization && SubtreeHeaders.size() == 0)
		{
            var subtree:BvhSubtreeInfo = new BvhSubtreeInfo();
            SubtreeHeaders.add(subtree);

            subtree.setAabbFromQuantizeNode(quantizedContiguousNodes, 0);
            subtree.rootNodeIndex = 0;
            subtree.subtreeSize = quantizedContiguousNodes.isLeafNode(0) ? 1 : quantizedContiguousNodes.getEscapeIndex(0);
        }

        // PCK: update the copy of the size
        subtreeHeaderCount = SubtreeHeaders.size();

        // PCK: clear m_quantizedLeafNodes and m_leafNodes, they are temporary
        quantizedLeafNodes.clear();
        leafNodes.clear();
    }

    public function refit(meshInterface:StridingMeshInterface):Void 
	{
        if (useQuantization) 
		{
            // calculate new aabb
            var aabbMin:Vector3f = new Vector3f();
			var aabbMax:Vector3f = new Vector3f();
            meshInterface.calculateAabbBruteForce(aabbMin, aabbMax);

            setQuantizationValues(aabbMin, aabbMax);

            updateBvhNodes(meshInterface, 0, curNodeIndex, 0);

            // now update all subtree headers
            for (i in 0...SubtreeHeaders.size())
			{
                var subtree:BvhSubtreeInfo = SubtreeHeaders.getQuick(i);
                subtree.setAabbFromQuantizeNode(quantizedContiguousNodes, subtree.rootNodeIndex);
            }

        } 
		else
		{
            // JAVA NOTE: added for testing, it's too slow for practical use
            build(meshInterface, false, null, null);
        }
    }

    public function refitPartial(meshInterface:StridingMeshInterface, aabbMin:Vector3f, aabbMax:Vector3f):Void
	{
        throw "UnsupportedOperationException";
//		// incrementally initialize quantization values
//		assert (useQuantization);
//
//		btAssert(aabbMin.getX() > m_bvhAabbMin.getX());
//		btAssert(aabbMin.getY() > m_bvhAabbMin.getY());
//		btAssert(aabbMin.getZ() > m_bvhAabbMin.getZ());
//
//		btAssert(aabbMax.getX() < m_bvhAabbMax.getX());
//		btAssert(aabbMax.getY() < m_bvhAabbMax.getY());
//		btAssert(aabbMax.getZ() < m_bvhAabbMax.getZ());
//
//		///we should update all quantization values, using updateBvhNodes(meshInterface);
//		///but we only update chunks that overlap the given aabb
//
//		unsigned short	quantizedQueryAabbMin[3];
//		unsigned short	quantizedQueryAabbMax[3];
//
//		quantizeWithClamp(&quantizedQueryAabbMin[0],aabbMin);
//		quantizeWithClamp(&quantizedQueryAabbMax[0],aabbMax);
//
//		int i;
//		for (i=0;i<this->m_SubtreeHeaders.size();i++)
//		{
//			btBvhSubtreeInfo& subtree = m_SubtreeHeaders[i];
//
//			//PCK: unsigned instead of bool
//			unsigned overlap = testQuantizedAabbAgainstQuantizedAabb(quantizedQueryAabbMin,quantizedQueryAabbMax,subtree.m_quantizedAabbMin,subtree.m_quantizedAabbMax);
//			if (overlap != 0)
//			{
//				updateBvhNodes(meshInterface,subtree.m_rootNodeIndex,subtree.m_rootNodeIndex+subtree.m_subtreeSize,i);
//
//				subtree.setAabbFromQuantizeNode(m_quantizedContiguousNodes[subtree.m_rootNodeIndex]);
//			}
//		}
    }

    public function updateBvhNodes(meshInterface:StridingMeshInterface, firstNode:Int, endNode:Int, index:Int):Void
	{
        Assert.assert(useQuantization);

        var curNodeSubPart:Int = -1;

        var triangleVerts:Array<Vector3f> = [new Vector3f(), new Vector3f(), new Vector3f()];
        var aabbMin:Vector3f = new Vector3f();
		var aabbMax:Vector3f = new Vector3f();
        var meshScaling:Vector3f = meshInterface.getScaling(new Vector3f());

        var data:VertexData = null;

		var i:Int = endNode - 1;
        while (i >= firstNode) 
		{
            var curNodes:QuantizedBvhNodes = quantizedContiguousNodes;
            var curNodeId:Int = i;

            if (curNodes.isLeafNode(curNodeId))
			{
                // recalc aabb from triangle data
                var nodeSubPart:Int = curNodes.getPartId(curNodeId);
                var nodeTriangleIndex:Int = curNodes.getTriangleIndex(curNodeId);
                if (nodeSubPart != curNodeSubPart)
				{
                    if (curNodeSubPart >= 0)
					{
                        meshInterface.unLockReadOnlyVertexBase(curNodeSubPart);
                    }
                    data = meshInterface.getLockedReadOnlyVertexIndexBase(nodeSubPart);
                }
                //triangles->getLockedReadOnlyVertexIndexBase(vertexBase,numVerts,

                data.getTriangle(nodeTriangleIndex * 3, meshScaling, triangleVerts);

                aabbMin.setTo(1e30, 1e30, 1e30);
                aabbMax.setTo(-1e30, -1e30, -1e30);
                VectorUtil.setMin(aabbMin, triangleVerts[0]);
                VectorUtil.setMax(aabbMax, triangleVerts[0]);
                VectorUtil.setMin(aabbMin, triangleVerts[1]);
                VectorUtil.setMax(aabbMax, triangleVerts[1]);
                VectorUtil.setMin(aabbMin, triangleVerts[2]);
                VectorUtil.setMax(aabbMax, triangleVerts[2]);

                curNodes.setQuantizedAabbMin(curNodeId, quantizeWithClamp(aabbMin));
                curNodes.setQuantizedAabbMax(curNodeId, quantizeWithClamp(aabbMax));
            } 
			else
			{
                // combine aabb from both children

                //quantizedContiguousNodes
                var leftChildNodeId:Int = i + 1;

                var rightChildNodeId:Int = quantizedContiguousNodes.isLeafNode(leftChildNodeId) ? i + 2 : i + 1 + quantizedContiguousNodes.getEscapeIndex(leftChildNodeId);

                for (i2 in 0...3)
				{
                    curNodes.setQuantizedAabbMinAt(curNodeId, i2, quantizedContiguousNodes.getQuantizedAabbMinAt(leftChildNodeId, i2));
                    if (curNodes.getQuantizedAabbMinAt(curNodeId, i2) > quantizedContiguousNodes.getQuantizedAabbMinAt(rightChildNodeId, i2)) 
					{
                        curNodes.setQuantizedAabbMinAt(curNodeId, i2, quantizedContiguousNodes.getQuantizedAabbMinAt(rightChildNodeId, i2));
                    }

                    curNodes.setQuantizedAabbMaxAt(curNodeId, i2, quantizedContiguousNodes.getQuantizedAabbMaxAt(leftChildNodeId, i2));
                    if (curNodes.getQuantizedAabbMaxAt(curNodeId, i2) < quantizedContiguousNodes.getQuantizedAabbMaxAt(rightChildNodeId, i2)) 
					{
                        curNodes.setQuantizedAabbMaxAt(curNodeId, i2, quantizedContiguousNodes.getQuantizedAabbMaxAt(rightChildNodeId, i2));
                    }
                }
            }
			
			i--;
        }

        if (curNodeSubPart >= 0)
		{
            meshInterface.unLockReadOnlyVertexBase(curNodeSubPart);
        }
    }

    private function buildTree(startIndex:Int, endIndex:Int):Void
	{
        //#ifdef DEBUG_TREE_BUILDING
        if (DEBUG_TREE_BUILDING) {
            gStackDepth++;
            if (gStackDepth > gMaxStackDepth) {
                gMaxStackDepth = gStackDepth;
            }
        }
        //#endif //DEBUG_TREE_BUILDING

        var splitAxis:Int, splitIndex:Int;
        var numIndices:Int = endIndex - startIndex;
        var curIndex:Int = curNodeIndex;

        //assert (numIndices > 0);

        if (numIndices == 1) 
		{
            //#ifdef DEBUG_TREE_BUILDING
            if (DEBUG_TREE_BUILDING)
			{
                gStackDepth--;
            }
            //#endif //DEBUG_TREE_BUILDING

            assignInternalNodeFromLeafNode(curNodeIndex, startIndex);

            curNodeIndex++;
            return;
        }
        // calculate Best Splitting Axis and where to split it. Sort the incoming 'leafNodes' array within range 'startIndex/endIndex'.

        splitAxis = calcSplittingAxis(startIndex, endIndex);

        splitIndex = sortAndCalcSplittingIndex(startIndex, endIndex, splitAxis);

        var internalNodeIndex:Int = curNodeIndex;

        var tmp1:Vector3f = new Vector3f();
        tmp1.setTo(-1e30, -1e30, -1e30);
        setInternalNodeAabbMax(curNodeIndex, tmp1);
        var tmp2:Vector3f = new Vector3f();
        tmp2.setTo(1e30, 1e30, 1e30);
        setInternalNodeAabbMin(curNodeIndex, tmp2);

        for (i in startIndex...endIndex)
		{
            mergeInternalNodeAabb(curNodeIndex, getAabbMin(i), getAabbMax(i));
        }

        curNodeIndex++;

        //internalNode->m_escapeIndex;

        var leftChildNodexIndex:Int = curNodeIndex;

        //build left child tree
        buildTree(startIndex, splitIndex);

        var rightChildNodexIndex:Int = curNodeIndex;
        // build right child tree
        buildTree(splitIndex, endIndex);

        //#ifdef DEBUG_TREE_BUILDING
        if (DEBUG_TREE_BUILDING) 
		{
            gStackDepth--;
        }
        //#endif //DEBUG_TREE_BUILDING

        var escapeIndex:Int = curNodeIndex - curIndex;

        if (useQuantization) 
		{
            // escapeIndex is the number of nodes of this subtree
            var sizeQuantizedNode:Int = QuantizedBvhNodes.getNodeSize();
            var treeSizeInBytes:Int = escapeIndex * sizeQuantizedNode;
            if (treeSizeInBytes > MAX_SUBTREE_SIZE_IN_BYTES) 
			{
                updateSubtreeHeaders(leftChildNodexIndex, rightChildNodexIndex);
            }
        }

        setInternalNodeEscapeIndex(internalNodeIndex, escapeIndex);
    }

    private function testQuantizedAabbAgainstQuantizedAabb( aabbMin1:Int, aabbMax1:Int, aabbMin2:Int, aabbMax2:Int):Bool 
	{
        var aabbMin1_0:Int = QuantizedBvhNodes.getCoord(aabbMin1, 0);
        var aabbMin1_1:Int = QuantizedBvhNodes.getCoord(aabbMin1, 1);
        var aabbMin1_2:Int = QuantizedBvhNodes.getCoord(aabbMin1, 2);

        var aabbMax1_0:Int = QuantizedBvhNodes.getCoord(aabbMax1, 0);
        var aabbMax1_1:Int = QuantizedBvhNodes.getCoord(aabbMax1, 1);
        var aabbMax1_2:Int = QuantizedBvhNodes.getCoord(aabbMax1, 2);

        var aabbMin2_0:Int = QuantizedBvhNodes.getCoord(aabbMin2, 0);
        var aabbMin2_1:Int = QuantizedBvhNodes.getCoord(aabbMin2, 1);
        var aabbMin2_2:Int = QuantizedBvhNodes.getCoord(aabbMin2, 2);

        var aabbMax2_0:Int = QuantizedBvhNodes.getCoord(aabbMax2, 0);
        var aabbMax2_1:Int = QuantizedBvhNodes.getCoord(aabbMax2, 1);
        var aabbMax2_2:Int = QuantizedBvhNodes.getCoord(aabbMax2, 2);

        var overlap:Bool = true;
        overlap = (aabbMin1_0 > aabbMax2_0 || aabbMax1_0 < aabbMin2_0) ? false : overlap;
        overlap = (aabbMin1_2 > aabbMax2_2 || aabbMax1_2 < aabbMin2_2) ? false : overlap;
        overlap = (aabbMin1_1 > aabbMax2_1 || aabbMax1_1 < aabbMin2_1) ? false : overlap;
        return overlap;
    }

    private function updateSubtreeHeaders(leftChildNodexIndex:Int, rightChildNodexIndex:Int):Void
	{
        Assert.assert (useQuantization);

        //btQuantizedBvhNode& leftChildNode = m_quantizedContiguousNodes[leftChildNodexIndex];
        var leftSubTreeSize:Int = quantizedContiguousNodes.isLeafNode(leftChildNodexIndex) ? 1 : quantizedContiguousNodes.getEscapeIndex(leftChildNodexIndex);
        var leftSubTreeSizeInBytes:Int = leftSubTreeSize * QuantizedBvhNodes.getNodeSize();

        //btQuantizedBvhNode& rightChildNode = m_quantizedContiguousNodes[rightChildNodexIndex];
        var rightSubTreeSize:Int = quantizedContiguousNodes.isLeafNode(rightChildNodexIndex) ? 1 : quantizedContiguousNodes.getEscapeIndex(rightChildNodexIndex);
        var rightSubTreeSizeInBytes:Int = rightSubTreeSize * QuantizedBvhNodes.getNodeSize();

        if (leftSubTreeSizeInBytes <= MAX_SUBTREE_SIZE_IN_BYTES)
		{
            var subtree:BvhSubtreeInfo = new BvhSubtreeInfo();
            SubtreeHeaders.add(subtree);

            subtree.setAabbFromQuantizeNode(quantizedContiguousNodes, leftChildNodexIndex);
            subtree.rootNodeIndex = leftChildNodexIndex;
            subtree.subtreeSize = leftSubTreeSize;
        }

        if (rightSubTreeSizeInBytes <= MAX_SUBTREE_SIZE_IN_BYTES) 
		{
            var subtree:BvhSubtreeInfo = new BvhSubtreeInfo();
            SubtreeHeaders.add(subtree);

            subtree.setAabbFromQuantizeNode(quantizedContiguousNodes, rightChildNodexIndex);
            subtree.rootNodeIndex = rightChildNodexIndex;
            subtree.subtreeSize = rightSubTreeSize;
        }

        // PCK: update the copy of the size
        subtreeHeaderCount = SubtreeHeaders.size();
    }

    private function sortAndCalcSplittingIndex(startIndex:Int, endIndex:Int, splitAxis:Int):Int 
	{
        var splitIndex:Int = startIndex;
        var numIndices:Int = endIndex - startIndex;
        var splitValue:Float;

        var means:Vector3f = new Vector3f();
        means.setTo(0, 0, 0);
        var center:Vector3f = new Vector3f();
        for (i in startIndex...endIndex) 
		{
            center.add2(getAabbMax(i), getAabbMin(i));
            center.scale(0.5);
            means.add(center);
        }
        means.scale(1 / numIndices);

        splitValue = VectorUtil.getCoord(means, splitAxis);

        //sort leafNodes so all values larger then splitValue comes first, and smaller values start from 'splitIndex'.
        for (i in startIndex...endIndex)
		{
            //Vector3f center = new Vector3f();
            center.add2(getAabbMax(i), getAabbMin(i));
            center.scale(0.5);

            if (VectorUtil.getCoord(center, splitAxis) > splitValue)
			{
                // swap
                swapLeafNodes(i, splitIndex);
                splitIndex++;
            }
        }

        // if the splitIndex causes unbalanced trees, fix this by using the center in between startIndex and endIndex
        // otherwise the tree-building might fail due to stack-overflows in certain cases.
        // unbalanced1 is unsafe: it can cause stack overflows
        // bool unbalanced1 = ((splitIndex==startIndex) || (splitIndex == (endIndex-1)));

        // unbalanced2 should work too: always use center (perfect balanced trees)
        // bool unbalanced2 = true;

        // this should be safe too:
        var rangeBalancedIndices:Int = Std.int(numIndices / 3);
        var unbalanced:Bool = ((splitIndex <= (startIndex + rangeBalancedIndices)) || (splitIndex >= (endIndex - 1 - rangeBalancedIndices)));

        if (unbalanced)
		{
            splitIndex = startIndex + (numIndices >> 1);
        }

        //var unbal:Bool = (splitIndex == startIndex) || (splitIndex == (endIndex));
        //assert (!unbal);

        return splitIndex;
    }

    private function calcSplittingAxis(startIndex:Int, endIndex:Int):Int
	{
        var means:Vector3f = new Vector3f();
        var variance:Vector3f = new Vector3f();
        var numIndices:Int = endIndex - startIndex;

        var center:Vector3f = new Vector3f();
        for (i in startIndex...endIndex)
		{
            center.add2(getAabbMax(i), getAabbMin(i));
            center.scale(0.5);
            means.add(center);
        }
        means.scale(1 / numIndices);

        var diff2:Vector3f = new Vector3f();
        for (i in startIndex...endIndex)
		{
            center.add2(getAabbMax(i), getAabbMin(i));
            center.scale(0.5);
            diff2.sub2(center, means);
            //diff2 = diff2 * diff2;
            VectorUtil.mul(diff2, diff2, diff2);
            variance.add(diff2);
        }
        variance.scale(1 / (numIndices - 1));

        return VectorUtil.maxAxis(variance);
    }

    public function reportAabbOverlappingNodex(nodeCallback:NodeOverlapCallback, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
        // either choose recursive traversal (walkTree) or stackless (walkStacklessTree)

        if (useQuantization)
		{
            // quantize query AABB
            var quantizedQueryAabbMin:Int;
            var quantizedQueryAabbMax:Int;
            quantizedQueryAabbMin = quantizeWithClamp(aabbMin);
            quantizedQueryAabbMax = quantizeWithClamp(aabbMax);

            // JAVA TODO:
            switch (traversalMode) 
			{
                case STACKLESS:
                    walkStacklessQuantizedTree(nodeCallback, quantizedQueryAabbMin, quantizedQueryAabbMax, 0, curNodeIndex);
//				case STACKLESS_CACHE_FRIENDLY:
//					walkStacklessQuantizedTreeCacheFriendly(nodeCallback, quantizedQueryAabbMin, quantizedQueryAabbMax);
                case RECURSIVE:
                    walkRecursiveQuantizedTreeAgainstQueryAabb(quantizedContiguousNodes, 0, nodeCallback, quantizedQueryAabbMin, quantizedQueryAabbMax);
                default:
                    //assert (false); // unsupported
            }
        } 
		else
		{
            walkStacklessTree(nodeCallback, aabbMin, aabbMax);
        }
    }

    private function walkStacklessTree( nodeCallback:NodeOverlapCallback, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
        Assert.assert (!useQuantization);

        // JAVA NOTE: rewritten
        var rootNode:OptimizedBvhNode = null;//contiguousNodes.get(0);
        var rootNode_index:Int = 0;

        var escapeIndex:Int, curIndex:Int = 0;
        var walkIterations:Int = 0;
        var isLeafNode:Bool;
        //PCK: unsigned instead of bool
        //unsigned aabbOverlap;
        var aabbOverlap:Bool;

        while (curIndex < curNodeIndex)
		{
            // catch bugs in tree data
            //assert (walkIterations < curNodeIndex);

            walkIterations++;

            rootNode = contiguousNodes.getQuick(rootNode_index);

            aabbOverlap = AabbUtil2.testAabbAgainstAabb2(aabbMin, aabbMax, rootNode.aabbMinOrg, rootNode.aabbMaxOrg);
            isLeafNode = (rootNode.escapeIndex == -1);

            // PCK: unsigned instead of bool
            if (isLeafNode && (aabbOverlap/* != 0*/))
			{
                nodeCallback.processNode(rootNode.subPart, rootNode.triangleIndex);
            }

            rootNode = null;

            //PCK: unsigned instead of bool
            if ((aabbOverlap/* != 0*/) || isLeafNode)
			{
                rootNode_index++;
                curIndex++;
            } 
			else 
			{
                escapeIndex = /*rootNode*/ contiguousNodes.getQuick(rootNode_index).escapeIndex;
                rootNode_index += escapeIndex;
                curIndex += escapeIndex;
            }
        }
        if (maxIterations < walkIterations)
		{
            maxIterations = walkIterations;
        }
    }

    private function walkRecursiveQuantizedTreeAgainstQueryAabb(currentNodes:QuantizedBvhNodes, currentNodeId:Int, nodeCallback:NodeOverlapCallback, quantizedQueryAabbMin:Int, quantizedQueryAabbMax:Int):Void
	{
        Assert.assert (useQuantization);

        var isLeafNode:Bool;
        var aabbOverlap:Bool;

        aabbOverlap = testQuantizedAabbAgainstQuantizedAabb(quantizedQueryAabbMin, quantizedQueryAabbMax, currentNodes.getQuantizedAabbMin(currentNodeId), currentNodes.getQuantizedAabbMax(currentNodeId));
        isLeafNode = currentNodes.isLeafNode(currentNodeId);

        if (aabbOverlap) 
		{
            if (isLeafNode)
			{
                nodeCallback.processNode(currentNodes.getPartId(currentNodeId), currentNodes.getTriangleIndex(currentNodeId));
            } 
			else
			{
                // process left and right children
                var leftChildNodeId:Int = currentNodeId + 1;
                walkRecursiveQuantizedTreeAgainstQueryAabb(currentNodes, leftChildNodeId, nodeCallback, quantizedQueryAabbMin, quantizedQueryAabbMax);

                var rightChildNodeId:Int = currentNodes.isLeafNode(leftChildNodeId) ? leftChildNodeId + 1 : leftChildNodeId + currentNodes.getEscapeIndex(leftChildNodeId);
                walkRecursiveQuantizedTreeAgainstQueryAabb(currentNodes, rightChildNodeId, nodeCallback, quantizedQueryAabbMin, quantizedQueryAabbMax);
            }
        }
    }

    private function walkStacklessQuantizedTreeAgainstRay(nodeCallback:NodeOverlapCallback, raySource:Vector3f, rayTarget:Vector3f, aabbMin:Vector3f, aabbMax:Vector3f, startNodeIndex:Int, endNodeIndex:Int):Void
	{
        Assert.assert (useQuantization);

        var tmp:Vector3f = new Vector3f();

        var curIndex:Int = startNodeIndex;
        var walkIterations:Int = 0;
        var subTreeSize:Int = endNodeIndex - startNodeIndex;

        var rootNode:QuantizedBvhNodes = quantizedContiguousNodes;
        var rootNode_idx = startNodeIndex;
        var escapeIndex;

        var isLeafNode:Bool;
        var boxBoxOverlap:Bool = false;
        var rayBoxOverlap:Bool = false;

        var lambda_max:Float = 1;
        //#define RAYAABB2
        //#ifdef RAYAABB2
        var rayFrom:Vector3f = raySource.clone();
        var rayDirection:Vector3f = new Vector3f();
        tmp.sub2(rayTarget, raySource);
        rayDirection.normalize(tmp);
        lambda_max = rayDirection.dot(tmp);
        rayDirection.x = 1 / rayDirection.x;
        rayDirection.y = 1 / rayDirection.y;
        rayDirection.z = 1 / rayDirection.z;
//		boolean sign_x = rayDirection.x < 0f;
//		boolean sign_y = rayDirection.y < 0f;
//		boolean sign_z = rayDirection.z < 0f;
        //#endif

		/* Quick pruning by quantized box */
        var rayAabbMin:Vector3f = raySource.clone();
        var rayAabbMax:Vector3f = raySource.clone();
        VectorUtil.setMin(rayAabbMin, rayTarget);
        VectorUtil.setMax(rayAabbMax, rayTarget);

		/* Add box cast extents to bounding box */
        rayAabbMin.add(aabbMin);
        rayAabbMax.add(aabbMax);

        var quantizedQueryAabbMin:Int;
        var quantizedQueryAabbMax:Int;
        quantizedQueryAabbMin = quantizeWithClamp(rayAabbMin);
        quantizedQueryAabbMax = quantizeWithClamp(rayAabbMax);

        var bounds_0:Vector3f = new Vector3f();
        var bounds_1:Vector3f = new Vector3f();
        var normal:Vector3f = new Vector3f();
        var param:Array<Float> = [0];

        while (curIndex < endNodeIndex)
		{

            //#define VISUALLY_ANALYZE_BVH 1
            //#ifdef VISUALLY_ANALYZE_BVH
            //		//some code snippet to debugDraw aabb, to visually analyze bvh structure
            //		static int drawPatch = 0;
            //		//need some global access to a debugDrawer
            //		extern btIDebugDraw* debugDrawerPtr;
            //		if (curIndex==drawPatch)
            //		{
            //			btVector3 aabbMin,aabbMax;
            //			aabbMin = unQuantize(rootNode->m_quantizedAabbMin);
            //			aabbMax = unQuantize(rootNode->m_quantizedAabbMax);
            //			btVector3	color(1,0,0);
            //			debugDrawerPtr->drawAabb(aabbMin,aabbMax,color);
            //		}
            //#endif//VISUALLY_ANALYZE_BVH

            // catch bugs in tree data
            //assert (walkIterations < subTreeSize);

            walkIterations++;
            // only interested if this is closer than any previous hit
            param[0] = 1;
            rayBoxOverlap = false;
            boxBoxOverlap = testQuantizedAabbAgainstQuantizedAabb(quantizedQueryAabbMin, quantizedQueryAabbMax, rootNode.getQuantizedAabbMin(rootNode_idx), rootNode.getQuantizedAabbMax(rootNode_idx));
            isLeafNode = rootNode.isLeafNode(rootNode_idx);
            if (boxBoxOverlap)
			{
                unQuantize(bounds_0, rootNode.getQuantizedAabbMin(rootNode_idx));
                unQuantize(bounds_1, rootNode.getQuantizedAabbMax(rootNode_idx));
                /* Add box cast extents */
                bounds_0.add(aabbMin);
                bounds_1.add(aabbMax);
                //#if 0
                //			bool ra2 = btRayAabb2 (raySource, rayDirection, sign, bounds, param, 0.0, lambda_max);
                //			bool ra = btRayAabb (raySource, rayTarget, bounds[0], bounds[1], param, normal);
                //			if (ra2 != ra)
                //			{
                //				printf("functions don't match\n");
                //			}
                //#endif
                //#ifdef RAYAABB2
                //			rayBoxOverlap = AabbUtil2.rayAabb2 (raySource, rayDirection, sign, bounds, param, 0.0, lambda_max);
                //#else
                rayBoxOverlap = AabbUtil2.rayAabb(raySource, rayTarget, bounds_0, bounds_1, param, normal);
                //#endif
            }

            if (isLeafNode && rayBoxOverlap)
			{
                nodeCallback.processNode(rootNode.getPartId(rootNode_idx), rootNode.getTriangleIndex(rootNode_idx));
            }

            if (rayBoxOverlap || isLeafNode)
			{
                rootNode_idx++;
                curIndex++;
            } 
			else 
			{
                escapeIndex = rootNode.getEscapeIndex(rootNode_idx);
                rootNode_idx += escapeIndex;
                curIndex += escapeIndex;
            }
        }

        if (maxIterations < walkIterations) {
            maxIterations = walkIterations;
        }
    }

    private function walkStacklessQuantizedTree(nodeCallback:NodeOverlapCallback, quantizedQueryAabbMin:Int, quantizedQueryAabbMax:Int, startNodeIndex:Int, endNodeIndex:Int):Void 
	{
		Assert.assert (useQuantization);

        var curIndex:Int = startNodeIndex;
        var walkIterations:Int = 0;
        var subTreeSize:Int = endNodeIndex - startNodeIndex;

        var rootNode:QuantizedBvhNodes = quantizedContiguousNodes;
        var rootNode_idx:Int = startNodeIndex;
        var escapeIndex:Int;

        var isLeafNode:Bool;
        var aabbOverlap:Bool;

        while (curIndex < endNodeIndex)
		{
            ////#define VISUALLY_ANALYZE_BVH 1
            //#ifdef VISUALLY_ANALYZE_BVH
            ////some code snippet to debugDraw aabb, to visually analyze bvh structure
            //static int drawPatch = 0;
            ////need some global access to a debugDrawer
            //extern btIDebugDraw* debugDrawerPtr;
            //if (curIndex==drawPatch)
            //{
            //	btVector3 aabbMin,aabbMax;
            //	aabbMin = unQuantize(rootNode->m_quantizedAabbMin);
            //	aabbMax = unQuantize(rootNode->m_quantizedAabbMax);
            //	btVector3	color(1,0,0);
            //	debugDrawerPtr->drawAabb(aabbMin,aabbMax,color);
            //}
            //#endif//VISUALLY_ANALYZE_BVH

            // catch bugs in tree data
            //assert (walkIterations < subTreeSize);

            walkIterations++;
            aabbOverlap = testQuantizedAabbAgainstQuantizedAabb(quantizedQueryAabbMin, quantizedQueryAabbMax, rootNode.getQuantizedAabbMin(rootNode_idx), rootNode.getQuantizedAabbMax(rootNode_idx));
            isLeafNode = rootNode.isLeafNode(rootNode_idx);

            if (isLeafNode && aabbOverlap)
			{
                nodeCallback.processNode(rootNode.getPartId(rootNode_idx), rootNode.getTriangleIndex(rootNode_idx));
            }

            if (aabbOverlap || isLeafNode) 
			{
                rootNode_idx++;
                curIndex++;
            } 
			else
			{
                escapeIndex = rootNode.getEscapeIndex(rootNode_idx);
                rootNode_idx += escapeIndex;
                curIndex += escapeIndex;
            }
        }

        if (maxIterations < walkIterations)
		{
            maxIterations = walkIterations;
        }
    }

    public function reportRayOverlappingNodex(nodeCallback:NodeOverlapCallback, raySource:Vector3f, rayTarget:Vector3f):Void
	{
        var fast_path:Bool = useQuantization && traversalMode == TraversalMode.STACKLESS;
        if (fast_path)
		{
            var tmp:Vector3f = new Vector3f();
            walkStacklessQuantizedTreeAgainstRay(nodeCallback, raySource, rayTarget, tmp, tmp, 0, curNodeIndex);
        } 
		else
		{
            /* Otherwise fallback to AABB overlap test */
            var aabbMin:Vector3f = raySource.clone();
            var aabbMax:Vector3f = raySource.clone();
            VectorUtil.setMin(aabbMin, rayTarget);
            VectorUtil.setMax(aabbMax, rayTarget);
            reportAabbOverlappingNodex(nodeCallback, aabbMin, aabbMax);
        }
    }

    public function reportBoxCastOverlappingNodex(nodeCallback:NodeOverlapCallback, raySource:Vector3f, rayTarget:Vector3f, aabbMin:Vector3f, aabbMax:Vector3f):Void 
	{
        var fast_path:Bool = useQuantization && traversalMode == TraversalMode.STACKLESS;
        if (fast_path) 
		{
            walkStacklessQuantizedTreeAgainstRay(nodeCallback, raySource, rayTarget, aabbMin, aabbMax, 0, curNodeIndex);
        } 
		else 
		{
			/* Slow path:
			Construct the bounding box for the entire box cast and send that down the tree */
			var qaabbMin:Vector3f = raySource.clone();
            var qaabbMax:Vector3f = raySource.clone();
            VectorUtil.setMin(qaabbMin, rayTarget);
            VectorUtil.setMax(qaabbMax, rayTarget);
            qaabbMin.add(aabbMin);
            qaabbMax.add(aabbMax);
            reportAabbOverlappingNodex(nodeCallback, qaabbMin, qaabbMax);
        }
    }

    public function quantizeWithClamp(point:Vector3f):Int
	{
        Assert.assert (useQuantization);

        var clampedPoint:Vector3f = point.clone();
        VectorUtil.setMax(clampedPoint, bvhAabbMin);
        VectorUtil.setMin(clampedPoint, bvhAabbMax);

        var v:Vector3f = new Vector3f();
        v.sub2(clampedPoint, bvhAabbMin);
        VectorUtil.mul(v, v, bvhQuantization);

        var out0:Int = Std.int(v.x + 0.5) & 0xFFFF;
        var out1:Int = Std.int(v.y + 0.5) & 0xFFFF;
        var out2:Int = Std.int(v.z + 0.5) & 0xFFFF;

        return (out0 | out1 << 16 | out2 << 32);
    }

    public function unQuantize(vecOut:Vector3f, vecIn:Int):Void 
	{
		//TODO 修改这里
        var vecIn0:Int = 0;// Std.int((vecIn & 0x00000000FFFF));
        var vecIn1:Int = 0;//Std.int((vecIn & 0x0000FFFF0000) >>> 16);
        var vecIn2:Int = 0;//Std.int((vecIn & 0xFFFF00000000) >>> 32);

        vecOut.x = vecIn0 / bvhQuantization.x;
        vecOut.y = vecIn1 / bvhQuantization.y;
        vecOut.z = vecIn2 / bvhQuantization.z;

        vecOut.add(bvhAabbMin);
    }
}

class NodeTriangleCallback extends InternalTriangleIndexCallback 
{
	public var triangleNodes:ObjectArrayList<OptimizedBvhNode>;
	
	private var aabbMin:Vector3f = new Vector3f();
	private var aabbMax:Vector3f = new Vector3f();

	public function new(triangleNodes:ObjectArrayList<OptimizedBvhNode>)
	{
		super();
		this.triangleNodes = triangleNodes;
	}

	override public function internalProcessTriangleIndex(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void
	{
		var node:OptimizedBvhNode = new OptimizedBvhNode();
		aabbMin.setTo(1e30, 1e30, 1e30);
		aabbMax.setTo(-1e30, -1e30, -1e30);
		VectorUtil.setMin(aabbMin, triangle[0]);
		VectorUtil.setMax(aabbMax, triangle[0]);
		VectorUtil.setMin(aabbMin, triangle[1]);
		VectorUtil.setMax(aabbMax, triangle[1]);
		VectorUtil.setMin(aabbMin, triangle[2]);
		VectorUtil.setMax(aabbMax, triangle[2]);

		// with quantization?
		node.aabbMinOrg.fromVector3f(aabbMin);
		node.aabbMaxOrg.fromVector3f(aabbMax);

		node.escapeIndex = -1;

		// for child nodes
		node.subPart = partId;
		node.triangleIndex = triangleIndex;
		triangleNodes.add(node);
	}
}

class QuantizedNodeTriangleCallback extends InternalTriangleIndexCallback 
{

	public var triangleNodes:QuantizedBvhNodes;
	public var optimizedTree:OptimizedBvh; // for quantization

	public function new( triangleNodes:QuantizedBvhNodes, tree:OptimizedBvh)
	{
		super();
		this.triangleNodes = triangleNodes;
		this.optimizedTree = tree;
	}

	override public function internalProcessTriangleIndex(triangle:Array<Vector3f>, partId:Int, triangleIndex:Int):Void
	{
		// The partId and triangle index must fit in the same (positive) integer
		//assert (partId < (1 << MAX_NUM_PARTS_IN_BITS));
		//assert (triangleIndex < (1 << (31 - MAX_NUM_PARTS_IN_BITS)));
		// negative indices are reserved for escapeIndex
		//assert (triangleIndex >= 0);

		var nodeId:Int = triangleNodes.add();
		var aabbMin:Vector3f = new Vector3f();
		var aabbMax:Vector3f = new Vector3f();
		aabbMin.setTo(1e30, 1e30, 1e30);
		aabbMax.setTo(-1e30, -1e30, -1e30);
		VectorUtil.setMin(aabbMin, triangle[0]);
		VectorUtil.setMax(aabbMax, triangle[0]);
		VectorUtil.setMin(aabbMin, triangle[1]);
		VectorUtil.setMax(aabbMax, triangle[1]);
		VectorUtil.setMin(aabbMin, triangle[2]);
		VectorUtil.setMax(aabbMax, triangle[2]);

		// PCK: add these checks for zero dimensions of aabb
		var MIN_AABB_DIMENSION:Float = 0.002;
		var MIN_AABB_HALF_DIMENSION:Float = 0.001;
		if (aabbMax.x - aabbMin.x < MIN_AABB_DIMENSION) 
		{
			aabbMax.x = (aabbMax.x + MIN_AABB_HALF_DIMENSION);
			aabbMin.x = (aabbMin.x - MIN_AABB_HALF_DIMENSION);
		}
		if (aabbMax.y - aabbMin.y < MIN_AABB_DIMENSION)
		{
			aabbMax.y = (aabbMax.y + MIN_AABB_HALF_DIMENSION);
			aabbMin.y = (aabbMin.y - MIN_AABB_HALF_DIMENSION);
		}
		if (aabbMax.z - aabbMin.z < MIN_AABB_DIMENSION) 
		{
			aabbMax.z = (aabbMax.z + MIN_AABB_HALF_DIMENSION);
			aabbMin.z = (aabbMin.z - MIN_AABB_HALF_DIMENSION);
		}

		triangleNodes.setQuantizedAabbMin(nodeId, optimizedTree.quantizeWithClamp(aabbMin));
		triangleNodes.setQuantizedAabbMax(nodeId, optimizedTree.quantizeWithClamp(aabbMax));

		triangleNodes.setEscapeIndexOrTriangleIndex(nodeId, (partId << (31 - OptimizedBvh.MAX_NUM_PARTS_IN_BITS)) | triangleIndex);
	}
}