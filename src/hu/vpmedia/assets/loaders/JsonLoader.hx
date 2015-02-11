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

import flash.events.Event;
import flash.events.IOErrorEvent;
import flash.events.ProgressEvent;
import flash.events.SecurityErrorEvent;
import flash.net.URLLoader;
import flash.net.URLLoaderDataFormat;
import flash.net.URLRequest;
import flash.net.URLRequestMethod;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class JsonLoader extends BaseAssetLoader
{
    private var _loader:URLLoader;
    
    private var _dataFormat:URLLoaderDataFormat;
    
    public function new(urlRequest:URLRequest=null)
    {
        super(urlRequest);
    }
    
    override private function initialize():Void
    {
        _type = AssetLoaderType.JSON_LOADER;
        _dataFormat = URLLoaderDataFormat.TEXT;
        _loader=new URLLoader();
        _loader.dataFormat=_dataFormat;
        attachListeners(_loader);
    }
    
    override public function load(urlRequest:URLRequest):Void
    {
        super.load(urlRequest);
        
        _loader.load(urlRequest);
    }
    
    override public function close():Void
    {
        try
        {
            _loader.close();
        } 
        catch(error:Dynamic)
        {                
        }                
    }
    
    override public function dispose():Void
    {
        super.dispose();
        detachListeners(_loader);
    }
}