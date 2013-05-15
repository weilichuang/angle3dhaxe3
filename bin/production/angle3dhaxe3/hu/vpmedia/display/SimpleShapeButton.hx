////////////////////////////////////////////////////////////////////////////////
//=BEGIN LICENSE MIT
//
// Copyright (c) 2012, Original author & contributors
// Original author : Andras Csizmadia -  http://www.vpmedia.eu
// Contributors: -
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

  import flash.display.Graphics;
  import flash.display.Shape;
  import flash.display.SimpleButton;
  
  class SimpleShapeButton extends SimpleButton
  {
      public function new(width:Float, height:Float, ?ellipse:Float=0, ?alpha:Float=0, ?color:Int=0x00FF00)
      {
          var hitTestShape:Shape=new Shape();
          var hitTestGraphics:Graphics=hitTestShape.graphics;
          hitTestGraphics.beginFill(color, alpha);
          hitTestGraphics.drawRoundRect(0, 0, width, height, ellipse);
          hitTestGraphics.endFill();
          this.useHandCursor=false;
          super(null, null, null, hitTestShape);
      }
  }

