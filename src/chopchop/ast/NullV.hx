package chopchop.ast;

import chopchop.Token;

/**
 * ...
 * @author Ohmnivore
 */
class NullV extends AST
{
	public function new(T:Token, Children:Array<AST>) 
	{
		super(T, Children);
	}
	
	override public function walk(I:ChopInterp):Dynamic 
	{
		return null;
	}
}