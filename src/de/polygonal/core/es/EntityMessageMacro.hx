/*
Copyright (c) 2012-2014 Michael Baczynski, http://www.polygonal.de

Permission is hereby granted, free of charge, to any person obtaining a copy of this software and
associated documentation files (the "Software"), to deal in the Software without restriction,
including without limitation the rights to use, copy, modify, merge, publish, distribute,
sublicense, and/or sell copies of the Software, and to permit persons to whom the Software is
furnished to do so, subject to the following conditions:

The above copyright notice and this permission notice shall be included in all copies or
substantial portions of the Software.

THE SOFTWARE IS PROVIDED "AS IS", WITHOUT WARRANTY OF ANY KIND, EXPRESS OR IMPLIED, INCLUDING BUT
NOT LIMITED TO THE WARRANTIES OF MERCHANTABILITY, FITNESS FOR A PARTICULAR PURPOSE AND
NONINFRINGEMENT. IN NO EVENT SHALL THE AUTHORS OR COPYRIGHT HOLDERS BE LIABLE FOR ANY CLAIM,
DAMAGES OR OTHER LIABILITY, WHETHER IN AN ACTION OF CONTRACT, TORT OR OTHERWISE, ARISING FROM, OUT
OF OR IN CONNECTION WITH THE SOFTWARE OR THE USE OR OTHER DEALINGS IN THE SOFTWARE.
*/
package de.polygonal.core.es;
import sys.FileSystem;
import sys.io.File;

#if macro
import haxe.macro.Context;
import haxe.macro.Expr;
#end

/**
	Helper macro generating unique message ids
	
	Example:
	
	<pre>
	@:build(de.polygonal.core.es.EntityMessageMacro.build([MSG1, MSG2, MSG3]))
	class MyMessages {}<br/>
	@:build(de.polygonal.core.es.EntityMessageMacro.build([MSG1, MSG2]))
	class MyOtherMessages {}
	</pre>
	
	Result:
	
	<pre>
	class MyMessages
	{
	    inline public static var MSG1:Int = 1;
	    inline public static var MSG2:Int = 2;
	    inline public static var MSG3:Int = 3;
	}
	
	class MyOtherMessages
	{
	    inline public static var MSG1:Int = 4;
	    inline public static var MSG2:Int = 5;
	}
	</pre>
**/
class EntityMessageMacro
{
	#if macro
	inline public static var FILE = ".de.polygonal.core.es.msg_macro";
	#end
	
	macro static function build(e:Expr):Array<Field>
	{
		var p = Context.currentPos();
		var fields = Context.getBuildFields();
		var module = Context.getLocalClass().get().module;
		
		function getNext(ident:String):Int
		{
			ident = '$module.$ident';
			var next = 0;
			var c = 0;
			if (FileSystem.exists(FILE))
			{
				var s = File.getContent(FILE);
				var exists = false;
				var a = s.split("\n");
				for (i in a)
				{
					if (i == ident)
					{
						exists = true;
						next = c;
						break;
					}
					c++;
				}
				if (!exists)
				{
					File.saveContent(FILE, s + '\n$ident');
					next = c;
				}
			}
			else
				File.saveContent(FILE, ident);
			return next;
		}
		
		switch (e.expr)
		{
			case EArrayDecl(a):
				for (b in a)
				{
					switch (b.expr)
					{
						case EConst(c):
							switch (c)
							{
								case CIdent(d):
									var next = getNext(d);
									if (next > 0x7FFF) Context.fatalError("message type out of range [0, 0x7FFF]", p);
									fields.push
									({
										name: d,
										doc: 'A global unique id that identifies messages of type $d.',
										meta: [],
										access: [AStatic, APublic, AInline],
										kind: FVar(TPath({pack: [], name: "Int", params: [], sub: null}), {expr: EConst(CInt(Std.string(next))), pos: p}),
										pos: p
									});
									
								case _: Context.error("unsupported declaration", p);
							}
						case _: Context.error("unsupported declaration", p);
					}
				}
			case _: Context.error("unsupported declaration", p);
		}
		
		return fields;
	}
	
	macro static function addMeta():Array<Field>
	{
		var p = Context.currentPos();
		Context.onGenerate(function(_)
		{
			switch (Context.getModule("de.polygonal.core.es.EntityMessage")[0])
			{
				case TInst(t, params):
					if (!FileSystem.exists(FILE)) return;
					var s = File.getContent(FILE);
					var a = [];
					for (name in s.split("\n"))
						a.push({expr: EConst(CString(name)), pos: p});
					var ct = t.get();
					if (ct.meta.has("names")) ct.meta.remove("names");
					if (ct.meta.has("count")) ct.meta.remove("count");
					
					if (Context.defined("debug"))
						ct.meta.add("names", [{expr: EArrayDecl(a), pos: p}], p);
					ct.meta.add("count", [{expr: EConst(CString(Std.string(a.length))), pos: p}], p);
				case _:
			}
		});
		
		return Context.getBuildFields();
	}
}