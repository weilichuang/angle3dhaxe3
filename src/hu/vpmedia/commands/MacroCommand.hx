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
package hu.vpmedia.commands;

import flash.Lib;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */

class MacroCommand extends BaseCommand
{
    private var commands:Array<IBaseCommand>;
    private var completeCount:Int;
    private var isOnceCommand:Bool;
    private var isPaused:Bool;
    
    public static inline var ITEM_COMPLETE:String="itemComplete";
            
    //----------------------------------
    //  Constructor
    //----------------------------------
    /**
     * Constructor
     */
    public function new(isOnceCommand:Bool=false, commands:Array<IBaseCommand>=null)
    {    
        super(0, null, true);
        this.isOnceCommand=isOnceCommand;
        if (commands != null)
        {
            this.commands = commands.copy();
        }
        else
        {
            this.commands=new Array();
        }
        completeCount=0;
    }
    
    //----------------------------------
    //  API
    //----------------------------------
    public function addCommand(command:IBaseCommand):Void
    {
        /*#if debug
        Lib.trace("addCommand::" + command);
        #end*/
        commands.push(command);
    }
    
    public function addCommandAt(command:IBaseCommand, index:Int):Void
    {
        /*#if debug
        Lib.trace("addCommandAt::" + command + "::" + index);
        #end*/
        commands.insert(index, command);
    }
    
    public function removeCommand(command:IBaseCommand):Void
    {
        var index:Int=Lambda.indexOf(commands, command);
       /*#if debug
        trace("removeCommand::" + command + "::" + index + "::" + commands.length);
        #end*/
        if (index <= -1)
        {
            return;
        }
        commands.splice(index, 1);
        command.dispose();
        command=null;
    }
    
    /**
     * execute
     */
    override function start(params:Dynamic=null):Void
    {
        //trace(this, "start", isRunning, completeCount);        
        if (isRunning)
        {
            return;
        }
        if (params != null)
        {
            this.params=params;
        }
        #if debug
        trace("start::" + this.params + "::" + completeCount);
        #end
        executeAll();
    }
    
    /**
     * Reset
     */
    override function reset():Void
    {
        //trace(this, "reset");
        super.reset();
        completeCount=0;
    }
    
    /**
     * Dispose
     */
    override function dispose():Void
    {
        //trace(this, "dispose");
        clear();
        super.dispose();
    }
    
    
    /**
     * Clear
     */
    public function clear():Void
    {
        reset();
        var n:Int = commands.length;
        for (i in 0...n)
        {
            removeCommand(commands[i]);
        }
        commands = new Array();
    }
    
    /**
     * Helper
     */
    public function getCommandByIndex(value:Int):IBaseCommand
    {
        return commands[value];
    }
    
    /**
     * Helper
     */
    public function getCommandByClass(value:Class<Dynamic>):IBaseCommand
    {
        var n:Int=commands.length;
        var i:Int;
        for (i in 0...n)
        {
            if (Std.is(commands[i],value))
            {
                return commands[i];
            }
        }
        return null;
    }
    
    /**
     * Size
     */
    public function size():Int
    {
        return commands.length;
    }
    
    /**
     * isEmpty
     */
    public function isEmpty():Bool
    {
        return size() <= 0;
    }
    
    /**
     * contains item
     */
    public function contains(item:IBaseCommand):Bool
    {
        return Lambda.indexOf(commands, item) > -1;
    }
    
    /**
     * 
     */
    public function getCommandIndex(item:IBaseCommand):Int
    {
        return Lambda.indexOf(commands, item);
    }
    
    //----------------------------------
    //  Methods
    //----------------------------------
    
    /*function bindItem(item:IBaseCommand):Void
    {
        item.signal.addOnce(completeHandler);
    }
    
    function unbindItem(item:IBaseCommand):Void
    {
        item.signal.remove(completeHandler);
    }*/
    
    function executeAll():Void
    {
        reset();
        if (commands.length == 0)
        {
            sendTransmission(BaseCommand.COMPLETE, null, null, this);
        }
        else
        {
            var n:Int = commands.length;
            for (i in 0...n)
            {
                executeCommand(commands[i]);
            }
        }
    }
    
    function executeFirst():Void
    {
        reset();
        if (commands.length == 0)
        {
            sendTransmission(BaseCommand.COMPLETE, null, null, this);
        }
        else
        {
            executeCommand(commands[0]);
        }
    }
    
    function executeCommand(command:IBaseCommand):Void
    {
        #if debug
        trace("executeCommand::" + command + "::" + params);
        #end
        isRunning=true;
        command.signal.add(completeHandler);
        command.start(params);
    }
    
    function completeHandler(code:String, level:String, data:Dynamic, source:Dynamic):Void
    {
        if (code != BaseCommand.COMPLETE)
        {
            #if debug
            trace("completeHandlerProgress::" + code);
            #end
            return;
        }
        var command:IBaseCommand=Std.instance(source, IBaseCommand);
        sendTransmission(ITEM_COMPLETE, level, data, source);
        completeCount++;
        #if debug
        trace("completeHandler::" + code + "::isRunning::" + completeCount + "::" + commands.length);
        #end
        if (completeCount == commands.length)
        {
            isRunning=false;
            sendTransmission(BaseCommand.COMPLETE, null, null, this);
            if (isOnceCommand)
            {
                clear();
            }
        }
    }
}