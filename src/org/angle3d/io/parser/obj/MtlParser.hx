package org.angle3d.io.parser.obj;
import flash.Vector;
import org.angle3d.io.parser.obj.MtlParser.MtlInfo;
import org.angle3d.material.Material;

class MtlInfo
{
	public var id:String;
	public var Ka:Float;
	public var Kd:Float;
	public var Ks:Float;
	public var Ke:Float;
	public var diffuseMap:String;
	public var bumpMap:String;
	public function new()
	{
		
	}
}

class MtlParser
{

	public function new() 
	{
		
	}
	
	public function parse(text:String):Vector<MtlInfo>
	{
		text = ~/\n{2,}/g.replace(text, "\n");
		
		var result:Vector<MtlInfo> = new Vector<MtlInfo>();
		
		var lines:Array<String> = text.split("\n");
		
		var info:MtlInfo = new MtlInfo();
		
		for (i in 0...lines.length) 
		{
			var line:String = lines[i];
			
			line = ~/\s{2,}/g.replace(line, " ");
			line = ~/\r/g.replace(line, "");
			line = StringTools.trim(line);
			
			var words:Array<String> = line.split(" ");
			
			if (words[0] == "newmtl") 
			{
				info = new MtlInfo();
				info.id = words[1];
				result.push(info);
			}
			else if (words[0] == "Ns")
			{
			}
			else if (words[0] == "d") 
			{
			}
			else if (words[0] == "illum") 
			{
			}
			else if (words[0] == "Ka") 
			{
				info.Ka = Std.parseFloat(words[1]);
			}
			else if (words[0] == "Kd") 
			{
				info.Kd = Std.parseFloat(words[1]);
			}
			else if (words[0] == "Ks") 
			{
				info.Ks = Std.parseFloat(words[1]);
			}
			else if (words[0] == "Ke") 
			{
				info.Ke = Std.parseFloat(words[1]);
			}
			else if (words[0] == "map_Ka") 
			{
			}
			else if (words[0] == "map_Kd") 
			{
				info.diffuseMap = StringTools.replace(words[1],"\\","/");
			}
			else if (words[0] == "map_d") 
			{
			}
			else if (words[0] == "map_bump") 
			{
				info.bumpMap = words[1];
			}
			else if (words[0] == "bump") 
			{
			}
		}
		
		return result;
	}
	
}