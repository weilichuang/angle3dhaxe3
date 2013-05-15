package org.angle3d.io.parser;

import flash.events.IEventDispatcher;
import flash.utils.ByteArray;

interface IParser extends IEventDispatcher
{
	function parse(data:ByteArray, options:ParserOptions):Bool;
}

