package org.angle3d.material.sgsl.error;

import flash.errors.Error;
import org.angle3d.material.sgsl.parser.Token;
import org.angle3d.material.sgsl.parser.TokenType;

class UnexpectedTokenError extends Error
{
	public function new(tok:Token = null, expected:String = null)
	{
		if (tok == null)
			tok = new Token(TokenType.NONE, "<NONE>");
		var msg:String = "Unexpected token " + tok.type;
		if (expected != null)
			msg += ", expected " + expected;

		super(msg);
	}

}


