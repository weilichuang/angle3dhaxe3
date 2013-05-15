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
package hu.vpmedia.utils;

class KeyCodes 
{         
    public static inline var KEY_BACKSPACE:Int = 8;
    public static inline var KEY_ENTER:Int = 13;
    
    public static inline var KEY_SHIFT:Int = 16;
    public static inline var KEY_CONTROL:Int = 17;
    
    public static inline var KEY_ESC:Int = 27;
    
    public static inline var KEY_SPACE:Int = 32;
    public static inline var KEY_PGUP:Int = 33;
    public static inline var KEY_PGDN:Int = 34;
    public static inline var KEY_END:Int = 35;
    public static inline var KEY_HOME:Int = 36;
    public static inline var KEY_LEFT:Int = 37;
    public static inline var KEY_UP:Int = 38;
    public static inline var KEY_RIGHT:Int = 39;
    public static inline var KEY_DOWN:Int = 40;
    
    public static inline var KEY_DELETE:Int = 46;
    public static inline var KEY_INSERT:Int = 45;
    
    public static inline var KEY_0:Int = 48;
    public static inline var KEY_1:Int = 49;
    public static inline var KEY_2:Int = 50;
    public static inline var KEY_3:Int = 51;
    public static inline var KEY_4:Int = 52;
    public static inline var KEY_5:Int = 53;
    public static inline var KEY_6:Int = 54;
    public static inline var KEY_7:Int = 55;
    public static inline var KEY_8:Int = 56;
    public static inline var KEY_9:Int = 57;

    #if flash
    public static inline var KEY_A:Int = 65;
    public static inline var KEY_B:Int = 66;
    public static inline var KEY_C:Int = 67;
    public static inline var KEY_D:Int = 68;
    public static inline var KEY_E:Int = 69;
    public static inline var KEY_F:Int = 70;
    public static inline var KEY_G:Int = 71;
    public static inline var KEY_H:Int = 72;
    public static inline var KEY_I:Int = 73;
    public static inline var KEY_J:Int = 74;
    public static inline var KEY_K:Int = 75;
    public static inline var KEY_L:Int = 76;
    public static inline var KEY_M:Int = 77;
    public static inline var KEY_N:Int = 78;
    public static inline var KEY_O:Int = 79;
    public static inline var KEY_P:Int = 80;
    public static inline var KEY_Q:Int = 81;
    public static inline var KEY_R:Int = 82;
    public static inline var KEY_S:Int = 83;
    public static inline var KEY_T:Int = 84;
    public static inline var KEY_U:Int = 85;
    public static inline var KEY_V:Int = 86;
    public static inline var KEY_W:Int = 87;
    public static inline var KEY_X:Int = 88;
    public static inline var KEY_Y:Int = 89;
    public static inline var KEY_Z:Int = 90;
    
    public static inline var KEY_F1:Int = 112;
    public static inline var KEY_F2:Int = 113;
    public static inline var KEY_F3:Int = 114;
    public static inline var KEY_F4:Int = 115;
    public static inline var KEY_F5:Int = 116;
    public static inline var KEY_F6:Int = 117;
    public static inline var KEY_F7:Int = 118;
    public static inline var KEY_F8:Int = 119;     
  #else         
  public static inline var KEY_A:Int = 97;
    public static inline var KEY_B:Int = 98;
    public static inline var KEY_C:Int = 99;
    public static inline var KEY_D:Int = 100;
    public static inline var KEY_E:Int = 101;
    public static inline var KEY_F:Int = 102;
    public static inline var KEY_G:Int = 103;
    public static inline var KEY_H:Int = 104;
    public static inline var KEY_I:Int = 105;
    public static inline var KEY_J:Int = 106;
    public static inline var KEY_K:Int = 107;
    public static inline var KEY_L:Int = 108;
    public static inline var KEY_M:Int = 109;
    public static inline var KEY_N:Int = 110;
    public static inline var KEY_O:Int = 111;
    public static inline var KEY_P:Int = 112;
    public static inline var KEY_Q:Int = 113;
    public static inline var KEY_R:Int = 114;
    public static inline var KEY_S:Int = 115;
    public static inline var KEY_T:Int = 116;
    public static inline var KEY_U:Int = 117;
    public static inline var KEY_V:Int = 118;
    public static inline var KEY_W:Int = 119;
    public static inline var KEY_X:Int = 120;
    public static inline var KEY_Y:Int = 121;
    public static inline var KEY_Z:Int = 122;      
  #end

}