declare Leaf App MakeOp Tokenize Lookup TokenToNode
ParseFactor ParseTerm ParseTermRest ParseExpr ParseExprRest ParseBody ParseDefinition
ParseApplication ParseArgs GraphGeneration GenerateGraph GraphToRecord
IsPrimitive IsNumberNode RightChild Unwind Redex PrimitiveRedex FirstRedex FindRedex NextReduction

fun {Leaf V}
   {NewCell leaf(V)}
end

fun {App L R}
   {NewCell app(L R)}
end

fun {MakeOp Op L R}
   {App {App {Leaf {String.toAtom Op}} L} R}
end

fun {Tokenize Line}
   Spaced = {FoldR Line
             fun {$ C Acc}
                if {Member C "+-*/()="} then & |C|& |Acc else C|Acc end
             end
             nil}
in
   {Filter {String.tokens Spaced & } fun {$ T} T \= nil end}
end

fun {Lookup Name Env}
   case Env of N#Node|Rest then
      if N == Name then Node else {Lookup Name Rest} end
   else
      {Leaf Name}
   end
end

fun {TokenToNode T Env}
   if {String.isInt T} then
      {Leaf {String.toInt T}}
   else
      {Lookup {String.toAtom T} Env}
   end
end

fun {ParseFactor Tokens Env}
   case Tokens of "("|Rest then
      Node Rest2 in
      Node#(_|Rest2) = {ParseExpr Rest Env}
      Node#Rest2
   [] T|Rest then
      {TokenToNode T Env}#Rest
   end
end

fun {ParseTerm Tokens Env}
   Left Rest in
   Left#Rest = {ParseFactor Tokens Env}
   {ParseTermRest Left Rest Env}
end

fun {ParseTermRest Left Tokens Env}
   case Tokens of Op|Rest then
      if Op == "*" orelse Op == "/" then
         Right Rest2 in
         Right#Rest2 = {ParseFactor Rest Env}
         {ParseTermRest {MakeOp Op Left Right} Rest2 Env}
      else
         Left#Tokens
      end
   else
      Left#Tokens
   end
end

fun {ParseExpr Tokens Env}
   Left Rest in
   Left#Rest = {ParseTerm Tokens Env}
   {ParseExprRest Left Rest Env}
end

fun {ParseExprRest Left Tokens Env}
   case Tokens of Op|Rest then
      if Op == "+" orelse Op == "-" then
         Right Rest2 in
         Right#Rest2 = {ParseTerm Rest Env}
         {ParseExprRest {MakeOp Op Left Right} Rest2 Env}
      else
         Left#Tokens
      end
   else
      Left#Tokens
   end
end

fun {ParseBody Tokens Env}
   case Tokens of "var"|NameS|Rest then
      ExprTokens Node Rest2 NewEnv in
      ExprTokens = case Rest of "="|R then R else Rest end
      Node#Rest2 = {ParseExpr ExprTokens Env}
      NewEnv = ({String.toAtom NameS}#Node)|Env
      case Rest2 of "in"|Rest3 then
         {ParseBody Rest3 NewEnv}
      else
         {ParseBody Rest2 NewEnv}
      end
   else
      {ParseExpr Tokens Env}.1
   end
end

fun {ParseDefinition Tokens}
   NameS Rest ParamsS BodyTokens in
   "fun"|NameS|Rest = Tokens
   {List.takeDropWhile Rest fun {$ T} T \= "=" end ParamsS _|BodyTokens}
   {String.toAtom NameS}#def(params: {Map ParamsS String.toAtom}
                             body: {ParseBody BodyTokens nil})
end

fun {ParseApplication Tokens Funs}
   case Tokens of "("|Rest then
      Node Rest2 in
      Node#(_|Rest2) = {ParseApplication Rest Funs}
      Node#Rest2
   [] T|Rest then
      if {String.isInt T} then
         {Leaf {String.toInt T}}#Rest
      else
         Name = {String.toAtom T} in
         if {HasFeature Funs Name} then
            {ParseArgs {Leaf Name} {Length Funs.Name.params} Rest Funs}
         else
            {Leaf Name}#Rest
         end
      end
   end
end

fun {ParseArgs Node N Tokens Funs}
   if N == 0 then
      Node#Tokens
   else
      Arg Rest in
      Arg#Rest = {ParseApplication Tokens Funs}
      {ParseArgs {App Node Arg} N-1 Rest Funs}
   end
end

fun {GraphGeneration Program}
   Lines = {Filter {Map {String.tokens Program &\n} Tokenize} fun {$ L} L \= nil end}
   Defs = {Filter Lines fun {$ L} L.1 == "fun" end}
   Calls = {Filter Lines fun {$ L} L.1 \= "fun" end}
   Funs = {List.toRecord funs {Map Defs ParseDefinition}}
in
   program(funs: Funs graph: {ParseApplication {List.last Calls} Funs}.1)
end

GenerateGraph = GraphGeneration

fun {GraphToRecord Node}
   case @Node of leaf(V) then V
   [] app(L R) then '@'({GraphToRecord L} {GraphToRecord R})
   [] ind(N) then {GraphToRecord N}
   end
end

fun {IsPrimitive V}
   {Member V ['+' '-' '*' '/']}
end

fun {IsNumberNode Node}
   case @Node of leaf(V) then {IsNumber V}
   [] ind(N) then {IsNumberNode N}
   else false
   end
end

fun {RightChild Node}
   case @Node of app(_ R) then R end
end

fun {Unwind Node Stack}
   case @Node of app(L _) then
      {Unwind L Node|Stack}
   [] ind(N) then
      {Unwind N Stack}
   else
      Node|Stack
   end
end

fun {Redex Name Stack Arity}
   if {Length Stack} =< Arity then
      none
   else
      redex(name: Name
            args: {Map {List.take Stack.2 Arity} RightChild}
            root: {Nth Stack Arity+1})
   end
end

fun {PrimitiveRedex Name Stack Funs}
   R = {Redex Name Stack 2}
in
   if R == none then none
   elseif {All R.args IsNumberNode} then R
   else {FirstRedex R.args Funs}
   end
end

fun {FirstRedex Nodes Funs}
   case Nodes of Node|Rest then
      R = {FindRedex Node Funs} in
      if R == none then {FirstRedex Rest Funs} else R end
   else
      none
   end
end

fun {FindRedex Node Funs}
   Stack = {Unwind Node nil}
   Head = Stack.1
   Name = case @Head of leaf(V) then V end
in
   if {IsPrimitive Name} then
      {PrimitiveRedex Name Stack Funs}
   elseif {HasFeature Funs Name} then
      {Redex Name Stack {Length Funs.Name.params}}
   else
      none
   end
end

fun {NextReduction Program}
   {FindRedex Program.graph Program.funs}
end
