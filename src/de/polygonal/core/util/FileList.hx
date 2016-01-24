/*
Copyright (c) 2014 Michael Baczynski, http://www.polygonal.de

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
package de.polygonal.core.util;

#if macro
import haxe.ds.StringMap;
import haxe.macro.Context;
import haxe.macro.Expr;
import sys.FileSystem;
#end

class FileList
{
	macro public static function build(path:String):Array<Field>
	{
		var pos = Context.currentPos();
		
		path = ~/(\/|\\)$/.replace(path, "");
		
		if (!FileSystem.exists(path))
			Context.fatalError('directory "$path" does not exist.', pos);
		
		Context.registerModuleDependency(Std.string(Context.getLocalClass()), path);
		
		var scan = function(path:String):Array<String>
		{
			var files = [];
			var stack = [path];
			while (stack.length > 0)
			{
				path = stack.pop();
				if (FileSystem.isDirectory(path))
				{
					for (i in FileSystem.readDirectory(path))
						stack.push('$path/$i');
				}
				else
					files.push(path);
			}
			return files;
		}
		
		var makeIdent = function(x:String):String
		{
			x = ~/.+?\//.replace(x, ""); //strip root path
			x = ~/[^A-Za-z0-9]+/g.replace(x, "_"); //strip invalid characters
			return x;
		}
		
		var makeArrayField = function(name:String, values:Array<String>):Field
		{
			var a = [];
			for (i in values) a.push({expr: EConst(CString(i)), pos: pos});
			var f =
			{
				args: [],
				ret: TPath({name: "Array", pack: [], params: [TPType(TPath({name: "String", pack: [], params: [], sub: null}))], sub: null}),
				expr: {expr: EReturn({expr: EArrayDecl(a), pos: pos}), pos: pos},
				params: []
			}
			return {name: name, doc: null, meta: [], access: [APublic, AStatic, AInline], kind: FFun(f), pos: pos};
		}
		
		var fields = Context.getBuildFields();
		var all = [];
		var files = scan(path);
		for (file in files)
		{
			if (!~/(?<=\.)[a-zA-Z0-9]{3,4}/.match(file)) continue;
			
			fields.push
			({
				name: makeIdent(file), doc: null, meta: [], access: [APublic, AStatic, AInline],
				kind: FVar(TPath({pack: [], name: "String", params: [], sub: null}), {expr: EConst(CString(file)), pos: pos}), pos: pos
			});
			all.push(file);
		}
		
		//all files
		fields.push(makeArrayField("all", all));
		
		fields.push
		({
			name: "path", doc: null, meta: [], access: [APublic, AStatic, AInline], pos: pos,
			kind: FVar(TPath({pack: [], name: "String", params: [], sub: null}), {expr: EConst(CString(path)), pos: pos})
		});
		
		//detect file sequences
		var matchCounter = new EReg('\\d\\d?', 'g');
		var matchExt = new EReg('\\.\\S{3,4}', 'g');
		var map = new StringMap<Array<String>>();
		
		var files = scan(path);
		for (file in files)
		{
			if (!~/(?<=\.)[a-zA-Z0-9]{3,4}/.match(file)) continue;
			
			if (matchCounter.match(file))
			{
				var key = matchCounter.matchedLeft();
				
				matchExt.match(matchCounter.matchedRight());
				
				var key = matchCounter.matchedLeft() + 'Nxxx' + matchExt.matched(0);
				var pos = Std.parseInt(matchCounter.matched(0));
				
				if (map.exists(key))
					map.get(key)[pos] = file;
				else
				{
					var a = [];
					a[pos] = file;
					map.set(key, a);
				}
			}
		}
		
		//remove key with incomplete sequence [0, 1, null, 2, null]...
		for (key in map.keys())
		{
			for (i in map.get(key))
			{
				if (i == null)
				{
					map.remove(key);
					break;
				}
			}
		}
		
		for (key in map.keys())
			fields.push(makeArrayField(makeIdent(key), map.get(key)));
		
		return fields;
	}
}