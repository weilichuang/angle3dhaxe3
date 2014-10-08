package com.bulletphysics.collision.broadphase;
import com.bulletphysics.collision.broadphase.Dbvt.Node;
import com.bulletphysics.linearmath.MiscUtil;
import com.bulletphysics.linearmath.Transform;
import com.bulletphysics.util.Assert;
import com.bulletphysics.util.IntArrayList;
import com.bulletphysics.util.ObjectArrayList;
import com.vecmath.FastMath;
import com.vecmath.Vector3f;
import haxe.ds.Vector;

/**
 * ...
 * @author weilichuang
 */
class Dbvt
{
	public static inline var SIMPLE_STACKSIZE:Int = 64;
    public static inline var DOUBLE_STACKSIZE:Int = 128;

    public var root:Node = null;
    public var free:Node = null;
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
            var leaves:ObjectArrayList<Node> = new ObjectArrayList<Node>(this.leaves);
            fetchleaves(this, root, leaves);
            bottomup(this, leaves);
            root = leaves.getQuick(0);
        }
    }

    public function optimizeTopDown(bu_treshold:Int = 128):Void
	{
        if (root != null)
		{
            var leaves:ObjectArrayList<Node> = new ObjectArrayList<Node>(this.leaves);
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
            var root_ref:Array<Node> = [null];
            do {
                var node:Node = root;
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

    public function insert(box:DbvtAabbMm, data:Dynamic):Node
	{
        var leaf:Node = createnode(this, null, box, data);
        insertleaf(this, root, leaf);
        leaves++;
        return leaf;
    }

    public function update(leaf:Node, lookahead:Int = -1):Void
	{
        var root:Node = removeleaf(this, leaf);
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

    public function update2(leaf:Node, volume:DbvtAabbMm):Void
	{
        var root:Node = removeleaf(this, leaf);
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

    public function update3(leaf:Node, volume:DbvtAabbMm, velocity:Vector3f, margin:Float):Bool
	{
        if (leaf.volume.Contain(volume)) 
		{
            return false;
        }
        var tmp:Vector3f = new Vector3f();
        tmp.setTo(margin, margin, margin);
        volume.Expand(tmp);
        volume.SignedExpand(velocity);
        update2(leaf, volume);
        return true;
    }

    public function update4(leaf:Node, volume:DbvtAabbMm, velocity:Vector3f):Bool
	{
        if (leaf.volume.Contain(volume))
		{
            return false;
        }
        volume.SignedExpand(velocity);
        update2(leaf, volume);
        return true;
    }

    public function update5(leaf:Node, volume:DbvtAabbMm, margin:Float):Bool
	{
        if (leaf.volume.Contain(volume))
		{
            return false;
        }
        var tmp:Vector3f = new Vector3f();
        tmp.setTo(margin, margin, margin);
        volume.Expand(tmp);
        update2(leaf, volume);
        return true;
    }

    public function remove(leaf:Node):Void
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

    public static function countLeaves(node:Node):Int
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

    public static function extractLeaves(node:Node, leaves:ObjectArrayList<Node>):Void
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

    public static function enumNodes(root:Node, policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        policy.Process(root);
        if (root.isinternal())
		{
            enumNodes(root.childs[0], policy);
            enumNodes(root.childs[1], policy);
        }
    }

    public static function enumLeaves(root:Node, policy:ICollide):Void
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

    public static function collideTT(root0:Node, root1:Node,  policy:ICollide):Void 
	{
        //DBVT_CHECKTYPE
        if (root0 != null && root1 != null) 
		{
            var stack:ObjectArrayList<SStkNN> = new ObjectArrayList<SStkNN>(DOUBLE_STACKSIZE);
            stack.add(new SStkNN(root0, root1));
            do {
                var p:SStkNN = stack.remove(stack.size() - 1);
                if (p.a == p.b)
				{
                    if (p.a.isinternal())
					{
                        stack.add(new SStkNN(p.a.childs[0], p.a.childs[0]));
                        stack.add(new SStkNN(p.a.childs[1], p.a.childs[1]));
                        stack.add(new SStkNN(p.a.childs[0], p.a.childs[1]));
                    }
                } 
				else if (DbvtAabbMm.Intersect(p.a.volume, p.b.volume)) 
				{
                    if (p.a.isinternal()) 
					{
                        if (p.b.isinternal()) 
						{
                            stack.add(new SStkNN(p.a.childs[0], p.b.childs[0]));
                            stack.add(new SStkNN(p.a.childs[1], p.b.childs[0]));
                            stack.add(new SStkNN(p.a.childs[0], p.b.childs[1]));
                            stack.add(new SStkNN(p.a.childs[1], p.b.childs[1]));
                        }
						else 
						{
                            stack.add(new SStkNN(p.a.childs[0], p.b));
                            stack.add(new SStkNN(p.a.childs[1], p.b));
                        }
                    } 
					else 
					{
                        if (p.b.isinternal())
						{
                            stack.add(new SStkNN(p.a, p.b.childs[0]));
                            stack.add(new SStkNN(p.a, p.b.childs[1]));
                        } 
						else 
						{
                            policy.Process2(p.a, p.b);
                        }
                    }
                }
            }
            while (stack.size() > 0);
        }
    }

    public static function collideTT2(root0:Node, root1:Node, xform:Transform, policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root0 != null && root1 != null) 
		{
            var stack:ObjectArrayList<SStkNN> = new ObjectArrayList<SStkNN>(DOUBLE_STACKSIZE);
            stack.add(new SStkNN(root0, root1));
            do {
                var p:SStkNN = stack.remove(stack.size() - 1);
                if (p.a == p.b) 
				{
                    if (p.a.isinternal())
					{
                        stack.add(new SStkNN(p.a.childs[0], p.a.childs[0]));
                        stack.add(new SStkNN(p.a.childs[1], p.a.childs[1]));
                        stack.add(new SStkNN(p.a.childs[0], p.a.childs[1]));
                    }
                } 
				else if (DbvtAabbMm.Intersect2(p.a.volume, p.b.volume, xform))
				{
                    if (p.a.isinternal())
					{
                        if (p.b.isinternal())
						{
                            stack.add(new SStkNN(p.a.childs[0], p.b.childs[0]));
                            stack.add(new SStkNN(p.a.childs[1], p.b.childs[0]));
                            stack.add(new SStkNN(p.a.childs[0], p.b.childs[1]));
                            stack.add(new SStkNN(p.a.childs[1], p.b.childs[1]));
                        } 
						else 
						{
                            stack.add(new SStkNN(p.a.childs[0], p.b));
                            stack.add(new SStkNN(p.a.childs[1], p.b));
                        }
                    }
					else 
					{
                        if (p.b.isinternal())
						{
                            stack.add(new SStkNN(p.a, p.b.childs[0]));
                            stack.add(new SStkNN(p.a, p.b.childs[1]));
                        } 
						else
						{
                            policy.Process2(p.a, p.b);
                        }
                    }
                }
            }
            while (stack.size() > 0);
        }
    }

    public static function collideTT3(root0:Node, xform0:Transform, root1:Node, xform1:Transform, policy:ICollide):Void
	{
        var xform:Transform = new Transform();
        xform.inverse(xform0);
        xform.mul(xform1);
        collideTT2(root0, root1, xform, policy);
    }

    public static function collideTV(root:Node, volume:DbvtAabbMm, policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root != null)
		{
            var stack:ObjectArrayList<Node> = new ObjectArrayList<Node>(SIMPLE_STACKSIZE);
            stack.add(root);
            do {
                var n:Node = stack.remove(stack.size() - 1);
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

    public static function collideRAY(root:Node, origin:Vector3f, direction:Vector3f, policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root != null) 
		{
            var normal:Vector3f = new Vector3f();
            normal.normalize(direction);
            var invdir:Vector3f = new Vector3f();
            invdir.setTo(1 / normal.x, 1 / normal.y, 1 / normal.z);
            var signs:Array<Int> = [direction.x < 0 ? 1 : 0, direction.y < 0 ? 1 : 0, direction.z < 0 ? 1 : 0];
            var stack:ObjectArrayList<Node> = new ObjectArrayList<Node>(SIMPLE_STACKSIZE);
            stack.add(root);
            do {
                var node:Node = stack.remove(stack.size() - 1);
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

    public static function collideKDOP(root:Node, normals:Array<Vector3f>, offsets:Array<Float>, count:Int,  policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root != null) 
		{
            var inside:Int = (1 << count) - 1;
            var stack:ObjectArrayList<SStkNP> = new ObjectArrayList<SStkNP>(SIMPLE_STACKSIZE);
            var signs:Vector<Int> = new Vector<Int>(4 * 8);
            Assert.assert (count < (/*sizeof(signs)*/128 / /*sizeof(signs[0])*/ 4));
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

    public static function collideOCL(root:Node, normals:Array<Vector3f>, offsets:Array<Float>, sortaxis:Vector3f, count:Int, policy:ICollide, fullsort:Bool = true):Void
	{
        //DBVT_CHECKTYPE
        if (root != null)
		{
            var srtsgns:Int = (sortaxis.x >= 0 ? 1 : 0) +
                    (sortaxis.y >= 0 ? 2 : 0) +
                    (sortaxis.z >= 0 ? 4 : 0);
            var inside:Int = (1 << count) - 1;
            var stock:ObjectArrayList<SStkNPS> = new ObjectArrayList<SStkNPS>();
            var ifree:IntArrayList = new IntArrayList();
            var stack:IntArrayList = new IntArrayList();
            var signs:Vector<Int> = new Vector<Int>(4 * 8);
            Assert.assert (count < (/*sizeof(signs)*/128 / /*sizeof(signs[0])*/ 4));
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
                        var pns:Array<Node> = [se.node.childs[0], se.node.childs[1]];
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

    public static function collideTU( root:Node,  policy:ICollide):Void
	{
        //DBVT_CHECKTYPE
        if (root != null) 
		{
            var stack:ObjectArrayList<Node> = new ObjectArrayList<Node>(SIMPLE_STACKSIZE);
            stack.add(root);
            do {
                var n:Node = stack.remove(stack.size() - 1);
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
        return (i);
    }

    ////////////////////////////////////////////////////////////////////////////

    private static function indexof(node:Node):Int
	{
        return (node.parent.childs[1] == node) ? 1 : 0;
    }

    private static function merge(a:DbvtAabbMm, b:DbvtAabbMm, out:DbvtAabbMm):DbvtAabbMm
	{
        DbvtAabbMm.Merge(a, b, out);
        return out;
    }

    // volume+edge lengths
    private static function size(a:DbvtAabbMm):Float
	{
        var edges:Vector3f = a.Lengths(new Vector3f());
        return (edges.x * edges.y * edges.z +
                edges.x + edges.y + edges.z);
    }

    private static function deletenode(pdbvt:Dbvt, node:Node):Void
	{
        //btAlignedFree(pdbvt->m_free);
        pdbvt.free = node;
    }

    private static function recursedeletenode(pdbvt:Dbvt, node:Node):Void
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

    private static function createnode(pdbvt:Dbvt, parent:Node, volume:DbvtAabbMm, data:Dynamic):Node
	{
        var node:Node;
        if (pdbvt.free != null)
		{
            node = pdbvt.free;
            pdbvt.free = null;
        } 
		else 
		{
            node = new Node();
        }
        node.parent = parent;
        node.volume.set(volume);
        node.data = data;
        node.childs[1] = null;
        return node;
    }

    private static function insertleaf(pdbvt:Dbvt, root:Node, leaf:Node):Void
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
                    if (DbvtAabbMm.Proximity(root.childs[0].volume, leaf.volume) <
                            DbvtAabbMm.Proximity(root.childs[1].volume, leaf.volume))
					{
                        root = root.childs[0];
                    } 
					else
					{
                        root = root.childs[1];
                    }
                }
                while (!root.isleaf());
            }
            var prev:Node = root.parent;
            var node:Node = createnode(pdbvt, prev, merge(leaf.volume, root.volume, new DbvtAabbMm()), null);
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

    private static function removeleaf( pdbvt:Dbvt, leaf:Node):Node
	{
        if (leaf == pdbvt.root)
		{
            pdbvt.root = null;
            return null;
        } 
		else 
		{
            var parent:Node = leaf.parent;
            var prev:Node = parent.parent;
            var sibling:Node = parent.childs[1 - indexof(leaf)];
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

    private static function fetchleaves(pdbvt:Dbvt, root:Node, leaves:ObjectArrayList<Node>, depth:Int = -1):Void
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

    private static function split(leaves:ObjectArrayList<Node>, 
								left:ObjectArrayList<Node>, 
								right:ObjectArrayList<Node>, 
								org:Vector3f,
								axis:Vector3f):Void
	{
        var tmp:Vector3f = new Vector3f();
        left.resize(0, Node);
        right.resize(0, Node);
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

    private static function bounds(leaves:ObjectArrayList<Node>):DbvtAabbMm
	{
        var volume:DbvtAabbMm = new DbvtAabbMm(leaves.getQuick(0).volume);
        for (i in 1...leaves.size()) 
		{
            merge(volume, leaves.getQuick(i).volume, volume);
        }
        return volume;
    }

    private static function bottomup(pdbvt:Dbvt, leaves:ObjectArrayList<Node>):Void
	{
        var tmpVolume:DbvtAabbMm = new DbvtAabbMm();
        while (leaves.size() > 1) 
		{
            var minsize:Float = BulletGlobals.SIMD_INFINITY;
            var minidx:Array<Int> = [-1, -1];
            for (i in 0...leaves.size()) 
			{
                for (j in (i + 1)...leaves.size()) 
				{
                    var sz:Float = size(merge(leaves.getQuick(i).volume, leaves.getQuick(j).volume, tmpVolume));
                    if (sz < minsize)
					{
                        minsize = sz;
                        minidx[0] = i;
                        minidx[1] = j;
                    }
                }
            }
            var n:Array<Node> = [leaves.getQuick(minidx[0]), leaves.getQuick(minidx[1])];
            var p:Node = createnode(pdbvt, null, merge(n[0].volume, n[1].volume, new DbvtAabbMm()), null);
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

    private static function topdown( pdbvt:Dbvt, leaves:ObjectArrayList<Node>, bu_treshold:Int):Node
	{
        if (leaves.size() > 1) 
		{
            if (leaves.size() > bu_treshold)
			{
                var vol:DbvtAabbMm = bounds(leaves);
                var org:Vector3f = vol.Center(new Vector3f());
                var sets:Array<ObjectArrayList<Node>> = [];
                for (i in 0...sets.length) 
				{
                    sets[i] = new ObjectArrayList<Node>();
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
                var node:Node = createnode(pdbvt, null, vol, null);
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

    private static function sort(n:Node, r:Array<Node>):Node
	{
        var p:Node = n.parent;
        Assert.assert (n.isinternal());
		//TODO 需要计算hashCode吗，这里判断的意义是什么？
        // JAVA TODO: fix this
        if (p != null) //&& p.hashCode() > n.hashCode())
		{
            var i:Int = indexof(n);
            var j:Int = 1 - i;
            var s:Node = p.childs[j];
            var q:Node = p.parent;
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

    private static function walkup(n:Node, count:Int):Node
	{
        while (n != null && (count--) != 0) 
		{
            n = n.parent;
        }
        return n;
    }
	
}

class Node
{
	public var volume:DbvtAabbMm = new DbvtAabbMm();
	public var parent:Node;
	public var childs:Vector<Node> = new Vector<Node>(2);
	public var data:Dynamic;
	
	public function new() 
	{
		
	}

	public function isleaf():Bool
	{
		return childs[1] == null;
	}

	public function isinternal():Bool
	{
		return !isleaf();
	}
}

/**
 * Stack element
 */
 class SStkNN 
 {
	public var a:Node;
	public var b:Node;

	public function new(na:Node, nb:Node)
	{
		a = na;
		b = nb;
	}
}

class SStkNP 
{
	public var node:Node;
	public var mask:Int;

	public function new(n:Node, m:Int)
	{
		node = n;
		mask = m;
	}
}

class SStkNPS 
{
	public var node:Node;
	public var mask:Int;
	public var value:Float;

	public function new( n:Node, m:Int, v:Float)
	{
		node = n;
		mask = m;
		value = v;
	}

	public function set(o:SStkNPS):Void
	{
		node = o.node;
		mask = o.mask;
		value = o.value;
	}
}
	
class SStkCLN 
{
	public var node:Node;
	public var parent:Node;

	public function new(n:Node, p:Node)
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
	
	public function Process2(n1:Node, n2:Node):Void
	{
		
	}
	
	public function Process(n:Node):Void
	{
		
	}
	
	public function Process3(n:Node, f:Float):Void
	{
		
	}
	
	public function Descent(n:Node):Bool
	{
		return true;
	}

	public function AllLeaves(n:Node):Bool
	{
		return true;
	}
}

class IWriter 
{
	public function Prepare(root:Node, numnodes:Int):Void
	{
		
	}

	public function WriteNode(n:Node, index:Int, parent:Int, child0:Int, child1:Int):Void
	{
		
	}

	public function WriteLeaf(n:Node, index:Int, parent:Int):Void
	{
		
	}
}

class IClone
{
	public function CloneLeaf(n:Node):Void
	{
	}
}