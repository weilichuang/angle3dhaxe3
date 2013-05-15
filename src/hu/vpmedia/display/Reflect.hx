////////////////////////////////////////////////////////////////////////////////
//=BEGIN LICENSE MIT
//
// Copyright (c) 2012, Original author & contributors
// Original author : Ben Pritchard of Pixelfumes <http://pixelfumes.blogspot.com>
// Contributors: 
//              Mim
//              Jasper
//              Jason Merrill
//              ...and all the others who have contributed
//              Andras Csizmadia -  http://www.vpmedia.eu
//
// Permission is hereby granted, free of charge, to any person obtaining
// a copy of this software and associated documentation files (the
// "Software"), to deal in the Software without restriction, including
// without limitation the rights to use, copy, modify, merge, publish,
// distribute, sublicense, and/or sell copies of the Software, and to
// permit persons to whom the Software is furnished to do so, subject to
// the following conditions:
// 
// The above copyright notice and this permission notice shall be
// included in all copies or substantial portions of the Software.
// 
// THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND,
// EXPRESS OR IMPLIED, INCLUDING BUT NOT LIMITED TO THE WARRANTIES OF
// MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
// NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE
// LIABLE FOR ANY CLAIM, DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION
// OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT OF OR IN CONNECTION
// WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
//  
//=END LICENSE MIT
////////////////////////////////////////////////////////////////////////////////
package hu.vpmedia.display;

import flash.display.Bitmap;
import flash.display.BitmapData;
import flash.display.GradientType;
import flash.display.SpreadMethod;
import flash.display.Sprite;
import flash.geom.Matrix;
import flash.utils.Timer;
import flash.events.TimerEvent;

class Reflect extends Sprite
{
    private var mc:Sprite;
    private var mcBMP:BitmapData;
    private var reflectionBMP:Bitmap;
    private var gradientMask_mc:Sprite;
    private var bounds:Dynamic;
    private var distance:Float;
    private var timer:Timer;

    public function new(mc:Sprite, ?pAlpha:Int=50, ?pRatio:Int=50, ?pDistance:Int=0, ?pUpdateTime:Int=0, ?pReflectionDropoff:Int=1)
    {
        super();
        /*the args object passes in the following variables
         /we set the values of our private vars to math the args*/
        //the clip being reflected
        distance = 0;
        this.mc=mc;
        //the alpha level of the reflection clip
        var alpha:Float=pAlpha / 100;
        //the ratio opaque color used in the gradient mask
        var ratio:Float=pRatio;
        //update time interval
        var updateTime:Float=pUpdateTime;
        //the distance at which the reflection visually drops off at
        var reflectionDropoff:Float=pReflectionDropoff;
        //the distance the reflection starts from the bottom of the mc
        var distance:Float=pDistance;
        //store width and height of the clip
        var mcHeight:Float=mc.height;
        var mcWidth:Float=mc.width;
        //store the bounds of the reflection
        bounds={};
        bounds.width=mcWidth;
        bounds.height=mcHeight;
        //create the BitmapData that will hold a snapshot of the movie clip
        mcBMP=new BitmapData(bounds.width, bounds.height, true, 0xFFFFFF);
        mcBMP.draw(mc);
        //create the BitmapData the will hold the reflection
        reflectionBMP=new Bitmap(mcBMP);
        //flip the reflection upside down
        reflectionBMP.scaleY=-1;
        //move the reflection to the bottom of the movie clip
        reflectionBMP.y=(bounds.height * 2) + distance;
        //add the reflection to the movie clip's Display Stack
        mc.addChild(reflectionBMP);
        //add a blank movie clip to hold our gradient mask
        gradientMask_mc = new Sprite();
        mc.addChild(gradientMask_mc);
        //set the values for the gradient fill
        var fillType:GradientType=GradientType.LINEAR;
        var colors:Array<UInt>=[0xFFFFFF, 0xFFFFFF];
        var alphas:Array<Float>=[alpha, 0];
        var ratios:Array<Float>=[0, ratio];
        var spreadMethod:SpreadMethod=SpreadMethod.PAD;
        //create the Matrix and create the gradient box
        var matr:Matrix=new Matrix();
        //set the height of the Matrix used for the gradient mask
        var matrixHeight:Float;
        if (reflectionDropoff <= 0)
        {
        matrixHeight=bounds.height;
        }
        else
        {
        matrixHeight=bounds.height / reflectionDropoff;
        }
        matr.createGradientBox(bounds.width, matrixHeight, (90 / 180) * Math.PI, 0, 0);
        //create the gradient fill
        gradientMask_mc.graphics.beginGradientFill(fillType, colors, alphas, ratios, matr, spreadMethod);
        gradientMask_mc.graphics.drawRect(0, 0, bounds.width, bounds.height);
        //position the mask over the reflection clip        
        gradientMask_mc.y=reflectionBMP.y - reflectionBMP.height;
        //cache clip as a bitmap so that the gradient mask will function
        gradientMask_mc.cacheAsBitmap=true;
        reflectionBMP.cacheAsBitmap=true;
        //set the mask for the reflection as the gradient mask
        reflectionBMP.mask=gradientMask_mc;
        //if we are updating the reflection for a video or animation do so here
        if (updateTime > -1)
        {
            timer = new Timer(updateTime);
            timer.addEventListener(TimerEvent.TIMER, onTimer, false, 0, true);
            timer.start();
        //updateInt=setInterval(update, updateTime, mc);
        }
    }

    function onTimer(event:TimerEvent):Void
    {
        update(mc);
    }    

    public function setBounds(w:Float, h:Float):Void
    {
        //allows the user to set the area that the reflection is allowed
        //this is useful for clips that move within themselves
        bounds.width=w;
        bounds.height=h;
        gradientMask_mc.width=bounds.width;
        redrawBMP(mc);
    }

    public function redrawBMP(mc:Sprite):Void
    {
        // redraws the bitmap reflection - Mim Gamiet [2006]
        mcBMP.dispose();
        mcBMP=new BitmapData(bounds.width, bounds.height, true, 0xFFFFFF);
        mcBMP.draw(mc);
    }

    private function update(mc:Sprite):Void
    {
        //updates the reflection to visually match the movie clip
        mcBMP=new BitmapData(bounds.width, bounds.height, true, 0xFFFFFF);
        mcBMP.draw(mc);
        reflectionBMP.bitmapData=mcBMP;
    }

    public function dispose():Void
    {
        //provides a method to remove the reflection
        mc.removeChild(reflectionBMP);
        reflectionBMP=null;
        mcBMP.dispose();
        if (timer != null)
        {
            timer.stop();
            timer.removeEventListener(TimerEvent.TIMER,onTimer);
            timer = null;
        }
        mc.removeChild(gradientMask_mc);
    }
}