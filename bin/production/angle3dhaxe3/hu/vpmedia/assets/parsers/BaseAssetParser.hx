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
import flash.net.URLLoaderDataFormat;
    
/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class BaseAssetParser
{
    private var _type:String;
    
    private var _pattern:EReg;
    
    private var _loaderType:String;
    
    private var _dataType:URLLoaderDataFormat;
    
    public function new()
    {
    }
    
    public function parse(data:Dynamic):Dynamic
    {
        return null;
    }
    
    public var type(get, null):String;
     private function get_type():String
    {
        return _type;
    }
    
    public var loaderType(get, null):String;
     private function get_loaderType():String
    {
        return _loaderType;
    }
    
    public var dataType(get, null):URLLoaderDataFormat;
     private function get_dataType():URLLoaderDataFormat
    {
        return _dataType;
    }
    
    public var pattern(get, null):EReg;
     private function get_pattern():EReg
    {
        return _pattern;
    }
    public var patternSource(get, null):String;
     private function get_patternSource():String
    {
        return Std.string(_pattern);
    }
    
    public function canParse(url:String):Bool
    {        
        return _pattern.match(url);
    }
    
    public function dispose():Void
    {
        // TODO
    }
}