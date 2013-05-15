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
package hu.vpmedia.stm.hfsm;

class State implements IState
{
    public var name:String;
    public var from:Array<String>;
    public var enter:String->String->String->Void;
    public var exit:String->String->String->Void;
    public var children:Array<IState>;
    public var parent(get_parent, set_parent):IState;
    public var root(get_root, null):IState;
    public var parents(get_parents, null):Array<IState>;
    private var _parent:IState;
    public function new(name:String, from:Array<String>=null, enter:String->String->String->Void=null, exit:String->String->String->Void=null)
    {
        this.name=name;
        if (from==null)
        from=["*"];
        this.from=from;
        this.enter=enter;
        this.exit=exit;
        this.children=[];
        /*if (parent != null)
        {
            _parent=parent;
            _parent.children.push(this);
        }*/
    }
    
    /*public function isAllowTransitionFrom(stateName:String):Bool
    {
        return(from.indexOf(stateName)!=-1 || from.indexOf("*"));
    }*/
    
    function set_parent(parent:IState):IState
    {
        _parent=parent;
        _parent.children.push(this);
        return _parent;
    }
    
    function get_parent():IState
    {
        return _parent;
    }
    
    function get_root():IState
    {
        var parentState:IState=_parent;
        if (parentState != null)
        {
            while (parentState.parent != null)
            {
                parentState=parentState.parent;
            }
        }
        return parentState;
    }
    
    function get_parents():Array<IState>
    {
        var parentList:Array<IState>=[];
        var parentState:IState=_parent;
        if (parentState != null)
        {
            parentList.push(parentState);
            while (parentState.parent != null)
            {
                parentState=parentState.parent;
                parentList.push(parentState);
            }
        }
        return parentList;
    }
    
    public function isStateAccepted(stateName:String):Bool
    {
        return Lambda.indexOf(from, stateName) != -1;
    }
    
    public function isAllStatesAccepted():Bool
    {
        return from[0] == "*";
    }
    
   /* public function toString():String
    {
        return this.name;
    } */
}