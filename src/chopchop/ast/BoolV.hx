package chopchop.ast;

import chopchop.ChopInterp;
import chopchop.Token;

/**
 * ...
 * @author Ohmnivore
 */
class BoolV extends ConstAST
{
	public function new(T:Token, Children:Array<AST>) 
	{
		super(T, Children);
	}
	
	override function setValue():Void 
	{
		if (token.text == "true")
			value = true;
		else
			value = false;
	}
}