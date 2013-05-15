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

import flash.utils.Timer;
import flash.events.TimerEvent;
import hu.vpmedia.signals.SignalLite;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class BaseCommand implements IBaseCommand
{
    public var delay:Int;
    public var dispatchEvents:Bool;
    public var isRunning:Bool;
    public var params:Dynamic;
    public var timer:Timer;
    public var signal:Signal;
        
    public static inline var COMPLETE:String="complete";
    
    //----------------------------------
    //  Constructor
    //----------------------------------
    /**
     * Constructor
     */
    public function new(?delay:Float=0, ?params:Dynamic=null, ?dispatchEvents:Bool=true)
    {                         
        if (delay > 0 && timer == null)
        {
            timer=new Timer(delay, 1);
            timer.addEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete, false, 0, true);
        }
        this.dispatchEvents=dispatchEvents;
        if (dispatchEvents)
        {
            signal = new Signal();
        }
        if (params != null)
        {
            this.params=params;
        }
        delay=cast(1000 * delay, Int);
    }
        
    public function dispose():Void
    {
        isRunning=false;
        if (delay > 0 && timer != null)
        {
        timer.reset();
        timer.removeEventListener(TimerEvent.TIMER_COMPLETE, onTimerComplete);
        timer=null;
        }
        if (params != null)
        {
            params=null;
        }
        if (signal != null)
        {
            signal.removeAll();
            signal=null;
        }
    }
    
    //----------------------------------
    //  Getters
    //----------------------------------
    
    public function reset():Void
    {
        if (delay > 0)
        {
        timer.reset();
        }
        isRunning=false;
    }
    
    //----------------------------------
    //  Methods
    //----------------------------------
    /**
     * Start
     */
    public function start(params:Dynamic=null):Void
    {
        if (isRunning)
        {
            return;
        }
        isRunning=true;
        if (params != null)
        {
            this.params=params;
        }
        if (delay > 0)
        {
            timer.start();
        }
        else
        {
            execute(params);
        }
    }
    
    public function stop():Void
    {
        if (delay > 0)
        {
        timer.stop();
        }
        isRunning=false;
    }
    
    /**
     * Execute
     */
    public function execute(params:Dynamic=null):Void
    {
        isRunning=false;
        if (dispatchEvents)
        {
            sendTransmission(COMPLETE,null,null,this);
        }
    }
    
    /**
     * Execute
     */
    public function sendTransmission(code:String, ?level:String = null, ?data:Dynamic = null, ?source:Dynamic = null):Void
    {
        signal.dispatch([code, level, data, source]);
    }
    
    /**
     * onTimerComplete
     */
    function onTimerComplete(event:TimerEvent):Void
    {
        execute(params);
    }
}