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
package hu.vpmedia.assets.parsers;

import flash.events.Event;
import flash.events.IEventDispatcher;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.media.Sound;
import flash.net.URLLoaderDataFormat;
import flash.utils.ByteArray;

import hu.vpmedia.assets.loaders.AssetLoaderType;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class SoundParser extends BaseAsyncAssetParser
{
    public function new()
    {
        super();
        _type=AssetParserType.SOUND_PARSER;
        _pattern=~/^.+\.((mp3)|(mp2)|(mp2)|(aiff))/i;
        _loaderType=AssetLoaderType.SOUND_LOADER;
        _dataType=URLLoaderDataFormat.BINARY;
    }
    
    override public function parse(data:Dynamic):Dynamic
    {
        return Std.instance(data, Sound);
    }
    
    override public function parseAsync(data:ByteArray, params:Dynamic):Void
    {
        _progress=0;
        progressed.dispatch([this]);
        
        var loader:Sound=new Sound();
        
        attachListeners(loader);
        
        loader.loadCompressedDataFromByteArray(data, data.length);
    }
    
    private function loaderProgressHandler(event:ProgressEvent):Void
    {
        if(event.bytesLoaded==event.bytesTotal)
        {
            detachListeners(Std.instance(event.target, IEventDispatcher));
            completed.dispatch([this, event.target]);
        }
    }
    
    private function loaderErrorHandler(event:Event):Void
    {
        detachListeners(Std.instance(event.target, IEventDispatcher));
        completed.dispatch([this, null]);
    }
    
    private function attachListeners(source:IEventDispatcher):Void
    {
        source.addEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
        source.addEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
    }
    
    private function detachListeners(source:IEventDispatcher):Void
    {
        source.removeEventListener(IOErrorEvent.IO_ERROR, loaderErrorHandler);
        source.removeEventListener(ProgressEvent.PROGRESS, loaderProgressHandler);
    }
}