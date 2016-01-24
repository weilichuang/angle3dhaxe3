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

import de.polygonal.core.math.Mathematics.M;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.ds.BucketList;
import de.polygonal.ds.IntIntHashTable;
import haxe.ds.IntMap;

/**
	An entity that can take the part of a subject in the observer pattern
	
	Observers are updated by sending messages to them.
**/
@:access(de.polygonal.core.es.EntitySystem)
@:access(de.polygonal.core.es.EntityId)
@:access(de.polygonal.core.es.MsgQue)
class ObservableEntity extends Entity
{
	var mBuckets:BucketList<EntityId>;
	var mStatus:IntIntHashTable;
	var mTmpArray:Array<EntityId>;
	
	#if debug
	var mObservers2:Array<Array<EntityId>>;
	var mAttachStatus2:AS;
	#end
	
	public function new(name:String = null, isGlobal:Bool = false, bucketSize = 4, shrink = true)
	{
		super(name, isGlobal);
		
		var k = Msg.totalMessages() + 1; //use zero index to store observers attached to all types
		mBuckets = new BucketList<EntityId>(M.max(k, 2), bucketSize, shrink);
		
		mStatus = new IntIntHashTable(1024, k * 100);
		
		#if debug
		mObservers2 = [for (i in 0...k) []];
		mAttachStatus2 = new AS();
		#end
		
		mTmpArray = [];
		
		super(name);
	}
	
	override public function free()
	{
		super.free();
		
		mBuckets.free();
		mStatus.free();
		
		mStatus = null;
		mBuckets = null;
		mTmpArray = null;
	}
	
	public function clear()
	{
		mBuckets.clear();
		mStatus.clear(true);
		
		#if debug
		var k = Msg.totalMessages() + 1;
		mObservers2 = [for (i in 0...k) []];
		mAttachStatus2 = new AS();
		#end
	}
	
	public function attach(e:Entity, ?msgTypes:Array<Int>, msgType:Int = -1):Bool
	{
		assert(msgType < Msg.totalMessages());
		
		var id = e.id;
		
		if (id == null) return false; //entity freed?
		
		assert(id.inner >= 0);
		
		if (msgTypes != null)
		{
			var success = true;
			for (i in msgTypes)
				success = success && attach(e, null, i);
			return success;
		}
		
		//an entity can be stored in the global list or the local list, but not in both at the same time.
		var has1 = mStatus.hasKey(id.inner);
		
		#if debug
		var has2 = mAttachStatus2.hasKey(id.inner);
		assert(has1 == has2);
		#end
		
		if (has1) //entity attached?
		{
			var isUnfiltered = mStatus.hasPair(id.inner, -1);
			
			#if debug
			//var isGlobal2 = mAttachStatus2.get(id) == -1;
			//assert(isUnfiltered == isGlobal2);
			#end
			
			if (isUnfiltered) //entity stored in global list?
			{
				if (msgType == -1)
					return false; //no change
				else
				{
					//move from unfiltered to filtered list
					var success1 = mBuckets.removeAt(0, id);
					assert(success1);
					
					#if debug
					var success2 = mObservers2[0].remove(id);
					assert(success1 == success2);
					#end
					
					mBuckets.add(msgType + 1, id);
					
					#if debug
					mObservers2[msgType + 1].push(id);
					#end
					
					var success1 = mStatus.clrPair(id.inner, -1);
					
					#if debug
					var success2 = mAttachStatus2.clrPair(id.inner, -1);
					assert(success1 == success2);
					#end
					
					var success1 = mStatus.set(id.inner, msgType);
					
					#if debug
					var success2 = mAttachStatus2.set(id.inner, msgType);
					assert(success1 == success2);
					#end
					
					return true;
				}
			}
			else
			{
				//attached to filtered list
				if (msgType == -1) //filtered list -> global list?
				{
					var success1 = false;
					
					//shift from local list(s) -> global list
					for (i in 1...mBuckets.numBuckets)
					{
						var removed = mBuckets.removeAt(i, id);
						if (removed) success1 = true;
					}
					
					while (mStatus.clr(id.inner)) {}
					
					assert(success1);
					
					#if debug
					mAttachStatus2.clrAll(id.inner);
					#end
					
					
					#if debug
					var success2 = false;
					for (i in mObservers2)
					{
						var removed = i.remove(id);
						if (removed) success2 = true;
					}
					assert(success2);
					assert(success1 == success2);
					
					assert(!mBuckets.exists(0, id));
					assert(!arrayHas(mObservers2[0], id));
					
					#end
					
					mBuckets.add(0, id);
					
					#if debug
					mObservers2[0].push(id);
					#end
					
					var success1 = mStatus.set(id.inner, -1);
					assert(success1);
					
					#if debug
					var success2 = mAttachStatus2.set(id.inner, -1);
					assert(success1 == success2);
					#end
					
					return true;
				}
				else
				{
					//must exist
					var exists1 = mBuckets.exists(msgType + 1, id);
					#if debug
					var exists2 = arrayHas(mObservers2[msgType + 1], id);
					assert(exists1 == exists2);
					#end
					
					if (exists1) //no change
					{
						L.e('$e already attached to ' + Msg.name(msgType));
						return false;
					}
					
					//add to another filtered list
					
					mBuckets.add(msgType + 1, id);
					var success1 = mStatus.set(id.inner, msgType);
					
					#if debug
					mObservers2[msgType + 1].push(id);
					var success2 = mAttachStatus2.set(id.inner, msgType);
					assert(success1 == success2);
					assert(success1 == false);
					assert(success2 == false);
					#end
				}
			}
		}
		else
		{
			//added for the first time
			assert(!mStatus.hasKey(id.inner)); //id must not have a status yet
			assert(!mBuckets.contains(id)); //id must not be contained in bucket list
			
			mBuckets.add(msgType + 1, id);
			var success1 = mStatus.set(id.inner, msgType);
			assert(success1);
			
			#if debug
			mObservers2[msgType + 1].push(id);
			var success2 = mAttachStatus2.set(id.inner, msgType);
			assert(success2);
			assert(success1 == success2);
			#end
		}
		
		return true;
	}
	
	public function detach(e:Entity, msgType:Int = -1, ?msgTypes:Array<Int>):Bool
	{
		var id = e.id;
		
		if (id == null) return false;
		
		assert(id.inner >= 0);
		
		if (msgTypes != null)
		{
			var success = true;
			
			for (i in msgTypes)
			{
				assert(i != -1);
				success = success && detach(e, i);
			}
		}
		
		//check if e is attached
		
		var has1 = mStatus.hasKey(id.inner);
		
		#if debug
		var has2 = mAttachStatus2.hasKey(id.inner);
		assert(has1 == has2);
		#end
		
		if (!has1) return false;
		
		if (mStatus.hasPair(id.inner, -1)) //stored in global list?
		{
			//either in global or local list so it's sufficient to remove from global list only
			
			var success1 = mBuckets.removeAt(0, id);
			assert(success1);
			
			#if debug
			var success2 = mObservers2[0].remove(id);
			assert(success2);
			assert(success1 == success2);
			#end
			
			var success1 = mStatus.clr(id.inner);
			assert(success1);
			
			#if debug
			var success2 = mAttachStatus2.clrPair(id.inner, -1);
			assert(success2);
			assert(success1 == success2);
			
			assert(!mStatus.hasKey(id.inner));
			assert(!mAttachStatus2.hasKey(id.inner));
			#end
			
			return true;
		}
		else
		{
			//must be in local list
			if (msgType == -1)
			{
				//remove from all local lists
				var removed = false;
				
				var t = mStatus.get(id.inner);
				while (t != IntIntHashTable.KEY_ABSENT)
				{
					var success = mStatus.clr(id.inner);
					assert(success);
					
					var success = mBuckets.removeAt(t + 1, id);
					if (success) removed = true;
					
					t = mStatus.get(id.inner);
				}
				assert(removed);
				
				#if debug
				removed = false;
				for (i in 1...mObservers2.length)
				{
					var success = mObservers2[i].remove(id);
					if (success) removed = true;
				}
				assert(removed);
				#end
				
				//TODO already cleared above!
				//while (mStatus.clr(id.inner)) {}
				assert(!mStatus.hasKey(id.inner));
				
				#if debug
				mAttachStatus2.clrAll(id.inner);
				#end
			}
			else
			{
				var success1 = mBuckets.removeAt(msgType + 1, id);
				
				var detachOk = success1;
				
				#if debug
				var success2 = mObservers2[msgType + 1].remove(id);
				assert(success1 == success2);
				#end
				
				var success1 = mStatus.clrPair(id.inner, msgType);
				
				#if debug
				var success2 = mAttachStatus2.clrPair(id.inner, msgType);
				assert(success1 == success2);
				#end
				
				return detachOk;
			}
			
			return true;
		}
	}
	
	public function dispatch(msgType:Int, dispatch = false)
	{
		var a = mTmpArray;
		var q = Entity.getMsgQue();
		var entities = Es.mFreeList;
		var id:EntityId;
		
		var k = 0;
		k += mBuckets.getBucketData(msgType + 1, a, 0);
		k += mBuckets.getBucketData(0, a, k);
		
		#if debug
		var list1B = mObservers2[msgType + 1];
		var list2B = mObservers2[0];
		var list = list1B.concat(list2B);
		var t = [];
		for (i in 0...k)t[i] = a[i];
		assert(cmpArr(list, t));
		#end
		
		//remove freed/stalled entities
		var i = k;
		while (i-- > 0)
		{
			id = a[i];
			if (id.inner < 0 || id.inner != entities[id.index].id.inner)
			{
				L.e("removed invalid from global");
				removeAll(id);
				k--;
			}
		}
		
		//enqueue messages
		i = k;
		while (i-- > 0) q.enqueue(this, entities[a[i].index], msgType, --k, 0);
		
		if (dispatch) EntitySystem.dispatchMessages();
	}
	
	function removeAll(id:EntityId)
	{
		while (mStatus.clr(id.inner)) {}
		
		assert(!mStatus.hasKey(id.inner));
		
		var removed = false;
		for (i in 0...mBuckets.numBuckets)
		{
			var success = mBuckets.removeAt(i, id);
			if (success) removed = true;
		}
		assert(removed);
		
		//for testing
		#if debug
		mAttachStatus2.clrAll(id.inner);
		
		var removed = false;
		for (i in 0...mObservers2.length)
		{
			var success = mObservers2[i].remove(id);
			if (success) removed = true;
		}
		assert(removed);
		#end
	}
	
	#if debug
	function cmpArr(a:Array<EntityId>, b:Array<EntityId>)
	{
		assert(a.length == b.length);
		
		for (i in 0...a.length)
		{
			if (a[i] != b[i]) return false;
		}
		
		return true;
	}
	
	function arrayHas(a:Array<EntityId>, v:EntityId)
	{
		for (i in a)
		{
			if (i == v) return true;
		}
		return false;
	}
	#end
}

#if debug
class AS
{
	var m:IntMap<Array<Int>>;
	
	public function new()
	{
		m = new IntMap<Array<Int>>();
	}
	
	public function set(inner:Int, msgType:Int):Bool
	{
		var first = false;
		if (m.get(inner) == null)
		{
			m.set(inner, []);
			first = true;
		}
		
		var a = m.get(inner);
		for (i in a)
		{
			if (i == msgType)
				throw 'dup!';
		}
		a.push(msgType);
		
		return first;
	}
	
	public function hasKey(inner:Int):Bool
	{
		return m.get(inner) != null;
	}
	
	public function hasPair(inner:Int, type:Int):Bool
	{
		var a = m.get(inner);
		if (a == null) return false;
		
		for (i in a)
			if (i == type) return true;
		return false;
	}
	
	public function clrPair(inner:Int, type:Int):Bool
	{
		var a = m.get(inner);
		if (a == null) return false;
		
		var c = 0;
		for (i in a)
			if (i == type)
				c++;
		//assert(c == 1);
		
		var success = a.remove(type);
		
		if (a.length == 0)
			m.set(inner, null);
			
		return success;
	}
	
	public function clrAll(inner:Int)
	{
		m.set(inner, null);
	}
}
#end