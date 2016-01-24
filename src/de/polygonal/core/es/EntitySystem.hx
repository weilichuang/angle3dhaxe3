/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.es;

import de.polygonal.core.util.Assert.assert;
import de.polygonal.ds.IntIntHashTable;
import haxe.ds.StringMap;
import haxe.ds.Vector;

import de.polygonal.core.es.Entity in E;

/**
	Manages all active entities
**/
@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntityMessageQue)
class EntitySystem
{
	/**
		The total number of entities that this system supports.
	**/
	inline public static var MAX_SUPPORTED_ENTITIES = 0xFFFE;
	
	/**
		Maximum capacity of the message queue.
		
		By default, a total of 32768 messages can be handled per game tick.
		This requires up to 896 KiB of memory (576 KiB if alchemy is used).
	**/
	inline public static var DEFAULT_MAX_MESSAGE_COUNT = 0x8000;
	
	/**
		The total number of supported entities.
		
		Default is 0x8000.
	**/
	inline public static var DEFAULT_MAX_ENTITY_COUNT = 0x8000;
	
	inline static var OFFSET_PREORDER = 0;
	inline static var OFFSET_PARENT = 1;
	inline static var OFFSET_FIRST_CHILD = 2;
	inline static var OFFSET_LAST_CHILD = 3;
	inline static var OFFSET_SIBLING = 4;
	inline static var OFFSET_SIZE = 5;
	inline static var OFFSET_DEPTH = 6;
	inline static var OFFSET_NUM_CHILDREN = 7;
	
	//unique id, incremented every time an entity is registered
	static var mNextInnerId:Int;
	
	//all existing entities
	static var mFreeList:Vector<E>;
	
	#if alchemy
	static var mNext:de.polygonal.ds.mem.ShortMemory;
	#else
	static var mNext:Vector<Int>;
	#end
	
	static var mFree:Int;
	
	//indices [0,3]: parent, child, sibling, last child (indices into the free list)
	//indices [4,6]: size (#descendants), tree depth, #children
	//index 7 is unused
	#if alchemy
	static var mTree:de.polygonal.ds.mem.ShortMemory;
	#else
	static var mTree:Vector<Int>;
	#end
	
	//name => [entities by name]
	static var mEntitiesByName:StringMap<E> = null;
	
	//circular message buffer
	static var mMsgQue:EntityMessageQue;
	
	//maps class x to all superclasses of x
	static var mInheritanceLut:IntIntHashTable;
	
	/**
		Initializes the entity system.
		
		@param maxEntityCount the total number of supported entities.
		@param maxMessageCount the total capacity of the message queue.
	**/
	public static function init(maxEntityCount:Int = DEFAULT_MAX_ENTITY_COUNT, maxMessageCount:Int = DEFAULT_MAX_MESSAGE_COUNT)
	{
		if (mFreeList != null) return;
		
		mNextInnerId = 0;
		
		assert(maxEntityCount > 0 && maxEntityCount <= MAX_SUPPORTED_ENTITIES);
		
		mFreeList = new Vector<E>(1 + maxEntityCount); //index 0 is reserved for null
		
		#if alchemy
		mTree = new de.polygonal.ds.mem.ShortMemory((1 + maxEntityCount) << 3, "topology");
		#else
		mTree = new Vector<Int>((1 + maxEntityCount) << 3);
		for (i in 0...mTree.length) mTree[i] = 0;
		#end
		
		mEntitiesByName = new StringMap<E>();
		
		//first element is stored at index=1 (0 is reserved for NULL)
		#if alchemy
		mNext = new de.polygonal.ds.mem.ShortMemory(1 + maxEntityCount, "es_freelist_shorts");
		for (i in 1...maxEntityCount)
			mNext.set(i, i + 1);
		mNext.set(maxEntityCount, -1);
		#else
		mNext = new Vector<Int>(1 + maxEntityCount);
		for (i in 1...maxEntityCount)
			mNext[i] = (i + 1);
		mNext[maxEntityCount] = -1;
		#end
		
		mFree = 1;
		
		mMsgQue = new EntityMessageQue(maxMessageCount);
		
		mInheritanceLut = new IntIntHashTable(1024);
		
		#if verbose
			//topology array
			var bytesUsed = 0;
			#if alchemy
			bytesUsed += mTree.size * 2;
			bytesUsed += mNext.size * 2;
			bytesUsed += mMsgQue.mQue.size;
			#else
			bytesUsed += mTree.length * 4;
			bytesUsed += mNext.length * 4;
			bytesUsed += mMsgQue.mQue.length * 4;
			#end
			
			bytesUsed += mFreeList.length * 4;
			
			L.d('using ${bytesUsed >> 10} KiB for managing $maxEntityCount entities and ${maxMessageCount} messages.', "es");
		#end
	}
	
	/**
		Disposes the system by explicitly nullifying all references for GC'ing used resources.
		
		This nullifies all `EntityId` objects but does not include calling the free() method on all registered entities.
	**/
	public static function free()
	{
		for (i in 0...mFreeList.length)
		{
			if (mFreeList[i] != null)
			{
				mFreeList[i].id = null;
				mFreeList[i].preorder = null;
			}
		}
		
		mFreeList = null;
		
		#if alchemy
		mTree.free();
		mNext.free();
		#end
		
		mTree = null;
		mEntitiesByName = null;
		mNext = null;
		mNextInnerId = 0;
		mInheritanceLut.free();
		mInheritanceLut = null;
	}
	
	/**
		Dispatches all queued messages.
	**/
	inline public static function dispatchMessages() mMsgQue.dispatch();
	
	/**
		Returns the entity that matches the given `name` or null if such an entity does not exist.
	**/
	inline public static function findByName<T:Entity>(name:String):T
	{
		return cast mEntitiesByName.get(name);
	}
	
	/**
		Returns the entity whose name is set to `clss`::ENTITY_NAME or null if such an entity does not exist.
	**/
	inline public static function lookup<T:Entity>(clss:Class<T>):T
	{
		var name =
		#if flash
		untyped clss.ENTITY_NAME;
		#elseif js
		untyped __js__('clss["ENTITY_NAME"]');
		#else
		Reflect.field(clss, "ENTITY_NAME");
		#end
		return cast mEntitiesByName.get(name);
	}
	
	/**
		Returns the entity that matches the given `id` or null if such an entity does not exist.
	**/
	inline public static function findById(id:EntityId):E
	{
		if (id.index > 0)
		{
			var e = mFreeList[id.index];
			if (e != null)
				return (e.id.inner == id.inner) ? e : null;
			else
				return null;
		}
		else
			return null;
	}
	
	/**
		Pretty-prints the entity hierarchy starting at `root`.
	**/
	public static function prettyPrint(root:Entity):String
	{
		if (root == null) return root.toString();
		
		function depth(x:Entity):Int
		{
			if (x.parent == null) return 0;
			var e = x;
			var c = 0;
			while (e.parent != null)
			{
				c++;
				e = e.parent;
			}
			return c;
		}	
		
		var s = root.name + '\n';
		
		var a = [root];
		
		var e = root.preorder;
		while (e != null)
		{
			a.push(e);
			
			e = e.preorder;
		}
		
		for (e in a)
		{
			var d = depth(e);
			for (i in 0...d)
			{
				if (i == d - 1)
					s += "+--- ";
				else
					s += "|    ";
			}
			s += "" + e.name + "\n";
		}
		
		return s;
	}
	
	static function register(e:E, isGlobal:Bool)
	{
		if (mFreeList == null) init();
		
		assert(e.id == null, "Entity has already been registered");
		
		var i = mFree;
		
		assert(i != -1);
		
		#if alchemy
		mFree = mNext.get(i);
		#else
		mFree = mNext[i];
		#end
		
		mFreeList[i] = e;
		
		var id = new EntityId();
		id.inner = mNextInnerId++;
		id.index = i;
		e.id = id;
		
		if (isGlobal)
		{
			assert(e.name != null);
			registerName(e);
		}
		
		var lut = mInheritanceLut;
		if (!lut.hasKey(e.type))
		{
			var t = e.type;
			lut.set(t, t);
			
			var sc:Class<E> = Reflect.field(Type.getClass(e), "SUPER_CLASS");
			while (sc != null)
			{
				mInheritanceLut.set(t, E.getEntityType(sc));
				sc = Reflect.field(sc, "SUPER_CLASS");
			}
		}
	}
	
	static function unregister(e:E)
	{
		assert(e.id != null);
		
		#if (verbose == "extra")
		L.d('$e is gone', "es");
		#end
		
		var i = e.id.index;
		
		//nullify for gc
		mFreeList[i] = null;
		
		var pos = i << 3;
		
		#if alchemy
		for (i in 0...8) mTree.set(pos + i, 0);
		#else
		for (i in 0...8) mTree[pos + i] = 0;
		#end
		
		//mark as free
		#if alchemy
		mNext.set(i, mFree);
		#else
		mNext[i] = mFree;
		#end
		mFree = i;
		
		//don't forget to nullify preorder pointer
		e.preorder = null;
		
		//remove from name => entity mapping
		if (e.mBits & E.BIT_IS_GLOBAL > 0)
		{
			mEntitiesByName.remove(e.name);
			e.mBits &= ~E.BIT_IS_GLOBAL;
		}
		
		//mark as removed by setting msb to one
		e.id.inner |= 0x80000000;
		e.id = null;
	}
	
	static function freeEntityTree(e:E)
	{
		#if verbose
		var c = getSize(e) + 1;
		if (c > 1)
			L.d('freeing up $c entities ...', "es");
		else
			L.d('freeing up one entity ...', "es");
		#end
		
		if (getSize(e) < 512)
			freeRecursive(e); //postorder traversal
		else
			freeIterative(e); //inverse levelorder traversal
	}
	
	inline public static function getPreorder(e:E):E return mFreeList[get(pos(e, OFFSET_PREORDER))];
	inline static function setPreorder(e:E, value:E) set(pos(e, OFFSET_PREORDER), value == null ? 0 : value.id.index);
	
	inline public static function getParent(e:E):E return mFreeList[get(pos(e, OFFSET_PARENT))];
	inline static function setParent(e:E, value:E) set(pos(e, OFFSET_PARENT), value == null ? 0 : value.id.index);
	
	inline public static function getFirstChild(e:E):E return mFreeList[get(pos(e, OFFSET_FIRST_CHILD))];
	inline static function setFirstChild(e:E, value:E) set(pos(e, OFFSET_FIRST_CHILD), value == null ? 0 : value.id.index);
	
	inline public static function getLastChild(e:E):E return mFreeList[get(pos(e, OFFSET_LAST_CHILD))];
	inline static function setLastChild(e:E, value:E) set(pos(e, OFFSET_LAST_CHILD), value == null ? 0 : value.id.index);
	
	inline public static function getSibling(e:E):E return mFreeList[get(pos(e, OFFSET_SIBLING))];
	inline static function setSibling(e:E, value:E) set(pos(e, OFFSET_SIBLING), value == null ? 0 : value.id.index);
	
	inline public static function getSize(e:E):Int return get(pos(e, OFFSET_SIZE));
	inline static function setSize(e:E, value:Int) set(pos(e, OFFSET_SIZE), value);
	
	inline public static function getDepth(e:E):Int return get(pos(e, OFFSET_DEPTH));
	inline static function setDepth(e:E, value:Int) set(pos(e, OFFSET_DEPTH), value);
	
	inline public static function getNumChildren(e:E):Int return get(pos(e, OFFSET_NUM_CHILDREN));
	inline static function setNumChildren(e:E, value:Int) set(pos(e, OFFSET_NUM_CHILDREN), value);
	
	inline static function get(i:Int):Int
	{
		return
		#if alchemy
		mTree.get(i);
		#else
		mTree[i];
		#end
	}
	
	inline static function set(i:Int, value:Int)
	{
		#if alchemy
		mTree.set(i, value);
		#else
		mTree[i] = value;
		#end
	}
	
	inline static function pos(e:E, shift:Int):Int return (e.id.index << 3) + shift;
   	
	static function freeRecursive(e:E)
	{
		var n = e.firstChild;
		while (n != null)
		{
			var sibling = n.sibling;
			freeRecursive(n);
			n = sibling;
		}
		
		e.mBits |= E.BIT_MARK_FREE;
		
		#if verbose
		L.d('free ${e.name}');
		#end
		
		e.onFree();
		unregister(e);
	}
	
	static function freeIterative(e:E)
	{
		var k = getSize(e) + 1;
		var a = new Vector<E>(k);
		for (i in 0...k) a[i] = null;
		
		var q = [e];
		var i = 0;
		var s = 1;
		var j, c;
		while (i < s)
		{
			j = q[i++];
			a[--k] = j; //add in reverse order
			c = j.firstChild;
			while (c != null)
			{
				q[s++] = c;
				c = c.sibling;
			}
		}
		
		for (e in a)
		{
			e.mBits |= E.BIT_MARK_FREE;
			
			#if verbose
			L.d('free ${e.name}');
			#end
			
			e.onFree();
			unregister(e);
		}
	}
	
	static function registerName(e:E)
	{
		assert(e.id != null, "Entity is not registered, call EntitySystem.register() before");
		
		if (mEntitiesByName.exists(e.name))
			throw '${e.name} already registered to ${mEntitiesByName.get(e.name)}';
		
		mEntitiesByName.set(e.name, e);
		e.mBits |= E.BIT_IS_GLOBAL;
		
		#if verbose
		L.d('registered entity by name: ${e.name} => $e', "es");
		#end
	}
	
	inline public static function findLastLeaf(e:Entity):Entity
	{
		//find bottom-most, right-most entity in the subtree e
		while (e.firstChild != null) e = getLastChild(e);
		
		return e;
	}
	
	inline public static function nextSubtree(e:Entity):Entity
	{
		var t = e.sibling;
		
		return t != null ? t : findLastLeaf(e).preorder;
	}
}