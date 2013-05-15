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
package hu.vpmedia.media;

import flash.events.Event;
import flash.media.Sound;
import flash.media.SoundChannel;
import flash.media.SoundTransform;

import hu.vpmedia.signals.SignalLite;

/**
 * TBD
 * @author Andras Csizmadia
 */
 class SoundPlayer 
 {
    //----------------------------------
    //  Properties
    //----------------------------------
    
    public var name : String;
    public var sound : Sound;
    public var lastPosition : Float;
    public var channel : SoundChannel;
    public var state : Int;
    public var volume : Float;
    public var isMuted : Bool;
    public var soundCompleted:Signal;
    
    //----------------------------------
    //  Consts
    //----------------------------------
    
    static public inline var STATE_PLAYING : Int = 0x01;
    static public inline var STATE_PAUSED : Int = 0x02;
    static public inline var STATE_STOPPED : Int = 0x03;
    static public inline var STATE_DISPOSED : Int = 0x04;
         
    public function new(sound : Sound = null, volume : Float = 1) 
    {
        if (sound != null)  
        {
            this.sound = sound;
        }
        this.volume = volume;
        soundCompleted=new Signal();
        //channel = new SoundChannel();
        lastPosition = 0;
    }

    //----------------------------------
    //  API
    //----------------------------------

    public function play(startTime : Float = 0, loops : Int = 0) : Void 
    {
        if (sound == null || isPlaying())  
        {
            return;
        }
        if (isPaused())  
        {
            startTime = lastPosition;
        }
        state = STATE_PLAYING;
        var soundTransform : SoundTransform = new SoundTransform((isMuted) ? 0 : volume);
        channel = sound.play(startTime, loops, soundTransform);
        channel.addEventListener(Event.SOUND_COMPLETE, soundChannelHandler);
    }
    
    public function pause() : Void 
    {
        if (isPaused())  
        {
            return;
        }
        state = STATE_PAUSED;
        lastPosition = channel.position;
        channel.stop();
        removeListeners();
    }
    
    public function stop() : Void 
    {
        if (isStopped())  
        {
            return;
        }
        state = STATE_STOPPED;
        lastPosition = 0;
        channel.stop();
        removeListeners();
    }

    //----------------------------------
    //  API : Info
    //----------------------------------
    
    public function getPlayPercent() : Float 
    {
        return (channel.position / sound.length) * 100;
    }
        
    public function getLength() : Float 
    {
        return sound.length;
    }
    
    public function getPosition() : Float 
    {
        return channel.position;
    }

    //----------------------------------
    //  API : States
    //----------------------------------

    public function isPlaying() : Bool 
    {
        return state == STATE_PLAYING;
    }
    
    public function isPaused() : Bool 
    {
        return state == STATE_PAUSED;
    }
    
    public function isStopped() : Bool 
    {
        return state == STATE_STOPPED;
    }
    
    public function isDisposed() : Bool 
    {
        return state == STATE_DISPOSED;
    }

    //----------------------------------
    //  API : Lifecycle
    //----------------------------------

    public function dispose() : Void 
    {
        if(isDisposed())  {
            return;
        }
        state = STATE_DISPOSED;
        removeListeners();
        if(channel != null) 
            channel.stop();
        channel = null;
    }

    //----------------------------------
    //  API : Volume
    //----------------------------------
        
    public function getVolume() : Float 
    {
        var result : Float = volume;
        if(channel != null)  {
            result = channel.soundTransform.volume;
        }
        return result;
    }
    
    public function setVolume(value : Float) : Void 
    {
        if(value > 0) 
            volume = value;
        isMuted = (value <= 0);
        var soundTransform : SoundTransform = channel.soundTransform;
        soundTransform.volume = value;
        channel.soundTransform = soundTransform;
    }
    
    public function mute() : Void 
    {
        if (!isMuted)  
        {
            setVolume(0);
        }
        else  
        {
            setVolume(volume);
        }
    }
    
    function soundChannelHandler(event : Event) : Void 
    {
        
        if (event.type == Event.SOUND_COMPLETE) 
        {        
            soundCompleted.dispatch([this]);
            stop();
        }
    }
    
    function removeListeners() : Void 
    {
        channel.removeEventListener(Event.SOUND_COMPLETE, soundChannelHandler);
    }

}

