package chopchop.ast;

import chopchop.Token;

/**
 * ...
 * @author Ohmnivore
 */
class Assign extends BinAST
{

	public function new(T:Token, Children:Array<AST>) 
	{
		super(T, Children);
		
	}
	
}