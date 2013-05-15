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

class SequenceCommand extends MacroCommand
{
    //----------------------------------
    //  Constructor
    //----------------------------------
    /**
     * Constructor
     */
    public function new(isOnceCommand:Bool=false, commands:Array<IBaseCommand>=null)
    {
        super(isOnceCommand, commands);
    }
    
    //----------------------------------
    //  Methods
    //----------------------------------
    /**
     * execute
     */
    override function start(params:Dynamic=null):Void
    {
        if (isRunning)
        {
            return;
        }
        if (params)
        {
            this.params=params;
        }
        #if debug
        trace("start" + "::" + this.params);
        #end
        executeFirst();
    }
    
    override function completeHandler(code:String, level:String, data:Dynamic, source:Dynamic):Void
    {
        if (code != BaseCommand.COMPLETE)
        {
            #if debug
            trace("completeHandlerProgress::" + code);
            #end
            return;
        }
        var command:IBaseCommand=cast(source,IBaseCommand);        
        sendTransmission(MacroCommand.ITEM_COMPLETE, level, data, source);
        if (isOnceCommand)
        {
            removeCommand(command);
        }
        else
        {
            completeCount++;
        }
        #if debug
        trace("completeHandler::" + code + "::isRunning::" + completeCount + "::" + commands.length);
        #end
        var n:Int=commands.length;
        if ((isOnceCommand && n == 0) || completeCount == n)
        {
            isRunning=false;
            sendTransmission(BaseCommand.COMPLETE, null, null, this);
        }
        else if (isRunning)
        {
            executeCommand(commands[completeCount]);
        }
    }
}