package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.broadphase.Dbvt.DbvtNode;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.linearmath.Transform;
import de.polygonal.ds.ArrayUtil;
import de.polygonal.ds.error.Assert;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;
import vecmath.FastMath;
import vecmath.Vector3f;
import haxe.ds.Vector;

/**
 * ...
 * @author weilichuang
 */
class Dbvt
{
	public static inline var SIMPLE_STACKSIZE:Int = 64;
    public static inline var DOUBLE_STACKSIZE:Int = 128;

    public var root:DbvtNode = null;
    public var free:DbvtNode = null;
    public var lkhd:Int = -1;
    public var leaves:Int = 0;
    public var opath:Int = 0;

    public function new()
	{
    }

    public function clear():Void
	{
        if (root != null) 
		{
            recursedeletenode(this, root);
        }
        //btAlignedFree(m_free);
        free = null;
    }

    public function empty():Bool
	{
        return (root == null);
    }

    public function optimizeBottomUp():Void
	{
        if (root != null)
		{
            var leaves:ObjectArrayList<DbvtNode> = new ObjectArrayList<DbvtNode>(this.leaves);
            fetchleaves(this, root, leaves);
            bottomup(this, leaves);
            root = leaves.getQuick(0);
        }
    }

    public function optimizeTopDown(bu_treshold:Int = 128):Void
	{
        if (root != null)
		{
            var leaves:ObjectArrayList<DbvtNode> = new ObjectArrayList<DbvtNode>(this.leaves);
            fetchleaves(this, root, leaves);
            root = topdown(this, leaves, bu_treshold);
        }
    }

    public function optimizeIncremental(passes:Int):Void
	{
        if (passes < 0)
		{
            passes = leaves;
        }

        if (root != null && (passes > 0))
		{
            var root_ref:Array<DbvtNode> = [null];
            do {
                var node:DbvtNode = root;
                var bit:Int = 0;
                while (node.isinternal()) 
				{
                    root_ref[0] = root;
                    node = sort(node, root_ref).childs[(opath >>> bit) & 1];
                    root = root_ref[0];

                    bit = (bit + 1) & (/*sizeof(unsigned)*/4 * 8 - 1);
                }
                update(node);
                ++opath;
            }
            while ((--passes) != 0);
        }
    }

    public inline function insert(box:DbvtAabbMm, data:Dynamic):DbvtNode
	{
        var leaf:DbvtNode = createnode(this, null, box, data);
        insertleaf(this, root, leaf);
        leaves++;
        return leaf;
    }

    public function update(leaf:DbvtNode, lookahead:Int = -1):Void
	{
        var root:DbvtNode = removeleaf(this, leaf);
        if (root != null)
		{
            if (lookahead >= 0)
			{
				var i:Int = 0;
                while ((i < lookahead) && root.parent != null )
				{
                    root = root.parent;
					i++;
                }
            } 
			else
			{
                root = this.root;
            }
        }
        insertleaf(this, root, leaf);
    }

    public function update2(leaf:DbvtNode, volume:DbvtAabbMm):Void
	{
        var root:DbvtNode = removeleaf(this, leaf);
        if (root != null)
		{
            if (lkhd >= 0) 
			{
				var i:Int = 0;
                while ((i < lkhd) && root.parent != null )
				{
                    root = root.parent;
					i++;
                }
            } 
			else
			{
                root = this.root;
            }
        }
        leaf.volume.set(volume);
        insertleaf(this, root, leaf);
    }

	private var tmp:Vector3f = new Vector3f();
    public function update3(leaf:DbvtNode, volume:DbvtAabbMm, velocity:Vector3f, margin:Float):Bool
	{
        if (leaf.volume.Contain(volume)) 
		{
            return false;
        }
        tmp.setTo(margin, margin, margin);
        volume.Expand(tmp);
        volume.SignedExpand(velocity);
        update2(leaf, volume);
        return true;
    }

    public function update4(leaf:DbvtNode, volume:DbvtAabbMm, velocity:Vector3f):Bool
	{
        if (leaf.volume.Contain(volume))
		{
            return false;
        }
        volume.SignedExpand(velocity);
        update2(leaf, volume);
        return true;
    }

    public function update5(leaf:DbvtNode, volume:DbvtAabbMm, margin:Float):Bool
	{
        if (leaf.volume.Contain(volume))
		{
            return false;
        }
        tmp.setTo(margin, margin, margin);
        volume.Expand(tmp);
        update2(leaf, volume);
        return true;
    }

    public inline function remove(leaf:DbvtNode):Void
	{
        removeleaf(this, leaf);
        deletenode(this, leaf);
        leaves--;
    }

    public function write(iwriter:IWriter):Void
	{
        //throw new UnsupportedOperationException();
    }

    public function clone(dest:Dbvt, iclone:IClone = null)
	{
        //throw new UnsupportedOperationException();
    }

    public static inline function countLeaves(node:DbvtNode):Int
	{
        if (node.isinternal()) 
		{
            return countLeaves(node.childs[0]) + countLeaves(node.childs[1]);
        } 
		else
		{
            return 1;
        }
    }

    public static inline function extractLeaves(node:DbvtNode, leaves:ObjectArrayList<DbvtNode>):Void
	{
        if (node.isinternal())
		{
            extractLeaves(node.childs[0], leaves);
            extractLeaves(node.childs[1], leaves);
        }
		else 
		{
            leaves.add(node);
        }
    }

    public static inline function enumNodes(root:DbvtNode, policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        policy.Process(root);
        if (root.isinternal())
		{
            enumNodes(root.childs[0], policy);
            enumNodes(root.childs[1], policy);
        }
    }

    public static inline function enumLeaves(root:DbvtNode, policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root.isinternal())
		{
            enumLeaves(root.childs[0], policy);
            enumLeaves(root.childs[1], policy);
        } 
		else
		{
            policy.Process(root);
        }
    }

	//此方法需要大量优化
	//测试结果：8000ms内此函数共耗时311ms
	//TODO ObjectArrayList删除操作很慢，这里考虑不要使用ObjectArrayList
    //public static function collideTT(root0:DbvtNode, root1:DbvtNode,  policy:ICollide):Void 
	//{
        ////DBVT_CHECKTYPE
        //if (root0 != null && root1 != null) 
		//{
            //var stack:ObjectArrayList<SStkNN> = new ObjectArrayList<SStkNN>(DOUBLE_STACKSIZE);
            //stack.add(new SStkNN(root0, root1));
            //do {
                //var p:SStkNN = stack.remove(stack.size() - 1);
				//var a:DbvtNode = p.a;
				//var b:DbvtNode = p.b;
                //if (a == b)
				//{
                    //if (a.isinternal())
					//{
                        //stack.add(new SStkNN(a.childs[0], a.childs[0]));
                        //stack.add(new SStkNN(a.childs[1], a.childs[1]));
                        //stack.add(new SStkNN(a.childs[0], a.childs[1]));
                    //}
                //} 
				//else if (DbvtAabbMm.Intersect(a.volume, b.volume)) 
				//{
                    //if (a.isinternal()) 
					//{
                        //if (b.isinternal()) 
						//{
                            //stack.add(new SStkNN(a.childs[0], b.childs[0]));
                            //stack.add(new SStkNN(a.childs[1], b.childs[0]));
                            //stack.add(new SStkNN(a.childs[0], b.childs[1]));
                            //stack.add(new SStkNN(a.childs[1], b.childs[1]));
                        //}
						//else 
						//{
                            //stack.add(new SStkNN(a.childs[0], b));
                            //stack.add(new SStkNN(a.childs[1], b));
                        //}
                    //} 
					//else 
					//{
                        //if (p.b.isinternal())
						//{
                            //stack.add(new SStkNN(a, b.childs[0]));
                            //stack.add(new SStkNN(a, b.childs[1]));
                        //} 
						//else 
						//{
                            //policy.Process2(a, b);
                        //}
                    //}
                //}
            //}
            //while (stack.size() > 0);
        //}
    //}
	
	private static var tmpStackList:Array<DbvtNode> = [];
	private static var tmpStackListSize:Int = 0;
	public static inline function collideTT(root0:DbvtNode, root1:DbvtNode,  policy:ICollide):Void 
	{
        if (root0 != null && root1 != null) 
		{
            //var stack:ObjectArrayList<SStkNN> = new ObjectArrayList<SStkNN>(DOUBLE_STACKSIZE);
            //stack.add(new SStkNN(root0, root1));
			tmpStackList[0] = root0;
			tmpStackList[1] = root1;
			tmpStackListSize = 2;
            do {
                //var p:SStkNN = stack.remove(stack.size() - 1);
				//var a:DbvtNode = p.a;
				//var b:DbvtNode = p.b;
				
				tmpStackListSize -= 2;
				var a:DbvtNode = tmpStackList[tmpStackListSize];
				var b:DbvtNode = tmpStackList[tmpStackListSize + 1];
                if (a == b)
				{
                    if (a.isinternal())
					{
						//stack.add(new SStkNN(a.childs[0], a.childs[0]));
                        //stack.add(new SStkNN(a.childs[1], a.childs[1]));
                        //stack.add(new SStkNN(a.childs[0], a.childs[1]));
						
						var child0:DbvtNode = a.childs[0];
						var child1:DbvtNode = a.childs[1];
						
						tmpStackList[tmpStackListSize++] = child0;
						tmpStackList[tmpStackListSize++] = child0;
						
						tmpStackList[tmpStackListSize++] = child1;
						tmpStackList[tmpStackListSize++] = child1;
						
						tmpStackList[tmpStackListSize++] = child0;
						tmpStackList[tmpStackListSize++] = child1;
                    }
                } 
				else if (DbvtAabbMm.Intersect(a.volume, b.volume)) 
				{
                    if (a.isinternal()) 
					{
                        if (b.isinternal()) 
						{
                            //stack.add(new SStkNN(a.childs[0], b.childs[0]));
                            //stack.add(new SStkNN(a.childs[1], b.childs[0]));
                            //stack.add(new SStkNN(a.childs[0], b.childs[1]));
                            //stack.add(new SStkNN(a.childs[1], b.childs[1]));
							
							var achild0:DbvtNode = a.childs[0];
							var achild1:DbvtNode = a.childs[1];
							
							var bchild0:DbvtNode = b.childs[0];
							var bchild1:DbvtNode = b.childs[1];
							
							tmpStackList[tmpStackListSize++] = achild0;
							tmpStackList[tmpStackListSize++] = bchild0;
							
							tmpStackList[tmpStackListSize++] = achild1;
							tmpStackList[tmpStackListSize++] = bchild0;
							
							tmpStackList[tmpStackListSize++] = achild0;
							tmpStackList[tmpStackListSize++] = bchild1;
							
							tmpStackList[tmpStackListSize++] = achild1;
							tmpStackList[tmpStackListSize++] = bchild1;
                        }
						else 
						{
                            //stack.add(new SStkNN(a.childs[0], b));
                            //stack.add(new SStkNN(a.childs[1], b));
							
							tmpStackList[tmpStackListSize++] = a.childs[0];
							tmpStackList[tmpStackListSize++] = b;
							
							tmpStackList[tmpStackListSize++] = a.childs[1];
							tmpStackList[tmpStackListSize++] = b;
                        }
                    } 
					else 
					{
                        if (b.isinternal())
						{
                            //stack.add(new SStkNN(a, b.childs[0]));
                            //stack.add(new SStkNN(a, b.childs[1]));
							
							tmpStackList[tmpStackListSize++] = a;
							tmpStackList[tmpStackListSize++] = b.childs[0];
							
							tmpStackList[tmpStackListSize++] = a;
							tmpStackList[tmpStackListSize++] = b.childs[1];
                        } 
						else 
						{
                            policy.Process2(a, b);
                        }
                    }
                }
            }
			//while (stack.size() > 0);
            while (tmpStackListSize > 0);
        }
    }

    public static function collideTT2(root0:DbvtNode, root1:DbvtNode, xform:Transform, policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root0 != null && root1 != null) 
		{
            var stack:ObjectArrayList<SStkNN> = new ObjectArrayList<SStkNN>(DOUBLE_STACKSIZE);
            stack.add(new SStkNN(root0, root1));
            do 
			{
                var p:SStkNN = stack.remove(stack.size() - 1);
				var a = p.a; var b = p.b;
                if (a == b) 
				{
                    if (a.isinternal())
					{
                        stack.add(new SStkNN(a.childs[0], a.childs[0]));
                        stack.add(new SStkNN(a.childs[1], a.childs[1]));
                        stack.add(new SStkNN(a.childs[0], a.childs[1]));
                    }
                } 
				else if (DbvtAabbMm.Intersect2(a.volume, b.volume, xform))
				{
                    if (a.isinternal())
					{
                        if (b.isinternal())
						{
                            stack.add(new SStkNN(a.childs[0], b.childs[0]));
                            stack.add(new SStkNN(a.childs[1], b.childs[0]));
                            stack.add(new SStkNN(a.childs[0], b.childs[1]));
                            stack.add(new SStkNN(a.childs[1], b.childs[1]));
                        } 
						else 
						{
                            stack.add(new SStkNN(a.childs[0], b));
                            stack.add(new SStkNN(a.childs[1], b));
                        }
                    }
					else 
					{
                        if (b.isinternal())
						{
                            stack.add(new SStkNN(a, b.childs[0]));
                            stack.add(new SStkNN(a, b.childs[1]));
                        } 
						else
						{
                            policy.Process2(a, b);
                        }
                    }
                }
            }
            while (stack.size() > 0);
        }
    }

	private static var xform:Transform = new Transform();
    public static inline function collideTT3(root0:DbvtNode, xform0:Transform, root1:DbvtNode, xform1:Transform, policy:ICollide):Void
	{
        xform.inverse(xform0);
        xform.mul(xform1);
        collideTT2(root0, root1, xform, policy);
    }

    public static function collideTV(root:DbvtNode, volume:DbvtAabbMm, policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root != null)
		{
            var stack:ObjectArrayList<DbvtNode> = new ObjectArrayList<DbvtNode>(SIMPLE_STACKSIZE);
            stack.add(root);
            do {
                var n:DbvtNode = stack.remove(stack.size() - 1);
                if (DbvtAabbMm.Intersect(n.volume, volume)) 
				{
                    if (n.isinternal())
					{
                        stack.add(n.childs[0]);
                        stack.add(n.childs[1]);
                    } 
					else
					{
                        policy.Process(n);
                    }
                }
            }
            while (stack.size() > 0);
        }
    }

	private static var normal:Vector3f = new Vector3f();
	private static var invdir:Vector3f = new Vector3f();
    public static function collideRAY(root:DbvtNode, origin:Vector3f, direction:Vector3f, policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root != null) 
		{
            normal.normalize(direction);
            
            invdir.setTo(1 / normal.x, 1 / normal.y, 1 / normal.z);
            var signs:Array<Int> = [direction.x < 0 ? 1 : 0, direction.y < 0 ? 1 : 0, direction.z < 0 ? 1 : 0];
            var stack:ObjectArrayList<DbvtNode> = new ObjectArrayList<DbvtNode>(SIMPLE_STACKSIZE);
            stack.add(root);
            do {
                var node:DbvtNode = stack.remove(stack.size() - 1);
                if (DbvtAabbMm.Intersect4(node.volume, origin, invdir, signs))
				{
                    if (node.isinternal()) 
					{
                        stack.add(node.childs[0]);
                        stack.add(node.childs[1]);
                    } 
					else 
					{
                        policy.Process(node);
                    }
                }
            }
            while (stack.size() != 0);
        }
    }

	private static var signs:Vector<Int> = new Vector<Int>(4 * 8);
    public static function collideKDOP(root:DbvtNode, normals:Array<Vector3f>, offsets:Array<Float>, count:Int,  policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root != null) 
		{
            var inside:Int = (1 << count) - 1;
            var stack:ObjectArrayList<SStkNP> = new ObjectArrayList<SStkNP>(SIMPLE_STACKSIZE);
            
			#if debug
            Assert.assert (count < (/*sizeof(signs)*/128 / /*sizeof(signs[0])*/ 4));
			#end
			
            for (i in 0...count)
			{
                signs[i] = ((normals[i].x >= 0) ? 1 : 0) +
                        ((normals[i].y >= 0) ? 2 : 0) +
                        ((normals[i].z >= 0) ? 4 : 0);
            }
			
            stack.add(new SStkNP(root, 0));
            do {
                var se:SStkNP = stack.remove(stack.size() - 1);
                var out:Bool = false;
				var i:Int = 0;
				var j:Int = 1;
                while ((!out) && (i < count))
				{
                    if (0 == (se.mask & j))
					{
                        var side:Int = se.node.volume.Classify(normals[i], offsets[i], signs[i]);
                        switch (side) 
						{
                            case -1:
                                out = true;
                            case 1:
                                se.mask |= j;
                        }
                    }
					
					++i;
					j <<= 1;
                }
                if (!out) 
				{
                    if ((se.mask != inside) && (se.node.isinternal()))
					{
                        stack.add(new SStkNP(se.node.childs[0], se.mask));
                        stack.add(new SStkNP(se.node.childs[1], se.mask));
                    } 
					else 
					{
                        if (policy.AllLeaves(se.node))
						{
                            enumLeaves(se.node, policy);
                        }
                    }
                }
            }
            while (stack.size() != 0);
        }
    }

	private static var ifree:IntArrayList = new IntArrayList();
	private static var stack:IntArrayList = new IntArrayList();
    public static function collideOCL(root:DbvtNode, normals:Array<Vector3f>, offsets:Array<Float>, sortaxis:Vector3f, count:Int, policy:ICollide, fullsort:Bool = true):Void
	{
        //DBVT_CHECKTYPE
        if (root != null)
		{
            var srtsgns:Int = (sortaxis.x >= 0 ? 1 : 0) +
                    (sortaxis.y >= 0 ? 2 : 0) +
                    (sortaxis.z >= 0 ? 4 : 0);
            var inside:Int = (1 << count) - 1;
            var stock:ObjectArrayList<SStkNPS> = new ObjectArrayList<SStkNPS>();
           
			#if debug
            Assert.assert (count < (/*sizeof(signs)*/128 / /*sizeof(signs[0])*/ 4));
			#end
			
            for (i in 0...count)
			{
                signs[i] = ((normals[i].x >= 0) ? 1 : 0) +
                        ((normals[i].y >= 0) ? 2 : 0) +
                        ((normals[i].z >= 0) ? 4 : 0);
            }
            //stock.reserve(SIMPLE_STACKSIZE);
            //stack.reserve(SIMPLE_STACKSIZE);
            //ifree.reserve(SIMPLE_STACKSIZE);
            stack.add(allocate(ifree, stock, new SStkNPS(root, 0, root.volume.ProjectMinimum(sortaxis, srtsgns))));
            do {
                // JAVA NOTE: check
                var id:Int = stack.remove(stack.size() - 1);
                var se:SStkNPS = stock.getQuick(id);
                ifree.add(id);
                if (se.mask != inside)
				{
                    var out:Bool = false;
					
					var i:Int = 0;
					var j:Int = 1; 
                    while ((!out) && (i < count))
					{
                        if (0 == (se.mask & j))
						{
                            var side:Int = se.node.volume.Classify(normals[i], offsets[i], signs[i]);
                            switch (side)
							{
                                case -1:
                                    out = true;
                                case 1:
                                    se.mask |= j;
                            }
                        }
						
						++i;
						j <<= 1;
                    }
                    if (out)
					{
                        continue;
                    }
                }
                if (policy.Descent(se.node)) 
				{
                    if (se.node.isinternal()) 
					{
                        var pns:Array<DbvtNode> = [se.node.childs[0], se.node.childs[1]];
                        var nes:Array<SStkNPS> = [new SStkNPS(pns[0], se.mask, pns[0].volume.ProjectMinimum(sortaxis, srtsgns)),
                                new SStkNPS(pns[1], se.mask, pns[1].volume.ProjectMinimum(sortaxis, srtsgns))
                        ];
                        var q:Int = nes[0].value < nes[1].value ? 1 : 0;
                        var j:Int = stack.size();
                        if (fullsort && (j > 0)) 
						{
                            /* Insert 0	*/
                            j = nearest(stack, stock, nes[q].value, 0, stack.size());
                            stack.add(0);
                            //#if DBVT_USE_MEMMOVE
                            //memmove(&stack[j+1],&stack[j],sizeof(int)*(stack.size()-j-1));
                            //#else
							var k:Int = stack.size() - 1;
                            while ( k > j) 
							{
                                stack.set(k, stack.get(k - 1));
                                //#endif
								--k;
                            }
                            stack.set(j, allocate(ifree, stock, nes[q]));
                            /* Insert 1	*/
                            j = nearest(stack, stock, nes[1 - q].value, j, stack.size());
                            stack.add(0);
                            //#if DBVT_USE_MEMMOVE
                            //memmove(&stack[j+1],&stack[j],sizeof(int)*(stack.size()-j-1));
                            //#else
							var k:Int = stack.size() - 1;
                            while ( k > j)
							{
                                stack.set(k, stack.get(k - 1));
                                //#endif
								--k;
                            }
                            stack.set(j, allocate(ifree, stock, nes[1 - q]));
                        }
						else
						{
                            stack.add(allocate(ifree, stock, nes[q]));
                            stack.add(allocate(ifree, stock, nes[1 - q]));
                        }
                    } 
					else
					{
                        policy.Process3(se.node, se.value);
                    }
                }
            }
            while (stack.size() != 0);
        }
    }

    public static function collideTU( root:DbvtNode,  policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root != null) 
		{
            var stack:ObjectArrayList<DbvtNode> = new ObjectArrayList<DbvtNode>(SIMPLE_STACKSIZE);
            stack.add(root);
            do {
                var n:DbvtNode = stack.remove(stack.size() - 1);
                if (policy.Descent(n)) 
				{
                    if (n.isinternal()) 
					{
                        stack.add(n.childs[0]);
                        stack.add(n.childs[1]);
                    } 
					else
					{
                        policy.Process(n);
                    }
                }
            }
            while (stack.size() > 0);
        }
    }

    public static function nearest(i:IntArrayList, a:ObjectArrayList<SStkNPS>, v:Float, l:Int, h:Int):Int
	{
        var m:Int = 0;
        while (l < h)
		{
            m = (l + h) >> 1;
            if (a.getQuick(i.get(m)).value >= v) 
			{
                l = m + 1;
            } 
			else
			{
                h = m;
            }
        }
        return h;
    }

    public static function allocate(ifree:IntArrayList, stock:ObjectArrayList<SStkNPS>, value:SStkNPS):Int
	{
        var i:Int;
        if (ifree.size() > 0)
		{
            i = ifree.get(ifree.size() - 1);
            ifree.remove(ifree.size() - 1);
            stock.getQuick(i).set(value);
        }
		else 
		{
            i = stock.size();
            stock.add(value);
        }
        return i;
    }

    ////////////////////////////////////////////////////////////////////////////

    private static inline function indexof(node:DbvtNode):Int
	{
        return (node.parent.childs[1] == node) ? 1 : 0;
    }

    private static inline function merge(a:DbvtAabbMm, b:DbvtAabbMm, out:DbvtAabbMm):DbvtAabbMm
	{
        DbvtAabbMm.Merge(a, b, out);
        return out;
    }

    // volume+edge lengths
	private static var edges:Vector3f = new Vector3f();
    private static inline function size(a:DbvtAabbMm):Float
	{
		edges = a.Lengths(edges);
        return (edges.x * edges.y * edges.z +
                edges.x + edges.y + edges.z);
    }

    private static inline function deletenode(pdbvt:Dbvt, node:DbvtNode):Void
	{
        //btAlignedFree(pdbvt->m_free);
        pdbvt.free = node;
    }

    private static function recursedeletenode(pdbvt:Dbvt, node:DbvtNode):Void
	{
        if (!node.isleaf())
		{
            recursedeletenode(pdbvt, node.childs[0]);
            recursedeletenode(pdbvt, node.childs[1]);
        }
        if (node == pdbvt.root)
		{
            pdbvt.root = null;
        }
        deletenode(pdbvt, node);
    }

    private static function createnode(pdbvt:Dbvt, parent:DbvtNode, volume:DbvtAabbMm, data:Dynamic):DbvtNode
	{
        var node:DbvtNode;
        if (pdbvt.free != null)
		{
            node = pdbvt.free;
            pdbvt.free = null;
        } 
		else 
		{
            node = new DbvtNode();
        }
        node.parent = parent;
        node.volume.set(volume);
        node.data = data;
        node.childs[1] = null;
        return node;
    }

	private static var tmpAabbMm:DbvtAabbMm = new DbvtAabbMm();
    private static function insertleaf(pdbvt:Dbvt, root:DbvtNode, leaf:DbvtNode):Void
	{
        if (pdbvt.root == null)
		{
            pdbvt.root = leaf;
            leaf.parent = null;
        } 
		else
		{
            if (!root.isleaf())
			{
                do {
					var childs:Vector<DbvtNode> = root.childs;
                    if (DbvtAabbMm.Proximity(childs[0].volume, leaf.volume) <
						DbvtAabbMm.Proximity(childs[1].volume, leaf.volume))
					{
                        root = childs[0];
                    } 
					else
					{
                        root = childs[1];
                    }
                }
                while (!root.isleaf());
            }
            var prev:DbvtNode = root.parent;
            var node:DbvtNode = createnode(pdbvt, prev, merge(leaf.volume, root.volume, tmpAabbMm), null);
            if (prev != null)
			{
                prev.childs[indexof(root)] = node;
                node.childs[0] = root;
                root.parent = node;
                node.childs[1] = leaf;
                leaf.parent = node;
                do {
                    if (!prev.volume.Contain(node.volume))
					{
                        DbvtAabbMm.Merge(prev.childs[0].volume, prev.childs[1].volume, prev.volume);
                    } 
					else 
					{
                        break;
                    }
                    node = prev;
                }
                while (null != (prev = node.parent));
            } 
			else 
			{
                node.childs[0] = root;
                root.parent = node;
                node.childs[1] = leaf;
                leaf.parent = node;
                pdbvt.root = node;
            }
        }
    }

    private static inline function removeleaf( pdbvt:Dbvt, leaf:DbvtNode):DbvtNode
	{
        if (leaf == pdbvt.root)
		{
            pdbvt.root = null;
            return null;
        } 
		else 
		{
            var parent:DbvtNode = leaf.parent;
            var prev:DbvtNode = parent.parent;
            var sibling:DbvtNode = parent.childs[1 - indexof(leaf)];
            if (prev != null)
			{
                prev.childs[indexof(parent)] = sibling;
                sibling.parent = prev;
                deletenode(pdbvt, parent);
                while (prev != null)
				{
                    var pb:DbvtAabbMm = prev.volume;
                    DbvtAabbMm.Merge(prev.childs[0].volume, prev.childs[1].volume, prev.volume);
                    if (DbvtAabbMm.NotEqual(pb, prev.volume))
					{
                        prev = prev.parent;
                    } 
					else
					{
                        break;
                    }
                }
                return (prev != null ? prev : pdbvt.root);
            } 
			else
			{
                pdbvt.root = sibling;
                sibling.parent = null;
                deletenode(pdbvt, parent);
                return pdbvt.root;
            }
        }
    }

    private static function fetchleaves(pdbvt:Dbvt, root:DbvtNode, leaves:ObjectArrayList<DbvtNode>, depth:Int = -1):Void
	{
        if (root.isinternal() && depth != 0)
		{
            fetchleaves(pdbvt, root.childs[0], leaves, depth - 1);
            fetchleaves(pdbvt, root.childs[1], leaves, depth - 1);
            deletenode(pdbvt, root);
        } 
		else 
		{
            leaves.add(root);
        }
    }

    private static function split(leaves:ObjectArrayList<DbvtNode>, 
								left:ObjectArrayList<DbvtNode>, 
								right:ObjectArrayList<DbvtNode>, 
								org:Vector3f,
								axis:Vector3f):Void
	{
        var tmp:Vector3f = new Vector3f();
        left.resize(0, DbvtNode);
        right.resize(0, DbvtNode);
        for (i in 0...leaves.size())
		{
            leaves.getQuick(i).volume.Center(tmp);
            tmp.sub(org);
            if (axis.dot(tmp) < 0) 
			{
                left.add(leaves.getQuick(i));
            }
			else
			{
                right.add(leaves.getQuick(i));
            }
        }
    }

    private static function bounds(leaves:ObjectArrayList<DbvtNode>):DbvtAabbMm
	{
        var volume:DbvtAabbMm = new DbvtAabbMm();
		volume.set(leaves.getQuick(0).volume);
        for (i in 1...leaves.size()) 
		{
            merge(volume, leaves.getQuick(i).volume, volume);
        }
        return volume;
    }

    private static function bottomup(pdbvt:Dbvt, leaves:ObjectArrayList<DbvtNode>):Void
	{
        while (leaves.size() > 1) 
		{
            var minsize:Float = BulletGlobals.SIMD_INFINITY;
            var minidx:Array<Int> = [-1, -1];
            for (i in 0...leaves.size()) 
			{
                for (j in (i + 1)...leaves.size()) 
				{
                    var sz:Float = size(merge(leaves.getQuick(i).volume, leaves.getQuick(j).volume, tmpAabbMm));
                    if (sz < minsize)
					{
                        minsize = sz;
                        minidx[0] = i;
                        minidx[1] = j;
                    }
                }
            }
            var n:Array<DbvtNode> = [leaves.getQuick(minidx[0]), leaves.getQuick(minidx[1])];
            var p:DbvtNode = createnode(pdbvt, null, merge(n[0].volume, n[1].volume, tmpAabbMm), null);
            p.childs[0] = n[0];
            p.childs[1] = n[1];
            n[0].parent = p;
            n[1].parent = p;
            // JAVA NOTE: check
            leaves.setQuick(minidx[0], p);
            leaves.swap(minidx[1], leaves.size() - 1);
            leaves.removeQuick(leaves.size() - 1);
        }
    }

    private static var axis:Array<Vector3f> = [new Vector3f(1, 0, 0), new Vector3f(0, 1, 0), new Vector3f(0, 0, 1)];

    private static function topdown( pdbvt:Dbvt, leaves:ObjectArrayList<DbvtNode>, bu_treshold:Int):DbvtNode
	{
        if (leaves.size() > 1) 
		{
            if (leaves.size() > bu_treshold)
			{
                var vol:DbvtAabbMm = bounds(leaves);
                var org:Vector3f = vol.Center(new Vector3f());
                var sets:Array<ObjectArrayList<DbvtNode>> = [];
                for (i in 0...sets.length) 
				{
                    sets[i] = new ObjectArrayList<DbvtNode>();
                }
				
                var bestaxis:Int = -1;
                var bestmidp:Int = leaves.size();
                var splitcount:Array<Array<Int>> = [[0, 0], [0, 0], [0, 0]];

                var x:Vector3f = new Vector3f();

                for (i in 0...leaves.size()) 
				{
                    leaves.getQuick(i).volume.Center(x);
                    x.sub(org);
                    for (j in 0...3) 
					{
                        splitcount[j][x.dot(axis[j]) > 0 ? 1 : 0]++;
                    }
                }
                for (i in 0...3)
				{
                    if ((splitcount[i][0] > 0) && (splitcount[i][1] > 0))
					{
                        var midp:Int = FastMath.iabs(splitcount[i][0] - splitcount[i][1]);
                        if (midp < bestmidp)
						{
                            bestaxis = i;
                            bestmidp = midp;
                        }
                    }
                }
                if (bestaxis >= 0)
				{
                    //sets[0].reserve(splitcount[bestaxis][0]);
                    //sets[1].reserve(splitcount[bestaxis][1]);
                    split(leaves, sets[0], sets[1], org, axis[bestaxis]);
                } 
				else
				{
                    //sets[0].reserve(leaves.size()/2+1);
                    //sets[1].reserve(leaves.size()/2);
                    for (i in 0...leaves.size()) 
					{
                        sets[i & 1].add(leaves.getQuick(i));
                    }
                }
                var node:DbvtNode = createnode(pdbvt, null, vol, null);
                node.childs[0] = topdown(pdbvt, sets[0], bu_treshold);
                node.childs[1] = topdown(pdbvt, sets[1], bu_treshold);
                node.childs[0].parent = node;
                node.childs[1].parent = node;
                return node;
            }
			else
			{
                bottomup(pdbvt, leaves);
                return leaves.getQuick(0);
            }
        }
        return leaves.getQuick(0);
    }

    private static function sort(n:DbvtNode, r:Array<DbvtNode>):DbvtNode
	{
        var p:DbvtNode = n.parent;
		
		#if debug
        Assert.assert (n.isinternal());
		#end
		
		//TODO 需要计算hashCode吗，这里判断的意义是什么？
        // JAVA TODO: fix this
        if (p != null) //&& p.hashCode() > n.hashCode())
		{
            var i:Int = indexof(n);
            var j:Int = 1 - i;
            var s:DbvtNode = p.childs[j];
            var q:DbvtNode = p.parent;
            Assert.assert (n == p.childs[i]);
            if (q != null)
			{
                q.childs[indexof(p)] = n;
            } 
			else
			{
                r[0] = n;
            }
            s.parent = n;
            p.parent = n;
            n.parent = q;
            p.childs[0] = n.childs[0];
            p.childs[1] = n.childs[1];
            n.childs[0].parent = p;
            n.childs[1].parent = p;
            n.childs[i] = p;
            n.childs[j] = s;

            DbvtAabbMm.swap(p.volume, n.volume);
            return p;
        }
        return n;
    }

    private static function walkup(n:DbvtNode, count:Int):DbvtNode
	{
        while (n != null && (count--) != 0) 
		{
            n = n.parent;
        }
        return n;
    }
	
}

@:final class DbvtNode
{
	public var volume:DbvtAabbMm = new DbvtAabbMm();
	public var parent:DbvtNode;
	public var childs:Vector<DbvtNode> = new Vector<DbvtNode>(2);
	public var data:Dynamic;
	
	public function new() 
	{
		
	}

	public inline function isleaf():Bool
	{
		return childs[1] == null;
	}

	public inline function isinternal():Bool
	{
		return !isleaf();
	}
}

/**
 * Stack element
 */
@:final class SStkNN 
 {
	public var a:DbvtNode;
	public var b:DbvtNode;

	public function new(na:DbvtNode, nb:DbvtNode)
	{
		a = na;
		b = nb;
	}
}

@:final class SStkNP 
{
	public var node:DbvtNode;
	public var mask:Int;

	public function new(n:DbvtNode, m:Int)
	{
		node = n;
		mask = m;
	}
}

@:final class SStkNPS 
{
	public var node:DbvtNode;
	public var mask:Int;
	public var value:Float;

	public function new( n:DbvtNode, m:Int, v:Float)
	{
		node = n;
		mask = m;
		value = v;
	}

	public inline function set(o:SStkNPS):Void
	{
		node = o.node;
		mask = o.mask;
		value = o.value;
	}
}
	
@:final class SStkCLN 
{
	public var node:DbvtNode;
	public var parent:DbvtNode;

	public function new(n:DbvtNode, p:DbvtNode)
	{
		node = n;
		parent = p;
	}
}

class ICollide
{
	public function new()
	{
		
	}
	
	public function Process2(n1:DbvtNode, n2:DbvtNode):Void
	{
		
	}
	
	public function Process(n:DbvtNode):Void
	{
		
	}
	
	public function Process3(n:DbvtNode, f:Float):Void
	{
		
	}
	
	public function Descent(n:DbvtNode):Bool
	{
		return true;
	}

	public function AllLeaves(n:DbvtNode):Bool
	{
		return true;
	}
}

class IWriter 
{
	public function Prepare(root:DbvtNode, numnodes:Int):Void
	{
		
	}

	public function WriteNode(n:DbvtNode, index:Int, parent:Int, child0:Int, child1:Int):Void
	{
		
	}

	public function WriteLeaf(n:DbvtNode, index:Int, parent:Int):Void
	{
		
	}
}

class IClone
{
	public function CloneLeaf(n:DbvtNode):Void
	{
	}
}