package org.angle3d.core;

typedef BitmapInnerData =
	#if openfl
	openfl.display.BitmapData;
	#elseif js
	js.html.CanvasRenderingContext2D;
	#elseif lime
	lime.graphics.Image;
	#else
	BitmapInnerDataImpl;

class BitmapInnerDataImpl {
	#if hl
	public var pixels : hl.BytesAccess<Int>;
	#else
	public var pixels : haxe.ds.Vector<Int>;
	#end
	public var width : Int;
	public var height : Int;
	public function new() {
	}
}
	#end

class BitmapData {

	#if openfl
	static var tmpRect = new openfl.geom.Rectangle();
	static var tmpPoint = new openfl.geom.Point();
	static var tmpMatrix = new openfl.geom.Matrix();
	#end

	#if openfl
	var bmp : openfl.display.BitmapData;
	#elseif js
	var ctx : js.html.CanvasRenderingContext2D;
	var lockImage : js.html.ImageData;
	var pixel : js.html.ImageData;
	#else
	var data : BitmapInnerData;
	#end

	public var width(get, never) : Int;
	public var height(get, never) : Int;

	public function new(width:Int, height:Int) {
		if ( width == -101 && height == -102 ) {
			// no alloc
		} else {
			#if openfl
			bmp = new openfl.display.BitmapData(width, height, true, 0);
			#elseif js
			var canvas = js.Browser.document.createCanvasElement();
			canvas.width = width;
			canvas.height = height;
			ctx = canvas.getContext2d();
			#elseif lime
			data = new lime.graphics.Image( null, 0, 0, width, height );
			#else
			data = new BitmapInnerData();
			#if hl
			data.pixels = new hl.Bytes(width * height * 4);
			(data.pixels:hl.Bytes).fill(0, width * height * 4, 0);
			#else
			data.pixels = new haxe.ds.Vector(width * height);
			#end
			data.width = width;
			data.height = height;
			#end
		}
	}

	public function clear( color : Int ) {
		#if openfl
		bmp.fillRect(bmp.rect, color);
		#else
		fill(0, 0, width, height, color);
		#end
	}

	static inline function notImplemented() {
		throw "Not implemented";
	}

	public function fill( x : Int, y : Int, width : Int, height : Int, color : Int ) {
		#if openfl
		var r = tmpRect;
		r.x = x;
		r.y = y;
		r.width = width;
		r.height = height;
		bmp.fillRect(r, color);
		#elseif js
		ctx.fillStyle = 'rgba(${(color>>16)&0xFF}, ${(color>>8)&0xFF}, ${color&0xFF}, ${(color>>>24)/255})';
		ctx.fillRect(x, y, width, height);
		#else
		if ( x < 0 ) {
			width += x;
			x = 0;
		}
		if ( y < 0 ) {
			height += y;
			y = 0;
		}
		if ( x + width > data.width )
			width = data.width - x;
		if ( y + height > data.height )
			height = data.height - y;
		for ( dy in 0...height ) {
			var p = x + (y + dy) * data.width;
			for ( dx in 0...width ) {
				#if lime
				data.buffer.data[p++] = color;
				#else
				data.pixels[p++] = color;
				#end
			}
		}
		#end
	}

	public function line( x0 : Int, y0 : Int, x1 : Int, y1 : Int, color : Int ) {
		var dx = x1 - x0;
		var dy = y1 - y0;
		if ( dx == 0 ) {
			if ( y1 < y0 ) {
				var tmp = y0;
				y0 = y1;
				y1 = tmp;
			}
			for ( y in y0...y1 + 1 )
				setPixel(x0, y, color);
		} else if ( dy == 0 ) {
			if ( x1 < x0 ) {
				var tmp = x0;
				x0 = x1;
				x1 = tmp;
			}
			for ( x in x0...x1 + 1 )
				setPixel(x, y0, color);
		} else {
			throw "TODO : brensenham line";
		}
	}

	public inline function dispose() {
		#if openfl
		bmp.dispose();
		#elseif js
		ctx = null;
		pixel = null;
		#else
		data = null;
		#end
	}

	public function clone() {
		return sub(0,0,width,height);
	}

	public function sub( x, y, w, h ) : BitmapData {
		#if openfl
		var b = new openfl.display.BitmapData(w, h);
		b.copyPixels(bmp, new openfl.geom.Rectangle(x, y, w, h), new openfl.geom.Point(0, 0));
		return fromNative(b);
		#elseif js
		var canvas = js.Browser.document.createCanvasElement();
		canvas.width = w;
		canvas.height = h;
		var ctx = canvas.getContext2d();
		ctx.drawImage(this.ctx.canvas, x, y);
		return fromNative(ctx);
		#elseif lime
		notImplemented();
		return null;
		#else
		if ( x < 0 || y < 0 || w < 0 || h < 0 || x + w > width || y + h > height ) throw "Outside bounds";
		var b = new BitmapInnerData();
		b.width = w;
		b.height = h;
		#if hl
		b.pixels = new hl.Bytes(w * h * 4);
		for ( dy in 0...h )
			b.pixels.blit(dy * w, data.pixels, x + (y + dy) * width, w);
		#else
		b.pixels = new haxe.ds.Vector(w * h);
		for ( dy in 0...h )
			haxe.ds.Vector.blit(data.pixels, x + (y + dy) * width, b.pixels, dy * w, w);
		#end
		return fromNative(b);
		#end
	}

	/**
		Inform that we will perform several pixel operations on the BitmapData.
	**/
	public function lock () {
		#if js
		if ( lockImage == null )
			lockImage = ctx.getImageData(0, 0, width, height);
		#end
	}

	/**
		Inform that we have finished performing pixel operations on the BitmapData.
	**/
	public function unlock() {
		#if js
		if ( lockImage != null ) {
			ctx.putImageData(lockImage, 0, 0);
			lockImage = null;
		}
		#end
	}

	/**
		Access the pixel color value at the given position. Note : this function can be very slow if done many times and the BitmapData has not been locked.
	**/
	public #if openfl inline #end function getPixel( x : Int, y : Int ) : Int {
		#if openfl
			return bmp.getPixel32(x, y);
		#elseif js
			var i = lockImage;
			var a;
			if ( i != null ) {
				a = (x + y * i.width) << 2;
			else {
				a = 0;
				i = ctx.getImageData(x, y, 1, 1);
			}
			return (i.data[a] << 16) | (i.data[a|1] << 8) | i.data[a|2] | (i.data[a|3] << 24);
		#elseif lime
			return if ( x >= 0 && y >= 0 && x < data.width && y < data.height ) data.buffer.data[x + y * data.width] else 0;
		#else
			return if ( x >= 0 && y >= 0 && x < data.width && y < data.height ) data.pixels[x + y * data.width] else 0;
		#end
		}

		/**
			Modify the pixel color value at the given position. Note : this function can be very slow if done many times and the BitmapData has not been locked.
		**/
		public #if openfl inline #end function setPixel( x : Int, y : Int, c : Int ) {
			#if openfl
			bmp.setPixel32(x, y, c);
			#elseif js
			var i : js.html.ImageData = lockImage;
			if ( i != null ) {
				var a = (x + y * i.width) << 2;
				i.data[a] = (c >> 16) & 0xFF;
				i.data[a|1] = (c >> 8) & 0xFF;
				i.data[a|2] = c & 0xFF;
				i.data[a|3] = (c >>> 24) & 0xFF;
				return;
			}
			var i = pixel;
			if ( i == null ) {
				i = ctx.createImageData(1, 1);
				pixel = i;
			}
			i.data[0] = (c >> 16) & 0xFF;
			i.data[1] = (c >> 8) & 0xFF;
			i.data[2] = c & 0xFF;
			i.data[3] = (c >>> 24) & 0xFF;
			ctx.putImageData(i, x, y);
			#elseif lime
			if ( x >= 0 && y >= 0 && x < data.width && y < data.height ) data.buffer.data[x + y * data.width] = c;
			#else
			if ( x >= 0 && y >= 0 && x < data.width && y < data.height ) data.pixels[x + y * data.width] = c;
			#end
		}

	inline function get_width() : Int {
		#if openfl
		return bmp.width;
		#elseif js
		return ctx.canvas.width;
		#else
		return data.width;
		#end
	}

	inline function get_height() {
		#if openfl
		return bmp.height;
		#elseif js
		return ctx.canvas.height;
		#else
		return data.height;
		#end
	}

	public function getPixels() : Pixels {
		#if openfl
		var p = new Pixels(width, height, haxe.io.Bytes.ofData(bmp.getPixels(bmp.rect)), ARGB);
		p.flags.set(AlphaPremultiplied);
		return p;
		#elseif js
		var w = width;
		var h = height;
		var data = ctx.getImageData(0, 0, w, h).data;
		var pixels = data.buffer;
		return new Pixels(w, h, haxe.io.Bytes.ofData(pixels), RGBA);
		#elseif lime
		var p = new Pixels(width, height, this.data.data.buffer, RGBA);
		return p;
		#else
		var out = hxd.impl.Tmp.getBytes(data.width * data.height * 4);
		for ( i in 0...data.width*data.height )
			out.setInt32(i << 2, data.pixels[i]);
		return new Pixels(data.width, data.height, out, BGRA);
		#end
	}

	public function setPixels( pixels : Pixels ) {
		if ( pixels.width != width || pixels.height != height )
			throw "Invalid pixels size";
		pixels.setFlip(false);
		#if js
		var img = ctx.createImageData(pixels.width, pixels.height);
		pixels.convert(RGBA);
		for ( i in 0...pixels.width*pixels.height*4 ) img.data[i] = pixels.bytes.get(i);
		ctx.putImageData(img, 0, 0);
		#elseif openfl
		pixels.convert(BGRA);
		bmp.setPixels(bmp.rect, openfl.utils.ByteArray.fromBytes(pixels.bytes));
		#elseif lime
		// TODO format
		pixels.convert(BGRA);
		var src = pixels.bytes;
		var i = 0;
		for ( y in 0...height ) {
			for ( x in 0...width  ) {
				data.setPixel32( x, y, src.getInt32(i<<2) );
				i++;
			}
		}
		#else
		pixels.convert(BGRA);
		var src = pixels.bytes;
		for ( i in 0...width * height )
			data.pixels[i] = src.getInt32(i<<2);
		#end
	}

	public inline function toNative() : BitmapInnerData {
		#if openfl
		return bmp;
		#elseif js
		return ctx;
		#else
		return data;
		#end
	}

	public static function fromNative( data : BitmapInnerData ) : BitmapData {
		var b = new BitmapData( -101, -102 );
		#if openfl
		b.bmp = data;
		#elseif js
		b.ctx = data;
		#else
		b.data = data;
		#end
		return b;
	}

	public function toPNG() {
		var pixels = getPixels();
		var png = pixels.toPNG();
		pixels.dispose();
		return png;
	}

}