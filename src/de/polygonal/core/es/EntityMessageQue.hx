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

import de.polygonal.core.fmt.StringUtil;
import de.polygonal.core.util.Assert.assert;
import de.polygonal.Printf;
import haxe.ds.Vector;

import de.polygonal.core.es.Entity in E;
import de.polygonal.core.es.EntitySystem in ES;

#if alchemy
import flash.Memory in Mem;
#end

using de.polygonal.core.es.EntitySystem;

/**
	A messaging system used by the entity system
**/
@:access(de.polygonal.core.es.Entity)
@:access(de.polygonal.core.es.EntityId)
@:access(de.polygonal.core.es.EntitySystem)
class EntityMessageQue
{
	inline static var MSG_SIZE =
	#if alchemy
	//sender+recipient inner: 2*4 bytes
	//sender+recipient index: 2*2 bytes
	//type, skip count, message index: 3*2 bytes
	18; //#bytes
	#else
	7; //#32bit integers
	#end
	
	var mQue:
	#if alchemy
	de.polygonal.ds.mem.ByteMemory;
	#else
	Vector<Int>;
	#end
	
	var mCapacity:Int;
	var mSize:Int;
	var mFront:Int;
	var mCurrMsgInIndex:Int;
	var mCurrMsgOut:EntityMessage;
	var mFreeMsgIndex:Int;
	var mMessages:Array<EntityMessage>;
	var mSending:Bool = false;
	
	public function new(capacity:Int)
	{
		mCapacity = capacity;
		
		mQue =
		#if alchemy
		//id.inner for sender: 4 bytes
		//id.inner for recipient: 4 bytes
		//id.index for sender: 2 bytes
		//id.index for recipient: 2 bytes
		//type: 2 bytes
		//remaining: 2 bytes
		//message index: 2 bytes
		new de.polygonal.ds.mem.ByteMemory(mCapacity * MSG_SIZE, "entity_system_message_que");
		#else
		new Vector<Int>(mCapacity * MSG_SIZE);
		#end
		
		mSize = 0;
		mFront = 0;
		
		mFreeMsgIndex = 0;
		mMessages = new Array<EntityMessage>();
		
		#if verbose
		L.d('there are ${EntityMessage.countTotalMessages()} message types', "es");
		#end
	}
	
	function getMsgIn():EntityMessage
	{
		if (mCurrMsgInIndex == -1) return null;
		
		return mMessages[mCurrMsgInIndex];
	}
	
	function getMsgOut():EntityMessage
	{
		mCurrMsgOut = mMessages[mFreeMsgIndex];
		if (mCurrMsgOut == null) mCurrMsgOut = mMessages[mFreeMsgIndex] = new EntityMessage();
		
		return mCurrMsgOut;
	}
	
	inline function clrMessage()
	{
		if (mCurrMsgOut != null)
		{
			mCurrMsgOut.mBits = 0;
			mCurrMsgOut.mObject = null;
			mCurrMsgOut = null;
		}
	}
	
	function enqueue(sender:E, recipient:E, type:Int, remaining:Int, dir:Int)
	{
		assert(sender != null);
		assert(recipient != null);
		assert(type >= 0 && type <= 0xFFFF);
		assert(mSize < mCapacity, 'message queue exhausted (size=$mSize capacity=$mCapacity)');
		
		var i = (mFront + mSize) % mCapacity;
		mSize++;
		
		if (recipient.mBits & (E.BIT_SKIP_MSG | E.BIT_MARK_FREE) > 0)
		{
			//enqueue message even if recipient doesn't want it;
			//this is required for properly stopping a message propagation (when an entity calls stop())
			#if alchemy
			Mem.setI32(mQue.offset + i * MSG_SIZE, -1);
			#else
			mQue[i * MSG_SIZE] = -1;
			#end
			return;
		}
		
		#if debug
		#if (verbose == "extra")
		var senderName = sender.name == null ? "N/A" : sender.name;
		var recipientName = recipient.name == null ? "N/A" : recipient.name;
		
		if (senderName.length > 30) senderName = StringUtil.ellipsis(senderName, 30, 1, true);
		if (recipientName.length > 30) recipientName = StringUtil.ellipsis(recipientName, 30, 1, true);
		
		var msgName = EntityMessage.name(type);
		if (msgName.length > 20) msgName = StringUtil.ellipsis(msgName, 20, 1, true);
		
		L.d(Printf.format('enqueue message %30s -> %-30s: %-20s (remaining: $remaining)', [senderName, recipientName, msgName]), "es");
		#end
		#end
		
		if (dir > 0) type |= 0x8000; //dispatch to descendants
		else
		if (dir < 0) type |= 0x4000; //dispatch to ancestors
		
		var senderId = sender.id;
		var recipientId = recipient.id;
		var q = mQue;
		
		#if alchemy
		var addr = q.getAddr(i * MSG_SIZE);
		Mem.setI32(addr     , senderId.inner);
		Mem.setI32(addr +  4, recipientId.inner);
		Mem.setI16(addr +  8, senderId.index);
		Mem.setI16(addr + 10, recipientId.index);
		Mem.setI16(addr + 12, type);
		Mem.setI16(addr + 14, remaining);
		Mem.setI16(addr + 16, mFreeMsgIndex);
		#else
		var addr = i * MSG_SIZE;
		q[addr    ] = senderId.inner;
		q[addr + 1] = recipientId.inner;
		q[addr + 2] = senderId.index;
		q[addr + 3] = recipientId.index;
		q[addr + 4] = type;
		q[addr + 5] = remaining;
		q[addr + 6] = mFreeMsgIndex;
		#end
		
		//use same message for multiple recipients
		//increment counter if batch is complete and data is set
		if (remaining == 0)
		{
			if (mCurrMsgOut != null && mCurrMsgOut.mBits > 0)
			{
				mCurrMsgOut.mBits |= EntityMessage.USED;
				mFreeMsgIndex++; 
				mCurrMsgOut = null;
			}
		}
	}
	
	function dispatch()
	{
		if (mSize == 0 || mSending) return;
		mSending = true;
		
		var a = ES.mFreeList;
		
		var senderIndex:Int;
		var senderInner:Int;
		var recipientIndex:Int;
		var recipientInner:Int;
		var type:Int;
		var skipCount:Int;
		var sender:Entity;
		var recipient:Entity;
		var dir:Int;
		
		var q = mQue;
		var c = mCapacity;
		
		#if verbose
		var numSkippedMessages = 0;
		var numDispatchedMessages = 0;
		#end
		
		#if (verbose == "extra")
		if (mSize == 1)
			L.d("sending one message ...", "es");
		else
			L.d('sending $mSize messages ...', "es");
		#end
		
		while (mSize > 0) //while there are buffered messages
		{
			#if alchemy
			var addr        = q.getAddr(mFront * MSG_SIZE);
			senderInner     = Mem.getI32(addr);
			recipientInner  = Mem.getI32(addr  +  4);
			senderIndex     = Mem.getUI16(addr +  8);
			recipientIndex  = Mem.getUI16(addr + 10);
			type            = Mem.getUI16(addr + 12);
			skipCount       = Mem.getUI16(addr + 14);
			mCurrMsgInIndex = Mem.getUI16(addr + 16);
			#else
			var addr        = mFront * MSG_SIZE;
			senderInner     = q[addr    ];
			recipientInner  = q[addr + 1];
			senderIndex     = q[addr + 2];
			recipientIndex  = q[addr + 3];
			type            = q[addr + 4];
			skipCount       = q[addr + 5];
			mCurrMsgInIndex = q[addr + 6];
			#end
			
			if (type & 0x8000 > 0)
			{
				dir = 1;
				type &= ~0x8000;
			}
			else
			if (type & 0x4000 > 0)
			{
				dir =-1;
				type &= ~0x4000;
			}
			else
				dir = 0;
			
			//ignore message?
			if (senderInner == -1)
			{
				#if verbose
				numSkippedMessages++;
				#end
				
				//dequeue
				mFront = (mFront + 1) % c;
				mSize--;
				continue;
			}
			
			sender = a[senderIndex];
			
			recipient = a[recipientIndex];
			
			//dequeue
			mFront = (mFront + 1) % c;
			mSize--;
			
			if (sender == null || recipient == null || (sender.mBits | recipient.mBits) & E.BIT_MARK_FREE > 0)
			{
				#if verbose
				numSkippedMessages++;
				#end
				
				#if (verbose == "extra")
				L.d('sender or recipient gone, skipping message.');
				#end
				continue;
			}
			
			#if debug
			#if (verbose == "extra")
			var data = mMessages[mCurrMsgInIndex] != null ? mMessages[mCurrMsgInIndex] : null;
			var senderId = sender.name == null ? Std.string(sender.id) : sender.name;
			var recipientId = recipient.name == null ? Std.string(recipient.id) : recipient.name;
			
			if (senderId.length > 30) senderId = StringUtil.ellipsis(senderId, 30, 1, true);
			if (recipientId.length > 30) recipientId = StringUtil.ellipsis(recipientId, 30, 1, true);
			
			var msgName = EntityMessage.name(type);
			if (msgName.length > 20) msgName = StringUtil.ellipsis(msgName, 20, 1, true);
			
			L.d(Printf.format('message %30s -> %-30s: %-20s $data (remaining: $skipCount)', [senderId, recipientId, msgName, skipCount]), "es");
			#end
			#end
			
			//notify recipient
			if (recipient.mBits & (E.BIT_SKIP_MSG | E.BIT_MARK_FREE) == 0)
			{
				recipient.onMsg(type, sender);
				
				#if verbose
				numDispatchedMessages++;
				#end
			}
			#if verbose
			else
				numSkippedMessages++;
			#end
			
			if (recipient.mBits & E.BIT_STOP_PROPAGATION > 0)
			{
				if (dir > 0)
				{
					//just skip the subtree rooted at the recipient, not the subtree of the sender
					skipCount = recipient.getSize();
					
					#if (verbose == "extra")
					trace('stop message propagation to descendants at "${recipient.name}" (skipping $skipCount messages)');
					#end
				}
				else
				if (dir < 0)
				{
					#if (verbose == "extra")
					trace('stop message propagation to ancestors at "${recipient.name}" (skipping $skipCount messages)');
					#end
				}
				
				//recipient stopped notification;
				//reset flag and skip remaining messages in current batch
				recipient.mBits &= ~E.BIT_STOP_PROPAGATION;
				mFront = (mFront + skipCount) % c;
				mSize -= skipCount;
			}
		}
		
		#if verbose
		if (numDispatchedMessages + numSkippedMessages > 0)
			L.d('dispatched $numDispatchedMessages messages (skipped: $numSkippedMessages)', "es");
		#end
		
		//clear messages
		for (i in 0...mMessages.length)
		{
			assert(mMessages[i] != null);
			mMessages[i].mBits = 0;
			mMessages[i].mObject = null;
		}
		mFreeMsgIndex = 0;
		mCurrMsgInIndex = -1;
		
		mSending = false;
	}
}