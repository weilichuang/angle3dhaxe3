////////////////////////////////////////////////////////////////////////////////
//=BEGIN MIT LICENSE
//
// The MIT License
// 
// Copyright (c) 2012-2013 Andras Csizmadia
// http://www.vpmedia.eu
// 
// Permission is hereby granted, free of charge, to any person obtaining a copy
// of this software and associated documentation files (the "Software"), to deal
// in the Software without restriction, including without limitation the rights
// to use, copy, modify, merge, publish, distribute, sublicense, and/or sell
// copies of the Software, and to permit persons to whom the Software is
// furnished to do so, subject to the following conditions:
// 
// The above copyright notice and this permission notice shall be included in
// all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR
// IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY,
// FITNESS FOR A PARTICULAR PURPOSE AND NONINFRINGEMENT. IN NO EVENT SHALL THE
// AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM, DAMAGES OR OTHER
// LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM,
// OUT OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN
// THE SOFTWARE.
//
//=END MIT LICENSE
////////////////////////////////////////////////////////////////////////////////

package hu.vpmedia.signals;

import flash.Lib;
import hu.vpmedia.ds.DoublyLinkedList;

/**
 * Simple signal without parameters
 * @author Andras Csizmadia
 */
class SignalLite
{    
    private var list:DoublyLinkedList<SlotLite>;
    
    /**
     * Constructor
     */
    public function new() 
    {   
        list = new DoublyLinkedList<SlotLite>();
    }
        
    public function add( listener:Dynamic, ?once:Bool = false ):Void
    {
        if ( has( listener ) ) 
        {
            //Lib.trace("WARN. Cannot add, listener already registered.");
            return;
        }
        var slot = new SlotLite();
        slot.listener = listener;
        list.add(slot);
    }
    
    public function addOnce( listener:Dynamic ):Void
    {
        if ( !has( listener ) ) 
        {
            add(listener, true);
        }
    }
    
    public function has( listener:Dynamic ):Bool
    {
        var node:SlotLite = list.head;
        while(node != null) 
        {
            if(node.listener == listener)
            {
                return true;
            }
            node = node.next;
        }         
        return false;
    }
    
    public function getSize():Int
    {
        var count:Int = 0;        
        var node:SlotLite = list.head;
        while(node != null) 
        {
            count++;
            node = node.next;
        }    
        
        return count;
    }
    
    public function remove( listener:Dynamic ):Void
    {        
        var node:SlotLite = list.head;
        while(node != null) 
        {
            if ( node.listener == listener )
            {
                list.remove(node);
            }            
            node = node.next;
        }  
    }
    
    public function removeAll():Void
    {        
        list.removeAll();
    }
    
    public function dispatch(?args:Array<Dynamic> = null):Void
    {  
        if (args == null)
        {
            args = new Array<Dynamic>();
        }
        var node:SlotLite = list.head;
        while(node != null) 
        {
            Reflect.callMethod( null, node.listener, args);
            node = node.next;
        }
    }
    
}

typedef Signal = SignalLite