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

import flash.display.DisplayObject;
import flash.display.Loader;
import flash.events.Event;
import flash.net.URLLoaderDataFormat;
import flash.system.ApplicationDomain;
import flash.system.LoaderContext;
import flash.utils.ByteArray;

import hu.vpmedia.assets.loaders.AssetLoaderType;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class SWFParser extends BaseAsyncAssetParser
{
    public function new()
    {
        super();
        _type=AssetParserType.SWF_PARSER;
        _pattern=~/^.+\.((swf))/i;
        _loaderType=AssetLoaderType.DISPLAY_LOADER;
        _dataType=URLLoaderDataFormat.BINARY;
    }
    
    override public function parse(data:Dynamic):Dynamic
    {
        return cast(data, DisplayObject);
    }
    
    override public function parseAsync(data:ByteArray, params:Dynamic):Void
    {
        _progress=0;
        progressed.dispatch([this]);
        
        var loader:Loader=new Loader();
        loader.contentLoaderInfo.addEventListener(Event.COMPLETE, loaderCompleteHandler);
        var context:LoaderContext=new LoaderContext(false, ApplicationDomain.currentDomain);
        context.allowCodeImport=true;
        try
        {
            context.allowLoadBytesCodeExecution=true;
        }
        catch(error:Dynamic)
        {
        }
        loader.loadBytes(data);
    }
    
    private function loaderCompleteHandler(event:Event):Void
    {
        event.target.removeEventListener(Event.COMPLETE, loaderCompleteHandler);
        completed.dispatch([this, event.target.loader.content]);
    }
}