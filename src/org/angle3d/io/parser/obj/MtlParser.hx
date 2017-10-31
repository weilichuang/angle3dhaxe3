package org.angle3d.io.parser.obj;

import org.angle3d.io.parser.obj.MtlParser.MtlInfo;
import org.angle3d.material.Material;
import org.angle3d.math.Color;

class MtlInfo
{
	public var id:String;
	public var ambient:Color = new Color(1,1,1);
	public var diffuse:Color = new Color(1,1,1);
	public var specular:Color = new Color(1,1,1);
	public var alpha:Float = 1;
	public var ambientMap:String;
	public var diffuseMap:String;
	public var bumpMap:String;
	public var alphaMap:String;
	public var shininess:Float = 0;
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
			
			if (words[0].toLowerCase() == "newmtl") 
			{
				info = new MtlInfo();
				info.id = words[1];
				result.push(info);
			}
			else if (words[0].toLowerCase() == "ns")
			{
				info.shininess = Std.parseFloat(words[1]);
			}
			else if (words[0].toLowerCase() == "d") 
			{
				info.alpha = Std.parseFloat(words[1]);
			}
			else if (words[0].toLowerCase() == "illum") 
			{
			}
			else if (words[0].toLowerCase() == "ka") 
			{
				info.ambient = new Color(Std.parseFloat(words[1]),Std.parseFloat(words[2]),Std.parseFloat(words[3]));
			}
			else if (words[0].toLowerCase() == "kd") 
			{
				info.diffuse = new Color(Std.parseFloat(words[1]),Std.parseFloat(words[2]),Std.parseFloat(words[3]));
			}
			else if (words[0].toLowerCase() == "ks") 
			{
				info.specular = new Color(Std.parseFloat(words[1]),Std.parseFloat(words[2]),Std.parseFloat(words[3]));
			}
			else if (words[0].toLowerCase() == "ke") 
			{
				//info.Ke = Std.parseFloat(words[1]);
			}
			else if (words[0].toLowerCase() == "map_ka") 
			{
				info.ambientMap = StringTools.replace(words[1], "\\", "/");
			}
			else if (words[0].toLowerCase() == "map_kd") 
			{
				info.diffuseMap = StringTools.replace(words[1],"\\","/");
			}
			else if (words[0].toLowerCase() == "map_d") 
			{
				info.alphaMap = StringTools.replace(words[1],"\\","/");
			}
			else if (words[0].toLowerCase() == "map_bump" || words[0] == "bump") 
			{
				info.bumpMap = StringTools.replace(words[1],"\\","/");
			}
		}
		
		return result;
	}
	
}