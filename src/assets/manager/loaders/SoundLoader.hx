package assets.manager.loaders;
import assets.manager.misc.FileType;
import flash.net.URLLoaderDataFormat;
import flash.media.Sound;


class SoundLoader extends BaseLoader
{
	
    public function new(id:String) {
		super(id, FileType.SOUND);
		loader.dataFormat = URLLoaderDataFormat.BINARY;
    }

	override public function processData():Void {
		var sound = new Sound();
		sound.loadCompressedDataFromByteArray(loader.data, loader.data.length);
		data = sound;
	}
	
}
