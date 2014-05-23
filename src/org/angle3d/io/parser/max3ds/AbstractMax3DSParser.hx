package org.angle3d.io.parser.max3ds;

import flash.events.EventDispatcher;

class AbstractMax3DSParser
{
	public var parseFunctions(get, null):Array < Max3DSChunk->Void > ;
	
	private var _functions:Array<Max3DSChunk->Void>;

	public function new(chunk:Max3DSChunk = null)
	{
		initialize();

		if (chunk != null)
			parseChunk(chunk);
	}

	private function initialize():Void
	{
		_functions = [];
	}

	
	private function get_parseFunctions():Array<Max3DSChunk->Void>
	{
		return _functions;
	}

	private function finalize():Void
	{
		// NOTHING
	}

	private function parseChunk(chunk:Max3DSChunk):Void
	{
		var parseFunction:Max3DSChunk->Void = null;

		parseFunction = _functions[chunk.identifier];

		if (parseFunction == null)
		{
			chunk.skip();

			return;
		}

		parseFunction(chunk);

		enterChunk(chunk);

		finalize();
	}

	private function enterChunk(chunk:Max3DSChunk):Void
	{
		while (chunk.bytesAvailable > 0)
		{
			var innerChunk:Max3DSChunk = new Max3DSChunk(chunk.data);

			var parseFunction:Max3DSChunk->Void = _functions[innerChunk.identifier];
			if (parseFunction == null)
			{
				innerChunk.skip();
			}
			else if (parseFunction != enterChunk)
			{
				parseFunction(innerChunk);
			}
		}
	}

}
