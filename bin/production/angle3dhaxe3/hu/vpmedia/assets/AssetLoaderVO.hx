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
package hu.vpmedia.assets;

import flash.net.URLRequest;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class AssetLoaderVO
{        
    private var _urlRequest:URLRequest;
    
    public var url:String;        
    
    public var priority:Int;
    
    public var type:String;    
    
    public var data:Dynamic;
    
    /**
     * TBD
     */
    public function new(url:String, priority:Int, data:Dynamic)
    {
        this.url=url;
        this.priority=priority;
        this.data=data;        
    }
        
    /**
     * TBD
     */
    public var urlRequest(get, null):URLRequest;
     private function get_urlRequest():URLRequest
    {        
        if (_urlRequest == null)
        {
            _urlRequest = new URLRequest(url);
        }    
        return _urlRequest;
    }
        
    /**
     * TBD
     */
    public function configure(requestParams:Array<Dynamic>):AssetLoaderVO
    {            
        for(k in requestParams)
        {
            if(Reflect.hasField(urlRequest, k))
                Reflect.setProperty(urlRequest,k,requestParams[k]);
        }    
        return this;
    }
            
    /**
     * TBD
     */
    public function toString():String
    {
        return "[AssetVO" + " url=" + url + " priority=" + priority + " data=" + data + " type=" + type + "]";
    }
            
    /**
     * @private
     */
    public static function compareByPriority(a:AssetLoaderVO, b:AssetLoaderVO):Int
    {
        if(a.priority<b.priority)
        {
            return -1;
        }
        else if(a.priority>b.priority)
        {
            return 1;
        }
        else
        {
            return 0;
        }
    }
}