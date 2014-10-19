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
package hu.vpmedia.math;

import flash.geom.Matrix;
import flash.geom.Point;
/**
 * 2D vector class
 */
class Vector2D
{
public static var RAD_TO_DEG:Float=180 / Math.PI; //57.29577951;
public static var DEG_TO_RAD:Float=Math.PI / 180;

public var y:Float;
public var x:Float;

public static var Epsilon:Float = 0.0000001;
public static var EpsilonSqr:Float = Epsilon * Epsilon;

/**
 * Constructor
 */
public function new(?x:Float=0, ?y:Float=0)
{
    this.x=x;
    this.y=y;
}

/**
 * Creates an exact copy of this Vector2D
 * @return Vector2D A copy of this Vector2D
 */
public function clone():Vector2D
{
    return new Vector2D(x, y);
}

/**
 * Creates an exact copy of this Vector2D
 * @return Vector2D A copy of this Vector2D
 */
public function copy():Vector2D
{
    return clone();
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function set(vector2:Vector2D):Vector2D
{
    x = vector2.x;
    y = vector2.y;
    return this;
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function setXY(x2:Float, y2:Float):Vector2D
{
    x = x2;
    y = y2;
    return this;
}

/**
 *  Transforms Vector2D based on the given Matrix
 * @param matrix The matrix to use to transform this vector.
 * @return Vector2D returns a new, transformed Vector2D.
 */
public function transform(matrix:Matrix):Vector2D
{
    var v:Vector2D=clone();
    v.x=x * matrix.a + y * matrix.c + matrix.tx;
    v.y=x * matrix.b + y * matrix.d + matrix.ty;
    return v;
}

/**
 * Makes x and y zero.
 * @return Vector2D This vector.
 */
public function zero():Vector2D
{
    x=0;
    y=0;
    return this;
}

/**
 * Is this vector zeroed?
 * @return Bool Returns true if zeroed, else returns false.
 */
public function isZero():Bool
{
    return x == 0 && y == 0;
}

/**
 * Is the vector's length = 1?
 * @return Bool If length is 1, true, else false.
 */
public function isNormalizedPrecise():Bool
{
    return getLength() == 1.0;
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function isNormalized():Bool
{ 
    return Math.abs(getLengthSquared() - 1) < EpsilonSqr; 
}

/**
 * Does this vector have the same location as another?
 * @param vector2 The vector to test.
 * @return Bool True if equal, false if not.
 */
public function equals(vector2:Vector2D):Bool
{
    return x == vector2.x && y == vector2.y;
}

/**
 * Does this vector have the same location as another?
 * @param vector2 The vector to test.
 * @return Bool True if equal, false if not.
 */
public function equalsXY(x2:Float, y2:Float):Bool
{
    return x == x2 && y == y2;
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function isNear(vec2:Vector2D):Bool 
{ 
    return distSQ(vec2) < EpsilonSqr; 
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function isNearXY(x2:Float, y2:Float):Bool 
{ 
    return distSQXY(x, y) < EpsilonSqr; 
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function isWithin(vec2:Vector2D, epsilon:Float):Bool 
{ 
    return distSQ(vec2) < epsilon * epsilon; 
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function isWithinXY(x2:Float, y2:Float, epsilon:Float):Bool 
{ 
    return distSQXY(x2, y2) < epsilon * epsilon; 
}

/**
 * Returns the length of the vector.
 **/
public function getLength():Float
{
    return Mathematics.sqrt(getLengthSquared());
}

/**
 * Sets the length which will change x and y, but not the angle.
 */
public function setLength(value:Float):Void
{
    var _angle:Float=getAngle();
    x=Math.cos(_angle) * value;
    y=Math.sin(_angle) * value;
    if (Math.abs(x) < 0.00000001)
    x=0;
    if (Math.abs(y) < 0.00000001)
    y=0;
}

/**
 * Returns the length of this vector, before square root. Allows for a faster check.
 */
public function getLengthSquared():Float
{
    return x * x + y * y;
}

/**
 * Changes the angle of the vector. X and Y will change, length stays the same.
 */
public function setAngle(value:Float):Void
{
    var len:Float=getLength();
    x=Math.cos(value) * len;
    y=Math.sin(value) * len;
}

/**
 * Get the angle of this vector (radians).
 **/
public function getAngle():Float
{
    return Math.atan2(y, x);
}

/**
 * Get the rotation of this vector (degrees).
 **/
public function getRotation():Float
{
    return getAngle() * RAD_TO_DEG;
}

/**
 * Sets the vector's length to 1.
 * @return Vector2D This vector.
 */
public function normalize():Vector2D
{
    if (getLength() == 0)
    {
    x=1;
    return this;
    }
    var len:Float=getLength();
    x/=len;
    y/=len;
    return this;
}

/**
 * Sets the vector's length to len.
 * @param len The length to set it to.
 * @return Vector2D This vector.
 */
public function normalcate(len:Float):Vector2D
{
    setLength(len);
    return this;
}

/**
 * Sets the length under the given value. Nothing is done if the vector is already shorter.
 * @param max The max length this vector can be.
 * @return Vector2D This vector.
 */
public function truncate(max:Float):Vector2D
{
    setLength(Math.min(max, getLength()));
    return this;
}

/**
 * Makes the vector face the opposite way.
 * @return Vector2D This vector.
 */
public function reverse():Vector2D
{
    x=-x;
    y=-y;
    return this;
}

/**
 * Calculate the dot product of this vector and another.
 * @param vector2 Another vector2D.
 * @return Number The dot product.
 */
public function dotProduct(vector2:Vector2D):Float
{
    return x * vector2.x + y * vector2.y;
}

/**
 * Calculate the cross product of this and another vector.
 * @param vector2 Another Vector2D.
 * @return Number The cross product.
 */
public function crossProd(vector2:Vector2D):Float
{
    return x * vector2.y - y * vector2.x;
}

/**
 * Calculate angle between any two vectors.
 * @param vector1 First vector2d.
 * @param vector2 Second vector2d.
 * @return Number Angle between vectors.
 */
public static function angleBetween(vector1:Vector2D, vector2:Vector2D):Float
{
    if (!vector1.isNormalized())
    vector1=vector1.clone().normalize();
    if (!vector2.isNormalized())
    vector2=vector2.clone().normalize();
    return Math.acos(vector1.dotProduct(vector2));
}

/**
 * Is the vector to the right or left of this one?
 * @param vector2 The vector to test.
 * @return Bool If left, returns true, if right, false.
 */
public function sign(vector2:Vector2D):Int
{
    return getPerpendicular().dotProduct(vector2) < 0 ? -1 : 1;
}

/**
 * Get the vector that is perpendicular.
 * @return Vector2D The perpendicular vector.
 */
public function getPerpendicular():Vector2D
{
    return new Vector2D(-y, x);
}

/**
 * Calculate between two vectors.
 * @param vector2 The vector to find distance.
 * @return Number The distance.
 */
public function distance(vector2:Vector2D):Float
{
    return Mathematics.sqrt(distSQ(vector2));
}

/**
 * Calculate between two vectors.
 * @param vector2 The vector to find distance.
 * @return Number The distance.
 */
public function distanceXY(x2:Float, y2:Float):Float
{
    return Mathematics.sqrt(distSQXY(x2, y2));
}

/**
 * Calculate squared distance between vectors. Faster than distance.
 * @param vector2 The other vector.
 * @return Number The squared distance between the vectors.
 */
public function distSQ(vector2:Vector2D):Float
{
    var dx:Float=vector2.x - x;
    var dy:Float=vector2.y - y;
    return dx * dx + dy * dy;
}

/**
 * Calculate squared distance between vectors. Faster than distance.
 * @param vector2 The other vector.
 * @return Number The squared distance between the vectors.
 */
public function distSQXY(x2:Float, y2:Float):Float
{
    var dx:Float=x2 - x;
    var dy:Float=y2 - y;
    return dx * dx + dy * dy;
}

/**
 * Add a vector to this vector.
 * @param vector2 The vector to add to this one.
 * @return Vector2D This vector.
 */
public function add(vector2:Vector2D):Vector2D
{
    x+=vector2.x;
    y+=vector2.y;
    return this;
}

/**
 * Add a vector to this vector.
 * @param vector2 The vector to add to this one.
 * @return Vector2D This vector.
 */
public function addXY(x2:Float,y2:Float):Vector2D
{
    x+=x2;
    y+=y2;
    return this;
}

/**
 * Subtract a vector from this one.
 * @param vector2 The vector to subtract.
 * @return Vector2D This vector.
 */
public function subtract(vector2:Vector2D):Vector2D
{
    x-=vector2.x;
    y-=vector2.y;
    return this;
}
/**
 * Subtract a vector from this one.
 * @param vector2 The vector to subtract.
 * @return Vector2D This vector.
 */
public function subtractXY(x2:Float,y2:Float):Vector2D
{
    x-=x2;
    y-=y2;
    return this;
}

/**
 * Mutiplies this vector by another one.
 * @param scalar The scalar to multiply by.
 * @return Vector2D This vector, multiplied.
 */
public function multiply(vector2:Vector2D):Vector2D
{
    x*=vector2.x;
    y*=vector2.y;
    return this;
}

/**
 * Mutiplies this vector by another one.
 * @param scalar The scalar to multiply by.
 * @return Vector2D This vector, multiplied.
 */
public function multiplyXY(x2:Float,y2:Float):Vector2D
{
    x*=x2;
    y*=y2;
    return this;
}

/**
 * Mutiplies this vector by another one.
 * @param scalar The scalar to multiply by.
 * @return Vector2D This vector, multiplied.
 */
public function multiplyScalar(scalar:Float):Vector2D
{
    x*=scalar;
    y*=scalar;
    return this;
}

/**
 * Divide this vector by a scalar.
 * @param scalar The scalar to divide by.
 * @return Vector2D This vector.
 */
public function divide(vector2:Vector2D):Vector2D
{
    x/=vector2.x;
    y/=vector2.y;
    return this;
}

/**
 * Divide this vector by a scalar.
 * @param scalar The scalar to divide by.
 * @return Vector2D This vector.
 */
public function divideXY(x2:Float,y2:Float):Vector2D
{
    x/=x2;
    y/=y2;
    return this;
}

/**
 * Divide this vector by a scalar.
 * @param scalar The scalar to divide by.
 * @return Vector2D This vector.
 */
public function divideScalar(scalar:Float):Vector2D
{
    x/=scalar;
    y/=scalar;
    return this;
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function reflect(normal:Vector2D):Vector2D
{
    var d = dotProduct(normal);
    var nx = x - 2 * d * normal.x;
    var ny = y - 2 * d * normal.y;
    x = nx;
    y = ny;
    return this;
}

/**
 * Rotate
 */
public function rotate(rads:Float):Vector2D
{
    var s:Float = Math.sin(rads);
    var c:Float = Math.cos(rads);
    var xr:Float = x * c - y * s;
    y = x * s + y * c;
    x = xr;
    return this;
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function normalRight():Vector2D
{
    var xr:Float = x;
    x = -y;
    y = xr;
    return this;
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function normalLeft():Vector2D
{
    var xr:Float = x;
    x = y;
    y = -xr;
    return this;
}

/**
 * TBD
 * @return Vector2D This vector 
 */
public function negate():Vector2D
{
    x = -x;
    y = -y;
    return this;
}

/**
 * Turn this vector into a string.
 * @return String This vector in string form.
 */
public function toString():String
{
    return "Vector2D x:" + x + ", y:" + y;
}
}