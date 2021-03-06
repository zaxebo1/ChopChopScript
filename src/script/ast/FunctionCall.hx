package script.ast;
import script.ScriptInterp;
import script.Symbol;

/**
 * ...
 * @author Ohmnivore
 */
class FunctionCall extends AST
{
	public function new(Text:String, Children:Array<AST>) 
	{
		super(Text, Children);
		canNest = true;
	}
	
	public function walkFuncAccess(I:ScriptInterp, Par:Access):Dynamic
	{
		return callFunction(I, Par.getVal());
	}
	public function walkFuncDirect(I:ScriptInterp, Par:AST):Dynamic
	{
		return callFunction(I, Par.walk(I));
	}
	private function callFunction(I:ScriptInterp, Obj:Dynamic):Dynamic
	{
		var args:Array<Dynamic> = [];
		for (arg in children)
		{
			args.push(arg.walk(I));
		}
		
		return Reflect.callMethod(Obj, Reflect.field(Obj, text), args);
	}
	
	override public function walk(I:ScriptInterp):Dynamic 
	{
		var funcName:String = text;
		var func:Dynamic = I.curScope.resolve(text).value;
		
		if (Std.is(func, FunctionDef))
		{
			var funcDef:FunctionDef = cast func;
			return funcDef.callFunction(I, children);
		}
		else
		{
			var args:Array<Dynamic> = [];
			for (arg in children)
			{
				args.push(arg.walk(I));
			}
			return Reflect.callMethod(null, func, args);
		}
	}
}