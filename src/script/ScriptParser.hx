package script;
import script.ast.*;

class ScriptParser extends Parser
{
	public var lexer:ScriptLexer;
	public var ast:Array<AST> = [];
	private var nestLVL:Int = 0;
	private var inNest:Class<AST>;
	
	public function new(Input:ScriptLexer) 
	{
		lexer = Input;
		super(Input, 4);
        
        var operator:AST = Type.createInstance(script.ast.Assign, ["=", []]);
	}
	
	public function parse():Array<AST>
	{
		nestLVL = 0;
		inNest = null;
		ast = makeAST(Lexer.EOF);
		return ast;
	}
	
	public function makeAST(Until:Int):Array<AST>
	{
		var ret:Array<AST> = [];
		while (LA(1) != Until && LA(1) != Lexer.EOF)
		{
			var t:Int = LA(1);
			var tok:Token = LT(1);
			var t2:Int = LA(2);
			var tok2:Token = LT(2);
			var t3:Int = LA(3);
			var tok3:Token = LT(3);
			
            //if (t == ScriptLexer.OPEN_CURLY || t == ScriptLexer.CLOSE_CURLY ||
				//t == ScriptLexer.OPEN_PAR || t == ScriptLexer.CLOSE_PAR)
			//{
				//
			//}
			//else
			//{
				ret.push(parseExpr(ScriptLexer.SEMI_COLON));
				if (Until == ScriptLexer.SEMI_COLON)
					return ret;
			//}
			consume();
		}
		
		return ret;
	}
	private function matchPrefix(IsFirst:Bool, T:Int, T2:Int, What:Int):Bool
	{
		if (IsFirst && T == What)
			return true;
		else if (T2 != What)
			return false;
		else if (T != ScriptLexer.INT && T != ScriptLexer.FLOAT && T != ScriptLexer.VARIABLE && T != ScriptLexer.FLOAT
			&& T != ScriptLexer.CLOSE_PAR)
		{
			return true;
		}
		return false;
	}
	public function parseExpr(Until:Int):AST
	{
		var operatorStack:Stack<AST> = new Stack<AST>();
		var operandStack:Stack<AST> = new Stack<AST>();
		var first:Bool = true;
		
		while (!(LA(1) == Until && nestLVL == 0) && LA(1) != Lexer.EOF)
		{
			var t:Int = LA(1);
			var tok:Token = LT(1);
			var t2:Int = LA(2);
			var tok2:Token = LT(2);
			var t3:Int = LA(3);
			var tok3:Token = LT(3);
			
			if (nestLVL == 2 && t == ScriptLexer.SEMI_COLON && t2 == ScriptLexer.CLOSE_CURLY && t3 != ScriptLexer.ELSE)
			{
				parseSimple(operatorStack, operandStack);
				handleClosePar(ParClose, tok2.text, operatorStack, operandStack);
				handleClosePar(ParClose, tok2.text, operatorStack, operandStack);
				break;
			}
			
			//Unary ops
			if (matchPrefix(first, t, t2, ScriptLexer.MINUS))
			{
				if (!first)
					parseSimple(operatorStack, operandStack);
				handleOperator(UnaryMinus, tok2.text, operatorStack, operandStack);
				consume();
			}
			else
			{
				parseSimple(operatorStack, operandStack);
			}
			first = false;
			
			//for (a in operandStack.arr)
			//{
				//if (a.isOperator || a.canNest)
					//trace("OPERAND", a, a.argCount);
				//else
					//trace("OPERAND", a);
			//}
			//for (a in operatorStack.arr)
			//{
				//if (a.isOperator || a.canNest)
					//trace("OPERATOR", a, a.argCount);
				//else
					//trace("OPERATOR", a);
			//}
			//trace("");
		}
		
		//for (a in operandStack.arr)
		//{
			//if (a.isOperator || a.canNest)
				//trace(a, a.argCount);
			//else
				//trace(a);
		//}
		//for (a in operatorStack.arr)
		//{
			//if (a.isOperator || a.canNest)
				//trace(a, a.argCount);
			//else
				//trace(a);
		//}
		
		// When there are no more tokens to read:
		// While there are still operator tokens in the stack:
		// Pop the operator onto the output queue.
		while (operatorStack.length > 0)
		{
			if (Type.getClass(operatorStack.first()) == ParOpen ||
				Type.getClass(operatorStack.first()) == ParClose)
				throw("Mismatched parantheses");
			operandStack.add(operatorStack.pop());
		}
		
		//Make tree
		var i:Int = 0;
		while (operandStack.length > 1 && i < operandStack.length)
		{
			var ast:AST = operandStack.arr[i];
			if (ast.isOperator || ast.canNest)
			{
				var j:Int = 0;
				while (j < ast.argCount)
				{
					if (operandStack.length < 2)
						throw "Wrong amount of arguments";
					
					ast.children.push(operandStack.arr[i - 1]);
					operandStack.arr.splice(i - 1, 1);
					i--;
					j++;
				}
				ast.children.reverse();
				ast.allSet();
			}
			i++;
		}
		
        return operandStack.pop();
	}
	private function parseSimple(operatorStack:Stack<AST>, operandStack:Stack<AST>):Void
	{
		var t:Int = LA(1);
		var tok:Token = LT(1);
		var t2:Int = LA(2);
		var tok2:Token = LT(2);
		var t3:Int = LA(3);
		var tok3:Token = LT(3);
		var t4:Int = LA(4);
		var tok4:Token = LT(4);
		
		//Flow
		if (t == ScriptLexer.FUNCTION)
		{
			if (nestLVL != 0)
				handleComma(operatorStack, operandStack);
			
			var fname:String = null;
			if (t2 == ScriptLexer.VARIABLE)
			{
				fname = tok2.text;
				consume();
			}
			
			inNest = If;
			handleFunction(FunctionDef, fname, false, operatorStack, operandStack);
			addArgCount(FunctionDef, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok2.text, operatorStack, operandStack);
			handleFunction(Condition, "CONDITION", false, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok2.text, operatorStack, operandStack);
			consume();
		}
		else if (t == ScriptLexer.IMPORT)
		{
			handleOperator(Import, tok.text, operatorStack, operandStack);
			//consume();
			
			var toImport:String = "";
			while (LA(2) == ScriptLexer.VARIABLE || LA(2) == ScriptLexer.FIELD_ACCESSSOR)
			{
				toImport += LT(2).text;
				consume();
			}
			handleOperand(StringV, toImport, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.FOR)
		{
			handleFunction(ForIn, tok.text, false, operatorStack, operandStack);
			addArgCount(ForIn, operatorStack, operandStack);
			addArgCount(ForIn, operatorStack, operandStack);
			consume();
			consume();
			handleOpenPar(ParOpen, tok3.text, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok3.text, operatorStack, operandStack);
			parseSimple(operatorStack, operandStack);
		}
		else if (t == ScriptLexer.DO && t2 == ScriptLexer.WHILE)
		{
			consume();
			if (nestLVL != 0)
				handleComma(operatorStack, operandStack);
			
			inNest = If;
			handleFunction(While, tok2.text, false, operatorStack, operandStack);
			addArgCount(While, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok3.text, operatorStack, operandStack);
			handleFunction(Condition, "CONDITION", false, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok3.text, operatorStack, operandStack);
			consume();
		}
		else if (t == ScriptLexer.WHILE)
		{
			if (nestLVL != 0)
				handleComma(operatorStack, operandStack);
			
			inNest = If;
			handleFunction(While, tok.text, false, operatorStack, operandStack);
			addArgCount(While, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok2.text, operatorStack, operandStack);
			handleFunction(Condition, "CONDITION", false, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok2.text, operatorStack, operandStack);
			consume();
		}
		else if (t == ScriptLexer.IF)
		{
			if (nestLVL != 0)
				handleComma(operatorStack, operandStack);
			
			inNest = If;
			handleFunction(If, tok.text, false, operatorStack, operandStack);
			addArgCount(If, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok2.text, operatorStack, operandStack);
			handleFunction(Condition, "CONDITION", false, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok2.text, operatorStack, operandStack);
			consume();
		}
		else if (t == ScriptLexer.ELSE && t2 != ScriptLexer.IF)
		{
			addArgCount(If, operatorStack, operandStack);
			handleFunction(Block, "BLOCK", true, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok2.text, operatorStack, operandStack);
			consume();
		}
		else if (t == ScriptLexer.ELSE && t2 == ScriptLexer.IF)
		{
			consume();
			addArgCount(If, operatorStack, operandStack);
			addArgCount(If, operatorStack, operandStack);
			handleFunction(Condition, "CONDITION", false, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok3.text, operatorStack, operandStack);
			consume();
		}
		else if (t == ScriptLexer.CLOSE_PAR && t2 == ScriptLexer.OPEN_CURLY)
		{
			handleClosePar(ParClose, tok.text, operatorStack, operandStack);
			handleFunction(Block, "BLOCK", true, operatorStack, operandStack);
			handleOpenPar(ParOpen, tok2.text, operatorStack, operandStack);
			consume();
		}
		else if (lastToken != null && (lastToken.type == ScriptLexer.VARIABLE || lastToken.type == ScriptLexer.CLOSE_BRACK) && t == ScriptLexer.OPEN_BRACK)
		{
			handleOperator(AccessArray, "ARRAYACCESS", operatorStack, operandStack);
			consume();
			handleOperand(IntV, tok2.text, operatorStack, operandStack);
			consume();
		}
		else if (t == ScriptLexer.BREAK)
		{
			handleOperand(Break, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.CONTINUE)
		{
			handleOperand(Continue, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.CLOSE_CURLY && t2 != ScriptLexer.ELSE)
		{
			handleClosePar(ParClose, tok.text, operatorStack, operandStack);
			if (inNest == If)
				handleClosePar(ParClose, tok.text, operatorStack, operandStack);
		}
		
		else if (t == ScriptLexer.OPEN_PAR)
		{
			handleOpenPar(ParOpen, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.CLOSE_PAR || t == ScriptLexer.CLOSE_BRACK || t == ScriptLexer.CLOSE_CURLY)
		{
			handleClosePar(ParClose, tok.text, operatorStack, operandStack);
		}
		
		//Other operators
		else if (t == ScriptLexer.NEW && t2 == ScriptLexer.VARIABLE && t3 == ScriptLexer.OPEN_PAR)
		{
			var isEmpty:Bool = false;
			if (t4 == ScriptLexer.CLOSE_PAR)
				isEmpty = true;
			consume();
			handleFunction(Constructor, tok2.text, isEmpty, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.VARIABLE && t2 == ScriptLexer.OPEN_PAR)
		{
			var isEmpty:Bool = false;
			if (t3 == ScriptLexer.CLOSE_PAR)
				isEmpty = true;
			handleFunction(FunctionCall, tok.text, isEmpty, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.EQUAL && t2 != ScriptLexer.EQUAL)
		{
			handleOperator(Assign, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.FIELD_ACCESSSOR)
		{
			handleOperator(AccessField, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.COMMA)
		{
			handleComma(operatorStack, operandStack);
		}
		
		//Bool operators
		
		
		//Math operators
		else if (t == ScriptLexer.PLUS)
		{
			if (t2 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundAdd, tok.text + tok2.text, operatorStack, operandStack);
			}
			else
				handleOperator(Add, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.MULT)
		{
			if (t2 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundMultiply, tok.text + tok2.text, operatorStack, operandStack);
			}
			else
				handleOperator(Multiply, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.DIV)
		{
			if (t2 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundDivide, tok.text + tok2.text, operatorStack, operandStack);
			}
			else
				handleOperator(Divide, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.MOD)
		{
			if (t2 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundModulo, tok.text + tok2.text, operatorStack, operandStack);
			}
			else
				handleOperator(Modulo, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.MINUS)
		{
			if (t2 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundSubstract, tok.text + tok2.text, operatorStack, operandStack);
			}
			else
				handleOperator(Substract, tok.text, operatorStack, operandStack);
		}
		
		//Bitwise operators
		else if (t == ScriptLexer.COMPLEMENT)
		{
			handleOperator(BitwiseNot, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.AND && t2 != ScriptLexer.AND)
		{
			if (t2 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundBitwiseAnd, tok.text + tok2.text, operatorStack, operandStack);
			}
			else
				handleOperator(BitwiseAnd, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.OR && t2 != ScriptLexer.OR)
		{
			if (t2 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundBitwiseOr, tok.text + tok2.text, operatorStack, operandStack);
			}
			else
				handleOperator(BitwiseOr, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.XOR)
		{
			if (t2 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundBitwiseXOr, tok.text + tok2.text, operatorStack, operandStack);
			}
			else
				handleOperator(BitwiseXOr, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.BIGGER && t2 == ScriptLexer.BIGGER && t3 != ScriptLexer.BIGGER)
		{
			consume();
			if (t3 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundBitwiseShiftRight, tok.text + tok2.text + tok3.text, operatorStack, operandStack);
			}
			else
				handleOperator(BitwiseShiftRight, tok.text + tok2.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.BIGGER && t2 == ScriptLexer.BIGGER && t3 == ScriptLexer.BIGGER)
		{
			consume();
			consume();
			if (t4 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundBitwiseShiftRightUnsigned, tok.text + tok2.text + tok3.text + tok4.text, operatorStack, operandStack);
			}
			else
				handleOperator(BitwiseShiftRightUnsigned, tok.text + tok2.text + tok3.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.SMALLER && t2 == ScriptLexer.SMALLER)
		{
			consume();
			if (t3 == ScriptLexer.EQUAL)
			{
				consume();
				handleOperator(CompoundBitwiseShiftLeft, tok.text + tok2.text + tok3.text, operatorStack, operandStack);
			}
			else
				handleOperator(BitwiseShiftLeft, tok.text + tok2.text, operatorStack, operandStack);
		}
		
		//Boolean operators
		else if (t == ScriptLexer.AND && t2 == ScriptLexer.AND)
		{
			consume();
			handleOperator(And, tok.text + tok2.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.OR && t2 == ScriptLexer.OR)
		{
			consume();
			handleOperator(Or, tok.text + tok2.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.NOT && t2 != ScriptLexer.EQUAL)
		{
			handleOperator(Not, tok.text + tok2.text, operatorStack, operandStack);
		}
		
		//Comparison operators
		else if (t == ScriptLexer.SMALLER && t2 != ScriptLexer.EQUAL)
		{
			handleOperator(Smaller, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.SMALLER && t2 == ScriptLexer.EQUAL)
		{
			consume();
			handleOperator(SmallerOrEqual, tok.text + tok2.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.BIGGER && t2 != ScriptLexer.EQUAL)
		{
			handleOperator(Bigger, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.BIGGER && t2 == ScriptLexer.EQUAL)
		{
			consume();
			handleOperator(BiggerOrEqual, tok.text + tok2.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.EQUAL && t2 == ScriptLexer.EQUAL)
		{
			consume();
			handleOperator(Equal, tok.text + tok2.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.NOT && t2 == ScriptLexer.EQUAL)
		{
			consume();
			handleOperator(NotEqual, tok.text + tok2.text, operatorStack, operandStack);
		}
		
		//Values
		else if (t == ScriptLexer.INT)
		{
			handleOperand(IntV, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.FLOAT)
		{
			handleOperand(FloatV, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.VARIABLE)
		{
			handleOperand(Variable, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.STRING)
		{
			handleOperand(StringV, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.BOOL)
		{
			handleOperand(BoolV, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.NULL)
		{
			handleOperand(NullV, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.OPEN_BRACK)
		{
			var isEmpty:Bool = false;
			if (t2 == ScriptLexer.CLOSE_BRACK)
				isEmpty = true;
			handleFunction(ArrayV, "ARRAY", isEmpty, operatorStack, operandStack);
			
			handleOpenPar(ParOpen, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.OPEN_CURLY)
		{
			inNest = ObjectV;
			var isEmpty:Bool = false;
			if (t2 == ScriptLexer.CLOSE_CURLY)
				isEmpty = true;
			handleFunction(ObjectV, "OBJECT", isEmpty, operatorStack, operandStack);
			
			handleOpenPar(ParOpen, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.COLON)
		{
			handleOperator(FieldID, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.COLON)
		{
			handleOperator(FieldID, tok.text, operatorStack, operandStack);
		}
		else if (t == ScriptLexer.SEMI_COLON)
		{
			handleComma(operatorStack, operandStack);
		}
		
		else
		{
			throw("Unknown token");
		}
		consume();
	}
	
	private function handleOpenPar(Ast:Class<AST>, Text:String, OperatorStack:Stack<AST>, OutStack:Stack<AST>):Void
	{
		// If the token is a left parenthesis (i.e. "("), then push it onto the stack.
		var ast:AST = Type.createInstance(Ast, [Text, []]);
		OperatorStack.add(ast);
		nestLVL++;
	}
	private function handleClosePar(Ast:Class<AST>, Text:String, OperatorStack:Stack<AST>, OutStack:Stack<AST>):Void
	{
		// If the token is a right parenthesis (i.e. ")"):
        // Until the token at the top of the stack is a left parenthesis, pop operators off the stack onto the output queue.
		while (true)
		{
			if (OperatorStack.length > 0)
			{
				var ast:AST = OperatorStack.first();
				if (Type.getClass(ast) == ParOpen)
				{
					// Pop the left parenthesis from the stack, but not onto the output queue.
					OperatorStack.pop();
					break;
				}
				else
					OutStack.add(OperatorStack.pop());
			}
			else
				throw("Mismatched parantheses");
		}
        // If the token at the top of the stack is a function token, pop it onto the output queue.
		if (OperatorStack.length > 0)
		{
			var ast:AST = OperatorStack.first();
			if (ast.canNest)
				OutStack.add(OperatorStack.pop());
		}
		nestLVL--;
	}
	private function handleFunction(Ast:Class<AST>, Text:String, IsEmptyFunction:Bool, OperatorStack:Stack<AST>, OutStack:Stack<AST>):Void
	{
		// If the token is a function token, then push it onto the stack.
		var ast:AST = Type.createInstance(Ast, [Text, []]);
		OperatorStack.add(ast);
        // Check if the function has no arguments
        if (IsEmptyFunction)
            ast.argCount = 0;
        else
            ast.argCount = 1;
	}
	private function handleComma(OperatorStack:Stack<AST>, OutStack:Stack<AST>):Void
	{
		// If the token is a function argument separator (e.g., a comma):
        // Until the token at the top of the stack is a left parenthesis,
		// pop operators off the stack onto the output queue. If no left
		// parentheses are encountered, either the separator was misplaced
		// or parentheses were mismatched.
		
		var k:Int = OperatorStack.length - 1;
		var found:Bool = false;
		while (k >= 0)
		{
			var o:AST = OperatorStack.arr[k];
			if (o.canNest)
			{
				found = true;
				o.argCount++;
				break;
			}
			k--;
		}
		
		while (Type.getClass(OperatorStack.first()) != ParOpen)
		{
			if (OperatorStack.length == 0)
				throw("Mismatched parantheses or misplaced comma");
			OutStack.add(OperatorStack.pop());
		}
	}
	private function addArgCount(Target:Class<AST>, OperatorStack:Stack<AST>, OutStack:Stack<AST>):Void
	{
		var k:Int = OperatorStack.length - 1;
		while (k >= 0)
		{
			var o:AST = OperatorStack.arr[k];
			if (Type.getClass(o) == Target)
			{
				o.argCount++;
				break;
			}
			k--;
		}
	}
	private function handleOperand(Ast:Class<AST>, Text:String, OperatorStack:Stack<AST>, OutStack:Stack<AST>):Void
	{
		// If the token is an operand, then add it to the output queue.
		var ast:AST = Type.createInstance(Ast, [Text, []]);
		OutStack.add(ast);
	}
	private function handleOperator(Ast:Class<AST>, Text:String, OperatorStack:Stack<AST>, OutStack:Stack<AST>):Void
	{
		var op1:AST = Type.createInstance(Ast, [Text, []]);
		
		// If the token is an operator, o1, then:
		// while there is an operator token, o2, at the top of the operator stack, and either
		// o1 is left-associative and its precedence is less than or equal to that of o2,
		// or
		// o1 is right associative, and has precedence less than that of o2,
		while (true)
		{
			var hasOp:Bool = false;
			var cond1:Bool = false;
			var cond2:Bool = false;
			var op2:AST = null;
			
			hasOp = OperatorStack.length > 0;
			if (hasOp)
			{
				op2 = OperatorStack.first();
				hasOp = op2.isOperator;
				
				cond1 = !op1.rightAssociative && op1.priority <= op2.priority;
				cond2 = op1.rightAssociative && op1.priority < op2.priority;
				
				if (cond1 || cond2)
				{
					// then pop o2 off the operator stack, onto the output queue;
					OutStack.add(OperatorStack.pop());
				}
				else
					break;
			}
			else
				break;
		}
		
		// push o1 onto the operator stack.
		OperatorStack.add(op1);
	}
}