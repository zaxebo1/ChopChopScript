package chopchop.ast;

import chopchop.ast.AccessField.Access;
import chopchop.Symbol;
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
	
	override public function walk(I:ChopInterp):Dynamic 
	{
		Reflect.setField(left, "isValue", false);
		var l:Access = cast left.walk(I);
		Reflect.setProperty(l.oldValue, l.newName, right.walk(I));
		
		return null;
	}
}