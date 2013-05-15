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

import hu.vpmedia.assets.parsers.BaseAssetParser;
import hu.vpmedia.assets.parsers.BinaryParser;
import hu.vpmedia.assets.parsers.CSSParser;
import hu.vpmedia.assets.parsers.ImageParser;
import hu.vpmedia.assets.parsers.JSONParser;
import hu.vpmedia.assets.parsers.SWCParser;
import hu.vpmedia.assets.parsers.SWFParser;
import hu.vpmedia.assets.parsers.SoundParser;
import hu.vpmedia.assets.parsers.TXTParser;
import hu.vpmedia.assets.parsers.XMLParser;

/**
 * @author Andras Csizmadia
 * @version 1.0
 */
class AssetLoaderPlugin
{
    /**
     * TBD
     */
    private static var DEFAULT_PARSER:BaseAssetParser=new BinaryParser();
    
    /**
     * TBD
     */
    private static var PARSERS:Array<BaseAssetParser>=[ new CSSParser(), new ImageParser(), new JSONParser(), new SWCParser(), new SWFParser(), new SoundParser(), new TXTParser(), new XMLParser()];
    
    
    /**
     * TBD
     */
    public static function register(parser:BaseAssetParser):Bool
    {
        var n:Int=PARSERS.length;
        for(i in 0...n)
        {
            if(PARSERS[i].patternSource==parser.patternSource)
            {
                return false;
            }
        }
        
        PARSERS.push(parser);
        
        return true;
    }
    
    /**
     * TBD
     */
    public static function getParserByUrl(url:String):BaseAssetParser
    {
        var n:Int=PARSERS.length;
        for(i in 0...n)
        {
            if(PARSERS[i].canParse(url))
            {
                return PARSERS[i];
            }
        }
        return DEFAULT_PARSER;
    }
    
    /**
     * TBD
     */
    public static function getParserByType(type:String):BaseAssetParser
    {
        var n:Int=PARSERS.length;
        for(i in 0...n)
        {
            if(PARSERS[i].type==type)
            {
                return PARSERS[i];
            }
        }
        return DEFAULT_PARSER;
    }
    
}