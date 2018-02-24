package angle3d.io.parser.max3ds;


class Max3DSMaterialParser extends AbstractMax3DSParser
{
	private var _name:String = null;
	private var _textureFilename:String = null;
	
	public var name(get, null):String;
	public var textureFilename(get, null):String;

	public function new(chunk:Max3DSChunk)
	{
		super(chunk);
	}

	private function get_name():String
	{
		return _name;
	}

	private function get_textureFilename():String
	{
		return _textureFilename;
	}

	override private function initialize():Void
	{
		super.initialize();

		parseFunctions[Max3DSChunk.MATERIAL] = enterChunk;
		parseFunctions[Max3DSChunk.MATERIAL_NAME] = parseName;
		parseFunctions[Max3DSChunk.MATERIAL_TEXMAP] = enterChunk;
		parseFunctions[Max3DSChunk.MATERIAL_MAPNAME] = parseTextureFilename;
	}

	private function parseName(chunk:Max3DSChunk):Void
	{
		_name = chunk.readString();
	}

	private function parseTextureFilename(chunk:Max3DSChunk):Void
	{
		_textureFilename = chunk.readString();
	}

}
