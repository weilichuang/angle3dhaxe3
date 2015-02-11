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
package hu.vpmedia.assets.loaders;

import flash.display.LoaderInfo;
import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.Lib;
import flash.media.Sound;
import flash.net.URLLoader;
import flash.net.URLRequest;

import hu.vpmedia.signals.SignalLite;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class BaseAssetLoader
{
    private var _progress:Float=0;
    
    private var _urlRequest:URLRequest;
    
    private var _data:Dynamic;
    
    private var _type:String;
    
    public var completed:Signal;
    
    public var progressed:Signal;
    
    public var failed:Signal;
	
	public var parserType:String;
            
    public function new(urlRequest:URLRequest=null)
    {
        completed = new Signal();
        progressed = new Signal();
        failed= new Signal();
        
        initialize();
        
        if(urlRequest !=null)
        {
            load(urlRequest);
        }
    }
    
    private function initialize():Void
    {
    }
    
    public function load(urlRequest:URLRequest):Void
    {            
        _progress=0;
        progressed.dispatch([this]);
        
        _urlRequest=urlRequest;
    }
    
    public function close():Void
    {        
    }
    
    public var progress(get, null):Float;
     private function get_progress():Float
    {
        return _progress;
    }
    
    public var data(get, set):Dynamic;
    private function get_data():Dynamic
    {
        return _data;
    }
    
    public var type(get, null):String;
     private function get_type():String 
    {
        return _type;
    }
    
    private function set_data(data:Dynamic):Dynamic
    {
        _data = data;
        return _data;
    }
    
    public var urlRequest(get, null):URLRequest;
     private function get_urlRequest():URLRequest
    {
        return _urlRequest;
    }
    
    public function dispose():Void
    {
        completed.removeAll();
        completed=null;
        
        failed.removeAll();
        failed=null;
        
        progressed.removeAll();
        progressed=null;
        
        _urlRequest=null;
        _data=null;
    }
    
    private function attachListeners(dispatcher:IEventDispatcher):Void
    {
        dispatcher.addEventListener(Event.COMPLETE, loaderCompleteHandler, false, 0, true);
        dispatcher.addEventListener(IOErrorEvent.IO_ERROR, loaderFailedHandler, false, 0, true);
        dispatcher.addEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderFailedHandler, false, 0, true);
        dispatcher.addEventListener(ProgressEvent.PROGRESS, loaderProgressHandler, false, 0, true);
    }
    
    private function detachListeners(dispatcher:IEventDispatcher):Void
    {
        dispatcher.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
        dispatcher.removeEventListener(IOErrorEvent.IO_ERROR, loaderFailedHandler);
        dispatcher.removeEventListener(SecurityErrorEvent.SECURITY_ERROR, loaderFailedHandler);
        dispatcher.removeEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
    }
    
    private function loaderCompleteHandler(event:Event):Void
    {
        if(Std.is(event.target, LoaderInfo))
        {
            data = Std.instance(event.target, LoaderInfo).loader.content;
        }
        else if(Std.is(event.target, Sound))
        {
            data = Std.instance(event.target, Sound);
        }
        else if(Std.is(event.target, URLLoader))
        {
            data = Std.instance(event.target, URLLoader).data;
        }
        else if(event.target.data)
        {
            data = event.target.data;
        }
        else
        {
            data = event.target;
        }
        completed.dispatch([this]);
    }
    
    private function loaderFailedHandler(event:Event):Void
    {
        Lib.trace(this+"::"+event);
        failed.dispatch([this]);
    }
    
    private function loaderProgressHandler(event:ProgressEvent):Void
    {
        _progress=(event.bytesLoaded / event.bytesTotal)* 100;
        progressed.dispatch([this]);
    }
}